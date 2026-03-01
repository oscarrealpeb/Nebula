import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/portal_role.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/nebula_button.dart';
import '../widgets/nebula_snack.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.controller,
    this.flashMessage = '',
    this.flashOk = true,
  });

  final AppController controller;
  final String flashMessage;
  final bool flashOk;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _navigating = false;
  PortalRole _role = PortalRole.caregiver;

  final _slides = const [
    (
      icon: Icons.rocket_launch_rounded,
      title: 'Aprende jugando',
      subtitle: 'Actividades cortas y divertidas para avanzar paso a paso.',
    ),
    (
      icon: Icons.sentiment_satisfied_alt_rounded,
      title: 'Entiende emociones',
      subtitle: 'Reconoce expresiones y practica habilidades de comunicacion.',
    ),
    (
      icon: Icons.family_restroom_rounded,
      title: 'Acompana en familia',
      subtitle: 'Cuidador y ni\u00f1o con experiencias separadas y seguras.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final flash = widget.flashMessage.trim();
    if (flash.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        NebulaSnack.show(context, message: flash, ok: widget.flashOk);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openLogin() async {
    if (_navigating || !mounted) return;
    _navigating = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            controller: widget.controller,
            initialRole: _role,
          ),
        ),
      );
    } finally {
      _navigating = false;
    }
  }

  Future<void> _openRegister() async {
    if (_navigating || !mounted) return;
    if (_role == PortalRole.child) {
      final goCaregiver = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cuenta de ni\u00f1o'),
          content: const Text(
            'Las cuentas de ni\u00f1o las crea un cuidador desde su panel.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ir a cuidador'),
            ),
          ],
        ),
      );
      if (!mounted || goCaregiver != true) return;
      setState(() => _role = PortalRole.caregiver);
    }
    _navigating = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RegisterScreen(controller: widget.controller),
        ),
      );
    } finally {
      _navigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CosmicBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shield_moon_outlined,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nebula',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF13254B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<PortalRole>(
                  segments: const [
                    ButtonSegment<PortalRole>(
                      value: PortalRole.child,
                      label: Text('Ni\u00f1o'),
                      icon: Icon(Icons.child_care_rounded),
                    ),
                    ButtonSegment<PortalRole>(
                      value: PortalRole.caregiver,
                      label: Text('Cuidador'),
                      icon: Icon(Icons.family_restroom_rounded),
                    ),
                  ],
                  selected: <PortalRole>{_role},
                  onSelectionChanged: (selection) {
                    setState(() => _role = selection.first);
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  '\u00bfQui\u00e9n va a usar la app ahora?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF4F628A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Este dispositivo puede ser compartido. Puedes alternar entre ni\u00f1o y cuidador cuando quieras.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF4F628A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 7,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _slides.length,
                      onPageChanged: (value) =>
                          setState(() => _currentPage = value),
                      itemBuilder: (context, index) {
                        final slide = _slides[index];
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              theme.colorScheme.primary
                                                  .withValues(alpha: 0.22),
                                              theme.colorScheme.primary
                                                  .withValues(alpha: 0.08),
                                            ],
                                          ),
                                        ),
                                        child: Icon(
                                          slide.icon,
                                          size: 66,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 30),
                                      Text(
                                        slide.title,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                          color: const Color(0xFF13254B),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        slide.subtitle,
                                        textAlign: TextAlign.center,
                                        style:
                                            theme.textTheme.bodyLarge?.copyWith(
                                          color: const Color(0xFF4F628A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (index) {
                    final selected = _currentPage == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: selected ? 26 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withValues(alpha: 0.23),
                      ),
                    );
                  }),
                ),
                const Spacer(),
                NebulaPrimaryButton(
                  text: 'Iniciar sesion',
                  onPressed: _openLogin,
                ),
                const SizedBox(height: 12),
                NebulaSecondaryButton(
                  text: 'Crear cuenta',
                  onPressed: _openRegister,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
