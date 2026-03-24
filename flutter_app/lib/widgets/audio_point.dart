import 'package:flutter/material.dart';

class AudioPoint extends StatelessWidget {
  final String audioPath;
  final Widget child;

  const AudioPoint({super.key, required this.audioPath, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Aquí irá la lógica de playAudio(audioPath) más adelante
        print("Reproduciendo: $audioPath");
      },
      child: child,
    );
  }
}