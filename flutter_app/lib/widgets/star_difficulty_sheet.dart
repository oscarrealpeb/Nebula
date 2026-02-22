import 'package:flutter/material.dart';

Future<int?> showStarDifficultySheet(BuildContext context) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true, // permite que ocupe más altura
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      // Tamaño de la sheet: mitad de la pantalla
      return FractionallySizedBox(
        heightFactor: 0.5, // 50% de la pantalla
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
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
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(3, (index) {
                  final value = index + 1;

                  // Colores por cantidad de estrellas
                  Color bgColor;
                  if (value == 1) {
                    bgColor = const Color.fromARGB(233, 129, 199, 132);
                  } else if (value == 2) {
                    bgColor = const Color.fromARGB(237, 255, 184, 77);
                  } else {
                    bgColor = const Color.fromARGB(226, 255, 136, 77); // no rojo
                  }

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(value),
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
                            (_) => const Icon(Icons.star, size: 20, color: Colors.white),
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