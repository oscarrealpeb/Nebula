import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../services/narration_service.dart';

Future<int?> showStarDifficultySheet(
  BuildContext context, {
  required AppController controller,
  int maxEnabledStars = 3,
}) {
  final safeMaxEnabledStars = maxEnabledStars.clamp(1, 3);
  bool played = false;
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true, // permite que ocupe más altura
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      if (!played) {
        played = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NarrationService.instance.play(
            controller,
            key: 'niveles',
          );
        });
      }
      // Tamaño de la sheet: mitad de la pantalla
      return FractionallySizedBox(
        heightFactor: 0.5, // 50% de la pantalla
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Elige tu desafío',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Selecciona cuantas estrellas quieres en esta actividad.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(3, (index) {
                  final value = index + 1;
                  final isEnabled = value <= safeMaxEnabledStars;

                  // Colores por cantidad de estrellas
                  Color bgColor;
                  if (!isEnabled) {
                    bgColor = Colors.grey.shade300;
                  } else if (value == 1) {
                    bgColor = const Color.fromARGB(233, 129, 199, 132);
                  } else if (value == 2) {
                    bgColor = const Color.fromARGB(237, 255, 184, 77);
                  } else {
                    bgColor = const Color.fromARGB(226, 255, 136, 77); // no rojo
                  }

                  return Expanded(
                    child: GestureDetector(
                      onTap: isEnabled ? () => Navigator.of(context).pop(value) : null,
                      child: Container(
                        height: 60,
                        margin: EdgeInsets.only(right: value < 3 ? 12 : 0),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.black26,
                            width: 1.5,
                          ),
                        ),
                        
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            value,
                            (_) => Icon(
                              Icons.star,
                              size: 20,
                              color: isEnabled ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      );
    },
  );
}

