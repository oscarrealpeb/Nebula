import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final _birthDateController = TextEditingController();
  int _birthDateMillis = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final child = _editingChild;
    if (child != null) {
      _nameController.text = child.name;
      _birthDateMillis = child.birthDateMillis;
    }
    if (_birthDateMillis > 0) {
      _birthDateController.text = _formatDate(_birthDateMillis);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
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
    setState(() {
      _birthDateMillis = picked.millisecondsSinceEpoch;
      _birthDateController.text = _formatDate(_birthDateMillis);
    });
  }

  void _onBirthDateChanged(String raw) {
    final parsed = _parseBirthDate(raw);
    if (_birthDateMillis == parsed) {
      if (mounted) setState(() {});
      return;
    }
    setState(() => _birthDateMillis = parsed);
  }

  int _parseBirthDate(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 8) return 0;
    final day = int.tryParse(digits.substring(0, 2));
    final month = int.tryParse(digits.substring(2, 4));
    final year = int.tryParse(digits.substring(4, 8));
    if (day == null || month == null || year == null) return 0;

    final now = DateTime.now();
    final minDate = DateTime(now.year - 18, 1, 1);
    final maxDate = DateTime(now.year, now.month, now.day);
    final date = DateTime(year, month, day);
    final isExact = date.year == year && date.month == month && date.day == day;
    if (!isExact) return 0;
    if (date.isBefore(minDate) || date.isAfter(maxDate)) return 0;
    return date.millisecondsSinceEpoch;
  }

  String? get _birthDateErrorText {
    final typed = _birthDateController.text.trim();
    if (typed.isEmpty) return null;
    final digits = typed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 8) return 'Completa la fecha en formato DD/MM/AAAA.';
    if (_birthDateMillis <= 0) return 'Fecha invalida.';
    return null;
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
    if (_birthDateMillis <= 0) {
      await NebulaSnack.show(
        context,
        message: 'Ingresa una fecha valida en formato DD/MM/AAAA.',
        ok: false,
      );
      return;
    }
    setState(() => _saving = true);
    final result = await widget.controller.createOrUpdateChildProfile(
      childId: widget.childId,
      name: _nameController.text,
      birthDateMillis: _birthDateMillis,
      age: _computeAge(_birthDateMillis),
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
                        TextField(
                          controller: _birthDateController,
                          keyboardType: TextInputType.number,
                          inputFormatters: const [
                            _BirthDateTextInputFormatter()
                          ],
                          onChanged: _onBirthDateChanged,
                          decoration: InputDecoration(
                            labelText: 'DD/MM/AAAA',
                            hintText: '12/03/2018',
                            errorText: _birthDateErrorText,
                            suffixIcon: IconButton(
                              onPressed: _pickBirthDate,
                              icon: const Icon(Icons.cake_outlined),
                              tooltip: 'Elegir desde calendario',
                            ),
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

class _BirthDateTextInputFormatter extends TextInputFormatter {
  const _BirthDateTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = digits.length > 8 ? digits.substring(0, 8) : digits;
    final formatted = _format(limited);
    final digitsBeforeCursor = _countDigitsBeforeCursor(
      raw,
      newValue.selection.end,
    );
    final nextCursor = _cursorFromDigitIndex(digitsBeforeCursor, formatted);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: nextCursor),
    );
  }

  String _format(String digits) {
    if (digits.isEmpty) return '';
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i == 1 || i == 3) && i != digits.length - 1) {
        buffer.write('/');
      }
    }
    return buffer.toString();
  }

  int _countDigitsBeforeCursor(String text, int cursor) {
    final safeCursor = cursor.clamp(0, text.length);
    var count = 0;
    for (var i = 0; i < safeCursor; i++) {
      if (_isDigit(text.codeUnitAt(i))) count++;
    }
    return count;
  }

  int _cursorFromDigitIndex(int digitIndex, String formatted) {
    if (digitIndex <= 0) return 0;
    var seenDigits = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (_isDigit(formatted.codeUnitAt(i))) {
        seenDigits++;
        if (seenDigits == digitIndex) {
          return i + 1;
        }
      }
    }
    return formatted.length;
  }

  bool _isDigit(int codeUnit) => codeUnit >= 48 && codeUnit <= 57;
}
