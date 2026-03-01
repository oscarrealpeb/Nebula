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

class GameContentConfig {
  const GameContentConfig({
    this.emotionItems = const [],
    this.soundItems = const [],
    this.updatedAtMillis = 0,
  });

  final List<EmotionContentItem> emotionItems;
  final List<SoundContentItem> soundItems;
  final int updatedAtMillis;

  GameContentConfig copyWith({
    List<EmotionContentItem>? emotionItems,
    List<SoundContentItem>? soundItems,
    int? updatedAtMillis,
  }) {
    return GameContentConfig(
      emotionItems: emotionItems ?? this.emotionItems,
      soundItems: soundItems ?? this.soundItems,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emotionItems': emotionItems.map((item) => item.toJson()).toList(),
      'soundItems': soundItems.map((item) => item.toJson()).toList(),
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
      updatedAtMillis: (json['updatedAtMillis'] as num?)?.toInt() ?? 0,
    );
  }
}
