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
}
