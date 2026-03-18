class EmotionContentItem {
  const EmotionContentItem({
    required this.id,
    required this.difficultyStars,
    required this.imagePath,
    required this.correctEmotion,
    this.enabled = true,
  });

  final String id;
  final int difficultyStars;
  final String imagePath;
  final String correctEmotion;
  final bool enabled;

  EmotionContentItem copyWith({
    String? id,
    int? difficultyStars,
    String? imagePath,
    String? correctEmotion,
    bool? enabled,
  }) {
    return EmotionContentItem(
      id: id ?? this.id,
      difficultyStars: difficultyStars ?? this.difficultyStars,
      imagePath: imagePath ?? this.imagePath,
      correctEmotion: correctEmotion ?? this.correctEmotion,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'difficultyStars': difficultyStars,
      'imagePath': imagePath,
      'correctEmotion': correctEmotion,
      'enabled': enabled,
    };
  }

  factory EmotionContentItem.fromJson(Map<String, dynamic> json) {
    return EmotionContentItem(
      id: (json['id'] as String?) ?? '',
      difficultyStars: (json['difficultyStars'] as num?)?.toInt() ?? 1,
      imagePath: (json['imagePath'] as String?) ?? '',
      correctEmotion: (json['correctEmotion'] as String?) ?? '',
      enabled: (json['enabled'] as bool?) ?? true,
    );
  }
}

class SoundContentItem {
  const SoundContentItem({
    required this.id,
    required this.difficultyStars,
    required this.soundAsset,
    required this.correctImage,
    this.category = '',
    this.enabled = true,
  });

  final String id;
  final int difficultyStars;
  final String soundAsset;
  final String correctImage;
  final String category;
  final bool enabled;

  SoundContentItem copyWith({
    String? id,
    int? difficultyStars,
    String? soundAsset,
    String? correctImage,
    String? category,
    bool? enabled,
  }) {
    return SoundContentItem(
      id: id ?? this.id,
      difficultyStars: difficultyStars ?? this.difficultyStars,
      soundAsset: soundAsset ?? this.soundAsset,
      correctImage: correctImage ?? this.correctImage,
      category: category ?? this.category,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'difficultyStars': difficultyStars,
      'soundAsset': soundAsset,
      'correctImage': correctImage,
      'category': category,
      'enabled': enabled,
    };
  }

  factory SoundContentItem.fromJson(Map<String, dynamic> json) {
    return SoundContentItem(
      id: (json['id'] as String?) ?? '',
      difficultyStars: (json['difficultyStars'] as num?)?.toInt() ?? 1,
      soundAsset: (json['soundAsset'] as String?) ?? '',
      correctImage: (json['correctImage'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      enabled: (json['enabled'] as bool?) ?? true,
    );
  }
}

class PuzzleContentItem {
  const PuzzleContentItem({
    required this.id,
    required this.imageSource,
    this.width = 0,
    this.height = 0,
    this.enabled = true,
  });

  final String id;
  final String imageSource;
  final int width;
  final int height;
  final bool enabled;

  PuzzleContentItem copyWith({
    String? id,
    String? imageSource,
    int? width,
    int? height,
    bool? enabled,
  }) {
    return PuzzleContentItem(
      id: id ?? this.id,
      imageSource: imageSource ?? this.imageSource,
      width: width ?? this.width,
      height: height ?? this.height,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageSource': imageSource,
      'width': width,
      'height': height,
      'enabled': enabled,
    };
  }

  factory PuzzleContentItem.fromJson(Map<String, dynamic> json) {
    return PuzzleContentItem(
      id: (json['id'] as String?) ?? '',
      imageSource: (json['imageSource'] as String?) ?? '',
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      enabled: (json['enabled'] as bool?) ?? true,
    );
  }
}

class GameContentConfig {
  const GameContentConfig({
    this.emotionItems = const [],
    this.soundItems = const [],
    this.puzzleItems = const [],
    this.globalEmotionImageOverrides = const {},
    this.globalSoundImageOverrides = const {},
    this.globalEmotionImageStoragePaths = const {},
    this.globalSoundImageStoragePaths = const {},
    this.updatedAtMillis = 0,
  });

  final List<EmotionContentItem> emotionItems;
  final List<SoundContentItem> soundItems;
  final List<PuzzleContentItem> puzzleItems;
  final Map<String, String> globalEmotionImageOverrides;
  final Map<String, String> globalSoundImageOverrides;
  final Map<String, String> globalEmotionImageStoragePaths;
  final Map<String, String> globalSoundImageStoragePaths;
  final int updatedAtMillis;

  GameContentConfig copyWith({
    List<EmotionContentItem>? emotionItems,
    List<SoundContentItem>? soundItems,
    List<PuzzleContentItem>? puzzleItems,
    Map<String, String>? globalEmotionImageOverrides,
    Map<String, String>? globalSoundImageOverrides,
    Map<String, String>? globalEmotionImageStoragePaths,
    Map<String, String>? globalSoundImageStoragePaths,
    int? updatedAtMillis,
  }) {
    return GameContentConfig(
      emotionItems: emotionItems ?? this.emotionItems,
      soundItems: soundItems ?? this.soundItems,
      puzzleItems: puzzleItems ?? this.puzzleItems,
      globalEmotionImageOverrides:
          globalEmotionImageOverrides ?? this.globalEmotionImageOverrides,
      globalSoundImageOverrides:
          globalSoundImageOverrides ?? this.globalSoundImageOverrides,
      globalEmotionImageStoragePaths:
          globalEmotionImageStoragePaths ?? this.globalEmotionImageStoragePaths,
      globalSoundImageStoragePaths:
          globalSoundImageStoragePaths ?? this.globalSoundImageStoragePaths,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emotionItems': emotionItems.map((item) => item.toJson()).toList(),
      'soundItems': soundItems.map((item) => item.toJson()).toList(),
      'puzzleItems': puzzleItems.map((item) => item.toJson()).toList(),
      'globalEmotionImageOverrides': globalEmotionImageOverrides,
      'globalSoundImageOverrides': globalSoundImageOverrides,
      'globalEmotionImageStoragePaths': globalEmotionImageStoragePaths,
      'globalSoundImageStoragePaths': globalSoundImageStoragePaths,
      'updatedAtMillis': updatedAtMillis,
    };
  }

  factory GameContentConfig.fromJson(Map<String, dynamic> json) {
    return GameContentConfig(
      emotionItems: (json['emotionItems'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => EmotionContentItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      soundItems: (json['soundItems'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => SoundContentItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      puzzleItems: (json['puzzleItems'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => PuzzleContentItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      globalEmotionImageOverrides: Map<String, String>.from(
        json['globalEmotionImageOverrides'] as Map? ?? const {},
      ),
      globalSoundImageOverrides: Map<String, String>.from(
        json['globalSoundImageOverrides'] as Map? ?? const {},
      ),
      globalEmotionImageStoragePaths: Map<String, String>.from(
        json['globalEmotionImageStoragePaths'] as Map? ?? const {},
      ),
      globalSoundImageStoragePaths: Map<String, String>.from(
        json['globalSoundImageStoragePaths'] as Map? ?? const {},
      ),
      updatedAtMillis: (json['updatedAtMillis'] as num?)?.toInt() ?? 0,
    );
  }
}
