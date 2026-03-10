import 'package:flutter/material.dart';

class NebulaSnack {
  NebulaSnack._();

  static const Color successColor = Color(0xFF45C97D);
  static const Color errorColor = Color(0xFFFF6E7A);
  static final Expando<bool> _busyByMessenger = Expando<bool>(
    'nebula_snack_busy',
  );

  static Future<void> show(
    BuildContext context, {
    required String message,
    required bool ok,
    Duration duration = const Duration(milliseconds: 1700),
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    if (_busyByMessenger[messenger] == true) {
      return;
    }

    _busyByMessenger[messenger] = true;
    try {
      final controller = messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: ok ? successColor : errorColor,
          duration: duration,
        ),
      );
      await controller.closed;
    } finally {
      _busyByMessenger[messenger] = false;
    }
  }
}
