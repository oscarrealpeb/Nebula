import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/nebula_user.dart';

class LocalStore {
  LocalStore._(this._prefs);

  static const _usersKey = 'nebula_users_v1';
  static const _sessionKey = 'nebula_session_user_id_v1';
  static const _sessionPortalRoleKey = 'nebula_session_portal_role_v1';
  static const _adminConfigKey = 'nebula_admin_config_v1';
  static const _gameContentConfigKey = 'nebula_game_content_config_v1';
  static const _deletedAccountsKey = 'nebula_deleted_accounts_v1';
  static const _pendingVerificationKey = 'nebula_pending_verification_v1';

  final SharedPreferences _prefs;

  static Future<LocalStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStore._(prefs);
  }

  Future<List<NebulaUser>> readUsers() async {
    final raw = _prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((item) => NebulaUser.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<void> writeUsers(List<NebulaUser> users) async {
    final serialized = jsonEncode(users.map((e) => e.toJson()).toList());
    await _prefs.setString(_usersKey, serialized);
  }

  Future<void> saveSessionUserId(String userId) async {
    await _prefs.setString(_sessionKey, userId);
  }

  Future<void> saveSessionPortalRole(String role) async {
    await _prefs.setString(_sessionPortalRoleKey, role);
  }

  String? readSessionUserId() {
    return _prefs.getString(_sessionKey);
  }

  String? readSessionPortalRole() {
    return _prefs.getString(_sessionPortalRoleKey);
  }

  Future<void> clearSession() async {
    await _prefs.remove(_sessionKey);
    await _prefs.remove(_sessionPortalRoleKey);
  }

  Map<String, dynamic>? readAdminConfig() {
    final raw = _prefs.getString(_adminConfigKey);
    if (raw == null || raw.trim().isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> writeAdminConfig(Map<String, dynamic> config) async {
    final serialized = jsonEncode(config);
    await _prefs.setString(_adminConfigKey, serialized);
  }

  Map<String, dynamic>? readGameContentConfig() {
    final raw = _prefs.getString(_gameContentConfigKey);
    if (raw == null || raw.trim().isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> writeGameContentConfig(Map<String, dynamic> config) async {
    final serialized = jsonEncode(config);
    await _prefs.setString(_gameContentConfigKey, serialized);
  }

  Future<List<Map<String, dynamic>>> readDeletedAccounts() async {
    final raw = _prefs.getString(_deletedAccountsKey);
    if (raw == null || raw.trim().isEmpty) return <Map<String, dynamic>>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <Map<String, dynamic>>[];
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> writeDeletedAccounts(List<Map<String, dynamic>> records) async {
    final serialized = jsonEncode(records);
    await _prefs.setString(_deletedAccountsKey, serialized);
  }

  Map<String, int> readPendingVerificationMap() {
    final raw = _prefs.getString(_pendingVerificationKey);
    if (raw == null || raw.trim().isEmpty) return <String, int>{};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return <String, int>{};
    final map = <String, int>{};
    decoded.forEach((key, value) {
      if (key is! String) return;
      final millis = (value as num?)?.toInt();
      if (millis == null || millis <= 0) return;
      map[key.trim().toLowerCase()] = millis;
    });
    return map;
  }

  int? readPendingVerificationIssuedAt(String email) {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    final map = readPendingVerificationMap();
    return map[normalized];
  }

  Future<void> writePendingVerificationIssuedAt(
    String email,
    int issuedAtMillis,
  ) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || issuedAtMillis <= 0) return;
    final map = readPendingVerificationMap();
    map[normalized] = issuedAtMillis;
    await _prefs.setString(_pendingVerificationKey, jsonEncode(map));
  }

  Future<void> clearPendingVerificationIssuedAt(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return;
    final map = readPendingVerificationMap();
    if (!map.containsKey(normalized)) return;
    map.remove(normalized);
    if (map.isEmpty) {
      await _prefs.remove(_pendingVerificationKey);
      return;
    }
    await _prefs.setString(_pendingVerificationKey, jsonEncode(map));
  }
}
