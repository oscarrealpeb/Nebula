class NebulaUser {
  const NebulaUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.password,
    required this.stars,
    required this.avatarIndex,
    required this.selectedNarratorId,
    required this.soundEffectsEnabled,
    required this.accentHue,
    required this.accentIntensity,
    required this.customImages,
  });

  final String id;
  final String name;
  final String username;
  final String email;
  final String password;
  final int stars;
  final int avatarIndex;
  final String selectedNarratorId;
  final bool soundEffectsEnabled;
  final double accentHue;
  final double accentIntensity;
  final Map<String, String> customImages;

  NebulaUser copyWith({
    String? name,
    String? username,
    String? email,
    String? password,
    int? stars,
    int? avatarIndex,
    String? selectedNarratorId,
    bool? soundEffectsEnabled,
    double? accentHue,
    double? accentIntensity,
    Map<String, String>? customImages,
  }) {
    return NebulaUser(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      stars: stars ?? this.stars,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      selectedNarratorId: selectedNarratorId ?? this.selectedNarratorId,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      accentHue: accentHue ?? this.accentHue,
      accentIntensity: accentIntensity ?? this.accentIntensity,
      customImages: customImages ?? this.customImages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'password': password,
      'stars': stars,
      'avatarIndex': avatarIndex,
      'selectedNarratorId': selectedNarratorId,
      'soundEffectsEnabled': soundEffectsEnabled,
      'accentHue': accentHue,
      'accentIntensity': accentIntensity,
      'customImages': customImages,
    };
  }

  factory NebulaUser.fromJson(Map<String, dynamic> json) {
    return NebulaUser(
      id: json['id'] as String,
      name: json['name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      stars: (json['stars'] as num?)?.toInt() ?? 0,
      avatarIndex: (json['avatarIndex'] as num?)?.toInt() ?? 0,
      selectedNarratorId: json['selectedNarratorId'] as String? ?? 'narrator_1',
      soundEffectsEnabled: json['soundEffectsEnabled'] as bool? ?? true,
      accentHue: (json['accentHue'] as num?)?.toDouble() ?? 196.0,
      accentIntensity: (json['accentIntensity'] as num?)?.toDouble() ?? 0.97,
      customImages: Map<String, String>.from(
        json['customImages'] as Map? ?? const {},
      ),
    );
  }
}
