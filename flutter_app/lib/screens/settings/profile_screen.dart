import 'dart:async';

import 'package:flutter/material.dart';

import '../../controllers/app_controller.dart';
import '../../core/data/avatar_catalog.dart';
import '../../core/data/planet_ladder.dart';
import '../../models/portal_role.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/nebula_button.dart';
import '../../widgets/nebula_snack.dart';
import '../../widgets/nebula_text_field.dart';
import '../welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.controller,
    this.showSecurity = true,
  });

  final AppController controller;
  final bool showSecurity;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  int _avatarIndex = 0;
  int _remaining = 0;
  Timer? _timer;
  Timer? _autoSaveTimer;
  bool _saving = false;
  bool _loggingOut = false;
  bool _autoSaving = false;
  bool? _usernameValid = true;
  late String _lastSavedName;
  late String _lastSavedUsername;
  late int _lastSavedAvatarIndex;
  bool get _isChildPortal =>
      widget.controller.activePortalRole == PortalRole.child;

  @override
  void initState() {
    super.initState();
    final user = widget.controller.currentUser!;
    final child = widget.controller.childProfile;
    final initialName =
        _isChildPortal && child != null ? child.name : user.name;
    final initialUsername = _isChildPortal ? '' : user.username;
    _nameController = TextEditingController(text: initialName);
    _usernameController = TextEditingController(text: initialUsername);
    _avatarIndex = user.avatarIndex;
    _lastSavedName = _nameController.text;
    _lastSavedUsername = _usernameController.text;
    _lastSavedAvatarIndex = _avatarIndex;
    _remaining = widget.controller.profileResetRemaining();
    _usernameValid = true;
    _startTickIfNeeded();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _startTickIfNeeded() {
    _timer?.cancel();
    if (_remaining <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = widget.controller.profileResetRemaining();
      if (!mounted) return;
      setState(() => _remaining = current);
      if (current <= 0) _timer?.cancel();
    });
  }

  void _showSnack(String message, {required bool ok}) {
    NebulaSnack.show(context, message: message, ok: ok);
  }

  bool get _nameValid => _nameController.text.trim().isNotEmpty;

  bool get _usernameFormatValid {
    if (_isChildPortal) return true;
    return widget.controller.authService
        .isValidUsernameFormat(_usernameController.text);
  }

  bool get _canSaveProfile {
    if (_isChildPortal) {
      return _nameValid && !_saving;
    }
    return _nameValid &&
        _usernameFormatValid &&
        _usernameValid == true &&
        !_saving;
  }

  String get _usernameValidationMessage {
    if (_usernameController.text.trim().isEmpty) {
      return _isChildPortal
          ? 'Escribe el usuario del ni\u00f1o.'
          : 'Escribe un apodo.';
    }
    if (!_usernameFormatValid) {
      return 'Usa 3 a 18 caracteres: letras, numeros, ., _, -.';
    }
    return _isChildPortal
        ? 'Ese usuario de ni\u00f1o ya esta en uso.'
        : 'Ese apodo ya esta en uso.';
  }

  Future<bool> _validateProfileUsername(String username) async {
    if (_isChildPortal) return true;
    final typed = username.trim();
    final normalizedTyped = typed.toLowerCase();
    if (!widget.controller.authService.isValidUsernameFormat(typed)) {
      if (mounted &&
          _usernameController.text.trim().toLowerCase() == normalizedTyped) {
        setState(() => _usernameValid = false);
      }
      return false;
    }

    final currentUser = widget.controller.currentUser;
    if (currentUser == null) return false;
    final child = widget.controller.childProfile;
    final currentUsername =
        _isChildPortal ? (child?.loginUsername ?? '') : currentUser.username;
    if (currentUsername.trim().toLowerCase() == normalizedTyped) {
      if (mounted &&
          _usernameController.text.trim().toLowerCase() == normalizedTyped) {
        setState(() => _usernameValid = true);
        _scheduleAutoSave();
      }
      return true;
    }

    final isAvailable = _isChildPortal
        ? await widget.controller.authService.checkChildLoginUsernameAvailable(
            typed,
            excludeCaregiverUserId: currentUser.id,
          )
        : await widget.controller.authService.checkUsernameAvailable(
            typed,
            excludeUserId: currentUser.id,
          );
    if (!mounted) return isAvailable;
    if (_usernameController.text.trim().toLowerCase() != normalizedTyped) {
      return isAvailable;
    }
    setState(() => _usernameValid = isAvailable);
    if (isAvailable) _scheduleAutoSave();
    return isAvailable;
  }

  bool get _hasPendingProfileChanges {
    return _nameController.text != _lastSavedName ||
        _usernameController.text != _lastSavedUsername ||
        _avatarIndex != _lastSavedAvatarIndex;
  }

  void _markCurrentValuesAsSaved() {
    _lastSavedName = _nameController.text;
    _lastSavedUsername = _usernameController.text;
    _lastSavedAvatarIndex = _avatarIndex;
  }

  void _scheduleAutoSave({Duration delay = const Duration(milliseconds: 700)}) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(delay, () {
      _autoSaveProfile();
    });
  }

  Future<ActionResult> _persistProfile() {
    return _isChildPortal
        ? _saveChildProfile()
        : widget.controller.saveProfile(
            name: _nameController.text,
            username: _usernameController.text,
            avatarIndex: _avatarIndex,
          );
  }

  Future<void> _autoSaveProfile() async {
    if (!mounted || _saving || _autoSaving) return;
    if (!_hasPendingProfileChanges) return;
    if (!_nameValid) return;
    if (!_isChildPortal) {
      if (!_usernameFormatValid) return;
      if (_usernameValid != true) return;
    }

    _autoSaving = true;
    final result = await _persistProfile();
    if (!mounted) return;
    if (result.ok) {
      _markCurrentValuesAsSaved();
    }
    _autoSaving = false;

    if (_hasPendingProfileChanges) {
      _scheduleAutoSave();
    }
  }

  Future<void> _saveProfile() async {
    if (!_nameValid) {
      _showSnack('Escribe tu nombre.', ok: false);
      return;
    }
    if (!_isChildPortal) {
      if (!_usernameFormatValid) {
        _showSnack('Revisa el formato del apodo.', ok: false);
        return;
      }
      if (_usernameValid != true) {
        _showSnack('Revisa el apodo antes de guardar.', ok: false);
        return;
      }
    }
    setState(() => _saving = true);
    final result = await _persistProfile();
    if (!mounted) return;
    if (result.ok) {
      _markCurrentValuesAsSaved();
    }
    setState(() => _saving = false);
    _showSnack(result.message, ok: result.ok);
  }

  Future<ActionResult> _saveChildProfile() async {
    final user = widget.controller.currentUser;
    final child = widget.controller.childProfile;
    if (user == null || child == null) {
      return const ActionResult(
        ok: false,
        message: 'No hay perfil de ni\u00f1o activo.',
      );
    }

    final childResult = await widget.controller.createOrUpdateChildProfile(
      childId: child.id,
      name: _nameController.text,
      birthDateMillis: child.birthDateMillis,
      age: child.age,
    );
    if (!childResult.ok) return childResult;

    if (user.avatarIndex == _avatarIndex) {
      return childResult;
    }

    final avatarResult = await widget.controller.saveProfile(
      name: user.name,
      username: user.username,
      avatarIndex: _avatarIndex,
    );
    if (!avatarResult.ok) return avatarResult;
    return childResult;
  }

  Future<void> _resetPassword() async {
    if (_remaining > 0) return;
    final result = await widget.controller.requestProfilePasswordReset();
    if (!mounted) return;
    _showSnack(result.message, ok: result.ok);
    setState(() => _remaining = widget.controller.profileResetRemaining());
    _startTickIfNeeded();
  }

  Future<String?> _askCurrentPasswordForDelete({
    required bool requirePassword,
  }) async {
    final passwordController = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Confirmar borrado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ten presente que si borras tu cuenta, perderás tu progreso y configuración guardada.',
              ),
              if (requirePassword) ...[
                const SizedBox(height: 10),
                const Text('Escribe tu contraseña actual para continuar.'),
                const SizedBox(height: 10),
                NebulaTextField(
                  controller: passwordController,
                  label: 'contraseña actual',
                  obscureText: true,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Borrar cuenta'),
            ),
          ],
        ),
      );
      if (confirmed != true) return null;
      final typed = passwordController.text.trim();
      if (requirePassword && typed.isEmpty) {
        _showSnack('Debes escribir tu contraseña para borrar la cuenta.',
            ok: false);
        return null;
      }
      return typed;
    } finally {
      passwordController.dispose();
    }
  }

  Future<void> _activateParentalPin() async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Activar PIN de adulto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NebulaTextField(
                controller: pinController,
                label: 'PIN (4 a 6 numeros)',
                keyboardType: TextInputType.number,
                obscureText: true,
                digitsOnly: true,
                maxLength: 6,
              ),
              const SizedBox(height: 10),
              NebulaTextField(
                controller: confirmController,
                label: 'Repite el PIN',
                keyboardType: TextInputType.number,
                obscureText: true,
                digitsOnly: true,
                maxLength: 6,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Activar'),
            ),
          ],
        ),
      );

      if (!mounted || confirmed != true) return;
      final pin = pinController.text.trim();
      final confirm = confirmController.text.trim();
      if (pin != confirm) {
        _showSnack('Los PIN no coinciden.', ok: false);
        return;
      }
      if (!widget.controller.isValidParentalPinFormat(pin)) {
        _showSnack('El PIN debe tener 4 a 6 numeros.', ok: false);
        return;
      }

      final result = await widget.controller.activateParentalPin(pin);
      if (!mounted) return;
      _showSnack(result.message, ok: result.ok);
    } finally {
      pinController.dispose();
      confirmController.dispose();
    }
  }

  Future<void> _changeParentalPin() async {
    final currentController = TextEditingController();
    final nextController = TextEditingController();
    final confirmController = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cambiar PIN de adulto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NebulaTextField(
                controller: currentController,
                label: 'PIN actual',
                keyboardType: TextInputType.number,
                obscureText: true,
                digitsOnly: true,
                maxLength: 6,
              ),
              const SizedBox(height: 10),
              NebulaTextField(
                controller: nextController,
                label: 'Nuevo PIN',
                keyboardType: TextInputType.number,
                obscureText: true,
                digitsOnly: true,
                maxLength: 6,
              ),
              const SizedBox(height: 10),
              NebulaTextField(
                controller: confirmController,
                label: 'Repite nuevo PIN',
                keyboardType: TextInputType.number,
                obscureText: true,
                digitsOnly: true,
                maxLength: 6,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;

      final currentPin = currentController.text.trim();
      final newPin = nextController.text.trim();
      final confirmPin = confirmController.text.trim();
      if (newPin != confirmPin) {
        _showSnack('El nuevo PIN no coincide.', ok: false);
        return;
      }
      if (!widget.controller.isValidParentalPinFormat(newPin)) {
        _showSnack('El nuevo PIN debe tener 4 a 6 numeros.', ok: false);
        return;
      }

      final result = await widget.controller.updateParentalPin(
        currentPin: currentPin,
        newPin: newPin,
      );
      if (!mounted) return;
      _showSnack(result.message, ok: result.ok);
    } finally {
      currentController.dispose();
      nextController.dispose();
      confirmController.dispose();
    }
  }

  Future<void> _deactivateParentalPin() async {
    final currentController = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Desactivar PIN de adulto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Escribe tu PIN actual para confirmar.'),
              const SizedBox(height: 10),
              NebulaTextField(
                controller: currentController,
                label: 'PIN actual',
                keyboardType: TextInputType.number,
                obscureText: true,
                digitsOnly: true,
                maxLength: 6,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Desactivar'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;

      final result =
          await widget.controller.deactivateParentalPin(currentController.text);
      if (!mounted) return;
      _showSnack(result.message, ok: result.ok);
    } finally {
      currentController.dispose();
    }
  }

  Future<void> _recoverForgottenParentalPin() async {
    if (!widget.controller.parentalPinEnabled) {
      _showSnack('No hay PIN de adulto activo en esta cuenta.', ok: false);
      return;
    }
    final user = widget.controller.currentUser;
    if (widget.controller.isGoogleOnlyAccount &&
        (user?.password.trim().isEmpty ?? true)) {
      final passwordReady = await _setupGoogleRecoveryPasswordOnce();
      if (!mounted || !passwordReady) return;
    }
    await _recoverParentalPinWithPasswordFlow();
  }

  Future<bool> _setupGoogleRecoveryPasswordOnce() async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Tu contraseña de respaldo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Esta cuenta de Google es antigua y aún no tiene contraseña local. Crea una ahora para recuperar tu PIN solo con contraseña.',
              ),
              const SizedBox(height: 8),
              const Text(
                'Tip: cuando quieras entrar, podrás usar Google o correo + contraseña.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              NebulaTextField(
                controller: passwordController,
                label: 'Escribe una contraseña (mínimo 6)',
                obscureText: true,
              ),
              const SizedBox(height: 10),
              NebulaTextField(
                controller: confirmController,
                label: 'Repite la contraseña',
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return false;

      final next = passwordController.text.trim();
      final confirm = confirmController.text.trim();
      if (next != confirm) {
        _showSnack('La contraseña no coincide.', ok: false);
        return false;
      }
      if (next.length < 6) {
        _showSnack('La contraseña debe tener al menos 6 caracteres.',
            ok: false);
        return false;
      }

      final result = await widget.controller.setupGoogleRecoveryPassword(
        newPassword: next,
      );
      if (!mounted) return false;
      _showSnack(result.message, ok: result.ok);
      return result.ok;
    } finally {
      passwordController.dispose();
      confirmController.dispose();
    }
  }

  Future<void> _recoverParentalPinWithPasswordFlow() async {
    final passwordController = TextEditingController();
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Recuperar PIN de adulto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Confirma la contraseña de la cuenta y elige un PIN nuevo.',
              ),
              const SizedBox(height: 10),
              NebulaTextField(
                controller: passwordController,
                label: 'contraseña de la cuenta',
                obscureText: true,
              ),
              const SizedBox(height: 10),
              NebulaTextField(
                controller: pinController,
                label: 'Nuevo PIN (4 a 6 numeros)',
                keyboardType: TextInputType.number,
                obscureText: true,
                digitsOnly: true,
                maxLength: 6,
              ),
              const SizedBox(height: 10),
              NebulaTextField(
                controller: confirmController,
                label: 'Repite el PIN',
                keyboardType: TextInputType.number,
                obscureText: true,
                digitsOnly: true,
                maxLength: 6,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Restablecer'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;

      final newPin = pinController.text.trim();
      final confirmPin = confirmController.text.trim();
      if (newPin != confirmPin) {
        _showSnack('El PIN no coincide.', ok: false);
        return;
      }
      if (!widget.controller.isValidParentalPinFormat(newPin)) {
        _showSnack('El PIN debe tener 4 a 6 numeros.', ok: false);
        return;
      }

      final result = await widget.controller.recoverParentalPinWithPassword(
        accountPassword: passwordController.text,
        newPin: newPin,
      );
      if (!mounted) return;
      _showSnack(result.message, ok: result.ok);
    } finally {
      passwordController.dispose();
      pinController.dispose();
      confirmController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final user = widget.controller.currentUser;
        if (user == null) return const SizedBox.shrink();
        final child = widget.controller.childProfile;
        final profileHeaderUsername =
            _isChildPortal && child != null ? child.name : user.username;

        final planet = planetForStars(user.stars);
        final progress = planetProgress(user.stars);
        final unlockedCount = unlockedAvatarCount(user.stars);
        final avatar =
            avatarCatalog[user.avatarIndex.clamp(0, avatarCatalog.length - 1)];
        // final primary = Theme.of(context).colorScheme.primary;
        final profileHeaderColor = widget.controller.accentColor;

        return Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: () => Navigator.of(context).pop()),
            title: const Text('Perfil'),
          ),
          body: CosmicBackground(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  elevation: 0,
                  clipBehavior: Clip.antiAlias,
                  child: Ink(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: profileHeaderColor,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white24,
                          child: Text(avatar,
                              style: const TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profileHeaderUsername,
                                style: const TextStyle(
                                  color: Color(0xFF22335D),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 19,
                                ),
                              ),
                              Text(
                                'Planeta ${planet.name}  |  ${user.stars} estrellas',
                                style: const TextStyle(
                                  color: Color(0xFF3A4B74),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  minHeight: 7,
                                  value: progress,
                                  backgroundColor: const Color(0xFFE8ECF5),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    Color(0xFFFFD86B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.showSecurity)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      child: Row(
                        children: [
                          Icon(
                            widget.controller.isOnline
                                ? Icons.wifi_rounded
                                : Icons.wifi_off_rounded,
                            color: widget.controller.isOnline
                                ? NebulaSnack.successColor
                                : NebulaSnack.errorColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.controller.isOnline
                                  ? 'Con internet: todo se sincroniza.'
                                  : 'Sin internet: jugando en modo local.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            onPressed: widget.controller.refreshOnlineStatus,
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                            tooltip: 'Actualizar estado',
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!widget.controller.isOnline)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, bottom: 6),
                    child: Text(
                      'Sin internet: algunos avances podrian no guardarse en la nube.',
                      style: TextStyle(color: NebulaSnack.errorColor),
                    ),
                  ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        NebulaTextField(
                          controller: _nameController,
                          label: 'Como te llamas?',
                          onChanged: (_) {
                            setState(() {});
                            _scheduleAutoSave();
                          },
                        ),
                        if (!_isChildPortal) ...[
                          const SizedBox(height: 12),
                          NebulaTextField(
                            controller: _usernameController,
                            label: 'Tu apodo genial',
                            validator: _validateProfileUsername,
                            showValidationStatus: true,
                            validationMessage: _usernameValidationMessage,
                            onChanged: (_) {
                              setState(() {
                                _usernameValid =
                                    _usernameFormatValid ? null : false;
                              });
                              _scheduleAutoSave();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Elige tu avatar favorito',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            Text(
                              '$unlockedCount/${avatarCatalog.length} desbloqueados',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        GridView.builder(
                          itemCount: avatarCatalog.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemBuilder: (_, index) {
                            final unlocked = index < unlockedCount;
                            final selected = index == _avatarIndex;
                            return InkWell(
                              onTap: unlocked
                                  ? () {
                                      setState(() => _avatarIndex = index);
                                      _scheduleAutoSave(
                                        delay: Duration.zero,
                                      );
                                    }
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                              child: Ink(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: unlocked
                                      ? Colors.white
                                      : const Color(0xFFE8E8E8),
                                  border: Border.all(
                                    color: selected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.transparent,
                                    width: 1.8,
                                  ),
                                ),
                                child: Center(
                                  child: unlocked
                                      ? Text(
                                          avatarCatalog[index],
                                          style: const TextStyle(fontSize: 24),
                                        )
                                      : const Icon(Icons.lock_rounded),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.showSecurity) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Seguridad!',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text('Tu correo actual: ${user.email}'),
                          const SizedBox(height: 6),
                          Text(
                            widget.controller.parentalPinEnabled
                                ? 'PIN de adulto: activo'
                                : 'PIN de adulto: opcional',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          if (!widget.controller.parentalPinEnabled)
                            TextButton.icon(
                              onPressed: _activateParentalPin,
                              icon: const Icon(Icons.lock_person_outlined),
                              label: const Text('Activar PIN de adulto'),
                            ),
                          if (widget.controller.parentalPinEnabled) ...[
                            TextButton.icon(
                              onPressed: _changeParentalPin,
                              icon: const Icon(Icons.pin_outlined),
                              label: const Text('Cambiar PIN de adulto'),
                            ),
                            TextButton.icon(
                              onPressed: _deactivateParentalPin,
                              icon: const Icon(Icons.lock_open_rounded),
                              label: const Text('Desactivar PIN de adulto'),
                            ),
                            TextButton.icon(
                              onPressed: _recoverForgottenParentalPin,
                              icon: const Icon(Icons.mail_outline_rounded),
                              label: const Text('Olvide mi PIN de adulto'),
                            ),
                          ],
                          TextButton.icon(
                            onPressed: _remaining > 0 ? null : _resetPassword,
                            icon: const Icon(Icons.password_rounded),
                            label: Text(
                              _remaining > 0
                                  ? 'Espera ${widget.controller.formatSeconds(_remaining)}'
                                  : 'Restablecer contraseña por correo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSaveProfile ? _saveProfile : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: profileHeaderColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          profileHeaderColor.withValues(alpha: 0.45),
                      disabledForegroundColor: Colors.white70,
                      elevation: _canSaveProfile ? 2.5 : 0,
                      shadowColor: profileHeaderColor.withValues(alpha: 0.30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      _saving ? 'Guardando...' : 'Guardar cambios!',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                if (!_isChildPortal) ...[
                  const SizedBox(height: 12),
                  NebulaSecondaryButton(
                    text: _loggingOut ? 'Cerrando...' : 'Cerrar sesión',
                    onPressed: () async {
                      if (_loggingOut) return;
                      FocusScope.of(context).unfocus();
                      setState(() => _loggingOut = true);
                      await widget.controller.logout();
                      if (!context.mounted) return;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => WelcomeScreen(
                              controller: widget.controller,
                              flashMessage: 'Sesión cerrada correctamente.',
                              flashOk: true,
                            ),
                          ),
                          (_) => false,
                        );
                      });
                    },
                  ),
                ],
                const SizedBox(height: 8),
                if (widget.showSecurity)
                  TextButton(
                    onPressed: () async {
                      var hasLocalPassword = (widget
                              .controller.currentUser?.password
                              .trim()
                              .isNotEmpty ??
                          false);
                      if (!hasLocalPassword &&
                          widget.controller.isGoogleOnlyAccount) {
                        final setupOk =
                            await _setupGoogleRecoveryPasswordOnce();
                        if (!context.mounted || !setupOk) return;
                        hasLocalPassword = (widget
                                .controller.currentUser?.password
                                .trim()
                                .isNotEmpty ??
                            false);
                      }
                      if (!hasLocalPassword) {
                        _showSnack(
                          'Primero crea una contraseña en tu perfil para continuar.',
                          ok: false,
                        );
                        return;
                      }

                      // Valida PIN primero; solo si pasa, pedimos contraseña.
                      final password = await _askCurrentPasswordForDelete(
                        requirePassword: true,
                      );
                      if (!context.mounted || password == null) return;

                      final result =
                          await widget.controller.requestDeleteAccount(
                        password: password,
                      );
                      if (!context.mounted) return;
                      if (!result.ok) {
                        _showSnack(result.message, ok: false);
                        return;
                      }
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => WelcomeScreen(
                              controller: widget.controller,
                              flashMessage: 'Cuenta eliminada correctamente.',
                              flashOk: true,
                            ),
                          ),
                          (_) => false,
                        );
                      });
                    },
                    child: const Text(
                      'Borrar cuenta',
                      style: TextStyle(color: NebulaSnack.errorColor),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
