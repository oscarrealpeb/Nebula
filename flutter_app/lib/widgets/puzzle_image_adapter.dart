import 'package:flutter/material.dart';

class PuzzleImageAdapter extends StatelessWidget {
  final String imagePath;
  final double size;

  const PuzzleImageAdapter({
    super.key,
    required this.imagePath,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: Image.asset(imagePath),
        ),
      ),
    );
  }
}