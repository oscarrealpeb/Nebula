import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nebula/screens/settings/learning_content_personalization_screen.dart';

import '../../controllers/app_controller.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/nebula_button.dart';
import '../../widgets/nebula_snack.dart';
import '../../widgets/nebula_text_field.dart';
import '../welcome_screen.dart';

class CaregiverSettingsScreen extends StatefulWidget {
  const CaregiverSettingsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<CaregiverSettingsScreen> createState() =>
      _CaregiverSettingsScreenState();
}

class _CaregiverSettingsScreenState extends State<CaregiverSettingsScreen> {
  static const double _minIntensity = 0.70;
  static const double _maxIntensity = 0.85;

  late final TextEditingController _nameController;
  bool _saving = false;
  int _remaining = 0;
  Timer? _timer;
  Timer? _themeSyncTimer;
  late double _hue;
  late double _intensity;

  final _hues = const [196.0, 215.0, 255.0, 345.0, 35.0, 290.0];

  @override
  void initState() {
    super.initState();
    final user = widget.controller.currentUser!;
    _nameController = TextEditingController(text: user.name);
    _hue = user.accentHue;
    _intensity =
        user.accentIntensity.clamp(_minIntensity, _maxIntensity).toDouble();
    _remaining = widget.controller.profileResetRemaining();
    _startTickIfNeeded();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _themeSyncTimer?.cancel();
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

  Color _colorFromHue(double hue) {
    final value = _intensity.clamp(_minIntensity, _maxIntensity).toDouble();
    return HSVColor.fromAHSV(1, hue, 0.60, value).toColor();
  }

  void _applyThemeRealtime() {
    _themeSyncTimer?.cancel();
    _themeSyncTimer = Timer(const Duration(milliseconds: 70), () {
      widget.controller.setThemeColor(
        hue: _hue,
        intensity: _intensity.clamp(_minIntensity, _maxIntensity).toDouble(),
      );
    });
  }

  void _showThemeSavedSnack() {
    widget.controller.setThemeColor(
      hue: _hue,
      intensity: _intensity.clamp(_minIntensity, _maxIntensity).toDouble(),
    );
    _showSnack('Listo. El tema del cuidador ya quedó actualizado.', ok: true);
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
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var typed = '';
        var attemptedSubmit = false;
        var obscure = true;
        return StatefulBuilder(
          builder: (context, setLocalState) => AlertDialog(
            title: const Text('Eliminar cuenta'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Esta acción elimina la cuenta del cuidador y el progreso guardado en este perfil.',
                ),
                const SizedBox(height: 10),
                TextField(
                  obscureText: obscure,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña actual',
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
                    if (trimmed.isEmpty) {
                      setLocalState(() => attemptedSubmit = true);
                      return;
                    }
                    Navigator.of(dialogContext).pop(trimmed);
                  },
                ),
                if (attemptedSubmit && typed.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 2),
                    child: Text(
                      'Escribe la contraseña para continuar.',
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
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (typed.isNotEmpty) {
                    Navigator.of(dialogContext).pop(typed);
                    return;
                  }
                  setLocalState(() => attemptedSubmit = true);
                },
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
      },
    );
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
        title: const Text('Configuración cuidador'),
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
                      'Tema del cuidador',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Este color se aplica a la experiencia del cuidador, sin cambiar el tema del niño.',
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      itemCount: _hues.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.2,
                      ),
                      itemBuilder: (_, index) {
                        final hue = _hues[index];
                        final selected = hue == _hue;
                        return InkWell(
                          onTap: () {
                            setState(() => _hue = hue);
                            _applyThemeRealtime();
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: _colorFromHue(hue),
                              border: Border.all(
                                color: selected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Intensidad del color',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Slider(
                      value: _intensity,
                      min: _minIntensity,
                      max: _maxIntensity,
                      onChanged: (value) {
                        setState(() => _intensity = value);
                        _applyThemeRealtime();
                      },
                    ),
                    const SizedBox(height: 4),
                    NebulaSecondaryButton(
                      text: 'Guardar tema del cuidador',
                      onPressed: _showThemeSavedSnack,
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
                            : 'Restablecer contraseña por correo',
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
                      'Personalización para niños',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Gestiona las imágenes que verán los niños vinculados a esta cuenta.',
                    ),
                    const SizedBox(height: 10),
                    NebulaSecondaryButton(
                      text: 'Abrir personalización',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PersonalizationScreen(
                              controller: widget.controller,
                            ),
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
