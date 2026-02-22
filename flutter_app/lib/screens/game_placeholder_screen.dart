import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/nebula_button.dart';
import '../widgets/nebula_snack.dart';

class GamePlaceholderScreen extends StatelessWidget {
  const GamePlaceholderScreen({
    super.key,
    required this.controller,
    required this.gameName,
    required this.difficultyStars,
  });

  final AppController controller;
  final String gameName;
  final int difficultyStars;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: Text(gameName),
      ),
      body: CosmicBackground(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                      'Reto elegido',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(
                          difficultyStars,
                          (_) => const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.star, color: Colors.amber),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Narrador activo: ${controller.currentUser?.selectedNarratorId ?? 'narrator_1'}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Muy bien. Este espacio queda listo para conectar la logica real del minijuego.',
              ),
              const Spacer(),
              NebulaPrimaryButton(
                text: 'Completar reto (+120 estrellas)',
                onPressed: () async {
                  await controller.addStars(120);
                  if (!context.mounted) return;
                  NebulaSnack.show(
                    context,
                    message: 'Genial, ganaste 120 estrellas.',
                    ok: true,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
