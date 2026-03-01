class DeletedAccountRecord {
  const DeletedAccountRecord({
    required this.id,
    required this.userId,
    required this.email,
    required this.username,
    required this.role,
    required this.deletedAtMillis,
    this.reason = '',
    this.hadChildProfile = false,
    this.sessionCount = 0,
  });

  final String id;
  final String userId;
  final String email;
  final String username;
  final String role;
  final int deletedAtMillis;
  final String reason;
  final bool hadChildProfile;
  final int sessionCount;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'email': email,
      'username': username,
      'role': role,
      'deletedAtMillis': deletedAtMillis,
      'reason': reason,
      'hadChildProfile': hadChildProfile,
      'sessionCount': sessionCount,
    };
  }

  factory DeletedAccountRecord.fromJson(Map<String, dynamic> json) {
    return DeletedAccountRecord(
      id: (json['id'] as String?) ?? '',
      userId: (json['userId'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      username: (json['username'] as String?) ?? '',
      role: (json['role'] as String?) ?? '',
      deletedAtMillis: (json['deletedAtMillis'] as num?)?.toInt() ?? 0,
      reason: (json['reason'] as String?) ?? '',
      hadChildProfile: (json['hadChildProfile'] as bool?) ?? false,
      sessionCount: (json['sessionCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminDashboardStats {
  const AdminDashboardStats({
    this.totalUsers = 0,
    this.caregiverUsers = 0,
    this.adminUsers = 0,
    this.usersWithChildProfile = 0,
    this.activeChildProfiles = 0,
    this.totalGameSessions = 0,
    this.sessionsLast7Days = 0,
    this.totalUsageMinutes = 0,
    this.usageMinutesLast7Days = 0,
    this.averageAccuracyPercent = 0,
    this.deletedAccounts = 0,
    this.deletedAccountsLast30Days = 0,
    this.sessionsByGame = const {},
    this.refreshedAtMillis = 0,
    this.source = 'local',
  });

  final int totalUsers;
  final int caregiverUsers;
  final int adminUsers;
  final int usersWithChildProfile;
  final int activeChildProfiles;
  final int totalGameSessions;
  final int sessionsLast7Days;
  final int totalUsageMinutes;
  final int usageMinutesLast7Days;
  final double averageAccuracyPercent;
  final int deletedAccounts;
  final int deletedAccountsLast30Days;
  final Map<String, int> sessionsByGame;
  final int refreshedAtMillis;
  final String source;

  AdminDashboardStats copyWith({
    int? totalUsers,
    int? caregiverUsers,
    int? adminUsers,
    int? usersWithChildProfile,
    int? activeChildProfiles,
    int? totalGameSessions,
    int? sessionsLast7Days,
    int? totalUsageMinutes,
    int? usageMinutesLast7Days,
    double? averageAccuracyPercent,
    int? deletedAccounts,
    int? deletedAccountsLast30Days,
    Map<String, int>? sessionsByGame,
    int? refreshedAtMillis,
    String? source,
  }) {
    return AdminDashboardStats(
      totalUsers: totalUsers ?? this.totalUsers,
      caregiverUsers: caregiverUsers ?? this.caregiverUsers,
      adminUsers: adminUsers ?? this.adminUsers,
      usersWithChildProfile:
          usersWithChildProfile ?? this.usersWithChildProfile,
      activeChildProfiles: activeChildProfiles ?? this.activeChildProfiles,
      totalGameSessions: totalGameSessions ?? this.totalGameSessions,
      sessionsLast7Days: sessionsLast7Days ?? this.sessionsLast7Days,
      totalUsageMinutes: totalUsageMinutes ?? this.totalUsageMinutes,
      usageMinutesLast7Days:
          usageMinutesLast7Days ?? this.usageMinutesLast7Days,
      averageAccuracyPercent:
          averageAccuracyPercent ?? this.averageAccuracyPercent,
      deletedAccounts: deletedAccounts ?? this.deletedAccounts,
      deletedAccountsLast30Days:
          deletedAccountsLast30Days ?? this.deletedAccountsLast30Days,
      sessionsByGame: sessionsByGame ?? this.sessionsByGame,
      refreshedAtMillis: refreshedAtMillis ?? this.refreshedAtMillis,
      source: source ?? this.source,
    );
  }
}
