import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/portal_role.dart';
import '../screens/portal_entry_screen.dart';

class ChildTimeLimitGuard extends StatefulWidget {
  const ChildTimeLimitGuard({
    super.key,
    required this.controller,
    required this.child,
  });

  final AppController controller;
  final Widget child;

  @override
  State<ChildTimeLimitGuard> createState() => _ChildTimeLimitGuardState();
}

class _ChildTimeLimitGuardState extends State<ChildTimeLimitGuard> {
  Timer? _timer;
  bool _dialogVisible = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_checkLimit);
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkLimit();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkLimit());
  }

  @override
  void didUpdateWidget(covariant ChildTimeLimitGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_checkLimit);
      widget.controller.addListener(_checkLimit);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_checkLimit);
    _timer?.cancel();
    super.dispose();
  }

  void _checkLimit() {
    if (!mounted) return;
    if (widget.controller.activePortalRole != PortalRole.child) return;
    widget.controller.evaluateChildTimeLimit();
    if (widget.controller.shouldShowChildTimeLimitDialog && !_dialogVisible) {
      _showLimitDialog();
    }
  }

  Future<void> _showLimitDialog() async {
    _dialogVisible = true;
    final accent = widget.controller.accentColor;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Tu tiempo de juego ha terminado'),
        content: const Text(
          'Pídele ayuda a un adulto para volver a jugar.',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    _dialogVisible = false;
    widget.controller.acknowledgeChildTimeLimitDialog();
    if (!widget.controller.isChildGameActive) {
      widget.controller.exitChildPortalDueToLimit();
      _redirectToPortalSelection();
    }
  }

  void _redirectToPortalSelection() {
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => PortalEntryScreen(
          controller: widget.controller,
          flashMessage: widget.controller.childTimeLimitMessage,
          flashOk: false,
        ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
