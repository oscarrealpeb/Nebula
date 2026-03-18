import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/app_controller.dart';
import '../../models/game_content_config.dart';
import '../../services/image_preparation_service.dart';
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
  static const List<String> _defaultEmotionImages = <String>[
    'assets/images/facil/feliz1.jpg',
    'assets/images/facil/feliz2.jpg',
    'assets/images/facil/feliz3.jpg',
    'assets/images/facil/feliz4.jpg',
    'assets/images/facil/feliz5.jpg',
    'assets/images/facil/feliz6.jpg',
    'assets/images/facil/feliz7.jpg',
    'assets/images/facil/feliz9.jpg',
    'assets/images/facil/feliz10.jpg',
    'assets/images/facil/triste1.jpg',
    'assets/images/facil/triste2.jpg',
    'assets/images/facil/triste3.jpg',
    'assets/images/facil/triste4.jpg',
    'assets/images/facil/triste5.jpg',
    'assets/images/facil/triste6.jpg',
    'assets/images/facil/enojado1.jpg',
    'assets/images/facil/enojado2.jpg',
    'assets/images/facil/enojado3.jpg',
    'assets/images/facil/enojado4.jpg',
    'assets/images/facil/enojado5.jpg',
    'assets/images/facil/enojado6.jpg',
    'assets/images/facil/enojado7.jpg',
    'assets/images/facil/enojado8.jpg',
    'assets/images/facil/enojado9.jpg',
    'assets/images/facil/enojado10.jpg',
    'assets/images/facil/asustado4.jpg',
    'assets/images/facil/asustado6.jpg',
    'assets/images/facil/sorprendido1.jpg',
    'assets/images/facil/sorprendido2.jpg',
    'assets/images/facil/sorpendido3.jpg',
    'assets/images/facil/sorprendido4.jpg',
    'assets/images/facil/sorprendido5.jpg',
    'assets/images/facil/sorprendido6.jpg',
    'assets/images/facil/sorprendido7.jpg',
    'assets/images/facil/sorprendido8.jpg',
    'assets/images/medio/s-asustado.jpg',
    'assets/images/medio/s-asustado2.jpg',
    'assets/images/medio/s-asustado3.jpg',
    'assets/images/medio/s-enojada.jpg',
    'assets/images/medio/s-feliz1.jpg',
    'assets/images/medio/s-feliz2.jpg',
    'assets/images/medio/s-feliz3jpg.jpg',
    'assets/images/medio/s-feliz4.jpg',
    'assets/images/medio/s-feliz5.jpg',
    'assets/images/medio/s-feliz6.jpg',
    'assets/images/medio/s-feliz7.jpg',
    'assets/images/medio/s-sorprendido1.jpg',
    'assets/images/medio/s-sorprendido2.jpg',
    'assets/images/medio/s-sorprendido3.jpg',
    'assets/images/medio/s-triste6.jpg',
    'assets/images/medio/s-triste7 (recortar).jpg',
    'assets/images/medio/s-triste8.jpg',
    'assets/images/dificil/d-asustado1.jpg',
    'assets/images/dificil/d-asustado2.jpg',
    'assets/images/dificil/d-asustado3.jpg',
    'assets/images/dificil/d-enojado1.jpg',
    'assets/images/dificil/d-enojado2.jpg',
    'assets/images/dificil/d-enojado3.jpg',
    'assets/images/dificil/d-enojado5.jpg',
    'assets/images/dificil/d-feliz.jpg',
    'assets/images/dificil/d-feliz1.jpg',
    'assets/images/dificil/d-feliz3.jpg',
    'assets/images/dificil/d-feliz5.jpg',
    'assets/images/dificil/d-feliz6.jpg',
    'assets/images/dificil/d-feliz7.jpg',
    'assets/images/dificil/d-sorprendidos.jpg',
    'assets/images/dificil/d-triste1.jpg',
  ];

  static const List<String> _defaultSoundImages = <String>[
    'assets/images/conecta/arpa.jpg',
    'assets/images/conecta/ballena.jpg',
    'assets/images/conecta/buho.jpg',
    'assets/images/conecta/burro.jpg',
    'assets/images/conecta/caballo.jpg',
    'assets/images/conecta/delfin.jpg',
    'assets/images/conecta/elefante.jpg',
    'assets/images/conecta/gallo.jpg',
    'assets/images/conecta/gato.jpg',
    'assets/images/conecta/grillo.jpg',
    'assets/images/conecta/guitarra.jpg',
    'assets/images/conecta/pato.jpg',
    'assets/images/conecta/perro.jpg',
    'assets/images/conecta/piano.jpg',
    'assets/images/conecta/vaca.jpg',
    'assets/images/conecta/violin.jpg',
    'assets/images/conecta/olas.jpg',
    'assets/images/conecta/aspiradora.jpg',
    'assets/images/conecta/microondas.jpg',
    'assets/images/conecta/puerta.jpg',
    'assets/images/conecta/bebe.jpg',
    'assets/images/conecta/aplausos.jpg',
    'assets/images/conecta/claxon.jpg',
    'assets/images/conecta/centro_comercial.jpg',
    'assets/images/conecta/restaurante.jpg',
    'assets/images/conecta/niños.jpg',
    'assets/images/conecta/tormenta.jpg',
    'assets/images/conecta/coro.jpg',
  ];

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
  String? _globalBusyKey;
  int _globalPreviewRevision = 0;
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

  String _prettyNameFromSource(String source) {
    final clean = source.trim();
    if (clean.isEmpty) return 'Elemento';
    final slashIndex = clean.lastIndexOf('/');
    final fileName = slashIndex >= 0 ? clean.substring(slashIndex + 1) : clean;
    final dotIndex = fileName.lastIndexOf('.');
    final base = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
    final spaced = base.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    if (spaced.isEmpty) return 'Elemento';
    return spaced
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  String _emotionDifficultyLabel(String source) {
    final normalized = source.toLowerCase();
    if (normalized.contains('/facil/')) {
      return 'Aparece en dificultad fácil';
    }
    if (normalized.contains('/medio/')) {
      return 'Aparece en dificultad media';
    }
    if (normalized.contains('/dificil/')) {
      return 'Aparece en dificultad difícil';
    }
    return 'Contenido predeterminado';
  }

  bool _hasGlobalOverride({
    required String gameKey,
    required String itemId,
  }) {
    final key = 'game::${gameKey.trim().toLowerCase()}::${itemId.trim().toLowerCase()}';
    return switch (gameKey.trim().toLowerCase()) {
      'emociones' => (_working.globalEmotionImageOverrides[key]?.trim().isNotEmpty ?? false),
      'sonidos' => (_working.globalSoundImageOverrides[key]?.trim().isNotEmpty ?? false),
      _ => false,
    };
  }

  String _defaultSourceFor({
    required String gameKey,
    required String itemId,
  }) {
    final normalizedGame = gameKey.trim().toLowerCase();
    final normalizedItemId = itemId.trim().toLowerCase();
    final pool = switch (normalizedGame) {
      'emociones' => _defaultEmotionImages,
      'sonidos' => _defaultSoundImages,
      _ => const <String>[],
    };
    for (final source in pool) {
      final sourceItemId = widget.controller.customContentItemId(source: source);
      if (sourceItemId.trim().toLowerCase() == normalizedItemId) {
        return source;
      }
    }
    return '';
  }

  Future<void> _pickGlobalImage({
    required String gameKey,
    required String itemId,
    required ImageSource source,
  }) async {
    final busyKey = '$gameKey::$itemId';
    setState(() => _globalBusyKey = busyKey);
    try {
      final previousSource = widget.controller.resolvedGameImageSourceFor(
        gameKey: gameKey,
        itemId: itemId,
        defaultSource: _defaultSourceFor(gameKey: gameKey, itemId: itemId),
      );
      final file = await _picker.pickImage(source: source, imageQuality: 80);
      if (file == null) return;
      if (!mounted) return;
      final prepared = await ImagePreparationService.cropAndValidate(
        context,
        file.path,
      );
      if (!mounted || prepared.cancelled) return;
      if (!prepared.ok) {
        await NebulaSnack.show(
          context,
          message: prepared.message,
          ok: false,
        );
        return;
      }
      final result = await widget.controller.saveGlobalGameImage(
        gameKey: gameKey,
        itemId: itemId,
        filePath: prepared.filePath,
      );
      if (!mounted) return;
      if (result.ok) {
        final nextSource = widget.controller.resolvedGameImageSourceFor(
          gameKey: gameKey,
          itemId: itemId,
          defaultSource: _defaultSourceFor(gameKey: gameKey, itemId: itemId),
        );
        await evictPuzzleImageSource(previousSource);
        if (nextSource != previousSource) {
          await evictPuzzleImageSource(nextSource);
        }
        setState(() {
          _working = widget.controller.gameContentConfig;
          _globalPreviewRevision++;
        });
      }
      if (!mounted) return;
      await NebulaSnack.show(context, message: result.message, ok: result.ok);
    } finally {
      if (mounted) {
        setState(() => _globalBusyKey = null);
      }
    }
  }

  Future<void> _restoreGlobalImage({
    required String gameKey,
    required String itemId,
  }) async {
    final previousSource = widget.controller.resolvedGameImageSourceFor(
      gameKey: gameKey,
      itemId: itemId,
      defaultSource: _defaultSourceFor(gameKey: gameKey, itemId: itemId),
    );
    final result = await widget.controller.restoreGlobalGameImage(
      gameKey: gameKey,
      itemId: itemId,
    );
    if (!mounted) return;
    if (result.ok) {
      final nextSource = widget.controller.resolvedGameImageSourceFor(
        gameKey: gameKey,
        itemId: itemId,
        defaultSource: _defaultSourceFor(gameKey: gameKey, itemId: itemId),
      );
      await evictPuzzleImageSource(previousSource);
      if (nextSource != previousSource) {
        await evictPuzzleImageSource(nextSource);
      }
      setState(() {
        _working = widget.controller.gameContentConfig;
        _globalPreviewRevision++;
      });
    }
    if (!mounted) return;
    await NebulaSnack.show(context, message: result.message, ok: result.ok);
  }

  Future<void> _openGlobalSourceSheet({
    required String gameKey,
    required String itemId,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
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
                  await _pickGlobalImage(
                    gameKey: gameKey,
                    itemId: itemId,
                    source: ImageSource.camera,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Usar galería'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pickGlobalImage(
                    gameKey: gameKey,
                    itemId: itemId,
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

  Widget _buildGlobalDefaultsCard({
    required String title,
    required String description,
    required List<_GlobalDefaultImageItem> items,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(description),
            const SizedBox(height: 10),
            ...items.map((item) {
              final busy = _globalBusyKey == '${item.gameKey}::${item.itemId}';
              final effectiveSource = widget.controller.resolvedGameImageSourceFor(
                gameKey: item.gameKey,
                itemId: item.itemId,
                defaultSource: item.defaultSource,
              );
              final hasOverride = _hasGlobalOverride(
                gameKey: item.gameKey,
                itemId: item.itemId,
              );
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8FC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDCE4F2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PuzzleImageAdapter(
                      key: ValueKey(
                        '${item.gameKey}::${item.itemId}::$_globalPreviewRevision::$effectiveSource',
                      ),
                      imageSource: effectiveSource,
                      size: 72,
                      borderRadius: 12,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.subtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hasOverride
                                ? 'Usando predeterminada actualizada por admin.'
                                : 'Usando imagen original de la app.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: hasOverride
                                      ? const Color(0xFF1B8B3B)
                                      : const Color(0xFF54637E),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.icon(
                                onPressed: busy
                                    ? null
                                    : () => _openGlobalSourceSheet(
                                          gameKey: item.gameKey,
                                          itemId: item.itemId,
                                        ),
                                icon: busy
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.edit_outlined),
                                label: Text(
                                  busy ? 'Guardando...' : 'Cambiar predeterminada',
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: hasOverride
                                    ? () => _restoreGlobalImage(
                                          gameKey: item.gameKey,
                                          itemId: item.itemId,
                                        )
                                    : null,
                                icon: const Icon(Icons.restore_rounded),
                                label: const Text('Restaurar original'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emotionItems = [..._working.emotionItems]
      ..sort((a, b) => a.difficultyStars.compareTo(b.difficultyStars));
    final soundItems = [..._working.soundItems]
      ..sort((a, b) => a.difficultyStars.compareTo(b.difficultyStars));
    final puzzleItems = [..._working.puzzleItems];
    final defaultEmotionItems = _defaultEmotionImages
        .map(
          (source) => _GlobalDefaultImageItem(
            gameKey: 'emociones',
            itemId: source,
            title: _prettyNameFromSource(source),
            subtitle: _emotionDifficultyLabel(source),
            defaultSource: source,
          ),
        )
        .toList();
    final defaultSoundItems = _defaultSoundImages
        .map(
          (source) => _GlobalDefaultImageItem(
            gameKey: 'sonidos',
            itemId: source,
            title: _prettyNameFromSource(source),
            subtitle: 'Se usa como imagen predeterminada en Conecta sonidos.',
            defaultSource: source,
          ),
        )
        .toList();

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
            _buildGlobalDefaultsCard(
              title: 'Predeterminadas globales · Emociones',
              description:
                  'Si cambias una imagen aqui, se actualiza para todos los usuarios que no tengan una personalizacion propia del nino.',
              items: defaultEmotionItems,
            ),
            const SizedBox(height: 10),
            _buildGlobalDefaultsCard(
              title: 'Predeterminadas globales · Conecta sonidos',
              description:
                  'Estas imagenes son la base global del juego. Las personalizaciones del cuidador por nino siguen teniendo prioridad.',
              items: defaultSoundItems,
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

class _GlobalDefaultImageItem {
  const _GlobalDefaultImageItem({
    required this.gameKey,
    required this.itemId,
    required this.title,
    required this.subtitle,
    required this.defaultSource,
  });

  final String gameKey;
  final String itemId;
  final String title;
  final String subtitle;
  final String defaultSource;
}
