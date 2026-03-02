import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/nebula_user.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/nebula_button.dart';
import '../widgets/nebula_snack.dart';
import '../widgets/nebula_text_field.dart';
import 'caregiver/caregiver_panel_screen.dart';
import 'portal_entry_screen.dart';

class ChildProfileSetupScreen extends StatefulWidget {
  const ChildProfileSetupScreen({
    super.key,
    required this.controller,
    this.isMandatory = false,
    this.childId = '',
  });

  final AppController controller;
  final bool isMandatory;
  final String childId;

  @override
  State<ChildProfileSetupScreen> createState() =>
      _ChildProfileSetupScreenState();
}

class _ChildProfileSetupScreenState extends State<ChildProfileSetupScreen> {
  final _nameController = TextEditingController();
  String _languageLevel = 'medio';
  int _birthDateMillis = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final child = _editingChild;
    if (child != null) {
      _nameController.text = child.name;
      _languageLevel =
          child.languageLevel.trim().isEmpty ? 'medio' : child.languageLevel;
      _birthDateMillis = child.birthDateMillis;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  ChildProfile? get _editingChild {
    final targetId = widget.childId.trim();
    if (targetId.isEmpty) return null;
    for (final child in widget.controller.childProfiles) {
      if (child.id == targetId) return child;
    }
    return null;
  }

  bool get _canSave {
    return _nameController.text.trim().isNotEmpty &&
        _birthDateMillis > 0 &&
        !_saving;
  }

  String _languageGuideByLevel(String level) {
    switch (level) {
      case 'bajo':
        return 'Bajo: usa palabras sueltas o requiere instrucciones muy cortas.';
      case 'alto':
        return 'Alto: comprende frases completas y dialogos simples.';
      case 'medio':
      default:
        return 'Medio: sigue instrucciones breves de 1 a 2 pasos.';
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDateMillis > 0
        ? DateTime.fromMillisecondsSinceEpoch(_birthDateMillis)
        : DateTime(now.year - 6, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(now.year - 18, 1, 1),
      lastDate: now,
      helpText: 'Fecha de nacimiento',
    );
    if (picked == null) return;
    setState(() => _birthDateMillis = picked.millisecondsSinceEpoch);
  }

  int _computeAge(int birthDateMillis) {
    if (birthDateMillis <= 0) return 0;
    final birth = DateTime.fromMillisecondsSinceEpoch(birthDateMillis);
    final now = DateTime.now();
    var age = now.year - birth.year;
    final beforeBirthday = now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day);
    if (beforeBirthday) age -= 1;
    return age.clamp(0, 18);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final result = await widget.controller.createOrUpdateChildProfile(
      childId: widget.childId,
      name: _nameController.text,
      birthDateMillis: _birthDateMillis,
      age: _computeAge(_birthDateMillis),
      languageLevel: _languageLevel,
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
          builder: (_) => PortalEntryScreen(controller: widget.controller),
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
    final birthDateLabel = _birthDateMillis <= 0
        ? 'Seleccionar fecha de nacimiento'
        : _formatDate(_birthDateMillis);

    return PopScope<Object?>(
      canPop: !widget.isMandatory,
      child: Scaffold(
        appBar: AppBar(
          leading: widget.isMandatory
              ? null
              : BackButton(onPressed: () => Navigator.of(context).pop()),
          title:
              Text(_editingChild == null ? 'Perfil del niño' : 'Editar niño'),
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
                              ? 'Antes de continuar, registra al menos un perfil de niño.'
                              : 'Completa la información del niño.',
                        ),
                        const SizedBox(height: 12),
                        NebulaTextField(
                          controller: _nameController,
                          label: 'Nombre del niño',
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Fecha de nacimiento',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          onPressed: _pickBirthDate,
                          icon: const Icon(Icons.cake_outlined),
                          label: Text(birthDateLabel),
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
                          'Guía rápida: ${_languageGuideByLevel(_languageLevel)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF253966),
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Este valor no cambia la lógica del juego. Se usa para contextualizar reportes y recomendaciones de acompañamiento.',
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

  String _formatDate(int millis) {
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}
