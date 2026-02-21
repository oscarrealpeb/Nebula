import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/nebula_user.dart';

class LocalStore {
  LocalStore._(this._prefs);

  static const _usersKey = 'nebula_users_v1';
  static const _sessionKey = 'nebula_session_user_id_v1';

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

  String? readSessionUserId() {
    return _prefs.getString(_sessionKey);
  }

  Future<void> clearSession() async {
    await _prefs.remove(_sessionKey);
  }
}
