import 'package:flutter/material.dart';
import '../../controllers/puzzle_controller.dart';

class PuzzleBoard extends StatelessWidget {
  const PuzzleBoard({
    super.key,
    required this.controller,
    this.spacing = 4,
    this.borderRadius = 10,
  });

  final PuzzleController controller;
  final double spacing;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {

    /// Cuando el puzzle está resuelto mostramos la imagen completa
    if (controller.isSolved && controller.puzzleImage != null) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: ClipRRect(
          key: const ValueKey("completed"),
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.asset(
            controller.puzzleImage!,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {

        final boardSize = constraints.maxWidth;
        final tileSize =
            (boardSize - (spacing * (controller.size - 1))) / controller.size;

        return SizedBox(
          width: boardSize,
          height: boardSize,
          child: Stack(
            children: List.generate(controller.tiles.length, (index) {

              final value = controller.tiles[index];

              /// 0 es el hueco
              if (value == 0) return const SizedBox();

              final row = index ~/ controller.size;
              final col = index % controller.size;

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                left: col * (tileSize + spacing),
                top: row * (tileSize + spacing),
                width: tileSize,
                height: tileSize,
                child: PuzzleTile(
                  value: value,
                  size: controller.size,
                  imagePath: controller.puzzleImage!,
                  borderRadius: borderRadius,
                  onTap: () {

                    if (!controller.isSolved) {
                      controller.moveTile(index);
                    }
                  },
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class PuzzleTile extends StatelessWidget {
  const PuzzleTile({
    super.key,
    required this.value,
    required this.size,
    required this.imagePath,
    required this.borderRadius,
    required this.onTap,
  });

  final int value;
  final int size;
  final String imagePath;
  final double borderRadius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {

    /// posición original de la pieza en la imagen
    final imageIndex = value - 1;
    final row = imageIndex ~/ size;
    final col = imageIndex % size;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [

            /// Imagen completa desplazada
            Positioned.fill(
              child: FractionallySizedBox(
                widthFactor: size.toDouble(),
                heightFactor: size.toDouble(),
                alignment: Alignment(
                  -1 + (2 * col) / (size - 1),
                  -1 + (2 * row) / (size - 1),
                ),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            /// Sombra suave
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: Colors.black12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}