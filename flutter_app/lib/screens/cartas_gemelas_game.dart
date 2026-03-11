import 'dart:math';

import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../widgets/cosmic_background.dart';

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
  static const List<String> _allImages = [
    'assets/images/cards/animales/abeja.png',
    'assets/images/cards/animales/ardilla.png',
    'assets/images/cards/animales/caballo.png',
    'assets/images/cards/animales/cabra.png',
    'assets/images/cards/animales/cobra.png',
    'assets/images/cards/animales/cocodrilo.png',
    'assets/images/cards/animales/elefante.png',
    'assets/images/cards/animales/ganso.png',
    'assets/images/cards/animales/gato.png',
    'assets/images/cards/animales/loro.png',
    'assets/images/cards/animales/oveja.png',
    'assets/images/cards/animales/perro.png',
    'assets/images/cards/animales/tigre.png',
    'assets/images/cards/animales/tortuga-marina.png',
    'assets/images/cards/animales/vaca.png',
    'assets/images/cards/frutas/cereza.png',
    'assets/images/cards/frutas/coco.png',
    'assets/images/cards/frutas/fresa.png',
    'assets/images/cards/frutas/kiwi-verde.png',
    'assets/images/cards/frutas/limon.png',
    'assets/images/cards/frutas/mango.png',
    'assets/images/cards/frutas/manzana.png',
    'assets/images/cards/frutas/maracuya.png',
    'assets/images/cards/frutas/naranja.png',
    'assets/images/cards/frutas/papaya.png',
    'assets/images/cards/frutas/pera.png',
    'assets/images/cards/frutas/pina.png',
    'assets/images/cards/frutas/platano.png',
    'assets/images/cards/frutas/sandia.png',
    'assets/images/cards/frutas/uva.png',
    'assets/images/cards/instrumentos/acordeon.png',
    'assets/images/cards/instrumentos/arpa.png',
    'assets/images/cards/instrumentos/bateria.png',
    'assets/images/cards/instrumentos/flauta.png',
    'assets/images/cards/instrumentos/guitarra-acustica.png',
    'assets/images/cards/instrumentos/guitarra-electrica.png',
    'assets/images/cards/instrumentos/maracas.png',
    'assets/images/cards/instrumentos/marimba.png',
    'assets/images/cards/instrumentos/pandereta.png',
    'assets/images/cards/instrumentos/piano.png',
    'assets/images/cards/instrumentos/platillo.png',
    'assets/images/cards/instrumentos/saxofono.png',
    'assets/images/cards/instrumentos/tambor.png',
    'assets/images/cards/instrumentos/trompeta.png',
    'assets/images/cards/instrumentos/violin.png',
    'assets/images/cards/transporte/autobus.png',
    'assets/images/cards/transporte/avion.png',
    'assets/images/cards/transporte/barco.png',
    'assets/images/cards/transporte/bicicleta.png',
    'assets/images/cards/transporte/carro-deportivo.png',
    'assets/images/cards/transporte/helicoptero.png',
    'assets/images/cards/transporte/moto.png',
    'assets/images/cards/transporte/submarino.png',
    'assets/images/cards/transporte/taxi.png',
    'assets/images/cards/transporte/tren.png',
  ];

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
  int _moves = 0;

  @override
  void initState() {
    super.initState();
    _difficultyStars = widget.difficultyStars.clamp(1, 3).toInt();
    _startNewGame();
  }

  void _startNewGame() {
    _startedAt = DateTime.now();
    _pairCount = _pairsForDifficulty(_difficultyStars);

    final images = List<String>.from(_allImages)..shuffle(_random);
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
    _moves = 0;
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

  int _starsReward(int stars) {
    switch (stars) {
      case 1:
        return 110;
      case 2:
        return 145;
      default:
        return 175;
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
    _moves += 1;

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
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excelente memoria'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Dificultad: $_difficultyStars estrella(s)'),
            const SizedBox(height: 6),
            Text('Movimientos: $_moves'),
            const SizedBox(height: 6),
            Text('Errores: $_mistakes'),
            const SizedBox(height: 6),
            Text('Ganaste $earned estrellas'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _startNewGame();
            },
            child: const Text('Jugar de nuevo'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() {
      _finishing = false;
    });
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
            const SizedBox(height: 4),
            Text(
              'Errores: $_mistakes   |   Movimientos: $_moves',
              style: Theme.of(context).textTheme.bodyMedium,
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
                                  ? Image.asset(
                                      _cards[index],
                                      fit: BoxFit.contain,
                                    )
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
