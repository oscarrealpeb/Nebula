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
  int? _selectedTileIndex;
  String? puzzleImageSource;
  ImageProvider<Object>? puzzleImageProvider;

  int? get selectedTileIndex => _selectedTileIndex;

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
    _createShuffledBoard();

    moves = 0;
    isSolved = false;
    _selectedTileIndex = null;
    notifyListeners();
  }

  void resetPuzzle() {
    generatePuzzle(size - 1);
  }

  void tapTile(int index) {
    if (isSolved || index < 0 || index >= tiles.length) return;

    if (_selectedTileIndex == null) {
      _selectedTileIndex = index;
      notifyListeners();
      return;
    }

    if (_selectedTileIndex == index) {
      _selectedTileIndex = null;
      notifyListeners();
      return;
    }

    final nextTiles = List<int>.from(tiles);
    final firstIndex = _selectedTileIndex!;
    final temp = nextTiles[index];
    nextTiles[index] = nextTiles[firstIndex];
    nextTiles[firstIndex] = temp;
    tiles = nextTiles;
    _selectedTileIndex = null;
    moves += 1;
    _checkSolved();
    notifyListeners();
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

  void _createShuffledBoard() {
    final total = size * size;
    final nextTiles = List<int>.generate(total, (index) => index);

    do {
      nextTiles.shuffle(_random);
    } while (_isSolvedState(nextTiles));

    tiles = nextTiles;
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
