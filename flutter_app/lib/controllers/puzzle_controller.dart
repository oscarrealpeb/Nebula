import 'dart:math';
import 'package:flutter/material.dart';

class PuzzleController extends ChangeNotifier {

  List<int> tiles = [];
  int size = 2;
  int moves = 0;
  bool isSolved = false;

  String? puzzleImage;

  final Random random = Random();
  final List<String> puzzleImages = [
  'assets/images/puzzles/piña.png',
  'assets/images/puzzles/mango.png',
  'assets/images/puzzles/uva.png',
  'assets/images/puzzles/durazno.png',
  'assets/images/puzzles/freijoas.png',
  'assets/images/puzzles/naranja1.png',
];

  void generatePuzzle(int stars) {

    /// dificultad
    size = stars + 1;

    /// ejemplo de imagen
    puzzleImage = puzzleImages[random.nextInt(puzzleImages.length)];

    int total = size * size;

    tiles = List.generate(total, (index) => index);

    tiles.shuffle();

    moves = 0;
    isSolved = false;

    notifyListeners();
  }

  void moveTile(int index) {

    int emptyIndex = tiles.indexOf(0);

    if (_canMove(index, emptyIndex)) {

      int temp = tiles[index];
      tiles[index] = tiles[emptyIndex];
      tiles[emptyIndex] = temp;

      moves++;

      _checkSolved();

      notifyListeners();
    }
  }

  bool _canMove(int index, int emptyIndex) {

    int row = index ~/ size;
    int col = index % size;

    int emptyRow = emptyIndex ~/ size;
    int emptyCol = emptyIndex % size;

    return (row == emptyRow && (col - emptyCol).abs() == 1) ||
        (col == emptyCol && (row - emptyRow).abs() == 1);
  }

  void _checkSolved() {

    for (int i = 0; i < tiles.length; i++) {

      if (tiles[i] != i) {
        isSolved = false;
        return;
      }

    }

    isSolved = true;
  }

  void resetPuzzle() {

    generatePuzzle(size - 1);
  }

}