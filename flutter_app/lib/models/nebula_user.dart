class UserRole {
  static const caregiver = 'caregiver';
  static const admin = 'admin';
}

class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.name,
    this.age = 0,
    this.birthDateMillis = 0,
    this.languageLevel = 'medio',
    this.active = true,
    this.createdAtMillis = 0,
    this.selectedNarratorId = 'narrator_1',
    this.soundEffectsEnabled = true,
    this.accentHue = 190,
    this.accentIntensity = 0.55,
    this.loginUsername = '',
    this.loginPinHash = '',
  });

  final String id;
  final String name;
  final int age;
  final int birthDateMillis;
  final String languageLevel;
  final bool active;
  final int createdAtMillis;
  final String selectedNarratorId;
  final bool soundEffectsEnabled;
  final double accentHue;
  final double accentIntensity;
  final String loginUsername;
  final String loginPinHash;

  ChildProfile copyWith({
    String? id,
    String? name,
    int? age,
    int? birthDateMillis,
    String? languageLevel,
    bool? active,
    int? createdAtMillis,
    String? selectedNarratorId,
    bool? soundEffectsEnabled,
    double? accentHue,
    double? accentIntensity,
    String? loginUsername,
    String? loginPinHash,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      birthDateMillis: birthDateMillis ?? this.birthDateMillis,
      languageLevel: languageLevel ?? this.languageLevel,
      active: active ?? this.active,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      selectedNarratorId: selectedNarratorId ?? this.selectedNarratorId,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      accentHue: accentHue ?? this.accentHue,
      accentIntensity: accentIntensity ?? this.accentIntensity,
      loginUsername: loginUsername ?? this.loginUsername,
      loginPinHash: loginPinHash ?? this.loginPinHash,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'birthDateMillis': birthDateMillis,
      'languageLevel': languageLevel,
      'active': active,
      'createdAtMillis': createdAtMillis,
      'selectedNarratorId': selectedNarratorId,
      'soundEffectsEnabled': soundEffectsEnabled,
      'accentHue': accentHue,
      'accentIntensity': accentIntensity,
      'loginUsername': loginUsername,
      'loginUsernameLower': loginUsername.trim().toLowerCase(),
      'loginPinHash': loginPinHash,
    };
  }

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      birthDateMillis: (json['birthDateMillis'] as num?)?.toInt() ?? 0,
      languageLevel: (json['languageLevel'] as String?) ?? 'medio',
      active: (json['active'] as bool?) ?? true,
      createdAtMillis: (json['createdAtMillis'] as num?)?.toInt() ?? 0,
      selectedNarratorId:
          (json['selectedNarratorId'] as String?) ?? 'narrator_1',
      soundEffectsEnabled: (json['soundEffectsEnabled'] as bool?) ?? true,
      accentHue: (json['accentHue'] as num?)?.toDouble() ?? 190,
      accentIntensity: (json['accentIntensity'] as num?)?.toDouble() ?? 0.55,
      loginUsername: (json['loginUsername'] as String?) ?? '',
      loginPinHash: (json['loginPinHash'] as String?) ?? '',
    );
  }
}

class GameSessionRecord {
  const GameSessionRecord({
    required this.id,
    required this.gameKey,
    required this.startedAtMillis,
    required this.endedAtMillis,
    required this.durationSeconds,
    required this.difficultyStars,
    required this.rounds,
    required this.mistakes,
    required this.pointsEarned,
    this.correctAnswers = 0,
    this.totalAttempts = 0,
  });

  final String id;
  final String gameKey;
  final int startedAtMillis;
  final int endedAtMillis;
  final int durationSeconds;
  final int difficultyStars;
  final int rounds;
  final int mistakes;
  final int pointsEarned;
  final int correctAnswers;
  final int totalAttempts;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameKey': gameKey,
      'startedAtMillis': startedAtMillis,
      'endedAtMillis': endedAtMillis,
      'durationSeconds': durationSeconds,
      'difficultyStars': difficultyStars,
      'rounds': rounds,
      'mistakes': mistakes,
      'pointsEarned': pointsEarned,
      'correctAnswers': correctAnswers,
      'totalAttempts': totalAttempts,
    };
  }

  factory GameSessionRecord.fromJson(Map<String, dynamic> json) {
    return GameSessionRecord(
      id: (json['id'] as String?) ?? '',
      gameKey: (json['gameKey'] as String?) ?? '',
      startedAtMillis: (json['startedAtMillis'] as num?)?.toInt() ?? 0,
      endedAtMillis: (json['endedAtMillis'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      difficultyStars: (json['difficultyStars'] as num?)?.toInt() ?? 1,
      rounds: (json['rounds'] as num?)?.toInt() ?? 0,
      mistakes: (json['mistakes'] as num?)?.toInt() ?? 0,
      pointsEarned: (json['pointsEarned'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      totalAttempts: (json['totalAttempts'] as num?)?.toInt() ?? 0,
    );
  }
}

class ParentalControl {
  const ParentalControl({
    this.dailyLimitMinutes = 0,
    this.allowedStartHour = -1,
    this.allowedEndHour = -1,
    this.blockedGameKeys = const [],
  });

  final int dailyLimitMinutes;
  final int allowedStartHour;
  final int allowedEndHour;
  final List<String> blockedGameKeys;

  bool get hasSchedule =>
      allowedStartHour >= 0 &&
      allowedStartHour <= 23 &&
      allowedEndHour >= 0 &&
      allowedEndHour <= 23 &&
      allowedStartHour != allowedEndHour;

  ParentalControl copyWith({
    int? dailyLimitMinutes,
    int? allowedStartHour,
    int? allowedEndHour,
    List<String>? blockedGameKeys,
  }) {
    return ParentalControl(
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      allowedStartHour: allowedStartHour ?? this.allowedStartHour,
      allowedEndHour: allowedEndHour ?? this.allowedEndHour,
      blockedGameKeys: blockedGameKeys ?? this.blockedGameKeys,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyLimitMinutes': dailyLimitMinutes,
      'allowedStartHour': allowedStartHour,
      'allowedEndHour': allowedEndHour,
      'blockedGameKeys': blockedGameKeys,
    };
  }

  factory ParentalControl.fromJson(Map<String, dynamic> json) {
    return ParentalControl(
      dailyLimitMinutes: (json['dailyLimitMinutes'] as num?)?.toInt() ?? 0,
      allowedStartHour: (json['allowedStartHour'] as num?)?.toInt() ?? -1,
      allowedEndHour: (json['allowedEndHour'] as num?)?.toInt() ?? -1,
      blockedGameKeys: List<String>.from(
        json['blockedGameKeys'] as List? ?? const <String>[],
      ),
    );
  }
}

class NebulaUser {
  const NebulaUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.password,
    required this.parentalPinHash,
    required this.stars,
    required this.avatarIndex,
    required this.selectedNarratorId,
    required this.soundEffectsEnabled,
    required this.accentHue,
    required this.accentIntensity,
    required this.customImages,
    this.role = UserRole.caregiver,
    this.childProfile,
    this.childProfiles = const [],
    this.gameSessions = const [],
    this.parentalControl = const ParentalControl(),
  });

  final String id;
  final String name;
  final String username;
  final String email;
  final String password;
  final String parentalPinHash;
  final int stars;
  final int avatarIndex;
  final String selectedNarratorId;
  final bool soundEffectsEnabled;
  final double accentHue;
  final double accentIntensity;
  final Map<String, String> customImages;
  final String role;
  final ChildProfile? childProfile;
  final List<ChildProfile> childProfiles;
  final List<GameSessionRecord> gameSessions;
  final ParentalControl parentalControl;

  NebulaUser copyWith({
    String? name,
    String? username,
    String? email,
    String? password,
    String? parentalPinHash,
    int? stars,
    int? avatarIndex,
    String? selectedNarratorId,
    bool? soundEffectsEnabled,
    double? accentHue,
    double? accentIntensity,
    Map<String, String>? customImages,
    String? role,
    ChildProfile? childProfile,
    bool clearChildProfile = false,
    List<ChildProfile>? childProfiles,
    List<GameSessionRecord>? gameSessions,
    ParentalControl? parentalControl,
  }) {
    return NebulaUser(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      parentalPinHash: parentalPinHash ?? this.parentalPinHash,
      stars: stars ?? this.stars,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      selectedNarratorId: selectedNarratorId ?? this.selectedNarratorId,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      accentHue: accentHue ?? this.accentHue,
      accentIntensity: accentIntensity ?? this.accentIntensity,
      customImages: customImages ?? this.customImages,
      role: role ?? this.role,
      childProfile:
          clearChildProfile ? null : (childProfile ?? this.childProfile),
      childProfiles: childProfiles ?? this.childProfiles,
      gameSessions: gameSessions ?? this.gameSessions,
      parentalControl: parentalControl ?? this.parentalControl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'password': password,
      'parentalPinHash': parentalPinHash,
      'stars': stars,
      'avatarIndex': avatarIndex,
      'selectedNarratorId': selectedNarratorId,
      'soundEffectsEnabled': soundEffectsEnabled,
      'accentHue': accentHue,
      'accentIntensity': accentIntensity,
      'customImages': customImages,
      'role': role,
      'childProfile': childProfile?.toJson(),
      'childProfiles': childProfiles.map((item) => item.toJson()).toList(),
      'gameSessions': gameSessions.map((item) => item.toJson()).toList(),
      'parentalControl': parentalControl.toJson(),
    };
  }

  factory NebulaUser.fromJson(Map<String, dynamic> json) {
    final parsedChildProfiles = (json['childProfiles'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => ChildProfile.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
    final legacyChildProfile = json['childProfile'] is Map
        ? ChildProfile.fromJson(
            Map<String, dynamic>.from(json['childProfile'] as Map),
          )
        : null;
    final resolvedChildProfiles = parsedChildProfiles.isNotEmpty
        ? parsedChildProfiles
        : (legacyChildProfile == null
            ? const <ChildProfile>[]
            : <ChildProfile>[legacyChildProfile]);
    final resolvedPrimaryChild = legacyChildProfile ??
        (resolvedChildProfiles.isEmpty ? null : resolvedChildProfiles.first);

    return NebulaUser(
      id: json['id'] as String,
      name: json['name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      parentalPinHash: (json['parentalPinHash'] as String?) ?? '',
      stars: (json['stars'] as num?)?.toInt() ?? 0,
      avatarIndex: (json['avatarIndex'] as num?)?.toInt() ?? 0,
      selectedNarratorId: json['selectedNarratorId'] as String? ?? 'narrator_1',
      soundEffectsEnabled: json['soundEffectsEnabled'] as bool? ?? true,
      accentHue: (json['accentHue'] as num?)?.toDouble() ?? 190.0,
      accentIntensity: (json['accentIntensity'] as num?)?.toDouble() ?? 0.55,
      customImages: Map<String, String>.from(
        json['customImages'] as Map? ?? const {},
      ),
      role: (json['role'] as String?) ?? UserRole.caregiver,
      childProfile: resolvedPrimaryChild,
      childProfiles: resolvedChildProfiles,
      gameSessions: (json['gameSessions'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => GameSessionRecord.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      parentalControl: json['parentalControl'] is Map
          ? ParentalControl.fromJson(
              Map<String, dynamic>.from(json['parentalControl'] as Map),
            )
          : const ParentalControl(),
    );
  }
}
