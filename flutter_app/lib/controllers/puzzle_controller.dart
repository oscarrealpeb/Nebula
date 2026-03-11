import 'dart:math';

import 'package:flutter/material.dart';

import '../core/data/puzzle_catalog.dart';
import '../widgets/puzzle_image_adapter.dart';

class PuzzleController extends ChangeNotifier {
  PuzzleController({
    List<String> imageSources = const [],
  }) : _random = Random() {
    setImageSources(imageSources);
  }

  final Random _random;
  List<String> _imageSources = List<String>.from(defaultPuzzleImageSources);

  List<int> tiles = const [];
  int size = 2;
  int moves = 0;
  bool isSolved = false;
  String? puzzleImageSource;
  ImageProvider<Object>? puzzleImageProvider;

  void setImageSources(List<String> imageSources) {
    final normalized = imageSources
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    _imageSources = normalized.isEmpty
        ? List<String>.from(defaultPuzzleImageSources)
        : normalized;
  }

  void generatePuzzle(int stars) {
    final safeStars = stars.clamp(1, 3).toInt();
    size = safeStars + 1;

    _selectPuzzleImage();
    _createSolvableBoard();

    moves = 0;
    isSolved = false;
    notifyListeners();
  }

  void resetPuzzle() {
    generatePuzzle(size - 1);
  }

  void moveTile(int index) {
    if (isSolved || index < 0 || index >= tiles.length) return;
    final emptyIndex = tiles.indexOf(0);
    if (emptyIndex < 0) return;
    if (!_isAdjacent(index, emptyIndex)) return;

    final nextTiles = List<int>.from(tiles);
    final temp = nextTiles[index];
    nextTiles[index] = nextTiles[emptyIndex];
    nextTiles[emptyIndex] = temp;
    tiles = nextTiles;
    moves += 1;
    _checkSolved();
    notifyListeners();
  }

  bool _isAdjacent(int index, int emptyIndex) {
    final row = index ~/ size;
    final col = index % size;
    final emptyRow = emptyIndex ~/ size;
    final emptyCol = emptyIndex % size;
    return (row == emptyRow && (col - emptyCol).abs() == 1) ||
        (col == emptyCol && (row - emptyRow).abs() == 1);
  }

  void _selectPuzzleImage() {
    if (_imageSources.isEmpty) {
      puzzleImageSource = null;
      puzzleImageProvider = null;
      return;
    }

    final shuffledSources = List<String>.from(_imageSources)..shuffle(_random);
    for (final source in shuffledSources) {
      final provider = puzzleImageProviderFromSource(source);
      if (provider == null) continue;
      puzzleImageSource = source;
      puzzleImageProvider = provider;
      return;
    }

    puzzleImageSource = null;
    puzzleImageProvider = null;
  }

  void _createSolvableBoard() {
    final total = size * size;
    final solved = List<int>.generate(total, (index) => index);
    final nextTiles = List<int>.from(solved);

    var empty = 0;
    final shuffleMoves = max(40, total * 14);
    for (var step = 0; step < shuffleMoves; step++) {
      final neighbors = _neighborsOf(empty);
      final swapIndex = neighbors[_random.nextInt(neighbors.length)];
      final temp = nextTiles[swapIndex];
      nextTiles[swapIndex] = nextTiles[empty];
      nextTiles[empty] = temp;
      empty = swapIndex;
    }

    if (_isSolvedState(nextTiles)) {
      final neighbors = _neighborsOf(empty);
      final swapIndex = neighbors.first;
      final temp = nextTiles[swapIndex];
      nextTiles[swapIndex] = nextTiles[empty];
      nextTiles[empty] = temp;
    }

    tiles = nextTiles;
  }

  List<int> _neighborsOf(int emptyIndex) {
    final row = emptyIndex ~/ size;
    final col = emptyIndex % size;
    final neighbors = <int>[];
    if (row > 0) neighbors.add((row - 1) * size + col);
    if (row < size - 1) neighbors.add((row + 1) * size + col);
    if (col > 0) neighbors.add(row * size + col - 1);
    if (col < size - 1) neighbors.add(row * size + col + 1);
    return neighbors;
  }

  bool _isSolvedState(List<int> state) {
    for (var i = 0; i < state.length; i++) {
      if (state[i] != i) return false;
    }
    return true;
  }

  void _checkSolved() {
    isSolved = _isSolvedState(tiles);
  }
}
