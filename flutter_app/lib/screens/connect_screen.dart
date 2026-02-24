// import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../controllers/app_controller.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/nebula_button.dart';

enum GameDifficulty { easy, medium, hard }

/// 🔊 Solo define sonido + imagen correcta
class SoundItem {
  final String soundAsset;
  final String correctImage;

  SoundItem({
    required this.soundAsset,
    required this.correctImage,
  });
}

/// 🎯 Pregunta generada dinámicamente
class SoundQuestion {
  final String soundAsset;
  final List<String> imageOptions;
  final int correctIndex;

  SoundQuestion({
    required this.soundAsset,
    required this.imageOptions,
    required this.correctIndex,
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
  final AudioPlayer _player = AudioPlayer();
  // final Random _random = Random();

  late List<SoundQuestion> _questions;
  int _currentRound = 0;

  int? _selectedIndex;
  Set<int> _disabledIndexes = {};

  bool _showFeedback = false;
  bool _isCorrectFeedback = false;

  int _totalMistakes = 0;

  /// 🖼️ Pool GLOBAL de imágenes
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
    _questions = _generateQuestions(widget.difficulty);
  }

  /// 🔥 Solo sonidos diferenciados por nivel
  List<SoundItem> _loadSoundItems(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return [
          SoundItem(
              soundAsset: 'assets/sounds/perro.mp3',
              correctImage: 'assets/images/conecta/perro.jpg'),
          // SoundItem(
          //     soundAsset: 'assets/sounds/cat.mp3',
          //     correctImage: 'assets/images/cat.png'),
        ];

      case GameDifficulty.medium:
        return [
          SoundItem(
              soundAsset: 'assets/sounds/door_knock.mp3',
              correctImage: 'assets/images/door.png'),
          SoundItem(
              soundAsset: 'assets/sounds/phone.mp3',
              correctImage: 'assets/images/phone.png'),
        ];

      case GameDifficulty.hard:
        return [
          SoundItem(
              soundAsset: 'assets/sounds/classroom.mp3',
              correctImage: 'assets/images/school.png'),
        ];
    }
  }

  /// 🧠 Generador automático de preguntas
  List<SoundQuestion> _generateQuestions(GameDifficulty difficulty) {
    final items = _loadSoundItems(difficulty)..shuffle();

    return items.take(5).map((item) {
      List<String> options = [];

      // Añadir correcta
      options.add(item.correctImage);

      // Filtrar distractores
      final distractors = _allImages
          .where((img) => img != item.correctImage)
          .toList()
        ..shuffle();

      options.addAll(distractors.take(4));

      options.shuffle();

      final correctIndex = options.indexOf(item.correctImage);

      return SoundQuestion(
        soundAsset: item.soundAsset,
        imageOptions: options,
        correctIndex: correctIndex,
      );
    }).toList();
  }

  Future<void> _playSound() async {
    await _player.stop();
    await _player.play(
        AssetSource(_questions[_currentRound].soundAsset));
  }

  void _confirmSelection() async {
    if (_selectedIndex == null) return;

    final question = _questions[_currentRound];

    if (_selectedIndex == question.correctIndex) {
      setState(() {
        _showFeedback = true;
        _isCorrectFeedback = true;
      });

      await Future.delayed(const Duration(milliseconds: 1000));

      if (_currentRound == _questions.length - 1) {
        _finishGame();
      } else {
        setState(() {
          _currentRound++;
          _selectedIndex = null;
          _disabledIndexes.clear();
          _showFeedback = false;
        });
      }
    } else {
      setState(() {
        _disabledIndexes.add(_selectedIndex!);
        _selectedIndex = null;
        _showFeedback = true;
        _isCorrectFeedback = false;
        _totalMistakes++;
      });
    }
  }

  Future<void> _finishGame() async {
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

    await widget.controller.addStars(total);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ganaste $total estrellas ⭐')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentRound];

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Ronda ${_currentRound + 1} de ${_questions.length}'),
      ),
      body: CosmicBackground(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                '¿A quién pertenece este sonido?',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      widget.controller.accentButtonColor,
                ),
                onPressed: _playSound,
                icon: const Icon(Icons.volume_up),
                label: const Text('Escuchar'),
              ),

              const SizedBox(height: 20),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(
                  question.imageOptions.length,
                  (index) {
                    final isDisabled =
                        _disabledIndexes.contains(index);
                    final isSelected =
                        _selectedIndex == index;

                    return GestureDetector(
                      onTap: isDisabled
                          ? null
                          : () {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                      child: Opacity(
                        opacity: isDisabled ? 0.4 : 1,
                        child: Card(
                          elevation: isSelected ? 6 : 2,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.all(14),
                            child: Image.asset(
                              question.imageOptions[index],
                              width: 70,
                              height: 70,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              if (_showFeedback)
                Container(
                  padding:
                      const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _isCorrectFeedback
                        ? Colors.green.shade200
                        : Colors.orange.shade200,
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isCorrectFeedback
                        ? '¡Muy bien!'
                        : 'Intentemos otra vez',
                    textAlign: TextAlign.center,
                  ),
                ),

              const Spacer(),

              NebulaPrimaryButton(
                text: 'Confirmar',
                onPressed: _selectedIndex == null
                    ? null
                    : _confirmSelection,
              ),
            ],
          ),
        ),
      ),
    );
  }
}