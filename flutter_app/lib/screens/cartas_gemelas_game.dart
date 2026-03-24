import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../controllers/app_controller.dart';
import '../core/data/memory_catalog.dart';
import '../services/narration_service.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/puzzle_image_adapter.dart';

class CartasGemelasGame extends StatefulWidget {
  const CartasGemelasGame({
    super.key,
    required this.controller,
    required this.difficultyStars,
  });

  final AppController controller;
  final int difficultyStars;

  @override
  State<CartasGemelasGame> createState() => _CartasGemelasGameState();
}

class _CartasGemelasGameState extends State<CartasGemelasGame> {
  final _random = Random();

  late DateTime _startedAt;
  late int _difficultyStars;
  late int _pairCount;
  late List<String> _cards;
  late List<bool> _flipped;
  late List<bool> _matched;

  int? _firstIndex;
  int? _secondIndex;
  int? _pressedIndex;
  bool _canTap = true;
  bool _finishing = false;
  int _mistakes = 0;

  @override
  void initState() {
    super.initState();
    _difficultyStars = widget.difficultyStars.clamp(1, 3).toInt();
    _startNewGame();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NarrationService.instance.play(
        widget.controller,
        key: 'cartas_gemelas_intro',
      );
    });
  }

  void _startNewGame() {
    _startedAt = DateTime.now();
    _pairCount = _pairsForDifficulty(_difficultyStars);

    final images = _imagePool()..shuffle(_random);
    final selected = images.take(_pairCount).toList();
    _cards = [...selected, ...selected]..shuffle(_random);

    _flipped = List<bool>.filled(_cards.length, false);
    _matched = List<bool>.filled(_cards.length, false);
    _firstIndex = null;
    _secondIndex = null;
    _pressedIndex = null;
    _canTap = true;
    _finishing = false;
    _mistakes = 0;
    setState(() {});
  }

  int _pairsForDifficulty(int stars) {
    switch (stars) {
      case 1:
        return 3; // 6 cartas
      case 2:
        return 4; // 8 cartas
      default:
        return 5; // 10 cartas
    }
  }

  List<String> _imagePool() {
    final custom = widget.controller.gameContentConfig.memoryItems
        .where((item) => item.enabled && item.imagePath.trim().isNotEmpty)
        .map(
          (item) => widget.controller.resolvedGameImageSourceFor(
            gameKey: 'cartas_gemelas',
            itemId: item.imagePath.trim(),
            defaultSource: item.imagePath.trim(),
          ),
        )
        .toList();
    final defaults = defaultMemoryImageSources
        .map(
          (source) => widget.controller.resolvedGameImageSourceFor(
            gameKey: 'cartas_gemelas',
            itemId: source,
            defaultSource: source,
          ),
        )
        .toList();
    if (custom.isEmpty) return List<String>.from(defaults);
    final merged = <String>[...custom];
    for (final image in defaults) {
      if (!merged.contains(image)) {
        merged.add(image);
      }
    }
    return merged;
  }

  int _starsReward(int stars) {
    switch (stars) {
      case 1:
        return 20;
      case 2:
        return 25;
      default:
        return 30;
    }
  }

  Future<void> _tapCard(int index) async {
    if (_finishing || !_canTap) return;
    if (index < 0 || index >= _cards.length) return;
    if (_flipped[index] || _matched[index]) return;
    if (_firstIndex == index) return;

    setState(() {
      _flipped[index] = true;
    });

    if (_firstIndex == null) {
      _firstIndex = index;
      return;
    }

    _secondIndex = index;
    _canTap = false;

    final first = _firstIndex!;
    final second = _secondIndex!;
    if (_cards[first] == _cards[second]) {
      if (!mounted) return;
      setState(() {
        _matched[first] = true;
        _matched[second] = true;
      });
      _firstIndex = null;
      _secondIndex = null;
      _canTap = true;

      if (_matched.every((item) => item)) {
        _finishing = true;
        await Future<void>.delayed(const Duration(milliseconds: 350));
        await _finishGame();
      }
      return;
    }

    _mistakes += 1;
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;
    setState(() {
      _flipped[first] = false;
      _flipped[second] = false;
    });
    _firstIndex = null;
    _secondIndex = null;
    _canTap = true;
  }

  Future<void> _finishGame() async {
    final earned = _starsReward(_difficultyStars);
    final rounds = _pairCount;
    final correct = _pairCount;
    final attempts = correct + _mistakes;

    await widget.controller.addStars(earned);
    await widget.controller.recordGameSession(
      gameKey: 'cartas_gemelas',
      startedAt: _startedAt,
      endedAt: DateTime.now(),
      difficultyStars: _difficultyStars,
      rounds: rounds,
      mistakes: _mistakes,
      pointsEarned: earned,
      correctAnswers: correct,
      totalAttempts: attempts,
      perfectRounds: _mistakes == 0 ? 1 : 0,
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
                'Ganaste $earned estrellas ⭐',
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
    _finishing = false;
    _startNewGame();
  }

  @override
  Widget build(BuildContext context) {
    final childAspect = _difficultyStars == 1
        ? 0.90
        : _difficultyStars == 2
            ? 1.18
            : 1.55;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('Cartas gemelas'),
      ),
      body: CosmicBackground(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              'Encuentra las parejas iguales',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: widget.controller.accentColor,
                  ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: childAspect,
                ),
                itemCount: _cards.length,
                itemBuilder: (context, index) {
                  final visible = _flipped[index] || _matched[index];
                  return GestureDetector(
                    onTapDown: (_) => setState(() => _pressedIndex = index),
                    onTapUp: (_) => setState(() => _pressedIndex = null),
                    onTapCancel: () => setState(() => _pressedIndex = null),
                    onTap: () => _tapCard(index),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 120),
                      scale: _pressedIndex == index ? 0.93 : 1,
                      child: Card(
                        elevation: visible ? 2 : 8,
                        color: visible
                            ? Theme.of(context).colorScheme.surface
                            : Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            reverseDuration: Duration.zero,
                            transitionBuilder: (child, animation) {
                              final rotate =
                                  Tween(begin: pi, end: 0.0).animate(animation);
                              return AnimatedBuilder(
                                animation: rotate,
                                child: child,
                                builder: (context, child) {
                                  return Transform(
                                    transform: Matrix4.rotationY(rotate.value),
                                    alignment: Alignment.center,
                                    child: child,
                                  );
                                },
                              );
                            },
                            child: Container(
                              key: ValueKey(visible),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(12),
                              child: visible
                                  ? (puzzleImageProviderFromSource(
                                              _cards[index]) ==
                                          null
                                      ? Icon(
                                          Icons.broken_image_outlined,
                                          size: 42,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                        )
                                      : Image(
                                          image: puzzleImageProviderFromSource(
                                            _cards[index],
                                          )!,
                                          fit: BoxFit.contain,
                                        ))
                                  : Icon(
                                      Icons.auto_awesome,
                                      size: 42,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
