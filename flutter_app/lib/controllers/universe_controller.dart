import 'package:flutter/material.dart';

// Rutas ajustadas a tu imagen (sin carpeta explore)
import '../core/data/universe_data.dart'; 
import '../screens/universe_game_screen.dart'; // Ruta directa
import '../widgets/universe_card.dart';        // Ruta directa

class UniverseGrid extends StatelessWidget {
  const UniverseGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: universeItems.length,
      itemBuilder: (context, i) {
        final item = universeItems[i];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UniverseGameScreen(item: item),
              ),
            );
          },
          child: UniverseCard(item: item),
        );
      },
    );
  }
}