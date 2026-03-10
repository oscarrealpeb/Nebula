import 'dart:math';

class PuzzleImages {

  /// Lista de imágenes disponibles para puzzles
  static const List<String> images = [
    "assets/images/puzzles/durazno.png",
    
    "assets/images/puzzles/mango.png",
    
    "assets/images/puzzles/Naranja1.png",
    
    "assets/images/puzzles/piña.png",
    "assets/images/puzzles/uva.png",
  ];

  /// Devuelve una imagen aleatoria
  static String randomImage() {
    final random = Random();
    return images[random.nextInt(images.length)];
  }

}