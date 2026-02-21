import 'package:flutter/material.dart';

Future<int?> showStarDifficultySheet(BuildContext context) {
  return showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Elige tu reto',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Selecciona cuantas estrellas quieres en esta actividad.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Row(
              children: List.generate(3, (index) {
                final value = index + 1;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: value < 3 ? 10 : 0),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(value),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          value,
                          (_) => const Icon(Icons.star, size: 16),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    },
  );
}
