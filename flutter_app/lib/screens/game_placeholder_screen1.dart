import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../controllers/app_controller.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/nebula_button.dart';

class GamePlaceholderScreen extends StatefulWidget {
  const GamePlaceholderScreen({
    super.key,
    required this.controller,
    required this.gameName,
    required this.gameKey,
    required this.difficultyStars,
  });

  final AppController controller;
  final String gameName;
  final String gameKey;
  final int difficultyStars;

  @override
  State<GamePlaceholderScreen> createState() => _GamePlaceholderScreenState();
}

class _GamePlaceholderScreenState extends State<GamePlaceholderScreen> {
  final DateTime _startedAt = DateTime.now();
  bool _completing = false;

  int _starsForDifficulty(int stars) {
    return widget.controller.starsRewardForGame(
      gameKey: widget.gameKey,
      difficultyStars: stars,
      mistakes: 0,
    );
  }

  Future<void> _completeGame() async {
    if (_completing) return;
    setState(() => _completing = true);

    try {
      final earnedStars = _starsForDifficulty(widget.difficultyStars);
      await widget.controller.addStars(earnedStars);
      await widget.controller.recordGameSession(
        gameKey: widget.gameKey,
        startedAt: _startedAt,
        endedAt: DateTime.now(),
        difficultyStars: widget.difficultyStars,
        rounds: 5,
        mistakes: 0,
        pointsEarned: earnedStars,
        correctAnswers: 5,
        totalAttempts: 5,
      );

      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          backgroundColor: const Color.fromARGB(255, 211, 237, 213),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ganaste $earnedStars estrellas ⭐',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
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
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _completing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: Text(widget.gameName),
      ),
      body: CosmicBackground(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reto elegido',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(
                          widget.difficultyStars,
                          (_) => const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.star, color: Colors.amber),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Narrador activo: ${widget.controller.selectedNarratorId}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Muy bien. Este espacio queda listo para conectar la logica real del minijuego.',
              ),
              const Spacer(),
              NebulaPrimaryButton(
                text: _completing
                    ? 'Completando...'
                    : 'Completar reto (+${_starsForDifficulty(widget.difficultyStars)} estrellas)',
                onPressed: _completing ? null : _completeGame,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
