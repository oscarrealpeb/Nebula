import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../controllers/app_controller.dart';
import '../core/data/donde_va_catalog.dart';
import '../widgets/cosmic_background.dart';

class DondeVaScreen extends StatefulWidget {
  const DondeVaScreen({
    super.key,
    required this.controller,
    required this.difficultyStars,
  });

  final AppController controller;
  final int difficultyStars;

  @override
  State<DondeVaScreen> createState() => _DondeVaScreenState();
}

class _DondeVaScreenState extends State<DondeVaScreen> {
  final Random _random = Random();

  late DateTime _startedAt;
  late int _difficultyStars;
  late DondeVaGameSession _session;
  int _roundIndex = 0;
  int _mistakes = 0;
  int _totalAttempts = 0;
  int _perfectRounds = 0;
  int _pressedBoxIndex = -1;
  String _feedbackMessage = 'Toca la caja donde pertenece el objeto.';
  bool _feedbackOk = true;
  bool _roundResolved = false;
  bool _finishing = false;
  String? _correctCategoryId;
  final Set<String> _disabledCategoryIds = <String>{};

  DondeVaRound get _currentRound => _session.rounds[_roundIndex];

  @override
  void initState() {
    super.initState();
    _difficultyStars = widget.difficultyStars.clamp(1, 3).toInt();
    _startSession();
  }

  void _startSession() {
    _startedAt = DateTime.now();
    _session = buildDondeVaGameSession(_difficultyStars, _random);
    _roundIndex = 0;
    _mistakes = 0;
    _totalAttempts = 0;
    _perfectRounds = 0;
    _pressedBoxIndex = -1;
    _feedbackMessage = 'Toca la caja donde pertenece el objeto.';
    _feedbackOk = true;
    _roundResolved = false;
    _finishing = false;
    _correctCategoryId = null;
    _disabledCategoryIds.clear();
  }

  int _starsReward() {
    switch (_difficultyStars) {
      case 1:
        return 20;
      case 2:
        return 25;
      default:
        return 30;
    }
  }

  Future<void> _selectCategory(DondeVaCategory category) async {
    if (_finishing || _roundResolved) return;
    if (_disabledCategoryIds.contains(category.id)) return;

    setState(() {
      _totalAttempts += 1;
    });

    if (category.id == _currentRound.correctCategory.id) {
      if (_disabledCategoryIds.isEmpty) {
        _perfectRounds += 1;
      }
      setState(() {
        _roundResolved = true;
        _correctCategoryId = category.id;
        _feedbackMessage = 'Muy bien. Ese objeto va en ${category.label}.';
        _feedbackOk = true;
      });

      await Future<void>.delayed(const Duration(milliseconds: 850));
      if (!mounted) return;

      if (_roundIndex >= _session.rounds.length - 1) {
        await _finishGame();
        return;
      }

      setState(() {
        _roundIndex += 1;
        _roundResolved = false;
        _correctCategoryId = null;
        _disabledCategoryIds.clear();
        _feedbackMessage = 'Excelente. Vamos con el siguiente objeto.';
        _feedbackOk = true;
      });
      return;
    }

    setState(() {
      _mistakes += 1;
      _disabledCategoryIds.add(category.id);
      _feedbackMessage = '${category.label} no es. Intenta con otra caja.';
      _feedbackOk = false;
    });
  }

  Future<void> _finishGame() async {
    if (_finishing) return;
    _finishing = true;
    final earnedStars = _starsReward();
    final rounds = _session.rounds.length;
    final correctAnswers = rounds;

    await widget.controller.addStars(earnedStars);
    await widget.controller.recordGameSession(
      gameKey: 'donde_va',
      startedAt: _startedAt,
      endedAt: DateTime.now(),
      difficultyStars: _difficultyStars,
      rounds: rounds,
      mistakes: _mistakes,
      pointsEarned: earnedStars,
      correctAnswers: correctAnswers,
      totalAttempts: _totalAttempts,
      perfectRounds: _perfectRounds,
    );

    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFFD3EDD5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ganaste $earnedStars estrellas',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Clasificaste $correctAnswers objetos.\nAciertos al primer intento: $_perfectRounds',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 140,
                child: Lottie.asset(
                  'assets/animations/estrellas.json',
                  repeat: true,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await Future<void>.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    if (rootNavigator.canPop()) {
      rootNavigator.pop();
    }
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    setState(() {
      _startSession();
    });
  }

  List<List<DondeVaCategory>> _categoryRows() {
    final categories = _session.visibleCategories;
    if (categories.length <= 2) {
      return <List<DondeVaCategory>>[categories];
    }
    if (categories.length == 3) {
      return <List<DondeVaCategory>>[
        categories.sublist(0, 2),
        categories.sublist(2, 3),
      ];
    }
    return <List<DondeVaCategory>>[
      categories.sublist(0, 2),
      categories.sublist(2, 4),
    ];
  }

  Widget _buildCategoryBox(DondeVaCategory category) {
    final boxIndex = _session.visibleCategories.indexOf(category);
    return _CategoryBox(
      category: category,
      disabled: _disabledCategoryIds.contains(category.id),
      isCorrect: _correctCategoryId == category.id,
      pressed: _pressedBoxIndex == boxIndex,
      onPressed: () => _selectCategory(category),
      onPressStart: () {
        setState(() => _pressedBoxIndex = boxIndex);
      },
      onPressEnd: () {
        setState(() => _pressedBoxIndex = -1);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.controller.accentButtonColor;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: Text(widget.controller.gameLabelForKey('donde_va')),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                _GameHeader(
                  accent: accent,
                  currentRound: _roundIndex + 1,
                  totalRounds: _session.rounds.length,
                  mistakes: _mistakes,
                  difficultyStars: _difficultyStars,
                ),
                      const SizedBox(height: 14),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _feedbackOk
                              ? const Color(0xFFE6F7EE)
                              : const Color(0xFFFBE3E6),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _feedbackOk
                                ? const Color(0xFF70C692)
                                : const Color(0xFFE48693),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _feedbackOk
                                  ? Icons.check_circle_rounded
                                  : Icons.info_rounded,
                              color: _feedbackOk
                                  ? const Color(0xFF2B8556)
                                  : const Color(0xFFB44E5F),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _feedbackMessage,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._categoryRows().map(
                        (row) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: row.length == 1
                              ? Center(
                                  child: SizedBox(
                                    width: 170,
                                    child: _buildCategoryBox(row.first),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: row.map((category) {
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                        ),
                                        child: _buildCategoryBox(category),
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: _ObjectCard(
                          accent: accent,
                          item: _currentRound.item,
                          assetPath: widget.controller.resolvedGameImageSourceFor(
                            gameKey: 'donde_va',
                            itemId: dondeVaGlobalItemId(
                              categoryId: _currentRound.correctCategory.id,
                              itemId: _currentRound.item.id,
                            ),
                            defaultSource: dondeVaItemAssetPath(
                              categoryId: _currentRound.correctCategory.id,
                              itemId: _currentRound.item.id,
                              extension: _currentRound.item.assetExtension,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Escoge la caja correcta para este objeto.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF253760),
                              fontWeight: FontWeight.w700,
                            ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({
    required this.accent,
    required this.currentRound,
    required this.totalRounds,
    required this.mistakes,
    required this.difficultyStars,
  });

  final Color accent;
  final int currentRound;
  final int totalRounds;
  final int mistakes;
  final int difficultyStars;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ronda $currentRound de $totalRounds',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Color(0xFF253760),
                  ),
                ),
              ),
              Row(
                children: List<Widget>.generate(
                  difficultyStars,
                  (_) => const Padding(
                    padding: EdgeInsets.only(left: 2),
                    child: Icon(Icons.star_rounded, color: Colors.amber),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List<Widget>.generate(totalRounds, (index) {
              final isCompleted = index < currentRound;
              return Expanded(
                child: Container(
                  height: 8,
                  margin: EdgeInsets.only(
                    right: index == totalRounds - 1 ? 0 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? accent
                        : const Color(0xFFE1E1E4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.track_changes_rounded, size: 18),
              const SizedBox(width: 6),
              Text(
                'Errores: $mistakes',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryBox extends StatelessWidget {
  const _CategoryBox({
    required this.category,
    required this.disabled,
    required this.isCorrect,
    required this.pressed,
    required this.onPressed,
    required this.onPressStart,
    required this.onPressEnd,
  });

  final DondeVaCategory category;
  final bool disabled;
  final bool isCorrect;
  final bool pressed;
  final VoidCallback onPressed;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;

  @override
  Widget build(BuildContext context) {
    final baseColor = disabled
        ? Colors.grey.shade300
        : isCorrect
            ? const Color(0xFFCDEECD)
            : category.color;
    final borderColor = disabled
        ? Colors.grey.shade500
        : isCorrect
            ? const Color(0xFF5EB977)
            : category.color.withValues(alpha: 0.95);

    return GestureDetector(
      onTapDown: (_) => onPressStart(),
      onTapUp: (_) => onPressEnd(),
      onTapCancel: onPressEnd,
      onTap: disabled ? null : onPressed,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: pressed ? 0.96 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: disabled
                ? const <BoxShadow>[]
                : <BoxShadow>[
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.24),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                category.emoji,
                style: const TextStyle(fontSize: 30),
              ),
              const SizedBox(height: 8),
              Text(
                category.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color:
                      disabled ? Colors.grey.shade700 : const Color(0xFF253760),
                ),
              ),
              const SizedBox(height: 6),
              Icon(
                disabled
                    ? Icons.block_rounded
                    : isCorrect
                        ? Icons.check_circle_rounded
                        : Icons.touch_app_rounded,
                color: disabled
                    ? Colors.grey.shade700
                    : isCorrect
                        ? const Color(0xFF2D8B57)
                        : const Color(0xFF253760),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ObjectCard extends StatelessWidget {
  const _ObjectCard({
    required this.accent,
    required this.item,
    required this.assetPath,
  });

  final Color accent;
  final DondeVaItem item;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: accent.withValues(alpha: 0.28),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 170),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FD),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: accent.withValues(alpha: 0.18),
                ),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, stackTrace) {
                    debugPrint(
                      'No se pudo cargar asset de Donde Va: $assetPath',
                    );
                    return Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 56),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF253760),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
