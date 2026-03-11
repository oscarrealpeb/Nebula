import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/app_controller.dart';
import '../../models/game_content_config.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/nebula_button.dart';
import '../../widgets/nebula_snack.dart';
import '../../widgets/puzzle_image_adapter.dart';

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
  final _puzzleSourceController = TextEditingController();
  final _picker = ImagePicker();

  static const int _maxPuzzleImages = 8;
  static const int _maxPuzzleBytes = 220 * 1024;
  static const int _minPuzzleSide = 256;
  static const int _maxPuzzleSide = 1024;

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
    _puzzleSourceController.dispose();
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

  Future<void> _pickPuzzleImage(ImageSource source) async {
    if (_working.puzzleItems.length >= _maxPuzzleImages) {
      await NebulaSnack.show(
        context,
        message: 'Limite alcanzado: maximo $_maxPuzzleImages imagenes.',
        ok: false,
      );
      return;
    }

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 78,
      maxWidth: _maxPuzzleSide.toDouble(),
      maxHeight: _maxPuzzleSide.toDouble(),
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    if (bytes.length > _maxPuzzleBytes) {
      await NebulaSnack.show(
        context,
        message:
            'Imagen muy pesada (${(bytes.length / 1024).toStringAsFixed(0)} KB). Maximo ${(_maxPuzzleBytes / 1024).toStringAsFixed(0)} KB.',
        ok: false,
      );
      return;
    }

    final imageInfo = await _decodeImageSize(bytes);
    if (!mounted) return;
    if (imageInfo == null) {
      await NebulaSnack.show(
        context,
        message: 'No pudimos leer dimensiones de la imagen.',
        ok: false,
      );
      return;
    }
    final width = imageInfo.width;
    final height = imageInfo.height;
    if (width < _minPuzzleSide || height < _minPuzzleSide) {
      await NebulaSnack.show(
        context,
        message:
            'La imagen es muy pequena. Minimo ${_minPuzzleSide}x$_minPuzzleSide px.',
        ok: false,
      );
      return;
    }

    final mime = _mimeForPath(picked.name);
    final sourceValue = 'data:$mime;base64,${base64Encode(bytes)}';
    final nextItem = PuzzleContentItem(
      id: 'puzzle_${DateTime.now().microsecondsSinceEpoch}',
      imageSource: sourceValue,
      width: width,
      height: height,
      enabled: true,
    );
    setState(() {
      _working = _working.copyWith(
        puzzleItems: [..._working.puzzleItems, nextItem],
      );
    });

    if (!mounted) return;
    await NebulaSnack.show(
      context,
      message: 'Imagen cargada para rompecabezas (${width}x$height).',
      ok: true,
    );
  }

  Future<_ImageSize?> _decodeImageSize(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final size = _ImageSize(width: image.width, height: image.height);
      image.dispose();
      codec.dispose();
      return size;
    } catch (_) {
      return null;
    }
  }

  String _mimeForPath(String path) {
    final lower = path.trim().toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  void _addPuzzleSourceManually() {
    final source = _puzzleSourceController.text.trim();
    if (source.isEmpty) {
      NebulaSnack.show(
        context,
        message: 'Escribe una URL o ruta de asset.',
        ok: false,
      );
      return;
    }
    if (_working.puzzleItems.length >= _maxPuzzleImages) {
      NebulaSnack.show(
        context,
        message: 'Limite alcanzado: maximo $_maxPuzzleImages imagenes.',
        ok: false,
      );
      return;
    }
    final nextItem = PuzzleContentItem(
      id: 'puzzle_${DateTime.now().microsecondsSinceEpoch}',
      imageSource: source,
      width: 0,
      height: 0,
      enabled: true,
    );
    setState(() {
      _working = _working.copyWith(
        puzzleItems: [..._working.puzzleItems, nextItem],
      );
      _puzzleSourceController.clear();
    });
  }

  void _togglePuzzleItem(String id, bool value) {
    final next = _working.puzzleItems.map((item) {
      if (item.id != id) return item;
      return item.copyWith(enabled: value);
    }).toList();
    setState(() {
      _working = _working.copyWith(puzzleItems: next);
    });
  }

  void _removePuzzleItem(String id) {
    final next = _working.puzzleItems.where((item) => item.id != id).toList();
    setState(() {
      _working = _working.copyWith(puzzleItems: next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final emotionItems = [..._working.emotionItems]
      ..sort((a, b) => a.difficultyStars.compareTo(b.difficultyStars));
    final soundItems = [..._working.soundItems]
      ..sort((a, b) => a.difficultyStars.compareTo(b.difficultyStars));
    final puzzleItems = [..._working.puzzleItems];

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
                      'Aquí defines recursos editables para juegos. Esta base no reemplaza aún la lógica actual en runtime.',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Emociones: ${_working.emotionItems.length}  |  Sonidos: ${_working.soundItems.length}  |  Puzzle: ${_working.puzzleItems.length}',
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Arma la imagen (rompecabezas)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Estandar recomendado: entre 256x256 y 1024x1024 px, maximo 220 KB por imagen.',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: NebulaSecondaryButton(
                            text: 'Subir desde galeria',
                            onPressed: () =>
                                _pickPuzzleImage(ImageSource.gallery),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: NebulaSecondaryButton(
                            text: 'Tomar foto',
                            onPressed: () =>
                                _pickPuzzleImage(ImageSource.camera),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _puzzleSourceController,
                      decoration: const InputDecoration(
                        labelText: 'URL o ruta de asset (opcional)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    NebulaSecondaryButton(
                      text: 'Agregar fuente manual',
                      onPressed: _addPuzzleSourceManually,
                    ),
                    const SizedBox(height: 10),
                    if (puzzleItems.isEmpty)
                      const Text('Sin imagenes de puzzle configuradas.')
                    else
                      ...puzzleItems.map((item) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Switch(
                              value: item.enabled,
                              onChanged: (value) =>
                                  _togglePuzzleItem(item.id, value),
                            ),
                            title: Text(
                              item.width > 0 && item.height > 0
                                  ? '${item.width}x${item.height}'
                                  : 'Fuente manual',
                            ),
                            subtitle: Text(
                              item.imageSource,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                PuzzleImageAdapter(
                                  imageSource: item.imageSource,
                                  size: 34,
                                  borderRadius: 6,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _removePuzzleItem(item.id),
                                ),
                              ],
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

class _ImageSize {
  const _ImageSize({
    required this.width,
    required this.height,
  });

  final int width;
  final int height;
}
