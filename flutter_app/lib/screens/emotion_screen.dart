import 'package:flutter/material.dart';
import '../controllers/app_controller.dart';

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

  // =============================
  // CONFIGURACIÓN GENERAL
  // =============================

  static const int totalRounds = 5;

  final List<String> allEmotions = [
    'Feliz',
    'Triste',
    'Enojado',
    'Sorprendido',
  ];

  // =============================
  // IMÁGENES POR DIFICULTAD
  // =============================

  late final List<EmotionQuestion> easyQuestions;
  late final List<EmotionQuestion> mediumQuestions;
  late final List<EmotionQuestion> hardQuestions;

  late List<EmotionQuestion> activeQuestions;

  // =============================
  // ESTADO DEL JUEGO
  // =============================

  EmotionQuestion? currentQuestion;
  List<String> currentOptions = [];

  String? selectedEmotion;
  Set<String> disabledOptions = {};

  int currentRound = 0;
  int totalMistakes = 0;

  String? feedbackMessage;

  @override
  void initState() {
    super.initState();

    // 🔹 EJEMPLOS (luego agrega todas tus imágenes aquí)
    easyQuestions = [
      EmotionQuestion(
        imagePath: 'assets/images/games/feliz1.jpg',
        correctEmotion: 'Feliz',
      ),
      EmotionQuestion(
        imagePath: 'assets/images/games/triste1.jpg',
        correctEmotion: 'Triste',
      ),
    ];

    mediumQuestions = [
      EmotionQuestion(
        imagePath: 'assets/images/games/situacion1.jpg',
        correctEmotion: 'Triste',
      ),
    ];

    hardQuestions = [
      EmotionQuestion(
        imagePath: 'assets/images/games/compleja1.jpg',
        correctEmotion: 'Feliz',
      ),
    ];

    // 🔹 Selección por dificultad
    if (widget.difficultyStars == 1) {
      activeQuestions = easyQuestions;
    } else if (widget.difficultyStars == 2) {
      activeQuestions = mediumQuestions;
    } else {
      activeQuestions = hardQuestions;
    }

    activeQuestions.shuffle();
    loadNextQuestion();
  }

  void loadNextQuestion() {
    if (currentRound >= totalRounds) {
      finishGame();
      return;
    }

    currentQuestion =
        activeQuestions[currentRound % activeQuestions.length];

    currentOptions = List.from(allEmotions)..shuffle();

    selectedEmotion = null;
    disabledOptions.clear();
    feedbackMessage = null;

    setState(() {});
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
      currentRound++;
      loadNextQuestion();
    } else {
      totalMistakes++;

      setState(() {
        disabledOptions.add(selectedEmotion!);
        selectedEmotion = null;
        feedbackMessage = "¡Casi lo logras, prueba de nuevo!";
      });
    }
  }

  void finishGame() async {
    int baseStars;

    if (totalMistakes == 0) {
      baseStars = 20;
    } else if (totalMistakes <= 3) {
      baseStars = 15;
    } else {
      baseStars = 10;
    }

    if (widget.difficultyStars == 2) {
      baseStars += 5;
    } else if (widget.difficultyStars == 3) {
      baseStars += 10;
    }

    await widget.controller.addStars(baseStars);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // =============================
  // BUILD
  // =============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gameName),
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // 🔹 Imagen
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
                          child: Image.asset(
                            currentQuestion!.imagePath,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 Instrucción
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

            // 🔹 Feedback si se equivoca
            if (feedbackMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    feedbackMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20, // 👈 MÁS GRANDE
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ),

            // 🔹 Opciones
            Expanded(
            flex: 4,
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
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
                          color: isDisabled
                              ? Colors.grey
                              : Colors.white,
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

            // 🔹 Botón confirmar
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
                onPressed: confirmAnswer,
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
    );
  }
}