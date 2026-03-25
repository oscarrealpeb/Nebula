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
    this.audioSource = '',
    this.width = 0,
    this.height = 0,
    this.enabled = true,
  });

  final String id;
  final String imageSource;
  final String audioSource;
  final int width;
  final int height;
  final bool enabled;

  PuzzleContentItem copyWith({
    String? id,
    String? imageSource,
    String? audioSource,
    int? width,
    int? height,
    bool? enabled,
  }) {
    return PuzzleContentItem(
      id: id ?? this.id,
      imageSource: imageSource ?? this.imageSource,
      audioSource: audioSource ?? this.audioSource,
      width: width ?? this.width,
      height: height ?? this.height,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageSource': imageSource,
      'audioSource': audioSource,
      'width': width,
      'height': height,
      'enabled': enabled,
    };
  }

  factory PuzzleContentItem.fromJson(Map<String, dynamic> json) {
    return PuzzleContentItem(
      id: (json['id'] as String?) ?? '',
      imageSource: (json['imageSource'] as String?) ?? '',
      audioSource: (json['audioSource'] as String?) ?? '',
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      enabled: (json['enabled'] as bool?) ?? true,
    );
  }
}

class DiloContentItem {
  const DiloContentItem({
    required this.id,
    required this.difficultyStars,
    required this.imagePath,
    required this.text,
    required this.audioSource,
    this.enabled = true,
  });

  final String id;
  final int difficultyStars;
  final String imagePath;
  final String text;
  final String audioSource;
  final bool enabled;

  DiloContentItem copyWith({
    String? id,
    int? difficultyStars,
    String? imagePath,
    String? text,
    String? audioSource,
    bool? enabled,
  }) {
    return DiloContentItem(
      id: id ?? this.id,
      difficultyStars: difficultyStars ?? this.difficultyStars,
      imagePath: imagePath ?? this.imagePath,
      text: text ?? this.text,
      audioSource: audioSource ?? this.audioSource,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'difficultyStars': difficultyStars,
      'imagePath': imagePath,
      'text': text,
      'audioSource': audioSource,
      'enabled': enabled,
    };
  }

  factory DiloContentItem.fromJson(Map<String, dynamic> json) {
    return DiloContentItem(
      id: (json['id'] as String?) ?? '',
      difficultyStars: (json['difficultyStars'] as num?)?.toInt() ?? 1,
      imagePath: (json['imagePath'] as String?) ?? '',
      text: (json['text'] as String?) ?? '',
      audioSource: (json['audioSource'] as String?) ?? '',
      enabled: (json['enabled'] as bool?) ?? true,
    );
  }
}

class MemoryContentItem {
  const MemoryContentItem({
    required this.id,
    required this.imagePath,
    this.audioSource = '',
    this.enabled = true,
  });

  final String id;
  final String imagePath;
  final String audioSource;
  final bool enabled;

  MemoryContentItem copyWith({
    String? id,
    String? imagePath,
    String? audioSource,
    bool? enabled,
  }) {
    return MemoryContentItem(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      audioSource: audioSource ?? this.audioSource,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'audioSource': audioSource,
      'enabled': enabled,
    };
  }

  factory MemoryContentItem.fromJson(Map<String, dynamic> json) {
    return MemoryContentItem(
      id: (json['id'] as String?) ?? '',
      imagePath: (json['imagePath'] as String?) ?? '',
      audioSource: (json['audioSource'] as String?) ?? '',
      enabled: (json['enabled'] as bool?) ?? true,
    );
  }
}

class ExploreContentItem {
  const ExploreContentItem({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.description,
    this.enabled = true,
  });

  final String id;
  final String categoryId;
  final String title;
  final String description;
  final bool enabled;

  ExploreContentItem copyWith({
    String? id,
    String? categoryId,
    String? title,
    String? description,
    bool? enabled,
  }) {
    return ExploreContentItem(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'title': title,
      'description': description,
      'enabled': enabled,
    };
  }

  factory ExploreContentItem.fromJson(Map<String, dynamic> json) {
    return ExploreContentItem(
      id: (json['id'] as String?) ?? '',
      categoryId: (json['categoryId'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      enabled: (json['enabled'] as bool?) ?? true,
    );
  }
}

class GameContentConfig {
  const GameContentConfig({
    this.emotionItems = const [],
    this.soundItems = const [],
    this.puzzleItems = const [],
    this.diloItems = const [],
    this.memoryItems = const [],
    this.exploreItems = const [],
    this.globalEmotionImageOverrides = const {},
    this.globalSoundImageOverrides = const {},
    this.globalPuzzleImageOverrides = const {},
    this.globalMemoryImageOverrides = const {},
    this.globalDondeVaImageOverrides = const {},
    this.globalEmotionImageStoragePaths = const {},
    this.globalSoundImageStoragePaths = const {},
    this.globalPuzzleImageStoragePaths = const {},
    this.globalMemoryImageStoragePaths = const {},
    this.globalDondeVaImageStoragePaths = const {},
    this.updatedAtMillis = 0,
  });

  final List<EmotionContentItem> emotionItems;
  final List<SoundContentItem> soundItems;
  final List<PuzzleContentItem> puzzleItems;
  final List<DiloContentItem> diloItems;
  final List<MemoryContentItem> memoryItems;
  final List<ExploreContentItem> exploreItems;
  final Map<String, String> globalEmotionImageOverrides;
  final Map<String, String> globalSoundImageOverrides;
  final Map<String, String> globalPuzzleImageOverrides;
  final Map<String, String> globalMemoryImageOverrides;
  final Map<String, String> globalDondeVaImageOverrides;
  final Map<String, String> globalEmotionImageStoragePaths;
  final Map<String, String> globalSoundImageStoragePaths;
  final Map<String, String> globalPuzzleImageStoragePaths;
  final Map<String, String> globalMemoryImageStoragePaths;
  final Map<String, String> globalDondeVaImageStoragePaths;
  final int updatedAtMillis;

  GameContentConfig copyWith({
    List<EmotionContentItem>? emotionItems,
    List<SoundContentItem>? soundItems,
    List<PuzzleContentItem>? puzzleItems,
    List<DiloContentItem>? diloItems,
    List<MemoryContentItem>? memoryItems,
    List<ExploreContentItem>? exploreItems,
    Map<String, String>? globalEmotionImageOverrides,
    Map<String, String>? globalSoundImageOverrides,
    Map<String, String>? globalPuzzleImageOverrides,
    Map<String, String>? globalMemoryImageOverrides,
    Map<String, String>? globalDondeVaImageOverrides,
    Map<String, String>? globalEmotionImageStoragePaths,
    Map<String, String>? globalSoundImageStoragePaths,
    Map<String, String>? globalPuzzleImageStoragePaths,
    Map<String, String>? globalMemoryImageStoragePaths,
    Map<String, String>? globalDondeVaImageStoragePaths,
    int? updatedAtMillis,
  }) {
    return GameContentConfig(
      emotionItems: emotionItems ?? this.emotionItems,
      soundItems: soundItems ?? this.soundItems,
      puzzleItems: puzzleItems ?? this.puzzleItems,
      diloItems: diloItems ?? this.diloItems,
      memoryItems: memoryItems ?? this.memoryItems,
      exploreItems: exploreItems ?? this.exploreItems,
      globalEmotionImageOverrides:
          globalEmotionImageOverrides ?? this.globalEmotionImageOverrides,
      globalSoundImageOverrides:
          globalSoundImageOverrides ?? this.globalSoundImageOverrides,
      globalPuzzleImageOverrides:
          globalPuzzleImageOverrides ?? this.globalPuzzleImageOverrides,
      globalMemoryImageOverrides:
          globalMemoryImageOverrides ?? this.globalMemoryImageOverrides,
      globalDondeVaImageOverrides:
          globalDondeVaImageOverrides ?? this.globalDondeVaImageOverrides,
      globalEmotionImageStoragePaths:
          globalEmotionImageStoragePaths ?? this.globalEmotionImageStoragePaths,
      globalSoundImageStoragePaths:
          globalSoundImageStoragePaths ?? this.globalSoundImageStoragePaths,
      globalPuzzleImageStoragePaths:
          globalPuzzleImageStoragePaths ?? this.globalPuzzleImageStoragePaths,
      globalMemoryImageStoragePaths:
          globalMemoryImageStoragePaths ?? this.globalMemoryImageStoragePaths,
      globalDondeVaImageStoragePaths:
          globalDondeVaImageStoragePaths ??
          this.globalDondeVaImageStoragePaths,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emotionItems': emotionItems.map((item) => item.toJson()).toList(),
      'soundItems': soundItems.map((item) => item.toJson()).toList(),
      'puzzleItems': puzzleItems.map((item) => item.toJson()).toList(),
      'diloItems': diloItems.map((item) => item.toJson()).toList(),
      'memoryItems': memoryItems.map((item) => item.toJson()).toList(),
      'exploreItems': exploreItems.map((item) => item.toJson()).toList(),
      'globalEmotionImageOverrides': globalEmotionImageOverrides,
      'globalSoundImageOverrides': globalSoundImageOverrides,
      'globalPuzzleImageOverrides': globalPuzzleImageOverrides,
      'globalMemoryImageOverrides': globalMemoryImageOverrides,
      'globalDondeVaImageOverrides': globalDondeVaImageOverrides,
      'globalEmotionImageStoragePaths': globalEmotionImageStoragePaths,
      'globalSoundImageStoragePaths': globalSoundImageStoragePaths,
      'globalPuzzleImageStoragePaths': globalPuzzleImageStoragePaths,
      'globalMemoryImageStoragePaths': globalMemoryImageStoragePaths,
      'globalDondeVaImageStoragePaths': globalDondeVaImageStoragePaths,
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
      diloItems: (json['diloItems'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => DiloContentItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      memoryItems: (json['memoryItems'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => MemoryContentItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      exploreItems: (json['exploreItems'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => ExploreContentItem.fromJson(
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
      globalPuzzleImageOverrides: Map<String, String>.from(
        json['globalPuzzleImageOverrides'] as Map? ?? const {},
      ),
      globalMemoryImageOverrides: Map<String, String>.from(
        json['globalMemoryImageOverrides'] as Map? ?? const {},
      ),
      globalDondeVaImageOverrides: Map<String, String>.from(
        json['globalDondeVaImageOverrides'] as Map? ?? const {},
      ),
      globalEmotionImageStoragePaths: Map<String, String>.from(
        json['globalEmotionImageStoragePaths'] as Map? ?? const {},
      ),
      globalSoundImageStoragePaths: Map<String, String>.from(
        json['globalSoundImageStoragePaths'] as Map? ?? const {},
      ),
      globalPuzzleImageStoragePaths: Map<String, String>.from(
        json['globalPuzzleImageStoragePaths'] as Map? ?? const {},
      ),
      globalMemoryImageStoragePaths: Map<String, String>.from(
        json['globalMemoryImageStoragePaths'] as Map? ?? const {},
      ),
      globalDondeVaImageStoragePaths: Map<String, String>.from(
        json['globalDondeVaImageStoragePaths'] as Map? ?? const {},
      ),
      updatedAtMillis: (json['updatedAtMillis'] as num?)?.toInt() ?? 0,
    );
  }
}
