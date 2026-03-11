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
    final provider = controller.puzzleImageProvider;
    if (provider == null) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFFE8ECF7),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'No pudimos cargar la imagen del rompecabezas.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (controller.isSolved) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: ClipRRect(
          key: const ValueKey('puzzle_solved'),
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image(
            image: provider,
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
              final row = index ~/ controller.size;
              final col = index % controller.size;

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                left: col * (tileSize + spacing),
                top: row * (tileSize + spacing),
                width: tileSize,
                height: tileSize,
                child: _PuzzleTile(
                  value: value,
                  size: controller.size,
                  imageProvider: provider,
                  borderRadius: borderRadius,
                  isSelected: controller.selectedTileIndex == index,
                  onTap: () => controller.tapTile(index),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _PuzzleTile extends StatelessWidget {
  const _PuzzleTile({
    required this.value,
    required this.size,
    required this.imageProvider,
    required this.borderRadius,
    required this.isSelected,
    required this.onTap,
  });

  final int value;
  final int size;
  final ImageProvider<Object> imageProvider;
  final double borderRadius;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageIndex = value;
    final row = imageIndex ~/ size;
    final col = imageIndex % size;
    final horizontal = size <= 1 ? 0.0 : (-1 + (2 * col) / (size - 1));
    final vertical = size <= 1 ? 0.0 : (-1 + (2 * row) / (size - 1));

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FractionallySizedBox(
              widthFactor: size.toDouble(),
              heightFactor: size.toDouble(),
              alignment: Alignment(horizontal, vertical),
              child: Image(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: isSelected ? const Color(0xFF1E88E5) : Colors.black12,
                  width: isSelected ? 3 : 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
