import 'dart:io';

import 'package:flutter/material.dart';
import '../controllers/app_controller.dart';
import 'home_screen.dart';
import 'package:lottie/lottie.dart';

class EmotionQuestion {
  final String imagePath;
  final String correctEmotion;

  EmotionQuestion({
    required this.imagePath,
    required this.correctEmotion,
  });
}

class EmotionGameScreen extends StatefulWidget {
  const EmotionGameScreen({
    super.key,
    required this.controller,
    required this.gameName,
    required this.difficultyStars,
  });

  final AppController controller;
  final String gameName;
  final int difficultyStars;

  @override
  State<EmotionGameScreen> createState() => _EmotionGameScreenState();
}

class _EmotionGameScreenState extends State<EmotionGameScreen> {
  static const int totalRounds = 5;

  static const List<String> _defaultEmotionOptions = [
    'Feliz',
    'Triste',
    'Enojado',
    'Sorprendido',
    'Asustado',
  ];

  late final List<EmotionQuestion> easyQuestions;
  late final List<EmotionQuestion> mediumQuestions;
  late final List<EmotionQuestion> hardQuestions;

  late List<EmotionQuestion> activeQuestions;

  EmotionQuestion? currentQuestion;
  List<String> currentOptions = [];

  String? selectedEmotion;
  Set<String> disabledOptions = {};

  int currentRound = 0;
  int totalMistakes = 0;
  int perfectRounds = 0;
  bool _roundHadMistake = false;
  final DateTime _startedAt = DateTime.now();

  String? feedbackMessage;
  bool _isFinishing = false;

  // 🔁 REPETICIÓN ESPACIADA (memoria local simple)
  static final List<EmotionQuestion> reviewPool = [];

  @override
  void initState() {
    super.initState();

    easyQuestions = [
      EmotionQuestion(
        imagePath: 'assets/images/facil/feliz1.jpg',
        correctEmotion: 'Feliz',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/feliz2.jpg',
        correctEmotion: 'Feliz',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/feliz3.jpg',
        correctEmotion: 'Feliz',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/feliz4.jpg',
        correctEmotion: 'Feliz',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/feliz5.jpg',
        correctEmotion: 'Feliz',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/feliz6.jpg',
        correctEmotion: 'Feliz',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/feliz7.jpg',
        correctEmotion: 'Feliz',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/feliz9.jpg',
        correctEmotion: 'Feliz',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/feliz10.jpg',
        correctEmotion: 'Feliz',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/triste1.jpg',
        correctEmotion: 'Triste',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/triste2.jpg',
        correctEmotion: 'Triste',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/triste3.jpg',
        correctEmotion: 'Triste',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/triste4.jpg',
        correctEmotion: 'Triste',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/triste5.jpg',
        correctEmotion: 'Triste',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/triste6.jpg',
        correctEmotion: 'Triste',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/enojado1.jpg',
        correctEmotion: 'Enojado',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/enojado2.jpg',
        correctEmotion: 'Enojado',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/enojado3.jpg',
        correctEmotion: 'Enojado',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/enojado4.jpg',
        correctEmotion: 'Enojado',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/enojado5.jpg',
        correctEmotion: 'Enojado',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/enojado6.jpg',
        correctEmotion: 'Enojado',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/enojado7.jpg',
        correctEmotion: 'Enojado',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/enojado8.jpg',
        correctEmotion: 'Enojado',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/enojado9.jpg',
        correctEmotion: 'Enojado',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/enojado10.jpg',
        correctEmotion: 'Enojado',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/asustado4.jpg',
        correctEmotion: 'Asustado',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/asustado6.jpg',
        correctEmotion: 'Asustado',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/sorprendido1.jpg',
        correctEmotion: 'Sorprendido',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/sorprendido2.jpg',
        correctEmotion: 'Sorprendido',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/sorpendido3.jpg',
        correctEmotion: 'Sorprendido',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/sorprendido4.jpg',
        correctEmotion: 'Sorprendido',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/sorprendido5.jpg',
        correctEmotion: 'Sorprendido',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/sorprendido6.jpg',
        correctEmotion: 'Sorprendido',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/sorprendido7.jpg',
        correctEmotion: 'Sorprendido',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/facil/sorprendido8.jpg',
        correctEmotion: 'Sorprendido',
      ),
    ];

    mediumQuestions = [
      EmotionQuestion(
        imagePath: 'assets/images/medio/s-asustado.jpg',
        correctEmotion: 'Asustado',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/medio/s-asustado2.jpg',
        correctEmotion: 'Asustado',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/medio/s-asustado3.jpg',
        correctEmotion: 'Asustado',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/medio/s-enojada.jpg',
        correctEmotion: 'Enojado',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/medio/s-feliz1.jpg',
        correctEmotion: 'Feliz',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/medio/s-feliz2.jpg',
        correctEmotion: 'Feliz',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/medio/s-feliz3jpg.jpg',
        correctEmotion: 'Feliz',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/medio/s-feliz4.jpg',
        correctEmotion: 'Feliz',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/medio/s-feliz5.jpg',
        correctEmotion: 'Feliz',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/medio/s-feliz6.jpg',
        correctEmotion: 'Feliz',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/medio/s-feliz7.jpg',
        correctEmotion: 'Feliz',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/medio/s-sorprendido1.jpg',
        correctEmotion: 'Sorprendido',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/medio/s-sorprendido2.jpg',
        correctEmotion: 'Sorprendido',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/medio/s-sorprendido3.jpg',
        correctEmotion: 'Sorprendido',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/medio/s-triste6.jpg',
        correctEmotion: 'Triste',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/medio/s-triste7 (recortar).jpg',
        correctEmotion: 'Triste',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/medio/s-triste8.jpg',
        correctEmotion: 'Triste',
      ),
    ];

    hardQuestions = [
      EmotionQuestion(
        imagePath: 'assets/images/dificil/d-asustado1.jpg',
        correctEmotion: 'Asustado',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/dificil/d-asustado2.jpg',
        correctEmotion: 'Asustado',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/dificil/d-asustado3.jpg',
        correctEmotion: 'Asustado',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/dificil/d-enojado1.jpg',
        correctEmotion: 'Enojado',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/dificil/d-enojado2.jpg',
        correctEmotion: 'Enojado',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/dificil/d-enojado3.jpg',
        correctEmotion: 'Enojado',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/dificil/d-enojado5.jpg',
        correctEmotion: 'Enojado',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/dificil/d-feliz.jpg',
        correctEmotion: 'Feliz',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/dificil/d-feliz1.jpg',
        correctEmotion: 'Feliz',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/dificil/d-feliz3.jpg',
        correctEmotion: 'Feliz',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/dificil/d-feliz5.jpg',
        correctEmotion: 'Feliz',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/dificil/d-feliz6.jpg',
        correctEmotion: 'Feliz',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/dificil/d-feliz7.jpg',
        correctEmotion: 'Feliz',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/dificil/d-sorprendidos.jpg',
        correctEmotion: 'Sorprendido',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/dificil/d-triste1.jpg',
        correctEmotion: 'Triste',
      ),
    ];

    activeQuestions = _questionsForDifficulty(widget.difficultyStars);

    // 🔁 Insertar preguntas falladas primero
    if (reviewPool.isNotEmpty) {
      activeQuestions.insertAll(0, reviewPool);
    }

    activeQuestions.shuffle();

    loadNextQuestion();
  }

  void loadNextQuestion() {
    if (currentRound >= totalRounds) {
      finishGame();
      return;
    }

    currentQuestion = activeQuestions[currentRound % activeQuestions.length];

    // 🔹 Generar solo 4 opciones (incluyendo la correcta)
    final emotionPool = _emotionPoolForOptions();
    List<String> wrongOptions = emotionPool
        .where((emotion) => emotion != currentQuestion!.correctEmotion)
        .toList();

    wrongOptions.shuffle();

    currentOptions = [
      currentQuestion!.correctEmotion,
      ...wrongOptions.take(3),
    ];

    currentOptions.shuffle();

    selectedEmotion = null;
    disabledOptions.clear();
    feedbackMessage = null;
    _roundHadMistake = false;

    setState(() {});
  }

  List<String> _emotionPoolForOptions() {
    final pool = <String>{
      ..._defaultEmotionOptions,
      ...easyQuestions.map((item) => item.correctEmotion.trim()),
      ...mediumQuestions.map((item) => item.correctEmotion.trim()),
      ...hardQuestions.map((item) => item.correctEmotion.trim()),
      ...activeQuestions.map((item) => item.correctEmotion.trim()),
    }.where((item) => item.isNotEmpty).toList();
    if (pool.length < 4) {
      return [..._defaultEmotionOptions];
    }
    return pool;
  }

  List<EmotionQuestion> _defaultQuestionsForDifficulty(int stars) {
    if (stars == 1) return [...easyQuestions];
    if (stars == 2) return [...mediumQuestions];
    return [...hardQuestions];
  }

  List<EmotionQuestion> _questionsForDifficulty(int stars) {
    final defaults = _defaultQuestionsForDifficulty(stars);
    final custom = widget.controller.gameContentConfig.emotionItems
        .where(
          (item) =>
              item.enabled &&
              item.difficultyStars == stars &&
              item.imagePath.trim().isNotEmpty &&
              item.correctEmotion.trim().isNotEmpty,
        )
        .map(
          (item) => EmotionQuestion(
            imagePath: item.imagePath.trim(),
            correctEmotion: item.correctEmotion.trim(),
          ),
        )
        .toList();
    if (custom.isEmpty) return defaults;

    final merged = <EmotionQuestion>[...custom];
    for (final item in defaults) {
      final exists = merged.any(
        (candidate) => candidate.imagePath.trim() == item.imagePath.trim(),
      );
      if (!exists) {
        merged.add(item);
      }
    }
    return merged;
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

  void selectEmotion(String emotion) {
    if (disabledOptions.contains(emotion)) return;

    setState(() {
      selectedEmotion = emotion;
    });
  }

  Future<void> confirmAnswer() async {
    if (selectedEmotion == null) return;

    if (selectedEmotion == currentQuestion!.correctEmotion) {
      if (!_roundHadMistake) {
        perfectRounds++;
      }
      setState(() {
        feedbackMessage = "¡Muy bien!";
        _isFinishing = true; // 🔒 bloquear confirmar
      });

      await Future.delayed(const Duration(milliseconds: 700));

      reviewPool.removeWhere((q) => q.imagePath == currentQuestion!.imagePath);

      currentRound++;

      if (currentRound >= totalRounds) {
        await finishGame();
      } else {
        _isFinishing = false; // 🔓 desbloquear para la siguiente ronda
        loadNextQuestion();
      }
    } else {
      totalMistakes++;
      _roundHadMistake = true;

      // 🔁 Agregar a revisión si no está ya
      if (!reviewPool.any((q) => q.imagePath == currentQuestion!.imagePath)) {
        reviewPool.add(currentQuestion!);
      }

      setState(() {
        disabledOptions.add(selectedEmotion!);
        selectedEmotion = null;
        feedbackMessage = "¡Casi, prueba de nuevo!";
      });
    }
  }

  Future<void> finishGame() async {
    // if (_isFinishing) return;
    _isFinishing = true;

    final baseByDifficulty = switch (widget.difficultyStars.clamp(1, 3)) {
      1 => 20,
      2 => 25,
      _ => 30,
    };
    final penalty = totalMistakes > 3 ? 10 : 0;
    final baseStars = (baseByDifficulty - penalty).clamp(0, 30).toInt();

    try {
      await widget.controller
          .addStars(baseStars)
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('finishGame/addStars error: $e');
    }

    try {
      await widget.controller.recordGameSession(
        gameKey: 'descubre_emocion',
        startedAt: _startedAt,
        endedAt: DateTime.now(),
        difficultyStars: widget.difficultyStars,
        rounds: totalRounds,
        mistakes: totalMistakes,
        pointsEarned: baseStars,
        correctAnswers: totalRounds,
        totalAttempts: totalRounds + totalMistakes,
        perfectRounds: perfectRounds,
      );
    } catch (e) {
      debugPrint('finishGame/recordGameSession error: $e');
    }

    if (!mounted) return;

    // 🔹 CUADRITO TRANQUILO
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

    /// 🔹 Espera breve para que lo lean
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomeScreen(controller: widget.controller),
      ),
      (route) => false,
    );
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
              foregroundColor: Colors.white, // texto blanco
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
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
        final isCompleted = index <= currentRound;
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
          title: Text(widget.gameName),
        ),
        body: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildRoundProgress(),
              const SizedBox(height: 12),

              // 🔹 NUEVO TEXTO GUÍA
              const Text(
                "Mira la imagen:",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                flex: 5,
                child: Center(
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey[200],
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: currentQuestion == null
                        ? const SizedBox()
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image(
                              image:
                                  _imageProviderFor(currentQuestion!.imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Elige cómo crees que se siente 😊',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              // 🔹 Feedback dinámico
              if (feedbackMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                    decoration: BoxDecoration(
                      color: feedbackMessage == "¡Muy bien!"
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      feedbackMessage!,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: feedbackMessage == "¡Muy bien!"
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
                ),

              Expanded(
                flex: 4,
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.7,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: currentOptions.map((emotion) {
                    final bool isDisabled = disabledOptions.contains(emotion);
                    final bool isSelected = selectedEmotion == emotion;

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
                        onTap: isDisabled ? null : () => selectEmotion(emotion),
                        child: Center(
                          child: Text(
                            emotion,
                            style: TextStyle(
                              color: isDisabled ? Colors.grey : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: SizedBox(
                  width: 220,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.controller.accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isFinishing ? null : confirmAnswer,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
