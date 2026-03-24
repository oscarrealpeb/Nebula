import 'package:flutter/material.dart';
import '../../core/data/universe_data.dart';

class UniverseCard extends StatelessWidget {
  final UniverseItem item;

  const UniverseCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Decoración con bordes redondeados y un fondo oscuro tipo "espacio"
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33), // Azul oscuro espacial
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Hero(
                  tag: 'universe_${item.title}', // Animación fluida al abrir el juego
                  child: Image.asset(
                    item.image,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Fondo de texto con un poco de contraste
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.white.withOpacity(0.05),
              child: Text(
                item.title.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}