import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/nebula_button.dart';
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
    if (result.ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen(controller: widget.controller)),
        (_) => false,
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    FocusScope.of(context).unfocus();
    setState(() => _googleSubmitting = true);
    final result = await widget.controller.loginWithGoogle();
    if (!mounted) return;
    setState(() => _googleSubmitting = false);

    if (result.message == 'EMAIL_EXISTS_NEED_LINK') {
      await _handleGoogleLinkFlow();
      return;
    }

    _showSnack(result.message, ok: result.ok);
    if (result.ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen(controller: widget.controller)),
        (_) => false,
      );
    }
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
        MaterialPageRoute(builder: (_) => HomeScreen(controller: widget.controller)),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ok ? const Color(0xFF2FA56A) : const Color(0xFFC64040),
      ),
    );
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
                        onPressed: (_submitting || _googleSubmitting) ? null : _login,
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
