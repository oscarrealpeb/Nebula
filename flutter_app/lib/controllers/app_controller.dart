import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/nebula_user.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
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
  AppController._(
    this._authService,
    this._cooldownService,
    this._connectivityService, {
    required bool firebaseEnabled,
  }) : _firebaseEnabled = firebaseEnabled;

  final AuthService _authService;
  final CooldownService _cooldownService;
  final ConnectivityService _connectivityService;
  final bool _firebaseEnabled;

  NebulaUser? _currentUser;
  bool _isOnline = true;
  StreamSubscription<bool>? _connectivitySub;

  static Future<AppController> bootstrap({
    bool firebaseEnabled = false,
    ConnectivityService? connectivityService,
  }) async {
    final store = await LocalStore.create();
    final authService = AuthService(
      store,
      firebaseAuth: firebaseEnabled ? FirebaseAuth.instance : null,
      firestore: firebaseEnabled ? FirebaseFirestore.instance : null,
    );
    final controller = AppController._(
      authService,
      CooldownService(),
      connectivityService ?? InternetConnectivityService(),
      firebaseEnabled: firebaseEnabled,
    );

    controller._currentUser = await authService.restoreSession();
    await controller._runThemeMigrationIfNeeded();
    await controller.refreshOnlineStatus();
    controller._connectivitySub =
        controller._connectivityService.onStatusChanged.listen(
      (online) {
        if (controller._isOnline == online) return;
        controller._isOnline = online;
        controller.notifyListeners();
      },
    );
    return controller;
  }

  NebulaUser? get currentUser => _currentUser;
  bool get isOnline => _isOnline;
  bool get firebaseEnabled => _firebaseEnabled;
  AuthService get authService => _authService;
  bool get isGoogleAccount =>
      _firebaseEnabled && _authService.isCurrentUserGoogleProvider;
  bool get hasPasswordCredential =>
      !_firebaseEnabled || _authService.isCurrentUserPasswordProvider;
  bool get isGoogleOnlyAccount => isGoogleAccount && !hasPasswordCredential;
  bool get parentalPinEnabled =>
      (_currentUser?.parentalPinHash.trim().isNotEmpty ?? false);

  Color get accentColor {
    final user = _currentUser;
    final hue = (user?.accentHue ?? 190).toDouble();
    final intensity =
        (user?.accentIntensity ?? 0.55).clamp(0.72, 1.0).toDouble();
    return HSVColor.fromAHSV(1, hue, 0.71, intensity).toColor();
  }

  // Home UI token from merged branch; mapped to current dynamic accent.
  Color get accentButtonColor => accentColor;

  Future<void> refreshOnlineStatus() async {
    bool online = _isOnline;
    try {
      online = await _connectivityService.isOnlineNow();
    } catch (_) {
      online = _isOnline;
    }
    if (online != _isOnline) {
      _isOnline = online;
      notifyListeners();
    }
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

  Future<ActionResult> loginWithGoogle() async {
    await refreshOnlineStatus();
    if (!_isOnline) {
      return const ActionResult(
        ok: false,
        message:
            'Sin internet. Para entrar con Google, revisa tu conexion e intenta de nuevo.',
      );
    }
    final result = await _authService.loginWithGoogle();
    if (result.ok && result.data != null) {
      _currentUser = result.data;
      notifyListeners();
    }
    return ActionResult(ok: result.ok, message: result.message);
  }

  Future<ActionResult> confirmPendingGoogleLogin({
    String preferredUsernameForNewAccount = '',
    String preferredPasswordForNewAccount = '',
  }) async {
    final result = await _authService.confirmPendingGoogleLogin(
      preferredUsernameForNewAccount: preferredUsernameForNewAccount,
      preferredPasswordForNewAccount: preferredPasswordForNewAccount,
    );
    if (result.ok && result.data != null) {
      _currentUser = result.data;
      notifyListeners();
    }
    return ActionResult(ok: result.ok, message: result.message);
  }

  Future<void> cancelPendingGoogleLogin() async {
    await _authService.cancelPendingGoogleLogin();
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

  Future<ActionResult> updateUsernameForCurrentUser(String newUsername) async {
    final result = await _authService.updateUsernameForCurrentUser(newUsername);
    if (result.ok && result.data != null) {
      _currentUser = result.data;
      notifyListeners();
    }
    return ActionResult(ok: result.ok, message: result.message);
  }

  Future<ActionResult> setPasswordForCurrentUser({
    required String newPassword,
    String parentalPin = '',
  }) async {
    final result = await _authService.setPasswordForCurrentUser(
      newPassword: newPassword,
      parentalPin: parentalPin,
    );
    if (result.ok) {
      final refreshed = await _authService.restoreSession();
      _currentUser = refreshed;
      notifyListeners();
    }
    return ActionResult(ok: result.ok, message: result.message);
  }

  Future<ActionResult> setupGoogleRecoveryPassword({
    required String newPassword,
  }) async {
    final result = await _authService.setupGoogleRecoveryPassword(
      newPassword: newPassword,
    );
    if (result.ok && result.data != null) {
      _currentUser = result.data;
      notifyListeners();
    }
    return ActionResult(ok: result.ok, message: result.message);
  }

  /// Mantiene compatibilidad, pero el cambio en-app esta deshabilitado.
  Future<ActionResult> changePasswordImproved({
    String currentPassword = '',
    required String newPassword,
    String parentalPin = '',
  }) async {
    return const ActionResult(
      ok: false,
      message:
          'El cambio de contraseña en la app esta deshabilitado. Usa el correo de restablecimiento.',
    );
  }

  Future<ActionResult> linkGoogleToExistingAccount({
    required String currentPassword,
  }) async {
    final result = await _authService.linkGoogleToExistingAccount(
      currentPassword: currentPassword,
    );
    if (result.ok) {
      final user = await _authService.restoreSession();
      _currentUser = user;
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
    final normalized = identifier.trim();
    if (normalized.contains('@') &&
        !_authService.isValidEmailFormat(normalized)) {
      return const ActionResult(
        ok: false,
        message: 'Escribe un correo valido.',
      );
    }

    final key = _loginCooldownKey(identifier);
    final remaining = _cooldownService.remainingSeconds(key);
    if (remaining > 0) {
      return ActionResult(
        ok: false,
        message: 'Espera $remaining segundos antes de otra solicitud.',
        remainingSeconds: remaining,
      );
    }
    final result =
        await _authService.sendPasswordResetForIdentifier(identifier);
    if (!result.ok) {
      return ActionResult(ok: false, message: result.message);
    }
    _cooldownService.start(key, const Duration(minutes: 2));
    return const ActionResult(
        ok: true, message: 'Listo. Revisa tu correo.', remainingSeconds: 120);
  }

  Future<ActionResult> requestProfilePasswordReset() async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(ok: false, message: 'No hay sesión activa.');
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
    final result = await _authService.sendPasswordResetForCurrentUser();
    if (!result.ok) {
      return ActionResult(ok: false, message: result.message);
    }
    _cooldownService.start(key, const Duration(minutes: 5));
    return const ActionResult(
        ok: true, message: 'Listo. Revisa tu correo.', remainingSeconds: 300);
  }

  Future<ActionResult> requestEmailChange({
    required String newEmail,
    String currentPassword = '',
    String parentalPin = '',
  }) async {
    return const ActionResult(
      ok: false,
      message: 'El cambio de correo desde la app esta deshabilitado.',
    );
  }

  Future<ActionResult> changePassword({
    String currentPassword = '',
    required String newPassword,
    String parentalPin = '',
  }) async {
    return const ActionResult(
      ok: false,
      message:
          'El cambio de contraseña en la app esta deshabilitado. Usa el correo de restablecimiento.',
    );
  }

  Future<ActionResult> requestDeleteAccount({
    String parentalPin = '',
    String password = '',
  }) async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(ok: false, message: 'No hay sesión activa.');
    }
    if (_firebaseEnabled) {
      await refreshOnlineStatus();
      if (!_isOnline) {
        return const ActionResult(
          ok: false,
          message:
              'Sin internet. Conectate para borrar la cuenta de forma segura.',
        );
      }
    }
    final result = await _authService.deleteCurrentAccount(
      parentalPin: parentalPin,
      password: password,
    );
    if (!result.ok) {
      return ActionResult(ok: false, message: result.message);
    }
    _currentUser = null;
    notifyListeners();
    return ActionResult(ok: true, message: result.message);
  }

  bool isValidParentalPinFormat(String value) {
    return _authService.isValidParentalPinFormat(value);
  }

  Future<ActionResult> activateParentalPin(String pin) async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(ok: false, message: 'No hay sesión activa.');
    }
    final result = await _authService.setParentalPin(pin: pin);
    if (result.ok && result.data != null) {
      _currentUser = result.data;
      notifyListeners();
    }
    return ActionResult(ok: result.ok, message: result.message);
  }

  Future<ActionResult> updateParentalPin({
    required String currentPin,
    required String newPin,
  }) async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(ok: false, message: 'No hay sesión activa.');
    }
    final result = await _authService.changeParentalPin(
      currentPin: currentPin,
      newPin: newPin,
    );
    if (result.ok && result.data != null) {
      _currentUser = result.data;
      notifyListeners();
    }
    return ActionResult(ok: result.ok, message: result.message);
  }

  Future<ActionResult> deactivateParentalPin(String currentPin) async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(ok: false, message: 'No hay sesión activa.');
    }
    final result =
        await _authService.disableParentalPin(currentPin: currentPin);
    if (result.ok && result.data != null) {
      _currentUser = result.data;
      notifyListeners();
    }
    return ActionResult(ok: result.ok, message: result.message);
  }

  Future<ActionResult> requestParentalPinRecoveryEmail() async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(ok: false, message: 'No hay sesión activa.');
    }
    final result = await _authService.sendParentalPinRecoveryEmail();
    return ActionResult(ok: result.ok, message: result.message);
  }

  Future<ActionResult> recoverParentalPinWithPassword({
    required String accountPassword,
    required String newPin,
  }) async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(ok: false, message: 'No hay sesión activa.');
    }
    final result = await _authService.recoverParentalPinWithPassword(
      accountPassword: accountPassword,
      newPin: newPin,
    );
    if (result.ok && result.data != null) {
      _currentUser = result.data;
      notifyListeners();
    }
    return ActionResult(ok: result.ok, message: result.message);
  }

  Future<ActionResult> recoverParentalPinWithGoogle({
    required String newPin,
  }) async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(ok: false, message: 'No hay sesión activa.');
    }
    final result = await _authService.recoverParentalPinWithGoogle(
      newPin: newPin,
    );
    if (result.ok && result.data != null) {
      _currentUser = result.data;
      notifyListeners();
    }
    return ActionResult(ok: result.ok, message: result.message);
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
      return const ActionResult(ok: false, message: 'No hay sesión activa.');
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

  // Usado solo por pruebas/manual.
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

  Future<void> _runThemeMigrationIfNeeded() async {
    final user = _currentUser;
    if (user == null) return;
    final needsMigration = ((user.accentHue - 215).abs() < 0.0001 &&
            (user.accentIntensity - 0.8).abs() < 0.0001) ||
        ((user.accentHue - 205).abs() < 0.0001 &&
            (user.accentIntensity - 0.9).abs() < 0.0001) ||
        ((user.accentHue - 196).abs() < 0.0001 &&
            (user.accentIntensity - 0.8).abs() < 0.0001);
    if (!needsMigration) return;

    final migrated = user.copyWith(accentHue: 255, accentIntensity: 0.776);
    final saved = await _authService.updateUser(migrated);
    if (saved.ok && saved.data != null) {
      _currentUser = saved.data;
    } else {
      _currentUser = migrated;
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _connectivityService.dispose();
    super.dispose();
  }
}
