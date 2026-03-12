import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/admin_dashboard_models.dart';
import '../core/data/achievement_catalog.dart';
import '../core/data/puzzle_catalog.dart';
import '../core/data/skill_catalog.dart';
import '../models/app_admin_config.dart';
import '../models/game_content_config.dart';
import '../models/nebula_user.dart';
import '../models/portal_role.dart';
import '../core/data/planet_ladder.dart';
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
  static const hiddenAdminPassword = '123456';

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
  String _activeChildProfileId = '';
  bool _needsPortalSelection = false;
  bool _isOnline = true;
  StreamSubscription<bool>? _connectivitySub;
  Future<void> _starUpdateQueue = Future<void>.value();
  String? _pendingHomeLevelUpPlanetName;
  final List<String> _pendingAchievementUnlockIds = <String>[];

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
    controller._activeChildProfileId = _resolveActiveChildId(
      user: controller._currentUser,
      requestedChildId: '',
    );
    controller._needsPortalSelection =
        controller._shouldAskPortalSelectionOnAppOpen();
    final configResult = await authService.fetchAppAdminConfig();
    if (configResult.data != null) {
      controller._appAdminConfig = configResult.data!;
    }
    final contentResult = await authService.fetchGameContentConfig();
    if (contentResult.data != null) {
      controller._gameContentConfig = contentResult.data!;
    }
    await controller._syncAchievementsFromProgress(
      queueNotification: false,
      notifyUi: false,
    );
    await controller._runThemeMigrationIfNeeded();
    await controller.refreshOnlineStatus();
    controller._connectivitySub =
        controller._connectivityService.onStatusChanged.listen(
      (online) {
        if (controller._isOnline == online) return;
        controller._isOnline = online;
        if (online) {
          unawaited(controller._authService.syncCurrentUserToCloudBestEffort());
        }
        controller.notifyListeners();
      },
    );
    return controller;
  }

  NebulaUser? get currentUser => _currentUser;
  PortalRole get activePortalRole => _activePortalRole;
  AppAdminConfig get appAdminConfig => _appAdminConfig;
  GameContentConfig get gameContentConfig => _gameContentConfig;
  List<String> get puzzleImageSources {
    final fromAdmin = _gameContentConfig.puzzleItems
        .where((item) => item.enabled)
        .map((item) => item.imageSource.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (fromAdmin.isEmpty) {
      return List<String>.from(defaultPuzzleImageSources);
    }
    final merged = <String>[
      ...fromAdmin,
      ...defaultPuzzleImageSources.where((item) => !fromAdmin.contains(item)),
    ];
    return merged;
  }

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
  String get activeChildProfileId => _activeChildProfileId;
  List<ChildProfile> get childProfiles {
    final user = _currentUser;
    if (user == null) return const <ChildProfile>[];
    if (user.childProfiles.isNotEmpty) {
      return List.unmodifiable(user.childProfiles);
    }
    if (user.childProfile != null) {
      return List.unmodifiable(<ChildProfile>[user.childProfile!]);
    }
    return const <ChildProfile>[];
  }

  ChildProfile? get childProfile {
    final profiles = childProfiles;
    if (profiles.isEmpty) return null;
    final activeId = _activeChildProfileId.trim();
    if (activeId.isNotEmpty) {
      for (final item in profiles) {
        if (item.id == activeId) return item;
      }
    }
    return profiles.first;
  }

  int get progressStars {
    final user = _currentUser;
    if (user == null) return 0;
    if (isAdmin) return user.stars;
    final activeChild = childProfile;
    if (activeChild != null) return activeChild.stars;
    return user.stars;
  }

  List<String> get progressUnlockedAchievementIds {
    final user = _currentUser;
    if (user == null) return const <String>[];
    if (isAdmin) return List<String>.unmodifiable(user.unlockedAchievementIds);
    final activeChild = childProfile;
    if (activeChild != null) {
      return List<String>.unmodifiable(activeChild.unlockedAchievementIds);
    }
    return List<String>.unmodifiable(user.unlockedAchievementIds);
  }

  bool get hasChildProfile => childProfile != null;
  bool get needsChildOnboarding => !isAdmin && childProfiles.isEmpty;
  bool get needsPortalSelection =>
      !isAdmin &&
      _currentUser != null &&
      childProfiles.isNotEmpty &&
      _needsPortalSelection;
  String? consumePendingHomeLevelUpPlanetName() {
    final value = _pendingHomeLevelUpPlanetName;
    _pendingHomeLevelUpPlanetName = null;
    return value;
  }

  List<AchievementDefinition> consumePendingAchievementUnlocks() {
    if (_pendingAchievementUnlockIds.isEmpty) {
      return const <AchievementDefinition>[];
    }
    final ids = List<String>.from(_pendingAchievementUnlockIds);
    _pendingAchievementUnlockIds.clear();
    final result = <AchievementDefinition>[];
    for (final id in ids) {
      final definition = achievementById(id);
      if (definition != null) {
        result.add(definition);
      }
    }
    return result;
  }

  bool isAchievementUnlocked(String achievementId) {
    return progressUnlockedAchievementIds.any((id) => id == achievementId);
  }

  List<GameSessionRecord> get gameSessions => List.unmodifiable(
      _currentUser?.gameSessions ?? const <GameSessionRecord>[]);

  int maxUnlockedDifficultyByPerfectRounds({
    required String gameKey,
    int easyToMediumPerfectRounds = 10,
    int mediumToHardPerfectRounds = 15,
  }) {
    final normalizedKey = gameKey.trim().toLowerCase();
    if (normalizedKey.isEmpty) return 1;
    final safeEasyTarget = easyToMediumPerfectRounds.clamp(1, 100000).toInt();
    final safeMediumTarget = mediumToHardPerfectRounds.clamp(1, 100000).toInt();

    var easyPerfectRounds = 0;
    var mediumPerfectRounds = 0;
    final sessions = _sessionsForScope();
    for (final session in sessions) {
      if (session.gameKey.trim().toLowerCase() != normalizedKey) continue;
      final safePerfectRounds = session.perfectRounds.clamp(0, 500).toInt();
      if (session.difficultyStars <= 1) {
        easyPerfectRounds += safePerfectRounds;
      } else if (session.difficultyStars == 2) {
        mediumPerfectRounds += safePerfectRounds;
      }
    }

    if (easyPerfectRounds < safeEasyTarget) return 1;
    if (mediumPerfectRounds < safeMediumTarget) return 2;
    return 3;
  }

  ParentalControl get parentalControl =>
      _currentUser?.parentalControl ?? const ParentalControl();
  String get selectedNarratorId {
    final childValue = childProfile?.selectedNarratorId.trim() ?? '';
    if (childValue.isNotEmpty) return childValue;
    return _currentUser?.selectedNarratorId ?? 'narrator_1';
  }

  bool get soundEffectsEnabled {
    final child = childProfile;
    if (child != null) return child.soundEffectsEnabled;
    return _currentUser?.soundEffectsEnabled ?? true;
  }

  double get currentAccentHue {
    final child = childProfile;
    if (child != null) return child.accentHue;
    return (_currentUser?.accentHue ?? 190).toDouble();
  }

  double get currentAccentIntensity {
    final child = childProfile;
    if (child != null) {
      return child.accentIntensity.clamp(0.65, 1.0).toDouble();
    }
    return (_currentUser?.accentIntensity ?? 0.55).clamp(0.65, 1.0).toDouble();
  }

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
    final hue = currentAccentHue;
    final intensity = currentAccentIntensity;
    return HSVColor.fromAHSV(1, hue, 0.60, intensity).toColor();
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
      _activeChildProfileId = _resolveActiveChildId(
        user: _currentUser,
        requestedChildId: '',
      );
      _needsPortalSelection = _shouldAskPortalSelectionAfterAuth();
      await _syncAchievementsFromProgress(
        queueNotification: false,
        notifyUi: false,
      );
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
    _activePortalRole = PortalRole.caregiver;
    _activeChildProfileId = _resolveActiveChildId(
      user: _currentUser,
      requestedChildId: '',
    );
    _needsPortalSelection = _shouldAskPortalSelectionAfterAuth();
    await _syncAchievementsFromProgress(
      queueNotification: false,
      notifyUi: false,
    );
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
    _activeChildProfileId = _resolveActiveChildId(
      user: _currentUser,
      requestedChildId: '',
    );
    _needsPortalSelection = false;
    await _syncAchievementsFromProgress(
      queueNotification: false,
      notifyUi: false,
    );
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
    return const ActionResult(
      ok: false,
      message:
          'El acceso directo de niño ya no está disponible. Entra con la cuenta del cuidador y luego elige el perfil del niño.',
    );
  }

  Future<ActionResult> loginWithGoogle() async {
    await refreshOnlineStatus();
    if (!_isOnline) {
      return const ActionResult(
        ok: false,
        message:
            'Sin internet. Para entrar con Google, revisa tu conexión e intenta de nuevo.',
      );
    }
    final result = await _authService.loginWithGoogle();
    if (result.ok && result.data != null) {
      _currentUser = result.data;
      _activePortalRole = PortalRole.caregiver;
      _activeChildProfileId = _resolveActiveChildId(
        user: _currentUser,
        requestedChildId: '',
      );
      _needsPortalSelection = _shouldAskPortalSelectionAfterAuth();
      await _syncAchievementsFromProgress(
        queueNotification: false,
        notifyUi: false,
      );
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
      _activePortalRole = PortalRole.caregiver;
      _activeChildProfileId = _resolveActiveChildId(
        user: _currentUser,
        requestedChildId: '',
      );
      _needsPortalSelection = _shouldAskPortalSelectionAfterAuth();
      await _syncAchievementsFromProgress(
        queueNotification: false,
        notifyUi: false,
      );
      await reloadAppAdminConfig(notify: false);
      await reloadGameContentConfig(notify: false);
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
      _activePortalRole = PortalRole.caregiver;
      _activeChildProfileId = _resolveActiveChildId(
        user: _currentUser,
        requestedChildId: '',
      );
      _needsPortalSelection = _shouldAskPortalSelectionAfterAuth();
      await _syncAchievementsFromProgress(
        queueNotification: false,
        notifyUi: false,
      );
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
      _activePortalRole = PortalRole.caregiver;
      _activeChildProfileId = _resolveActiveChildId(
        user: _currentUser,
        requestedChildId: '',
      );
      _needsPortalSelection = _shouldAskPortalSelectionAfterAuth();
      await _syncAchievementsFromProgress(
        queueNotification: false,
        notifyUi: false,
      );
      notifyListeners();
    }
    return ActionResult(ok: result.ok, message: result.message);
  }

  Future<ActionResult> enterChildPortal(String childId) async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(ok: false, message: 'No hay sesión activa.');
    }
    if (isAdmin) {
      return const ActionResult(
        ok: false,
        message: 'El admin no usa portal de niño.',
      );
    }
    final targetId = childId.trim();
    if (targetId.isEmpty) {
      return const ActionResult(
        ok: false,
        message: 'Selecciona un perfil de niño.',
      );
    }
    final exists = childProfiles.any((item) => item.id == targetId);
    if (!exists) {
      return const ActionResult(
        ok: false,
        message: 'Ese perfil de niño no existe.',
      );
    }
    _activeChildProfileId = targetId;
    _activePortalRole = PortalRole.child;
    _needsPortalSelection = false;

    final selectedChild =
        childProfiles.firstWhere((item) => item.id == targetId);
    final nextPrimary = user.copyWith(
      childProfile: selectedChild,
      childProfiles: childProfiles,
    );
    final saved = await _authService.updateUser(nextPrimary);
    if (saved.ok && saved.data != null) {
      _currentUser = saved.data;
    }
    await _authService.persistPortalRole(PortalRole.child);
    notifyListeners();
    return const ActionResult(ok: true, message: 'Portal niño listo.');
  }

  Future<ActionResult> enterCaregiverPortal({
    required String password,
  }) async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(ok: false, message: 'No hay sesión activa.');
    }
    if (isAdmin) {
      _activePortalRole = PortalRole.admin;
      _needsPortalSelection = false;
      notifyListeners();
      return const ActionResult(ok: true, message: 'Portal admin listo.');
    }
    final typed = password.trim();
    if (typed.isEmpty) {
      return const ActionResult(
        ok: false,
        message: 'Escribe la contraseña del cuidador.',
      );
    }
    final valid = await _authService.verifyCurrentUserPassword(typed);
    if (!valid.ok) {
      return ActionResult(ok: false, message: valid.message);
    }
    _activePortalRole = PortalRole.caregiver;
    _needsPortalSelection = false;
    await _authService.persistPortalRole(PortalRole.caregiver);
    notifyListeners();
    return const ActionResult(ok: true, message: 'Portal cuidador listo.');
  }

  Future<ActionResult> setCaregiverChildContext(String childId) async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(ok: false, message: 'No hay sesión activa.');
    }
    if (isAdmin) {
      return const ActionResult(
        ok: false,
        message: 'El admin no usa perfiles de niño.',
      );
    }
    final targetId = childId.trim();
    if (targetId.isEmpty) {
      return const ActionResult(
        ok: false,
        message: 'Selecciona un perfil de niño.',
      );
    }
    final list = childProfiles;
    final exists = list.any((item) => item.id == targetId);
    if (!exists) {
      return const ActionResult(
        ok: false,
        message: 'Ese perfil de niño no existe.',
      );
    }

    final selectedChild = list.firstWhere((item) => item.id == targetId);
    _activeChildProfileId = targetId;
    final nextPrimary = user.copyWith(
      childProfile: selectedChild,
      childProfiles: list,
    );
    final saved = await _authService.updateUser(nextPrimary);
    if (saved.ok && saved.data != null) {
      _currentUser = saved.data;
      _activeChildProfileId = _resolveActiveChildId(
        user: _currentUser,
        requestedChildId: targetId,
      );
      notifyListeners();
      return const ActionResult(
        ok: true,
        message: 'Perfil activo actualizado.',
      );
    }
    return ActionResult(ok: false, message: saved.message);
  }

  void markPortalSelectionPending() {
    if (_currentUser == null || isAdmin || childProfiles.isEmpty) return;
    _needsPortalSelection = true;
    notifyListeners();
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
        message: 'Solo el admin puede modificar esta configuración.',
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
      _activeChildProfileId = _resolveActiveChildId(
        user: _currentUser,
        requestedChildId: _activeChildProfileId,
      );
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

  /// Mantiene compatibilidad, pero el cambio en-app está deshabilitado.
  Future<ActionResult> changePasswordImproved({
    String currentPassword = '',
    required String newPassword,
    String parentalPin = '',
  }) async {
    return const ActionResult(
      ok: false,
      message:
          'El cambio de contraseña en la app está deshabilitado. Usa el correo de restablecimiento.',
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
      _activePortalRole = _authService.activePortalRole;
      _activeChildProfileId = _resolveActiveChildId(
        user: _currentUser,
        requestedChildId: _activeChildProfileId,
      );
      _needsPortalSelection = _shouldAskPortalSelectionAfterAuth();
      notifyListeners();
    }
    return ActionResult(ok: result.ok, message: result.message);
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _activePortalRole = _authService.activePortalRole;
    _activeChildProfileId = '';
    _needsPortalSelection = false;
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
        message: 'Escribe un correo válido.',
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

  Future<ActionResult> resendLoginVerificationEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!_authService.isValidEmailFormat(normalizedEmail)) {
      return const ActionResult(
        ok: false,
        message: 'Escribe un correo válido para reenviar verificación.',
      );
    }
    if (password.trim().isEmpty) {
      return const ActionResult(
        ok: false,
        message: 'Escribe la contraseña para reenviar verificación.',
      );
    }

    final key = 'verify_resend_$normalizedEmail';
    final remaining = _cooldownService.remainingSeconds(key);
    if (remaining > 0) {
      return ActionResult(
        ok: false,
        message: 'Espera $remaining segundos antes de reenviar.',
        remainingSeconds: remaining,
      );
    }

    final result = await _authService.resendVerificationEmailForCredentials(
      email: normalizedEmail,
      password: password,
    );
    if (!result.ok) {
      return ActionResult(ok: false, message: result.message);
    }

    _cooldownService.start(key, const Duration(minutes: 1));
    return const ActionResult(
      ok: true,
      message: 'Reenvío solicitado. Revisa tu correo.',
      remainingSeconds: 60,
    );
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
      message: 'El cambio de correo desde la app está deshabilitado.',
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
          'El cambio de contraseña en la app está deshabilitado. Usa el correo de restablecimiento.',
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
    _activeChildProfileId = '';
    _needsPortalSelection = false;
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
    if (value == 0) return;
    _starUpdateQueue = _starUpdateQueue.then((_) async {
      final user = _currentUser;
      if (user == null) return;
      var next = user;
      var previousStars = user.stars;
      var nextStars = (user.stars + value).clamp(0, 1000000000).toInt();

      if (!isAdmin) {
        final active = childProfile;
        if (active != null) {
          previousStars = active.stars;
          nextStars = (active.stars + value).clamp(0, 1000000000).toInt();
          final updatedChild = active.copyWith(stars: nextStars);
          next = _upsertChildProfile(next, updatedChild);
          final aggregateStars = next.childProfiles.fold<int>(
            0,
            (acc, item) => acc + item.stars.clamp(0, 1000000000).toInt(),
          );
          next = next.copyWith(stars: aggregateStars);
        } else {
          next = next.copyWith(stars: nextStars);
        }
      } else {
        next = next.copyWith(stars: nextStars);
      }

      next = _syncLegacyProgressFromChildren(next);
      final currentProgressStars = (!isAdmin && childProfile != null)
          ? nextStars
          : next.stars;
      final previousPlanet = planetForStars(previousStars);
      final nextPlanet = planetForStars(currentProgressStars);
      final previousIndex = planetLadder.indexOf(previousPlanet);
      final nextIndex = planetLadder.indexOf(nextPlanet);
      if (nextIndex > previousIndex) {
        _pendingHomeLevelUpPlanetName = nextPlanet.name;
      }
      _currentUser = next;
      notifyListeners();
      final saved = await _authService.updateUser(next);
      if (saved.ok && saved.data != null) {
        _currentUser = saved.data;
        notifyListeners();
      }
    });
    await _starUpdateQueue;
  }

  Future<void> setNarrator(String narratorId) async {
    final user = _currentUser;
    if (user == null) return;
    final normalizedNarrator = narratorId.trim();
    if (normalizedNarrator.isEmpty) return;

    var next = user.copyWith(selectedNarratorId: normalizedNarrator);
    final active = childProfile;
    if (active != null && !isAdmin) {
      final updatedChild = active.copyWith(
        selectedNarratorId: normalizedNarrator,
      );
      next = _upsertChildProfile(next, updatedChild);
    }
    final saved = await _authService.updateUser(next);
    if (saved.ok && saved.data != null) {
      _currentUser = saved.data;
      _activeChildProfileId = _resolveActiveChildId(
        user: _currentUser,
        requestedChildId: _activeChildProfileId,
      );
      notifyListeners();
    }
  }

  Future<void> setSoundEffects(bool enabled) async {
    final user = _currentUser;
    if (user == null) return;

    var next = user.copyWith(soundEffectsEnabled: enabled);
    final active = childProfile;
    if (active != null && !isAdmin) {
      final updatedChild = active.copyWith(
        soundEffectsEnabled: enabled,
      );
      next = _upsertChildProfile(next, updatedChild);
    }
    final saved = await _authService.updateUser(next);
    if (saved.ok && saved.data != null) {
      _currentUser = saved.data;
      _activeChildProfileId = _resolveActiveChildId(
        user: _currentUser,
        requestedChildId: _activeChildProfileId,
      );
      notifyListeners();
    }
  }

  Future<void> setThemeColor({
    required double hue,
    required double intensity,
  }) async {
    final user = _currentUser;
    if (user == null) return;
    final safeIntensity = intensity.clamp(0.65, 1.0).toDouble();
    final targetChildId = (childProfile?.id ?? '').trim();
    var next = user.copyWith(accentHue: hue, accentIntensity: safeIntensity);
    final active = childProfile;
    if (active != null && !isAdmin) {
      final updatedChild = active.copyWith(
        accentHue: hue,
        accentIntensity: safeIntensity,
      );
      next = _upsertChildProfile(next, updatedChild);
    }
    _currentUser = next;
    _activeChildProfileId = _resolveActiveChildId(
      user: _currentUser,
      requestedChildId: _activeChildProfileId,
    );
    notifyListeners();

    unawaited(() async {
      final saved = await _authService.updateUser(next);
      if (saved.ok && saved.data != null) {
        final current = _currentUser;
        if (current == null || current.id != saved.data!.id) return;

        if (targetChildId.isEmpty) {
          final hueMatches = (current.accentHue - hue).abs() < 0.0001;
          final intensityMatches =
              (current.accentIntensity - safeIntensity).abs() < 0.0001;
          if (!hueMatches || !intensityMatches) return;
        } else {
          final currentProfiles = current.childProfiles.isNotEmpty
              ? current.childProfiles
              : (current.childProfile == null
                  ? const <ChildProfile>[]
                  : <ChildProfile>[current.childProfile!]);
          ChildProfile? currentChild;
          for (final profile in currentProfiles) {
            if (profile.id != targetChildId) continue;
            currentChild = profile;
            break;
          }
          if (currentChild == null) return;
          final hueMatches = (currentChild.accentHue - hue).abs() < 0.0001;
          final intensityMatches =
              (currentChild.accentIntensity - safeIntensity).abs() < 0.0001;
          if (!hueMatches || !intensityMatches) return;
        }

        _currentUser = saved.data;
        _activeChildProfileId = _resolveActiveChildId(
          user: _currentUser,
          requestedChildId: _activeChildProfileId,
        );
        notifyListeners();
      }
    }());
  }

  String? customImagePathFor({
    required String key,
    String childId = '',
  }) {
    final user = _currentUser;
    if (user == null) return null;
    final normalizedKey = key.trim().toLowerCase();
    if (normalizedKey.isEmpty) return null;

    final directChildId = childId.trim();
    final activeId =
        directChildId.isNotEmpty ? directChildId : _activeChildProfileId;
    final childScopedKey = _scopedCustomImageKey(
      baseKey: normalizedKey,
      childId: activeId,
    );
    if (childScopedKey != null) {
      final scoped = user.customImages[childScopedKey]?.trim() ?? '';
      if (scoped.isNotEmpty) return scoped;
    }

    final global = user.customImages[normalizedKey]?.trim() ?? '';
    if (global.isNotEmpty) return global;
    return null;
  }

  Future<void> updateCustomImage({
    required String key,
    required String imagePath,
    String childId = '',
  }) async {
    final user = _currentUser;
    if (user == null) return;
    final normalizedKey = key.trim().toLowerCase();
    final normalizedPath = imagePath.trim();
    if (normalizedKey.isEmpty || normalizedPath.isEmpty) return;

    final nextMap = Map<String, String>.from(user.customImages);
    final targetKey = _scopedCustomImageKey(
          baseKey: normalizedKey,
          childId: childId.trim().isEmpty ? _activeChildProfileId : childId,
        ) ??
        normalizedKey;
    nextMap[targetKey] = normalizedPath;
    final next = user.copyWith(customImages: nextMap);
    final saved = await _authService.updateUser(next);
    if (saved.ok && saved.data != null) {
      _currentUser = saved.data;
      _activeChildProfileId = _resolveActiveChildId(
        user: _currentUser,
        requestedChildId: _activeChildProfileId,
      );
      notifyListeners();
    }
  }

  Future<ActionResult> createOrUpdateChildProfile({
    String childId = '',
    required String name,
    required int birthDateMillis,
    required int age,
  }) async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(ok: false, message: 'No hay sesión activa.');
    }
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const ActionResult(
        ok: false,
        message: 'Escribe el nombre del ni\u00f1o.',
      );
    }
    final editingExisting = childId.trim().isNotEmpty;
    if (birthDateMillis <= 0 && !editingExisting) {
      return const ActionResult(
        ok: false,
        message: 'Selecciona la fecha de nacimiento del ni\u00f1o.',
      );
    }
    final normalizedName = trimmedName.toLowerCase();
    final existingProfiles = List<ChildProfile>.from(childProfiles);
    final duplicate = existingProfiles.any((item) {
      if (childId.trim().isNotEmpty && item.id == childId.trim()) return false;
      if (birthDateMillis <= 0) return false;
      return item.name.trim().toLowerCase() == normalizedName &&
          item.birthDateMillis == birthDateMillis;
    });
    if (duplicate) {
      return const ActionResult(
        ok: false,
        message: 'Ya existe un perfil con ese nombre y fecha de nacimiento.',
      );
    }

    final boundedAge = age.clamp(0, 18);
    final now = DateTime.now().millisecondsSinceEpoch;
    final targetChildId =
        childId.trim().isNotEmpty ? childId.trim() : 'child_${user.id}_$now';
    final index =
        existingProfiles.indexWhere((item) => item.id == targetChildId);
    final base = index >= 0 ? existingProfiles[index] : null;
    final child = (base ??
            ChildProfile(
              id: targetChildId,
              name: trimmedName,
              createdAtMillis: now,
              selectedNarratorId: user.selectedNarratorId,
              soundEffectsEnabled: user.soundEffectsEnabled,
              accentHue: user.accentHue,
              accentIntensity: user.accentIntensity,
            ))
        .copyWith(
      id: targetChildId,
      name: trimmedName,
      age: boundedAge,
      birthDateMillis:
          birthDateMillis > 0 ? birthDateMillis : (base?.birthDateMillis ?? 0),
      languageLevel: base?.languageLevel ?? 'medio',
      active: true,
    );
    if (index >= 0) {
      existingProfiles[index] = child;
    } else {
      existingProfiles.add(child);
    }
    _activeChildProfileId = child.id;
    final next = user.copyWith(
      childProfile: child,
      childProfiles: existingProfiles,
    );
    final saved = await _authService.updateUser(next);
    if (saved.ok && saved.data != null) {
      _currentUser = saved.data;
      _activeChildProfileId = _resolveActiveChildId(
        user: _currentUser,
        requestedChildId: child.id,
      );
      _needsPortalSelection = _shouldAskPortalSelectionAfterAuth();
      notifyListeners();
      return ActionResult(
        ok: true,
        message: index >= 0
            ? 'Perfil del ni\u00f1o actualizado correctamente.'
            : 'Perfil del ni\u00f1o creado correctamente.',
      );
    }
    return ActionResult(ok: false, message: saved.message);
  }

  Future<ActionResult> updateParentalControl(
      ParentalControl nextControl) async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(ok: false, message: 'No hay sesión activa.');
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

  ({
    NebulaUser user,
    ChildProfile demoChild,
    bool existed,
  }) _buildDemoSeededUser(
    NebulaUser user, {
    DateTime? referenceNow,
  }) {
    final now = referenceNow ?? DateTime.now();
    final nowMillis = now.millisecondsSinceEpoch;
    final demoChildId = 'child_${user.id}_demo_reports';
    final sourceProfiles = user.childProfiles.isNotEmpty
        ? user.childProfiles
        : (user.childProfile == null
            ? const <ChildProfile>[]
            : <ChildProfile>[user.childProfile!]);
    final existingProfiles = List<ChildProfile>.from(sourceProfiles);
    final existingIndex =
        existingProfiles.indexWhere((item) => item.id == demoChildId);

    final birthDate = DateTime(now.year - 8, now.month, now.day);
    final baseChild = existingIndex >= 0
        ? existingProfiles[existingIndex]
        : ChildProfile(
            id: demoChildId,
            name: 'Perfil demo',
            createdAtMillis: nowMillis,
            selectedNarratorId: user.selectedNarratorId,
            soundEffectsEnabled: user.soundEffectsEnabled,
            accentHue: user.accentHue,
            accentIntensity: user.accentIntensity,
          );

    final demoChild = baseChild.copyWith(
      id: demoChildId,
      name: 'Perfil demo',
      age: 8,
      birthDateMillis: birthDate.millisecondsSinceEpoch,
      active: true,
      createdAtMillis:
          baseChild.createdAtMillis > 0 ? baseChild.createdAtMillis : nowMillis,
    );

    if (existingIndex >= 0) {
      existingProfiles[existingIndex] = demoChild;
    } else {
      existingProfiles.add(demoChild);
    }

    final keptSessions = user.gameSessions.where((session) {
      final isDemoSession = session.id.startsWith('demo_session_');
      return !(session.childId == demoChildId && isDemoSession);
    }).toList();

    final gameSeeds = <Map<String, dynamic>>[
      {'key': 'descubre_emocion', 'accuracy': 0.90},
      {'key': 'conecta_sonidos', 'accuracy': 0.76},
      {'key': 'di_palabra', 'accuracy': 0.58},
      {'key': 'explora_aprende', 'accuracy': 0.80},
      {'key': 'cartas_gemelas', 'accuracy': 0.72},
      {'key': 'que_sigue', 'accuracy': 0.63},
      {'key': 'donde_va', 'accuracy': 0.68},
      {'key': 'arma_imagen', 'accuracy': 0.84},
    ];

    final generated = <GameSessionRecord>[];
    const totalSessions = 24;
    for (var i = 0; i < totalSessions; i++) {
      final seed = gameSeeds[i % gameSeeds.length];
      final gameKey = (seed['key'] as String).trim();
      final baseAccuracy = (seed['accuracy'] as double);
      final jitter = ((i % 5) - 2) * 0.025;
      final accuracy = (baseAccuracy + jitter).clamp(0.45, 0.97).toDouble();
      final rounds = 8 + (i % 5);
      final totalAttempts = rounds;
      final correctAnswers = (rounds * accuracy).round().clamp(0, rounds);
      final mistakes = (totalAttempts - correctAnswers).clamp(0, totalAttempts);
      final durationSeconds = (rounds * 20) + (mistakes * 9) + (i % 33);

      final startedAt = DateTime(
        now.year,
        now.month,
        now.day,
        8 + ((i * 2) % 11),
        (i * 11) % 60,
      ).subtract(Duration(days: totalSessions - i));
      final endedAt = startedAt.add(Duration(seconds: durationSeconds));

      generated.add(
        GameSessionRecord(
          id: 'demo_session_${i + 1}',
          gameKey: gameKey,
          startedAtMillis: startedAt.millisecondsSinceEpoch,
          endedAtMillis: endedAt.millisecondsSinceEpoch,
          durationSeconds: durationSeconds,
          difficultyStars: (1 + (i % 3)).clamp(1, 3),
          rounds: rounds,
          mistakes: mistakes,
          pointsEarned: (correctAnswers * 12) - (mistakes * 2),
          correctAnswers: correctAnswers,
          totalAttempts: totalAttempts,
          childId: demoChildId,
        ),
      );
    }

    final nextSessions = <GameSessionRecord>[
      ...keptSessions,
      ...generated,
    ];
    nextSessions.sort((a, b) => a.startedAtMillis.compareTo(b.startedAtMillis));
    if (nextSessions.length > 1500) {
      nextSessions.removeRange(0, nextSessions.length - 1500);
    }

    final next = user.copyWith(
      childProfile: demoChild,
      childProfiles: existingProfiles,
      gameSessions: nextSessions,
    );
    return (user: next, demoChild: demoChild, existed: existingIndex >= 0);
  }

  Future<ActionResult> seedDemoChildForReports() async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(ok: false, message: 'No hay sesión activa.');
    }
    if (isAdmin) {
      return const ActionResult(
        ok: false,
        message:
            'El perfil demo solo está disponible para cuentas de cuidador.',
      );
    }

    final seeded = _buildDemoSeededUser(user);
    final saved = await _authService.updateUser(seeded.user);
    if (!saved.ok || saved.data == null) {
      return ActionResult(
        ok: false,
        message: saved.message.trim().isEmpty
            ? 'No se pudo crear el perfil de ejemplo.'
            : saved.message,
      );
    }

    _currentUser = saved.data;
    _activeChildProfileId = _resolveActiveChildId(
      user: _currentUser,
      requestedChildId: seeded.demoChild.id,
    );
    _needsPortalSelection = _shouldAskPortalSelectionAfterAuth();
    notifyListeners();
    await _syncAchievementsFromProgress();

    return ActionResult(
      ok: true,
      message: seeded.existed
          ? 'Perfil demo actualizado con datos de ejemplo.'
          : 'Perfil demo creado con datos de ejemplo.',
    );
  }

  Future<ActionResult> seedDemoChildForReportsForAllUsers() async {
    final current = _currentUser;
    if (current == null) {
      return const ActionResult(ok: false, message: 'No hay sesiÃ³n activa.');
    }
    if (!isAdmin) {
      return const ActionResult(
        ok: false,
        message: 'Solo el admin puede aplicar datos demo a todos los usuarios.',
      );
    }

    final usersResult = await _authService.listLocalUsers();
    if (!usersResult.ok || usersResult.data == null) {
      return ActionResult(
        ok: false,
        message: usersResult.message.trim().isEmpty
            ? 'No se pudieron leer los usuarios.'
            : usersResult.message,
      );
    }

    final caregivers = usersResult.data!
        .where((item) => item.role.trim().toLowerCase() != UserRole.admin)
        .toList();
    if (caregivers.isEmpty) {
      return const ActionResult(
        ok: true,
        message: 'No hay cuentas de cuidador para actualizar.',
      );
    }

    final now = DateTime.now();
    final seededUsers = <NebulaUser>[];
    var createdCount = 0;
    var updatedCount = 0;

    for (final user in caregivers) {
      final seeded = _buildDemoSeededUser(user, referenceNow: now);
      seededUsers.add(seeded.user);
      if (seeded.existed) {
        updatedCount += 1;
      } else {
        createdCount += 1;
      }
    }

    final saveResult = await _authService.upsertUsersSilently(seededUsers);
    if (!saveResult.ok) {
      return ActionResult(
        ok: false,
        message: saveResult.message.trim().isEmpty
            ? 'No se pudieron aplicar los datos demo.'
            : saveResult.message,
      );
    }

    await reloadAdminDashboard();
    notifyListeners();

    final total = saveResult.data ?? seededUsers.length;
    return ActionResult(
      ok: true,
      message:
          'Perfil demo aplicado en $total cuentas ($createdCount creadas, $updatedCount actualizadas).',
    );
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
    String childId = '',
    int perfectRounds = 0,
  }) async {
    final user = _currentUser;
    if (user == null) return;
    final safeEnd = endedAt.isBefore(startedAt) ? startedAt : endedAt;
    final duration =
        safeEnd.difference(startedAt).inSeconds.clamp(0, 24 * 3600);
    final normalizedChildId = childId.trim().isNotEmpty
        ? childId.trim()
        : _activeChildProfileId.trim();
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
      childId: normalizedChildId,
      perfectRounds: perfectRounds.clamp(0, 500),
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
    await _syncAchievementsFromProgress();
  }

  ActionResult canLaunchGame(String gameKey) {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(ok: false, message: 'No hay sesión activa.');
    }
    if (!isAdmin && _appAdminConfig.maintenanceMode) {
      final message = _appAdminConfig.maintenanceMessage.trim().isEmpty
          ? 'La app está en mantenimiento. Intenta más tarde.'
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
        message: 'Este juego está deshabilitado por administración.',
      );
    }
    final blocked = control.blockedGameKeys.any(
      (item) => item.trim().toLowerCase() == normalizedKey,
    );
    if (blocked) {
      return const ActionResult(
        ok: false,
        message: 'Este juego está bloqueado por control parental.',
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

  int usedMinutesOn(
    DateTime day, {
    String childId = '',
  }) {
    final sessions = _sessionsForScope(childId: childId);
    var total = 0;
    for (final session in sessions) {
      final started =
          DateTime.fromMillisecondsSinceEpoch(session.startedAtMillis);
      if (_sameLocalDay(started, day)) {
        total += _effectiveSessionDurationSeconds(session);
      }
    }
    return total ~/ 60;
  }

  List<GameSessionRecord> sessionsForLastDays(
    int days, {
    String childId = '',
  }) {
    final safeDays = days.clamp(1, 365);
    final from = DateTime.now().subtract(Duration(days: safeDays));
    final sessions = _sessionsForScope(childId: childId);
    return sessions.where((session) {
      final started =
          DateTime.fromMillisecondsSinceEpoch(session.startedAtMillis);
      return started.isAfter(from) || started.isAtSameMomentAs(from);
    }).toList();
  }

  Map<int, int> usageMinutesByHour({
    int days = 14,
    String childId = '',
  }) {
    final result = <int, int>{};
    for (var h = 0; h < 24; h++) {
      result[h] = 0;
    }
    final sessions = sessionsForLastDays(days, childId: childId);
    for (final session in sessions) {
      final started =
          DateTime.fromMillisecondsSinceEpoch(session.startedAtMillis);
      final minutes = (_effectiveSessionDurationSeconds(session) / 60).round();
      result[started.hour] = (result[started.hour] ?? 0) + minutes;
    }
    return result;
  }

  int _effectiveSessionDurationSeconds(GameSessionRecord session) {
    final stored = session.durationSeconds.clamp(0, 24 * 3600);
    if (stored > 0) return stored;

    final startedAt = session.startedAtMillis;
    final endedAt = session.endedAtMillis;
    if (startedAt <= 0 || endedAt <= startedAt) return 0;

    final inferred = ((endedAt - startedAt) ~/ 1000).clamp(0, 24 * 3600);
    return inferred;
  }

  List<GameSessionRecord> _sessionsForScope({String childId = ''}) {
    final user = _currentUser;
    if (user == null) return const <GameSessionRecord>[];
    final sessions = user.gameSessions;
    final scopedChildId = _resolveMetricsChildId(childId);
    if (scopedChildId.isEmpty) {
      return sessions;
    }
    final includeUnassigned = _shouldIncludeUnassignedSessions(scopedChildId);
    return sessions.where((session) {
      final sessionChildId = session.childId.trim();
      if (sessionChildId == scopedChildId) return true;
      if (includeUnassigned && sessionChildId.isEmpty) return true;
      return false;
    }).toList();
  }

  String _resolveMetricsChildId(String explicitChildId) {
    final normalized = explicitChildId.trim();
    if (normalized.isNotEmpty) return normalized;
    if (isAdmin) return '';
    return _activeChildProfileId.trim();
  }

  bool _shouldIncludeUnassignedSessions(String childId) {
    final children = childProfiles;
    if (children.length != 1) return false;
    return children.first.id == childId;
  }

  Future<void> _syncAchievementsFromProgress({
    bool queueNotification = true,
    bool notifyUi = true,
  }) async {
    final user = _currentUser;
    if (user == null) return;
    final activeChild = !isAdmin ? childProfile : null;
    final scopedChildId = activeChild?.id.trim() ?? '';
    final unlocked = (activeChild?.unlockedAchievementIds ?? user.unlockedAchievementIds)
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    final sessions = scopedChildId.isEmpty
        ? user.gameSessions
        : _sessionsForScope(childId: scopedChildId);
    final starsForRules = activeChild?.stars ?? user.stars;

    final sessionsByGame = <String, int>{};
    var perfectSessions = 0;
    var totalMinutes = 0;
    for (final session in sessions) {
      final key = session.gameKey.trim().toLowerCase();
      if (key.isNotEmpty) {
        sessionsByGame[key] = (sessionsByGame[key] ?? 0) + 1;
      }
      final rounds = session.rounds.clamp(0, 10000);
      final mistakes = session.mistakes.clamp(0, 10000);
      if (rounds > 0 && mistakes == 0) {
        perfectSessions += 1;
      }
      totalMinutes += (_effectiveSessionDurationSeconds(session) ~/ 60);
    }
    final distinctGames = sessionsByGame.keys.length;

    final newlyUnlocked = <String>[];
    for (final achievement in achievementCatalog) {
      if (unlocked.contains(achievement.id)) continue;
      var reached = false;
      switch (achievement.ruleType) {
        case AchievementRuleType.totalStars:
          reached = starsForRules >= achievement.target;
          break;
        case AchievementRuleType.totalSessions:
          reached = sessions.length >= achievement.target;
          break;
        case AchievementRuleType.distinctGames:
          reached = distinctGames >= achievement.target;
          break;
        case AchievementRuleType.perfectSessions:
          reached = perfectSessions >= achievement.target;
          break;
        case AchievementRuleType.totalMinutes:
          reached = totalMinutes >= achievement.target;
          break;
        case AchievementRuleType.gameSessions:
          final key = achievement.gameKey.trim().toLowerCase();
          reached = (sessionsByGame[key] ?? 0) >= achievement.target;
          break;
      }
      if (!reached) continue;
      unlocked.add(achievement.id);
      newlyUnlocked.add(achievement.id);
    }

    if (newlyUnlocked.isEmpty) return;

    final ordered = _orderedAchievementIds(unlocked);
    NebulaUser updated;
    if (activeChild != null) {
      final updatedChild = activeChild.copyWith(
        unlockedAchievementIds: ordered,
      );
      updated = _upsertChildProfile(user, updatedChild);
      updated = _syncLegacyProgressFromChildren(updated);
    } else {
      updated = user.copyWith(unlockedAchievementIds: ordered);
    }
    _currentUser = updated;

    if (queueNotification) {
      for (final id in newlyUnlocked) {
        if (_pendingAchievementUnlockIds.contains(id)) continue;
        _pendingAchievementUnlockIds.add(id);
      }
    }
    if (notifyUi) {
      notifyListeners();
    }

    final saved = await _authService.updateUser(updated);
    if (saved.ok && saved.data != null) {
      _currentUser = saved.data;
      if (notifyUi) {
        notifyListeners();
      }
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

  bool _sameLocalDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<String> _orderedAchievementIds(Iterable<String> ids) {
    final normalized = ids
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    return achievementCatalog
        .map((item) => item.id)
        .where((id) => normalized.contains(id))
        .toList();
  }

  NebulaUser _syncLegacyProgressFromChildren(NebulaUser user) {
    if (user.childProfiles.isEmpty) return user;
    final aggregateStars = user.childProfiles.fold<int>(
      0,
      (acc, item) => acc + item.stars.clamp(0, 1000000000).toInt(),
    );
    final aggregateAchievements = <String>{};
    for (final child in user.childProfiles) {
      aggregateAchievements.addAll(child.unlockedAchievementIds);
    }
    return user.copyWith(
      stars: aggregateStars,
      unlockedAchievementIds: _orderedAchievementIds(aggregateAchievements),
    );
  }

  NebulaUser _upsertChildProfile(NebulaUser user, ChildProfile updatedChild) {
    final existing = user.childProfiles.isNotEmpty
        ? List<ChildProfile>.from(user.childProfiles)
        : (user.childProfile == null
            ? <ChildProfile>[]
            : <ChildProfile>[user.childProfile!]);
    final index = existing.indexWhere((item) => item.id == updatedChild.id);
    if (index >= 0) {
      existing[index] = updatedChild;
    } else {
      existing.add(updatedChild);
    }
    return user.copyWith(
      childProfile: updatedChild,
      childProfiles: existing,
    );
  }

  String? _scopedCustomImageKey({
    required String baseKey,
    required String childId,
  }) {
    final normalizedBase = baseKey.trim().toLowerCase();
    if (normalizedBase.isEmpty) return null;
    final normalizedChild = childId.trim();
    if (normalizedChild.isEmpty) return null;
    return 'child::$normalizedChild::$normalizedBase';
  }

  static String _resolveActiveChildId({
    required NebulaUser? user,
    required String requestedChildId,
  }) {
    if (user == null) return '';
    final list = user.childProfiles.isNotEmpty
        ? user.childProfiles
        : (user.childProfile == null
            ? const <ChildProfile>[]
            : <ChildProfile>[user.childProfile!]);
    if (list.isEmpty) return '';
    final requested = requestedChildId.trim();
    if (requested.isNotEmpty && list.any((item) => item.id == requested)) {
      return requested;
    }
    final legacy = user.childProfile?.id.trim() ?? '';
    if (legacy.isNotEmpty && list.any((item) => item.id == legacy)) {
      return legacy;
    }
    return list.first.id;
  }

  bool _shouldAskPortalSelectionAfterAuth() {
    final user = _currentUser;
    if (user == null) return false;
    if ((user.role).trim().toLowerCase() == UserRole.admin) return false;
    final hasChildren =
        user.childProfiles.isNotEmpty || user.childProfile != null;
    return hasChildren;
  }

  bool _shouldAskPortalSelectionOnAppOpen() {
    final user = _currentUser;
    if (user == null) return false;
    if ((user.role).trim().toLowerCase() == UserRole.admin) return false;
    final hasChildren =
        user.childProfiles.isNotEmpty || user.childProfile != null;
    return hasChildren;
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
