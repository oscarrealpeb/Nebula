import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/nebula_button.dart';
import '../widgets/nebula_snack.dart';
import '../widgets/nebula_text_field.dart';
import 'caregiver/caregiver_panel_screen.dart';
import 'home_screen.dart';

class ChildProfileSetupScreen extends StatefulWidget {
  const ChildProfileSetupScreen({
    super.key,
    required this.controller,
    this.isMandatory = false,
  });

  final AppController controller;
  final bool isMandatory;

  @override
  State<ChildProfileSetupScreen> createState() =>
      _ChildProfileSetupScreenState();
}

class _ChildProfileSetupScreenState extends State<ChildProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _loginUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  String _languageLevel = 'medio';
  bool? _usernameAvailable = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final child = widget.controller.childProfile;
    if (child != null) {
      _nameController.text = child.name;
      if (child.age > 0) {
        _ageController.text = child.age.toString();
      }
      _loginUsernameController.text = child.loginUsername;
      _languageLevel =
          child.languageLevel.trim().isEmpty ? 'medio' : child.languageLevel;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _loginUsernameController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  bool get _usernameFormatValid {
    return widget.controller.authService
        .isValidUsernameFormat(_loginUsernameController.text);
  }

  bool get _canSave {
    return _nameController.text.trim().isNotEmpty &&
        _loginUsernameController.text.trim().isNotEmpty &&
        _usernameFormatValid &&
        _usernameAvailable == true &&
        !_saving;
  }

  String get _usernameValidationMessage {
    if (_loginUsernameController.text.trim().isEmpty) {
      return 'Escribe un usuario para el ni\u00f1o.';
    }
    if (!_usernameFormatValid) {
      return 'Usa 3 a 18 caracteres: letras, numeros, ., _, -.';
    }
    return 'Ese usuario ya esta en uso.';
  }

  Future<bool> _validateChildUsername(String username) async {
    final typed = username.trim();
    final normalizedTyped = typed.toLowerCase();
    if (!widget.controller.authService.isValidUsernameFormat(typed)) {
      if (mounted &&
          _loginUsernameController.text.trim().toLowerCase() ==
              normalizedTyped) {
        setState(() => _usernameAvailable = false);
      }
      return false;
    }

    final currentUser = widget.controller.currentUser;
    if (currentUser == null) return false;
    final available =
        await widget.controller.authService.checkChildLoginUsernameAvailable(
      typed,
      excludeCaregiverUserId: currentUser.id,
    );
    if (!mounted) return available;
    if (_loginUsernameController.text.trim().toLowerCase() != normalizedTyped) {
      return available;
    }
    setState(() => _usernameAvailable = available);
    return available;
  }

  String _languageGuideByLevel(String level) {
    switch (level) {
      case 'bajo':
        return 'Bajo: usa palabras sueltas, apoyos visuales o necesita instrucciones muy cortas.';
      case 'alto':
        return 'Alto: comprende frases completas, dialogos simples y mas detalles verbales.';
      case 'medio':
      default:
        return 'Medio: entiende frases cortas y puede seguir instrucciones de 1 a 2 pasos.';
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final password = _passwordController.text.trim();
    final passwordConfirm = _passwordConfirmController.text.trim();
    if (password.isNotEmpty && password != passwordConfirm) {
      await NebulaSnack.show(
        context,
        message: 'Las contrase\u00f1as del ni\u00f1o no coinciden.',
        ok: false,
      );
      return;
    }
    if (password.isNotEmpty &&
        !widget.controller.isValidChildLoginPinFormat(password)) {
      await NebulaSnack.show(
        context,
        message:
            'La contrase\u00f1a del ni\u00f1o debe tener al menos 6 caracteres.',
        ok: false,
      );
      return;
    }

    setState(() => _saving = true);
    final age = int.tryParse(_ageController.text.trim()) ?? 0;
    final result = await widget.controller.createOrUpdateChildProfile(
      name: _nameController.text,
      age: age,
      languageLevel: _languageLevel,
      loginUsername: _loginUsernameController.text,
      loginPassword: password,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    await NebulaSnack.show(
      context,
      message: result.message,
      ok: result.ok,
    );
    if (!result.ok) return;
    if (widget.isMandatory) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => HomeScreen(controller: widget.controller),
        ),
        (_) => false,
      );
      return;
    }
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(true);
      return;
    }
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => CaregiverPanelScreen(controller: widget.controller),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const levels = ['bajo', 'medio', 'alto'];
    return PopScope<Object?>(
      canPop: !widget.isMandatory,
      child: Scaffold(
        appBar: AppBar(
          leading: widget.isMandatory
              ? null
              : BackButton(onPressed: () => Navigator.of(context).pop()),
          title: const Text('Perfil del ni\u00f1o'),
        ),
        body: CosmicBackground(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isMandatory
                              ? 'Antes de empezar, crea el perfil del ni\u00f1o.'
                              : 'Actualiza la informacion del ni\u00f1o.',
                        ),
                        const SizedBox(height: 12),
                        NebulaTextField(
                          controller: _nameController,
                          label: 'Nombre del ni\u00f1o',
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        NebulaTextField(
                          controller: _ageController,
                          label: 'Edad (opcional)',
                          keyboardType: TextInputType.number,
                          digitsOnly: true,
                          maxLength: 2,
                        ),
                        const SizedBox(height: 12),
                        NebulaTextField(
                          controller: _loginUsernameController,
                          label: 'Usuario para el ni\u00f1o',
                          validator: _validateChildUsername,
                          showValidationStatus: true,
                          validationMessage: _usernameValidationMessage,
                          onChanged: (_) {
                            setState(() {
                              _usernameAvailable =
                                  _usernameFormatValid ? null : false;
                            });
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Solo letras, numeros, punto, guion o _. Sin espacios.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF4F628A),
                                  ),
                        ),
                        const SizedBox(height: 12),
                        NebulaTextField(
                          controller: _passwordController,
                          label:
                              'Contrase\u00f1a del ni\u00f1o (m\u00ednimo 6 caracteres)',
                          obscureText: true,
                          maxLength: 32,
                        ),
                        const SizedBox(height: 12),
                        NebulaTextField(
                          controller: _passwordConfirmController,
                          label: 'Confirmar contrase\u00f1a del ni\u00f1o',
                          obscureText: true,
                          maxLength: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nivel de lenguaje',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: levels.contains(_languageLevel)
                              ? _languageLevel
                              : 'medio',
                          items: levels
                              .map(
                                (value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value.toUpperCase()),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _languageLevel = value);
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gu\u00eda r\u00e1pida: ${_languageGuideByLevel(_languageLevel)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF253966),
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Importa porque contextualiza los reportes para cuidador y terapeuta (c\u00f3mo interpretar resultados y metas). No cambia la dificultad de los juegos por ahora.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF4F628A),
                                  ),
                        ),
                        const SizedBox(height: 16),
                        NebulaPrimaryButton(
                          text: _saving ? 'Guardando...' : 'Guardar perfil',
                          onPressed: _canSave ? _save : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
