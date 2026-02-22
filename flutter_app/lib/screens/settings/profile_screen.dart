import 'dart:async';

import 'package:flutter/material.dart';

import '../../controllers/app_controller.dart';
import '../../core/data/avatar_catalog.dart';
import '../../core/data/planet_ladder.dart';
import '../../core/theme/color_utils.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/nebula_button.dart';
import '../../widgets/nebula_text_field.dart';
import '../welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  int _avatarIndex = 0;
  int _remaining = 0;
  Timer? _timer;
  bool _saving = false;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    final user = widget.controller.currentUser!;
    _nameController = TextEditingController(text: user.name);
    _usernameController = TextEditingController(text: user.username);
    _avatarIndex = user.avatarIndex;
    _remaining = widget.controller.profileResetRemaining();
    _startTickIfNeeded();
  }

  @override
  void dispose() {
    _timer?.cancel();
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ok ? const Color(0xFF2FA56A) : const Color(0xFFC64040),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    final result = await widget.controller.saveProfile(
      name: _nameController.text,
      username: _usernameController.text,
      avatarIndex: _avatarIndex,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    _showSnack(result.message, ok: result.ok);
  }

  Future<void> _resetPassword() async {
    if (widget.controller.isGoogleOnlyAccount) {
      _showSnack(
        'Tu cuenta usa Google. Recupera el acceso desde tu cuenta de Google.',
        ok: false,
      );
      return;
    }
    if (_remaining > 0) return;
    final result = await widget.controller.requestProfilePasswordReset();
    if (!mounted) return;
    _showSnack(result.message, ok: result.ok);
    setState(() => _remaining = widget.controller.profileResetRemaining());
    _startTickIfNeeded();
  }

  Future<void> _changeEmailNow() async {
    if (widget.controller.isGoogleOnlyAccount) {
      _showSnack(
        'Esta cuenta usa Google. Cambia el correo en Google y vuelve a entrar.',
        ok: false,
      );
      return;
    }

    final needsCurrentPassword = !widget.controller.isGoogleOnlyAccount;
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cambiar correo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NebulaTextField(
                controller: emailController,
                label: 'Nuevo correo',
                keyboardType: TextInputType.emailAddress,
              ),
              if (needsCurrentPassword) ...[
                const SizedBox(height: 10),
                NebulaTextField(
                  controller: passwordController,
                  label: 'Tu Contraseña actual',
                  obscureText: true,
                ),
              ] else ...[
                const SizedBox(height: 10),
                const Text(
                  'Como entraste con Google, luego te pediremos confirmar tu cuenta de Google.',
                  style: TextStyle(fontSize: 12),
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
              child: const Text('Cambiar'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      if (confirmed != true) return;
      final parentalPin = await _askParentalPinIfNeeded(
        actionText: 'cambiar el correo',
      );
      if (!mounted || parentalPin == null) return;
      final result = await widget.controller.requestEmailChange(
        newEmail: emailController.text,
        currentPassword: needsCurrentPassword ? passwordController.text : '',
        parentalPin: parentalPin,
      );
      if (!mounted) return;
      _showSnack(result.message, ok: result.ok);
    } finally {
      emailController.dispose();
      passwordController.dispose();
    }
  }

  Future<void> _changePasswordNow() async {
    final requiresCurrentPassword = !widget.controller.isGoogleOnlyAccount;

    final currentController = TextEditingController();
    final nextController = TextEditingController();
    final confirmController = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cambiar Contraseña'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (requiresCurrentPassword) ...[
                NebulaTextField(
                  controller: currentController,
                  label: 'Contraseña actual',
                  obscureText: true,
                ),
                const SizedBox(height: 10),
              ] else ...[
                const Text(
                  'Vas a crear una contraseña para poder entrar también con correo y contraseña.',
                ),
                const SizedBox(height: 10),
              ],
              NebulaTextField(
                controller: nextController,
                label: 'Nueva Contraseña',
                obscureText: true,
              ),
              const SizedBox(height: 10),
              NebulaTextField(
                controller: confirmController,
                label: 'Repite nueva Contraseña',
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
      if (!mounted) return;
      if (confirmed != true) return;

      final next = nextController.text.trim();
      final confirm = confirmController.text.trim();
      if (next != confirm) {
        _showSnack('La nueva contraseña no coincide.', ok: false);
        return;
      }

      final parentalPin = await _askParentalPinIfNeeded(
        actionText: 'cambiar la contraseña',
      );
      if (!mounted || parentalPin == null) return;

      final result = await widget.controller.changePassword(
        currentPassword: requiresCurrentPassword ? currentController.text : '',
        newPassword: nextController.text,
        parentalPin: parentalPin,
      );
      if (!mounted) return;
      _showSnack(result.message, ok: result.ok);
    } finally {
      currentController.dispose();
      nextController.dispose();
      confirmController.dispose();
    }
  }

  Future<String?> _askParentalPinIfNeeded({
    required String actionText,
  }) async {
    if (!widget.controller.parentalPinEnabled) return '';
    final pinController = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Zona de adulto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Para $actionText, escribe el PIN de adulto.'),
              const SizedBox(height: 10),
              NebulaTextField(
                controller: pinController,
                label: 'PIN de adulto',
                keyboardType: TextInputType.number,
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
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (confirmed != true) return null;
      return pinController.text.trim();
    } finally {
      pinController.dispose();
    }
  }

  Future<String?> _askCurrentPasswordForDelete() async {
    final passwordController = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Confirmar borrado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Escribe tu contrasena actual para borrar la cuenta.'),
              const SizedBox(height: 10),
              NebulaTextField(
                controller: passwordController,
                label: 'Contrasena actual',
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
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (confirmed != true) return null;
      return passwordController.text.trim();
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
                label: 'PIN (4 a 6 números)',
                keyboardType: TextInputType.number,
                obscureText: true,
              ),
              const SizedBox(height: 10),
              NebulaTextField(
                controller: confirmController,
                label: 'Repite el PIN',
                keyboardType: TextInputType.number,
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
        _showSnack('El PIN debe tener 4 a 6 números.', ok: false);
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
              ),
              const SizedBox(height: 10),
              NebulaTextField(
                controller: nextController,
                label: 'Nuevo PIN',
                keyboardType: TextInputType.number,
                obscureText: true,
              ),
              const SizedBox(height: 10),
              NebulaTextField(
                controller: confirmController,
                label: 'Repite nuevo PIN',
                keyboardType: TextInputType.number,
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
      if (!mounted || confirmed != true) return;

      final currentPin = currentController.text.trim();
      final newPin = nextController.text.trim();
      final confirmPin = confirmController.text.trim();
      if (newPin != confirmPin) {
        _showSnack('El nuevo PIN no coincide.', ok: false);
        return;
      }
      if (!widget.controller.isValidParentalPinFormat(newPin)) {
        _showSnack('El nuevo PIN debe tener 4 a 6 números.', ok: false);
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final user = widget.controller.currentUser;
        if (user == null) return const SizedBox.shrink();

        final planet = planetForStars(user.stars);
        final progress = planetProgress(user.stars);
        final unlockedCount = unlockedAvatarCount(user.stars);
        final avatar =
            avatarCatalog[user.avatarIndex.clamp(0, avatarCatalog.length - 1)];
        final primary = Theme.of(context).colorScheme.primary;

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
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          tint(shiftHue(primary, -8), 0.15),
                          tint(shiftHue(primary, 22), 0.18),
                        ],
                      ),
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
                                user.username,
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
                              ? const Color(0xFF2FA56A)
                              : const Color(0xFFC64040),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.controller.isOnline
                                ? 'Con internet: todo se sincroniza.'
                                : 'Sin internet: jugando en modo local.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
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
                      'Sin internet: algunos avances podrían no guardarse en la nube.',
                      style: TextStyle(color: Color(0xFFC64040)),
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
                          label: '¿Cómo te llamas?',
                        ),
                        const SizedBox(height: 12),
                        NebulaTextField(
                          controller: _usernameController,
                          label: 'Tu apodo genial',
                        ),
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
                                  ? () => setState(() => _avatarIndex = index)
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
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '¡Seguridad!',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text('Tu correo actual: ${user.email}'),
                        const SizedBox(height: 6),
                        Text(
                          widget.controller.parentalPinEnabled
                              ? 'PIN de adulto: activo ✅'
                              : 'PIN de adulto: opcional ✨',
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
                        ],
                        TextButton.icon(
                          onPressed: _changeEmailNow,
                          icon: const Icon(Icons.mark_email_read_outlined),
                          label: Text(
                            widget.controller.isGoogleOnlyAccount
                                ? 'Correo administrado por Google'
                                : 'Cambiar correo',
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _changePasswordNow,
                          icon: const Icon(Icons.password_rounded),
                          label: Text(
                            widget.controller.isGoogleOnlyAccount
                                ? 'Crear contraseña para entrar con correo'
                                : 'Cambiar contraseña',
                          ),
                        ),
                        if (!widget.controller.isGoogleOnlyAccount)
                          TextButton(
                            onPressed: _remaining > 0 ? null : _resetPassword,
                            child: Text(
                              _remaining > 0
                                  ? 'Espera ${widget.controller.formatSeconds(_remaining)}'
                                  : 'Olvidé mi contraseña',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                NebulaPrimaryButton(
                  text: _saving ? '¡Guardando...!' : '¡Guardar cambios!',
                  onPressed: _saving ? null : _saveProfile,
                ),
                const SizedBox(height: 12),
                NebulaSecondaryButton(
                  text: _loggingOut ? 'Cerrando...' : 'Cerrar sesión',
                  onPressed: () async {
                    if (_loggingOut) return;
                    FocusScope.of(context).unfocus();
                    setState(() => _loggingOut = true);
                    await widget.controller.logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) =>
                            WelcomeScreen(controller: widget.controller),
                      ),
                      (_) => false,
                    );
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    final parentalPin = await _askParentalPinIfNeeded(
                      actionText: 'borrar la cuenta',
                    );
                    if (!context.mounted || parentalPin == null) return;

                    String password = '';
                    if (!widget.controller.parentalPinEnabled &&
                        !widget.controller.isGoogleOnlyAccount) {
                      final typedPassword = await _askCurrentPasswordForDelete();
                      if (!context.mounted || typedPassword == null) return;
                      password = typedPassword;
                    }

                    final result = await widget.controller.requestDeleteAccount(
                      parentalPin: parentalPin,
                      password: password,
                    );
                    if (!context.mounted) return;
                    _showSnack(result.message, ok: result.ok);
                    if (!result.ok) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) =>
                            WelcomeScreen(controller: widget.controller),
                      ),
                      (_) => false,
                    );
                  },
                  child: const Text(
                    'Borrar cuenta',
                    style: TextStyle(color: Color(0xFFC64040)),
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
