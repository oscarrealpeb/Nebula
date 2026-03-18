import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../controllers/app_controller.dart';
import '../services/narration_service.dart';
import 'home_screen.dart';
import 'package:lottie/lottie.dart';

enum GameDifficulty { easy, medium, hard }

class SoundItem {
  final String category;
  final String soundAsset;
  final String correctImage;
  final String itemId;

  SoundItem({
    this.itemId = '',
    required this.category,
    required this.soundAsset,
    required this.correctImage,
  });
}

class ConnectSoundGameScreen extends StatefulWidget {
  const ConnectSoundGameScreen({
    super.key,
    required this.controller,
    required this.difficulty,
  });

  final AppController controller;
  final GameDifficulty difficulty;

  @override
  State<ConnectSoundGameScreen> createState() => _ConnectSoundGameScreenState();
}

class _ConnectSoundGameScreenState extends State<ConnectSoundGameScreen> {
  static const int totalRounds = 5;
  final AudioPlayer _player = AudioPlayer();

  static final Map<GameDifficulty, List<SoundItem>> _reviewPoolByDifficulty = {
    GameDifficulty.easy: [],
    GameDifficulty.medium: [],
    GameDifficulty.hard: [],
  };

  late List<SoundItem> _activeItems;
  SoundItem? _currentItem;
  List<String> _currentOptions = [];
  int _correctIndex = -1;

  int _currentRound = 0;
  int _perfectRounds = 0;
  bool _roundHadMistake = false;

  int? _selectedIndex;
  final Set<int> _disabledIndexes = {};

  bool _showFeedback = false;
  bool _isCorrectFeedback = false;
  bool _isFinishing = false;

  int _totalMistakes = 0;
  final DateTime _startedAt = DateTime.now();
  bool _introNarrationQueued = false;

  static const List<String> _defaultImages = [
    'assets/images/conecta/arpa.jpg',
    'assets/images/conecta/ballena.jpg',
    'assets/images/conecta/buho.jpg',
    'assets/images/conecta/burro.jpg',
    'assets/images/conecta/caballo.jpg',
    'assets/images/conecta/delfin.jpg',
    'assets/images/conecta/elefante.jpg',
    'assets/images/conecta/gallo.jpg',
    'assets/images/conecta/gato.jpg',
    'assets/images/conecta/grillo.jpg',
    'assets/images/conecta/guitarra.jpg',
    'assets/images/conecta/pato.jpg',
    'assets/images/conecta/perro.jpg',
    'assets/images/conecta/piano.jpg',
    'assets/images/conecta/vaca.jpg',
    'assets/images/conecta/violin.jpg',
    'assets/images/conecta/olas.jpg',
    'assets/images/conecta/aspiradora.jpg',
    'assets/images/conecta/microondas.jpg',
    'assets/images/conecta/puerta.jpg',
    'assets/images/conecta/bebe.jpg',
    'assets/images/conecta/aplausos.jpg',
    'assets/images/conecta/claxon.jpg',
    'assets/images/conecta/centro_comercial.jpg',
    'assets/images/conecta/restaurante.jpg',
    'assets/images/conecta/niños.jpg',
    'assets/images/conecta/tormenta.jpg',
    'assets/images/conecta/coro.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _activeItems = _buildActiveItems(widget.difficulty);
    _loadNextQuestion();
    _queueIntroNarrationAfterFirstSound();
  }

  void _queueIntroNarrationAfterFirstSound() {
    if (_introNarrationQueued) return;
    _introNarrationQueued = true;
    Future.microtask(() async {
      if (!widget.controller.soundEffectsEnabled) return;
      try {
        await _player.onPlayerComplete.first;
      } catch (_) {
        return;
      }
      if (!mounted) return;
      await NarrationService.instance.play(
        widget.controller,
        key: 'connect_intro',
      );
    });
  }

  List<SoundItem> _loadCategorizedSoundItems(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return [
          SoundItem(
              category: 'animales',
              soundAsset: 'sounds/arpa.mp3',
              correctImage: 'assets/images/conecta/arpa.jpg'),
          SoundItem(
              category: 'animales',
              soundAsset: 'sounds/ballena.mp3',
              correctImage: 'assets/images/conecta/ballena.jpg'),
          SoundItem(
              category: 'animales',
              soundAsset: 'sounds/buho.mp3',
              correctImage: 'assets/images/conecta/buho.jpg'),
          SoundItem(
              category: 'animales',
              soundAsset: 'sounds/burro.mp3',
              correctImage: 'assets/images/conecta/burro.jpg'),
          SoundItem(
              category: 'animales',
              soundAsset: 'sounds/caballo.mp3',
              correctImage: 'assets/images/conecta/caballo.jpg'),
          SoundItem(
              category: 'animales',
              soundAsset: 'sounds/delfin.mp3',
              correctImage: 'assets/images/conecta/delfin.jpg'),
          SoundItem(
              category: 'animales',
              soundAsset: 'sounds/elefante.mp3',
              correctImage: 'assets/images/conecta/elefante.jpg'),
          SoundItem(
              category: 'animales',
              soundAsset: 'sounds/gallo.mp3',
              correctImage: 'assets/images/conecta/gallo.jpg'),
          SoundItem(
              category: 'animales',
              soundAsset: 'sounds/gato.mp3',
              correctImage: 'assets/images/conecta/gato.jpg'),
          SoundItem(
              category: 'animales',
              soundAsset: 'sounds/grillo.mp3',
              correctImage: 'assets/images/conecta/grillo.jpg'),
          SoundItem(
              category: 'animales',
              soundAsset: 'sounds/guitarra.mp3',
              correctImage: 'assets/images/conecta/guitarra.jpg'),
          SoundItem(
              category: 'animales',
              soundAsset: 'sounds/pato.mp3',
              correctImage: 'assets/images/conecta/pato.jpg'),
          SoundItem(
              category: 'animales',
              soundAsset: 'sounds/perro.mp3',
              correctImage: 'assets/images/conecta/perro.jpg'),
          SoundItem(
              category: 'animales',
              soundAsset: 'sounds/piano.mp3',
              correctImage: 'assets/images/conecta/piano.jpg'),
          SoundItem(
              category: 'animales',
              soundAsset: 'sounds/vaca.mp3',
              correctImage: 'assets/images/conecta/vaca.jpg'),
          SoundItem(
              category: 'animales',
              soundAsset: 'sounds/violin.mp3',
              correctImage: 'assets/images/conecta/violin.jpg'),
        ];
      case GameDifficulty.medium:
        return [
          SoundItem(
              category: 'objetos',
              soundAsset: 'sounds/olas.mp3',
              correctImage: 'assets/images/conecta/olas.jpg'),
          SoundItem(
              category: 'objetos',
              soundAsset: 'sounds/aspiradora.mp3',
              correctImage: 'assets/images/conecta/aspiradora.jpg'),
          SoundItem(
              category: 'objetos',
              soundAsset: 'sounds/microondas.mp3',
              correctImage: 'assets/images/conecta/microondas.jpg'),
          SoundItem(
              category: 'objetos',
              soundAsset: 'sounds/puerta.mp3',
              correctImage: 'assets/images/conecta/puerta.jpg'),
          SoundItem(
              category: 'objetos',
              soundAsset: 'sounds/bebe.mp3',
              correctImage: 'assets/images/conecta/bebe.jpg'),
          SoundItem(
              category: 'objetos',
              soundAsset: 'sounds/aplausos.mp3',
              correctImage: 'assets/images/conecta/aplausos.jpg'),
          SoundItem(
              category: 'objetos',
              soundAsset: 'sounds/claxon.mp3',
              correctImage: 'assets/images/conecta/claxon.jpg'),
        ];
      case GameDifficulty.hard:
        return [
          SoundItem(
              category: 'objetos',
              soundAsset: 'sounds/niños.mp3',
              correctImage: 'assets/images/conecta/niños.jpg'),
          SoundItem(
              category: 'objetos',
              soundAsset: 'sounds/restaurante.mp3',
              correctImage: 'assets/images/conecta/restaurante.jpg'),
          SoundItem(
              category: 'objetos',
              soundAsset: 'sounds/centro_comercial.mp3',
              correctImage: 'assets/images/conecta/centro_comercial.jpg'),
          SoundItem(
              category: 'objetos',
              soundAsset: 'sounds/tormenta.mp3',
              correctImage: 'assets/images/conecta/tormenta.jpg'),
          SoundItem(
              category: 'objetos',
              soundAsset: 'sounds/coro.mp3',
              correctImage: 'assets/images/conecta/coro.jpg'),
        ];
    }
  }

  List<SoundItem> _buildActiveItems(GameDifficulty difficulty) {
    final baseItems = _itemsForDifficulty(difficulty);
    final reviewPool = _reviewPoolByDifficulty[difficulty]!;

    if (reviewPool.isNotEmpty) {
      baseItems.insertAll(0, reviewPool);
    }

    baseItems.shuffle();

    if (baseItems.isEmpty) {
      throw StateError('No hay elementos de sonido configurados.');
    }

    while (baseItems.length < totalRounds) {
      final refill = [...baseItems]..shuffle();
      baseItems.addAll(refill);
    }

    return baseItems;
  }

  void _loadNextQuestion() {
    if (_currentRound >= totalRounds) {
      _finishGame();
      return;
    }

    _currentItem = _activeItems[_currentRound % _activeItems.length];

    final options = <String>[_currentItem!.correctImage];
    final distractors = _imagePoolForOptions()
        .where((img) => img != _currentItem!.correctImage)
        .toList()
      ..shuffle();
    options.addAll(distractors.take(3));
    options.shuffle();

    setState(() {
      _currentOptions = options;
      _correctIndex = options.indexOf(_currentItem!.correctImage);
      _selectedIndex = null;
      _disabledIndexes.clear();
      _showFeedback = false;
      _roundHadMistake = false;
    });
    Future.microtask(() => _playSound());
  }

  Future<void> _playSound() async {
    if (_currentItem == null) return;

    try {
      await _player.stop();
      await _player.play(
        _audioSourceFor(_currentItem!.soundAsset),
        volume: 1.0,
      );
    } catch (e) {
      debugPrint("Error reproduciendo sonido: $e");
    }
  }

  int _difficultyStars(GameDifficulty difficulty) {
    return switch (difficulty) {
      GameDifficulty.easy => 1,
      GameDifficulty.medium => 2,
      GameDifficulty.hard => 3,
    };
  }

  List<SoundItem> _customSoundItemsForDifficulty(GameDifficulty difficulty) {
    final stars = _difficultyStars(difficulty);
    return widget.controller.gameContentConfig.soundItems
        .where(
          (item) =>
              item.enabled &&
              item.difficultyStars == stars &&
              item.soundAsset.trim().isNotEmpty &&
              item.correctImage.trim().isNotEmpty,
        )
        .map(
          (item) => SoundItem(
            itemId: widget.controller.customContentItemId(
              source: item.correctImage.trim(),
              rawId: item.id,
            ),
            category: item.category.trim().isEmpty
                ? 'personalizado'
                : item.category.trim(),
            soundAsset: item.soundAsset.trim(),
            correctImage: item.correctImage.trim(),
          ),
        )
        .toList();
  }

  SoundItem _resolvedSoundItem(SoundItem item) {
    final itemId = item.itemId.trim().isNotEmpty
        ? item.itemId
        : widget.controller.customContentItemId(source: item.correctImage);
    final resolvedImage = widget.controller.resolvedGameImageSourceFor(
      gameKey: 'sonidos',
      itemId: itemId,
      defaultSource: item.correctImage,
    );
    return SoundItem(
      itemId: itemId,
      category: item.category,
      soundAsset: item.soundAsset,
      correctImage: resolvedImage,
    );
  }

  List<SoundItem> _itemsForDifficulty(GameDifficulty difficulty) {
    final defaults = _loadCategorizedSoundItems(difficulty);
    final custom = _customSoundItemsForDifficulty(difficulty);
    if (custom.isEmpty) return defaults.map(_resolvedSoundItem).toList();

    final merged = <SoundItem>[...custom];
    for (final item in defaults) {
      final exists = merged.any(
        (candidate) =>
            candidate.soundAsset == item.soundAsset &&
            candidate.correctImage == item.correctImage,
      );
      if (!exists) {
        merged.add(item);
      }
    }
    return merged.map(_resolvedSoundItem).toList();
  }

  List<String> _imagePoolForOptions() {
    final pool = <String>{
      ..._defaultImages.map(
        (source) => widget.controller.resolvedGameImageSourceFor(
          gameKey: 'sonidos',
          itemId: widget.controller.customContentItemId(source: source),
          defaultSource: source,
        ),
      ),
      ..._activeItems.map((item) => item.correctImage.trim()),
    }.where((item) => item.isNotEmpty).toList();
    return pool;
  }

  Source _audioSourceFor(String rawPath) {
    final path = rawPath.trim();
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return UrlSource(path);
    }
    final looksAbsoluteWindows = RegExp(r'^[a-zA-Z]:\\').hasMatch(path);
    final looksAbsoluteUnix = path.startsWith('/');
    final looksUnc = path.startsWith(r'\\');
    if (looksAbsoluteWindows || looksAbsoluteUnix || looksUnc) {
      return DeviceFileSource(path);
    }
    final normalizedAsset =
        path.startsWith('assets/') ? path.substring('assets/'.length) : path;
    return AssetSource(normalizedAsset);
  }

  ImageProvider _imageProviderFor(String path) {
    final normalized = path.trim();
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return NetworkImage(normalized);
    }
    if (normalized.startsWith('assets/')) {
      return AssetImage(normalized);
    }
    if (normalized.isNotEmpty && File(normalized).existsSync()) {
      return FileImage(File(normalized));
    }
    return AssetImage(normalized);
  }

  void _confirmSelection() async {
    if (_selectedIndex == null || _currentItem == null) return;

    if (_selectedIndex == _correctIndex) {
      if (!_roundHadMistake) {
        _perfectRounds++;
      }
      setState(() {
        _showFeedback = true;
        _isCorrectFeedback = true;
        _isFinishing = true; // 🔒 bloquear confirmar temporalmente
      });

      await Future.delayed(const Duration(milliseconds: 700));

      final reviewPool = _reviewPoolByDifficulty[widget.difficulty]!;
      reviewPool.removeWhere((item) =>
          item.soundAsset == _currentItem!.soundAsset &&
          item.correctImage == _currentItem!.correctImage);

      _currentRound++;
      if (_currentRound >= totalRounds) {
        await _finishGame();
      } else {
        _isFinishing = false; // 🔓 desbloquear para la siguiente ronda
        _loadNextQuestion();
      }
    } else {
      setState(() {
        _disabledIndexes.add(_selectedIndex!);
        _selectedIndex = null;
        _showFeedback = true;
        _isCorrectFeedback = false;
        _totalMistakes++;
        _roundHadMistake = true;
      });

      final reviewPool = _reviewPoolByDifficulty[widget.difficulty]!;
      final alreadyInPool = reviewPool.any((item) =>
          item.soundAsset == _currentItem!.soundAsset &&
          item.correctImage == _currentItem!.correctImage);
      if (!alreadyInPool) {
        reviewPool.add(_currentItem!);
      }
    }
  }

  Future<void> _finishGame() async {
    // if (_isFinishing) return;
    _isFinishing = true;

    int difficultyBonus = switch (widget.difficulty) {
      GameDifficulty.easy => 20,
      GameDifficulty.medium => 25,
      GameDifficulty.hard => 30,
    };
    final penalty = _totalMistakes > 3 ? 10 : 0;
    final total = (difficultyBonus - penalty).clamp(0, 30).toInt();

    try {
      await widget.controller
          .addStars(total)
          .timeout(const Duration(seconds: 2));
    } catch (_) {}

    try {
      final difficultyStars = switch (widget.difficulty) {
        GameDifficulty.easy => 1,
        GameDifficulty.medium => 2,
        GameDifficulty.hard => 3,
      };
      await widget.controller.recordGameSession(
        gameKey: 'conecta_sonidos',
        startedAt: _startedAt,
        endedAt: DateTime.now(),
        difficultyStars: difficultyStars,
        rounds: totalRounds,
        mistakes: _totalMistakes,
        pointsEarned: total,
        correctAnswers: totalRounds,
        totalAttempts: totalRounds + _totalMistakes,
        perfectRounds: _perfectRounds,
      );
    } catch (_) {}

    await _player.stop();

    if (!mounted) return;

    showDialog(
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
                "Ganaste $total estrellas ⭐",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 18),

              /// ✨ ANIMACIÓN ESTRELLAS
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

    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomeScreen(controller: widget.controller),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_isFinishing) return false;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "¿Salir del juego?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Si sales ahora, perderás tus estrellas⭐.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade300,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await _player.stop(); // 🔊 detenemos audio
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text(
              "Salir",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  Widget _buildRoundProgress() {
    return Row(
      children: List.generate(totalRounds, (index) {
        final isCompleted = index <= _currentRound;
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: index == totalRounds - 1 ? 0 : 8),
            decoration: BoxDecoration(
              color: isCompleted
                  ? widget.controller.accentColor
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = _currentOptions;

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _onWillPop();
        if (!mounted || !shouldExit) return;
        Navigator.of(this.context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Conecta el sonido'),
        ),
        body: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildRoundProgress(),
              const SizedBox(height: 12),

              /// 🔹 TÍTULO SUPERIOR
              const Text(
                "Escucha el sonido",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              /// 🔊 BOTÓN DE AUDIO MÁS PEQUEÑO
              Center(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: _playSound,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: widget.controller.accentColor
                          .withAlpha((0.15 * 255).toInt()),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: widget.controller.accentColor,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.volume_up_rounded,
                      size: 55,
                      color: widget.controller.accentColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// 🔹 PREGUNTA
              const Text(
                "¿A quién pertenece este sonido?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              /// 🔹 FEEDBACK (ESPACIO RESERVADO)
              SizedBox(
                height: 40,
                child: _showFeedback
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 20),
                        decoration: BoxDecoration(
                          color: _isCorrectFeedback
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            _isCorrectFeedback
                                ? "¡Muy bien!"
                                : "¡Casi, prueba de nuevo!",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isCorrectFeedback
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(),
              ),

              const SizedBox(height: 10),

              /// 🔹 GRID 2x2 (NO TOCADO)
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                  children: List.generate(
                    options.length,
                    (index) {
                      final isDisabled = _disabledIndexes.contains(index);
                      final isSelected = _selectedIndex == index;

                      return Material(
                        color: isDisabled
                            ? Colors.grey.shade300
                            : isSelected
                                ? widget.controller.accentColor
                                : widget.controller.accentColor
                                    .withAlpha((0.55 * 255).toInt()),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: isDisabled
                              ? null
                              : () {
                                  setState(() {
                                    _selectedIndex = index;
                                  });
                                },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image(
                                image: _imageProviderFor(options[index]),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.broken_image_outlined),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              /// 🔹 BOTÓN CONFIRMAR
              SizedBox(
                width: 220,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.controller.accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _selectedIndex == null || _isFinishing
                      ? null
                      : _confirmSelection,
                  child: const Text(
                    'Confirmar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
