import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NebulaTextField extends StatefulWidget {
  const NebulaTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.maxLength,
    this.digitsOnly = false,
    this.validator,
    this.onChanged,
    this.showValidationStatus = false,
    this.validationMessage,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLength;
  final bool digitsOnly;
  final Future<bool> Function(String)? validator;
  final void Function(String)? onChanged;
  final bool showValidationStatus;
  final String? validationMessage;

  @override
  State<NebulaTextField> createState() => _NebulaTextFieldState();
}

class _NebulaTextFieldState extends State<NebulaTextField> {
  late bool _obscure;
  Timer? _debounceTimer;
  bool? _validationResult; // null = no validado, true = válido, false = inválido
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant NebulaTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.obscureText && widget.obscureText) {
      _obscure = true;
    }
  }

  void _onTextChanged() {
    widget.onChanged?.call(widget.controller.text);

    if (widget.validator == null || !widget.showValidationStatus) return;

    // Cancelar validación anterior
    _debounceTimer?.cancel();

    // Si el campo está vacío, limpiar validación
    if (widget.controller.text.isEmpty) {
      setState(() {
        _validationResult = null;
        _isValidating = false;
      });
      return;
    }

    // Iniciar debounce de 500ms
    setState(() => _isValidating = true);
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      final text = widget.controller.text;
      if (text.isEmpty) return;

      final result = await widget.validator!(text);
      if (!mounted) return;
      setState(() {
        _validationResult = result;
        _isValidating = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final inputFormatters = <TextInputFormatter>[
      if (widget.digitsOnly) FilteringTextInputFormatter.digitsOnly,
      if (widget.maxLength != null)
        LengthLimitingTextInputFormatter(widget.maxLength),
    ];

    final suffixIcon = _buildSuffixIcon();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: widget.controller,
          obscureText: _obscure,
          keyboardType: widget.keyboardType,
          inputFormatters: inputFormatters.isEmpty ? null : inputFormatters,
          decoration: InputDecoration(
            labelText: widget.label,
            suffixIcon: suffixIcon,
            errorBorder: _validationResult == false
                ? const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFC64040)),
                  )
                : null,
          ),
        ),
        if (widget.showValidationStatus &&
            widget.controller.text.isNotEmpty &&
            _validationResult == false &&
            widget.validationMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.validationMessage!,
              style: const TextStyle(color: Color(0xFFC64040), fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    // Si es campo de contraseña
    if (widget.obscureText) {
      return IconButton(
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(
          _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        ),
      );
    }

    // Si hay validación en tiempo real
    if (!widget.showValidationStatus || widget.validator == null) {
      return null;
    }

    if (widget.controller.text.isEmpty) {
      return null;
    }

    if (_isValidating) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_validationResult == true) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Icon(Icons.check_circle, color: Color(0xFF2FA56A)),
      );
    }

    if (_validationResult == false) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Icon(Icons.cancel, color: Color(0xFFC64040)),
      );
    }

    return null;
  }
}
