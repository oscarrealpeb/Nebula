import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/nebula_button.dart';
import '../widgets/nebula_snack.dart';
import 'caregiver/caregiver_panel_screen.dart';
import 'home_screen.dart';

enum _PortalStep {
  role,
  child,
}

class PortalEntryScreen extends StatefulWidget {
  const PortalEntryScreen({
    super.key,
    required this.controller,
    this.flashMessage = '',
    this.flashOk = true,
  });

  final AppController controller;
  final String flashMessage;
  final bool flashOk;

  @override
  State<PortalEntryScreen> createState() => _PortalEntryScreenState();
}

class _PortalEntryScreenState extends State<PortalEntryScreen> {
  bool _childSubmitting = false;
  bool _caregiverSubmitting = false;
  String _selectedChildId = '';
  _PortalStep _step = _PortalStep.role;

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
    final flash = widget.flashMessage.trim();
    if (flash.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        NebulaSnack.show(context, message: flash, ok: widget.flashOk);
      });
    }
  }

  void _showSnack(String message, {required bool ok}) {
    NebulaSnack.show(context, message: message, ok: ok);
  }

  Future<void> _goToChildStep() async {
    if (_childSubmitting || _caregiverSubmitting) return;
    if (widget.controller.childProfiles.isEmpty) {
      _showSnack(
        'No hay perfiles de ni\u00f1o disponibles. Crea uno desde la Zona cuidador.',
        ok: false,
      );
      return;
    }
    setState(() => _step = _PortalStep.child);
  }

  Future<void> _enterChild() async {
    if (_childSubmitting || _caregiverSubmitting) return;
    final target = _selectedChildId.trim();
    if (target.isEmpty) {
      _showSnack('Selecciona un perfil de ni\u00f1o para continuar.',
          ok: false);
      return;
    }
    setState(() => _childSubmitting = true);
    final result = await widget.controller.enterChildPortal(target);
    if (!mounted) return;
    setState(() => _childSubmitting = false);
    if (!result.ok) {
      _showSnack(result.message, ok: false);
      return;
    }
    final childName = widget.controller.childProfile?.name.trim().isNotEmpty ==
            true
        ? widget.controller.childProfile!.name.trim()
        : 'explorador';
    _openChildScreen(
      flashMessage: '¡Hola, $childName!',
      flashOk: true,
    );
  }

  Future<void> _promptCaregiverPassword() async {
    if (_childSubmitting || _caregiverSubmitting) return;
    final password = await _askCaregiverPassword();
    if (!mounted || password == null) return;
    await _enterCaregiver(password);
  }

  Future<void> _enterCaregiver(String password) async {
    if (_childSubmitting || _caregiverSubmitting) return;
    setState(() => _caregiverSubmitting = true);
    final result = await widget.controller.enterCaregiverPortal(
      password: password,
    );
    if (!mounted) return;
    setState(() => _caregiverSubmitting = false);
    if (!result.ok) {
      _showSnack(result.message, ok: false);
      return;
    }
    _openCaregiverScreen(
      flashMessage: result.message,
      flashOk: true,
    );
  }

  void _openChildScreen({
    String flashMessage = '',
    bool flashOk = true,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            controller: widget.controller,
            flashMessage: flashMessage,
            flashOk: flashOk,
          ),
        ),
      );
    });
  }

  void _openCaregiverScreen({
    String flashMessage = '',
    bool flashOk = true,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CaregiverPanelScreen(
            controller: widget.controller,
            flashMessage: flashMessage,
            flashOk: flashOk,
          ),
        ),
      );
    });
  }

  Future<String?> _askCaregiverPassword() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        var typed = '';
        var resetSending = false;
        var resetMessage = '';
        var resetOk = false;
        var obscure = true;

        return StatefulBuilder(
          builder: (context, setLocalState) => AlertDialog(
            title: const Text('Entrar como cuidador'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  obscureText: obscure,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña del cuidador',
                    suffixIcon: IconButton(
                      onPressed: () => setLocalState(() => obscure = !obscure),
                      icon: Icon(
                        obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  onChanged: (value) =>
                      setLocalState(() => typed = value.trim()),
                  onSubmitted: (value) {
                    final trimmed = value.trim();
                    if (trimmed.isEmpty) return;
                    Navigator.of(dialogContext).pop(trimmed);
                  },
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: resetSending
                      ? null
                      : () async {
                          final email =
                              widget.controller.currentUser?.email.trim() ?? '';
                          if (email.isEmpty) {
                            setLocalState(() {
                              resetMessage =
                                  'No hay correo del cuidador para recuperar.';
                              resetOk = false;
                            });
                            return;
                          }
                          setLocalState(() {
                            resetSending = true;
                            resetMessage = '';
                          });
                          final result = await widget.controller
                              .requestLoginPasswordReset(email);
                          if (!dialogContext.mounted) return;
                          setLocalState(() {
                            resetSending = false;
                            resetMessage = result.message;
                            resetOk = result.ok;
                          });
                        },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    resetSending
                        ? 'Enviando correo...'
                        : 'Olvidé mi contraseña',
                  ),
                ),
                if (resetMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      resetMessage,
                      style: TextStyle(
                        fontSize: 12,
                        color: resetOk
                            ? const Color(0xFF1B8B3B)
                            : const Color(0xFFB3261E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: typed.isEmpty
                    ? null
                    : () => Navigator.of(dialogContext).pop(typed),
                child: const Text('Entrar'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = widget.controller.childProfiles;
    final loading = _childSubmitting || _caregiverSubmitting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('\u00bfQui\u00e9n usa la aplicaci\u00f3n?'),
      ),
      body: CosmicBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _step == _PortalStep.role
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selecciona como quieres entrar:',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 12),
                          NebulaPrimaryButton(
                            text: 'Entrar como ni\u00f1o',
                            onPressed: loading ? null : _goToChildStep,
                          ),
                          const SizedBox(height: 10),
                          NebulaSecondaryButton(
                            text: _caregiverSubmitting
                                ? 'Validando...'
                                : 'Entrar como cuidador',
                            onPressed:
                                loading ? null : _promptCaregiverPassword,
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selecciona el perfil de ni\u00f1o',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          if (children.isEmpty)
                            const Text(
                              'No hay perfiles disponibles. Vuelve y entra como cuidador para crear uno.',
                            )
                          else
                            ...children.map((child) {
                              final selected = _selectedChildId == child.id;
                              return ListTile(
                                selected: selected,
                                selectedTileColor: const Color(0xFFEAF3FF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                onTap: () => setState(
                                  () => _selectedChildId = child.id,
                                ),
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
                                      ? 'Ni\u00f1o sin nombre'
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
                                _childSubmitting ? 'Entrando...' : 'Continuar',
                            onPressed: (loading || children.isEmpty)
                                ? null
                                : _enterChild,
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: loading
                                ? null
                                : () =>
                                    setState(() => _step = _PortalStep.role),
                            child: const Text('Volver'),
                          ),
                        ],
                      ),
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


