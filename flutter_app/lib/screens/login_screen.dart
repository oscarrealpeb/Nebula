import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/nebula_button.dart';
import '../widgets/nebula_snack.dart';
import '../widgets/nebula_text_field.dart';
import 'caregiver/caregiver_panel_screen.dart';
import 'child_profile_setup_screen.dart';
import 'portal_entry_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.controller,
    this.initialIdentifier = '',
  });

  final AppController controller;
  final String initialIdentifier;

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
  void initState() {
    super.initState();
    final initial = widget.initialIdentifier.trim();
    if (initial.isNotEmpty) {
      _identifierController.text = initial;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final identifier = _identifierController.text.trim();
    final secret = _passwordController.text.trim();
    if (identifier.isEmpty || secret.isEmpty) {
      _showSnack('Completa los campos para continuar.', ok: false);
      return;
    }
    if (!identifier.contains('@')) {
      _showSnack('Ingresa el correo del cuidador.', ok: false);
      return;
    }

    setState(() => _submitting = true);
    final resolved = await widget.controller.loginAsCaregiver(
      identifier,
      secret,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!resolved.ok) {
      _showSnack(resolved.message, ok: false);
      return;
    }
    _openPostLoginScreen();
  }

  Future<void> _loginWithGoogle() async {
    FocusScope.of(context).unfocus();
    setState(() => _googleSubmitting = true);
    final result = await widget.controller.loginWithGoogle();
    if (!mounted) return;
    setState(() => _googleSubmitting = false);

    if (_isGoogleConfirmRequired(result.message)) {
      final confirmed = await _confirmGoogleSelection(
        _extractGoogleConfirmEmail(result.message),
      );
      if (!mounted) return;
      if (!confirmed) {
        await widget.controller.cancelPendingGoogleLogin();
        return;
      }

      var preferredPasswordForNewAccount = '';
      if (_isGooglePasswordRequired(result.message)) {
        final password = await _askGooglePasswordForFirstLogin(
          email: _extractGoogleConfirmEmail(result.message),
        );
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
              ? _extractGoogleConfirmEmail(result.message)
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
        if (!retryResult.ok) {
          _showSnack(retryResult.message, ok: false);
          return;
        }
        _openPostLoginScreen();
        return;
      }
      if (!confirmResult.ok) {
        _showSnack(confirmResult.message, ok: false);
        return;
      }
      _openPostLoginScreen();
      return;
    }

    if (!result.ok) {
      _showSnack(result.message, ok: false);
      return;
    }
    _openPostLoginScreen();
  }

  void _openPostLoginScreen() {
    final Widget destination;
    if (widget.controller.isAdmin) {
      destination = CaregiverPanelScreen(controller: widget.controller);
    } else if (widget.controller.needsChildOnboarding) {
      destination = ChildProfileSetupScreen(
        controller: widget.controller,
        isMandatory: true,
      );
    } else if (widget.controller.needsPortalSelection) {
      destination = PortalEntryScreen(controller: widget.controller);
    } else {
      destination = CaregiverPanelScreen(controller: widget.controller);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destination),
        (_) => false,
      );
    });
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

  Future<String?> _askGooglePasswordForFirstLogin({
    required String email,
  }) async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    var attemptedSubmit = false;
    try {
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setLocalState) {
              final pass = passwordController.text.trim();
              final confirm = confirmController.text.trim();
              final minLengthOk = pass.length >= 6;
              final matchOk = confirm.isNotEmpty && pass == confirm;
              final ok = minLengthOk && matchOk;
              return AlertDialog(
                title: const Text('Completa tu cuenta'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cuenta Google: $email'),
                    const SizedBox(height: 8),
                    const Text(
                      'Por seguridad, crea una contraseña del cuidador para abrir la Zona cuidador en dispositivos compartidos.',
                    ),
                    const SizedBox(height: 10),
                    NebulaTextField(
                      controller: passwordController,
                      label: 'Contraseña del cuidador (mínimo 6)',
                      obscureText: true,
                      onChanged: (_) => setLocalState(() {}),
                    ),
                    if ((attemptedSubmit || pass.isNotEmpty) && !minLengthOk)
                      const Padding(
                        padding: EdgeInsets.only(top: 6, left: 2),
                        child: Text(
                          'Mínimo 6 caracteres.',
                          style: TextStyle(
                            color: Color(0xFFB3261E),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    NebulaTextField(
                      controller: confirmController,
                      label: 'Confirmar contraseña',
                      obscureText: true,
                      onChanged: (_) => setLocalState(() {}),
                    ),
                    if (attemptedSubmit && confirm.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 6, left: 2),
                        child: Text(
                          'Confirma la contraseña.',
                          style: TextStyle(
                            color: Color(0xFFB3261E),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else if (confirm.isNotEmpty && !matchOk)
                      const Padding(
                        padding: EdgeInsets.only(top: 6, left: 2),
                        child: Text(
                          'Las contraseñas no coinciden.',
                          style: TextStyle(
                            color: Color(0xFFB3261E),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (ok) {
                        Navigator.of(context).pop(pass);
                        return;
                      }
                      setLocalState(() => attemptedSubmit = true);
                    },
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
    if (currentRemaining <= 0) return;
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

  Future<void> _openHiddenAdminAccess() async {
    final result = await widget.controller.ensureHiddenAdminAccount();
    if (!mounted) return;
    if (!result.ok) {
      _showSnack(result.message, ok: false);
      return;
    }

    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    try {
      final credentials = await showDialog<(String, String)>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Acceso administrador'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NebulaTextField(
                controller: emailController,
                label: 'Correo admin',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              NebulaTextField(
                controller: passwordController,
                label: 'Contraseña admin',
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop((
                emailController.text.trim(),
                passwordController.text.trim(),
              )),
              child: const Text('Entrar'),
            ),
          ],
        ),
      );
      if (!mounted || credentials == null) return;
      final email = credentials.$1;
      final password = credentials.$2;
      if (email.isEmpty || password.isEmpty) {
        _showSnack('Completa correo y contraseña admin.', ok: false);
        return;
      }
      final login = await widget.controller.loginAsAdmin(email, password);
      if (!mounted) return;
      _showSnack(login.message, ok: login.ok);
      if (!login.ok) return;
      _openPostLoginScreen();
    } finally {
      emailController.dispose();
      passwordController.dispose();
    }
  }

  Future<void> _openCreateAccount() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(controller: widget.controller),
      ),
    );
  }

  void _showSnack(String message, {required bool ok}) {
    NebulaSnack.show(context, message: message, ok: ok);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: GestureDetector(
          onLongPress: _openHiddenAdminAccess,
          child: const Text('Entrar como cuidador'),
        ),
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
                      Text(
                        'Accede con tu correo de cuidador.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF4F628A),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      NebulaTextField(
                        controller: _identifierController,
                        label: 'Correo del cuidador',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      NebulaTextField(
                        controller: _passwordController,
                        label: 'Contraseña',
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
                          child: const Text('Ayuda con mi contraseña'),
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
                      const SizedBox(height: 8),
                      NebulaSecondaryButton(
                        text: 'Crear cuenta',
                        onPressed: _openCreateAccount,
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
