import 'package:flutter/material.dart';
import '../controllers/puzzle_controller.dart';
import '../widgets/puzzle/puzzle_board.dart';
import '../widgets/puzzle_image_adapter.dart';

class PuzzleScreen extends StatefulWidget {
  final int stars;

  const PuzzleScreen({
    super.key,
    required this.stars,
  });

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  // Usamos final porque el objeto controlador no cambia, solo su estado interno
  late final PuzzleController controller;
  late int selectedStars;
  bool puzzleCompleted = false;

  @override
  void initState() {
    super.initState();
    selectedStars = widget.stars;
    controller = PuzzleController();

    // El listener debe ser lo más ligero posible
    controller.addListener(_onControllerChange);
    
    // Generar el puzzle inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.generatePuzzle(selectedStars);
    });
  }

  void _onControllerChange() {
    if (controller.isSolved && !puzzleCompleted) {
      puzzleCompleted = true;
      _showVictoryDialog();
    }
    // Solo actualizamos la UI si el widget sigue montado
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    // Es vital remover el listener antes de hacer dispose del controlador
    controller.removeListener(_onControllerChange);
    controller.dispose();
    super.dispose();
  }

  // --- Lógica de navegación y juego ---

  void _resetGame() {
    controller.resetPuzzle();
    setState(() => puzzleCompleted = false);
  }

  void _nextLevel() {
    int nextLevel = selectedStars + 1;
    if (nextLevel > 3) nextLevel = 1;

    setState(() {
      selectedStars = nextLevel;
      puzzleCompleted = false;
    });
    controller.generatePuzzle(selectedStars);
  }

  // --- UI Components ---

  void _showVictoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("🎉 ¡Lo lograste!", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            const SizedBox(height: 10),
            Text("Movimientos totales: ${controller.moves}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 15),
            Text("⭐" * selectedStars, style: const TextStyle(fontSize: 32)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: const Text("Repetir"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(elevation: 0),
            onPressed: () {
              Navigator.pop(context);
              _nextLevel();
            },
            child: const Text("Siguiente Nivel"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usamos Theme para mantener consistencia visual
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Puzzle Challenge"),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // Indicador de nivel
              Text("Dificultad", style: theme.textTheme.labelLarge),
              Text("⭐" * selectedStars, style: const TextStyle(fontSize: 28)),
              
              const SizedBox(height: 15),
              
              // Contador de movimientos estilizado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Movimientos: ${controller.moves}",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Referencia de imagen
              if (controller.puzzleImage != null)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: PuzzleImageAdapter(
                      imagePath: controller.puzzleImage!,
                      size: 150,
                    ),
                  ),
                ),

              const SizedBox(height: 30),

              // Tablero con limitación de ancho para Tablets
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: PuzzleBoard(controller: controller),
                ),
              ),

              const SizedBox(height: 30),

              // Botón de reinicio
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: theme.colorScheme.primary),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("REINICIAR PUZZLE"),
                  onPressed: _resetGame,
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}