import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../controllers/app_controller.dart';
import '../widgets/cosmic_background.dart';

class QueSigueScreen extends StatefulWidget {
  const QueSigueScreen({
    super.key,
    required this.controller,
    required this.difficultyStars,
  });

  final AppController controller;
  final int difficultyStars;

  @override
  State<QueSigueScreen> createState() => _QueSigueScreenState();
}

class _QueSigueScreenState extends State<QueSigueScreen> {
  final Random _random = Random();

  late DateTime _startedAt;
  late int _difficultyStars;
  late List<_Sequence> _allSequences;
  late List<_Sequence> _activeSequences;
  late List<_SeqToken> _visibleOptions;

  int _currentIndex = 0;
  int _mistakes = 0;
  int _attempts = 0;
  bool _finishing = false;
  bool _locked = false;
  bool _feedbackPositive = false;
  bool _showFeedback = false;
  String? _pressedOptionId;
  String? _selectedOptionId;

  @override
  void initState() {
    super.initState();
    _difficultyStars = widget.difficultyStars.clamp(1, 3).toInt();
    _allSequences = _sequencesForDifficulty(_difficultyStars);
    _activeSequences = _pickSequences(_allSequences);
    _startedAt = DateTime.now();
    _loadSequence(0);
  }

  void _loadSequence(int index) {
    final safeIndex = index.clamp(0, _activeSequences.length - 1);
    final sequence = _activeSequences[safeIndex];
    _currentIndex = safeIndex;
    _showFeedback = false;
    _feedbackPositive = false;
    _locked = false;
    _pressedOptionId = null;
    _selectedOptionId = null;
    _visibleOptions = List<_SeqToken>.from(sequence.options)
      ..shuffle(_random);
    setState(() {});
  }

  List<_Sequence> _pickSequences(List<_Sequence> source) {
    if (source.isEmpty) return const [];
    final copy = List<_Sequence>.from(source);
    copy.shuffle(_random);
    final count = min(5, copy.length);
    return copy.take(count).toList();
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

  Future<bool> _onWillPop() async {
    if (_finishing) return false;
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
          'Si sales ahora, perderás tus estrellas⭐.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade300,
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

  Future<void> _requestExit() async {
    final shouldExit = await _onWillPop();
    if (!mounted || !shouldExit) return;
    Navigator.of(context).pop();
  }

  Future<void> _handleOptionTap(_SeqToken selected) async {
    if (_finishing || _locked) return;
    final sequence = _activeSequences[_currentIndex];
    _attempts += 1;
    _selectedOptionId = selected.id;
    if (selected.id == sequence.answer.id) {
      _showFeedback = true;
      _feedbackPositive = true;
      _locked = true;
      setState(() {});
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      if (_currentIndex >= _activeSequences.length - 1) {
        await _finishGame();
      } else {
        _loadSequence(_currentIndex + 1);
      }
      return;
    }

    _mistakes += 1;
    _showFeedback = true;
    _feedbackPositive = false;
    setState(() {});
  }

  Future<void> _finishGame() async {
    if (_finishing) return;
    _finishing = true;

    final earned = _starsReward(_difficultyStars);
    final rounds = _activeSequences.length;
    final correct = _activeSequences.length;

    await widget.controller.addStars(earned);
    await widget.controller.recordGameSession(
      gameKey: 'que_sigue',
      startedAt: _startedAt,
      endedAt: DateTime.now(),
      difficultyStars: _difficultyStars,
      rounds: rounds,
      mistakes: _mistakes,
      pointsEarned: earned,
      correctAnswers: correct,
      totalAttempts: _attempts,
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
                'Ganaste $earned estrellas',
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.controller.accentColor;
    final fill = accent.withValues(alpha: 0.12);
    final sequence = _activeSequences[_currentIndex];
    final sizeProfile = _sizeProfileForDifficulty(_difficultyStars);

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
          leading: BackButton(onPressed: _requestExit),
          title: Text(widget.controller.gameLabelForKey('que_sigue')),
        ),
        body: CosmicBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Completa la secuencia',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                  ),
                const SizedBox(height: 6),
                Text(
                  'Secuencia ${_currentIndex + 1} de ${_activeSequences.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF617298),
                      ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    runAlignment: WrapAlignment.center,
                    children: [
                      ...sequence.pattern.map(
                        (token) => _TokenCard(
                          assets: token.assets,
                          borderColor: accent,
                          fillColor: fill,
                          imageSize: sizeProfile.sequenceImageSize,
                          height: sizeProfile.sequenceCardHeight,
                          width: _cardWidthForAssets(
                            token.assets.length,
                            sizeProfile.sequenceImageSize,
                            basePadding: sizeProfile.sequencePadding,
                          ),
                        ),
                      ),
                      _TokenCard(
                        assets: const [],
                        borderColor: accent,
                        fillColor: fill,
                        imageSize: sizeProfile.sequenceImageSize,
                        height: sizeProfile.sequenceCardHeight,
                        width: sizeProfile.sequenceCardHeight,
                        overrideChild: Text(
                          '?',
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '¿Qué sigue?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1F2A44),
                        fontSize: 26,
                      ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            runAlignment: WrapAlignment.center,
                            children: _visibleOptions.map((option) {
                              final isPressed = _pressedOptionId == option.id;
                              final isSelected = _selectedOptionId == option.id;
                              final width =
                                  _cardWidthForAssets(
                                    option.assets.length,
                                    sizeProfile.optionImageSize,
                                    basePadding: sizeProfile.optionPadding,
                                  );
                              final baseFill = fill;
                              final selectedFill =
                                  accent.withValues(alpha: 0.30);
                              final pressedFill =
                                  accent.withValues(alpha: 0.38);
                              return GestureDetector(
                                onTapDown: (_) =>
                                    setState(() => _pressedOptionId = option.id),
                                onTapUp: (_) =>
                                    setState(() => _pressedOptionId = null),
                                onTapCancel: () =>
                                    setState(() => _pressedOptionId = null),
                                onTap: () => _handleOptionTap(option),
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 120),
                                  scale: isPressed ? 0.96 : 1,
                                  child: _TokenCard(
                                    assets: option.assets,
                                    borderColor: accent,
                                    fillColor: isPressed
                                        ? pressedFill
                                        : isSelected
                                            ? selectedFill
                                            : baseFill,
                                    imageSize: sizeProfile.optionImageSize,
                                    height: sizeProfile.optionCardHeight,
                                    width: width,
                                    elevation: isPressed ? 0 : 3,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 40,
                          child: _showFeedback
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _feedbackPositive
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _feedbackPositive
                                          ? '¡Muy bien!'
                                          : '¡Casi, prueba de nuevo!',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _feedbackPositive
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

double _cardWidthForAssets(
  int assetCount,
  double imageSize, {
  double basePadding = 36,
}) {
  final perAsset = imageSize + 8;
  if (assetCount <= 1) return imageSize + basePadding;
  return (perAsset * assetCount) + basePadding;
}

class _TokenCard extends StatelessWidget {
  const _TokenCard({
    required this.assets,
    required this.borderColor,
    required this.fillColor,
    required this.imageSize,
    required this.height,
    required this.width,
    this.elevation = 0,
    this.overrideChild,
  });

  final List<String> assets;
  final Color borderColor;
  final Color fillColor;
  final double imageSize;
  final double height;
  final double width;
  final double elevation;
  final Widget? overrideChild;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Card(
        elevation: elevation,
        color: fillColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: borderColor,
            width: 2,
          ),
        ),
        child: Center(
          child: overrideChild ??
              _TokenAssetsRow(
                assets: assets,
                size: imageSize,
              ),
        ),
      ),
    );
  }
}

class _TokenAssetsRow extends StatelessWidget {
  const _TokenAssetsRow({
    required this.assets,
    required this.size,
  });

  final List<String> assets;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: assets
          .map(
            (asset) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Image.asset(
                asset,
                width: size,
                height: size,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.image_not_supported_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: size,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SeqToken {
  const _SeqToken({required this.id, required this.assets});

  final String id;
  final List<String> assets;
}

class _Sequence {
  const _Sequence({
    required this.pattern,
    required this.answer,
    required this.options,
  });

  final List<_SeqToken> pattern;
  final _SeqToken answer;
  final List<_SeqToken> options;
}

class _SizeProfile {
  const _SizeProfile({
    required this.sequenceImageSize,
    required this.sequenceCardHeight,
    required this.sequencePadding,
    required this.optionImageSize,
    required this.optionCardHeight,
    required this.optionPadding,
  });

  final double sequenceImageSize;
  final double sequenceCardHeight;
  final double sequencePadding;
  final double optionImageSize;
  final double optionCardHeight;
  final double optionPadding;
}

_SizeProfile _sizeProfileForDifficulty(int stars) {
  switch (stars) {
    case 1:
      return const _SizeProfile(
        sequenceImageSize: 50,
        sequenceCardHeight: 94,
        sequencePadding: 52,
        optionImageSize: 70,
        optionCardHeight: 118,
        optionPadding: 62,
      );
    case 2:
      return const _SizeProfile(
        sequenceImageSize: 46,
        sequenceCardHeight: 88,
        sequencePadding: 48,
        optionImageSize: 64,
        optionCardHeight: 110,
        optionPadding: 58,
      );
    default:
      return const _SizeProfile(
        sequenceImageSize: 38,
        sequenceCardHeight: 76,
        sequencePadding: 38,
        optionImageSize: 52,
        optionCardHeight: 92,
        optionPadding: 46,
      );
  }
}

const String _assetRoot = 'assets/secuencias/';

const Map<String, String> _assetById = {
  'perro': 'perro.png',
  'gato': 'gato.png',
  'pinguino': 'pinguino.png',
  'conejo': 'conejo.png',
  'oso': 'oso-panda.png',
  'manzana': 'manzana.png',
  'pina': 'pina.png',
  'uvas': 'racimo-de-uvas.png',
  'fresa': 'fresa.png',
  'naranja': 'naranja.png',
  'estrella': 'estrella.png',
  'corazon': 'corazón.png',
  'circulo_azul': 'circulo-azul.png',
  'circulo_amarillo': 'circulo-amarillo.png',
  'circulo_rojo': 'circulo-rojo.png',
  'cuadrado': 'cuadrado.png',
  'triangulo': 'triangulo.png',
};

_SeqToken _token(String id) {
  final asset = _assetById[id];
  if (asset == null) {
    throw ArgumentError('Token no definido: $id');
  }
  return _SeqToken(id: id, assets: ['$_assetRoot$asset']);
}

_SeqToken _combo(String id, List<String> parts) {
  final assets = <String>[];
  for (final part in parts) {
    final asset = _assetById[part];
    if (asset == null) {
      throw ArgumentError('Token no definido: $part');
    }
    assets.add('$_assetRoot$asset');
  }
  return _SeqToken(
    id: id,
    assets: assets,
  );
}

List<_Sequence> _sequencesForDifficulty(int stars) {
  final perro = _token('perro');
  final gato = _token('gato');
  final pinguino = _token('pinguino');
  final conejo = _token('conejo');
  final oso = _token('oso');
  final manzana = _token('manzana');
  final pina = _token('pina');
  final uvas = _token('uvas');
  final fresa = _token('fresa');
  final naranja = _token('naranja');
  final estrella = _token('estrella');
  final corazon = _token('corazon');
  final circuloAzul = _token('circulo_azul');
  final circuloAmarillo = _token('circulo_amarillo');
  final circuloRojo = _token('circulo_rojo');
  final cuadrado = _token('cuadrado');
  final triangulo = _token('triangulo');

  final rojoEstrella =
      _combo('rojo_estrella', ['circulo_rojo', 'estrella']);
  final rojoCorazon =
      _combo('rojo_corazon', ['circulo_rojo', 'corazon']);
  final azulCorazon =
      _combo('azul_corazon', ['circulo_azul', 'corazon']);
  final azulEstrella =
      _combo('azul_estrella', ['circulo_azul', 'estrella']);
  final amarilloTriangulo =
      _combo('amarillo_triangulo', ['circulo_amarillo', 'triangulo']);
  final amarilloEstrella =
      _combo('amarillo_estrella', ['circulo_amarillo', 'estrella']);
  final azulTriangulo =
      _combo('azul_triangulo', ['circulo_azul', 'triangulo']);
  final amarilloAzul =
      _combo('amarillo_azul', ['circulo_amarillo', 'circulo_azul']);

  if (stars == 1) {
    return [
      _Sequence(
        pattern: [perro, gato, perro, gato],
        answer: perro,
        options: [perro, gato, pinguino],
      ),
      _Sequence(
        pattern: [pinguino, conejo, pinguino, conejo],
        answer: pinguino,
        options: [pinguino, conejo, perro],
      ),
      _Sequence(
        pattern: [oso, perro, oso, perro],
        answer: oso,
        options: [oso, perro, gato],
      ),
      _Sequence(
        pattern: [manzana, pina, manzana, pina],
        answer: manzana,
        options: [manzana, pina, uvas],
      ),
      _Sequence(
        pattern: [uvas, fresa, uvas, fresa],
        answer: uvas,
        options: [uvas, fresa, manzana],
      ),
      _Sequence(
        pattern: [naranja, manzana, naranja, manzana],
        answer: naranja,
        options: [naranja, manzana, pina],
      ),
      _Sequence(
        pattern: [estrella, corazon, estrella, corazon],
        answer: estrella,
        options: [estrella, corazon, triangulo],
      ),
      _Sequence(
        pattern: [circuloAzul, cuadrado, circuloAzul, cuadrado],
        answer: circuloAzul,
        options: [circuloAzul, cuadrado, circuloAmarillo],
      ),
      _Sequence(
        pattern: [triangulo, estrella, triangulo, estrella],
        answer: triangulo,
        options: [triangulo, estrella, corazon],
      ),
      _Sequence(
        pattern: [corazon, circuloAzul, corazon, circuloAzul],
        answer: corazon,
        options: [corazon, circuloAzul, estrella],
      ),
    ];
  }

  if (stars == 2) {
    return [
      _Sequence(
        pattern: [perro, perro, gato, perro],
        answer: perro,
        options: [perro, gato, pinguino],
      ),
      _Sequence(
        pattern: [manzana, manzana, pina, manzana],
        answer: manzana,
        options: [manzana, pina, naranja],
      ),
      _Sequence(
        pattern: [estrella, estrella, corazon, estrella],
        answer: estrella,
        options: [estrella, corazon, triangulo],
      ),
      _Sequence(
        pattern: [perro, gato, gato, perro],
        answer: gato,
        options: [gato, perro, pinguino],
      ),
      _Sequence(
        pattern: [manzana, pina, pina, manzana],
        answer: pina,
        options: [pina, manzana, uvas],
      ),
      _Sequence(
        pattern: [circuloAzul, cuadrado, cuadrado, circuloAzul],
        answer: cuadrado,
        options: [cuadrado, circuloAzul, circuloAmarillo],
      ),
      _Sequence(
        pattern: [perro, perro, gato, perro, perro],
        answer: gato,
        options: [gato, perro, pinguino],
      ),
      _Sequence(
        pattern: [pinguino, pinguino, conejo, pinguino, pinguino],
        answer: conejo,
        options: [conejo, pinguino, gato],
      ),
      _Sequence(
        pattern: [oso, oso, perro, oso, oso],
        answer: perro,
        options: [perro, oso, pinguino],
      ),
      _Sequence(
        pattern: [manzana, manzana, pina, manzana, manzana],
        answer: pina,
        options: [pina, manzana, uvas],
      ),
    ];
  }

  return [
    _Sequence(
      pattern: [
        circuloRojo,
        estrella,
        circuloRojo,
        corazon,
        circuloRojo,
        estrella,
        circuloRojo,
        corazon,
      ],
      answer: rojoEstrella,
      options: [rojoEstrella, rojoCorazon],
    ),
    _Sequence(
      pattern: [
        circuloAzul,
        corazon,
        circuloAzul,
        estrella,
        circuloAzul,
        corazon,
      ],
      answer: azulEstrella,
      options: [azulCorazon, azulEstrella],
    ),
    _Sequence(
      pattern: [
        circuloAmarillo,
        triangulo,
        circuloAmarillo,
        estrella,
        circuloAmarillo,
        triangulo,
        circuloAmarillo,
        estrella,
      ],
      answer: amarilloTriangulo,
      options: [amarilloTriangulo, amarilloEstrella],
    ),
    _Sequence(
      pattern: [
        circuloAzul,
        corazon,
        circuloAzul,
        triangulo,
        circuloAzul,
        corazon,
      ],
      answer: azulTriangulo,
      options: [azulCorazon, azulTriangulo],
    ),
    _Sequence(
      pattern: [
        circuloAmarillo,
        estrella,
        circuloAmarillo,
        circuloAzul,
        circuloAmarillo,
        estrella,
      ],
      answer: amarilloAzul,
      options: [amarilloEstrella, amarilloAzul],
    ),
    _Sequence(
      pattern: [perro, gato, pinguino, perro, gato],
      answer: pinguino,
      options: [perro, gato, pinguino],
    ),
    _Sequence(
      pattern: [manzana, pina, uvas, manzana, pina],
      answer: uvas,
      options: [manzana, pina, uvas],
    ),
    _Sequence(
      pattern: [estrella, corazon, triangulo, estrella, corazon],
      answer: triangulo,
      options: [estrella, corazon, triangulo],
    ),
  ];
}
