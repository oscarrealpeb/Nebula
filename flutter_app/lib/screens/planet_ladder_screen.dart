import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../core/data/planet_ladder.dart';
import 'logros_screen.dart';

class PlanetLadderScreen extends StatelessWidget {
  const PlanetLadderScreen({super.key, required this.controller});

  final AppController controller;

  static const List<String> extendedOrder = [
    "Mercurio",
    "Venus",
    "Tierra",
    "Marte",
    "Júpiter",
    "Saturno",
    "Urano",
    "Neptuno",
    "Nebulosa Dorada",
    "Galaxia Prisma",
    "Universo Infinito",
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final user = controller.currentUser;
        if (user == null) return const SizedBox.shrink();

        final accent = controller.accentColor;
        final paleAccent = accent.withValues(alpha: 0.08);
        final progressStars = controller.progressStars;

        final currentPlanet = planetForStars(progressStars);
        final progress = planetProgress(progressStars);
        final remaining = starsToNextPlanet(progressStars);

        return Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: () => Navigator.of(context).pop()),
            title: const Text('Escalera de planetas'),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: planetLadder.length,
                  itemBuilder: (context, index) {
                    final planet = planetLadder[index];

                    final locked = progressStars < planet.minStars;
                    final completed = progressStars >= planet.maxStars;
                    final isCurrent = planet.name == currentPlanet.name;

                    final nextPlanetName = index < planetLadder.length - 1
                        ? planetLadder[index + 1].name
                        : "Universo Infinito";

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _PlanetCard(
                        planet: planet,
                        planetIndex: index,
                        accent: accent,
                        paleAccent: paleAccent,
                        locked: locked,
                        completed: completed,
                        isCurrent: isCurrent,
                        userStars: progressStars,
                        progress: progress,
                        remaining: remaining,
                        nextPlanetName: nextPlanetName,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _BottomTabButton(
                      label: "Planetas",
                      selected: true,
                      color: accent,
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                LogrosScreen(controller: controller),
                          ),
                        );
                      },
                      child: _BottomTabButton(
                        label: "Logros",
                        selected: false,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlanetCard extends StatelessWidget {
  const _PlanetCard({
    required this.planet,
    required this.planetIndex,
    required this.accent,
    required this.paleAccent,
    required this.locked,
    required this.completed,
    required this.isCurrent,
    required this.userStars,
    required this.progress,
    required this.remaining,
    required this.nextPlanetName,
  });

  final dynamic planet;
  final int planetIndex;
  final Color accent;
  final Color paleAccent;
  final bool locked;
  final bool completed;
  final bool isCurrent;
  final int userStars;
  final double progress;
  final int remaining;
  final String nextPlanetName;

  @override
  Widget build(BuildContext context) {
    final rewardAvatars = avatarsUnlockedAtLevel(planetIndex);
    if (locked) {
      return Opacity(
        opacity: 0.4,
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(
              color: Colors.grey,
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/planets/${planet.name}.png',
                  height: 60,
                ),
                const SizedBox(height: 6),
                Text(
                  planet.name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text('${planet.minStars}-${planet.maxStars} ⭐',
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 6),
                const Text(
                  "Planeta bloqueado 🔒",
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (completed && !isCurrent) {
      return Card(
        color: Colors.green.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Colors.green, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Image.asset(
                'assets/images/planets/${planet.name}.png',
                height: 60,
              ),
              const SizedBox(height: 6),
              Text(planet.name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              Text('${planet.minStars}-${planet.maxStars} ⭐',
                  style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 6),
              const Text("Premios obtenidos",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              if (rewardAvatars.isNotEmpty)
                Text(
                  "Avatar desbloqueado: ${rewardAvatars.join(" ")}",
                  style: const TextStyle(fontSize: 13),
                ),
              const Text("🚀  Categoría Explora y Aprende",
                  style: TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              const Text(
                "✔ Planeta completado",
                style: TextStyle(fontSize: 13, color: Colors.green),
              ),
            ],
          ),
        ),
      );
    }

    final percent = (progress * 100).clamp(0, 100).toStringAsFixed(0);

    return Card(
      color: paleAccent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: accent, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.asset(
              'assets/images/planets/${planet.name}.png',
              height: 70,
            ),
            const SizedBox(height: 6),
            Text(
              planet.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text('${planet.minStars}-${planet.maxStars} ⭐',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "$percent% del planeta explorado",
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              remaining > 0
                  ? "🚀 Solo $remaining estrellas más para viajar a $nextPlanetName"
                  : "Listo para viajar 🚀",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 6),
            const Text("Tus premios🎁:",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            if (rewardAvatars.isNotEmpty)
              Text(
                "Nuevo avatar: ${rewardAvatars.join(" ")}",
                style: const TextStyle(fontSize: 13),
              ),
            const Text("📚  Nuevas cartas en 'Explora y aprende'",
                style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _BottomTabButton extends StatelessWidget {
  const _BottomTabButton({
    required this.label,
    required this.selected,
    required this.color,
  });

  final String label;
  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      constraints: const BoxConstraints(
        minWidth: 140,
        minHeight: 50,
      ),
      decoration: BoxDecoration(
        color: selected ? color : color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
