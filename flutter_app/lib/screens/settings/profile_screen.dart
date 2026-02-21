import 'dart:async';

import 'package:flutter/material.dart';

import '../../controllers/app_controller.dart';
import '../../core/data/avatar_catalog.dart';
import '../../core/data/planet_ladder.dart';
import '../../core/theme/color_utils.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/nebula_button.dart';
import '../../widgets/nebula_text_field.dart';
import '../welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  int _avatarIndex = 0;
  int _remaining = 0;
  Timer? _timer;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = widget.controller.currentUser!;
    _nameController = TextEditingController(text: user.name);
    _usernameController = TextEditingController(text: user.username);
    _avatarIndex = user.avatarIndex;
    _remaining = widget.controller.profileResetRemaining();
    _startTickIfNeeded();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _startTickIfNeeded() {
    _timer?.cancel();
    if (_remaining <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = widget.controller.profileResetRemaining();
      if (!mounted) return;
      setState(() => _remaining = current);
      if (current <= 0) _timer?.cancel();
    });
  }

  void _showSnack(String message, {required bool ok}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ok ? const Color(0xFF2FA56A) : const Color(0xFFC64040),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    final result = await widget.controller.saveProfile(
      name: _nameController.text,
      username: _usernameController.text,
      avatarIndex: _avatarIndex,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    _showSnack(result.message, ok: result.ok);
  }

  Future<void> _resetPassword() async {
    if (_remaining > 0) return;
    final result = await widget.controller.requestProfilePasswordReset();
    if (!mounted) return;
    _showSnack(result.message, ok: result.ok);
    setState(() => _remaining = widget.controller.profileResetRemaining());
    _startTickIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.controller.currentUser;
    if (user == null) return const SizedBox.shrink();

    final planet = planetForStars(user.stars);
    final progress = planetProgress(user.stars);
    final unlockedCount = unlockedAvatarCount(user.stars);
    final avatar = avatarCatalog[user.avatarIndex.clamp(0, avatarCatalog.length - 1)];
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('Perfil'),
      ),
      body: CosmicBackground(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              child: Ink(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tint(shiftHue(primary, -8), 0.15),
                      tint(shiftHue(primary, 22), 0.18),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white24,
                      child: Text(avatar, style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.username,
                            style: const TextStyle(
                              color: Color(0xFF22335D),
                              fontWeight: FontWeight.w800,
                              fontSize: 19,
                            ),
                          ),
                          Text(
                            'Planeta ${planet.name}  |  ${user.stars} estrellas',
                            style: const TextStyle(
                              color: Color(0xFF3A4B74),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              minHeight: 7,
                              value: progress,
                              backgroundColor: const Color(0xFFE8ECF5),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFFFD86B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Row(
                  children: [
                    Text(
                      widget.controller.isOnline ? 'Estado: En linea' : 'Estado: Sin internet',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Switch(
                      value: widget.controller.isOnline,
                      onChanged: widget.controller.setOnline,
                    ),
                  ],
                ),
              ),
            ),
            if (!widget.controller.isOnline)
              const Padding(
                padding: EdgeInsets.only(top: 6, bottom: 6),
                child: Text(
                  'Sin internet: algunos avances podrian no guardarse en la nube.',
                  style: TextStyle(color: Color(0xFFC64040)),
                ),
              ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    NebulaTextField(
                      controller: _nameController,
                      label: 'Como te llamas?',
                    ),
                    const SizedBox(height: 12),
                    NebulaTextField(
                      controller: _usernameController,
                      label: 'Tu apodo genial',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Elige tu avatar favorito',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          '$unlockedCount/${avatarCatalog.length} desbloqueados',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      itemCount: avatarCatalog.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemBuilder: (_, index) {
                        final unlocked = index < unlockedCount;
                        final selected = index == _avatarIndex;
                        return InkWell(
                          onTap: unlocked ? () => setState(() => _avatarIndex = index) : null,
                          borderRadius: BorderRadius.circular(16),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: unlocked ? Colors.white : const Color(0xFFE8E8E8),
                              border: Border.all(
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                width: 1.8,
                              ),
                            ),
                            child: Center(
                              child: unlocked
                                  ? Text(
                                      avatarCatalog[index],
                                      style: const TextStyle(fontSize: 24),
                                    )
                                  : const Icon(Icons.lock_rounded),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seguridad',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text('Tu correo actual: ${user.email}'),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () async {
                        final result = await widget.controller.requestEmailChange();
                        if (!context.mounted) return;
                        _showSnack(result.message, ok: result.ok);
                      },
                      icon: const Icon(Icons.mark_email_read_outlined),
                      label: const Text('Cambiar correo'),
                    ),
                    TextButton(
                      onPressed: _remaining > 0 ? null : _resetPassword,
                      child: Text(
                        _remaining > 0
                            ? 'Espera ${widget.controller.formatSeconds(_remaining)}'
                            : 'Quiero cambiar mi contrasena',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            NebulaPrimaryButton(
              text: _saving ? 'Guardando...' : 'Guardar y continuar',
              onPressed: _saving ? null : _saveProfile,
            ),
            const SizedBox(height: 12),
            NebulaSecondaryButton(
              text: 'Cerrar sesion',
              onPressed: () async {
                await widget.controller.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => WelcomeScreen(controller: widget.controller),
                  ),
                  (_) => false,
                );
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                final result = await widget.controller.requestDeleteAccount();
                if (!context.mounted) return;
                _showSnack(result.message, ok: result.ok);
              },
              child: const Text(
                'Borrar cuenta',
                style: TextStyle(color: Color(0xFFC64040)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

