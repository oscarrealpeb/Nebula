import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';

import '../models/nebula_user.dart';
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
  NebulaUser? _pendingGoogleUserForLink;
  NebulaUser? _pendingLocalUserForLink;
  String? _pendingGoogleAccessTokenForLink;
  String? _pendingGoogleIdTokenForLink;

  bool get _useFirebase => _firebaseAuth != null && _firestore != null;

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
      return null;
    }

    final users = await _store.readUsers();
    for (final user in users) {
      if (user.id == sessionUserId) {
        _currentUser = user;
        return user;
      }
    }
    _currentUser = null;
    return null;
  }

  Future<bool> checkUsernameAvailable(String username) async {
    final trimmed = username.trim();
    if (trimmed.length < 3 || trimmed.length > 18) return false;
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(trimmed.toLowerCase())) return false;

    final users = await _store.readUsers();
    return !users.any(
      (user) => user.username.toLowerCase() == trimmed.toLowerCase(),
    );
  }

  String generateSuggestedUsername(String email) {
    final normalized = email.trim().toLowerCase();
    final seed = normalized.contains('@')
        ? normalized.split('@').first
        : normalized;
    return _sanitizeUsernameSeed(seed);
  }

  String _sanitizeUsernameSeed(String seed) {
    var cleaned = seed.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    if (cleaned.length > 18) cleaned = cleaned.substring(0, 18);
    if (cleaned.length < 3) cleaned = '${cleaned}_user';
    return cleaned;
  }

  Future<ServiceResult<NebulaUser>> updateUsernameForCurrentUser(
    String newUsername,
  ) async {
    final trimmed = newUsername.trim();
    final available = await checkUsernameAvailable(trimmed);
    if (!available) {
      return const ServiceResult(
        ok: false,
        message: 'Ese apodo ya lo usa alguien mas. Prueba otro.',
      );
    }

    if (_currentUser == null) {
      return const ServiceResult(
        ok: false,
        message: 'No hay usuario actual.',
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
            'Completa todos los campos. La contrasena debe tener al menos 6 caracteres.',
      );
    }

    final users = await _store.readUsers();
    final usernameTaken = users.any(
      (user) => user.username.toLowerCase() == trimmedUsername.toLowerCase(),
    );
    if (usernameTaken) {
      return const ServiceResult(
        ok: false,
        message: 'Ese apodo ya lo usa alguien mas. Prueba otro.',
      );
    }

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
              'Ese correo ya existe con Google. Entra con Google y luego crea una contrasena desde tu perfil si quieres entrar tambien con contrasena.',
        );
      }
      return const ServiceResult(
        ok: false,
        message: 'Ese correo ya esta registrado.',
      );
    }

    final newUser = NebulaUser(
      id: _uuid.v4(),
      name: trimmedName,
      username: trimmedUsername,
      email: normalizedEmail,
      password: _hashPassword(trimmedPassword),
      parentalPinHash: '',
      stars: 0,
      avatarIndex: 0,
      selectedNarratorId: 'narrator_1',
      soundEffectsEnabled: true,
      accentHue: 196,
      accentIntensity: 0.97,
      customImages: const {},
    );

    await _store.writeUsers([...users, newUser]);
    await _store.saveSessionUserId(newUser.id);
    _currentUser = newUser;

    return ServiceResult(
      ok: true,
      message: 'Cuenta creada. Bienvenido a Nebula.',
      data: newUser,
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
        message: 'Escribe tu usuario/correo y tu contrasena para entrar.',
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

    if (match != null && match.password.trim().isEmpty) {
      return const ServiceResult(
        ok: false,
        message:
            'Esta cuenta entra con Google. Usa "Entrar con Google" o crea una contrasena desde tu perfil.',
      );
    }

    if (match == null || !_passwordMatches(stored: match.password, input: secret)) {
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

    await _store.saveSessionUserId(match.id);
    _currentUser = match;
    return ServiceResult(ok: true, message: 'Listo, ya estas dentro.', data: match);
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
    _clearPendingGoogleLink();
  }

  Future<ServiceResult<NebulaUser>> updateUser(NebulaUser nextUser) async {
    final users = await _store.readUsers();
    final replaced = users.map((user) {
      if (user.id == nextUser.id) return nextUser;
      return user;
    }).toList();
    await _store.writeUsers(replaced);
    await _store.saveSessionUserId(nextUser.id);
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

    final usernameTaken = users.any(
      (user) =>
          user.id != userId &&
          user.username.toLowerCase() == trimmedUsername.toLowerCase(),
    );
    if (usernameTaken) {
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

      final auth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      final userCredential = await _firebaseAuth!.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return const ServiceResult(
          ok: false,
          message: 'No pudimos crear la sesion de Google.',
        );
      }

      final emailLower = (firebaseUser.email ?? '').toLowerCase();
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

      if (existingUser != null && existingUser.password.isNotEmpty) {
        _pendingGoogleUserForLink = NebulaUser(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'Explorador',
          username: generateSuggestedUsername(firebaseUser.email ?? ''),
          email: firebaseUser.email ?? '',
          password: '',
          parentalPinHash: '',
          stars: 0,
          avatarIndex: 0,
          selectedNarratorId: 'narrator_1',
          soundEffectsEnabled: true,
          accentHue: 196,
          accentIntensity: 0.97,
          customImages: const {},
        );
        _pendingLocalUserForLink = existingUser;
        _pendingGoogleAccessTokenForLink = auth.accessToken;
        _pendingGoogleIdTokenForLink = auth.idToken;
        await _firebaseAuth.signOut();
        await _googleSignIn.signOut();
        return const ServiceResult(
          ok: false,
          message: 'EMAIL_EXISTS_NEED_LINK',
          data: null,
        );
      }

      late final NebulaUser signedUser;
      if (existingUser != null) {
        final localUser = existingUser;
        final preservedUser = NebulaUser(
          id: firebaseUser.uid,
          name: localUser.name.trim().isEmpty
              ? firebaseUser.displayName ?? 'Explorador'
              : localUser.name,
          username: localUser.username.trim().isEmpty
              ? generateSuggestedUsername(firebaseUser.email ?? emailLower)
              : localUser.username,
          email: emailLower,
          password: localUser.password,
          parentalPinHash: localUser.parentalPinHash,
          stars: localUser.stars,
          avatarIndex: localUser.avatarIndex,
          selectedNarratorId: localUser.selectedNarratorId,
          soundEffectsEnabled: localUser.soundEffectsEnabled,
          accentHue: localUser.accentHue,
          accentIntensity: localUser.accentIntensity,
          customImages: localUser.customImages,
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
        final newUser = NebulaUser(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'Explorador',
          username: generateSuggestedUsername(firebaseUser.email ?? ''),
          email: emailLower,
          password: '',
          parentalPinHash: '',
          stars: 0,
          avatarIndex: 0,
          selectedNarratorId: 'narrator_1',
          soundEffectsEnabled: true,
          accentHue: 196,
          accentIntensity: 0.97,
          customImages: const {},
        );
        await _upsertLocal(newUser);
        signedUser = newUser;
      }

      await _store.saveSessionUserId(signedUser.id);
      _currentUser = signedUser;
      _clearPendingGoogleLink();

      return ServiceResult(
        ok: true,
        message: 'Sesion iniciada con Google.',
        data: signedUser,
      );
    } catch (e) {
      _clearPendingGoogleLink();
      return ServiceResult(
        ok: false,
        message: 'Error al iniciar sesion con Google: $e',
      );
    }
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
        message: 'La contrasena debe tener al menos 6 caracteres.',
      );
    }

    if (_requiresParentalPin() && !_isValidCurrentParentalPin(parentalPin)) {
      return const ServiceResult(
        ok: false,
        message: 'PIN parental incorrecto.',
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
        message: 'Contrasena establecida correctamente.',
      );
    } catch (e) {
      return ServiceResult(
        ok: false,
        message: 'Error al establecer contrasena: $e',
      );
    }
  }

  Future<ServiceResult<void>> changePassword({
    String oldPassword = '',
    String currentPassword = '',
    required String newPassword,
    String parentalPin = '',
  }) async {
    if (_currentUser == null) {
      return const ServiceResult(
        ok: false,
        message: 'No hay usuario actual.',
      );
    }

    if (_requiresParentalPin() && !_isValidCurrentParentalPin(parentalPin)) {
      return const ServiceResult(
        ok: false,
        message: 'PIN parental incorrecto.',
      );
    }

    if (isCurrentUserGoogleProvider && !isCurrentUserPasswordProvider) {
      return setPasswordForCurrentUser(
        newPassword: newPassword,
        parentalPin: parentalPin,
      );
    }

    final passwordToCheck =
        currentPassword.isNotEmpty ? currentPassword : oldPassword;
    if (!_passwordMatches(
      stored: _currentUser!.password,
      input: passwordToCheck.trim(),
    )) {
      return const ServiceResult(
        ok: false,
        message: 'La contrasena actual es incorrecta.',
      );
    }

    final trimmed = newPassword.trim();
    if (trimmed.length < 6) {
      return const ServiceResult(
        ok: false,
        message: 'La nueva contrasena debe tener al menos 6 caracteres.',
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
        message: 'Contrasena cambiada correctamente.',
      );
    } catch (e) {
      return ServiceResult(
        ok: false,
        message: 'Error al cambiar contrasena: $e',
      );
    }
  }

  Future<ServiceResult<NebulaUser>> changeEmail({
    required String newEmail,
    String currentPassword = '',
    String password = '',
    String parentalPin = '',
  }) async {
    if (_currentUser == null) {
      return const ServiceResult(
        ok: false,
        message: 'No hay usuario actual.',
      );
    }

    final normalized = newEmail.trim().toLowerCase();
    if (!isValidEmailFormat(normalized)) {
      return const ServiceResult(
        ok: false,
        message: 'Email invalido.',
      );
    }

    final users = await _store.readUsers();
    final taken = users.any(
      (user) =>
          user.id != _currentUser!.id &&
          user.email.toLowerCase() == normalized,
    );
    if (taken) {
      return const ServiceResult(
        ok: false,
        message: 'Ese email ya esta registrado.',
      );
    }

    if (_requiresParentalPin() && !_isValidCurrentParentalPin(parentalPin)) {
      return const ServiceResult(
        ok: false,
        message: 'PIN parental incorrecto.',
      );
    }

    final passwordToCheck =
        currentPassword.trim().isNotEmpty ? currentPassword : password;
    final mustValidatePassword =
        _currentUser!.password.trim().isNotEmpty || !_useFirebase;
    if (mustValidatePassword &&
        !_passwordMatches(stored: _currentUser!.password, input: passwordToCheck.trim())) {
      return const ServiceResult(
        ok: false,
        message: 'La contrasena actual es incorrecta.',
      );
    }

    try {
      if (_useFirebase) {
        await _firebaseAuth!.currentUser?.verifyBeforeUpdateEmail(normalized);
      }

      final updated = _currentUser!.copyWith(email: normalized);
      await _upsertLocal(updated);
      _currentUser = updated;

      return ServiceResult(
        ok: true,
        message: 'Email cambiado correctamente.',
        data: updated,
      );
    } catch (e) {
      return ServiceResult(
        ok: false,
        message: 'Error al cambiar email: $e',
      );
    }
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
          return const ServiceResult(
            ok: false,
            message: 'Usuario no encontrado.',
          );
        }
        emailToReset = user.email;
      }

      await _firebaseAuth!.sendPasswordResetEmail(email: emailToReset);
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
      final updated = _currentUser!.copyWith(parentalPinHash: _hashParentalPin(pin));
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

  Future<ServiceResult<void>> deleteCurrentAccount({
    String parentalPin = '',
    String password = '',
  }) async {
    if (_currentUser == null) {
      return const ServiceResult(
        ok: false,
        message: 'No hay usuario actual.',
      );
    }

    if (_requiresParentalPin() && !_isValidCurrentParentalPin(parentalPin)) {
      return const ServiceResult(
        ok: false,
        message: 'PIN incorrecto.',
      );
    }

    if (password.trim().isNotEmpty &&
        !_passwordMatches(stored: _currentUser!.password, input: password.trim())) {
      return const ServiceResult(
        ok: false,
        message: 'Contrasena incorrecta.',
      );
    }

    if (!_requiresParentalPin() &&
        _currentUser!.password.trim().isNotEmpty &&
        password.trim().isEmpty) {
      return const ServiceResult(
        ok: false,
        message: 'Escribe tu contrasena actual para borrar la cuenta.',
      );
    }

    try {
      final users = await _store.readUsers();
      final filtered = users.where((u) => u.id != _currentUser!.id).toList();
      await _store.writeUsers(filtered);
      await _store.clearSession();

      if (_useFirebase) {
        await _firebaseAuth!.currentUser?.delete();
      }

      _currentUser = null;
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
          message: 'No hay una vinculacion pendiente. Intenta de nuevo con Google.',
        );
      }
      if (pendingAccessToken == null || pendingIdToken == null) {
        _clearPendingGoogleLink();
        return const ServiceResult(
          ok: false,
          message: 'No pudimos recuperar la sesion de Google para vincular.',
        );
      }

      final typed = currentPassword.trim();
      if (typed.isEmpty ||
          !_passwordMatches(stored: localUser.password, input: typed)) {
        return const ServiceResult(
          ok: false,
          message: 'La contrasena actual no es correcta.',
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
      await firebaseGoogleUser.linkWithCredential(emailCredential);

      final users = await _store.readUsers();
      final normalizedPassword = _isSha256Hex(localUser.password)
          ? localUser.password
          : _hashPassword(typed);

      final merged = NebulaUser(
        id: googleUser.id,
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
      );

      final nextUsers = users
          .where(
            (u) => u.id != localUser.id && u.id != googleUser.id,
          )
          .toList();
      nextUsers.add(merged);

      await _store.writeUsers(nextUsers);
      await _store.saveSessionUserId(merged.id);
      _currentUser = merged;
      _clearPendingGoogleLink();

      return const ServiceResult(
        ok: true,
        message: 'Cuenta vinculada. Ya puedes entrar con Google o contrasena.',
      );
    } catch (e) {
      return ServiceResult(
        ok: false,
        message: 'Error al vincular Google: $e',
      );
    }
  }

  Future<void> _upsertLocal(NebulaUser user) async {
    final users = await _store.readUsers();
    final updated = users.map((u) => u.id == user.id ? user : u).toList();
    if (!users.any((u) => u.id == user.id)) {
      updated.add(user);
    }
    await _store.writeUsers(updated);
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

}
