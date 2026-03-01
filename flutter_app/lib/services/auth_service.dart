import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';

import '../models/admin_dashboard_models.dart';
import '../models/app_admin_config.dart';
import '../models/game_content_config.dart';
import '../models/nebula_user.dart';
import '../models/portal_role.dart';
import 'local_store.dart';

class ServiceResult<T> {
  const ServiceResult({
    required this.ok,
    required this.message,
    this.data,
  });

  final bool ok;
  final String message;
  final T? data;
}

class _DashboardSessionSnapshot {
  const _DashboardSessionSnapshot({
    required this.gameKey,
    required this.startedAtMillis,
    required this.durationSeconds,
    required this.correctAnswers,
    required this.totalAttempts,
  });

  final String gameKey;
  final int startedAtMillis;
  final int durationSeconds;
  final int correctAnswers;
  final int totalAttempts;
}

class _DashboardUserSnapshot {
  const _DashboardUserSnapshot({
    required this.role,
    required this.hasChildProfile,
    required this.childProfileActive,
    required this.sessions,
  });

  final String role;
  final bool hasChildProfile;
  final bool childProfileActive;
  final List<_DashboardSessionSnapshot> sessions;
}

class AuthService {
  AuthService(
    this._store, {
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore,
        _googleSignIn = googleSignIn ?? GoogleSignIn.standard();

  final LocalStore _store;
  final FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;
  final GoogleSignIn _googleSignIn;
  final _uuid = const Uuid();

  NebulaUser? _currentUser;
  PortalRole _activePortalRole = PortalRole.caregiver;
  NebulaUser? _pendingGoogleUserForLink;
  NebulaUser? _pendingLocalUserForLink;
  String? _pendingGoogleAccessTokenForLink;
  String? _pendingGoogleIdTokenForLink;
  String? _pendingGoogleAccessTokenForConfirm;
  String? _pendingGoogleIdTokenForConfirm;
  String? _pendingGoogleEmailForConfirm;
  String? _pendingGoogleNameForConfirm;

  bool get _useFirebase => _firebaseAuth != null && _firestore != null;
  PortalRole get activePortalRole => _activePortalRole;

  bool get isCurrentUserGoogleProvider {
    if (!_useFirebase) return false;
    final current = _firebaseAuth!.currentUser;
    if (current == null) return false;
    return current.providerData.any(
      (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID,
    );
  }

  bool get isCurrentUserPasswordProvider {
    if (!_useFirebase) return false;
    final current = _firebaseAuth!.currentUser;
    if (current == null) return false;
    return current.providerData.any(
      (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
    );
  }

  Future<NebulaUser?> restoreSession() async {
    final sessionUserId = _store.readSessionUserId();
    if (sessionUserId == null) {
      _currentUser = null;
      _activePortalRole = PortalRole.caregiver;
      return null;
    }

    final users = await _store.readUsers();
    NebulaUser? sessionUser;
    for (final user in users) {
      if (user.id == sessionUserId) {
        sessionUser = user;
        break;
      }
    }
    if (sessionUser == null) {
      _currentUser = null;
      _activePortalRole = PortalRole.caregiver;
      await _store.clearSession();
      return null;
    }

    if (_useFirebase) {
      final firebaseUser = _firebaseAuth?.currentUser;
      if (firebaseUser != null) {
        final verificationGate = await _enforceVerifiedEmailForPasswordUser(
          firebaseUser,
          fallbackEmail: sessionUser.email,
        );
        if (!verificationGate.ok) {
          _currentUser = null;
          _activePortalRole = PortalRole.caregiver;
          return null;
        }
      }
    }

    final storedRole = PortalRoleLabel.fromStorageValue(
      _store.readSessionPortalRole(),
    );
    _activePortalRole = _resolvePortalRoleForUser(
      user: sessionUser,
      requestedRole: storedRole,
    );
    _currentUser = sessionUser;
    return sessionUser;
  }

  Future<ServiceResult<AppAdminConfig>> fetchAppAdminConfig() async {
    final local = _store.readAdminConfig();
    final localConfig =
        local == null ? const AppAdminConfig() : AppAdminConfig.fromJson(local);

    if (!_useFirebase) {
      return ServiceResult(
        ok: true,
        message: 'Config admin local.',
        data: localConfig,
      );
    }

    try {
      final snapshot =
          await _firestore!.collection('app').doc('admin_config').get();
      final cloud = snapshot.data();
      if (cloud == null) {
        return ServiceResult(
          ok: true,
          message: 'Config admin no definida en nube.',
          data: localConfig,
        );
      }
      final remoteConfig = AppAdminConfig.fromJson(
        Map<String, dynamic>.from(cloud),
      );
      await _store.writeAdminConfig(remoteConfig.toJson());
      return ServiceResult(
        ok: true,
        message: 'Config admin cargada.',
        data: remoteConfig,
      );
    } catch (_) {
      return ServiceResult(
        ok: true,
        message: 'Config admin local por fallback.',
        data: localConfig,
      );
    }
  }

  Future<ServiceResult<AppAdminConfig>> saveAppAdminConfig(
    AppAdminConfig config,
  ) async {
    final blocked = config.blockedGameKeys
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
    final labels = <String, String>{};
    config.gameLabels.forEach((key, value) {
      final normalizedKey = key.trim().toLowerCase();
      final normalizedValue = value.trim();
      if (normalizedKey.isEmpty) return;
      if (normalizedValue.isEmpty) return;
      labels[normalizedKey] = normalizedValue;
    });
    final normalized = config.copyWith(
      maintenanceMessage: config.maintenanceMessage.trim(),
      minimumVersion: config.minimumVersion.trim(),
      blockedGameKeys: blocked,
      gameLabels: labels,
      updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
    );

    try {
      await _store.writeAdminConfig(normalized.toJson());
      if (_useFirebase) {
        await _firestore!
            .collection('app')
            .doc('admin_config')
            .set(normalized.toJson(), SetOptions(merge: true));
      }
      return ServiceResult(
        ok: true,
        message: 'Config admin guardada.',
        data: normalized,
      );
    } catch (e) {
      return ServiceResult(
        ok: false,
        message: 'No pudimos guardar la config admin: $e',
        data: normalized,
      );
    }
  }

  Future<ServiceResult<GameContentConfig>> fetchGameContentConfig({
    bool requireCloud = false,
  }) async {
    final local = _store.readGameContentConfig();
    final localConfig = local == null
        ? const GameContentConfig()
        : GameContentConfig.fromJson(local);

    if (!_useFirebase) {
      if (requireCloud) {
        return const ServiceResult(
          ok: false,
          message:
              'La sincronizacion global requiere Firebase habilitado en esta app.',
        );
      }
      return ServiceResult(
        ok: true,
        message: 'Contenido de juegos cargado desde local.',
        data: localConfig,
      );
    }

    try {
      final snapshot =
          await _firestore!.collection('app').doc('game_content_config').get();
      final cloud = snapshot.data();
      if (cloud == null) {
        if (requireCloud) {
          return const ServiceResult(
            ok: false,
            message: 'No hay contenido global publicado por administracion.',
          );
        }
        return ServiceResult(
          ok: true,
          message: 'Contenido de juegos no definido en nube.',
          data: localConfig,
        );
      }
      final remoteConfig = GameContentConfig.fromJson(
        Map<String, dynamic>.from(cloud),
      );
      await _store.writeGameContentConfig(remoteConfig.toJson());
      return ServiceResult(
        ok: true,
        message: 'Contenido de juegos cargado.',
        data: remoteConfig,
      );
    } catch (e) {
      if (requireCloud) {
        return ServiceResult(
          ok: false,
          message: 'No pudimos sincronizar el contenido global de juegos: $e',
        );
      }
      return ServiceResult(
        ok: true,
        message: 'Contenido de juegos local por fallback.',
        data: localConfig,
      );
    }
  }

  Future<ServiceResult<GameContentConfig>> saveGameContentConfig(
    GameContentConfig config,
  ) async {
    final emotions = config.emotionItems
        .where(
          (item) =>
              item.id.trim().isNotEmpty &&
              item.imagePath.trim().isNotEmpty &&
              item.correctEmotion.trim().isNotEmpty,
        )
        .map(
          (item) => item.copyWith(
            difficultyStars: item.difficultyStars.clamp(1, 3),
            imagePath: item.imagePath.trim(),
            correctEmotion: item.correctEmotion.trim(),
          ),
        )
        .toList();
    final sounds = config.soundItems
        .where(
          (item) =>
              item.id.trim().isNotEmpty &&
              item.soundAsset.trim().isNotEmpty &&
              item.correctImage.trim().isNotEmpty,
        )
        .map(
          (item) => item.copyWith(
            difficultyStars: item.difficultyStars.clamp(1, 3),
            soundAsset: item.soundAsset.trim(),
            correctImage: item.correctImage.trim(),
            category: item.category.trim(),
          ),
        )
        .toList();
    final normalized = GameContentConfig(
      emotionItems: emotions,
      soundItems: sounds,
      updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
    );

    try {
      await _store.writeGameContentConfig(normalized.toJson());
      if (_useFirebase) {
        await _firestore!
            .collection('app')
            .doc('game_content_config')
            .set(normalized.toJson(), SetOptions(merge: true));
      }
      return ServiceResult(
        ok: true,
        message: 'Contenido de juegos guardado.',
        data: normalized,
      );
    } catch (e) {
      return ServiceResult(
        ok: false,
        message: 'No pudimos guardar el contenido de juegos: $e',
        data: normalized,
      );
    }
  }

  Future<ServiceResult<AdminDashboardStats>> fetchAdminDashboardStats() async {
    final localUsers = await _store.readUsers();
    final localDeleted = await _readLocalDeletedAccountRecords();

    var source = 'local';
    var dashboardUsers = _buildDashboardUsersFromLocal(localUsers);
    var deletedAccounts = localDeleted;

    if (_useFirebase) {
      try {
        final usersSnapshot = await _firestore!.collection('users').get();
        dashboardUsers = _buildDashboardUsersFromCloud(usersSnapshot.docs);
        source = 'cloud';
      } catch (_) {}

      try {
        final deletedSnapshot =
            await _firestore!.collection('admin_deleted_accounts').get();
        final cloudDeleted = deletedSnapshot.docs.map((doc) {
          final json = Map<String, dynamic>.from(doc.data());
          if ((json['id'] as String?)?.trim().isEmpty ?? true) {
            json['id'] = doc.id;
          }
          return DeletedAccountRecord.fromJson(json);
        }).toList();
        if (cloudDeleted.isNotEmpty) {
          deletedAccounts = _mergeDeletedRecords(localDeleted, cloudDeleted);
          source = source == 'cloud' ? 'cloud' : 'mixed';
        }
      } catch (_) {}
    }

    final stats = _buildDashboardStats(
      users: dashboardUsers,
      deletedAccounts: deletedAccounts,
      source: source,
    );

    return ServiceResult(
      ok: true,
      message: 'Dashboard admin cargado.',
      data: stats,
    );
  }

  Future<ServiceResult<List<DeletedAccountRecord>>> fetchDeletedAccounts({
    int limit = 80,
  }) async {
    final safeLimit = limit.clamp(1, 500);
    final localRecords = await _readLocalDeletedAccountRecords();
    var merged = localRecords;
    var source = 'local';

    if (_useFirebase) {
      try {
        final snapshot = await _firestore!
            .collection('admin_deleted_accounts')
            .limit(1000)
            .get();
        final cloudRecords = snapshot.docs.map((doc) {
          final json = Map<String, dynamic>.from(doc.data());
          if ((json['id'] as String?)?.trim().isEmpty ?? true) {
            json['id'] = doc.id;
          }
          return DeletedAccountRecord.fromJson(json);
        }).toList();
        if (cloudRecords.isNotEmpty) {
          merged = _mergeDeletedRecords(localRecords, cloudRecords);
          source = 'cloud';
          await _writeLocalDeletedAccountRecords(merged);
        }
      } catch (_) {}
    }

    final sorted = [...merged]
      ..sort((a, b) => b.deletedAtMillis.compareTo(a.deletedAtMillis));
    return ServiceResult(
      ok: true,
      message: source == 'cloud'
          ? 'Cuentas eliminadas cargadas desde nube.'
          : 'Cuentas eliminadas cargadas desde local.',
      data: sorted.take(safeLimit).toList(),
    );
  }

  bool isValidUsernameFormat(String username) {
    final normalized = username.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9._-]{3,18}$').hasMatch(normalized)) {
      return false;
    }
    if (RegExp(r'^[._-]|[._-]$').hasMatch(normalized)) {
      return false;
    }
    return true;
  }

  Future<bool> checkUsernameAvailable(
    String username, {
    String excludeUserId = '',
  }) async {
    final trimmed = username.trim();
    if (!isValidUsernameFormat(trimmed)) return false;
    final normalized = trimmed.toLowerCase();

    final users = await _store.readUsers();
    final localTaken = users.any((user) {
      if (user.id == excludeUserId) return false;
      if (user.username.toLowerCase() == normalized) return true;
      final childUsername =
          user.childProfile?.loginUsername.trim().toLowerCase() ?? '';
      if (childUsername.isEmpty) return false;
      return childUsername == normalized;
    });
    if (localTaken) return false;

    final cloudTaken = await _isUsernameTakenInCloud(
      normalized,
      excludeUserId: excludeUserId,
    );
    if (cloudTaken == true) return false;

    final childCloudTaken = await _isChildLoginUsernameTakenInCloud(
      normalized,
      excludeCaregiverUserId: excludeUserId,
    );
    if (childCloudTaken == true) return false;

    return true;
  }

  Future<bool> checkChildLoginUsernameAvailable(
    String username, {
    String excludeCaregiverUserId = '',
  }) async {
    final trimmed = username.trim().toLowerCase();
    if (!isValidUsernameFormat(trimmed)) return false;

    final users = await _store.readUsers();
    final localTaken = users.any((user) {
      if (user.username.toLowerCase() == trimmed) return true;
      if (excludeCaregiverUserId.isNotEmpty &&
          user.id == excludeCaregiverUserId) {
        return false;
      }
      final childUsername =
          user.childProfile?.loginUsername.trim().toLowerCase() ?? '';
      if (childUsername.isEmpty) return false;
      return childUsername == trimmed;
    });
    if (localTaken) return false;

    final cloudUsernameTaken = await _isUsernameTakenInCloud(
      trimmed,
      excludeUserId: '',
    );
    if (cloudUsernameTaken == true) return false;

    final childCloudTaken = await _isChildLoginUsernameTakenInCloud(
      trimmed,
      excludeCaregiverUserId: excludeCaregiverUserId,
    );
    if (childCloudTaken == true) return false;

    return true;
  }

  String generateSuggestedUsername(String email) {
    final normalized = email.trim().toLowerCase();
    final seed =
        normalized.contains('@') ? normalized.split('@').first : normalized;
    return _sanitizeUsernameSeed(seed);
  }

  String _sanitizeUsernameSeed(String seed) {
    var cleaned = seed.toLowerCase().replaceAll(RegExp(r'[^a-z0-9._-]'), '_');
    cleaned = cleaned.replaceAll(RegExp(r'^[._-]+'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[._-]+$'), '');
    if (cleaned.length > 18) cleaned = cleaned.substring(0, 18);
    if (cleaned.length < 3) cleaned = 'user_$cleaned';
    cleaned = cleaned.replaceAll(RegExp(r'^[._-]+'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[._-]+$'), '');
    if (cleaned.length < 3) cleaned = 'user001';
    if (cleaned.length > 18) cleaned = cleaned.substring(0, 18);
    return cleaned;
  }

  Future<String> _resolveAvailableUsername({
    required String email,
    String preferredUsername = '',
    String excludeUserId = '',
  }) async {
    var base = preferredUsername.trim().toLowerCase();
    if (base.isEmpty) {
      base = generateSuggestedUsername(email);
    }
    if (!isValidUsernameFormat(base)) {
      base = _sanitizeUsernameSeed(base);
    }
    if (!isValidUsernameFormat(base)) {
      base = _sanitizeUsernameSeed(generateSuggestedUsername(email));
    }
    if (!isValidUsernameFormat(base)) {
      base = 'user001';
    }

    var candidate = base;
    for (var i = 0; i < 500; i++) {
      final available = await checkUsernameAvailable(
        candidate,
        excludeUserId: excludeUserId,
      );
      if (available) return candidate;

      final suffix = (i + 1).toString();
      final maxBase = 18 - suffix.length;
      final cutBase = base.length > maxBase ? base.substring(0, maxBase) : base;
      candidate = '$cutBase$suffix';
    }

    final fallbackSuffix =
        DateTime.now().millisecondsSinceEpoch.toString().substring(9);
    final maxBase = 18 - fallbackSuffix.length;
    final cutBase = base.length > maxBase ? base.substring(0, maxBase) : base;
    return '$cutBase$fallbackSuffix';
  }

  Future<ServiceResult<NebulaUser>> updateUsernameForCurrentUser(
    String newUsername,
  ) async {
    if (_currentUser == null) {
      return const ServiceResult(
        ok: false,
        message: 'No hay usuario actual.',
      );
    }

    final trimmed = newUsername.trim();
    if (!isValidUsernameFormat(trimmed)) {
      return const ServiceResult(
        ok: false,
        message:
            'El apodo debe tener 3 a 18 caracteres: letras, numeros, punto, guion y _.',
      );
    }

    if (_currentUser!.username.toLowerCase() == trimmed.toLowerCase()) {
      return ServiceResult(
        ok: true,
        message: 'Username actualizado correctamente.',
        data: _currentUser,
      );
    }

    final available = await checkUsernameAvailable(
      trimmed,
      excludeUserId: _currentUser!.id,
    );
    if (!available) {
      return const ServiceResult(
        ok: false,
        message: 'Ese apodo ya lo usa alguien mas. Prueba otro.',
      );
    }

    final updated = _currentUser!.copyWith(username: trimmed);
    await _upsertLocal(updated);
    _currentUser = updated;
    return ServiceResult(
      ok: true,
      message: 'Username actualizado correctamente.',
      data: updated,
    );
  }

  Future<ServiceResult<NebulaUser>> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final trimmedName = name.trim();
    final trimmedUsername = username.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final trimmedPassword = password.trim();

    if (trimmedName.isEmpty ||
        trimmedUsername.isEmpty ||
        normalizedEmail.isEmpty ||
        trimmedPassword.length < 6) {
      return const ServiceResult(
        ok: false,
        message:
            'Completa todos los campos. La contraseña debe tener al menos 6 caracteres.',
      );
    }

    if (!isValidEmailFormat(normalizedEmail)) {
      return const ServiceResult(
        ok: false,
        message: 'El correo no es valido.',
      );
    }

    if (!isValidUsernameFormat(trimmedUsername)) {
      return const ServiceResult(
        ok: false,
        message:
            'El apodo debe tener 3 a 18 caracteres: letras, numeros, punto, guion y _.',
      );
    }

    final usernameAvailable = await checkUsernameAvailable(trimmedUsername);
    if (!usernameAvailable) {
      return const ServiceResult(
        ok: false,
        message: 'Ese apodo ya lo usa alguien mas. Prueba otro.',
      );
    }

    final users = await _store.readUsers();
    NebulaUser? existingEmailUser;
    for (final user in users) {
      if (user.email.toLowerCase() == normalizedEmail) {
        existingEmailUser = user;
        break;
      }
    }
    if (existingEmailUser != null) {
      if (existingEmailUser.password.trim().isEmpty) {
        return const ServiceResult(
          ok: false,
          message:
              'Ese correo ya existe con Google. Entra con Google y luego crea una contraseña desde tu perfil si quieres entrar tambien con contraseña.',
        );
      }
      return const ServiceResult(
        ok: false,
        message: 'Ese correo ya esta registrado.',
      );
    }

    String userId = _uuid.v4();
    User? firebaseUser;
    if (_useFirebase) {
      try {
        final credential = await _firebaseAuth!.createUserWithEmailAndPassword(
          email: normalizedEmail,
          password: trimmedPassword,
        );
        firebaseUser = credential.user;
        if (firebaseUser == null) {
          return const ServiceResult(
            ok: false,
            message: 'No pudimos crear tu cuenta en Firebase Auth.',
          );
        }
        userId = firebaseUser.uid;
        try {
          await firebaseUser.updateDisplayName(trimmedName);
        } catch (_) {}
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          return const ServiceResult(
            ok: false,
            message: 'Ese correo ya esta registrado.',
          );
        }
        if (e.code == 'weak-password') {
          return const ServiceResult(
            ok: false,
            message: 'La contraseña es muy debil. Usa al menos 6 caracteres.',
          );
        }
        if (e.code == 'invalid-email') {
          return const ServiceResult(
            ok: false,
            message: 'El correo no es valido.',
          );
        }
        return ServiceResult(
          ok: false,
          message: 'Error al crear cuenta en Firebase: ${e.message ?? e.code}',
        );
      }
    }

    final newUser = NebulaUser(
      id: userId,
      name: trimmedName,
      username: trimmedUsername,
      email: normalizedEmail,
      password: _hashPassword(trimmedPassword),
      parentalPinHash: '',
      stars: 0,
      avatarIndex: 0,
      selectedNarratorId: 'narrator_1',
      soundEffectsEnabled: true,
      accentHue: 190,
      accentIntensity: 0.55,
      customImages: const {},
      role: UserRole.caregiver,
    );

    if (_useFirebase) {
      try {
        await _writeCloudUser(newUser);
        if (firebaseUser != null) {
          await _firebaseAuth?.setLanguageCode('es');
          await firebaseUser.sendEmailVerification();
        }
        await _firebaseAuth?.signOut();
        await _store.clearSession();
        _currentUser = null;
        _activePortalRole = PortalRole.caregiver;
        return const ServiceResult(
          ok: true,
          message:
              'Cuenta creada. Te enviamos un correo de verificacion. Tienes 1 hora para verificarlo o la cuenta se eliminara por seguridad.',
        );
      } catch (e) {
        try {
          await firebaseUser?.delete();
        } catch (_) {}
        try {
          await _firebaseAuth?.signOut();
        } catch (_) {}
        _currentUser = null;
        _activePortalRole = PortalRole.caregiver;
        await _store.clearSession();
        return ServiceResult(
          ok: false,
          message: 'No pudimos completar el registro y verificar el correo: $e',
        );
      }
    }

    await _upsertLocal(newUser);
    await _persistSessionState(newUser, requestedRole: PortalRole.caregiver);
    _currentUser = newUser;

    return ServiceResult(
      ok: true,
      message: 'Cuenta creada. Bienvenido a Nebula.',
      data: newUser,
    );
  }

  Future<ServiceResult<NebulaUser>> registerCaregiver({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final preferredUsername = _sanitizeUsernameSeed(name.trim().toLowerCase());
    final resolvedUsername = await _resolveAvailableUsername(
      email: normalizedEmail,
      preferredUsername: preferredUsername,
    );
    return register(
      name: name,
      username: resolvedUsername,
      email: normalizedEmail,
      password: password,
    );
  }

  Future<ServiceResult<NebulaUser>> ensureHiddenAdminAccount({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final trimmedPassword = password.trim();
    if (!isValidEmailFormat(normalizedEmail) || trimmedPassword.length < 6) {
      return const ServiceResult(
        ok: false,
        message: 'Configuracion admin invalida.',
      );
    }

    final users = await _store.readUsers();
    for (final user in users) {
      if (user.role == UserRole.admin) {
        return ServiceResult(
          ok: true,
          message: 'Cuenta admin ya existente.',
          data: user,
        );
      }
    }

    var usernameBase = 'admin_nebula';
    var candidate = usernameBase;
    var i = 1;
    while (users.any((u) => u.username.toLowerCase() == candidate)) {
      candidate = '${usernameBase}_$i';
      i++;
    }

    final newAdmin = NebulaUser(
      id: _uuid.v4(),
      name: 'Administrador Nebula',
      username: candidate,
      email: normalizedEmail,
      password: _hashPassword(trimmedPassword),
      parentalPinHash: '',
      stars: 0,
      avatarIndex: 0,
      selectedNarratorId: 'narrator_1',
      soundEffectsEnabled: true,
      accentHue: 190,
      accentIntensity: 0.55,
      customImages: const {},
      role: UserRole.admin,
    );

    await _upsertLocal(newAdmin);
    return ServiceResult(
      ok: true,
      message: 'Cuenta admin creada.',
      data: newAdmin,
    );
  }

  Future<ServiceResult<NebulaUser>> login({
    required String identifier,
    required String password,
  }) async {
    final needle = identifier.trim().toLowerCase();
    final secret = password.trim();
    if (needle.isEmpty || secret.isEmpty) {
      return const ServiceResult(
        ok: false,
        message: 'Escribe tu usuario/correo y tu contraseña para entrar.',
      );
    }

    final users = await _store.readUsers();
    NebulaUser? match;
    for (final user in users) {
      if (user.email.toLowerCase() == needle ||
          user.username.toLowerCase() == needle) {
        match = user;
        break;
      }
    }

    if (match == null && _useFirebase) {
      var loginEmail = needle.contains('@') ? needle : '';
      if (loginEmail.isEmpty) {
        loginEmail = await _lookupEmailByUsernameFromCloud(needle) ?? '';
      }
      if (loginEmail.isNotEmpty) {
        final firebaseOnlyLogin = await _loginUsingFirebaseWithoutLocalUser(
          email: loginEmail,
          password: secret,
        );
        if (firebaseOnlyLogin.ok && firebaseOnlyLogin.data != null) {
          return firebaseOnlyLogin;
        }
        return ServiceResult(
          ok: false,
          message: firebaseOnlyLogin.message,
        );
      }
    }

    if (match != null && match.password.trim().isEmpty) {
      return const ServiceResult(
        ok: false,
        message:
            'Esta cuenta entra con Google. Usa "Entrar con Google" o crea una contraseña desde tu perfil.',
      );
    }

    if (match == null) {
      return const ServiceResult(
        ok: false,
        message: 'No pudimos entrar. Revisa tus datos e intenta otra vez.',
      );
    }

    final localPasswordMatches = _passwordMatches(
      stored: match.password,
      input: secret,
    );
    if (!localPasswordMatches) {
      if (_useFirebase) {
        final firebaseSync = await _ensureFirebaseUserForPasswordLogin(
          localUser: match,
          plainPassword: secret,
          createIfMissing: false,
        );
        if (firebaseSync.ok && firebaseSync.data != null) {
          match = firebaseSync.data!;
          await _persistSessionState(match);
          _currentUser = match;
          return ServiceResult(
            ok: true,
            message: 'Listo, ya estas dentro.',
            data: match,
          );
        }
      }
      return const ServiceResult(
        ok: false,
        message: 'No pudimos entrar. Revisa tus datos e intenta otra vez.',
      );
    }

    if (!_isSha256Hex(match.password)) {
      final migrated = match.copyWith(password: _hashPassword(secret));
      await _upsertLocal(migrated);
      match = migrated;
    }

    if (_useFirebase && match.role != UserRole.admin) {
      final firebaseSync = await _ensureFirebaseUserForPasswordLogin(
        localUser: match,
        plainPassword: secret,
      );
      if (!firebaseSync.ok || firebaseSync.data == null) {
        return ServiceResult(ok: false, message: firebaseSync.message);
      }
      match = firebaseSync.data!;
    }

    await _persistSessionState(match);
    _currentUser = match;
    return ServiceResult(
        ok: true, message: 'Listo, ya estas dentro.', data: match);
  }

  Future<ServiceResult<NebulaUser>> loginChild({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();
    final trimmedPassword = password.trim();
    if (normalizedUsername.isEmpty || trimmedPassword.isEmpty) {
      return const ServiceResult(
        ok: false,
        message: 'Escribe usuario y contrase\u00f1a para continuar.',
      );
    }
    if (!isValidUsernameFormat(normalizedUsername)) {
      return const ServiceResult(
        ok: false,
        message: 'El usuario del ni\u00f1o no es valido.',
      );
    }
    if (!isValidChildLoginPinFormat(trimmedPassword)) {
      return const ServiceResult(
        ok: false,
        message:
            'La contrase\u00f1a del ni\u00f1o debe tener al menos 6 caracteres.',
      );
    }

    final users = await _store.readUsers();
    NebulaUser? match;
    for (final user in users) {
      final child = user.childProfile;
      if (child == null) continue;
      final childUsername = child.loginUsername.trim().toLowerCase();
      if (childUsername == normalizedUsername) {
        match = user;
        break;
      }
    }

    if (match == null) {
      return const ServiceResult(
        ok: false,
        message:
            'No encontramos ese perfil de ni\u00f1o en este dispositivo. Pide a un cuidador iniciar sesion aqui primero.',
      );
    }

    final expectedHash = match.childProfile?.loginPinHash.trim() ?? '';
    if (expectedHash.isEmpty ||
        expectedHash != _hashParentalPin(trimmedPassword)) {
      return const ServiceResult(
        ok: false,
        message: 'Usuario o contrase\u00f1a incorrecta.',
      );
    }

    await _persistSessionState(match, requestedRole: PortalRole.child);
    _currentUser = match;
    return ServiceResult(
      ok: true,
      message: 'Bienvenido, a jugar.',
      data: match,
    );
  }

  Future<void> logout() async {
    await _store.clearSession();
    if (_useFirebase) {
      try {
        await _firebaseAuth!.signOut();
      } catch (_) {}
    }
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
    _currentUser = null;
    _activePortalRole = PortalRole.caregiver;
    _clearPendingGoogleLink();
    _clearPendingGoogleConfirmation();
  }

  Future<ServiceResult<NebulaUser>> updateUser(NebulaUser nextUser) async {
    await _upsertLocal(nextUser);
    await _persistSessionState(nextUser, requestedRole: _activePortalRole);
    _currentUser = nextUser;
    return ServiceResult(
      ok: true,
      message: 'Datos actualizados.',
      data: nextUser,
    );
  }

  Future<ServiceResult<NebulaUser>> updateProfile({
    required String userId,
    required String name,
    required String username,
    required int avatarIndex,
  }) async {
    final users = await _store.readUsers();
    NebulaUser? current;
    for (final user in users) {
      if (user.id == userId) {
        current = user;
        break;
      }
    }
    if (current == null) {
      return const ServiceResult(ok: false, message: 'Usuario no encontrado.');
    }

    final trimmedName = name.trim();
    final trimmedUsername = username.trim();

    if (trimmedName.isEmpty || trimmedUsername.isEmpty) {
      return const ServiceResult(
        ok: false,
        message: 'Nombre y apodo son obligatorios.',
      );
    }

    if (!isValidUsernameFormat(trimmedUsername)) {
      return const ServiceResult(
        ok: false,
        message:
            'El apodo debe tener 3 a 18 caracteres: letras, numeros, punto, guion y _.',
      );
    }

    final usernameAvailable = await checkUsernameAvailable(
      trimmedUsername,
      excludeUserId: userId,
    );
    if (!usernameAvailable) {
      return const ServiceResult(
        ok: false,
        message: 'Ese apodo ya esta en uso por otra cuenta.',
      );
    }

    final next = current.copyWith(
      name: trimmedName,
      username: trimmedUsername,
      avatarIndex: avatarIndex,
    );
    return updateUser(next);
  }

  Future<bool> existsEmailOrUsername(String value) async {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    final users = await _store.readUsers();
    return users.any(
      (user) =>
          user.email.toLowerCase() == normalized ||
          user.username.toLowerCase() == normalized,
    );
  }

  Future<ServiceResult<NebulaUser>> loginWithGoogle() async {
    if (!_useFirebase) {
      return const ServiceResult(
        ok: false,
        message: 'Google Sign-In solo funciona con Firebase habilitado.',
      );
    }

    try {
      _clearPendingGoogleLink();
      _clearPendingGoogleConfirmation();

      // Limpia cuenta de Google en memoria para forzar selector de cuenta.
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final account = await _googleSignIn.signIn();
      if (account == null) {
        return const ServiceResult(
          ok: false,
          message: 'Google Sign-In cancelado.',
        );
      }

      final emailLower = account.email.trim().toLowerCase();
      if (emailLower.isEmpty) {
        return const ServiceResult(
          ok: false,
          message: 'Tu cuenta de Google no devolvio un correo valido.',
        );
      }

      final users = await _store.readUsers();
      NebulaUser? existingUser;
      for (final user in users) {
        if (user.email.toLowerCase() == emailLower) {
          existingUser = user;
          break;
        }
      }
      final localMissingUsername =
          existingUser == null || existingUser.username.trim().isEmpty;
      final localMissingPassword =
          existingUser == null || existingUser.password.trim().isEmpty;
      var needsUsernameSetup = localMissingUsername || localMissingPassword;
      var suggestedUsername =
          (existingUser != null && existingUser.username.trim().isNotEmpty)
              ? existingUser.username.trim()
              : generateSuggestedUsername(emailLower);
      if (existingUser == null && _useFirebase) {
        try {
          final cloudByEmail = await _firestore!
              .collection('users')
              .where('emailLower', isEqualTo: emailLower)
              .limit(1)
              .get();
          var cloudUsername = '';
          var cloudHasLocalPassword = false;
          if (cloudByEmail.docs.isNotEmpty) {
            final cloudData = cloudByEmail.docs.first.data();
            cloudUsername = (cloudData['username'] as String?)?.trim() ?? '';
            cloudHasLocalPassword =
                (cloudData['hasLocalPassword'] as bool?) ?? false;
          }
          if (cloudUsername.isNotEmpty) {
            suggestedUsername = cloudUsername;
          }
          needsUsernameSetup = cloudUsername.isEmpty || !cloudHasLocalPassword;
        } catch (_) {}
      }
      if (needsUsernameSetup) {
        suggestedUsername = await _resolveAvailableUsername(
          email: emailLower,
          preferredUsername: suggestedUsername,
        );
      }

      final auth = await account.authentication;
      final accessToken = auth.accessToken;
      final idToken = auth.idToken;
      final hasValidToken =
          (accessToken ?? '').isNotEmpty || (idToken ?? '').isNotEmpty;
      if (!hasValidToken) {
        return const ServiceResult(
          ok: false,
          message: 'No pudimos validar tu cuenta de Google.',
        );
      }

      _pendingGoogleAccessTokenForConfirm = accessToken;
      _pendingGoogleIdTokenForConfirm = idToken;
      _pendingGoogleEmailForConfirm = emailLower;
      _pendingGoogleNameForConfirm = account.displayName ?? 'Explorador';
      if (needsUsernameSetup) {
        return ServiceResult(
          ok: false,
          message:
              'GOOGLE_CONFIRM_REQUIRED_WITH_USERNAME:$emailLower|$suggestedUsername',
        );
      }
      return ServiceResult(
        ok: false,
        message: 'GOOGLE_CONFIRM_REQUIRED:$emailLower',
      );
    } catch (e) {
      _clearPendingGoogleLink();
      _clearPendingGoogleConfirmation();
      return ServiceResult(
        ok: false,
        message: 'Error al iniciar sesión con Google: $e',
      );
    }
  }

  Future<ServiceResult<NebulaUser>> confirmPendingGoogleLogin({
    String preferredUsernameForNewAccount = '',
    String preferredPasswordForNewAccount = '',
  }) async {
    if (!_useFirebase) {
      return const ServiceResult(
        ok: false,
        message: 'Google Sign-In solo funciona con Firebase habilitado.',
      );
    }

    final accessToken = _pendingGoogleAccessTokenForConfirm;
    final idToken = _pendingGoogleIdTokenForConfirm;
    final hasValidToken =
        (accessToken ?? '').isNotEmpty || (idToken ?? '').isNotEmpty;
    if (!hasValidToken) {
      return const ServiceResult(
        ok: false,
        message: 'No hay una confirmacion pendiente de Google.',
      );
    }

    try {
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );
      final userCredential =
          await _firebaseAuth!.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        _clearPendingGoogleConfirmation();
        return const ServiceResult(
          ok: false,
          message: 'No pudimos crear la sesión de Google.',
        );
      }

      final emailLower =
          (firebaseUser.email ?? _pendingGoogleEmailForConfirm ?? '')
              .trim()
              .toLowerCase();
      if (emailLower.isEmpty) {
        _clearPendingGoogleConfirmation();
        return const ServiceResult(
          ok: false,
          message: 'Tu cuenta de Google no devolvio un correo valido.',
        );
      }

      final users = await _store.readUsers();
      NebulaUser? existingUserByUid;
      NebulaUser? existingUserByEmail;
      for (final user in users) {
        if (user.id == firebaseUser.uid) {
          existingUserByUid = user;
          break;
        }
        if (existingUserByEmail == null &&
            user.email.toLowerCase() == emailLower) {
          existingUserByEmail = user;
        }
      }
      final existingUser = existingUserByUid ?? existingUserByEmail;

      var hasPasswordProvider = firebaseUser.providerData.any(
        (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
      );
      var hasGoogleProvider = firebaseUser.providerData.any(
        (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID,
      );
      if (!hasPasswordProvider || !hasGoogleProvider) {
        try {
          await firebaseUser.reload();
          final refreshed = _firebaseAuth.currentUser;
          if (refreshed != null && refreshed.uid == firebaseUser.uid) {
            hasPasswordProvider = refreshed.providerData.any(
              (provider) =>
                  provider.providerId == EmailAuthProvider.PROVIDER_ID,
            );
            hasGoogleProvider = refreshed.providerData.any(
              (provider) =>
                  provider.providerId == GoogleAuthProvider.PROVIDER_ID,
            );
          }
        } catch (_) {}
      }
      final alreadyLinkedOnFirebase = hasPasswordProvider && hasGoogleProvider;

      if (existingUser != null &&
          existingUser.password.isNotEmpty &&
          existingUser.id != firebaseUser.uid &&
          !alreadyLinkedOnFirebase) {
        _pendingGoogleUserForLink = NebulaUser(
          id: firebaseUser.uid,
          name: _pendingGoogleNameForConfirm ??
              firebaseUser.displayName ??
              'Explorador',
          username: generateSuggestedUsername(emailLower),
          email: emailLower,
          password: '',
          parentalPinHash: '',
          stars: 0,
          avatarIndex: 0,
          selectedNarratorId: 'narrator_1',
          soundEffectsEnabled: true,
          accentHue: 190,
          accentIntensity: 0.55,
          customImages: const {},
        );
        _pendingLocalUserForLink = existingUser;
        _pendingGoogleAccessTokenForLink = accessToken;
        _pendingGoogleIdTokenForLink = idToken;
        _clearPendingGoogleConfirmation();
        try {
          await _firebaseAuth.signOut();
        } catch (_) {}
        try {
          await _googleSignIn.signOut();
        } catch (_) {}
        return const ServiceResult(
          ok: false,
          message: 'EMAIL_EXISTS_NEED_LINK',
        );
      }

      late final NebulaUser signedUser;
      if (existingUser != null) {
        final localUser = existingUser;
        final preferredTyped = preferredUsernameForNewAccount.trim();
        final preferredPassword = preferredPasswordForNewAccount.trim();
        final requiresUsernameSetup = localUser.username.trim().isEmpty;
        final requiresPasswordSetup =
            localUser.password.trim().isEmpty || !hasPasswordProvider;

        if (requiresUsernameSetup) {
          if (preferredTyped.isEmpty) {
            _clearPendingGoogleConfirmation();
            try {
              await _firebaseAuth.signOut();
            } catch (_) {}
            try {
              await _googleSignIn.signOut();
            } catch (_) {}
            return const ServiceResult(
              ok: false,
              message: 'Elige un apodo para continuar.',
            );
          }
          if (!isValidUsernameFormat(preferredTyped)) {
            _clearPendingGoogleConfirmation();
            try {
              await _firebaseAuth.signOut();
            } catch (_) {}
            try {
              await _googleSignIn.signOut();
            } catch (_) {}
            return const ServiceResult(
              ok: false,
              message:
                  'El apodo debe tener 3 a 18 caracteres: letras, numeros, punto, guion y _.',
            );
          }
          final available = await checkUsernameAvailable(
            preferredTyped,
            excludeUserId: localUser.id,
          );
          if (!available) {
            _clearPendingGoogleConfirmation();
            try {
              await _firebaseAuth.signOut();
            } catch (_) {}
            try {
              await _googleSignIn.signOut();
            } catch (_) {}
            return const ServiceResult(
              ok: false,
              message: 'Ese apodo ya lo usa alguien mas. Prueba otro.',
            );
          }
        } else if (preferredTyped.isNotEmpty &&
            preferredTyped.toLowerCase() != localUser.username.toLowerCase()) {
          if (!isValidUsernameFormat(preferredTyped)) {
            _clearPendingGoogleConfirmation();
            try {
              await _firebaseAuth.signOut();
            } catch (_) {}
            try {
              await _googleSignIn.signOut();
            } catch (_) {}
            return const ServiceResult(
              ok: false,
              message:
                  'El apodo debe tener 3 a 18 caracteres: letras, numeros, punto, guion y _.',
            );
          }
          final available = await checkUsernameAvailable(
            preferredTyped,
            excludeUserId: localUser.id,
          );
          if (!available) {
            _clearPendingGoogleConfirmation();
            try {
              await _firebaseAuth.signOut();
            } catch (_) {}
            try {
              await _googleSignIn.signOut();
            } catch (_) {}
            return const ServiceResult(
              ok: false,
              message: 'Ese apodo ya lo usa alguien mas. Prueba otro.',
            );
          }
        }

        if (requiresPasswordSetup) {
          if (preferredPassword.length < 6) {
            _clearPendingGoogleConfirmation();
            try {
              await _firebaseAuth.signOut();
            } catch (_) {}
            try {
              await _googleSignIn.signOut();
            } catch (_) {}
            return const ServiceResult(
              ok: false,
              message: 'La contraseña debe tener al menos 6 caracteres.',
            );
          }

          try {
            if (hasPasswordProvider) {
              await firebaseUser.updatePassword(preferredPassword);
            } else {
              final emailCredential = EmailAuthProvider.credential(
                email: emailLower,
                password: preferredPassword,
              );
              await firebaseUser.linkWithCredential(emailCredential);
            }
            hasPasswordProvider = true;
          } on FirebaseAuthException catch (e) {
            if (e.code == 'provider-already-linked') {
              try {
                await firebaseUser.updatePassword(preferredPassword);
                hasPasswordProvider = true;
              } on FirebaseAuthException catch (inner) {
                _clearPendingGoogleConfirmation();
                try {
                  await _firebaseAuth.signOut();
                } catch (_) {}
                try {
                  await _googleSignIn.signOut();
                } catch (_) {}
                return ServiceResult(
                  ok: false,
                  message:
                      'No pudimos guardar tu contraseña local: ${inner.message ?? inner.code}',
                );
              }
            } else {
              _clearPendingGoogleConfirmation();
              try {
                await _firebaseAuth.signOut();
              } catch (_) {}
              try {
                await _googleSignIn.signOut();
              } catch (_) {}
              if (e.code == 'credential-already-in-use' ||
                  e.code == 'email-already-in-use') {
                return const ServiceResult(
                  ok: false,
                  message:
                      'No pudimos crear la contraseña local porque ese correo ya esta vinculado en otra cuenta.',
                );
              }
              return ServiceResult(
                ok: false,
                message:
                    'No pudimos crear tu contraseña local: ${e.message ?? e.code}',
              );
            }
          }
        }

        final preferredForResolve = requiresUsernameSetup
            ? (preferredTyped.isNotEmpty
                ? preferredTyped
                : (_pendingGoogleNameForConfirm ?? ''))
            : (preferredTyped.isNotEmpty ? preferredTyped : localUser.username);
        final resolvedUsername = await _resolveAvailableUsername(
          email: emailLower,
          preferredUsername: preferredForResolve,
          excludeUserId: localUser.id,
        );
        final preservedUser = NebulaUser(
          id: firebaseUser.uid,
          name: localUser.name.trim().isEmpty
              ? (_pendingGoogleNameForConfirm ??
                  firebaseUser.displayName ??
                  'Explorador')
              : localUser.name,
          username: resolvedUsername,
          email: emailLower,
          password: requiresPasswordSetup
              ? _hashPassword(preferredPassword)
              : localUser.password,
          parentalPinHash: localUser.parentalPinHash,
          stars: localUser.stars,
          avatarIndex: localUser.avatarIndex,
          selectedNarratorId: localUser.selectedNarratorId,
          soundEffectsEnabled: localUser.soundEffectsEnabled,
          accentHue: localUser.accentHue,
          accentIntensity: localUser.accentIntensity,
          customImages: localUser.customImages,
          role: localUser.role,
          childProfile: localUser.childProfile,
          gameSessions: localUser.gameSessions,
          parentalControl: localUser.parentalControl,
        );

        final nextUsers = users
            .where(
              (u) =>
                  u.id != localUser.id &&
                  u.id != firebaseUser.uid &&
                  u.email.toLowerCase() != emailLower,
            )
            .toList();
        nextUsers.add(preservedUser);
        await _store.writeUsers(nextUsers);
        signedUser = preservedUser;
      } else {
        final cloudDoc =
            await _firestore!.collection('users').doc(firebaseUser.uid).get();
        final cloud = cloudDoc.data();

        final cloudUsername = (cloud?['username'] as String?)?.trim() ?? '';
        final preferredTyped = preferredUsernameForNewAccount.trim();
        final preferredPassword = preferredPasswordForNewAccount.trim();
        final requiresUsernameSetup = cloudUsername.isEmpty;
        final requiresPasswordSetup = !hasPasswordProvider;

        if (requiresUsernameSetup) {
          if (preferredTyped.isEmpty) {
            _clearPendingGoogleConfirmation();
            try {
              await _firebaseAuth.signOut();
            } catch (_) {}
            try {
              await _googleSignIn.signOut();
            } catch (_) {}
            return const ServiceResult(
              ok: false,
              message: 'Elige un apodo para continuar.',
            );
          }
          if (!isValidUsernameFormat(preferredTyped)) {
            _clearPendingGoogleConfirmation();
            try {
              await _firebaseAuth.signOut();
            } catch (_) {}
            try {
              await _googleSignIn.signOut();
            } catch (_) {}
            return const ServiceResult(
              ok: false,
              message:
                  'El apodo debe tener 3 a 18 caracteres: letras, numeros, punto, guion y _.',
            );
          }
          final available = await checkUsernameAvailable(
            preferredTyped,
            excludeUserId: firebaseUser.uid,
          );
          if (!available) {
            _clearPendingGoogleConfirmation();
            try {
              await _firebaseAuth.signOut();
            } catch (_) {}
            try {
              await _googleSignIn.signOut();
            } catch (_) {}
            return const ServiceResult(
              ok: false,
              message: 'Ese apodo ya lo usa alguien mas. Prueba otro.',
            );
          }
        }
        if (requiresPasswordSetup && preferredPassword.length < 6) {
          _clearPendingGoogleConfirmation();
          try {
            await _firebaseAuth.signOut();
          } catch (_) {}
          try {
            await _googleSignIn.signOut();
          } catch (_) {}
          return const ServiceResult(
            ok: false,
            message: 'La contraseña debe tener al menos 6 caracteres.',
          );
        }

        if (requiresPasswordSetup) {
          try {
            if (hasPasswordProvider) {
              await firebaseUser.updatePassword(preferredPassword);
            } else {
              final emailCredential = EmailAuthProvider.credential(
                email: emailLower,
                password: preferredPassword,
              );
              await firebaseUser.linkWithCredential(emailCredential);
            }
            hasPasswordProvider = true;
          } on FirebaseAuthException catch (e) {
            if (e.code == 'provider-already-linked') {
              try {
                await firebaseUser.updatePassword(preferredPassword);
                hasPasswordProvider = true;
              } on FirebaseAuthException catch (inner) {
                _clearPendingGoogleConfirmation();
                try {
                  await _firebaseAuth.signOut();
                } catch (_) {}
                try {
                  await _googleSignIn.signOut();
                } catch (_) {}
                return ServiceResult(
                  ok: false,
                  message:
                      'No pudimos guardar tu contraseña local: ${inner.message ?? inner.code}',
                );
              }
            } else {
              _clearPendingGoogleConfirmation();
              try {
                await _firebaseAuth.signOut();
              } catch (_) {}
              try {
                await _googleSignIn.signOut();
              } catch (_) {}
              if (e.code == 'credential-already-in-use' ||
                  e.code == 'email-already-in-use') {
                return const ServiceResult(
                  ok: false,
                  message:
                      'No pudimos crear la contraseña local porque ese correo ya esta vinculado en otra cuenta.',
                );
              }
              return ServiceResult(
                ok: false,
                message:
                    'No pudimos crear tu contraseña local: ${e.message ?? e.code}',
              );
            }
          }
        }

        final preferredForResolve = requiresUsernameSetup
            ? (preferredTyped.isNotEmpty
                ? preferredTyped
                : (_pendingGoogleNameForConfirm ?? ''))
            : cloudUsername;
        final resolvedUsername = await _resolveAvailableUsername(
          email: emailLower,
          preferredUsername: preferredForResolve,
          excludeUserId: firebaseUser.uid,
        );
        final newUser = NebulaUser(
          id: firebaseUser.uid,
          name: (cloud?['name'] as String?)?.trim().isNotEmpty == true
              ? (cloud!['name'] as String)
              : (_pendingGoogleNameForConfirm ??
                  firebaseUser.displayName ??
                  'Explorador'),
          username: resolvedUsername,
          email: emailLower,
          password:
              requiresPasswordSetup ? _hashPassword(preferredPassword) : '',
          parentalPinHash: '',
          stars: (cloud?['stars'] as num?)?.toInt() ?? 0,
          avatarIndex: (cloud?['avatarIndex'] as num?)?.toInt() ?? 0,
          selectedNarratorId:
              (cloud?['selectedNarratorId'] as String?) ?? 'narrator_1',
          soundEffectsEnabled: (cloud?['soundEffectsEnabled'] as bool?) ?? true,
          accentHue: (cloud?['accentHue'] as num?)?.toDouble() ?? 190,
          accentIntensity:
              (cloud?['accentIntensity'] as num?)?.toDouble() ?? 0.55,
          customImages: Map<String, String>.from(
            cloud?['customImages'] as Map? ?? const {},
          ),
          role: (cloud?['role'] as String?) ?? UserRole.caregiver,
          childProfile: cloud?['childProfile'] is Map
              ? ChildProfile.fromJson(
                  Map<String, dynamic>.from(cloud!['childProfile'] as Map),
                )
              : null,
          gameSessions: (cloud?['gameSessions'] as List? ?? const [])
              .whereType<Map>()
              .map(
                (item) => GameSessionRecord.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(),
          parentalControl: cloud?['parentalControl'] is Map
              ? ParentalControl.fromJson(
                  Map<String, dynamic>.from(cloud!['parentalControl'] as Map),
                )
              : const ParentalControl(),
        );
        await _upsertLocal(newUser);
        signedUser = newUser;
      }

      await _persistSessionState(
        signedUser,
        requestedRole: signedUser.role == UserRole.admin
            ? PortalRole.admin
            : PortalRole.caregiver,
      );
      _currentUser = signedUser;
      await _syncCloudUserBestEffort(signedUser);
      _clearPendingGoogleLink();
      _clearPendingGoogleConfirmation();

      return ServiceResult(
        ok: true,
        message: 'sesión iniciada con Google.',
        data: signedUser,
      );
    } catch (e) {
      _clearPendingGoogleConfirmation();
      return ServiceResult(
        ok: false,
        message: 'Error al confirmar Google: $e',
      );
    }
  }

  Future<void> cancelPendingGoogleLogin() async {
    _clearPendingGoogleConfirmation();
    try {
      await _firebaseAuth?.signOut();
    } catch (_) {}
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
  }

  Future<ServiceResult<void>> setPasswordForCurrentUser({
    required String newPassword,
    String parentalPin = '',
  }) async {
    if (_currentUser == null) {
      return const ServiceResult(
        ok: false,
        message: 'No hay usuario actual.',
      );
    }

    final trimmed = newPassword.trim();
    if (trimmed.length < 6) {
      return const ServiceResult(
        ok: false,
        message: 'La contraseña debe tener al menos 6 caracteres.',
      );
    }

    try {
      if (_useFirebase) {
        await _firebaseAuth!.currentUser?.updatePassword(trimmed);
      }

      final updated = _currentUser!.copyWith(password: _hashPassword(trimmed));
      await _upsertLocal(updated);
      _currentUser = updated;

      return const ServiceResult(
        ok: true,
        message: 'contraseña establecida correctamente.',
      );
    } catch (e) {
      return ServiceResult(
        ok: false,
        message: 'Error al establecer contraseña: $e',
      );
    }
  }

  Future<ServiceResult<NebulaUser>> setupGoogleRecoveryPassword({
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      return const ServiceResult(
        ok: false,
        message: 'No hay usuario actual.',
      );
    }
    if (!_useFirebase || !isCurrentUserGoogleProvider) {
      return const ServiceResult(
        ok: false,
        message: 'Este flujo solo aplica para cuentas de Google.',
      );
    }

    final trimmed = newPassword.trim();
    if (trimmed.length < 6) {
      return const ServiceResult(
        ok: false,
        message: 'La contraseña debe tener al menos 6 caracteres.',
      );
    }

    final firebaseUser = _firebaseAuth?.currentUser;
    if (firebaseUser == null) {
      return const ServiceResult(
        ok: false,
        message: 'No hay sesión valida en Firebase.',
      );
    }

    final currentEmail = _currentUser!.email.trim().toLowerCase();
    if (currentEmail.isEmpty) {
      return const ServiceResult(
        ok: false,
        message: 'No pudimos leer un correo valido en tu cuenta.',
      );
    }

    try {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      try {
        await _googleSignIn.disconnect();
      } catch (_) {}

      final account = await _googleSignIn.signIn();
      if (account == null) {
        return const ServiceResult(
          ok: false,
          message: 'Proceso cancelado.',
        );
      }

      final selectedEmail = account.email.trim().toLowerCase();
      if (selectedEmail != currentEmail) {
        return ServiceResult(
          ok: false,
          message: 'Debes elegir la misma cuenta de Google ($currentEmail).',
        );
      }

      final auth = await account.authentication;
      final googleCredential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      await firebaseUser.reauthenticateWithCredential(googleCredential);

      if (isCurrentUserPasswordProvider) {
        await firebaseUser.updatePassword(trimmed);
      } else {
        final emailCredential = EmailAuthProvider.credential(
          email: currentEmail,
          password: trimmed,
        );
        try {
          await firebaseUser.linkWithCredential(emailCredential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'provider-already-linked') {
            await firebaseUser.updatePassword(trimmed);
          } else if (e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use') {
            return const ServiceResult(
              ok: false,
              message:
                  'Ese correo ya esta vinculado con contraseña en otra cuenta.',
            );
          } else {
            rethrow;
          }
        }
      }

      final updated = _currentUser!.copyWith(password: _hashPassword(trimmed));
      await _upsertLocal(updated);
      _currentUser = updated;
      return ServiceResult(
        ok: true,
        message: 'contraseña de respaldo creada correctamente.',
        data: updated,
      );
    } on FirebaseAuthException catch (e) {
      return ServiceResult(
        ok: false,
        message:
            'No pudimos crear la contraseña de respaldo: ${e.message ?? e.code}',
      );
    } catch (e) {
      return ServiceResult(
        ok: false,
        message: 'No pudimos crear la contraseña de respaldo: $e',
      );
    }
  }

  Future<ServiceResult<void>> changePassword({
    String oldPassword = '',
    String currentPassword = '',
    required String newPassword,
    String parentalPin = '',
  }) async {
    return const ServiceResult(
      ok: false,
      message:
          'El cambio de contraseña en la app esta deshabilitado. Usa el correo de restablecimiento.',
    );
  }

  Future<ServiceResult<NebulaUser>> changeEmail({
    required String newEmail,
    String currentPassword = '',
    String password = '',
    String parentalPin = '',
  }) async {
    return const ServiceResult(
      ok: false,
      message: 'El cambio de correo desde la app esta deshabilitado.',
    );
  }

  Future<ServiceResult<void>> sendPasswordResetForIdentifier(
    String identifier,
  ) async {
    if (!_useFirebase) {
      return const ServiceResult(
        ok: false,
        message: 'Password reset requiere Firebase.',
      );
    }

    try {
      final firebaseAuth = _firebaseAuth;
      if (firebaseAuth == null) {
        return const ServiceResult(
          ok: false,
          message: 'Password reset requiere Firebase.',
        );
      }

      final needle = identifier.trim().toLowerCase();
      var emailToReset = needle;
      if (!needle.contains('@')) {
        final users = await _store.readUsers();
        NebulaUser? user;
        for (final u in users) {
          if (u.username.toLowerCase() == needle) {
            user = u;
            break;
          }
        }
        if (user == null) {
          final cloudEmail = await _lookupEmailByUsernameFromCloud(needle);
          if (cloudEmail == null || cloudEmail.trim().isEmpty) {
            return const ServiceResult(
              ok: false,
              message: 'Usuario no encontrado.',
            );
          }
          emailToReset = cloudEmail;
        } else {
          emailToReset = user.email;
        }
      }

      await firebaseAuth.setLanguageCode('es');
      await firebaseAuth.sendPasswordResetEmail(email: emailToReset);
      return const ServiceResult(
        ok: true,
        message: 'Email de reset enviado. Revisa tu bandeja de entrada.',
      );
    } catch (e) {
      return ServiceResult(
        ok: false,
        message: 'Error al enviar email: $e',
      );
    }
  }

  Future<ServiceResult<void>> sendPasswordResetForCurrentUser() async {
    if (_currentUser == null) {
      return const ServiceResult(
        ok: false,
        message: 'No hay usuario actual.',
      );
    }
    return sendPasswordResetForIdentifier(_currentUser!.email);
  }

  bool isValidParentalPinFormat(String value) {
    return RegExp(r'^\d{4,6}$').hasMatch(value.trim());
  }

  bool isValidChildLoginPinFormat(String value) {
    final trimmed = value.trim();
    return trimmed.length >= 6 && trimmed.length <= 32;
  }

  String hashChildLoginPin(String value) {
    return _hashParentalPin(value.trim());
  }

  bool verifyCurrentParentalPin(String pin) {
    if (_currentUser == null) return false;
    return _isValidCurrentParentalPin(pin.trim());
  }

  Future<ServiceResult<NebulaUser>> setParentalPin({
    required String pin,
    String parentalPin = '',
  }) async {
    if (_currentUser == null) {
      return const ServiceResult(
        ok: false,
        message: 'No hay usuario actual.',
      );
    }

    if (!isValidParentalPinFormat(pin)) {
      return const ServiceResult(
        ok: false,
        message: 'PIN debe ser 4-6 digitos.',
      );
    }

    try {
      final updated =
          _currentUser!.copyWith(parentalPinHash: _hashParentalPin(pin));
      await _upsertLocal(updated);
      _currentUser = updated;
      return ServiceResult(
        ok: true,
        message: 'PIN parental establecido.',
        data: updated,
      );
    } catch (e) {
      return ServiceResult(
        ok: false,
        message: 'Error al establecer PIN: $e',
      );
    }
  }

  Future<ServiceResult<NebulaUser>> changeParentalPin({
    String currentPin = '',
    String oldPin = '',
    required String newPin,
    String parentalPin = '',
  }) async {
    if (_currentUser == null) {
      return const ServiceResult(
        ok: false,
        message: 'No hay usuario actual.',
      );
    }

    final pinToCheck = currentPin.isNotEmpty ? currentPin : oldPin;
    final oldHashed = _hashParentalPin(pinToCheck);
    if (_currentUser!.parentalPinHash != oldHashed) {
      return const ServiceResult(
        ok: false,
        message: 'PIN actual incorrecto.',
      );
    }

    return setParentalPin(pin: newPin);
  }

  Future<ServiceResult<NebulaUser>> disableParentalPin({
    String currentPin = '',
    String parentalPin = '',
  }) async {
    if (_currentUser == null) {
      return const ServiceResult(
        ok: false,
        message: 'No hay usuario actual.',
      );
    }

    final pinToCheck = currentPin.isNotEmpty ? currentPin : parentalPin;
    final hashed = _hashParentalPin(pinToCheck);
    if (_currentUser!.parentalPinHash != hashed) {
      return const ServiceResult(
        ok: false,
        message: 'PIN incorrecto.',
      );
    }

    try {
      final updated = _currentUser!.copyWith(parentalPinHash: '');
      await _upsertLocal(updated);
      _currentUser = updated;
      return ServiceResult(
        ok: true,
        message: 'PIN parental desactivado.',
        data: updated,
      );
    } catch (e) {
      return ServiceResult(
        ok: false,
        message: 'Error al desactivar PIN: $e',
      );
    }
  }

  Future<ServiceResult<void>> sendParentalPinRecoveryEmail() async {
    if (_currentUser == null) {
      return const ServiceResult(
        ok: false,
        message: 'No hay usuario actual.',
      );
    }
    if (!_useFirebase) {
      return const ServiceResult(
        ok: false,
        message: 'Recuperar PIN por correo requiere Firebase.',
      );
    }

    try {
      final firebaseAuth = _firebaseAuth;
      if (firebaseAuth == null) {
        return const ServiceResult(
          ok: false,
          message: 'Recuperar PIN por correo requiere Firebase.',
        );
      }
      await firebaseAuth.setLanguageCode('es');
      await firebaseAuth.sendPasswordResetEmail(email: _currentUser!.email);
      return const ServiceResult(
        ok: true,
        message:
            'Te enviamos un correo para recuperar el acceso de tu cuenta y poder restablecer el PIN.',
      );
    } catch (e) {
      return ServiceResult(
        ok: false,
        message: 'No pudimos enviar el correo de recuperacion del PIN: $e',
      );
    }
  }

  Future<ServiceResult<NebulaUser>> recoverParentalPinWithPassword({
    required String accountPassword,
    required String newPin,
  }) async {
    if (_currentUser == null) {
      return const ServiceResult(
        ok: false,
        message: 'No hay usuario actual.',
      );
    }

    final trimmedNewPin = newPin.trim();
    if (!isValidParentalPinFormat(trimmedNewPin)) {
      return const ServiceResult(
        ok: false,
        message: 'El PIN debe tener entre 4 y 6 digitos.',
      );
    }

    final typedPassword = accountPassword.trim();
    if (typedPassword.isEmpty) {
      return const ServiceResult(
        ok: false,
        message: 'Escribe la contraseña de tu cuenta para restablecer el PIN.',
      );
    }

    if (_useFirebase) {
      final firebaseUser = _firebaseAuth?.currentUser;
      if (firebaseUser == null) {
        return const ServiceResult(
          ok: false,
          message: 'No hay sesión valida en Firebase para verificar la cuenta.',
        );
      }
      try {
        final credential = EmailAuthProvider.credential(
          email: _currentUser!.email,
          password: typedPassword,
        );
        await firebaseUser.reauthenticateWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' ||
            e.code == 'invalid-credential' ||
            e.code == 'user-mismatch' ||
            e.code == 'invalid-email') {
          return const ServiceResult(
            ok: false,
            message: 'La contraseña de la cuenta es incorrecta.',
          );
        }
        return ServiceResult(
          ok: false,
          message:
              'No pudimos verificar tu cuenta para restablecer el PIN: ${e.message ?? e.code}',
        );
      }
    } else if (!_passwordMatches(
      stored: _currentUser!.password,
      input: typedPassword,
    )) {
      return const ServiceResult(
        ok: false,
        message: 'La contraseña de la cuenta es incorrecta.',
      );
    }

    try {
      final updated = _currentUser!.copyWith(
        parentalPinHash: _hashParentalPin(trimmedNewPin),
        password: _hashPassword(typedPassword),
      );
      await _upsertLocal(updated);
      _currentUser = updated;
      return ServiceResult(
        ok: true,
        message: 'PIN restablecido correctamente.',
        data: updated,
      );
    } catch (e) {
      return ServiceResult(
        ok: false,
        message: 'No pudimos restablecer el PIN: $e',
      );
    }
  }

  Future<ServiceResult<NebulaUser>> recoverParentalPinWithGoogle({
    required String newPin,
  }) async {
    if (_currentUser == null) {
      return const ServiceResult(
        ok: false,
        message: 'No hay usuario actual.',
      );
    }
    if (!_useFirebase) {
      return const ServiceResult(
        ok: false,
        message: 'Este metodo requiere Firebase activo.',
      );
    }

    final trimmedNewPin = newPin.trim();
    if (!isValidParentalPinFormat(trimmedNewPin)) {
      return const ServiceResult(
        ok: false,
        message: 'El PIN debe tener entre 4 y 6 digitos.',
      );
    }

    try {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      try {
        await _googleSignIn.disconnect();
      } catch (_) {}

      final account = await _googleSignIn.signIn();
      if (account == null) {
        return const ServiceResult(
          ok: false,
          message: 'Recuperacion cancelada.',
        );
      }

      final selectedEmail = account.email.trim().toLowerCase();
      final currentEmail = _currentUser!.email.trim().toLowerCase();
      if (selectedEmail != currentEmail) {
        return ServiceResult(
          ok: false,
          message:
              'Debes elegir la misma cuenta de Google ($currentEmail) para recuperar el PIN.',
        );
      }

      final auth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      final firebaseUser = _firebaseAuth?.currentUser;
      if (firebaseUser == null) {
        return const ServiceResult(
          ok: false,
          message: 'No hay sesión valida en Firebase para verificar Google.',
        );
      }
      await firebaseUser.reauthenticateWithCredential(credential);

      final updated = _currentUser!
          .copyWith(parentalPinHash: _hashParentalPin(trimmedNewPin));
      await _upsertLocal(updated);
      _currentUser = updated;
      return ServiceResult(
        ok: true,
        message: 'PIN restablecido correctamente con Google.',
        data: updated,
      );
    } on FirebaseAuthException catch (e) {
      return ServiceResult(
        ok: false,
        message:
            'No pudimos verificar tu cuenta de Google para restablecer el PIN: ${e.message ?? e.code}',
      );
    } catch (e) {
      return ServiceResult(
        ok: false,
        message: 'No pudimos restablecer el PIN con Google: $e',
      );
    }
  }

  Future<ServiceResult<void>> deleteCurrentAccount({
    String parentalPin = '',
    String password = '',
  }) async {
    final deletingUser = _currentUser;
    if (deletingUser == null) {
      return const ServiceResult(
        ok: false,
        message: 'No hay usuario actual.',
      );
    }

    if (deletingUser.password.trim().isEmpty) {
      return const ServiceResult(
        ok: false,
        message:
            'Primero crea una contraseña local desde tu perfil para poder borrar la cuenta.',
      );
    }

    if (deletingUser.password.trim().isNotEmpty && password.trim().isEmpty) {
      return const ServiceResult(
        ok: false,
        message: 'Escribe tu contraseña actual para borrar la cuenta.',
      );
    }
    if (deletingUser.password.trim().isNotEmpty &&
        !_passwordMatches(
          stored: deletingUser.password,
          input: password.trim(),
        )) {
      return const ServiceResult(
        ok: false,
        message: 'contraseña incorrecta.',
      );
    }

    try {
      final userId = deletingUser.id;
      if (_useFirebase) {
        await _firebaseAuth!.currentUser?.delete();
      }

      final users = await _store.readUsers();
      final filtered = users.where((u) => u.id != deletingUser.id).toList();
      await _store.writeUsers(filtered);
      await _store.clearSession();
      await _deleteCloudUserBestEffort(userId);
      final now = DateTime.now().millisecondsSinceEpoch;
      await _recordDeletedAccountBestEffort(
        DeletedAccountRecord(
          id: 'del_${userId}_$now',
          userId: userId,
          email: deletingUser.email,
          username: deletingUser.username,
          role: deletingUser.role,
          deletedAtMillis: now,
          reason: 'self_delete',
          hadChildProfile: deletingUser.childProfile != null,
          sessionCount: deletingUser.gameSessions.length,
        ),
      );

      _currentUser = null;
      _activePortalRole = PortalRole.caregiver;
      return const ServiceResult(
        ok: true,
        message: 'Cuenta eliminada.',
      );
    } catch (e) {
      return ServiceResult(
        ok: false,
        message: 'Error al eliminar cuenta: $e',
      );
    }
  }

  Future<ServiceResult<void>> linkGoogleToExistingAccount({
    required String currentPassword,
  }) async {
    if (!_useFirebase) {
      return const ServiceResult(
        ok: false,
        message: 'Linkage requiere Firebase.',
      );
    }

    try {
      final googleUser = _pendingGoogleUserForLink;
      final localUser = _pendingLocalUserForLink;
      final pendingAccessToken = _pendingGoogleAccessTokenForLink;
      final pendingIdToken = _pendingGoogleIdTokenForLink;
      if (googleUser == null || localUser == null) {
        return const ServiceResult(
          ok: false,
          message:
              'No hay una vinculacion pendiente. Intenta de nuevo con Google.',
        );
      }
      if (pendingAccessToken == null || pendingIdToken == null) {
        _clearPendingGoogleLink();
        return const ServiceResult(
          ok: false,
          message: 'No pudimos recuperar la sesión de Google para vincular.',
        );
      }

      final typed = currentPassword.trim();
      if (typed.isEmpty ||
          !_passwordMatches(stored: localUser.password, input: typed)) {
        return const ServiceResult(
          ok: false,
          message: 'La contraseña actual no es correcta.',
        );
      }

      final googleCredential = GoogleAuthProvider.credential(
        accessToken: pendingAccessToken,
        idToken: pendingIdToken,
      );
      final googleSignInResult =
          await _firebaseAuth!.signInWithCredential(googleCredential);
      final firebaseGoogleUser = googleSignInResult.user;
      if (firebaseGoogleUser == null) {
        _clearPendingGoogleLink();
        return const ServiceResult(
          ok: false,
          message: 'No pudimos recuperar la cuenta Google para vincular.',
        );
      }

      final emailCredential = EmailAuthProvider.credential(
        email: localUser.email,
        password: typed,
      );
      try {
        await firebaseGoogleUser.linkWithCredential(emailCredential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'provider-already-linked') {
          await firebaseGoogleUser.updatePassword(typed);
        } else {
          rethrow;
        }
      }

      final users = await _store.readUsers();
      final normalizedPassword = _isSha256Hex(localUser.password)
          ? localUser.password
          : _hashPassword(typed);

      final merged = NebulaUser(
        id: firebaseGoogleUser.uid,
        name: localUser.name,
        username: localUser.username,
        email: localUser.email.toLowerCase(),
        password: normalizedPassword,
        parentalPinHash: localUser.parentalPinHash,
        stars: localUser.stars,
        avatarIndex: localUser.avatarIndex,
        selectedNarratorId: localUser.selectedNarratorId,
        soundEffectsEnabled: localUser.soundEffectsEnabled,
        accentHue: localUser.accentHue,
        accentIntensity: localUser.accentIntensity,
        customImages: localUser.customImages,
        role: localUser.role,
        childProfile: localUser.childProfile,
        gameSessions: localUser.gameSessions,
        parentalControl: localUser.parentalControl,
      );

      final nextUsers = users
          .where(
            (u) => u.id != localUser.id && u.id != firebaseGoogleUser.uid,
          )
          .toList();
      nextUsers.add(merged);

      await _store.writeUsers(nextUsers);
      await _persistSessionState(
        merged,
        requestedRole: merged.role == UserRole.admin
            ? PortalRole.admin
            : PortalRole.caregiver,
      );
      _currentUser = merged;
      await _syncCloudUserBestEffort(merged);
      _clearPendingGoogleLink();

      return const ServiceResult(
        ok: true,
        message: 'Cuenta vinculada. Ya puedes entrar con Google o contraseña.',
      );
    } catch (e) {
      return ServiceResult(
        ok: false,
        message: 'Error al vincular Google: $e',
      );
    }
  }

  Future<bool?> _isUsernameTakenInCloud(
    String normalizedUsername, {
    String excludeUserId = '',
  }) async {
    if (!_useFirebase) return false;
    if (normalizedUsername.trim().isEmpty) return false;
    try {
      final query = await _firestore!
          .collection('users')
          .where('usernameLower',
              isEqualTo: normalizedUsername.trim().toLowerCase())
          .limit(5)
          .get();
      for (final doc in query.docs) {
        final data = doc.data();
        final idFromField = (data['id'] as String?)?.trim() ?? '';
        final docId = doc.id.trim();
        final matchesExcluded = excludeUserId.isNotEmpty &&
            (docId == excludeUserId || idFromField == excludeUserId);
        if (!matchesExcluded) return true;
      }
      return false;
    } catch (_) {
      return null;
    }
  }

  Future<bool?> _isChildLoginUsernameTakenInCloud(
    String normalizedUsername, {
    String excludeCaregiverUserId = '',
  }) async {
    if (!_useFirebase) return false;
    if (normalizedUsername.trim().isEmpty) return false;
    try {
      final query = await _firestore!
          .collection('users')
          .where('childProfile.loginUsernameLower',
              isEqualTo: normalizedUsername.trim().toLowerCase())
          .limit(5)
          .get();
      for (final doc in query.docs) {
        final data = doc.data();
        final idFromField = (data['id'] as String?)?.trim() ?? '';
        final docId = doc.id.trim();
        final matchesExcluded = excludeCaregiverUserId.isNotEmpty &&
            (docId == excludeCaregiverUserId ||
                idFromField == excludeCaregiverUserId);
        if (!matchesExcluded) return true;
      }
      return false;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _lookupEmailByUsernameFromCloud(String username) async {
    if (!_useFirebase) return null;
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    try {
      final query = await _firestore!
          .collection('users')
          .where('usernameLower', isEqualTo: normalized)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      final data = query.docs.first.data();
      final emailLower = (data['emailLower'] as String?)?.trim();
      final email = (data['email'] as String?)?.trim();
      final resolved = (emailLower?.isNotEmpty == true ? emailLower : email)
              ?.toLowerCase() ??
          '';
      if (resolved.isEmpty) return null;
      return resolved;
    } catch (_) {
      return null;
    }
  }

  Future<ServiceResult<NebulaUser>> _loginUsingFirebaseWithoutLocalUser({
    required String email,
    required String password,
  }) async {
    if (!_useFirebase) {
      return const ServiceResult(
        ok: false,
        message: 'Cuenta no encontrada localmente.',
      );
    }

    try {
      final credential = await _firebaseAuth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        return const ServiceResult(
          ok: false,
          message: 'No pudimos recuperar tu cuenta en Firebase.',
        );
      }
      final verificationGate = await _enforceVerifiedEmailForPasswordUser(
        firebaseUser,
        fallbackEmail: email,
      );
      if (!verificationGate.ok) {
        return ServiceResult(
          ok: false,
          message: verificationGate.message,
        );
      }

      final cloudDoc =
          await _firestore!.collection('users').doc(firebaseUser.uid).get();
      final cloud = cloudDoc.data();
      final preferredUsername = (cloud?['username'] as String?)?.trim() ?? '';
      final resolvedUsername = await _resolveAvailableUsername(
        email: firebaseUser.email ?? email,
        preferredUsername: preferredUsername,
        excludeUserId: firebaseUser.uid,
      );
      final restored = NebulaUser(
        id: firebaseUser.uid,
        name: (cloud?['name'] as String?)?.trim().isNotEmpty == true
            ? (cloud!['name'] as String)
            : (firebaseUser.displayName ?? 'Explorador'),
        username: resolvedUsername,
        email: ((cloud?['email'] as String?) ?? email).trim().toLowerCase(),
        password: _hashPassword(password),
        parentalPinHash: (cloud?['parentalPinHash'] as String?) ?? '',
        stars: (cloud?['stars'] as num?)?.toInt() ?? 0,
        avatarIndex: (cloud?['avatarIndex'] as num?)?.toInt() ?? 0,
        selectedNarratorId:
            (cloud?['selectedNarratorId'] as String?) ?? 'narrator_1',
        soundEffectsEnabled: (cloud?['soundEffectsEnabled'] as bool?) ?? true,
        accentHue: (cloud?['accentHue'] as num?)?.toDouble() ?? 190,
        accentIntensity:
            (cloud?['accentIntensity'] as num?)?.toDouble() ?? 0.55,
        customImages: Map<String, String>.from(
          cloud?['customImages'] as Map? ?? const {},
        ),
        role: (cloud?['role'] as String?) ?? UserRole.caregiver,
        childProfile: cloud?['childProfile'] is Map
            ? ChildProfile.fromJson(
                Map<String, dynamic>.from(cloud!['childProfile'] as Map),
              )
            : null,
        gameSessions: (cloud?['gameSessions'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (item) => GameSessionRecord.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(),
        parentalControl: cloud?['parentalControl'] is Map
            ? ParentalControl.fromJson(
                Map<String, dynamic>.from(cloud!['parentalControl'] as Map),
              )
            : const ParentalControl(),
      );

      await _upsertLocal(restored);
      await _persistSessionState(
        restored,
        requestedRole: restored.role == UserRole.admin
            ? PortalRole.admin
            : PortalRole.caregiver,
      );
      _currentUser = restored;
      return ServiceResult(
        ok: true,
        message: 'Listo, ya estas dentro.',
        data: restored,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'wrong-password') {
        return const ServiceResult(
          ok: false,
          message: 'No pudimos entrar. Revisa tus datos e intenta otra vez.',
        );
      }
      return ServiceResult(
        ok: false,
        message: 'Error al iniciar sesión con Firebase: ${e.message ?? e.code}',
      );
    } catch (e) {
      return ServiceResult(
        ok: false,
        message: 'Error al recuperar tu cuenta de Firebase: $e',
      );
    }
  }

  Future<ServiceResult<NebulaUser>> _ensureFirebaseUserForPasswordLogin({
    required NebulaUser localUser,
    required String plainPassword,
    bool createIfMissing = true,
  }) async {
    if (!_useFirebase) {
      return ServiceResult(
        ok: true,
        message: 'Firebase no activo.',
        data: localUser,
      );
    }

    try {
      UserCredential credential;
      try {
        credential = await _firebaseAuth!.signInWithEmailAndPassword(
          email: localUser.email,
          password: plainPassword,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          if (!createIfMissing) {
            return const ServiceResult(
              ok: false,
              message: 'Cuenta no encontrada en Firebase.',
            );
          }
          credential = await _firebaseAuth!.createUserWithEmailAndPassword(
            email: localUser.email,
            password: plainPassword,
          );
        } else if (e.code == 'wrong-password' ||
            e.code == 'invalid-credential') {
          return const ServiceResult(
            ok: false,
            message:
                'Tu contraseña no coincide con Firebase. Prueba recuperar contraseña.',
          );
        } else {
          return ServiceResult(
            ok: false,
            message:
                'No pudimos validar tu cuenta en Firebase: ${e.message ?? e.code}',
          );
        }
      }

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        return const ServiceResult(
          ok: false,
          message: 'No pudimos recuperar tu sesión en Firebase.',
        );
      }
      final verificationGate = await _enforceVerifiedEmailForPasswordUser(
        firebaseUser,
        fallbackEmail: localUser.email,
      );
      if (!verificationGate.ok) {
        return ServiceResult(
          ok: false,
          message: verificationGate.message,
        );
      }

      var syncedUser =
          localUser.copyWith(password: _hashPassword(plainPassword));
      if (localUser.id != firebaseUser.uid) {
        syncedUser = _copyUserWithId(syncedUser, firebaseUser.uid);
        final users = await _store.readUsers();
        final nextUsers = users
            .where(
              (u) => u.id != localUser.id && u.id != firebaseUser.uid,
            )
            .toList();
        nextUsers.add(syncedUser);
        await _store.writeUsers(nextUsers);
      } else {
        await _upsertLocal(syncedUser);
      }

      await _syncCloudUserBestEffort(syncedUser);
      return ServiceResult(
        ok: true,
        message: 'Firebase validado.',
        data: syncedUser,
      );
    } on FirebaseAuthException catch (e) {
      return ServiceResult(
        ok: false,
        message: 'Error de Firebase: ${e.message ?? e.code}',
      );
    } catch (e) {
      return ServiceResult(
        ok: false,
        message: 'Error al sincronizar login con Firebase: $e',
      );
    }
  }

  Future<ServiceResult<void>> _enforceVerifiedEmailForPasswordUser(
    User firebaseUser, {
    required String fallbackEmail,
  }) async {
    if (!_useFirebase) {
      return const ServiceResult(
        ok: true,
        message: 'Firebase no activo.',
      );
    }

    try {
      await firebaseUser.reload();
    } catch (_) {}
    final refreshed = _firebaseAuth?.currentUser ?? firebaseUser;
    final usesPasswordProvider = refreshed.providerData.any(
      (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
    );
    final usesGoogleProvider = refreshed.providerData.any(
      (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID,
    );
    if (!usesPasswordProvider || usesGoogleProvider) {
      return const ServiceResult(
        ok: true,
        message: 'No requiere verificacion por correo.',
      );
    }

    if (refreshed.emailVerified) {
      return const ServiceResult(
        ok: true,
        message: 'Correo verificado.',
      );
    }

    final createdAt = refreshed.metadata.creationTime;
    if (createdAt != null) {
      final age = DateTime.now().difference(createdAt);
      const ttl = Duration(hours: 1);
      if (age >= ttl) {
        await _deleteUnverifiedFirebaseAccount(
          refreshed,
          fallbackEmail: fallbackEmail,
        );
        return const ServiceResult(
          ok: false,
          message:
              'No verificaste tu correo en 1 hora. La cuenta se elimino por seguridad. Registrate otra vez.',
        );
      }

      final left = ttl - age;
      final minutesLeft =
          (left.inMinutes + ((left.inSeconds % 60 == 0) ? 0 : 1)).clamp(1, 60);
      try {
        await _firebaseAuth?.setLanguageCode('es');
        await refreshed.sendEmailVerification();
      } catch (_) {}
      try {
        await _firebaseAuth?.signOut();
      } catch (_) {}
      _currentUser = null;
      _activePortalRole = PortalRole.caregiver;
      await _store.clearSession();
      return ServiceResult(
        ok: false,
        message:
            'Tu correo no esta verificado. Revisa tu email y vuelve a entrar. Si no verificas en $minutesLeft min, la cuenta se elimina.',
      );
    }

    try {
      await _firebaseAuth?.setLanguageCode('es');
      await refreshed.sendEmailVerification();
    } catch (_) {}
    try {
      await _firebaseAuth?.signOut();
    } catch (_) {}
    _currentUser = null;
    _activePortalRole = PortalRole.caregiver;
    await _store.clearSession();
    return const ServiceResult(
      ok: false,
      message:
          'Tu correo no esta verificado. Revisa tu email para activar la cuenta.',
    );
  }

  Future<void> _deleteUnverifiedFirebaseAccount(
    User firebaseUser, {
    required String fallbackEmail,
  }) async {
    final uid = firebaseUser.uid;
    final emailToClean =
        (firebaseUser.email ?? fallbackEmail).trim().toLowerCase();
    NebulaUser? removedUser;

    try {
      await _deleteCloudUserBestEffort(uid);
    } catch (_) {}

    try {
      final users = await _store.readUsers();
      removedUser = users.firstWhere(
        (u) => u.id == uid || u.email.toLowerCase() == emailToClean,
        orElse: () => const NebulaUser(
          id: '',
          name: '',
          username: '',
          email: '',
          password: '',
          parentalPinHash: '',
          stars: 0,
          avatarIndex: 0,
          selectedNarratorId: 'narrator_1',
          soundEffectsEnabled: true,
          accentHue: 190,
          accentIntensity: 0.55,
          customImages: <String, String>{},
        ),
      );
      final filtered = users
          .where(
            (u) => u.id != uid && u.email.toLowerCase() != emailToClean,
          )
          .toList();
      await _store.writeUsers(filtered);
    } catch (_) {}

    try {
      await firebaseUser.delete();
    } catch (_) {}
    try {
      await _firebaseAuth?.signOut();
    } catch (_) {}
    _currentUser = null;
    _activePortalRole = PortalRole.caregiver;
    try {
      await _store.clearSession();
    } catch (_) {}
    final now = DateTime.now().millisecondsSinceEpoch;
    await _recordDeletedAccountBestEffort(
      DeletedAccountRecord(
        id: 'del_${uid}_$now',
        userId: uid,
        email: emailToClean,
        username: removedUser?.username ?? '',
        role: (removedUser?.role.trim().isNotEmpty ?? false)
            ? removedUser!.role
            : UserRole.caregiver,
        deletedAtMillis: now,
        reason: 'unverified_email_ttl',
        hadChildProfile: removedUser?.childProfile != null,
        sessionCount: removedUser?.gameSessions.length ?? 0,
      ),
    );
  }

  List<_DashboardUserSnapshot> _buildDashboardUsersFromLocal(
    List<NebulaUser> users,
  ) {
    return users
        .map(
          (user) => _DashboardUserSnapshot(
            role: user.role,
            hasChildProfile: user.childProfile != null,
            childProfileActive: user.childProfile?.active ?? false,
            sessions: user.gameSessions
                .map(
                  (session) => _DashboardSessionSnapshot(
                    gameKey: session.gameKey,
                    startedAtMillis: session.startedAtMillis,
                    durationSeconds: session.durationSeconds,
                    correctAnswers: session.correctAnswers,
                    totalAttempts: session.totalAttempts,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  List<_DashboardUserSnapshot> _buildDashboardUsersFromCloud(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final users = <_DashboardUserSnapshot>[];
    for (final doc in docs) {
      final data = doc.data();
      final role = (data['role'] as String?) ?? UserRole.caregiver;
      final childRaw = data['childProfile'];
      final hasChildProfile = childRaw is Map;
      final childActive =
          childRaw is Map ? ((childRaw['active'] as bool?) ?? false) : false;

      final sessions = <_DashboardSessionSnapshot>[];
      final sessionsRaw = data['gameSessions'];
      if (sessionsRaw is List) {
        for (final raw in sessionsRaw.whereType<Map>()) {
          final json = Map<String, dynamic>.from(raw);
          sessions.add(
            _DashboardSessionSnapshot(
              gameKey: (json['gameKey'] as String?) ?? '',
              startedAtMillis: (json['startedAtMillis'] as num?)?.toInt() ?? 0,
              durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
              correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
              totalAttempts: (json['totalAttempts'] as num?)?.toInt() ?? 0,
            ),
          );
        }
      }

      users.add(
        _DashboardUserSnapshot(
          role: role,
          hasChildProfile: hasChildProfile,
          childProfileActive: childActive,
          sessions: sessions,
        ),
      );
    }
    return users;
  }

  AdminDashboardStats _buildDashboardStats({
    required List<_DashboardUserSnapshot> users,
    required List<DeletedAccountRecord> deletedAccounts,
    required String source,
  }) {
    final now = DateTime.now();
    final from7Days =
        now.subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    final from30Days =
        now.subtract(const Duration(days: 30)).millisecondsSinceEpoch;

    var totalUsers = 0;
    var caregiverUsers = 0;
    var adminUsers = 0;
    var usersWithChildProfile = 0;
    var activeChildProfiles = 0;
    var totalGameSessions = 0;
    var sessionsLast7Days = 0;
    var totalUsageSeconds = 0;
    var usageSecondsLast7Days = 0;
    var totalCorrectAnswers = 0;
    var totalAttempts = 0;
    final sessionsByGame = <String, int>{};

    for (final user in users) {
      totalUsers += 1;
      final role = user.role.trim().toLowerCase();
      if (role == UserRole.admin) {
        adminUsers += 1;
      } else {
        caregiverUsers += 1;
      }

      if (user.hasChildProfile) {
        usersWithChildProfile += 1;
      }
      if (user.childProfileActive) {
        activeChildProfiles += 1;
      }

      for (final session in user.sessions) {
        totalGameSessions += 1;
        final duration = session.durationSeconds.clamp(0, 24 * 3600);
        totalUsageSeconds += duration;
        if (session.startedAtMillis >= from7Days) {
          sessionsLast7Days += 1;
          usageSecondsLast7Days += duration;
        }
        final attempts = session.totalAttempts.clamp(0, 10000);
        if (attempts > 0) {
          totalAttempts += attempts;
          totalCorrectAnswers += session.correctAnswers.clamp(0, attempts);
        }
        final gameKey = session.gameKey.trim().toLowerCase();
        if (gameKey.isNotEmpty) {
          sessionsByGame[gameKey] = (sessionsByGame[gameKey] ?? 0) + 1;
        }
      }
    }

    final deletedLast30Days = deletedAccounts
        .where((item) => item.deletedAtMillis >= from30Days)
        .length;
    final avgAccuracy = totalAttempts <= 0
        ? 0.0
        : ((totalCorrectAnswers * 100.0) / totalAttempts);

    return AdminDashboardStats(
      totalUsers: totalUsers,
      caregiverUsers: caregiverUsers,
      adminUsers: adminUsers,
      usersWithChildProfile: usersWithChildProfile,
      activeChildProfiles: activeChildProfiles,
      totalGameSessions: totalGameSessions,
      sessionsLast7Days: sessionsLast7Days,
      totalUsageMinutes: totalUsageSeconds ~/ 60,
      usageMinutesLast7Days: usageSecondsLast7Days ~/ 60,
      averageAccuracyPercent: avgAccuracy,
      deletedAccounts: deletedAccounts.length,
      deletedAccountsLast30Days: deletedLast30Days,
      sessionsByGame: sessionsByGame,
      refreshedAtMillis: now.millisecondsSinceEpoch,
      source: source,
    );
  }

  Future<List<DeletedAccountRecord>> _readLocalDeletedAccountRecords() async {
    final raw = await _store.readDeletedAccounts();
    final records = <DeletedAccountRecord>[];
    for (final json in raw) {
      try {
        records.add(DeletedAccountRecord.fromJson(json));
      } catch (_) {}
    }
    records.sort((a, b) => b.deletedAtMillis.compareTo(a.deletedAtMillis));
    return records;
  }

  Future<void> _writeLocalDeletedAccountRecords(
    List<DeletedAccountRecord> records,
  ) async {
    final normalized = [...records]
      ..sort((a, b) => b.deletedAtMillis.compareTo(a.deletedAtMillis));
    if (normalized.length > 1000) {
      normalized.removeRange(1000, normalized.length);
    }
    await _store.writeDeletedAccounts(
      normalized.map((item) => item.toJson()).toList(),
    );
  }

  List<DeletedAccountRecord> _mergeDeletedRecords(
    List<DeletedAccountRecord> first,
    List<DeletedAccountRecord> second,
  ) {
    final mergedById = <String, DeletedAccountRecord>{};
    for (final item in [...first, ...second]) {
      final key = item.id.trim().isEmpty
          ? '${item.userId}_${item.deletedAtMillis}'
          : item.id;
      final existing = mergedById[key];
      if (existing == null || item.deletedAtMillis > existing.deletedAtMillis) {
        mergedById[key] = item;
      }
    }
    final merged = mergedById.values.toList()
      ..sort((a, b) => b.deletedAtMillis.compareTo(a.deletedAtMillis));
    return merged;
  }

  Future<void> _recordDeletedAccountBestEffort(
    DeletedAccountRecord record,
  ) async {
    try {
      final current = await _readLocalDeletedAccountRecords();
      final merged = _mergeDeletedRecords(current, [record]);
      await _writeLocalDeletedAccountRecords(merged);
    } catch (_) {}
    if (!_useFirebase) return;
    try {
      await _firestore!
          .collection('admin_deleted_accounts')
          .doc(record.id)
          .set(record.toJson(), SetOptions(merge: true));
    } catch (_) {}
  }

  NebulaUser _copyUserWithId(NebulaUser user, String id) {
    return NebulaUser(
      id: id,
      name: user.name,
      username: user.username,
      email: user.email,
      password: user.password,
      parentalPinHash: user.parentalPinHash,
      stars: user.stars,
      avatarIndex: user.avatarIndex,
      selectedNarratorId: user.selectedNarratorId,
      soundEffectsEnabled: user.soundEffectsEnabled,
      accentHue: user.accentHue,
      accentIntensity: user.accentIntensity,
      customImages: user.customImages,
      role: user.role,
      childProfile: user.childProfile,
      gameSessions: user.gameSessions,
      parentalControl: user.parentalControl,
    );
  }

  Map<String, dynamic> _toCloudUserData(NebulaUser user) {
    return {
      'id': user.id,
      'name': user.name,
      'username': user.username,
      'usernameLower': user.username.toLowerCase(),
      'email': user.email,
      'emailLower': user.email.toLowerCase(),
      'hasLocalPassword': user.password.trim().isNotEmpty,
      'parentalPinHash': user.parentalPinHash,
      'stars': user.stars,
      'avatarIndex': user.avatarIndex,
      'selectedNarratorId': user.selectedNarratorId,
      'soundEffectsEnabled': user.soundEffectsEnabled,
      'accentHue': user.accentHue,
      'accentIntensity': user.accentIntensity,
      'customImages': user.customImages,
      'role': user.role,
      'childProfile': user.childProfile?.toJson(),
      'gameSessions': user.gameSessions.map((item) => item.toJson()).toList(),
      'parentalControl': user.parentalControl.toJson(),
    };
  }

  Future<void> _writeCloudUser(NebulaUser user) async {
    if (!_useFirebase) return;
    await _firestore!.collection('users').doc(user.id).set(
          _toCloudUserData(user),
          SetOptions(merge: true),
        );
  }

  Future<void> _syncCloudUserBestEffort(NebulaUser user) async {
    if (!_useFirebase) return;
    try {
      await _writeCloudUser(user);
    } catch (_) {}
  }

  Future<void> _deleteCloudUserBestEffort(String userId) async {
    if (!_useFirebase) return;
    try {
      await _firestore!.collection('users').doc(userId).delete();
    } catch (_) {}
  }

  Future<void> _upsertLocal(NebulaUser user) async {
    final users = await _store.readUsers();
    final updated = users.map((u) => u.id == user.id ? user : u).toList();
    if (!users.any((u) => u.id == user.id)) {
      updated.add(user);
    }
    await _store.writeUsers(updated);
    await _syncCloudUserBestEffort(user);
  }

  PortalRole _resolvePortalRoleForUser({
    required NebulaUser user,
    PortalRole? requestedRole,
  }) {
    if (user.role == UserRole.admin) {
      return PortalRole.admin;
    }
    if (requestedRole == PortalRole.child && user.childProfile != null) {
      return PortalRole.child;
    }
    if (requestedRole == PortalRole.admin) {
      return PortalRole.admin;
    }
    return PortalRole.caregiver;
  }

  Future<void> _persistSessionState(
    NebulaUser user, {
    PortalRole? requestedRole,
  }) async {
    final resolved = _resolvePortalRoleForUser(
      user: user,
      requestedRole: requestedRole,
    );
    await _store.saveSessionUserId(user.id);
    await _store.saveSessionPortalRole(resolved.storageValue);
    _activePortalRole = resolved;
  }

  bool isValidEmailFormat(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  String _hashParentalPin(String value) {
    return sha256.convert(utf8.encode(value.trim())).toString();
  }

  String _hashPassword(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }

  bool _isSha256Hex(String value) {
    return RegExp(r'^[a-f0-9]{64}$').hasMatch(value);
  }

  bool _passwordMatches({
    required String stored,
    required String input,
  }) {
    if (stored.isEmpty) return input.isEmpty;
    if (_isSha256Hex(stored)) {
      return _hashPassword(input) == stored;
    }
    return stored == input;
  }

  bool _requiresParentalPin() {
    return _currentUser?.parentalPinHash.trim().isNotEmpty ?? false;
  }

  bool _isValidCurrentParentalPin(String pin) {
    if (!_requiresParentalPin()) return true;
    return _currentUser!.parentalPinHash == _hashParentalPin(pin);
  }

  void _clearPendingGoogleLink() {
    _pendingGoogleUserForLink = null;
    _pendingLocalUserForLink = null;
    _pendingGoogleAccessTokenForLink = null;
    _pendingGoogleIdTokenForLink = null;
  }

  void _clearPendingGoogleConfirmation() {
    _pendingGoogleAccessTokenForConfirm = null;
    _pendingGoogleIdTokenForConfirm = null;
    _pendingGoogleEmailForConfirm = null;
    _pendingGoogleNameForConfirm = null;
  }
}
