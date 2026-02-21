import 'package:flutter/material.dart';

import '../../controllers/app_controller.dart';
import '../../widgets/cosmic_background.dart';
import 'personalization_screen.dart';
import 'preferences_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('Configuracion'),
      ),
      body: CosmicBackground(
        child: ListView(
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
            const SizedBox(height: 14),
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
            ),
            const SizedBox(height: 12),
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
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              title: 'Personalizacion',
              subtitle: 'Sube fotos divertidas para animales y objetos.',
              icon: Icons.auto_awesome_outlined,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PersonalizationScreen(controller: controller),
                  ),
                );
              },
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
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withValues(alpha: 0.11),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

