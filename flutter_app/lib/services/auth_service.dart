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
  AuthService(this._store);

  final LocalStore _store;
  final _uuid = const Uuid();

  Future<NebulaUser?> restoreSession() async {
    final sessionUserId = _store.readSessionUserId();
    if (sessionUserId == null) return null;

    final users = await _store.readUsers();
    for (final user in users) {
      if (user.id == sessionUserId) return user;
    }
    return null;
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
        message: 'Completa todos los campos. La contrasena debe tener al menos 6 caracteres.',
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

    final emailTaken = users.any(
      (user) => user.email.toLowerCase() == normalizedEmail,
    );
    if (emailTaken) {
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
      password: trimmedPassword,
      stars: 0,
      avatarIndex: 0,
      selectedNarratorId: 'narrator_1',
      soundEffectsEnabled: true,
      accentHue: 196,
      accentIntensity: 0.97,
      customImages: const {},
    );

    final nextUsers = [...users, newUser];
    await _store.writeUsers(nextUsers);
    await _store.saveSessionUserId(newUser.id);

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

    if (match == null || match.password != secret) {
      return const ServiceResult(
        ok: false,
        message: 'No pudimos entrar. Revisa tus datos e intenta otra vez.',
      );
    }

    await _store.saveSessionUserId(match.id);
    return ServiceResult(ok: true, message: 'Listo, ya estas dentro.', data: match);
  }

  Future<void> logout() async {
    await _store.clearSession();
  }

  Future<ServiceResult<NebulaUser>> updateUser(NebulaUser nextUser) async {
    final users = await _store.readUsers();
    final replaced = users.map((user) {
      if (user.id == nextUser.id) return nextUser;
      return user;
    }).toList();
    await _store.writeUsers(replaced);
    await _store.saveSessionUserId(nextUser.id);
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
}
