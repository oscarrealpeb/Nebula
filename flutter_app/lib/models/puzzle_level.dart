enum PuzzleDifficulty {
  easy,
  medium,
  hard,
  expert,
}

class PuzzleLevel {
  final int id;
  final String name;
  final PuzzleDifficulty difficulty;
  final int gridSize;
  final List<String> solution;

  /// Gameplay properties
  final int moveLimit;
  final int maxStars;

  /// Player progress
  final bool unlocked;
  final int starsEarned;

  const PuzzleLevel({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.gridSize,
    required this.solution,
    required this.moveLimit,
    this.maxStars = 3,
    this.unlocked = false,
    this.starsEarned = 0,
  });

  /// Indicates if the level has been completed at least once
  bool get isCompleted => starsEarned > 0;

  /// Create a modified copy (useful for state updates)
  PuzzleLevel copyWith({
    int? id,
    String? name,
    PuzzleDifficulty? difficulty,
    int? gridSize,
    List<String>? solution,
    int? moveLimit,
    int? maxStars,
    bool? unlocked,
    int? starsEarned,
  }) {
    return PuzzleLevel(
      id: id ?? this.id,
      name: name ?? this.name,
      difficulty: difficulty ?? this.difficulty,
      gridSize: gridSize ?? this.gridSize,
      solution: solution ?? this.solution,
      moveLimit: moveLimit ?? this.moveLimit,
      maxStars: maxStars ?? this.maxStars,
      unlocked: unlocked ?? this.unlocked,
      starsEarned: starsEarned ?? this.starsEarned,
    );
  }

  factory PuzzleLevel.fromJson(Map<String, dynamic> json) {
    return PuzzleLevel(
      id: json['id'] as int,
      name: json['name'] as String,
      difficulty: PuzzleDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
      ),
      gridSize: json['gridSize'] as int,
      solution: List<String>.from(json['solution'] as List),
      moveLimit: json['moveLimit'] as int,
      maxStars: json['maxStars'] ?? 3,
      unlocked: json['unlocked'] ?? false,
      starsEarned: json['starsEarned'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'difficulty': difficulty.name,
      'gridSize': gridSize,
      'solution': solution,
      'moveLimit': moveLimit,
      'maxStars': maxStars,
      'unlocked': unlocked,
      'starsEarned': starsEarned,
    };
  }
}