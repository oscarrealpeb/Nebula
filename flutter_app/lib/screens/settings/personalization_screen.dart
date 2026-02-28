import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/app_controller.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/nebula_button.dart';
import '../../widgets/nebula_snack.dart';

class PersonalizationScreen extends StatefulWidget {
  const PersonalizationScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends State<PersonalizationScreen> {
  final _picker = ImagePicker();
  final _targets = const ['perro', 'gato', 'pelota', 'carro', 'arbol', 'luna'];
  String? _busyKey;

  Future<void> _pick(String target, ImageSource source) async {
    setState(() => _busyKey = target);
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 75);
      if (file != null) {
        await widget.controller.updateCustomImage(
          key: target,
          imagePath: file.path,
        );
      }
      if (!mounted) return;
      NebulaSnack.show(
        context,
        message:
            'Imagen guardada. Pendiente conectar validacion IA (ML Kit/Firebase).',
        ok: true,
      );
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  Future<void> _openSourceSheet(String target) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar foto'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pick(target, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Usar galeria'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pick(target, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.controller.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('Personalización'),
      ),
      body: CosmicBackground(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Personaliza animales y objetos. Puedes usar fotos propias o dejar la imagen predeterminada.',
            ),
            const SizedBox(height: 12),
            ..._targets.map((target) {
              final imagePath = user.customImages[target];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 62,
                            height: 62,
                            color: const Color(0xFFEAF0FF),
                            child: imagePath == null
                                ? const Icon(Icons.image_outlined)
                                : Image(
                                    image: FileImage(File(imagePath)),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                target.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                imagePath == null
                                    ? 'Imagen predeterminada'
                                    : 'Imagen personalizada',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed:
                              _busyKey == target ? null : () => _openSourceSheet(target),
                          icon: _busyKey == target
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.edit_outlined),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            NebulaSecondaryButton(
              text: 'Mantener imagenes predeterminadas',
              onPressed: () {
                NebulaSnack.show(
                  context,
                  message: 'Perfecto, dejamos el set original.',
                  ok: true,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
