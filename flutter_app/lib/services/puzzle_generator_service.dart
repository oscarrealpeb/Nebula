import 'dart:math';

class PuzzleGeneratorService {

  final Random _random = Random();

  /// Crea un tablero resuelto
  List<int> generateSolvedBoard(int size) {

    int total = size * size;

    return List.generate(total, (index) => index);
  }

  /// Mezcla el tablero
  List<int> shuffleBoard(List<int> board, int size) {

    List<int> shuffled = List.from(board);

    do {
      shuffled.shuffle(_random);
    } while (!_isSolvable(shuffled, size) || _isSolved(shuffled));

    return shuffled;
  }

  /// Verifica si el puzzle está resuelto
  bool _isSolved(List<int> board) {

    for (int i = 0; i < board.length; i++) {
      if (board[i] != i) {
        return false;
      }
    }

    return true;
  }

  /// Verifica si el puzzle tiene solución
  bool _isSolvable(List<int> board, int size) {

    int inversions = 0;

    for (int i = 0; i < board.length; i++) {

      for (int j = i + 1; j < board.length; j++) {

        if (board[i] != 0 &&
            board[j] != 0 &&
            board[i] > board[j]) {

          inversions++;
        }
      }
    }

    if (size % 2 == 1) {
      return inversions % 2 == 0;
    }

    int emptyRow = board.indexOf(0) ~/ size;

    if (emptyRow % 2 == 0) {
      return inversions % 2 == 1;
    } else {
      return inversions % 2 == 0;
    }
  }
}