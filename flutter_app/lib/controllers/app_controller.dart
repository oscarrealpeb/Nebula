import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

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
import '../services/image_ai_review_service.dart';
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
  static const int minChildProfileAge = 10;
  static const int maxChildProfileAge = 18;
  static const int maxCustomImageBytes = 5 * 1024 * 1024;
  static const int maxCustomImageKilobytes = maxCustomImageBytes ~/ 1024;
  static const int maxCustomImageMegabytes =
      maxCustomImageBytes ~/ (1024 * 1024);
  static const List<String> allowedCustomImageExtensions = <String>[
    'jpg',
    'jpeg',
    'png',
  ];
  static const int _dailyUsagePersistThresholdSeconds = 10;
  static const Set<String> _minigameKeys = <String>{
    'cartas_gemelas',
    'que_sigue',
    'donde_va',
    'arma_imagen',
  };

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
  String _localImageCacheDirPath = '';
  final Set<String> _imageCacheSyncInFlight = <String>{};
  StreamSubscription<bool>? _connectivitySub;
  Future<void> _starUpdateQueue = Future<void>.value();
  String? _pendingHomeLevelUpPlanetName;
  final List<String> _pendingAchievementUnlockIds = <String>[];
  DateTime? _childSessionStartedAt;
  int _childSessionBufferedSeconds = 0;
  bool _childLimitReached = false;
  bool _childLimitDialogShown = false;
  bool _childLimitExitPending = false;
  bool _childGameActive = false;

  static Future<AppController> bootstrap({
    bool firebaseEnabled = false,
    ConnectivityService? connectivityService,
  }) async {
    final store = await LocalStore.create();
    final authService = AuthService(
      store,
      firebaseAuth: firebaseEnabled ? FirebaseAuth.instance : null,
      firestore: firebaseEnabled ? FirebaseFirestore.instance : null,
      storage: firebaseEnabled ? FirebaseStorage.instance : null,
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
    await controller._ensureLocalImageCacheDirReady();
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
          unawaited(controller._warmLocalImageCachesBestEffort());
        }
        controller.notifyListeners();
      },
    );
    unawaited(controller._warmLocalImageCachesBestEffort());
    return controller;
  }

  NebulaUser? get currentUser => _currentUser;
  PortalRole get activePortalRole => _activePortalRole;
  AppAdminConfig get appAdminConfig => _appAdminConfig;
  GameContentConfig get gameContentConfig => _gameContentConfig;
  List<String> get puzzleImageSources {
    final fromAdmin = _gameContentConfig.puzzleItems
        .where((item) => item.enabled)
        .map((item) {
          final source = item.imageSource.trim();
          if (source.isEmpty) return '';
          return resolvedGameImageSourceFor(
            gameKey: 'puzzle',
            itemId: source,
            defaultSource: source,
          );
        })
        .where((item) => item.isNotEmpty)
        .toList();
    if (fromAdmin.isEmpty) {
      return defaultPuzzleImageSources
          .map(
            (source) => resolvedGameImageSourceFor(
              gameKey: 'puzzle',
              itemId: source,
              defaultSource: source,
            ),
          )
          .toList();
    }
    final merged = <String>[
      ...fromAdmin,
      ...defaultPuzzleImageSources
          .map(
            (source) => resolvedGameImageSourceFor(
              gameKey: 'puzzle',
              itemId: source,
              defaultSource: source,
            ),
          )
          .where((item) => !fromAdmin.contains(item)),
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
  bool get needsChildOnboarding =>
      !isAdmin &&
      childProfiles.isEmpty &&
      _activePortalRole == PortalRole.child;
  bool get needsPortalSelection =>
      !isAdmin &&
      _currentUser != null &&
      childProfiles.isNotEmpty &&
      _needsPortalSelection;
  bool get isChildGameActive => _childGameActive;
  bool get shouldShowChildTimeLimitDialog =>
      _childLimitReached &&
      !_childLimitDialogShown &&
      _activePortalRole == PortalRole.child;
  bool get shouldExitChildAfterTimeLimit =>
      _childLimitExitPending && _childLimitDialogShown;
  String get childTimeLimitMessage =>
      'Tu tiempo de juego ha terminado. P\u00eddale ayuda a un adulto para volver a jugar.';
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

  ParentalControl get parentalControl {
    final user = _currentUser;
    if (user == null) return const ParentalControl();
    if (isAdmin) return user.parentalControl;
    final activeChild = childProfile;
    if (activeChild != null) {
      final childControl = activeChild.parentalControl;
      final legacyControl = user.parentalControl;
      if (_isEmptyParentalControl(childControl) &&
          !_isEmptyParentalControl(legacyControl)) {
        return legacyControl;
      }
      return childControl;
    }
    return user.parentalControl;
  }

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
    final child = _activePortalRole == PortalRole.child ? childProfile : null;
    if (child != null) return child.accentHue;
    return (_currentUser?.accentHue ?? 190).toDouble();
  }

  double get currentAccentIntensity {
    final child = _activePortalRole == PortalRole.child ? childProfile : null;
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

  int starsRewardForGame({
    required String gameKey,
    required int difficultyStars,
    int mistakes = 0,
  }) {
    final normalizedKey = gameKey.trim().toLowerCase();
    final safeDifficulty = difficultyStars.clamp(1, 3).toInt();
    var reward = switch (safeDifficulty) {
      1 => 20,
      2 => 25,
      _ => 30,
    };

    final isMinigame = _minigameKeys.contains(normalizedKey);
    if (!isMinigame && mistakes >= 3 && safeDifficulty >= 2) {
      reward -= 5;
    }
    return reward;
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
      unawaited(_warmLocalImageCachesBestEffort());
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
    unawaited(_warmLocalImageCachesBestEffort());
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
    unawaited(_warmLocalImageCachesBestEffort());
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
          'El acceso directo de ni\u00f1o ya no est\u00e1 disponible. Entra con la cuenta del cuidador y luego elige el perfil del ni\u00f1o.',
    );
  }

  Future<ActionResult> loginWithGoogle() async {
    await refreshOnlineStatus();
    if (!_isOnline) {
      return const ActionResult(
        ok: false,
        message:
            'Sin internet. Para entrar con Google, revisa tu conexi\u00f3n e intenta de nuevo.',
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
      unawaited(_warmLocalImageCachesBestEffort());
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
      unawaited(_warmLocalImageCachesBestEffort());
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
      return const ActionResult(
          ok: false, message: 'No hay sesi\u00f3n activa.');
    }
    if (isAdmin) {
      return const ActionResult(
        ok: false,
        message: 'El admin no usa portal de ni\u00f1o.',
      );
    }
    if (_appAdminConfig.maintenanceMode) {
      final message = _appAdminConfig.maintenanceMessage.trim().isEmpty
          ? 'La app est\u00e1 en mantenimiento. Intenta m\u00e1s tarde.'
          : _appAdminConfig.maintenanceMessage;
      return ActionResult(ok: false, message: message);
    }
    final targetId = childId.trim();
    if (targetId.isEmpty) {
      return const ActionResult(
        ok: false,
        message: 'Selecciona un perfil de ni\u00f1o.',
      );
    }
    final exists = childProfiles.any((item) => item.id == targetId);
    if (!exists) {
      return const ActionResult(
        ok: false,
        message: 'Ese perfil de ni\u00f1o no existe.',
      );
    }
    final targetChild = childProfiles.firstWhere((item) => item.id == targetId);
    final targetControl = _parentalControlForChild(targetChild);
    if (targetControl.hasSchedule &&
        !_isWithinAllowedSchedule(targetControl, DateTime.now())) {
      final start = targetControl.allowedStartHour;
      final end = targetControl.allowedEndHour;
      return ActionResult(
        ok: false,
        message:
            'Fuera del horario permitido ($start:00 - $end:00). Pide ayuda a un adulto.',
      );
    }
    if (_isChildTimeLimitReachedForChild(targetId)) {
      return ActionResult(ok: false, message: childTimeLimitMessage);
    }
    _activeChildProfileId = targetId;
    _activePortalRole = PortalRole.child;
    _needsPortalSelection = false;
    _childLimitReached = false;
    _childLimitDialogShown = false;
    _childLimitExitPending = false;
    _childGameActive = false;
    _childSessionBufferedSeconds = 0;
    _childSessionStartedAt = null;

    final selectedChild = targetChild;
    final nextPrimary = user.copyWith(
      childProfile: selectedChild,
      childProfiles: childProfiles,
    );
    final saved = await _authService.updateUser(nextPrimary);
    if (saved.ok && saved.data != null) {
      _currentUser = saved.data;
    }
    _ensureActiveChildUsageDayIsToday();
    await _authService.persistPortalRole(PortalRole.child);
    notifyListeners();
    return const ActionResult(ok: true, message: 'Portal ni\u00f1o listo.');
  }

  Future<ActionResult> enterCaregiverPortal({
    required String password,
  }) async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(
          ok: false, message: 'No hay sesi\u00f3n activa.');
    }
    if (isAdmin) {
      _activePortalRole = PortalRole.admin;
      _needsPortalSelection = false;
      notifyListeners();
      return const ActionResult(ok: true, message: 'Portal admin listo.');
    }
    if (_appAdminConfig.maintenanceMode) {
      final message = _appAdminConfig.maintenanceMessage.trim().isEmpty
          ? 'La app est\u00e1 en mantenimiento. Intenta m\u00e1s tarde.'
          : _appAdminConfig.maintenanceMessage;
      return ActionResult(ok: false, message: message);
    }
    final typed = password.trim();
    if (typed.isEmpty) {
      return const ActionResult(
        ok: false,
        message: 'Escribe la contrase\u00f1a del cuidador.',
      );
    }
    final valid = await _authService.verifyCurrentUserPassword(typed);
    if (!valid.ok) {
      return ActionResult(ok: false, message: valid.message);
    }
    _endChildSessionTracking();
    _childGameActive = false;
    _activePortalRole = PortalRole.caregiver;
    _needsPortalSelection = false;
    await _authService.persistPortalRole(PortalRole.caregiver);
    notifyListeners();
    return const ActionResult(ok: true, message: 'Portal cuidador listo.');
  }

  Future<ActionResult> setCaregiverChildContext(String childId) async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(
          ok: false, message: 'No hay sesi\u00f3n activa.');
    }
    if (isAdmin) {
      return const ActionResult(
        ok: false,
        message: 'El admin no usa perfiles de ni\u00f1o.',
      );
    }
    final targetId = childId.trim();
    if (targetId.isEmpty) {
      return const ActionResult(
        ok: false,
        message: 'Selecciona un perfil de ni\u00f1o.',
      );
    }
    final list = childProfiles;
    final exists = list.any((item) => item.id == targetId);
    if (!exists) {
      return const ActionResult(
        ok: false,
        message: 'Ese perfil de ni\u00f1o no existe.',
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
    _endChildSessionTracking();
    _childGameActive = false;
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

  Future<ActionResult> _ensureAdminFirebaseSessionIfNeeded() async {
    if (!_firebaseEnabled || !isAdmin) {
      return const ActionResult(ok: true, message: 'No requiere recuperación.');
    }
    if (_authService.hasActiveFirebaseSession) {
      return const ActionResult(ok: true, message: 'Sesión Firebase activa.');
    }

    final recovered = await _authService.ensureAdminFirebaseSession(
      plainPassword: hiddenAdminPassword,
    );
    if (!recovered.ok || recovered.data == null) {
      return ActionResult(
        ok: false,
        message: recovered.message.isEmpty
            ? 'Tu sesión de Firebase no está activa. Cierra sesión y vuelve a entrar.'
            : recovered.message,
      );
    }

    _currentUser = recovered.data;
    _activePortalRole = PortalRole.admin;
    _activeChildProfileId = _resolveActiveChildId(
      user: _currentUser,
      requestedChildId: _activeChildProfileId,
    );
    _needsPortalSelection = false;
    notifyListeners();
    return const ActionResult(
      ok: true,
      message: 'Sesión admin Firebase recuperada.',
    );
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
        message: 'Solo el admin puede modificar esta configuraci\u00f3n.',
      );
    }
    final firebaseSession = await _ensureAdminFirebaseSessionIfNeeded();
    if (!firebaseSession.ok) {
      return firebaseSession;
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
      unawaited(_warmLocalImageCachesBestEffort());
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
      unawaited(_warmLocalImageCachesBestEffort());
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
    final firebaseSession = await _ensureAdminFirebaseSessionIfNeeded();
    if (!firebaseSession.ok) {
      return firebaseSession;
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

  /// Mantiene compatibilidad, pero el cambio en-app est\u00e1 deshabilitado.
  Future<ActionResult> changePasswordImproved({
    String currentPassword = '',
    required String newPassword,
    String parentalPin = '',
  }) async {
    return const ActionResult(
      ok: false,
      message:
          'El cambio de contrase\u00f1a en la app est\u00e1 deshabilitado. Usa el correo de restablecimiento.',
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
    _endChildSessionTracking();
    _childSessionBufferedSeconds = 0;
    _childLimitReached = false;
    _childLimitDialogShown = false;
    _childLimitExitPending = false;
    _childGameActive = false;
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
        message: 'Escribe un correo v\u00e1lido.',
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
        message:
            'Escribe un correo v\u00e1lido para reenviar verificaci\u00f3n.',
      );
    }
    if (password.trim().isEmpty) {
      return const ActionResult(
        ok: false,
        message: 'Escribe la contrase\u00f1a para reenviar verificaci\u00f3n.',
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
      message: 'Reenv\u00edo solicitado. Revisa tu correo.',
      remainingSeconds: 60,
    );
  }

  Future<ActionResult> requestProfilePasswordReset() async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(
          ok: false, message: 'No hay sesi\u00f3n activa.');
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
      message: 'El cambio de correo desde la app est\u00e1 deshabilitado.',
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
          'El cambio de contrase\u00f1a en la app est\u00e1 deshabilitado. Usa el correo de restablecimiento.',
    );
  }

  Future<ActionResult> requestDeleteAccount({
    String parentalPin = '',
    String password = '',
  }) async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(
          ok: false, message: 'No hay sesi\u00f3n activa.');
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
      return const ActionResult(
          ok: false, message: 'No hay sesi\u00f3n activa.');
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
      return const ActionResult(
          ok: false, message: 'No hay sesi\u00f3n activa.');
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
      return const ActionResult(
          ok: false, message: 'No hay sesi\u00f3n activa.');
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
      return const ActionResult(
          ok: false, message: 'No hay sesi\u00f3n activa.');
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
      return const ActionResult(
          ok: false, message: 'No hay sesi\u00f3n activa.');
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
      return const ActionResult(
          ok: false, message: 'No hay sesi\u00f3n activa.');
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
      return const ActionResult(
          ok: false, message: 'No hay sesi\u00f3n activa.');
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
      final currentProgressStars =
          (!isAdmin && childProfile != null) ? nextStars : next.stars;
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
    final applyToChild = _activePortalRole == PortalRole.child && !isAdmin;
    final targetChildId = applyToChild ? (childProfile?.id ?? '').trim() : '';
    var next = user.copyWith(accentHue: hue, accentIntensity: safeIntensity);
    final active = childProfile;
    if (applyToChild && active != null) {
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

  String _customGameImageBaseKey({
    required String gameKey,
    required String itemId,
  }) {
    final normalizedGame = gameKey.trim().toLowerCase();
    final normalizedItem = itemId.trim().toLowerCase();
    return 'game::$normalizedGame::$normalizedItem';
  }

  String customContentItemId({
    required String source,
    String rawId = '',
  }) {
    final explicit = rawId.trim().toLowerCase();
    if (explicit.isNotEmpty) return explicit;
    final normalizedSource = source.trim().toLowerCase();
    if (normalizedSource.isEmpty) return 'item';
    final collapsed = normalizedSource.replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
    return collapsed.replaceAll(RegExp(r'^_+|_+$'), '');
  }

  Future<void> _ensureLocalImageCacheDirReady() async {
    if (_localImageCacheDirPath.trim().isNotEmpty) return;
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${docsDir.path}/nebula_image_cache');
      if (!cacheDir.existsSync()) {
        await cacheDir.create(recursive: true);
      }
      _localImageCacheDirPath = cacheDir.path;
    } catch (_) {
      _localImageCacheDirPath = '';
    }
  }

  String _localCachePathForStoragePath(String storagePath) {
    final normalized = storagePath.trim();
    if (_localImageCacheDirPath.trim().isEmpty || normalized.isEmpty) {
      return '';
    }
    final extension = _fileExtension(normalized) ?? 'jpg';
    final encoded =
        base64Url.encode(utf8.encode(normalized)).replaceAll('=', '');
    return '$_localImageCacheDirPath/$encoded.$extension';
  }

  String? _localCachedFilePathForStoragePath(String? storagePath) {
    final normalized = storagePath?.trim() ?? '';
    if (normalized.isEmpty) return null;
    final localPath = _localCachePathForStoragePath(normalized);
    if (localPath.isEmpty) return null;
    final file = File(localPath);
    if (!file.existsSync()) return null;
    return localPath;
  }

  Future<void> _writeLocalImageCacheCopy({
    required String sourcePath,
    required String storagePath,
  }) async {
    final normalizedSource = sourcePath.trim();
    final normalizedStorage = storagePath.trim();
    if (normalizedSource.isEmpty || normalizedStorage.isEmpty) return;
    await _ensureLocalImageCacheDirReady();
    final targetPath = _localCachePathForStoragePath(normalizedStorage);
    if (targetPath.isEmpty) return;
    final sourceFile = File(normalizedSource);
    if (!sourceFile.existsSync()) return;
    final targetFile = File(targetPath);
    await targetFile.parent.create(recursive: true);
    await sourceFile.copy(targetPath);
  }

  Future<void> _deleteLocalImageCacheFileBestEffort(String storagePath) async {
    final targetPath = _localCachePathForStoragePath(storagePath);
    if (targetPath.isEmpty) return;
    try {
      final targetFile = File(targetPath);
      if (targetFile.existsSync()) {
        await targetFile.delete();
      }
    } catch (_) {}
  }

  Future<void> _cacheRemoteImageLocallyBestEffort({
    required String storagePath,
    required String sourceUrl,
  }) async {
    final normalizedStorage = storagePath.trim();
    final normalizedUrl = sourceUrl.trim();
    if (normalizedStorage.isEmpty || normalizedUrl.isEmpty || !_isOnline) {
      return;
    }
    if (_imageCacheSyncInFlight.contains(normalizedStorage)) return;
    _imageCacheSyncInFlight.add(normalizedStorage);
    try {
      await _ensureLocalImageCacheDirReady();
      final targetPath = _localCachePathForStoragePath(normalizedStorage);
      if (targetPath.isEmpty) return;
      final uri = Uri.tryParse(normalizedUrl);
      if (uri == null ||
          !(uri.scheme.toLowerCase() == 'http' ||
              uri.scheme.toLowerCase() == 'https')) {
        return;
      }

      final client = HttpClient();
      try {
        final request = await client.getUrl(uri);
        final response = await request.close();
        if (response.statusCode < 200 || response.statusCode >= 300) {
          return;
        }
        final bytes = await consolidateHttpClientResponseBytes(response);
        final targetFile = File(targetPath);
        await targetFile.parent.create(recursive: true);
        await targetFile.writeAsBytes(bytes, flush: true);
      } finally {
        client.close(force: true);
      }
    } catch (_) {
      // Cache local best-effort: si falla, seguimos usando la URL remota.
    } finally {
      _imageCacheSyncInFlight.remove(normalizedStorage);
    }
  }

  Future<void> _warmLocalImageCachesBestEffort() async {
    if (!_isOnline) return;
    final user = _currentUser;
    await _ensureLocalImageCacheDirReady();
    if (_localImageCacheDirPath.trim().isEmpty) return;

    if (user != null) {
      for (final entry in user.customImageStoragePaths.entries) {
        final storagePath = entry.value.trim();
        final sourceUrl = user.customImages[entry.key]?.trim() ?? '';
        if (storagePath.isEmpty || sourceUrl.isEmpty) continue;
        unawaited(
          _cacheRemoteImageLocallyBestEffort(
            storagePath: storagePath,
            sourceUrl: sourceUrl,
          ),
        );
      }
    }

    for (final entry
        in _gameContentConfig.globalEmotionImageStoragePaths.entries) {
      final storagePath = entry.value.trim();
      final sourceUrl =
          _gameContentConfig.globalEmotionImageOverrides[entry.key]?.trim() ??
              '';
      if (storagePath.isEmpty || sourceUrl.isEmpty) continue;
      unawaited(
        _cacheRemoteImageLocallyBestEffort(
          storagePath: storagePath,
          sourceUrl: sourceUrl,
        ),
      );
    }

    for (final entry
        in _gameContentConfig.globalSoundImageStoragePaths.entries) {
      final storagePath = entry.value.trim();
      final sourceUrl =
          _gameContentConfig.globalSoundImageOverrides[entry.key]?.trim() ?? '';
      if (storagePath.isEmpty || sourceUrl.isEmpty) continue;
      unawaited(
        _cacheRemoteImageLocallyBestEffort(
          storagePath: storagePath,
          sourceUrl: sourceUrl,
        ),
      );
    }

    for (final entry
        in _gameContentConfig.globalPuzzleImageStoragePaths.entries) {
      final storagePath = entry.value.trim();
      final sourceUrl =
          _gameContentConfig.globalPuzzleImageOverrides[entry.key]?.trim() ??
              '';
      if (storagePath.isEmpty || sourceUrl.isEmpty) continue;
      unawaited(
        _cacheRemoteImageLocallyBestEffort(
          storagePath: storagePath,
          sourceUrl: sourceUrl,
        ),
      );
    }

    for (final entry
        in _gameContentConfig.globalMemoryImageStoragePaths.entries) {
      final storagePath = entry.value.trim();
      final sourceUrl =
          _gameContentConfig.globalMemoryImageOverrides[entry.key]?.trim() ??
              '';
      if (storagePath.isEmpty || sourceUrl.isEmpty) continue;
      unawaited(
        _cacheRemoteImageLocallyBestEffort(
          storagePath: storagePath,
          sourceUrl: sourceUrl,
        ),
      );
    }

    for (final entry
        in _gameContentConfig.globalDondeVaImageStoragePaths.entries) {
      final storagePath = entry.value.trim();
      final sourceUrl =
          _gameContentConfig.globalDondeVaImageOverrides[entry.key]?.trim() ??
              '';
      if (storagePath.isEmpty || sourceUrl.isEmpty) continue;
      unawaited(
        _cacheRemoteImageLocallyBestEffort(
          storagePath: storagePath,
          sourceUrl: sourceUrl,
        ),
      );
    }
  }

  String? customGameImageSourceFor({
    required String gameKey,
    required String itemId,
    required String defaultSource,
    String childId = '',
  }) {
    final localCustom = _localCachedFilePathForStoragePath(
      _customGameImageStoragePathFor(
        gameKey: gameKey,
        itemId: itemId,
        childId: childId,
      ),
    );
    if (localCustom != null && localCustom.isNotEmpty) {
      return localCustom;
    }
    final custom = customImagePathFor(
      key: _customGameImageBaseKey(gameKey: gameKey, itemId: itemId),
      childId: childId,
    );
    if (custom == null || custom.trim().isEmpty) {
      return defaultSource;
    }
    return custom;
  }

  String? _globalGameImageOverrideFor({
    required String gameKey,
    required String itemId,
  }) {
    final normalizedKey =
        _customGameImageBaseKey(gameKey: gameKey, itemId: itemId);
    return switch (gameKey.trim().toLowerCase()) {
      'emociones' =>
        _gameContentConfig.globalEmotionImageOverrides[normalizedKey]?.trim(),
      'sonidos' =>
        _gameContentConfig.globalSoundImageOverrides[normalizedKey]?.trim(),
      'puzzle' =>
        _gameContentConfig.globalPuzzleImageOverrides[normalizedKey]?.trim(),
      'cartas_gemelas' =>
        _gameContentConfig.globalMemoryImageOverrides[normalizedKey]?.trim(),
      'donde_va' =>
        _gameContentConfig.globalDondeVaImageOverrides[normalizedKey]?.trim(),
      _ => null,
    };
  }

  String _globalGameImageStorageMapKey({
    required String gameKey,
    required String itemId,
  }) {
    return _customGameImageBaseKey(gameKey: gameKey, itemId: itemId);
  }

  String? _globalGameImageStoragePathFor({
    required String gameKey,
    required String itemId,
  }) {
    final key = _globalGameImageStorageMapKey(gameKey: gameKey, itemId: itemId);
    return switch (gameKey.trim().toLowerCase()) {
      'emociones' =>
        _gameContentConfig.globalEmotionImageStoragePaths[key]?.trim(),
      'sonidos' => _gameContentConfig.globalSoundImageStoragePaths[key]?.trim(),
      'puzzle' => _gameContentConfig.globalPuzzleImageStoragePaths[key]?.trim(),
      'cartas_gemelas' =>
        _gameContentConfig.globalMemoryImageStoragePaths[key]?.trim(),
      'donde_va' =>
        _gameContentConfig.globalDondeVaImageStoragePaths[key]?.trim(),
      _ => null,
    };
  }

  String resolvedGameImageSourceFor({
    required String gameKey,
    required String itemId,
    required String defaultSource,
    String childId = '',
  }) {
    final customStoragePath = _customGameImageStoragePathFor(
      gameKey: gameKey,
      itemId: itemId,
      childId: childId,
    );
    final localCustom = _localCachedFilePathForStoragePath(customStoragePath);
    if (localCustom != null && localCustom.isNotEmpty) {
      return localCustom;
    }
    final custom = customImagePathFor(
      key: _customGameImageBaseKey(gameKey: gameKey, itemId: itemId),
      childId: childId,
    );
    if (custom != null && custom.trim().isNotEmpty) {
      if (customStoragePath != null && customStoragePath.trim().isNotEmpty) {
        unawaited(
          _cacheRemoteImageLocallyBestEffort(
            storagePath: customStoragePath,
            sourceUrl: custom,
          ),
        );
      }
      return custom;
    }
    final globalStoragePath = _globalGameImageStoragePathFor(
      gameKey: gameKey,
      itemId: itemId,
    );
    final localGlobal = _localCachedFilePathForStoragePath(globalStoragePath);
    if (localGlobal != null && localGlobal.isNotEmpty) {
      return localGlobal;
    }
    final global =
        _globalGameImageOverrideFor(gameKey: gameKey, itemId: itemId);
    if (global != null && global.isNotEmpty) {
      if (globalStoragePath != null && globalStoragePath.trim().isNotEmpty) {
        unawaited(
          _cacheRemoteImageLocallyBestEffort(
            storagePath: globalStoragePath,
            sourceUrl: global,
          ),
        );
      }
      return global;
    }
    return defaultSource;
  }

  bool hasCustomGameImage({
    required String gameKey,
    required String itemId,
    String childId = '',
  }) {
    final custom = customImagePathFor(
      key: _customGameImageBaseKey(gameKey: gameKey, itemId: itemId),
      childId: childId,
    );
    return custom != null && custom.trim().isNotEmpty;
  }

  String? _customGameImageStoragePathFor({
    required String gameKey,
    required String itemId,
    String childId = '',
  }) {
    final user = _currentUser;
    if (user == null) return null;
    final directChildId = childId.trim();
    final activeId =
        directChildId.isNotEmpty ? directChildId : _activeChildProfileId;
    final key = _scopedCustomImageKey(
          baseKey: _customGameImageBaseKey(gameKey: gameKey, itemId: itemId),
          childId: activeId,
        ) ??
        _customGameImageBaseKey(gameKey: gameKey, itemId: itemId);
    final value = user.customImageStoragePaths[key]?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  Future<ActionResult> saveCustomGameImage({
    required String gameKey,
    required String itemId,
    required String filePath,
    String childId = '',
    List<String> expectedConcepts = const <String>[],
    String expectedEmotion = '',
    String expectedDescription = '',
  }) async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(
          ok: false, message: 'No hay sesi\u00f3n activa.');
    }
    if (!_firebaseEnabled) {
      return const ActionResult(
        ok: false,
        message: 'Esta funci\u00f3n requiere sincronizaci\u00f3n con Firebase.',
      );
    }
    if (!_authService.hasActiveFirebaseSession) {
      return const ActionResult(
        ok: false,
        message:
            'Tu sesi\u00f3n de Firebase no est\u00e1 activa. Cierra sesi\u00f3n y vuelve a entrar antes de sincronizar im\u00e1genes.',
      );
    }
    await refreshOnlineStatus();

    final normalizedPath = filePath.trim();
    if (normalizedPath.isEmpty) {
      return const ActionResult(
        ok: false,
        message: 'No se encontr\u00f3 la imagen seleccionada.',
      );
    }
    final file = File(normalizedPath);
    if (!file.existsSync()) {
      return const ActionResult(
        ok: false,
        message: 'La imagen seleccionada ya no est\u00e1 disponible.',
      );
    }

    final extension = _fileExtension(normalizedPath);
    if (extension == null ||
        !allowedCustomImageExtensions.contains(extension.toLowerCase())) {
      return const ActionResult(
        ok: false,
        message: 'Formato no permitido. Usa JPG o PNG.',
      );
    }

    final sizeBytes = file.lengthSync();
    if (sizeBytes > maxCustomImageBytes) {
      return const ActionResult(
        ok: false,
        message:
            'La imagen supera el tama\u00f1o m\u00e1ximo permitido de $maxCustomImageMegabytes MB.',
      );
    }

    final review = await ImageAiReviewService.reviewImage(
      filePath: normalizedPath,
      context: ImageAiReviewContext(
        gameKey: gameKey,
        itemId: itemId,
        expectedConcepts: expectedConcepts,
        expectedEmotion: expectedEmotion,
        expectedDescription: expectedDescription,
      ),
    );
    if (!review.ok) {
      return ActionResult(ok: false, message: review.message);
    }

    final targetChildId =
        childId.trim().isEmpty ? _activeChildProfileId : childId.trim();
    if (targetChildId.isEmpty) {
      return const ActionResult(
        ok: false,
        message: 'Selecciona primero un perfil de ni\u00f1o.',
      );
    }

    final baseKey = _customGameImageBaseKey(gameKey: gameKey, itemId: itemId);
    final targetKey = _scopedCustomImageKey(
          baseKey: baseKey,
          childId: targetChildId,
        ) ??
        baseKey;
    final previousStoragePath = _customGameImageStoragePathFor(
      gameKey: gameKey,
      itemId: itemId,
      childId: targetChildId,
    );

    final uploaded = await _authService.uploadCustomImageFile(
      user: user,
      childId: targetChildId,
      gameKey: gameKey,
      itemId: itemId,
      filePath: normalizedPath,
    );
    if (!uploaded.ok || uploaded.data == null) {
      return ActionResult(ok: false, message: uploaded.message);
    }

    final nextImages = Map<String, String>.from(user.customImages);
    nextImages[targetKey] = uploaded.data!.downloadUrl;
    final nextStorage = Map<String, String>.from(user.customImageStoragePaths);
    nextStorage[targetKey] = uploaded.data!.storagePath;

    final next = user.copyWith(
      customImages: nextImages,
      customImageStoragePaths: nextStorage,
    );
    final saved = await _authService.updateUserEnsuringCloud(next);
    if (!saved.ok || saved.data == null) {
      await _authService.deleteCustomImageFileBestEffort(
        uploaded.data!.storagePath,
      );
      return ActionResult(ok: false, message: saved.message);
    }

    _currentUser = saved.data;
    _activeChildProfileId = _resolveActiveChildId(
      user: _currentUser,
      requestedChildId: _activeChildProfileId,
    );
    await _writeLocalImageCacheCopy(
      sourcePath: normalizedPath,
      storagePath: uploaded.data!.storagePath,
    );
    notifyListeners();

    if (previousStoragePath != null &&
        previousStoragePath.isNotEmpty &&
        previousStoragePath != uploaded.data!.storagePath) {
      unawaited(
        _authService.deleteCustomImageFileBestEffort(previousStoragePath),
      );
      unawaited(_deleteLocalImageCacheFileBestEffort(previousStoragePath));
    }

    return const ActionResult(
      ok: true,
      message: 'Imagen personalizada guardada correctamente.',
    );
  }

  Future<ActionResult> saveGlobalGameImage({
    required String gameKey,
    required String itemId,
    required String filePath,
    List<String> expectedConcepts = const <String>[],
    String expectedEmotion = '',
    String expectedDescription = '',
  }) async {
    if (!isAdmin) {
      return const ActionResult(
        ok: false,
        message:
            'Solo el administrador puede cambiar im\u00e1genes predeterminadas.',
      );
    }
    if (!_firebaseEnabled) {
      return const ActionResult(
        ok: false,
        message: 'Esta funci\u00f3n requiere sincronizaci\u00f3n con Firebase.',
      );
    }
    final firebaseSession = await _ensureAdminFirebaseSessionIfNeeded();
    if (!firebaseSession.ok) {
      return firebaseSession;
    }
    await refreshOnlineStatus();
    final normalizedPath = filePath.trim();
    if (normalizedPath.isEmpty) {
      return const ActionResult(
        ok: false,
        message: 'No se encontr\u00f3 la imagen seleccionada.',
      );
    }
    final file = File(normalizedPath);
    if (!file.existsSync()) {
      return const ActionResult(
        ok: false,
        message: 'La imagen seleccionada ya no est\u00e1 disponible.',
      );
    }
    final extension = _fileExtension(normalizedPath);
    if (extension == null ||
        !allowedCustomImageExtensions.contains(extension.toLowerCase())) {
      return const ActionResult(
        ok: false,
        message: 'Formato no permitido. Usa JPG o PNG.',
      );
    }
    final sizeBytes = file.lengthSync();
    if (sizeBytes > maxCustomImageBytes) {
      return const ActionResult(
        ok: false,
        message:
            'La imagen supera el tama\u00f1o m\u00e1ximo permitido de $maxCustomImageMegabytes MB.',
      );
    }
    final review = await ImageAiReviewService.reviewImage(
      filePath: normalizedPath,
      context: ImageAiReviewContext(
        gameKey: gameKey,
        itemId: itemId,
        expectedConcepts: expectedConcepts,
        expectedEmotion: expectedEmotion,
        expectedDescription: expectedDescription,
      ),
    );
    if (!review.ok) {
      return ActionResult(ok: false, message: review.message);
    }
    final previousStoragePath = _globalGameImageStoragePathFor(
      gameKey: gameKey,
      itemId: itemId,
    );
    final uploaded = await _authService.uploadGlobalGameImageFile(
      gameKey: gameKey,
      itemId: itemId,
      filePath: normalizedPath,
    );
    if (!uploaded.ok || uploaded.data == null) {
      return ActionResult(ok: false, message: uploaded.message);
    }
    final key = _globalGameImageStorageMapKey(gameKey: gameKey, itemId: itemId);
    late final GameContentConfig nextConfig;
    switch (gameKey.trim().toLowerCase()) {
      case 'emociones':
        nextConfig = _gameContentConfig.copyWith(
          globalEmotionImageOverrides: Map<String, String>.from(
            _gameContentConfig.globalEmotionImageOverrides,
          )..[key] = uploaded.data!.downloadUrl,
          globalEmotionImageStoragePaths: Map<String, String>.from(
            _gameContentConfig.globalEmotionImageStoragePaths,
          )..[key] = uploaded.data!.storagePath,
        );
        break;
      case 'sonidos':
        nextConfig = _gameContentConfig.copyWith(
          globalSoundImageOverrides: Map<String, String>.from(
            _gameContentConfig.globalSoundImageOverrides,
          )..[key] = uploaded.data!.downloadUrl,
          globalSoundImageStoragePaths: Map<String, String>.from(
            _gameContentConfig.globalSoundImageStoragePaths,
          )..[key] = uploaded.data!.storagePath,
        );
        break;
      case 'puzzle':
        nextConfig = _gameContentConfig.copyWith(
          globalPuzzleImageOverrides: Map<String, String>.from(
            _gameContentConfig.globalPuzzleImageOverrides,
          )..[key] = uploaded.data!.downloadUrl,
          globalPuzzleImageStoragePaths: Map<String, String>.from(
            _gameContentConfig.globalPuzzleImageStoragePaths,
          )..[key] = uploaded.data!.storagePath,
        );
        break;
      case 'cartas_gemelas':
        nextConfig = _gameContentConfig.copyWith(
          globalMemoryImageOverrides: Map<String, String>.from(
            _gameContentConfig.globalMemoryImageOverrides,
          )..[key] = uploaded.data!.downloadUrl,
          globalMemoryImageStoragePaths: Map<String, String>.from(
            _gameContentConfig.globalMemoryImageStoragePaths,
          )..[key] = uploaded.data!.storagePath,
        );
        break;
      case 'donde_va':
        nextConfig = _gameContentConfig.copyWith(
          globalDondeVaImageOverrides: Map<String, String>.from(
            _gameContentConfig.globalDondeVaImageOverrides,
          )..[key] = uploaded.data!.downloadUrl,
          globalDondeVaImageStoragePaths: Map<String, String>.from(
            _gameContentConfig.globalDondeVaImageStoragePaths,
          )..[key] = uploaded.data!.storagePath,
        );
        break;
      default:
        await _authService.deleteCustomImageFileBestEffort(
          uploaded.data!.storagePath,
        );
        return const ActionResult(
          ok: false,
          message: 'Este juego a\u00fan no admite cambios globales de imagen.',
        );
    }
    final saved = await _authService.saveGameContentConfig(nextConfig);
    if (!saved.ok || saved.data == null) {
      await _authService.deleteCustomImageFileBestEffort(
        uploaded.data!.storagePath,
      );
      return ActionResult(ok: false, message: saved.message);
    }
    _gameContentConfig = saved.data!;
    await _writeLocalImageCacheCopy(
      sourcePath: normalizedPath,
      storagePath: uploaded.data!.storagePath,
    );
    notifyListeners();
    if (previousStoragePath != null &&
        previousStoragePath.isNotEmpty &&
        previousStoragePath != uploaded.data!.storagePath) {
      unawaited(
        _authService.deleteCustomImageFileBestEffort(previousStoragePath),
      );
      unawaited(_deleteLocalImageCacheFileBestEffort(previousStoragePath));
    }
    return const ActionResult(
      ok: true,
      message: 'Imagen predeterminada actualizada correctamente.',
    );
  }

  Future<ActionResult> restoreCustomGameImage({
    required String gameKey,
    required String itemId,
    String childId = '',
  }) async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(
          ok: false, message: 'No hay sesi\u00f3n activa.');
    }
    if (_firebaseEnabled && !_authService.hasActiveFirebaseSession) {
      return const ActionResult(
        ok: false,
        message:
            'Tu sesi\u00f3n de Firebase no est\u00e1 activa. Cierra sesi\u00f3n y vuelve a entrar antes de restaurar im\u00e1genes.',
      );
    }

    final targetChildId =
        childId.trim().isEmpty ? _activeChildProfileId : childId.trim();
    final baseKey = _customGameImageBaseKey(gameKey: gameKey, itemId: itemId);
    final targetKey = _scopedCustomImageKey(
          baseKey: baseKey,
          childId: targetChildId,
        ) ??
        baseKey;

    final nextImages = Map<String, String>.from(user.customImages);
    final nextStorage = Map<String, String>.from(user.customImageStoragePaths);
    final removedImage = nextImages.remove(targetKey);
    final removedStorage = nextStorage.remove(targetKey);
    if ((removedImage == null || removedImage.trim().isEmpty) &&
        (removedStorage == null || removedStorage.trim().isEmpty)) {
      return const ActionResult(
        ok: false,
        message: 'Ese elemento ya usa la imagen original.',
      );
    }

    final next = user.copyWith(
      customImages: nextImages,
      customImageStoragePaths: nextStorage,
    );
    final saved = await _authService.updateUserEnsuringCloud(next);
    if (!saved.ok || saved.data == null) {
      return ActionResult(ok: false, message: saved.message);
    }

    _currentUser = saved.data;
    _activeChildProfileId = _resolveActiveChildId(
      user: _currentUser,
      requestedChildId: _activeChildProfileId,
    );
    notifyListeners();

    if (removedStorage != null && removedStorage.trim().isNotEmpty) {
      unawaited(_authService.deleteCustomImageFileBestEffort(removedStorage));
      unawaited(_deleteLocalImageCacheFileBestEffort(removedStorage));
    }

    return const ActionResult(
      ok: true,
      message: 'Se restaur\u00f3 la imagen original.',
    );
  }

  Future<ActionResult> restoreGlobalGameImage({
    required String gameKey,
    required String itemId,
  }) async {
    if (!isAdmin) {
      return const ActionResult(
        ok: false,
        message:
            'Solo el administrador puede restaurar im\u00e1genes predeterminadas.',
      );
    }
    final firebaseSession = await _ensureAdminFirebaseSessionIfNeeded();
    if (!firebaseSession.ok) {
      return firebaseSession;
    }
    final key = _globalGameImageStorageMapKey(gameKey: gameKey, itemId: itemId);
    final previousStoragePath = _globalGameImageStoragePathFor(
      gameKey: gameKey,
      itemId: itemId,
    );
    late final GameContentConfig nextConfig;
    switch (gameKey.trim().toLowerCase()) {
      case 'emociones':
        final hasOverride = _gameContentConfig.globalEmotionImageOverrides
                .containsKey(key) ||
            _gameContentConfig.globalEmotionImageStoragePaths.containsKey(key);
        if (!hasOverride && previousStoragePath == null) {
          return const ActionResult(
            ok: false,
            message: 'Ese elemento ya usa la imagen predeterminada original.',
          );
        }
        final nextOverrides = Map<String, String>.from(
          _gameContentConfig.globalEmotionImageOverrides,
        )..remove(key);
        final nextStorage = Map<String, String>.from(
          _gameContentConfig.globalEmotionImageStoragePaths,
        )..remove(key);
        nextConfig = _gameContentConfig.copyWith(
          globalEmotionImageOverrides: nextOverrides,
          globalEmotionImageStoragePaths: nextStorage,
        );
        break;
      case 'sonidos':
        final hasOverride = _gameContentConfig.globalSoundImageOverrides
                .containsKey(key) ||
            _gameContentConfig.globalSoundImageStoragePaths.containsKey(key);
        if (!hasOverride && previousStoragePath == null) {
          return const ActionResult(
            ok: false,
            message: 'Ese elemento ya usa la imagen predeterminada original.',
          );
        }
        final nextOverrides = Map<String, String>.from(
          _gameContentConfig.globalSoundImageOverrides,
        )..remove(key);
        final nextStorage = Map<String, String>.from(
          _gameContentConfig.globalSoundImageStoragePaths,
        )..remove(key);
        nextConfig = _gameContentConfig.copyWith(
          globalSoundImageOverrides: nextOverrides,
          globalSoundImageStoragePaths: nextStorage,
        );
        break;
      case 'puzzle':
        final hasOverride = _gameContentConfig.globalPuzzleImageOverrides
                .containsKey(key) ||
            _gameContentConfig.globalPuzzleImageStoragePaths.containsKey(key);
        if (!hasOverride && previousStoragePath == null) {
          return const ActionResult(
            ok: false,
            message: 'Ese elemento ya usa la imagen predeterminada original.',
          );
        }
        final nextOverrides = Map<String, String>.from(
          _gameContentConfig.globalPuzzleImageOverrides,
        )..remove(key);
        final nextStorage = Map<String, String>.from(
          _gameContentConfig.globalPuzzleImageStoragePaths,
        )..remove(key);
        nextConfig = _gameContentConfig.copyWith(
          globalPuzzleImageOverrides: nextOverrides,
          globalPuzzleImageStoragePaths: nextStorage,
        );
        break;
      case 'cartas_gemelas':
        final hasOverride = _gameContentConfig.globalMemoryImageOverrides
                .containsKey(key) ||
            _gameContentConfig.globalMemoryImageStoragePaths.containsKey(key);
        if (!hasOverride && previousStoragePath == null) {
          return const ActionResult(
            ok: false,
            message: 'Ese elemento ya usa la imagen predeterminada original.',
          );
        }
        final nextOverrides = Map<String, String>.from(
          _gameContentConfig.globalMemoryImageOverrides,
        )..remove(key);
        final nextStorage = Map<String, String>.from(
          _gameContentConfig.globalMemoryImageStoragePaths,
        )..remove(key);
        nextConfig = _gameContentConfig.copyWith(
          globalMemoryImageOverrides: nextOverrides,
          globalMemoryImageStoragePaths: nextStorage,
        );
        break;
      case 'donde_va':
        final hasOverride = _gameContentConfig.globalDondeVaImageOverrides
                .containsKey(key) ||
            _gameContentConfig.globalDondeVaImageStoragePaths.containsKey(key);
        if (!hasOverride && previousStoragePath == null) {
          return const ActionResult(
            ok: false,
            message: 'Ese elemento ya usa la imagen predeterminada original.',
          );
        }
        final nextOverrides = Map<String, String>.from(
          _gameContentConfig.globalDondeVaImageOverrides,
        )..remove(key);
        final nextStorage = Map<String, String>.from(
          _gameContentConfig.globalDondeVaImageStoragePaths,
        )..remove(key);
        nextConfig = _gameContentConfig.copyWith(
          globalDondeVaImageOverrides: nextOverrides,
          globalDondeVaImageStoragePaths: nextStorage,
        );
        break;
      default:
        return const ActionResult(
          ok: false,
          message: 'Este juego a\u00fan no admite cambios globales de imagen.',
        );
    }
    final saved = await _authService.saveGameContentConfig(nextConfig);
    if (!saved.ok || saved.data == null) {
      return ActionResult(ok: false, message: saved.message);
    }
    _gameContentConfig = saved.data!;
    notifyListeners();
    if (previousStoragePath != null && previousStoragePath.isNotEmpty) {
      unawaited(
        _authService.deleteCustomImageFileBestEffort(previousStoragePath),
      );
      unawaited(_deleteLocalImageCacheFileBestEffort(previousStoragePath));
    }
    return const ActionResult(
      ok: true,
      message: 'Imagen predeterminada restaurada.',
    );
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
      return const ActionResult(
          ok: false, message: 'No hay sesi\u00f3n activa.');
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

    final effectiveBirthDateMillis = birthDateMillis > 0
        ? birthDateMillis
        : (editingExisting
            ? existingProfiles
                .firstWhere((item) => item.id == childId.trim())
                .birthDateMillis
            : 0);
    final resolvedAge = effectiveBirthDateMillis > 0
        ? _computeChildAgeFromBirthDateMillis(effectiveBirthDateMillis)
        : age;
    if (resolvedAge < minChildProfileAge || resolvedAge > maxChildProfileAge) {
      return const ActionResult(
        ok: false,
        message:
            'La edad permitida para perfiles de ni\u00f1o es de 10 a 18 a\u00f1os.',
      );
    }
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
      age: resolvedAge,
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

  Future<ActionResult> deleteChildProfile(String childId) async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(
          ok: false, message: 'No hay sesi\u00f3n activa.');
    }

    final targetChildId = childId.trim();
    if (targetChildId.isEmpty) {
      return const ActionResult(
        ok: false,
        message: 'No se pudo identificar el perfil a eliminar.',
      );
    }

    final existingProfiles = List<ChildProfile>.from(childProfiles);
    final index =
        existingProfiles.indexWhere((item) => item.id.trim() == targetChildId);
    if (index < 0) {
      return const ActionResult(
        ok: false,
        message: 'Ese perfil ya no existe o no est\u00e1 disponible.',
      );
    }

    final removingOnlyChild = existingProfiles.length == 1;
    existingProfiles.removeAt(index);

    final nextSessions = user.gameSessions.where((session) {
      final sessionChildId = session.childId.trim();
      if (sessionChildId == targetChildId) return false;
      if (removingOnlyChild && sessionChildId.isEmpty) return false;
      return true;
    }).toList();

    final scopedPrefix = 'child::${targetChildId.toLowerCase()}::';
    final nextCustomImages = Map<String, String>.from(user.customImages)
      ..removeWhere(
        (key, _) => key.trim().toLowerCase().startsWith(scopedPrefix),
      );
    final removedStoragePaths = <String>[];
    final nextCustomImageStoragePaths = Map<String, String>.from(
      user.customImageStoragePaths,
    )..removeWhere((key, value) {
        final matches = key.trim().toLowerCase().startsWith(scopedPrefix);
        if (matches && value.trim().isNotEmpty) {
          removedStoragePaths.add(value.trim());
        }
        return matches;
      });

    final previousPrimaryId = user.childProfile?.id.trim() ?? '';
    final shouldReplacePrimary =
        previousPrimaryId.isEmpty || previousPrimaryId == targetChildId;
    ChildProfile? nextPrimary;
    if (existingProfiles.isNotEmpty) {
      if (!shouldReplacePrimary) {
        for (final item in existingProfiles) {
          if (item.id == previousPrimaryId) {
            nextPrimary = item;
            break;
          }
        }
      }
      nextPrimary ??= existingProfiles.first;
    }

    var next = user.copyWith(
      childProfile: nextPrimary,
      childProfiles: existingProfiles,
      gameSessions: nextSessions,
      customImages: nextCustomImages,
      customImageStoragePaths: nextCustomImageStoragePaths,
    );

    if (existingProfiles.isEmpty) {
      next = next.copyWith(stars: 0, unlockedAchievementIds: const <String>[]);
    } else {
      next = _syncLegacyProgressFromChildren(next);
    }

    final saved = await _authService.updateUser(next);
    if (saved.ok && saved.data != null) {
      _currentUser = saved.data;
      _activeChildProfileId = _resolveActiveChildId(
        user: _currentUser,
        requestedChildId: nextPrimary?.id ?? '',
      );
      _needsPortalSelection = _activePortalRole == PortalRole.caregiver
          ? false
          : _shouldAskPortalSelectionAfterAuth();
      notifyListeners();
      for (final path in removedStoragePaths) {
        unawaited(_authService.deleteCustomImageFileBestEffort(path));
        unawaited(_deleteLocalImageCacheFileBestEffort(path));
      }
      return const ActionResult(
        ok: true,
        message: 'Perfil del ni\u00f1o eliminado correctamente.',
      );
    }

    return ActionResult(ok: false, message: saved.message);
  }

  int _computeChildAgeFromBirthDateMillis(int birthDateMillis) {
    if (birthDateMillis <= 0) return 0;
    final birth = DateTime.fromMillisecondsSinceEpoch(birthDateMillis);
    final now = DateTime.now();
    var age = now.year - birth.year;
    final beforeBirthday = now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day);
    if (beforeBirthday) age -= 1;
    return age;
  }

  Future<ActionResult> updateParentalControl(
      ParentalControl nextControl) async {
    final user = _currentUser;
    if (user == null) {
      return const ActionResult(
          ok: false, message: 'No hay sesi\u00f3n activa.');
    }
    final hasStart = nextControl.allowedStartHour >= 0;
    final hasEnd = nextControl.allowedEndHour >= 0;
    if (hasStart != hasEnd) {
      return const ActionResult(
        ok: false,
        message: 'Completa ambos horarios o deja ambos en "Sin horario".',
      );
    }
    if (hasStart &&
        hasEnd &&
        nextControl.allowedStartHour >= nextControl.allowedEndHour) {
      return const ActionResult(
        ok: false,
        message: 'El horario "Desde" debe ser anterior al horario "Hasta".',
      );
    }
    final normalized = nextControl.copyWith(
      dailyLimitMinutes: nextControl.dailyLimitMinutes.clamp(0, 24 * 60),
      allowedStartHour: nextControl.allowedStartHour.clamp(-1, 23),
      allowedEndHour: nextControl.allowedEndHour.clamp(-1, 23),
      blockedGameKeys: nextControl.blockedGameKeys
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(),
    );
    final activeChild = !isAdmin ? childProfile : null;
    final todayKey = _todayKey();
    final next = activeChild == null
        ? user.copyWith(parentalControl: normalized)
        : _upsertChildProfile(
            user,
            activeChild.copyWith(
              parentalControl: normalized,
              dailyLimitUsageSeconds: 0,
              dailyLimitUsageDayKey: todayKey,
            ),
          );
    final saved = await _authService.updateUser(next);
    if (saved.ok && saved.data != null) {
      _currentUser = saved.data;
      _childLimitReached = false;
      _childLimitDialogShown = false;
      _childLimitExitPending = false;
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

    final birthDate =
        DateTime(now.year - minChildProfileAge, now.month, now.day);
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
      age: minChildProfileAge,
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
      return const ActionResult(
          ok: false, message: 'No hay sesi\u00f3n activa.');
    }
    if (isAdmin) {
      return const ActionResult(
        ok: false,
        message:
            'El perfil demo solo est\u00e1 disponible para cuentas de cuidador.',
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
      return const ActionResult(
          ok: false, message: 'No hay sesi\u00f3n activa.');
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
      return const ActionResult(
          ok: false, message: 'No hay sesi\u00f3n activa.');
    }
    if (!isAdmin && _appAdminConfig.maintenanceMode) {
      final message = _appAdminConfig.maintenanceMessage.trim().isEmpty
          ? 'La app est\u00e1 en mantenimiento. Intenta m\u00e1s tarde.'
          : _appAdminConfig.maintenanceMessage;
      return ActionResult(ok: false, message: message);
    }

    ChildProfile? activeChild;
    if (_activePortalRole == PortalRole.child) {
      final activeId = _activeChildProfileId.trim();
      if (activeId.isNotEmpty) {
        for (final item in childProfiles) {
          if (item.id == activeId) {
            activeChild = item;
            break;
          }
        }
      }
      activeChild ??= childProfile;
    }
    final control = activeChild == null
        ? parentalControl
        : _parentalControlForChild(activeChild);
    if (_activePortalRole == PortalRole.child) {
      _ensureActiveChildUsageDayIsToday();
    }
    final normalizedKey = gameKey.trim().toLowerCase();
    final globallyBlocked = _appAdminConfig.blockedGameKeys.any(
      (item) => item.trim().toLowerCase() == normalizedKey,
    );
    if (!isAdmin && globallyBlocked) {
      return const ActionResult(
        ok: false,
        message: 'Este juego est\u00e1 deshabilitado por administraci\u00f3n.',
      );
    }
    final blocked = control.blockedGameKeys.any(
      (item) => item.trim().toLowerCase() == normalizedKey,
    );
    if (blocked) {
      return const ActionResult(
        ok: false,
        message: 'Este juego est\u00e1 bloqueado por control parental.',
      );
    }

    if (control.hasSchedule) {
      final now = DateTime.now();
      if (!_isWithinAllowedSchedule(control, now)) {
        final start = control.allowedStartHour;
        final end = control.allowedEndHour;
        return ActionResult(
          ok: false,
          message:
              'Fuera del horario permitido ($start:00 - $end:00). Pide ayuda a un adulto.',
        );
      }
    }

    if (control.dailyLimitMinutes > 0) {
      final used = _estimatedUsedMinutesToday();
      if (used >= control.dailyLimitMinutes) {
        return ActionResult(
          ok: false,
          message:
              'L\u00edmite diario alcanzado (${control.dailyLimitMinutes} min). Vuelve ma\u00f1ana.',
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
    final unlocked =
        (activeChild?.unlockedAchievementIds ?? user.unlockedAchievementIds)
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

  int _todayKey([DateTime? when]) {
    final now = when ?? DateTime.now();
    return (now.year * 10000) + (now.month * 100) + now.day;
  }

  ParentalControl _parentalControlForChild(ChildProfile child) {
    final user = _currentUser;
    if (user == null) return const ParentalControl();
    final childControl = child.parentalControl;
    final legacyControl = user.parentalControl;
    if (_isEmptyParentalControl(childControl) &&
        !_isEmptyParentalControl(legacyControl)) {
      return legacyControl;
    }
    return childControl;
  }

  bool _isWithinAllowedSchedule(ParentalControl control, DateTime now) {
    if (!control.hasSchedule) return true;
    final start = control.allowedStartHour.clamp(0, 23);
    final end = control.allowedEndHour.clamp(0, 23);
    final currentMinutes = (now.hour * 60) + now.minute;
    final startMinutes = start * 60;
    final endMinutes = end * 60;
    if (start < end) {
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }
    return currentMinutes >= startMinutes || currentMinutes < endMinutes;
  }

  int _usageSecondsTodayForChild(ChildProfile child, int todayKey) {
    if (child.dailyLimitUsageDayKey != todayKey) return 0;
    return child.dailyLimitUsageSeconds.clamp(0, 24 * 3600);
  }

  void _ensureActiveChildUsageDayIsToday({bool notify = false}) {
    final user = _currentUser;
    final child = childProfile;
    if (user == null || child == null) return;
    final todayKey = _todayKey();
    if (child.dailyLimitUsageDayKey == todayKey) return;
    final updatedChild = child.copyWith(
      dailyLimitUsageSeconds: 0,
      dailyLimitUsageDayKey: todayKey,
    );
    final next = _upsertChildProfile(user, updatedChild);
    _currentUser = next;
    _childSessionBufferedSeconds = 0;
    _childSessionStartedAt = _childGameActive ? DateTime.now() : null;
    _childLimitReached = false;
    _childLimitDialogShown = false;
    _childLimitExitPending = false;
    if (notify) {
      notifyListeners();
    }
    unawaited(_authService.updateUser(next));
  }

  void _updateActiveChildUsage({
    required ChildProfile child,
    required int nextSeconds,
    required int dayKey,
    bool notify = false,
  }) {
    final user = _currentUser;
    if (user == null) return;
    final updatedChild = child.copyWith(
      dailyLimitUsageSeconds: nextSeconds.clamp(0, 24 * 3600),
      dailyLimitUsageDayKey: dayKey,
    );
    final next = _upsertChildProfile(user, updatedChild);
    _currentUser = next;
    if (notify) {
      notifyListeners();
    }
    unawaited(_authService.updateUser(next));
  }

  void _flushBufferedChildUsage({bool notify = false}) {
    if (_childSessionBufferedSeconds <= 0) return;
    final child = childProfile;
    if (child == null) {
      _childSessionBufferedSeconds = 0;
      return;
    }
    final todayKey = _todayKey();
    final baseSeconds = _usageSecondsTodayForChild(child, todayKey);
    final nextSeconds = baseSeconds + _childSessionBufferedSeconds;
    _childSessionBufferedSeconds = 0;
    _updateActiveChildUsage(
      child: child,
      nextSeconds: nextSeconds,
      dayKey: todayKey,
      notify: notify,
    );
  }

  void _bufferChildSessionUsage({bool force = false}) {
    if (_childSessionStartedAt == null) return;
    final now = DateTime.now();
    final elapsed = now.difference(_childSessionStartedAt!).inSeconds;
    if (elapsed <= 0) return;
    _childSessionBufferedSeconds += elapsed;
    _childSessionStartedAt = now;
    if (force ||
        _childSessionBufferedSeconds >= _dailyUsagePersistThresholdSeconds) {
      _flushBufferedChildUsage(notify: false);
    }
  }

  void setChildGameActive(bool value) {
    if (_childGameActive == value) return;
    _childGameActive = value;
    if (value) {
      _startChildSessionTracking();
    } else {
      _endChildSessionTracking();
      _checkChildLimitAfterSessionEnd();
    }
    notifyListeners();
  }

  void acknowledgeChildTimeLimitDialog() {
    if (_childLimitDialogShown) return;
    _childLimitDialogShown = true;
    notifyListeners();
  }

  void evaluateChildTimeLimit() {
    if (_activePortalRole != PortalRole.child) return;
    _ensureActiveChildUsageDayIsToday();
    if (!_childGameActive) return;
    final limit = parentalControl.dailyLimitMinutes;
    if (limit <= 0) return;
    _bufferChildSessionUsage();
    final used = _estimatedUsedMinutesToday();
    if (used >= limit && !_childLimitReached) {
      _childLimitReached = true;
      _childLimitExitPending = true;
      _bufferChildSessionUsage(force: true);
      notifyListeners();
    }
  }

  void _checkChildLimitAfterSessionEnd() {
    if (_activePortalRole != PortalRole.child) return;
    final limit = parentalControl.dailyLimitMinutes;
    if (limit <= 0) return;
    _ensureActiveChildUsageDayIsToday();
    final used = _estimatedUsedMinutesToday();
    if (used >= limit && !_childLimitReached) {
      _childLimitReached = true;
      _childLimitExitPending = true;
    }
  }

  void exitChildPortalDueToLimit() {
    _endChildSessionTracking();
    _childLimitExitPending = false;
    _childLimitDialogShown = true;
    markPortalSelectionPending();
  }

  bool _isChildTimeLimitReachedForChild(String childId) {
    final user = _currentUser;
    if (user == null) return false;
    ChildProfile? target;
    for (final item in childProfiles) {
      if (item.id == childId) {
        target = item;
        break;
      }
    }
    if (target == null) return false;
    final control = _parentalControlForChild(target);
    final limit = control.dailyLimitMinutes;
    if (limit <= 0) return false;
    final todayKey = _todayKey();
    final usedSeconds = _usageSecondsTodayForChild(target, todayKey);
    return (usedSeconds ~/ 60) >= limit;
  }

  int _estimatedUsedMinutesToday() {
    final child = childProfile;
    if (child == null) return 0;
    final todayKey = _todayKey();
    final baseSeconds = _usageSecondsTodayForChild(child, todayKey);
    final elapsed = _childSessionStartedAt == null
        ? 0
        : DateTime.now().difference(_childSessionStartedAt!).inSeconds;
    final totalSeconds = baseSeconds + _childSessionBufferedSeconds + elapsed;
    return totalSeconds ~/ 60;
  }

  void _startChildSessionTracking() {
    _ensureActiveChildUsageDayIsToday();
    _childSessionBufferedSeconds = 0;
    _childSessionStartedAt = DateTime.now();
  }

  void _endChildSessionTracking() {
    if (_childSessionStartedAt == null) return;
    _bufferChildSessionUsage(force: true);
    _childSessionStartedAt = null;
  }

  bool _isEmptyParentalControl(ParentalControl control) {
    return control.dailyLimitMinutes <= 0 &&
        control.allowedStartHour < 0 &&
        control.allowedEndHour < 0 &&
        control.blockedGameKeys.isEmpty;
  }

  bool _sameLocalDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<String> _orderedAchievementIds(Iterable<String> ids) {
    final normalized =
        ids.map((item) => item.trim()).where((item) => item.isNotEmpty).toSet();
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

  String? _fileExtension(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex >= path.length - 1) return null;
    final ext = path.substring(dotIndex + 1).trim().toLowerCase();
    if (ext.isEmpty) return null;
    return ext;
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
