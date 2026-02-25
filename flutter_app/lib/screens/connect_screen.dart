import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../controllers/app_controller.dart';
import 'home_screen.dart';
import 'package:lottie/lottie.dart';


enum GameDifficulty { easy, medium, hard }

class SoundItem {
  final String category;
  final String soundAsset;
  final String correctImage;

  SoundItem({
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
  State<ConnectSoundGameScreen> createState() =>
      _ConnectSoundGameScreenState();
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

  int? _selectedIndex;
  final Set<int> _disabledIndexes = {};

  bool _showFeedback = false;
  bool _isCorrectFeedback = false;
  bool _isFinishing = false;

  int _totalMistakes = 0;

  final List<String> _allImages = [
    'assets/images/conecta/perro.jpg',
    'assets/images/conecta/gato.jpg',
    'assets/images/conecta/pajaro.jpg',
    'assets/images/conecta/caballo.jpg',
    'assets/images/conecta/campana.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _activeItems = _buildActiveItems(widget.difficulty);
    _loadNextQuestion();
  }

  List<SoundItem> _loadCategorizedSoundItems(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return [
          SoundItem(
              category: 'animales',
              soundAsset: 'sounds/perro.mp3',
              correctImage: 'assets/images/conecta/perro.jpg'),
        ];
      case GameDifficulty.medium:
        return [
          SoundItem(
              category: 'objetos',
              soundAsset: 'sounds/perro.mp3',
              correctImage: 'assets/images/conecta/perro.jpg'),
        ];
      case GameDifficulty.hard:
        return [
          SoundItem(
              category: 'entorno',
              soundAsset: 'sounds/perro.mp3',
              correctImage: 'assets/images/conecta/perro.jpg'),
        ];
    }
  }

  List<SoundItem> _buildActiveItems(GameDifficulty difficulty) {
    final baseItems = [..._loadCategorizedSoundItems(difficulty)];
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
    final distractors = _allImages
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
    });
    Future.microtask(() => _playSound());
  }

  Future<void> _playSound() async {
  if (_currentItem == null) return;

  try {
    await _player.stop();
    await _player.play(
      AssetSource(_currentItem!.soundAsset),
      volume: 1.0,
    );
  } catch (e) {
    debugPrint("Error reproduciendo sonido: $e");
  }
  }

  void _confirmSelection() async {
    if (_selectedIndex == null || _currentItem == null) return;

    if (_selectedIndex == _correctIndex) {
      setState(() {
        _showFeedback = true;
        _isCorrectFeedback = true;
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
        _loadNextQuestion();
      }
    } else {
      setState(() {
        _disabledIndexes.add(_selectedIndex!);
        _selectedIndex = null;
        _showFeedback = true;
        _isCorrectFeedback = false;
        _totalMistakes++;
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
    if (_isFinishing) return;
    _isFinishing = true;

    int baseStars;

    if (_totalMistakes == 0) {
      baseStars = 20;
    } else if (_totalMistakes <= 3) {
      baseStars = 15;
    } else {
      baseStars = 10;
    }

    int difficultyBonus = switch (widget.difficulty) {
      GameDifficulty.easy => 0,
      GameDifficulty.medium => 5,
      GameDifficulty.hard => 10,
    };

    final total = baseStars + difficultyBonus;

    try {
      await widget.controller.addStars(total).timeout(const Duration(seconds: 2));
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
              "Ganaste $baseStars estrellas ⭐",
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

  @override
Widget build(BuildContext context) {
  final options = _currentOptions;

  return Scaffold(
    appBar: AppBar(
      title: const Text('Conecta el sonido'),
    ),
    body: Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

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
                      borderRadius:
                          BorderRadius.circular(16),
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
                  final isDisabled =
                      _disabledIndexes.contains(index);
                  final isSelected =
                      _selectedIndex == index;

                  return Material(
                    color: isDisabled
                        ? Colors.grey.shade300
                        : isSelected
                            ? widget.controller.accentColor
                            : widget.controller.accentColor
                                .withAlpha(
                                    (0.55 * 255).toInt()),
                    borderRadius:
                        BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(14),
                      onTap: isDisabled
                          ? null
                          : () {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                      child: Padding(
                        padding:
                            const EdgeInsets.all(12),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(10),
                          child: Image.asset(
                            options[index],
                            fit: BoxFit.cover,
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
                backgroundColor:
                    widget.controller.accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
              onPressed:
                  _selectedIndex == null || _isFinishing ? null : _confirmSelection,
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
  );
}
}
