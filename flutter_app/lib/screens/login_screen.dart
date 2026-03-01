import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/portal_role.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/nebula_button.dart';
import '../widgets/nebula_snack.dart';
import '../widgets/nebula_text_field.dart';
import 'caregiver/caregiver_panel_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.controller,
    this.initialIdentifier = '',
    this.initialRole = PortalRole.caregiver,
  });

  final AppController controller;
  final String initialIdentifier;
  final PortalRole initialRole;

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
  late PortalRole _role;

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole == PortalRole.child
        ? PortalRole.child
        : PortalRole.caregiver;
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
    if (_role == PortalRole.caregiver && !identifier.contains('@')) {
      _showSnack('Ingresa el correo del cuidador.', ok: false);
      return;
    }
    if (_role == PortalRole.child &&
        !widget.controller.isValidChildLoginPinFormat(secret)) {
      _showSnack(
        'La contrase\u00f1a del ni\u00f1o debe tener al menos 6 caracteres.',
        ok: false,
      );
      return;
    }

    setState(() => _submitting = true);
    final result = switch (_role) {
      PortalRole.child => widget.controller.loginAsChild(
          username: identifier,
          password: secret,
        ),
      PortalRole.caregiver => widget.controller.loginAsCaregiver(
          identifier,
          secret,
        ),
      PortalRole.admin => widget.controller.loginAsAdmin(
          identifier,
          secret,
        ),
    };
    final resolved = await result;
    if (!mounted) return;
    setState(() => _submitting = false);
    _showSnack(resolved.message, ok: resolved.ok);
    if (!resolved.ok) return;
    _openPostLoginScreen();
  }

  Future<void> _loginWithGoogle() async {
    if (_role != PortalRole.caregiver) return;
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

      var preferredUsernameForNewAccount = '';
      var preferredPasswordForNewAccount = '';

      if (_isGoogleConfirmWithUsername(result.message)) {
        final data = await _askGooglePasswordForFirstLogin(
          email: _extractGoogleConfirmEmail(result.message),
        );
        if (!mounted) return;
        if (data == null) {
          await widget.controller.cancelPendingGoogleLogin();
          return;
        }
        preferredUsernameForNewAccount = data.$1;
        preferredPasswordForNewAccount = data.$2;
      }

      setState(() => _googleSubmitting = true);
      final confirmResult = await widget.controller.confirmPendingGoogleLogin(
        preferredUsernameForNewAccount: preferredUsernameForNewAccount,
        preferredPasswordForNewAccount: preferredPasswordForNewAccount,
      );
      if (!mounted) return;
      setState(() => _googleSubmitting = false);
      _showSnack(confirmResult.message, ok: confirmResult.ok);
      if (!confirmResult.ok) return;
      _openPostLoginScreen();
      return;
    }

    _showSnack(result.message, ok: result.ok);
    if (!result.ok) return;
    _openPostLoginScreen();
  }

  void _openPostLoginScreen() {
    final role = widget.controller.activePortalRole;
    final Widget destination = role == PortalRole.child
        ? HomeScreen(controller: widget.controller)
        : CaregiverPanelScreen(controller: widget.controller);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (_) => false,
    );
  }

  bool _isGoogleConfirmRequired(String message) {
    return message.startsWith('GOOGLE_CONFIRM_REQUIRED:') ||
        message.startsWith('GOOGLE_CONFIRM_REQUIRED_WITH_USERNAME:');
  }

  bool _isGoogleConfirmWithUsername(String message) {
    return message.startsWith('GOOGLE_CONFIRM_REQUIRED_WITH_USERNAME:');
  }

  String _extractGoogleConfirmEmail(String message) {
    const withUsername = 'GOOGLE_CONFIRM_REQUIRED_WITH_USERNAME:';
    if (message.startsWith(withUsername)) {
      final payload = message.substring(withUsername.length);
      return payload.split('|').first.trim();
    }
    const simple = 'GOOGLE_CONFIRM_REQUIRED:';
    if (!message.startsWith(simple)) return '';
    return message.substring(simple.length).trim();
  }

  Future<(String, String)?> _askGooglePasswordForFirstLogin({
    required String email,
  }) async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    try {
      final result = await showDialog<(String, String)>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setLocalState) {
              final pass = passwordController.text.trim();
              final confirm = confirmController.text.trim();
              final ok = pass.length >= 6 && pass == confirm;
              final username =
                  widget.controller.authService.generateSuggestedUsername(
                email,
              );
              return AlertDialog(
                title: const Text('Completa tu cuenta'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Cuenta Google: $email'),
                    const SizedBox(height: 8),
                    Text('Usuario interno: $username'),
                    const SizedBox(height: 10),
                    NebulaTextField(
                      controller: passwordController,
                      label: 'Contrase\u00f1a de respaldo (minimo 6)',
                      obscureText: true,
                      onChanged: (_) => setLocalState(() {}),
                    ),
                    const SizedBox(height: 10),
                    NebulaTextField(
                      controller: confirmController,
                      label: 'Confirmar contrase\u00f1a',
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
                    onPressed: ok
                        ? () => Navigator.of(context).pop((username, pass))
                        : null,
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
        content: Text('Vas a entrar con $selected. Deseas continuar?'),
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
    if (_role == PortalRole.child) {
      final wantsSwitch = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cuenta de niño'),
          content: const Text(
            'Las cuentas de niño las crea un cuidador desde su panel.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ir a cuidador'),
            ),
          ],
        ),
      );
      if (!mounted || wantsSwitch != true) return;
      setState(() => _role = PortalRole.caregiver);
    }
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
          child: const Text('Vamos a entrar'),
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
                      SegmentedButton<PortalRole>(
                        segments: const [
                          ButtonSegment<PortalRole>(
                            value: PortalRole.child,
                            label: Text('Ni\u00f1o'),
                            icon: Icon(Icons.child_care_rounded),
                          ),
                          ButtonSegment<PortalRole>(
                            value: PortalRole.caregiver,
                            label: Text('Cuidador'),
                            icon: Icon(Icons.family_restroom_rounded),
                          ),
                        ],
                        selected: <PortalRole>{_role},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _role = selection.first;
                            _identifierController.clear();
                            _passwordController.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Dispositivo compartido: cambia entre ni\u00f1o y cuidador segun quien vaya a entrar ahora.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF4F628A),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      NebulaTextField(
                        controller: _identifierController,
                        label: _role == PortalRole.child
                            ? 'Usuario del ni\u00f1o'
                            : 'Correo del cuidador',
                        keyboardType: _role == PortalRole.child
                            ? TextInputType.text
                            : TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      NebulaTextField(
                        controller: _passwordController,
                        label: _role == PortalRole.child
                            ? 'Contrase\u00f1a del ni\u00f1o'
                            : 'Contrase\u00f1a',
                        maxLength: _role == PortalRole.child ? 32 : null,
                        obscureText: true,
                      ),
                      if (_role == PortalRole.child) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'La contrase\u00f1a del ni\u00f1o debe tener al menos 6 caracteres.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: const Color(0xFF4F628A)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      NebulaPrimaryButton(
                        text: _submitting ? 'Entrando...' : 'Comenzar',
                        onPressed:
                            (_submitting || _googleSubmitting) ? null : _login,
                      ),
                      if (_role == PortalRole.caregiver) ...[
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
                            child: const Text('Ayuda con mi contrase\u00f1a'),
                          ),
                        ),
                      ],
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
