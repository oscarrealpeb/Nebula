class AppAdminConfig {
  const AppAdminConfig({
    this.maintenanceMode = false,
    this.maintenanceMessage = '',
    this.minimumVersion = '',
    this.blockedGameKeys = const [],
    this.gameLabels = const {},
    this.updatedAtMillis = 0,
  });

  final bool maintenanceMode;
  final String maintenanceMessage;
  final String minimumVersion;
  final List<String> blockedGameKeys;
  final Map<String, String> gameLabels;
  final int updatedAtMillis;

  AppAdminConfig copyWith({
    bool? maintenanceMode,
    String? maintenanceMessage,
    String? minimumVersion,
    List<String>? blockedGameKeys,
    Map<String, String>? gameLabels,
    int? updatedAtMillis,
  }) {
    return AppAdminConfig(
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      maintenanceMessage: maintenanceMessage ?? this.maintenanceMessage,
      minimumVersion: minimumVersion ?? this.minimumVersion,
      blockedGameKeys: blockedGameKeys ?? this.blockedGameKeys,
      gameLabels: gameLabels ?? this.gameLabels,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maintenanceMode': maintenanceMode,
      'maintenanceMessage': maintenanceMessage,
      'minimumVersion': minimumVersion,
      'blockedGameKeys': blockedGameKeys,
      'gameLabels': gameLabels,
      'updatedAtMillis': updatedAtMillis,
    };
  }

  factory AppAdminConfig.fromJson(Map<String, dynamic> json) {
    final labelsRaw = json['gameLabels'] as Map?;
    return AppAdminConfig(
      maintenanceMode: (json['maintenanceMode'] as bool?) ?? false,
      maintenanceMessage: (json['maintenanceMessage'] as String?) ?? '',
      minimumVersion: (json['minimumVersion'] as String?) ?? '',
      blockedGameKeys: List<String>.from(
        json['blockedGameKeys'] as List? ?? const <String>[],
      ),
      gameLabels: labelsRaw == null
          ? const {}
          : labelsRaw.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            ),
      updatedAtMillis: (json['updatedAtMillis'] as num?)?.toInt() ?? 0,
    );
  }
}
