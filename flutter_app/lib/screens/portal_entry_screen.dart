import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/nebula_button.dart';
import '../widgets/nebula_snack.dart';
import '../widgets/nebula_text_field.dart';

class PortalEntryScreen extends StatefulWidget {
  const PortalEntryScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<PortalEntryScreen> createState() => _PortalEntryScreenState();
}

class _PortalEntryScreenState extends State<PortalEntryScreen> {
  final _passwordController = TextEditingController();
  bool _childSubmitting = false;
  bool _caregiverSubmitting = false;
  String _selectedChildId = '';

  @override
  void initState() {
    super.initState();
    final children = widget.controller.childProfiles;
    final current = widget.controller.childProfile;
    if (current != null) {
      _selectedChildId = current.id;
    } else if (children.isNotEmpty) {
      _selectedChildId = children.first.id;
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {required bool ok}) {
    NebulaSnack.show(context, message: message, ok: ok);
  }

  Future<void> _enterChild() async {
    if (_childSubmitting || _caregiverSubmitting) return;
    final target = _selectedChildId.trim();
    if (target.isEmpty) {
      _showSnack('Selecciona un perfil de niño para continuar.', ok: false);
      return;
    }
    setState(() => _childSubmitting = true);
    final result = await widget.controller.enterChildPortal(target);
    if (!mounted) return;
    setState(() => _childSubmitting = false);
    if (!result.ok) {
      _showSnack(result.message, ok: false);
    }
  }

  Future<void> _enterCaregiver() async {
    if (_childSubmitting || _caregiverSubmitting) return;
    setState(() => _caregiverSubmitting = true);
    final result = await widget.controller.enterCaregiverPortal(
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _caregiverSubmitting = false);
    if (!result.ok) {
      _showSnack(result.message, ok: false);
      return;
    }
    _passwordController.clear();
  }

  Future<void> _logout() async {
    await widget.controller.logout();
  }

  @override
  Widget build(BuildContext context) {
    final children = widget.controller.childProfiles;
    final caregiverEmail = widget.controller.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('¿Quién usa la aplicación?'),
      ),
      body: CosmicBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Entrar como niño',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Elige el perfil del niño para jugar.',
                    ),
                    const SizedBox(height: 10),
                    ...children.map((child) {
                      final selected = _selectedChildId == child.id;
                      return ListTile(
                        selected: selected,
                        selectedTileColor: const Color(0xFFEAF3FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        onTap: () =>
                            setState(() => _selectedChildId = child.id),
                        leading: Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: selected
                              ? const Color(0xFF1B8B3B)
                              : const Color(0xFF5A6E97),
                        ),
                        title: Text(
                          child.name.trim().isEmpty
                              ? 'Niño sin nombre'
                              : child.name,
                        ),
                        subtitle: Text(
                          child.birthDateMillis > 0
                              ? 'Nacimiento: ${_formatDate(child.birthDateMillis)}'
                              : 'Nacimiento no definido',
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    NebulaPrimaryButton(
                      text:
                          _childSubmitting ? 'Entrando...' : 'Entrar como niño',
                      onPressed: (_childSubmitting || _caregiverSubmitting)
                          ? null
                          : _enterChild,
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
                      'Entrar como cuidador',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      caregiverEmail.isEmpty
                          ? 'Confirma tu contraseña para abrir la zona cuidador.'
                          : 'Cuenta: $caregiverEmail\nConfirma tu contraseña para abrir la zona cuidador.',
                    ),
                    const SizedBox(height: 10),
                    NebulaTextField(
                      controller: _passwordController,
                      label: 'Contraseña del cuidador',
                      obscureText: true,
                    ),
                    const SizedBox(height: 10),
                    NebulaSecondaryButton(
                      text: _caregiverSubmitting
                          ? 'Validando...'
                          : 'Entrar como cuidador',
                      onPressed: (_childSubmitting || _caregiverSubmitting)
                          ? null
                          : _enterCaregiver,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _logout,
                child: const Text('Cerrar sesión'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(int millis) {
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}
