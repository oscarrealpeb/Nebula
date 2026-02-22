import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/nebula_button.dart';
import '../widgets/nebula_snack.dart';
import '../widgets/nebula_text_field.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  bool _googleSubmitting = false;
  bool? _usernameValid; // null = no validado, true = válido, false = inválido

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<bool> _validateUsername(String username) async {
    final isAvailable =
        await widget.controller.authService.checkUsernameAvailable(username);
    setState(() {
      _usernameValid = isAvailable;
    });
    return isAvailable;
  }

  bool get _nameValid => _nameController.text.trim().isNotEmpty;

  bool get _usernameFormatValid {
    final username = _usernameController.text.trim().toLowerCase();
    return RegExp(r'^[a-z0-9_]{3,18}$').hasMatch(username);
  }

  bool get _emailValid {
    final email = _emailController.text.trim().toLowerCase();
    return widget.controller.authService.isValidEmailFormat(email);
  }

  bool get _passwordValid => _passwordController.text.trim().length >= 6;

  bool get _canSubmit {
    return _nameValid &&
        _usernameFormatValid &&
        _usernameValid == true &&
        _emailValid &&
        _passwordValid &&
        !_submitting &&
        !_googleSubmitting;
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final result = await widget.controller.register(
      name: _nameController.text,
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    _showSnack(result.message, ok: result.ok);

    if (result.ok) {
      if (widget.controller.currentUser == null) {
        if (_isVerificationPendingMessage(result.message)) {
          await _showVerificationRequiredNotice(fromMessage: result.message);
        }
        return;
      }
      await _maybeOfferParentalPin();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) => HomeScreen(controller: widget.controller)),
        (_) => false,
      );
    }
  }

  bool _isVerificationPendingMessage(String message) {
    final text = message.toLowerCase();
    return text.contains('correo de verificacion') ||
        text.contains('correo no esta verificado') ||
        text.contains('verifica tu cuenta');
  }

  Future<void> _showVerificationRequiredNotice({String? fromMessage}) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.92, end: 1),
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutBack,
          builder: (context, value, child) => Transform.scale(
            scale: value,
            child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE7F4FF),
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_rounded,
                    size: 36,
                    color: Color(0xFF1F86E6),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Revisa tu correo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Te enviamos un correo de verificacion. Debes verificarlo para activar la cuenta.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Importante: tienes 1 hora. Si no verificas a tiempo, la cuenta se elimina por seguridad.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE76F51),
                  ),
                ),
                if (fromMessage != null && fromMessage.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    fromMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _registerWithGoogle() async {
    FocusScope.of(context).unfocus();
    setState(() => _googleSubmitting = true);
    final result = await widget.controller.loginWithGoogle();
    if (!mounted) return;
    setState(() => _googleSubmitting = false);

    if (_isGoogleConfirmRequired(result.message)) {
      final email = _extractGoogleConfirmEmail(result.message);
      final confirmed = await _confirmGoogleSelection(email);
      if (!mounted) return;
      if (!confirmed) {
        await widget.controller.cancelPendingGoogleLogin();
        return;
      }

      setState(() => _googleSubmitting = true);
      final confirmedResult =
          await widget.controller.confirmPendingGoogleLogin();
      if (!mounted) return;
      setState(() => _googleSubmitting = false);

      if (confirmedResult.message == 'EMAIL_EXISTS_NEED_LINK') {
        await _handleGoogleLinkFlow();
        return;
      }

      _showSnack(confirmedResult.message, ok: confirmedResult.ok);
      if (!confirmedResult.ok) return;

      await _maybeOfferParentalPin();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => HomeScreen(controller: widget.controller),
        ),
        (_) => false,
      );
      return;
    }

    if (result.message == 'EMAIL_EXISTS_NEED_LINK') {
      await _handleGoogleLinkFlow();
      return;
    }

    _showSnack(result.message, ok: result.ok);
    if (!result.ok) return;

    await _maybeOfferParentalPin();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (_) => HomeScreen(controller: widget.controller)),
      (_) => false,
    );
  }

  bool _isGoogleConfirmRequired(String message) {
    return message.startsWith('GOOGLE_CONFIRM_REQUIRED:');
  }

  String _extractGoogleConfirmEmail(String message) {
    const prefix = 'GOOGLE_CONFIRM_REQUIRED:';
    if (!message.startsWith(prefix)) return '';
    return message.substring(prefix.length).trim();
  }

  Future<bool> _confirmGoogleSelection(String email) async {
    final selected = email.isEmpty ? 'esta cuenta' : email;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar cuenta Google'),
        content: Text(
          'Vas a entrar con $selected. ¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _handleGoogleLinkFlow() async {
    final passwordController = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Vincular cuenta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ya existe una cuenta con ese correo. Escribe tu contrasena actual para vincular Google.',
              ),
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
              child: const Text('Vincular'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;

      final linkResult = await widget.controller.linkGoogleToExistingAccount(
        currentPassword: passwordController.text,
      );
      if (!mounted) return;
      _showSnack(linkResult.message, ok: linkResult.ok);
      if (!linkResult.ok) return;

      await _maybeOfferParentalPin();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => HomeScreen(controller: widget.controller),
        ),
        (_) => false,
      );
    } finally {
      passwordController.dispose();
    }
  }

  void _showSnack(String message, {required bool ok}) {
    NebulaSnack.show(context, message: message, ok: ok);
  }

  Future<void> _maybeOfferParentalPin() async {
    if (widget.controller.parentalPinEnabled) return;
    final wantsPin = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¡Modo adulto opcional!'),
        content: const Text(
          '¿Quieres activar un PIN de adulto para proteger acciones sensibles como borrar cuenta o cambiar datos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ahora no'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Activar PIN'),
          ),
        ],
      ),
    );
    if (!mounted || wantsPin != true) return;
    await _setupParentalPin();
  }

  Future<void> _setupParentalPin() async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Crear PIN de adulto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NebulaTextField(
                controller: pinController,
                label: 'PIN (4 a 6 números)',
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
              child: const Text('Guardar PIN'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;

      final pin = pinController.text.trim();
      final confirm = confirmController.text.trim();
      if (pin != confirm) {
        _showSnack('Los PIN no coinciden. ¡Intentemos otra vez!', ok: false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('¡Crear mi cuenta!'),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    NebulaTextField(
                      controller: _nameController,
                      onChanged: (_) => setState(() {}),
                      label: '¿Cómo te llamas?',
                    ),
                    const SizedBox(height: 12),
                    NebulaTextField(
                      controller: _usernameController,
                      label: 'Tu apodo (nombre de usuario)',
                      validator: _validateUsername,
                      showValidationStatus: true,
                      validationMessage:
                          'Este nombre de usuario ya está en uso',
                      onChanged: (_) {
                        setState(() {
                          _usernameValid = _usernameFormatValid ? null : false;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    NebulaTextField(
                      controller: _emailController,
                      onChanged: (_) => setState(() {}),
                      label: 'Correo',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    NebulaTextField(
                      controller: _passwordController,
                      onChanged: (_) => setState(() {}),
                      label: 'Contraseña',
                      obscureText: true,
                    ),
                    const SizedBox(height: 18),
                    NebulaPrimaryButton(
                      text: _submitting
                          ? '¡Creando cuenta...!'
                          : '¡Empezar aventura!',
                      onPressed: _canSubmit ? _register : null,
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: (_submitting || _googleSubmitting)
                          ? null
                          : widget.controller.firebaseEnabled
                              ? _registerWithGoogle
                              : null,
                      icon: const Icon(Icons.account_circle_outlined),
                      label: Text(
                        _googleSubmitting
                            ? 'Conectando con Google...'
                            : '¡Crear con Google!',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
