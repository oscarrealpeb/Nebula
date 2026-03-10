import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../controllers/app_controller.dart';
import 'home_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class Gamediloscreen extends StatefulWidget {
  const Gamediloscreen({
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
  State<Gamediloscreen> createState() => _GamediloscreenState();
}

class _GamediloscreenState extends State<Gamediloscreen> {
  final DateTime _startedAt = DateTime.now();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late stt.SpeechToText _speech;
  bool _speechAvailable = false;
  String _recognizedText = '';
  String? _speechLocaleId;
  int _attemptsForCurrentWord = 0;
  final List<Map<String, String>> _failedWords = [];
  static const int _maxRounds = 5;
  static const int _maxAttemptsPerWord = 3;
  List<int> _errorIndexes = [];


  int _currentRound = 0;
  int _totalMistakes = 0;
  int _correctAnswers = 0;
  int _totalStarsEarned = 0;

  bool _isListening = false;
  String? _feedbackMessage;
  bool _completing = false;

  final List<Map<String, String>> _easyWords = [
  {
    'image': 'assets/images/conecta/gato.jpg',
    'text': 'Gato',
    'audio': 'sounds/gato.mp3',
  },
  // {
  //   'image': 'assets/sol.png',
  //   'text': 'sol',
  //   'audio': 'sounds/sol.mp3',
  // },
];

final List<Map<String, String>> _mediumWords = [
  {
    'image': 'assets/images/conecta/elefante.jpg',
    'text': 'Elefante',
    'audio': 'sounds/elefante.mp3',
  },
  // {
  //   'image': 'assets/mesa.png',
  //   'text': 'mesa',
  //   'audio': 'sounds/mesa.mp3',
  // },
];

final List<Map<String, String>> _hardWords = [
  {
    'image': 'assets/images/conecta/guitarra',
    'text': 'Guitarra',
    'audio': 'sounds/guitarra.mp3',
  },
  // {
  //   'image': 'assets/comer.png',
  //   'text': 'quiero comer',
  //   'audio': 'sounds/quiero_comer.mp3',
  // },
  ];

  List<Map<String, String>> get _currentList {
    if (widget.difficultyStars <= 1) return _easyWords;
    if (widget.difficultyStars == 2) return _mediumWords;
    return _hardWords;
  }

  Map<String, String> get _currentItem =>
      _currentList[_currentRound % _currentList.length];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _toggleListening() async {
  // if (!_speechAvailable) {
  //   setState(() {
  //     _feedbackMessage = 'Micrófono no disponible';
  //   });
  //   return;
  // }
    if (!_speechAvailable) {
    await _showOfflineSpeechDialog();
    return;
  }

  if (_isListening) {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
    return;
  }

  setState(() {
    _recognizedText = '';
    _feedbackMessage = null;
    _isListening = true;
  });

  await _speech.listen(
    localeId: _speechLocaleId,
    listenFor: const Duration(seconds: 20),
    pauseFor: const Duration(seconds: 8),
    partialResults: false,
    cancelOnError: true,
    listenMode: stt.ListenMode.dictation,
    onResult: (result) async {
      if (!mounted) return;

      setState(() {
        _recognizedText = result.recognizedWords;
      });

      if (result.finalResult) {
        await _speech.stop();

        if (!mounted) return;

        setState(() {
          _isListening = false;
        });

        if (_recognizedText.trim().isEmpty) {
          setState(() {
            _feedbackMessage = 'No escuché nada 😅';
          });
        } else {
          _evaluateAttempt();
        }
      }
    },
  );



  _speech.errorListener = (error) async {
  if (!mounted) return;

  setState(() {
    _isListening = false;
  });

  await _showOfflineSpeechDialog();
};
}



  Future<void> _playAudio() async {
    final audioPath = _currentItem['audio'];
    if (audioPath != null) {
      await _audioPlayer.play(AssetSource(audioPath));
    }
  }

  Future<void> _initSpeech() async {
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      if (!mounted) return;
      setState(() {
        _speechAvailable = false;
        _feedbackMessage = 'Permiso de micrófono denegado';
      });
      return;
    }

    _speechAvailable = await _speech.initialize(
  onStatus: (status) {
    debugPrint('Speech status: $status');
  },
  onError: (error) async {
    debugPrint('speech_to_text error: $error');

    if (!mounted) return;

    setState(() {
      _isListening = false;
    });

    await _showOfflineSpeechDialog();
  },
);

    if (!_speechAvailable) return;

    final locales = await _speech.locales();
    print(locales);
    for (var locale in locales) {
      if (locale.localeId.toLowerCase().startsWith('es')) {
        _speechLocaleId = locale.localeId;
        break;
      }
    }

    _speechLocaleId ??= locales.first.localeId;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _speech.stop();
    super.dispose();
  }


  int _levenshtein(String s, String t) {
  final m = s.length;
  final n = t.length;

  if (m == 0) return n;
  if (n == 0) return m;

  List<List<int>> dp =
      List.generate(m + 1, (_) => List.filled(n + 1, 0));

  for (int i = 0; i <= m; i++) {
    dp[i][0] = i;
  }

  for (int j = 0; j <= n; j++) {
    dp[0][j] = j;
  }

  for (int i = 1; i <= m; i++) {
    for (int j = 1; j <= n; j++) {
      int cost = s[i - 1] == t[j - 1] ? 0 : 1;

      dp[i][j] = [
        dp[i - 1][j] + 1,       // eliminación
        dp[i][j - 1] + 1,       // inserción
        dp[i - 1][j - 1] + cost // sustitución
      ].reduce((a, b) => a < b ? a : b);
    }
  }

  return dp[m][n];
}


List<int> _getErrorIndexes(String spoken, String correct) {
  final List<int> errors = [];

  final minLength = spoken.length < correct.length
      ? spoken.length
      : correct.length;

  for (int i = 0; i < minLength; i++) {
    if (spoken[i] != correct[i]) {
      errors.add(i);
    }
  }

  // Si faltan letras al final
  if (correct.length > spoken.length) {
    for (int i = spoken.length; i < correct.length; i++) {
      errors.add(i);
    }
  }

  return errors;
}


  void _evaluateAttempt() {
  final correctText = _normalize(_currentItem['text']!);
  final spokenText = _normalize(_recognizedText);

  int allowedErrors;

  if (widget.difficultyStars <= 1) {
    allowedErrors = 2;
  } else {
    allowedErrors = 1;
  }

  final distance = _levenshtein(spokenText, correctText);
  final isCorrect = distance <= allowedErrors;

  if (isCorrect) {
    _errorIndexes = [];

    _correctAnswers++;
    _attemptsForCurrentWord = 0;

    setState(() {
      _feedbackMessage = '¡Muy bien!';
    });

    Future.delayed(const Duration(seconds: 1), _nextRound);
  } else {
    _errorIndexes = _getErrorIndexes(spokenText, correctText);
    _totalMistakes++;
    _attemptsForCurrentWord++;

    if (_attemptsForCurrentWord >= _maxAttemptsPerWord) {
      // Guardar palabra fallada para repetición espaciada
      _failedWords.add(_currentItem);

      setState(() {
        _feedbackMessage = 'Pasamos a la siguiente 😊';
      });

      _attemptsForCurrentWord = 0;
      Future.delayed(const Duration(seconds: 1), _nextRound);
    } else {
      setState(() {
        _feedbackMessage = '¡Casi, prueba de nuevo!';
      });
    }
  }
}


  String _normalize(String text) {
  return text
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[áàäâ]'), 'a')
      .replaceAll(RegExp(r'[éèëê]'), 'e')
      .replaceAll(RegExp(r'[íìïî]'), 'i')
      .replaceAll(RegExp(r'[óòöô]'), 'o')
      .replaceAll(RegExp(r'[úùüû]'), 'u')
      .replaceAll(RegExp(r'\s+'), ' ');
}

  void _nextRound() {
  if (_currentRound >= _maxRounds - 1) {
    _completeGame();
    return;
  }

  setState(() {
    _currentRound++;
    _feedbackMessage = null;
    _recognizedText = '';
  });
}

  Future<void> _completeGame() async {
    if (_completing) return;
    setState(() => _completing = true);

    // Misma logica de estrellas que emotion_screen.
    int earnedStars;
    if (_totalMistakes == 0) {
      earnedStars = 20;
    } else if (_totalMistakes <= 3) {
      earnedStars = 15;
    } else {
      earnedStars = 10;
    }

    if (widget.difficultyStars == 2) {
      earnedStars += 5;
    } else if (widget.difficultyStars == 3) {
      earnedStars += 10;
    }
    _totalStarsEarned = earnedStars;

    await widget.controller.addStars(_totalStarsEarned);

    await widget.controller.recordGameSession(
      gameKey: widget.gameKey,
      startedAt: _startedAt,
      endedAt: DateTime.now(),
      difficultyStars: widget.difficultyStars,
      rounds: 5,
      mistakes: _totalMistakes,
      pointsEarned: _totalStarsEarned,
      correctAnswers: _correctAnswers,
      totalAttempts: _correctAnswers + _totalMistakes,
    );

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
                'Ganaste $_totalStarsEarned estrellas ⭐',
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



  Future<void> _showOfflineSpeechDialog() async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        'Necesitamos configurar algo antes de empezar 😊',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: const SingleChildScrollView(
        child: Text(
          'Este juego necesita usar el micrófono sin internet.\n\n'
          'Sigue estos pasos:\n\n'
          '1. Ve a Ajustes\n'
          '2. Busca "Idioma y entrada" o "Sistema"\n'
          '3. Entra en "Reconocimiento de voz" o "Escritura por voz"\n'
          '4. Selecciona "Reconocimiento sin conexión"\n'
          '5. Descarga Español\n\n'
          '──────────────\n'
          'Sugerencia: si no encuentras la opción, usa el buscador de Ajustes '
          'y escribe "reconocimiento de voz sin conexión" para ubicarla más rápido.',
          style: TextStyle(
            fontSize: 15.5, // un poquito más grande
            height: 1.4,    // mejor espaciado
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: const Color.fromARGB(255, 255, 255, 255), // texto 
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop(); // salir del juego
          },
          child: const Text(
            'Entendido',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
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
              const Text(
                'Mira la imagen:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          _currentItem['image']!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Center(child: Icon(Icons.broken_image_outlined)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      _currentItem['text']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: widget.controller.accentColor,
                      ),
                    ),
                  ],
                ),
              ),

              // const SizedBox(height: 2),

              // Text(
              //   _currentItem['text']!,
              //   textAlign: TextAlign.center,
              //   style: TextStyle(
              //     fontSize: 22,
              //     fontWeight: FontWeight.bold,
              //     letterSpacing: 1.2,
              //     color: widget.controller.accentColor,
              //   ),
              // ),
              const SizedBox(height: 4),
              const Text(
                '¿Cómo se llama?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),


              if (_recognizedText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: _buildColoredText(),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              if (_feedbackMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                    decoration: BoxDecoration(
                      color: _feedbackMessage == '¡Muy bien!'
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _feedbackMessage!,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _feedbackMessage == '¡Muy bien!'
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: widget.controller.accentColor.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _playAudio,
                        child: const SizedBox(
                          height: 56,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.volume_up_rounded, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Escuchar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Material(
                      color: _isListening
                          ? widget.controller.accentColor
                          : widget.controller.accentColor.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _toggleListening,
                        child: SizedBox(
                          height: 56,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isListening
                                    ? Icons.stop_circle_rounded
                                    : Icons.mic_rounded,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isListening ? 'Detener' : 'Hablar',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  List<TextSpan> _buildColoredText() {
  final correctText = _normalize(_currentItem['text']!);
  final spokenText = _normalize(_recognizedText);

  final List<TextSpan> spans = [];

  for (int i = 0; i < spokenText.length; i++) {
    final bool isError =
        i >= correctText.length || _errorIndexes.contains(i);

    spans.add(
      TextSpan(
        text: spokenText[i],
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: isError ? Colors.red : Colors.black,
        ),
      ),
    );
  }

  return spans;
}
}