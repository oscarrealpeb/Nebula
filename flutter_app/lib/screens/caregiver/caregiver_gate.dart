import 'package:flutter/material.dart';

import '../../controllers/app_controller.dart';
import '../../widgets/nebula_snack.dart';
import '../../widgets/nebula_text_field.dart';

Future<bool> ensureCaregiverAccess(
  BuildContext context,
  AppController controller,
) async {
  if (!controller.parentalPinEnabled) {
    final allow = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Zona cuidador'),
        content: const Text(
          'No hay PIN parental activo. Puedes entrar y luego configurarlo en seguridad.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    return allow == true;
  }

  final pinController = TextEditingController();
  try {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Zona cuidador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Escribe el PIN parental para continuar.'),
            const SizedBox(height: 10),
            NebulaTextField(
              controller: pinController,
              label: 'PIN parental',
              obscureText: true,
              digitsOnly: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
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
            child: const Text('Entrar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    final valid =
        controller.verifyCurrentParentalPin(pinController.text.trim());
    if (!valid && context.mounted) {
      await NebulaSnack.show(
        context,
        message: 'PIN incorrecto. Intenta nuevamente.',
        ok: false,
      );
    }
    return valid;
  } finally {
    pinController.dispose();
  }
}
