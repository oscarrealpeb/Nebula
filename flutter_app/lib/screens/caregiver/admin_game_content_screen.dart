import 'package:flutter/material.dart';

import '../../controllers/app_controller.dart';
import '../../models/game_content_config.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/nebula_button.dart';
import '../../widgets/nebula_snack.dart';

class AdminGameContentScreen extends StatefulWidget {
  const AdminGameContentScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  State<AdminGameContentScreen> createState() => _AdminGameContentScreenState();
}

class _AdminGameContentScreenState extends State<AdminGameContentScreen> {
  final _emotionImageController = TextEditingController();
  final _emotionCorrectController = TextEditingController();
  final _soundAssetController = TextEditingController();
  final _soundImageController = TextEditingController();
  final _soundCategoryController = TextEditingController();

  int _emotionDifficulty = 1;
  int _soundDifficulty = 1;
  bool _saving = false;
  bool _loading = false;
  late GameContentConfig _working;

  @override
  void initState() {
    super.initState();
    _working = widget.controller.gameContentConfig;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reload();
    });
  }

  @override
  void dispose() {
    _emotionImageController.dispose();
    _emotionCorrectController.dispose();
    _soundAssetController.dispose();
    _soundImageController.dispose();
    _soundCategoryController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    if (_loading) return;
    setState(() => _loading = true);
    final result =
        await widget.controller.reloadGameContentConfig(notify: false);
    if (!mounted) return;
    setState(() {
      _working = widget.controller.gameContentConfig;
      _loading = false;
    });
    await NebulaSnack.show(context, message: result.message, ok: result.ok);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final result = await widget.controller.saveGameContentConfig(_working);
    if (!mounted) return;
    setState(() => _saving = false);
    await NebulaSnack.show(context, message: result.message, ok: result.ok);
  }

  void _addEmotionItem() {
    final imagePath = _emotionImageController.text.trim();
    final correctEmotion = _emotionCorrectController.text.trim();
    if (imagePath.isEmpty || correctEmotion.isEmpty) {
      NebulaSnack.show(
        context,
        message: 'Completa ruta de imagen y emocion correcta.',
        ok: false,
      );
      return;
    }

    final item = EmotionContentItem(
      id: 'emotion_${DateTime.now().microsecondsSinceEpoch}',
      difficultyStars: _emotionDifficulty.clamp(1, 3),
      imagePath: imagePath,
      correctEmotion: correctEmotion,
      enabled: true,
    );

    setState(() {
      _working = _working.copyWith(
        emotionItems: [..._working.emotionItems, item],
      );
      _emotionImageController.clear();
      _emotionCorrectController.clear();
    });
  }

  void _toggleEmotionItem(String id, bool value) {
    final next = _working.emotionItems.map((item) {
      if (item.id != id) return item;
      return item.copyWith(enabled: value);
    }).toList();
    setState(() {
      _working = _working.copyWith(emotionItems: next);
    });
  }

  void _removeEmotionItem(String id) {
    final next = _working.emotionItems.where((item) => item.id != id).toList();
    setState(() {
      _working = _working.copyWith(emotionItems: next);
    });
  }

  void _addSoundItem() {
    final soundAsset = _soundAssetController.text.trim();
    final correctImage = _soundImageController.text.trim();
    final category = _soundCategoryController.text.trim();
    if (soundAsset.isEmpty || correctImage.isEmpty) {
      NebulaSnack.show(
        context,
        message: 'Completa ruta del sonido y de la imagen correcta.',
        ok: false,
      );
      return;
    }

    final item = SoundContentItem(
      id: 'sound_${DateTime.now().microsecondsSinceEpoch}',
      difficultyStars: _soundDifficulty.clamp(1, 3),
      soundAsset: soundAsset,
      correctImage: correctImage,
      category: category,
      enabled: true,
    );

    setState(() {
      _working = _working.copyWith(
        soundItems: [..._working.soundItems, item],
      );
      _soundAssetController.clear();
      _soundImageController.clear();
      _soundCategoryController.clear();
    });
  }

  void _toggleSoundItem(String id, bool value) {
    final next = _working.soundItems.map((item) {
      if (item.id != id) return item;
      return item.copyWith(enabled: value);
    }).toList();
    setState(() {
      _working = _working.copyWith(soundItems: next);
    });
  }

  void _removeSoundItem(String id) {
    final next = _working.soundItems.where((item) => item.id != id).toList();
    setState(() {
      _working = _working.copyWith(soundItems: next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final emotionItems = [..._working.emotionItems]
      ..sort((a, b) => a.difficultyStars.compareTo(b.difficultyStars));
    final soundItems = [..._working.soundItems]
      ..sort((a, b) => a.difficultyStars.compareTo(b.difficultyStars));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('Contenido de juegos (Admin)'),
      ),
      body: CosmicBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Editor de contenido',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Aqui defines recursos editables para juegos. Esta base no reemplaza aun la logica actual en runtime.',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Emociones: ${_working.emotionItems.length}  |  Sonidos: ${_working.soundItems.length}',
                    ),
                    if (_loading) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Descubre emocion',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Dificultad:'),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _emotionDifficulty,
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('1')),
                            DropdownMenuItem(value: 2, child: Text('2')),
                            DropdownMenuItem(value: 3, child: Text('3')),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _emotionDifficulty = value);
                          },
                        ),
                      ],
                    ),
                    TextField(
                      controller: _emotionImageController,
                      decoration: const InputDecoration(
                        labelText: 'Ruta de imagen (assets/... o local)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emotionCorrectController,
                      decoration: const InputDecoration(
                        labelText: 'Respuesta correcta (ej: Feliz)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    NebulaSecondaryButton(
                      text: 'Agregar item de emocion',
                      onPressed: _addEmotionItem,
                    ),
                    const SizedBox(height: 10),
                    if (emotionItems.isEmpty)
                      const Text('Sin items personalizados.')
                    else
                      ...emotionItems.map((item) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Switch(
                              value: item.enabled,
                              onChanged: (value) =>
                                  _toggleEmotionItem(item.id, value),
                            ),
                            title: Text(
                              'D${item.difficultyStars} | ${item.correctEmotion}',
                            ),
                            subtitle: Text(
                              item.imagePath,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _removeEmotionItem(item.id),
                            ),
                          )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conecta sonidos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Dificultad:'),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _soundDifficulty,
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('1')),
                            DropdownMenuItem(value: 2, child: Text('2')),
                            DropdownMenuItem(value: 3, child: Text('3')),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _soundDifficulty = value);
                          },
                        ),
                      ],
                    ),
                    TextField(
                      controller: _soundAssetController,
                      decoration: const InputDecoration(
                        labelText: 'Ruta de sonido (sounds/...)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _soundImageController,
                      decoration: const InputDecoration(
                        labelText: 'Ruta de imagen correcta',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _soundCategoryController,
                      decoration: const InputDecoration(
                        labelText: 'Categoria (opcional)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    NebulaSecondaryButton(
                      text: 'Agregar item de sonido',
                      onPressed: _addSoundItem,
                    ),
                    const SizedBox(height: 10),
                    if (soundItems.isEmpty)
                      const Text('Sin items personalizados.')
                    else
                      ...soundItems.map((item) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Switch(
                              value: item.enabled,
                              onChanged: (value) =>
                                  _toggleSoundItem(item.id, value),
                            ),
                            title: Text(
                              'D${item.difficultyStars} | ${item.category.isEmpty ? 'sin categoria' : item.category}',
                            ),
                            subtitle: Text(
                              '${item.soundAsset} -> ${item.correctImage}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _removeSoundItem(item.id),
                            ),
                          )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: NebulaSecondaryButton(
                    text: _loading ? 'Recargando...' : 'Recargar',
                    onPressed: _loading ? null : _reload,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: NebulaPrimaryButton(
                    text: _saving ? 'Guardando...' : 'Guardar contenido',
                    onPressed: _saving ? null : _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
