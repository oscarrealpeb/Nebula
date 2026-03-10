import 'dart:math';

class PuzzleImageService {

  final Random _random = Random();

  /// Lista de imágenes disponibles para puzzles
  final List<String> _images = [

    "assets/puzzles/puzzle1.jpg",
    "assets/puzzles/puzzle2.jpg",
    "assets/puzzles/puzzle3.jpg",
    "assets/puzzles/puzzle4.jpg",
    "assets/puzzles/puzzle5.jpg",

  ];

  /// Devuelve todas las imágenes
  List<String> getAllImages() {
    return _images;
  }

  /// Devuelve una imagen aleatoria
  String getRandomImage() {

    int index = _random.nextInt(_images.length);

    return _images[index];
  }

  /// Devuelve una imagen según el nivel
  String getImageForLevel(int level) {

    int index = level % _images.length;

    return _images[index];
  }
}