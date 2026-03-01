import 'dart:async';

import 'package:flutter/material.dart';

import '../../controllers/app_controller.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/nebula_button.dart';
import '../../widgets/nebula_snack.dart';
import '../../widgets/nebula_text_field.dart';
import '../settings/personalization_screen.dart';
import '../welcome_screen.dart';

class CaregiverSettingsScreen extends StatefulWidget {
  const CaregiverSettingsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<CaregiverSettingsScreen> createState() =>
      _CaregiverSettingsScreenState();
}

class _CaregiverSettingsScreenState extends State<CaregiverSettingsScreen> {
  late final TextEditingController _nameController;
  bool _saving = false;
  int _remaining = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final user = widget.controller.currentUser!;
    _nameController = TextEditingController(text: user.name);
    _remaining = widget.controller.profileResetRemaining();
    _startTickIfNeeded();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
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

  Future<void> _saveName() async {
    final user = widget.controller.currentUser;
    if (user == null) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack('Escribe un nombre para continuar.', ok: false);
      return;
    }

    setState(() => _saving = true);
    final result = await widget.controller.saveProfile(
      name: name,
      username: user.username,
      avatarIndex: user.avatarIndex,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    _showSnack(result.message, ok: result.ok);
  }

  Future<void> _requestPasswordReset() async {
    if (_remaining > 0) return;
    final result = await widget.controller.requestProfilePasswordReset();
    if (!mounted) return;
    _showSnack(result.message, ok: result.ok);
    setState(() => _remaining = widget.controller.profileResetRemaining());
    _startTickIfNeeded();
  }

  Future<String?> _askCurrentPasswordForDelete() async {
    final passwordController = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Eliminar cuenta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Esta accion elimina la cuenta del cuidador y el progreso guardado en este perfil.',
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
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      if (confirmed != true) return null;
      final typed = passwordController.text.trim();
      if (typed.isEmpty) {
        _showSnack('Escribe la contrasena para continuar.', ok: false);
        return null;
      }
      return typed;
    } finally {
      passwordController.dispose();
    }
  }

  Future<void> _deleteAccount() async {
    final password = await _askCurrentPasswordForDelete();
    if (!mounted || password == null) return;
    final result = await widget.controller.requestDeleteAccount(
      password: password,
    );
    if (!mounted) return;
    if (!result.ok) {
      _showSnack(result.message, ok: false);
      return;
    }
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
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.controller.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('Configuracion cuidador'),
      ),
      body: CosmicBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cuenta del cuidador',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    NebulaTextField(
                      controller: _nameController,
                      label: 'Nombre',
                    ),
                    const SizedBox(height: 10),
                    Text('Correo: ${user.email}'),
                    const SizedBox(height: 6),
                    Text(
                      'En perfil de cuidador no se usa avatar ni apodo.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    NebulaPrimaryButton(
                      text: _saving ? 'Guardando...' : 'Guardar cambios',
                      onPressed: _saving ? null : _saveName,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seguridad',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _remaining > 0 ? null : _requestPasswordReset,
                      icon: const Icon(Icons.password_rounded),
                      label: Text(
                        _remaining > 0
                            ? 'Espera ${widget.controller.formatSeconds(_remaining)}'
                            : 'Restablecer contrasena por correo',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personalizacion para ninos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Gestiona las imagenes que veran los ninos vinculados a esta cuenta.',
                    ),
                    const SizedBox(height: 10),
                    NebulaSecondaryButton(
                      text: 'Abrir personalizacion',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PersonalizationScreen(
                                controller: widget.controller),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _deleteAccount,
              child: const Text(
                'Eliminar cuenta',
                style: TextStyle(color: NebulaSnack.errorColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
