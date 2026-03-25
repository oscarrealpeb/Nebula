import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../controllers/app_controller.dart';
import '../controllers/puzzle_controller.dart';
import '../services/narration_service.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/puzzle/puzzle_board.dart';
import '../widgets/puzzle_image_adapter.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({
    super.key,
    required this.controller,
    required this.stars,
  });

  final AppController controller;
  final int stars;

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  late final PuzzleController _puzzleController;
  late int _selectedStars;
  late DateTime _startedAt;

  bool _dialogOpen = false;
  bool _sessionRecorded = false;
  int _lastEarnedStars = 0;

  @override
  void initState() {
    super.initState();
    _selectedStars = widget.stars.clamp(1, 3).toInt();
    _startedAt = DateTime.now();
    _puzzleController = PuzzleController(
      imageSources: widget.controller.puzzleImageSources,
    )..addListener(_onPuzzleChanged);
    _puzzleController.generatePuzzle(_selectedStars);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NarrationService.instance.play(
        widget.controller,
        key: 'puzzle_intro',
      );
    });
  }

  @override
  void dispose() {
    _puzzleController.removeListener(_onPuzzleChanged);
    _puzzleController.dispose();
    super.dispose();
  }

  void _onPuzzleChanged() {
    if (!mounted) return;
    setState(() {});
    if (_puzzleController.isSolved && !_dialogOpen) {
      _handleSolvedPuzzle();
    }
  }

  Future<void> _handleSolvedPuzzle() async {
    _dialogOpen = true;
    try {
      if (!_sessionRecorded) {
        await _saveSessionAndReward();
      }
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
                  'Ganaste $_lastEarnedStars estrellas ⭐',
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
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
        return;
      }
      _startPuzzle(_selectedStars);
    } finally {
      _dialogOpen = false;
    }
  }

  Future<void> _saveSessionAndReward() async {
    _sessionRecorded = true;
    final rounds = max(1, (_selectedStars + 1) * (_selectedStars + 1) - 1);
    final mistakes = max(0, _puzzleController.moves - rounds);
    final earned = _rewardForDifficulty(_selectedStars);

    _lastEarnedStars = earned;

    await widget.controller.addStars(earned);
    await widget.controller.recordGameSession(
      gameKey: 'arma_imagen',
      startedAt: _startedAt,
      endedAt: DateTime.now(),
      difficultyStars: _selectedStars,
      rounds: rounds,
      mistakes: mistakes,
      pointsEarned: earned,
      correctAnswers: rounds,
      totalAttempts: rounds + mistakes,
      perfectRounds: mistakes == 0 ? 1 : 0,
    );
  }

  int _rewardForDifficulty(int stars) {
    return widget.controller.starsRewardForGame(
      gameKey: 'arma_imagen',
      difficultyStars: stars,
      mistakes: 0,
    );
  }

  void _startPuzzle(int stars) {
    setState(() {
      _selectedStars = stars.clamp(1, 3).toInt();
      _startedAt = DateTime.now();
      _sessionRecorded = false;
      _lastEarnedStars = 0;
    });
    _puzzleController.setImageSources(widget.controller.puzzleImageSources);
    _puzzleController.generatePuzzle(_selectedStars);
  }

  @override
  Widget build(BuildContext context) {
    final imageSource = _puzzleController.puzzleImageSource ?? '';
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('Arma la imagen'),
      ),
      body: CosmicBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dificultad',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text('$_selectedStars estrella(s)'),
                          const SizedBox(height: 8),
                          Text('Movimientos: ${_puzzleController.moves}'),
                          const SizedBox(height: 6),
                          const Text(
                            'Toca una ficha y luego otra para intercambiarlas.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (imageSource.isNotEmpty)
                      PuzzleImageAdapter(
                        imageSource: imageSource,
                        size: 84,
                        borderRadius: 10,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: PuzzleBoard(controller: _puzzleController),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _startPuzzle(_selectedStars),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reiniciar'),
            ),
          ],
        ),
      ),
    );
  }
}
