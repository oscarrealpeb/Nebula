import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../widgets/cosmic_background.dart';
//import '../widgets/nebula_button.dart';
import '../widgets/nebula_snack.dart';
import 'cartas_gemelas_game.dart';

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

    int earnedStars;

    if (widget.difficultyStars == 1) {
      earnedStars = 20;
    } else if (widget.difficultyStars == 2) {
      earnedStars = 25;
    } else {
      earnedStars = 30;
    }
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
      duration: const Duration(milliseconds: 900),
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    
    if (!mounted) return;
    setState(() => _completing = false);
  }

  Future<bool> _onWillPop() async {
    if (_completing) return false;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '¿Salir del juego?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Si sales ahora, perderás el progreso de esta partida.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Salir',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }


  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _onWillPop();
        if (!mounted || !shouldExit) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () async {
            final shouldExit = await _onWillPop();
            if (shouldExit) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(widget.gameName),
      ),
      body: CosmicBackground(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /*Card(
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
              const SizedBox(height: 16),*/
if (widget.gameKey == 'cartas_gemelas')
  Expanded(
    child: CartasGemelasGame(
      controller: widget.controller,
      difficultyStars: widget.difficultyStars,
      onGameCompleted: _completeGame,
    ),
  )
else
  const Expanded(
    child: Center(
      child: Text(
        'Muy bien. Este espacio queda listo para conectar la lógica real del minijuego.',
      ),
    ),
  ),
              /*NebulaPrimaryButton(
                text: _completing
                    ? 'Completando...'
                    : 'Completar reto (+120 estrellas)',
                onPressed: _completing ? null : _completeGame,
              ),*/
            ],
          ),
        ),
      ),
    ));
  }
}
