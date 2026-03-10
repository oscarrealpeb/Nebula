import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/nebula_button.dart';
import '../widgets/nebula_snack.dart';

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

  Future<void> _completeGame() async {
    if (_completing) return;
    setState(() => _completing = true);

    const earnedStars = 120;
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
    await NebulaSnack.show(
      context,
      message: 'Genial, ganaste $earnedStars estrellas.',
      ok: true,
    );
    if (!mounted) return;
    setState(() => _completing = false);
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
                    : 'Completar reto (+120 estrellas)',
                onPressed: _completing ? null : _completeGame,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
