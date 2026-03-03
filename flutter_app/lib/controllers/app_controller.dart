import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/admin_dashboard_models.dart';
import '../core/data/skill_catalog.dart';
import '../models/app_admin_config.dart';
import '../models/game_content_config.dart';
import '../models/nebula_user.dart';
import '../models/portal_role.dart';
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
  static const hiddenAdminEmail = 'admin@nebula.local';
  static const hiddenAdminPassword = 'NebulaAdmin2026';

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
  PortalRole _activePortalRole = PortalRole.caregiver;
  AppAdminConfig _appAdminConfig = const AppAdminConfig();
  GameContentConfig _gameContentConfig = const GameContentConfig();
  AdminDashboardStats _adminDashboardStats = const AdminDashboardStats();
  List<DeletedAccountRecord> _deletedAccounts = const [];
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
    controller._activePortalRole = authService.activePortalRole;
    final configResult = await authService.fetchAppAdminConfig();
    if (configResult.data != null) {
      controller._appAdminConfig = configResult.data!;
    }
    final contentResult = await authService.fetchGameContentConfig();
    if (contentResult.data != null) {
      controller._gameContentConfig = contentResult.data!;
    }
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
  PortalRole get activePortalRole => _activePortalRole;
  AppAdminConfig get appAdminConfig => _appAdminConfig;
  GameContentConfig get gameContentConfig => _gameContentConfig;
  AdminDashboardStats get adminDashboardStats => _adminDashboardStats;
  List<DeletedAccountRecord> get deletedAccounts =>
      List.unmodifiable(_deletedAccounts);
  bool get appInMaintenance => _appAdminConfig.maintenanceMode;
  String get appMaintenanceMessage => _appAdminConfig.maintenanceMessage;
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
  bool get isAdmin => (_currentUser?.role ?? '') == UserRole.admin;
  ChildProfile? get childProfile => _currentUser?.childProfile;
  bool get hasChildProfile => childProfile != null;
  List<GameSessionRecord> get gameSessions => List.unmodifiable(
      _currentUser?.gameSessions ?? const <GameSessionRecord>[]);
  ParentalControl get parentalControl =>
      _currentUser?.parentalControl ?? const ParentalControl();
  String get activeChildName {
    final name = childProfile?.name.trim() ?? '';
    if (name.isNotEmpty) return name;
    return _currentUser?.username ?? 'Explorador';
  }

  Map<String, String> get effectiveGameLabels {
    final labels = <String, String>{...gameLabelByKey};
    _appAdminConfig.gameLabels.forEach((key, value) {
      final normalizedKey = key.trim().toLowerCase();
      final normalizedValue = value.trim();
      if (normalizedKey.isEmpty || normalizedValue.isEmpty) return;
      labels[normalizedKey] = normalizedValue;
    });
    return labels;
  }

  String gameLabelForKey(String gameKey) {
    final key = gameKey.trim().toLowerCase();
    final fromAdmin = _appAdminConfig.gameLabels[key]?.trim() ?? '';
    if (fromAdmin.isNotEmpty) return fromAdmin;
    return gameLabelByKey[key] ?? gameKey;
  }

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
      _activePortalRole = _authService.activePortalRole;
      await reloadGameContentConfig(notify: false);
      notifyListeners();
    }
    return ActionResult(ok: result.ok, message: result.message);
  }

  Future<ActionResult> loginAsCaregiver(
      String identifier, String password) async {
    final result = await _authService.login(
      identifier: identifier,
      password: password,
    );
    if (!result.ok || result.data == null) {
      return ActionResult(ok: result.ok, message: result.message);
    }
    if (result.data!.role == UserRole.admin) {
      await _authService.logout();
      _currentUser = null;
      _activePortalRole = _authService.activePortalRole;
      notifyListeners();
      return const ActionResult(
        ok: false,
        message: 'Esa cuenta es de administrador. Usa acceso admin oculto.',
      );
    }
    _currentUser = result.data;
    _activePortalRole = _authService.activePortalRole;
    await reloadAppAdminConfig(notify: false);
    await reloadGameContentConfig(notify: false);
    notifyListeners();
    return ActionResult(ok: true, message: result.message);
  }

  Future<ActionResult> loginAsAdmin(String identifier, String password) async {
    final result = await _authService.login(
      identifier: identifier,
      password: password,
    );
    if (!result.ok || result.data == null) {
      return ActionResult(ok: result.ok, message: result.message);
    }
    if (result.data!.role != UserRole.admin) {
      await _authService.logout();
      _currentUser = null;
      _activePortalRole = _authService.activePortalRole;
      notifyListeners();
      return const ActionResult(
        ok: false,
        message: 'Esta cuenta no tiene rol administrador.',
      );
    }
    _currentUser = result.data;
    _activePortalRole = _authService.activePortalRole;
    await reloadAppAdminConfig(notify: false);
    await reloadGameContentConfig(notify: false);
    await reloadAdminDashboard(notify: false);
    notifyListeners();
    return ActionResult(ok: true, message: result.message);
  }

  Future<ActionResult> loginAsChild({
    required String username,
    required String password,
  }) async {
    final result = await _authService.loginChild(
      username: username,
      password: password,
    );
    if (result.ok && result.data != null) {
      _currentUser = result.data;
      _activePortalRole = _authService.activePortalRole;
      await reloadAppAdminConfig(notify: false);
      await reloadGameContentConfig(notify: false);
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
      _activePortalRole = _authService.activePortalRole;
      await reloadAppAdminConfig(notify: false);
      await reloadGameContentConfig(notify: false);
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
      _activePortalRole = _authService.activePortalRole;
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
      _activePortalRole = _authService.activePortalRole;
      notifyListeners();
    }
    return ActionResult(ok: result.ok, message: result.message);
  }

  Future<ActionResult> registerCaregiver({
    required String name,
    required String email,
    required String password,
  }) async {
    final result = await _authService.registerCaregiver(
      name: name,
      email: email,
      password: password,
    );
    if (result.ok && result.data != null) {
      _currentUser = result.data;
      _activePortalRole = _authService.activePortalRole;
      notifyListeners();
    }
    return ActionResult(ok: result.ok, message: result.message);
  }

  Future<ActionResult> ensureHiddenAdminAccount() async {
    final result = await _authService.ensureHiddenAdminAccount(
      email: hiddenAdminEmail,
      password: hiddenAdminPassword,
    );
    return ActionResult(ok: result.ok, message: result.message);
  }

  Future<ActionResult> reloadAppAdminConfig({bool notify = true}) async {
    final result = await _authService.fetchAppAdminConfig();
    if (result.data != null) {
      _appAdminConfig = result.data!;
      if (notify) {
        notifyListeners();
      }
      return const ActionResult(ok: true, message: 'Config admin cargada.');
    }
    return ActionResult(ok: result.ok, message: result.message);
  }

  Future<ActionResult> saveAppAdminConfig(AppAdminConfig config) async {
    if (!isAdmin) {
      return const ActionResult(
        ok: false,
        message: 'Solo el admin puede modificar esta configuracion.',
      );
    }
    final result = await _authService.saveAppAdminConfig(config);
    if (result.ok && result.data != null) {
      _appAdminConfig = result.data!;
      notifyListeners();
    }
    return ActionResult(ok: result.ok, message: result.message);
  }

  Future<ActionResult> reloadGameContentConfig({bool notify = true}) async {
    final result = await _authService.fetchGameContentConfig();
    if (result.data != null) {
      _gameContentConfig = result.data!;
      if (notify) {
        notifyListeners();
      }
      return const ActionResult(
        ok: true,
        message: 'Contenido de juegos cargado.',
      );
    }
    return ActionResult(ok: result.ok, message: result.message);
  }

  Future<ActionResult> syncGlobalGameContentForPlay({
    bool notify = false,
  }) async {
    final result = await _authService.fetchGameContentConfig();
    if (result.ok && result.data != null) {
      _gameContentConfig = result.data!;
      if (notify) notifyListeners();
      return ActionResult(ok: true, message: result.message);
    }
    // No bloquea el juego por falta de config global. Se conserva contenido local.
    return ActionResult(ok: true, message: result.message);
  }

  Future<ActionResult> saveGameContentConfig(GameContentConfig config) async {
    if (!isAdmin) {
      return const ActionResult(
        ok: false,
        message: 'Solo el admin puede editar contenido de juegos.',
      );
    }
    final result = await _authService.saveGameContentConfig(config);
    if (result.ok && result.data != null) {
      _gameContentConfig = result.data!;
      notifyListeners();
    }
    return ActionResult(ok: result.ok, message: result.message);
  }

  Future<ActionResult> reloadAdminDashboard({
    int deletedLimit = 120,
    bool notify = true,
  }) async {
    if (!isAdmin) {
      return const ActionResult(
        ok: false,
        message: 'Solo el admin puede ver este dashboard.',
      );
    }

    final statsResult = await _authService.fetchAdminDashboardStats();
    final deletedResult =
        await _authService.fetchDeletedAccounts(limit: deletedLimit);

    var changed = false;
    if (statsResult.data != null) {
      _adminDashboardStats = statsResult.data!;
      changed = true;
    }
    if (deletedResult.data != null) {
      _deletedAccounts = deletedResult.data!;
      changed = true;
    }
    if (notify && changed) {
      notifyListeners();
    }

    final ok = statsResult.ok || deletedResult.ok;
    if (ok) {
      return ActionResult(
        ok: true,
        message: '${statsResult.message} ${deletedResult.message}',
      );
    }
    return ActionResult(
      ok: false,
      message: statsResult.message,
    );
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
    _activePortalRole = _authService.activePortalRole;
    _gameContentConfig = const GameContentConfig();
    _adminDashboardStats = const AdminDashboardStats();
    _deletedAccounts = const [];
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
    _activePortalRole = _authService.activePortalRole;
    _gameContentConfig = const GameContentConfig();
    _adminDashboardStats = const AdminDashboardStats();
    _deletedAccounts = const [];
    notifyListeners();
    return ActionResult(ok: true, message: result.message);
  }

  bool isValidParentalPinFormat(String value) {
    return _authService.isValidParentalPinFormat(value);
  }

  bool isValidChildLoginPinFormat(String value) {
    return _authService.isValidChildLoginPinFormat(value);
  }

  bool verifyCurrentParentalPin(String pin) {
    return _authService.verifyCurrentParentalPin(pin);
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
    final saved = await _authService.updateUser(next, syncCloud: false);
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

  Future<ActionResult> createOrUpdateChildProfile({
    required String name,
    required int age,
    required String languageLevel,
    required String loginUsername,
    String loginPassword = '',
  }) async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(ok: false, message: 'No hay sesion activa.');
    }
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const ActionResult(
        ok: false,
        message: 'Escribe el nombre del ni\u00f1o.',
      );
    }
    final normalizedLoginUsername = loginUsername.trim().toLowerCase();
    if (!_authService.isValidUsernameFormat(normalizedLoginUsername)) {
      return const ActionResult(
        ok: false,
        message:
            'El usuario del ni\u00f1o debe tener 3 a 18 caracteres: letras, numeros, punto, guion y _.',
      );
    }
    final available = await _authService.checkChildLoginUsernameAvailable(
      normalizedLoginUsername,
      excludeCaregiverUserId: user.id,
    );
    if (!available) {
      return const ActionResult(
        ok: false,
        message: 'Ese usuario de ni\u00f1o ya existe. Prueba otro.',
      );
    }
    final trimmedPassword = loginPassword.trim();
    if (trimmedPassword.isNotEmpty &&
        !_authService.isValidChildLoginPinFormat(trimmedPassword)) {
      return const ActionResult(
        ok: false,
        message:
            'La contrase\u00f1a del ni\u00f1o debe tener al menos 6 caracteres.',
      );
    }

    final boundedAge = age.clamp(0, 18);
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = user.childProfile;
    final nextPinHash = trimmedPassword.isNotEmpty
        ? _authService.hashChildLoginPin(trimmedPassword)
        : (existing?.loginPinHash ?? '');
    if (nextPinHash.trim().isEmpty) {
      return const ActionResult(
        ok: false,
        message:
            'Define una contrase\u00f1a del ni\u00f1o para poder iniciar sesi\u00f3n.',
      );
    }
    final child = (existing ??
            ChildProfile(
              id: 'child_${user.id}',
              name: trimmedName,
              createdAtMillis: now,
            ))
        .copyWith(
      name: trimmedName,
      age: boundedAge,
      languageLevel: languageLevel.trim().isEmpty ? 'medio' : languageLevel,
      active: true,
      loginUsername: normalizedLoginUsername,
      loginPinHash: nextPinHash,
    );
    final next = user.copyWith(childProfile: child);
    final saved = await _authService.updateUser(next);
    if (saved.ok && saved.data != null) {
      _currentUser = saved.data;
      notifyListeners();
      return const ActionResult(
        ok: true,
        message: 'Perfil del ni\u00f1o guardado correctamente.',
      );
    }
    return ActionResult(ok: false, message: saved.message);
  }

  Future<ActionResult> updateParentalControl(
      ParentalControl nextControl) async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(ok: false, message: 'No hay sesion activa.');
    }
    final normalized = nextControl.copyWith(
      dailyLimitMinutes: nextControl.dailyLimitMinutes.clamp(0, 24 * 60),
      blockedGameKeys: nextControl.blockedGameKeys
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(),
    );
    final next = user.copyWith(parentalControl: normalized);
    final saved = await _authService.updateUser(next);
    if (saved.ok && saved.data != null) {
      _currentUser = saved.data;
      notifyListeners();
      return const ActionResult(
          ok: true, message: 'Control parental guardado.');
    }
    return ActionResult(ok: false, message: saved.message);
  }

  Future<void> recordGameSession({
    required String gameKey,
    required DateTime startedAt,
    required DateTime endedAt,
    required int difficultyStars,
    required int rounds,
    required int mistakes,
    required int pointsEarned,
    int correctAnswers = 0,
    int totalAttempts = 0,
  }) async {
    final user = _currentUser;
    if (user == null) return;
    final safeEnd = endedAt.isBefore(startedAt) ? startedAt : endedAt;
    final duration =
        safeEnd.difference(startedAt).inSeconds.clamp(0, 24 * 3600);
    final session = GameSessionRecord(
      id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
      gameKey: gameKey.trim().isEmpty ? 'unknown_game' : gameKey.trim(),
      startedAtMillis: startedAt.millisecondsSinceEpoch,
      endedAtMillis: safeEnd.millisecondsSinceEpoch,
      durationSeconds: duration,
      difficultyStars: difficultyStars.clamp(1, 3),
      rounds: rounds.clamp(0, 500),
      mistakes: mistakes.clamp(0, 500),
      pointsEarned: pointsEarned.clamp(0, 1000000),
      correctAnswers: correctAnswers.clamp(0, 500),
      totalAttempts: totalAttempts.clamp(0, 1000),
    );
    final nextSessions = <GameSessionRecord>[
      ...user.gameSessions,
      session,
    ];
    if (nextSessions.length > 1500) {
      nextSessions.removeRange(0, nextSessions.length - 1500);
    }
    final next = user.copyWith(gameSessions: nextSessions);
    final saved = await _authService.updateUser(next);
    if (saved.ok && saved.data != null) {
      _currentUser = saved.data;
      notifyListeners();
    }
  }

  ActionResult canLaunchGame(String gameKey) {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(ok: false, message: 'No hay sesion activa.');
    }
    if (!isAdmin && _appAdminConfig.maintenanceMode) {
      final message = _appAdminConfig.maintenanceMessage.trim().isEmpty
          ? 'La app esta en mantenimiento. Intenta mas tarde.'
          : _appAdminConfig.maintenanceMessage;
      return ActionResult(ok: false, message: message);
    }

    final control = user.parentalControl;
    final normalizedKey = gameKey.trim().toLowerCase();
    final globallyBlocked = _appAdminConfig.blockedGameKeys.any(
      (item) => item.trim().toLowerCase() == normalizedKey,
    );
    if (!isAdmin && globallyBlocked) {
      return const ActionResult(
        ok: false,
        message: 'Este juego esta deshabilitado por administracion.',
      );
    }
    final blocked = control.blockedGameKeys.any(
      (item) => item.trim().toLowerCase() == normalizedKey,
    );
    if (blocked) {
      return const ActionResult(
        ok: false,
        message: 'Este juego esta bloqueado por control parental.',
      );
    }

    if (control.hasSchedule) {
      final hour = DateTime.now().hour;
      final start = control.allowedStartHour;
      final end = control.allowedEndHour;
      final allowed = start < end
          ? (hour >= start && hour < end)
          : (hour >= start || hour < end);
      if (!allowed) {
        return ActionResult(
          ok: false,
          message:
              'Fuera del horario permitido ($start:00 - $end:00). Pide ayuda a un adulto.',
        );
      }
    }

    if (control.dailyLimitMinutes > 0) {
      final used = usedMinutesOn(DateTime.now());
      if (used >= control.dailyLimitMinutes) {
        return ActionResult(
          ok: false,
          message:
              'Limite diario alcanzado (${control.dailyLimitMinutes} min). Vuelve ma\u00f1ana.',
        );
      }
    }
    return const ActionResult(ok: true, message: 'OK');
  }

  int usedMinutesOn(DateTime day) {
    final sessions = _currentUser?.gameSessions ?? const <GameSessionRecord>[];
    var total = 0;
    for (final session in sessions) {
      final started =
          DateTime.fromMillisecondsSinceEpoch(session.startedAtMillis);
      if (_sameLocalDay(started, day)) {
        total += session.durationSeconds;
      }
    }
    return total ~/ 60;
  }

  List<GameSessionRecord> sessionsForLastDays(int days) {
    final user = _currentUser;
    if (user == null) return const <GameSessionRecord>[];
    final safeDays = days.clamp(1, 365);
    final from = DateTime.now().subtract(Duration(days: safeDays));
    return user.gameSessions.where((session) {
      final started =
          DateTime.fromMillisecondsSinceEpoch(session.startedAtMillis);
      return started.isAfter(from);
    }).toList();
  }

  Map<int, int> usageMinutesByHour({int days = 14}) {
    final result = <int, int>{};
    for (var h = 0; h < 24; h++) {
      result[h] = 0;
    }
    final sessions = sessionsForLastDays(days);
    for (final session in sessions) {
      final started =
          DateTime.fromMillisecondsSinceEpoch(session.startedAtMillis);
      final minutes = (session.durationSeconds / 60).round();
      result[started.hour] = (result[started.hour] ?? 0) + minutes;
    }
    return result;
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

  bool _sameLocalDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
