import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../controllers/app_controller.dart';
import '../core/data/avatar_catalog.dart';
import '../core/data/planet_ladder.dart';
import '../widgets/nebula_snack.dart';
import '../widgets/star_difficulty_sheet.dart';
import 'child_profile_setup_screen.dart';
import 'connect_screen.dart';
import 'dilo_screen.dart';
import 'emotion_screen.dart';
import 'explore_learn_screen.dart';
import 'game_placeholder_screen1.dart';
import 'minigames_screen.dart';
import 'planet_ladder_screen.dart';
import 'portal_entry_screen.dart';
import 'settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _checkedChildProfile = false;
  bool _levelUpDialogCheckQueued = false;
  bool _levelUpDialogVisible = false;
  static const double _levelUpDialogHeight = 520; // editable
  static const double _levelUpDialogMaxWidth = 360; // editable

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectIfMissingChildProfile();
    });
  }

  Future<void> _redirectIfMissingChildProfile() async {
    if (_checkedChildProfile || !mounted) return;
    _checkedChildProfile = true;
    if (!widget.controller.hasChildProfile) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChildProfileSetupScreen(
            controller: widget.controller,
            isMandatory: true,
          ),
        ),
      );
    }
  }

  Future<bool> _guardGameAccess(
    BuildContext context, {
    required String gameKey,
  }) async {
    final check = widget.controller.canLaunchGame(gameKey);
    if (!check.ok) {
      await NebulaSnack.show(context, message: check.message, ok: false);
      return false;
    }

    final sync = await widget.controller.syncGlobalGameContentForPlay();
    if (!context.mounted) return false;
    if (!sync.ok) {
      await NebulaSnack.show(context, message: sync.message, ok: false);
      return false;
    }
    return true;
  }

  Future<void> _openGame(
    BuildContext context, {
    required String gameName,
    required String gameKey,
  }) async {
    final allowed = await _guardGameAccess(context, gameKey: gameKey);
    if (!context.mounted || !allowed) return;

    final stars = await showStarDifficultySheet(context);
    if (!context.mounted || stars == null) return;

    Widget screen;
    switch (gameKey) {
      case 'descubre_emocion':
        screen = EmotionGameScreen(
          controller: widget.controller,
          gameName: gameName,
          difficultyStars: stars,
        );
        break;
      case 'conecta_sonidos':
        final difficulty = switch (stars) {
          1 => GameDifficulty.easy,
          2 => GameDifficulty.medium,
          3 => GameDifficulty.hard,
          _ => GameDifficulty.easy,
        };
        screen = ConnectSoundGameScreen(
          controller: widget.controller,
          difficulty: difficulty,
        );
        break;
      case 'di_palabra':
        screen = Gamediloscreen(
          controller: widget.controller,
          gameName: gameName,
          gameKey: gameKey,
          difficultyStars: stars,
        );
        break;
      default:
        screen = GamePlaceholderScreen(
          controller: widget.controller,
          gameName: gameName,
          gameKey: gameKey,
          difficultyStars: stars,
        );
        break;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<void> _backToPortalSelector() async {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    widget.controller.markPortalSelectionPending();
    if (!mounted) return;
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => PortalEntryScreen(controller: widget.controller),
      ),
    );
  }

  void _schedulePendingLevelUpDialogCheck() {
    if (!mounted || _levelUpDialogVisible || _levelUpDialogCheckQueued) return;
    _levelUpDialogCheckQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _levelUpDialogCheckQueued = false;
      if (!mounted || _levelUpDialogVisible) return;
      final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
      if (!isCurrentRoute) return;
      final nextPlanetName =
          widget.controller.consumePendingHomeLevelUpPlanetName();
      if (nextPlanetName == null || nextPlanetName.trim().isEmpty) return;
      _levelUpDialogVisible = true;
      final accent = widget.controller.accentButtonColor;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          final width = MediaQuery.sizeOf(context).width;
          final dialogWidth =
              (width * 0.92).clamp(280.0, _levelUpDialogMaxWidth);
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: accent, width: 3),
            ),
            child: SizedBox(
              width: dialogWidth,
              height: _levelUpDialogHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                child: Column(
                  children: [
                    const Text(
                      '¡Felicidades!🏅',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF253760),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Has llegado a $nextPlanetName',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF253760),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: Lottie.asset(
                        'assets/animations/niveles.json',
                        fit: BoxFit.contain,
                        repeat: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Revisa tus premios🎁',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF253760),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: SizedBox(
                        width: 180,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Continuar'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
      _levelUpDialogVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.controller.currentUser;
    if (user == null) return const SizedBox.shrink();
    _schedulePendingLevelUpDialogCheck();

    final descubreLabel = widget.controller.gameLabelForKey('descubre_emocion');
    final conectaLabel = widget.controller.gameLabelForKey('conecta_sonidos');
    final diLabel = widget.controller.gameLabelForKey('di_palabra');
    final exploraLabel = widget.controller.gameLabelForKey('explora_aprende');
    final miniLabel = widget.controller.gameLabelForKey('minijuegos');
    final color = widget.controller.accentButtonColor;
    final planet = planetForStars(user.stars);
    final progress = planetProgress(user.stars);
    final remaining = starsToNextPlanet(user.stars);
    final avatarIndex =
        user.avatarIndex.clamp(0, avatarCatalog.length - 1).toInt();
    final avatar = avatarCatalog[avatarIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
          children: [
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _backToPortalSelector,
                  child: Ink(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white.withValues(alpha: 0.90),
                    ),
                    child: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.rocket_launch_rounded,
                        size: 18,
                        color: color,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Habla conmigo',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                          controller: widget.controller,
                          allowPersonalization: false,
                        ),
                      ),
                    );
                  },
                  child: Ink(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white.withValues(alpha: 0.90),
                    ),
                    child: const Icon(Icons.settings_rounded),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (widget.controller.appInMaintenance && widget.controller.isAdmin)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.admin_panel_settings_rounded),
                    title: const Text('Modo mantenimiento activo'),
                    subtitle: Text(
                      widget.controller.appMaintenanceMessage.trim().isEmpty
                          ? 'Los perfiles ni\u00f1o/cuidador no podran abrir juegos.'
                          : widget.controller.appMaintenanceMessage,
                    ),
                  ),
                ),
              ),
            _WelcomeStatusCard(
              accentColor: color,
              username: widget.controller.activeChildName,
              avatar: avatar,
              isOnline: widget.controller.isOnline,
              planetName: planet.name,
              stars: user.stars,
              progress: progress,
              remaining: remaining,
              onPlanetTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        PlanetLadderScreen(controller: widget.controller),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            const _SectionHeader(
              title: 'Juegos divertidos',
              subtitle: 'Escoge una aventura y suma estrellitas',
            ),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.85,
              children: [
                _GameCard(
                  title: descubreLabel.toUpperCase(),
                  imagePath: 'assets/images/games/descubre_emocion1.png',
                  onTap: () => _openGame(
                    context,
                    gameName: descubreLabel,
                    gameKey: 'descubre_emocion',
                  ),
                  accentColor: color,
                ),
                _GameCard(
                  title: conectaLabel.toUpperCase(),
                  imagePath: 'assets/images/games/conecta_imagenes1.png',
                  accentColor: color,
                  onTap: () => _openGame(
                    context,
                    gameName: conectaLabel,
                    gameKey: 'conecta_sonidos',
                  ),
                ),
                _GameCard(
                  title: diLabel.toUpperCase(),
                  imagePath: 'assets/images/games/di_palabra1.png',
                  accentColor: color,
                  onTap: () => _openGame(
                    context,
                    gameName: diLabel,
                    gameKey: 'di_palabra',
                  ),
                ),
                _GameCard(
                  title: exploraLabel.toUpperCase(),
                  imagePath: 'assets/images/games/explora_aprende1.png',
                  accentColor: color,
                  onTap: () async {
                    final allowed = await _guardGameAccess(
                      context,
                      gameKey: 'explora_aprende',
                    );
                    if (!context.mounted || !allowed) return;
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ExploreLearnScreen(controller: widget.controller),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - 10) / 2;
                final cardHeight = cardWidth / 1.04;
                return Center(
                  child: SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: _GameCard(
                      title: miniLabel.toUpperCase(),
                      imagePath: 'assets/images/games/minijuegos1.png',
                      accentColor: color,
                      onTap: () async {
                        final allowed = await _guardGameAccess(
                          context,
                          gameKey: 'minijuegos',
                        );
                        if (!context.mounted || !allowed) return;
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                MinigamesScreen(controller: widget.controller),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF253760),
              ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF607297),
              ),
        ),
      ],
    );
  }
}

class _WelcomeStatusCard extends StatelessWidget {
  const _WelcomeStatusCard({
    required this.username,
    required this.avatar,
    required this.isOnline,
    required this.planetName,
    required this.stars,
    required this.progress,
    required this.remaining,
    required this.onPlanetTap,
    required this.accentColor,
  });

  final String username;
  final String avatar;
  final bool isOnline;
  final String planetName;
  final int stars;
  final double progress;
  final int remaining;
  final VoidCallback onPlanetTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: accentColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Text(
                    avatar,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, $username!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOnline ? 'Listo para jugar' : 'Modo offline',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onPlanetTap,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Planeta $planetName',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$stars estrellas⭐',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      remaining > 0
                          ? 'Faltan $remaining estrellas.'
                          : 'Rango maximo alcanzado.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.title,
    required this.imagePath,
    required this.onTap,
    required this.accentColor,
  });

  final String title;
  final String imagePath;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(22),
      color: accentColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 4,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
