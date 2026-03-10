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
  bool _attemptedSubmit = false;
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

  bool get _showNameError =>
      _attemptedSubmit || _nameController.text.trim().isNotEmpty;

  bool get _showEmailError =>
      _attemptedSubmit || _emailController.text.trim().isNotEmpty;

  bool get _showPasswordError =>
      _attemptedSubmit || _passwordController.text.isNotEmpty;

  bool get _showConfirmError =>
      _attemptedSubmit || _confirmController.text.isNotEmpty;

  String? get _nameError {
    if (!_showNameError) return null;
    if (_nameValid) return null;
    return 'Ingresa tu nombre.';
  }

  String? get _emailError {
    if (!_showEmailError) return null;
    if (_emailValid) return null;
    return 'Ingresa un correo valido.';
  }

  String? get _passwordError {
    if (!_showPasswordError) return null;
    final value = _passwordController.text.trim();
    if (value.isEmpty) return 'Ingresa una contrase\u00f1a.';
    if (_passwordValid) return null;
    return 'La contrase\u00f1a debe tener al menos 6 caracteres.';
  }

  String? get _confirmError {
    if (!_showConfirmError) return null;
    final value = _confirmController.text.trim();
    if (value.isEmpty) return 'Confirma la contrase\u00f1a.';
    if (_passwordsMatch) return null;
    return 'Las contrase\u00f1as no coinciden.';
  }

  bool get _hasValidationErrors =>
      _nameError != null ||
      _emailError != null ||
      _passwordError != null ||
      _confirmError != null;

  Future<void> _submitRegister() async {
    if (_submitting || _googleSubmitting) return;
    FocusScope.of(context).unfocus();
    setState(() => _attemptedSubmit = true);
    if (_hasValidationErrors) {
      _showSnack('Corrige los campos marcados en rojo.', ok: false);
      return;
    }
    await _registerCaregiver();
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
    if (!result.ok) {
      _showSnack(result.message, ok: false);
      return;
    }

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
    return text.contains('correo de verificación') ||
        text.contains('correo no está verificado') ||
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
                'Te enviamos un correo de verificación. Tienes 1 hora para activarlo.\n\nSi no lo ves, revisa spam o correo no deseado.',
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
        if (!retryResult.ok) {
          _showSnack(retryResult.message, ok: false);
          return;
        }
        _openPostRegisterScreen();
        return;
      }
      if (!confirmResult.ok) {
        _showSnack(confirmResult.message, ok: false);
        return;
      }

      _openPostRegisterScreen();
      return;
    }

    if (!result.ok) {
      _showSnack(result.message, ok: false);
      return;
    }
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
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var pass = '';
        var confirm = '';
        var attemptedSubmit = false;
        var obscurePass = true;
        var obscureConfirm = true;
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final minLengthOk = pass.length >= 6;
            final matchOk = confirm.isNotEmpty && pass == confirm;
            final ok = minLengthOk && matchOk;
            return AlertDialog(
              scrollable: true,
              title: const Text('Completa tu cuenta'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cuenta Google: $email'),
                    const SizedBox(height: 8),
                    const Text(
                      'Esta contraseña protege la entrada a la Zona cuidador en dispositivos compartidos.',
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      obscureText: obscurePass,
                      onChanged: (value) =>
                          setLocalState(() => pass = value.trim()),
                      decoration: InputDecoration(
                        labelText: 'Contraseña del cuidador (mínimo 6)',
                        suffixIcon: IconButton(
                          onPressed: () => setLocalState(() {
                            obscurePass = !obscurePass;
                          }),
                          icon: Icon(
                            obscurePass
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
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
                    TextField(
                      obscureText: obscureConfirm,
                      onChanged: (value) =>
                          setLocalState(() => confirm = value.trim()),
                      onSubmitted: (_) {
                        if (ok) {
                          Navigator.of(dialogContext).pop(pass);
                          return;
                        }
                        setLocalState(() => attemptedSubmit = true);
                      },
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña',
                        suffixIcon: IconButton(
                          onPressed: () => setLocalState(() {
                            obscureConfirm = !obscureConfirm;
                          }),
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (ok) {
                      Navigator.of(dialogContext).pop(pass);
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
  }

  void _showSnack(String message, {required bool ok}) {
    NebulaSnack.show(context, message: message, ok: ok);
  }

  Widget _inlineError(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 2),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFB3261E),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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
                    if (_nameError != null) _inlineError(_nameError!),
                    const SizedBox(height: 12),
                    NebulaTextField(
                      controller: _emailController,
                      onChanged: (_) => setState(() {}),
                      label: 'Correo',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    if (_emailError != null) _inlineError(_emailError!),
                    const SizedBox(height: 12),
                    NebulaTextField(
                      controller: _passwordController,
                      onChanged: (_) => setState(() {}),
                      label: 'Contraseña',
                      obscureText: true,
                    ),
                    if (_passwordError != null) _inlineError(_passwordError!),
                    const SizedBox(height: 12),
                    NebulaTextField(
                      controller: _confirmController,
                      onChanged: (_) => setState(() {}),
                      label: 'Confirmar contraseña',
                      obscureText: true,
                    ),
                    if (_confirmError != null) _inlineError(_confirmError!),
                    const SizedBox(height: 18),
                    NebulaPrimaryButton(
                      text: _submitting ? 'Creando cuenta...' : 'Crear cuenta',
                      onPressed: (_submitting || _googleSubmitting)
                          ? null
                          : _submitRegister,
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
