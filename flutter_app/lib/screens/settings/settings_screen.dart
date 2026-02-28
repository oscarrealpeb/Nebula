import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../controllers/app_controller.dart';
import 'personalization_screen.dart';
import 'preferences_screen.dart';
import 'profile_screen.dart';

const Color settingsLilac = Color.fromARGB(255, 143, 115, 198); // 👈 cambia este y cambian los 3 botones

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 👈 fondo completamente blanco
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('Configuracion'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Personaliza tu aventura',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF13254B),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ajusta perfil, sonidos y colores para jugar a tu manera.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF4F628A),
                      ),
                ),
                const SizedBox(height: 18),

                _SettingsTile(
                  title: 'Perfil',
                  subtitle: 'Tu nombre, avatar, correo y seguridad.',
                  icon: Icons.badge_outlined,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(controller: controller),
                      ),
                    );
                  },
                  tileColor: controller.accentColor, // <- aquí
                ),

                const SizedBox(height: 14),

                _SettingsTile(
                  title: 'Preferencias',
                  subtitle: 'Voces, sonidos y color en tiempo real.',
                  icon: Icons.tune_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PreferencesScreen(controller: controller),
                      ),
                    );
                  },
                  tileColor: controller.accentColor, // <- aquí
                ),

                const SizedBox(height: 14),

                _SettingsTile(
                  title: 'Personalización',
                  subtitle: 'Sube fotos divertidas para animales y objetos.',
                  icon: Icons.auto_awesome_outlined,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            PersonalizationScreen(controller: controller),
                      ),
                    );
                  },
                  tileColor: controller.accentColor, // <- aquí
                ),
              ],
            ),

            // 🚀 Animación esquina inferior izquierda
            Positioned(
              bottom: 10,
              left: 10,
              child: SizedBox(
                width: 180,
                height: 180,
                child: Lottie.asset(
                  'assets/animations/settings.json', // 👈 cambia si tu archivo tiene otro nombre
                  repeat: true,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.tileColor, // <- nuevo

  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color tileColor; // <- nuevo


  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: tileColor, // 👈 mismo color para los 3
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withValues(alpha: 0.2),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.white,
        ),
      ),
    );
  }
}
