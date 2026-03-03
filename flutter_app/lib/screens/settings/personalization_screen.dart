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
  String _selectedChildId = '';

  @override
  void initState() {
    super.initState();
    final selected = widget.controller.childProfile?.id.trim() ?? '';
    if (selected.isNotEmpty) {
      _selectedChildId = selected;
      return;
    }
    final children = widget.controller.childProfiles;
    if (children.isNotEmpty) {
      _selectedChildId = children.first.id;
    }
  }

  Future<void> _pick({
    required String target,
    required String childId,
    required ImageSource source,
  }) async {
    final busy = '$childId::$target';
    setState(() => _busyKey = busy);
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 75);
      if (file != null) {
        await widget.controller.updateCustomImage(
          key: target,
          imagePath: file.path,
          childId: childId,
        );
      }
      if (!mounted || file == null) return;
      final childName = _childNameById(childId);
      NebulaSnack.show(
        context,
        message: 'Imagen guardada para $childName.',
        ok: true,
      );
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  Future<String?> _askTargetChild() async {
    final children = widget.controller.childProfiles;
    if (children.isEmpty) {
      NebulaSnack.show(
        context,
        message: 'Primero crea un perfil de niño.',
        ok: false,
      );
      return null;
    }
    if (children.length == 1) return children.first.id;

    var selected = _selectedChildId;
    if (selected.trim().isEmpty ||
        !children.any((item) => item.id == selected.trim())) {
      selected = children.first.id;
    }

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Aplicar imagen a'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...children.map((child) {
                final isSelected = selected == child.id;
                return ListTile(
                  onTap: () => setLocalState(() => selected = child.id),
                  leading: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isSelected
                        ? const Color(0xFF1B8B3B)
                        : const Color(0xFF5A6E97),
                  ),
                  title: Text(
                    child.name.trim().isEmpty ? 'Niño sin nombre' : child.name,
                  ),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(selected),
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSourceSheet(String target) async {
    final childId = await _askTargetChild();
    if (!mounted || childId == null) return;
    if (_selectedChildId != childId) {
      setState(() => _selectedChildId = childId);
    }

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
                  await _pick(
                    target: target,
                    childId: childId,
                    source: ImageSource.camera,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Usar galeria'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pick(
                    target: target,
                    childId: childId,
                    source: ImageSource.gallery,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _childNameById(String childId) {
    for (final child in widget.controller.childProfiles) {
      if (child.id != childId) continue;
      final name = child.name.trim();
      return name.isEmpty ? 'niño sin nombre' : name;
    }
    return 'este perfil';
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.controller.currentUser;
    if (user == null) return const SizedBox.shrink();
    final children = widget.controller.childProfiles;

    var previewChildId = _selectedChildId.trim();
    if (previewChildId.isEmpty ||
        !children.any((item) => item.id == previewChildId)) {
      previewChildId = children.isNotEmpty ? children.first.id : '';
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('Personalización de contenido'),
      ),
      body: CosmicBackground(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Aquí el cuidador edita imágenes de animales y objetos para cada niño vinculado.',
            ),
            const SizedBox(height: 8),
            if (children.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'No hay perfiles de niño todavía. Crea uno desde Zona cuidador.',
                  ),
                ),
              )
            else if (children.length == 1)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.child_care_rounded),
                  title: Text(_childNameById(children.first.id)),
                  subtitle:
                      const Text('Las imágenes se guardarán para este perfil.'),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: DropdownButtonFormField<String>(
                    initialValue: previewChildId,
                    decoration: const InputDecoration(
                      labelText: 'Vista previa del perfil',
                    ),
                    items: children
                        .map(
                          (child) => DropdownMenuItem<String>(
                            value: child.id,
                            child: Text(
                              child.name.trim().isEmpty
                                  ? 'Niño sin nombre'
                                  : child.name,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedChildId = value);
                    },
                  ),
                ),
              ),
            const SizedBox(height: 10),
            ..._targets.map((target) {
              final imagePath = widget.controller.customImagePathFor(
                key: target,
                childId: previewChildId,
              );
              final busy = _busyKey == '$previewChildId::$target';
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
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
                          onPressed: (busy || children.isEmpty)
                              ? null
                              : () => _openSourceSheet(target),
                          icon: busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
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
