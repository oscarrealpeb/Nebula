import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/nebula_button.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _navigating = false;

  final _slides = const [
    (
      icon: Icons.rocket_launch_rounded,
      title: '¡Aprende jugando!',
      subtitle:
          'Descubre habilidades nuevas con actividades cortas y divertidas.',
    ),
    (
      icon: Icons.sentiment_satisfied_alt_rounded,
      title: '¡Entiende emociones!',
      subtitle: 'Reconoce caritas y sentimientos con apoyo visual súper claro.',
    ),
    (
      icon: Icons.stars_rounded,
      title: '¡Suma estrellas!',
      subtitle: 'Cada logro te lleva a planetas nuevos y premios geniales.',
    ),
    (
      icon: Icons.family_restroom_rounded,
      title: '¡Acompaña en familia!',
      subtitle: 'Una experiencia amable para niños, padres y terapeutas.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openLogin() async {
    if (_navigating || !mounted) return;
    _navigating = true;
    final navigator = Navigator.of(context);
    try {
      FocusScope.of(context).unfocus();
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => LoginScreen(controller: widget.controller),
        ),
      );
    } finally {
      _navigating = false;
    }
  }

  Future<void> _openRegister() async {
    if (_navigating || !mounted) return;
    _navigating = true;
    final navigator = Navigator.of(context);
    try {
      FocusScope.of(context).unfocus();
      await navigator.push(
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
                const SizedBox(height: 10),
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
                        return Padding(
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
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: const Color(0xFF13254B),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                slide.subtitle,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: const Color(0xFF4F628A),
                                ),
                              ),
                            ],
                          ),
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
                  text: '¡Quiero entrar!',
                  onPressed: _openLogin,
                ),
                const SizedBox(height: 12),
                NebulaSecondaryButton(
                  text: '¡Crear mi cuenta!',
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
