import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/nebula_button.dart';
import '../widgets/nebula_snack.dart';
import '../widgets/nebula_text_field.dart';
import 'child_profile_setup_screen.dart';
import 'login_screen.dart';
import 'portal_entry_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _submitting = false;
  bool _googleSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _nameValid => _nameController.text.trim().isNotEmpty;

  bool get _emailValid {
    final email = _emailController.text.trim().toLowerCase();
    return widget.controller.authService.isValidEmailFormat(email);
  }

  bool get _passwordValid => _passwordController.text.trim().length >= 6;

  bool get _passwordsMatch =>
      _passwordController.text.trim() == _confirmController.text.trim();

  bool get _canSubmit {
    return _nameValid &&
        _emailValid &&
        _passwordValid &&
        _passwordsMatch &&
        !_submitting &&
        !_googleSubmitting;
  }

  Future<void> _registerCaregiver() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final result = await widget.controller.registerCaregiver(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    _showSnack(result.message, ok: result.ok);
    if (!result.ok) return;

    if (widget.controller.currentUser == null) {
      if (_isVerificationPendingMessage(result.message)) {
        await _showVerificationRequiredNotice();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => LoginScreen(
              controller: widget.controller,
              initialIdentifier: _emailController.text.trim(),
            ),
          ),
        );
      }
      return;
    }

    _openPostRegisterScreen();
  }

  bool _isVerificationPendingMessage(String message) {
    final text = message.toLowerCase();
    return text.contains('correo de verificacion') ||
        text.contains('correo no esta verificado') ||
        text.contains('verifica tu cuenta');
  }

  Future<void> _showVerificationRequiredNotice() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                'Te enviamos un correo de verificacion. Tienes 1 hora para activarlo.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
            ],
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

      var preferredPasswordForNewAccount = '';
      if (_isGooglePasswordRequired(result.message)) {
        final password = await _askGooglePasswordForFirstLogin(email: email);
        if (!mounted) return;
        if (password == null) {
          await widget.controller.cancelPendingGoogleLogin();
          return;
        }
        preferredPasswordForNewAccount = password;
      }

      setState(() => _googleSubmitting = true);
      final confirmResult = await widget.controller.confirmPendingGoogleLogin(
        preferredPasswordForNewAccount: preferredPasswordForNewAccount,
      );
      if (!mounted) return;
      setState(() => _googleSubmitting = false);
      if (!confirmResult.ok &&
          preferredPasswordForNewAccount.isEmpty &&
          _isGooglePasswordRequired(confirmResult.message)) {
        final retryPassword = await _askGooglePasswordForFirstLogin(
          email: _extractGoogleConfirmEmail(confirmResult.message).isEmpty
              ? email
              : _extractGoogleConfirmEmail(confirmResult.message),
        );
        if (!mounted) return;
        if (retryPassword == null) {
          await widget.controller.cancelPendingGoogleLogin();
          return;
        }
        setState(() => _googleSubmitting = true);
        final retryResult = await widget.controller.confirmPendingGoogleLogin(
          preferredPasswordForNewAccount: retryPassword,
        );
        if (!mounted) return;
        setState(() => _googleSubmitting = false);
        _showSnack(retryResult.message, ok: retryResult.ok);
        if (!retryResult.ok) return;
        _openPostRegisterScreen();
        return;
      }
      _showSnack(confirmResult.message, ok: confirmResult.ok);
      if (!confirmResult.ok) return;

      _openPostRegisterScreen();
      return;
    }

    _showSnack(result.message, ok: result.ok);
    if (!result.ok) return;
    _openPostRegisterScreen();
  }

  void _openPostRegisterScreen() {
    final Widget destination;
    if (widget.controller.needsChildOnboarding) {
      destination = ChildProfileSetupScreen(
        controller: widget.controller,
        isMandatory: true,
      );
    } else if (widget.controller.needsPortalSelection) {
      destination = PortalEntryScreen(controller: widget.controller);
    } else {
      destination = PortalEntryScreen(controller: widget.controller);
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (_) => false,
    );
  }

  bool _isGoogleConfirmRequired(String message) {
    return message.startsWith('GOOGLE_CONFIRM_REQUIRED:') ||
        message.startsWith('GOOGLE_CONFIRM_REQUIRED_WITH_PASSWORD:') ||
        message.startsWith('GOOGLE_CONFIRM_REQUIRED_WITH_USERNAME:');
  }

  bool _isGooglePasswordRequired(String message) {
    return message.startsWith('GOOGLE_CONFIRM_REQUIRED_WITH_PASSWORD:') ||
        message.startsWith('GOOGLE_CONFIRM_REQUIRED_WITH_USERNAME:');
  }

  String _extractGoogleConfirmEmail(String message) {
    const withPassword = 'GOOGLE_CONFIRM_REQUIRED_WITH_PASSWORD:';
    if (message.startsWith(withPassword)) {
      return message.substring(withPassword.length).trim();
    }
    const withUsername = 'GOOGLE_CONFIRM_REQUIRED_WITH_USERNAME:';
    if (message.startsWith(withUsername)) {
      final payload = message.substring(withUsername.length);
      return payload.split('|').first.trim();
    }
    const simple = 'GOOGLE_CONFIRM_REQUIRED:';
    if (!message.startsWith(simple)) return '';
    return message.substring(simple.length).trim();
  }

  Future<bool> _confirmGoogleSelection(String email) async {
    final selected = email.isEmpty ? 'esta cuenta' : email;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar cuenta Google'),
        content: Text('Vas a entrar con $selected. ¿Deseas continuar?'),
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

  Future<String?> _askGooglePasswordForFirstLogin({
    required String email,
  }) async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    try {
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setLocalState) {
              final pass = passwordController.text.trim();
              final confirm = confirmController.text.trim();
              final ok = pass.length >= 6 && pass == confirm;
              return AlertDialog(
                title: const Text('Completa tu cuenta'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Cuenta Google: $email'),
                    const SizedBox(height: 8),
                    const Text(
                      'Esta contraseña protege la entrada a la Zona cuidador en dispositivos compartidos.',
                    ),
                    const SizedBox(height: 10),
                    NebulaTextField(
                      controller: passwordController,
                      label: 'Contraseña del cuidador (mínimo 6)',
                      obscureText: true,
                      onChanged: (_) => setLocalState(() {}),
                    ),
                    const SizedBox(height: 10),
                    NebulaTextField(
                      controller: confirmController,
                      label: 'Confirmar contraseña',
                      obscureText: true,
                      onChanged: (_) => setLocalState(() {}),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed:
                        ok ? () => Navigator.of(context).pop(pass) : null,
                    child: const Text('Continuar'),
                  ),
                ],
              );
            },
          );
        },
      );
      return result;
    } finally {
      passwordController.dispose();
      confirmController.dispose();
    }
  }

  void _showSnack(String message, {required bool ok}) {
    NebulaSnack.show(context, message: message, ok: ok);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('Crear cuenta de cuidador'),
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
                      label: 'Nombre',
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
                    const SizedBox(height: 12),
                    NebulaTextField(
                      controller: _confirmController,
                      onChanged: (_) => setState(() {}),
                      label: 'Confirmar contraseña',
                      obscureText: true,
                    ),
                    const SizedBox(height: 18),
                    NebulaPrimaryButton(
                      text: _submitting ? 'Creando cuenta...' : 'Crear cuenta',
                      onPressed: _canSubmit ? _registerCaregiver : null,
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
                            : 'Crear con Google',
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
