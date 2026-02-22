import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/nebula_button.dart';
import '../widgets/nebula_snack.dart';
import '../widgets/nebula_text_field.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _submitting = false;
  bool _googleSubmitting = false;
  int _remaining = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _submitting = true);
    final result = await widget.controller.login(
      _identifierController.text,
      _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    _showSnack(result.message, ok: result.ok);
    if (!result.ok && _isVerificationPendingMessage(result.message)) {
      await _showVerificationRequiredNotice(fromMessage: result.message);
      return;
    }
    if (result.ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) => HomeScreen(controller: widget.controller)),
        (_) => false,
      );
    }
  }

  bool _isVerificationPendingMessage(String message) {
    final text = message.toLowerCase();
    return text.contains('correo no esta verificado') ||
        text.contains('correo de verificacion') ||
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
                  'Verifica tu correo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tu cuenta aun no esta verificada. Abre el correo que te enviamos y confirma el enlace.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Recuerda: solo tienes 1 hora desde el registro. Luego la cuenta se elimina por seguridad.',
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

  Future<void> _loginWithGoogle() async {
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
      if (confirmedResult.ok) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (_) => HomeScreen(controller: widget.controller)),
          (_) => false,
        );
      }
      return;
    }

    if (result.message == 'EMAIL_EXISTS_NEED_LINK') {
      await _handleGoogleLinkFlow();
      return;
    }

    _showSnack(result.message, ok: result.ok);
    if (result.ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) => HomeScreen(controller: widget.controller)),
        (_) => false,
      );
    }
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

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) => HomeScreen(controller: widget.controller)),
        (_) => false,
      );
    } finally {
      passwordController.dispose();
    }
  }

  Future<void> _requestReset() async {
    final result = await widget.controller.requestLoginPasswordReset(
      _identifierController.text,
    );
    if (!mounted) return;
    _showSnack(result.message, ok: result.ok);
    final currentRemaining = widget.controller.loginResetRemaining(
      _identifierController.text,
    );
    setState(() => _remaining = currentRemaining);
    _timer?.cancel();
    if (currentRemaining > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        final value = widget.controller.loginResetRemaining(
          _identifierController.text,
        );
        if (!mounted) return;
        setState(() => _remaining = value);
        if (value <= 0) {
          _timer?.cancel();
        }
      });
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
        title: const Text('Vamos a entrar'),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      NebulaTextField(
                        controller: _identifierController,
                        label: 'Correo o nombre de usuario',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      NebulaTextField(
                        controller: _passwordController,
                        label: 'Contrasena',
                        obscureText: true,
                      ),
                      const SizedBox(height: 18),
                      NebulaPrimaryButton(
                        text: _submitting ? 'Entrando...' : 'Comenzar',
                        onPressed:
                            (_submitting || _googleSubmitting) ? null : _login,
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: (_submitting || _googleSubmitting)
                            ? null
                            : widget.controller.firebaseEnabled
                                ? _loginWithGoogle
                                : null,
                        icon: const Icon(Icons.account_circle_outlined),
                        label: Text(
                          _googleSubmitting
                              ? 'Conectando con Google...'
                              : 'Entrar con Google',
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _requestReset,
                          child: const Text('Ayuda con mi contrasena'),
                        ),
                      ),
                      if (_remaining > 0)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Espera ${widget.controller.formatSeconds(_remaining)} antes de otra solicitud.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
