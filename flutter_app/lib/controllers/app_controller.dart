import 'dart:async';

import 'package:flutter/material.dart';

import '../models/nebula_user.dart';
import '../services/auth_service.dart';
import '../services/cooldown_service.dart';
import '../services/local_store.dart';

class ActionResult {
  const ActionResult({
    required this.ok,
    required this.message,
    this.remainingSeconds = 0,
  });

  final bool ok;
  final String message;
  final int remainingSeconds;
}

class AppController extends ChangeNotifier {
  AppController._(this._authService, this._cooldownService);

  final AuthService _authService;
  final CooldownService _cooldownService;

  NebulaUser? _currentUser;
  bool _isOnline = true;

  static Future<AppController> bootstrap() async {
    final store = await LocalStore.create();
    final authService = AuthService(store);
    final controller = AppController._(authService, CooldownService());
    controller._currentUser = await authService.restoreSession();
    final user = controller._currentUser;
    final needsMigration = user != null &&
        (((user.accentHue - 215).abs() < 0.0001 &&
                (user.accentIntensity - 0.8).abs() < 0.0001) ||
            ((user.accentHue - 205).abs() < 0.0001 &&
                (user.accentIntensity - 0.9).abs() < 0.0001));
    if (needsMigration) {
      final migrated = user.copyWith(accentHue: 196, accentIntensity: 0.97);
      final saved = await authService.updateUser(migrated);
      if (saved.ok && saved.data != null) {
        controller._currentUser = saved.data;
      } else {
        controller._currentUser = migrated;
      }
    }
    return controller;
  }

  NebulaUser? get currentUser => _currentUser;
  bool get isOnline => _isOnline;

  Color get accentColor {
    final user = _currentUser;
    final hue = (user?.accentHue ?? 196).toDouble();
    final intensity = (user?.accentIntensity ?? 0.97).clamp(0.72, 1.0).toDouble();
    return HSVColor.fromAHSV(1, hue, 0.78, intensity).toColor();
  }

  Future<ActionResult> login(String identifier, String password) async {
    final result = await _authService.login(
      identifier: identifier,
      password: password,
    );
    if (result.ok && result.data != null) {
      _currentUser = result.data;
      notifyListeners();
    }
    return ActionResult(ok: result.ok, message: result.message);
  }

  Future<ActionResult> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final result = await _authService.register(
      name: name,
      username: username,
      email: email,
      password: password,
    );
    if (result.ok && result.data != null) {
      _currentUser = result.data;
      notifyListeners();
    }
    return ActionResult(ok: result.ok, message: result.message);
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<ActionResult> requestLoginPasswordReset(String identifier) async {
    final key = _loginCooldownKey(identifier);
    final remaining = _cooldownService.remainingSeconds(key);
    if (remaining > 0) {
      return ActionResult(
        ok: false,
        message: 'Espera $remaining segundos antes de otra solicitud.',
        remainingSeconds: remaining,
      );
    }

    final exists = await _authService.existsEmailOrUsername(identifier);
    if (!exists) {
      return const ActionResult(
        ok: false,
        message: 'Escribe un correo o apodo que ya este registrado.',
      );
    }

    _cooldownService.start(key, const Duration(minutes: 2));
    return const ActionResult(
      ok: true,
      message: 'Te enviamos un correo para crear una nueva contrasena.',
      remainingSeconds: 120,
    );
  }

  Future<ActionResult> requestProfilePasswordReset() async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(ok: false, message: 'No hay sesion activa.');
    }
    final key = 'profile_reset_${user.id}';
    final remaining = _cooldownService.remainingSeconds(key);
    if (remaining > 0) {
      return ActionResult(
        ok: false,
        message: 'Espera ${_formatTime(remaining)} para otra solicitud.',
        remainingSeconds: remaining,
      );
    }
    _cooldownService.start(key, const Duration(minutes: 5));
    return const ActionResult(
      ok: true,
      message: 'Listo. Te enviamos un correo para cambiar tu contrasena.',
      remainingSeconds: 300,
    );
  }

  Future<ActionResult> requestEmailChange() async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(ok: false, message: 'No hay sesion activa.');
    }
    return ActionResult(
      ok: true,
      message: 'Revisa tu correo (${user.email}), te enviamos un enlace de cambio.',
    );
  }

  Future<ActionResult> requestDeleteAccount() async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(ok: false, message: 'No hay sesion activa.');
    }
    return ActionResult(
      ok: true,
      message: 'Enviamos un correo a ${user.email} para confirmar el borrado de la cuenta.',
    );
  }

  int loginResetRemaining(String identifier) {
    return _cooldownService.remainingSeconds(_loginCooldownKey(identifier));
  }

  int profileResetRemaining() {
    final user = _currentUser;
    if (user == null) return 0;
    return _cooldownService.remainingSeconds('profile_reset_${user.id}');
  }

  Future<ActionResult> saveProfile({
    required String name,
    required String username,
    required int avatarIndex,
  }) async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(ok: false, message: 'No hay sesion activa.');
    }

    final result = await _authService.updateProfile(
      userId: user.id,
      name: name,
      username: username,
      avatarIndex: avatarIndex,
    );
    if (result.ok && result.data != null) {
      _currentUser = result.data;
      notifyListeners();
    }
    return ActionResult(ok: result.ok, message: result.message);
  }

  Future<void> addStars(int value) async {
    final user = _currentUser;
    if (user == null) return;
    final next = user.copyWith(stars: user.stars + value);
    final saved = await _authService.updateUser(next);
    if (saved.ok && saved.data != null) {
      _currentUser = saved.data;
      notifyListeners();
    }
  }

  Future<void> setNarrator(String narratorId) async {
    final user = _currentUser;
    if (user == null) return;
    final next = user.copyWith(selectedNarratorId: narratorId);
    final saved = await _authService.updateUser(next);
    if (saved.ok && saved.data != null) {
      _currentUser = saved.data;
      notifyListeners();
    }
  }

  Future<void> setSoundEffects(bool enabled) async {
    final user = _currentUser;
    if (user == null) return;
    final next = user.copyWith(soundEffectsEnabled: enabled);
    final saved = await _authService.updateUser(next);
    if (saved.ok && saved.data != null) {
      _currentUser = saved.data;
      notifyListeners();
    }
  }

  Future<void> setThemeColor({
    required double hue,
    required double intensity,
  }) async {
    final user = _currentUser;
    if (user == null) return;
    final next = user.copyWith(accentHue: hue, accentIntensity: intensity);
    _currentUser = next;
    notifyListeners();

    unawaited(() async {
      final saved = await _authService.updateUser(next);
      if (saved.ok && saved.data != null) {
        final current = _currentUser;
        if (current == null || current.id != saved.data!.id) {
          return;
        }
        final hueMatches = (current.accentHue - next.accentHue).abs() < 0.0001;
        final intensityMatches =
            (current.accentIntensity - next.accentIntensity).abs() < 0.0001;
        if (!hueMatches || !intensityMatches) {
          return;
        }
        _currentUser = saved.data;
        notifyListeners();
      }
    }());
  }

  Future<void> updateCustomImage({
    required String key,
    required String imagePath,
  }) async {
    final user = _currentUser;
    if (user == null) return;
    final nextMap = Map<String, String>.from(user.customImages);
    nextMap[key] = imagePath;
    final next = user.copyWith(customImages: nextMap);
    final saved = await _authService.updateUser(next);
    if (saved.ok && saved.data != null) {
      _currentUser = saved.data;
      notifyListeners();
    }
  }

  void setOnline(bool value) {
    _isOnline = value;
    notifyListeners();
  }

  String formatSeconds(int seconds) => _formatTime(seconds);

  String _loginCooldownKey(String identifier) {
    return 'login_reset_${identifier.trim().toLowerCase()}';
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final rem = seconds % 60;
    final remText = rem.toString().padLeft(2, '0');
    return '$minutes:$remText';
  }
}
