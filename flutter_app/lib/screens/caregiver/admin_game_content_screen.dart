import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _puzzleAudioController = TextEditingController();
  final _diloImageController = TextEditingController();
  final _diloTextController = TextEditingController();
  final _diloAudioController = TextEditingController();
  final _memoryImageController = TextEditingController();
  final _memoryAudioController = TextEditingController();
  final _picker = ImagePicker();

  static const int _maxPuzzleImages = 8;
  static const int _maxPuzzleBytes = 220 * 1024;
  static const int _minPuzzleSide = 256;
  static const int _maxPuzzleSide = 1024;

  int _emotionDifficulty = 1;
  int _soundDifficulty = 1;
  int _diloDifficulty = 1;
  bool _saving = false;
  bool _loading = false;
  String? _globalBusyKey;
  String? _newItemBusyKey;
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
    _puzzleAudioController.dispose();
    _diloImageController.dispose();
    _diloTextController.dispose();
    _diloAudioController.dispose();
    _memoryImageController.dispose();
    _memoryAudioController.dispose();
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

  Future<void> _addEmotionItem() async {
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
    final imageOk = await _validateImageSource(
      imagePath,
      label: 'imagen',
    );
    if (!imageOk) return;

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

  Future<void> _addSoundItem() async {
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
    final soundOk = await _validateAudioSource(soundAsset);
    if (!soundOk) return;
    final imageOk = await _validateImageSource(
      correctImage,
      label: 'imagen correcta',
    );
    if (!imageOk) return;

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

  Future<void> _addDiloItem() async {
    final imagePath = _diloImageController.text.trim();
    final text = _diloTextController.text.trim();
    final audioSource = _diloAudioController.text.trim();
    if (imagePath.isEmpty || text.isEmpty || audioSource.isEmpty) {
      NebulaSnack.show(
        context,
        message: 'Completa imagen, texto y audio.',
        ok: false,
      );
      return;
    }
    final imageOk = await _validateImageSource(
      imagePath,
      label: 'imagen',
    );
    if (!imageOk) return;
    final audioOk = await _validateAudioSource(audioSource);
    if (!audioOk) return;

    final item = DiloContentItem(
      id: 'dilo_${DateTime.now().microsecondsSinceEpoch}',
      difficultyStars: _diloDifficulty.clamp(1, 3),
      imagePath: imagePath,
      text: text,
      audioSource: audioSource,
      enabled: true,
    );

    setState(() {
      _working = _working.copyWith(
        diloItems: [..._working.diloItems, item],
      );
      _diloImageController.clear();
      _diloTextController.clear();
      _diloAudioController.clear();
    });
  }

  void _toggleDiloItem(String id, bool value) {
    final next = _working.diloItems.map((item) {
      if (item.id != id) return item;
      return item.copyWith(enabled: value);
    }).toList();
    setState(() {
      _working = _working.copyWith(diloItems: next);
    });
  }

  void _removeDiloItem(String id) {
    final next = _working.diloItems.where((item) => item.id != id).toList();
    setState(() {
      _working = _working.copyWith(diloItems: next);
    });
  }

  Future<void> _addMemoryItem() async {
    final imagePath = _memoryImageController.text.trim();
    final audioSource = _memoryAudioController.text.trim();
    if (imagePath.isEmpty) {
      NebulaSnack.show(
        context,
        message: 'Completa la ruta de imagen.',
        ok: false,
      );
      return;
    }
    final imageOk = await _validateImageSource(
      imagePath,
      label: 'imagen',
    );
    if (!imageOk) return;
    if (audioSource.isNotEmpty) {
      final audioOk = await _validateAudioSource(audioSource);
      if (!audioOk) return;
    }

    final item = MemoryContentItem(
      id: 'memory_${DateTime.now().microsecondsSinceEpoch}',
      imagePath: imagePath,
      audioSource: audioSource,
      enabled: true,
    );

    setState(() {
      _working = _working.copyWith(
        memoryItems: [..._working.memoryItems, item],
      );
      _memoryImageController.clear();
      _memoryAudioController.clear();
    });
  }

  void _toggleMemoryItem(String id, bool value) {
    final next = _working.memoryItems.map((item) {
      if (item.id != id) return item;
      return item.copyWith(enabled: value);
    }).toList();
    setState(() {
      _working = _working.copyWith(memoryItems: next);
    });
  }

  void _removeMemoryItem(String id) {
    final next = _working.memoryItems.where((item) => item.id != id).toList();
    setState(() {
      _working = _working.copyWith(memoryItems: next);
    });
  }

  String _prettyNameFromSource(String source) {
    final clean = source.trim();
    if (clean.isEmpty || clean.toLowerCase().startsWith('data:image/')) {
      return 'Elemento';
    }
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

  String _emotionFromSource(String source) {
    final normalized = source.trim().toLowerCase();
    if (normalized.contains('feliz')) return 'feliz';
    if (normalized.contains('triste')) return 'triste';
    if (normalized.contains('enojado')) return 'enojado';
    if (normalized.contains('sorprendido') ||
        normalized.contains('sorpendido')) {
      return 'sorprendido';
    }
    if (normalized.contains('asustado')) return 'asustado';
    return '';
  }

  String _prettyEmotionName(String emotion) {
    final normalized = emotion.trim().toLowerCase();
    if (normalized.isEmpty) return 'emocion esperada';
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  List<String> _expectedConceptsFromSource(
    String source, {
    Iterable<String> extraLabels = const <String>[],
  }) {
    final concepts = <String>{};

    void addConcept(String raw) {
      final normalized = raw
          .trim()
          .toLowerCase()
          .replaceAll('á', 'a')
          .replaceAll('é', 'e')
          .replaceAll('í', 'i')
          .replaceAll('ó', 'o')
          .replaceAll('ú', 'u')
          .replaceAll('ü', 'u')
          .replaceAll('ñ', 'n')
          .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (normalized.isEmpty) return;
      concepts.add(normalized);
      for (final token in normalized.split(' ')) {
        if (token.length >= 3) {
          concepts.add(token);
        }
      }
    }

    if (!source.trim().toLowerCase().startsWith('data:image/')) {
      addConcept(_prettyNameFromSource(source));
    }
    for (final extra in extraLabels) {
      addConcept(extra);
    }
    return concepts.toList(growable: false);
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
    final key =
        'game::${gameKey.trim().toLowerCase()}::${itemId.trim().toLowerCase()}';
    return switch (gameKey.trim().toLowerCase()) {
      'emociones' =>
        (_working.globalEmotionImageOverrides[key]?.trim().isNotEmpty ?? false),
      'sonidos' =>
        (_working.globalSoundImageOverrides[key]?.trim().isNotEmpty ?? false),
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
      final sourceItemId =
          widget.controller.customContentItemId(source: source);
      if (sourceItemId.trim().toLowerCase() == normalizedItemId) {
        return source;
      }
    }
    return '';
  }

  List<String> _expectedConceptsForGlobalItem({
    required String gameKey,
    required String itemId,
  }) {
    final defaultSource = _defaultSourceFor(gameKey: gameKey, itemId: itemId);
    if (gameKey.trim().toLowerCase() == 'emociones') {
      return const <String>[];
    }
    return _expectedConceptsFromSource(defaultSource);
  }

  String _expectedEmotionForGlobalItem({
    required String gameKey,
    required String itemId,
  }) {
    if (gameKey.trim().toLowerCase() != 'emociones') return '';
    final defaultSource = _defaultSourceFor(gameKey: gameKey, itemId: itemId);
    return _emotionFromSource(defaultSource);
  }

  String _expectedDescriptionForGlobalItem({
    required String gameKey,
    required String itemId,
  }) {
    final defaultSource = _defaultSourceFor(gameKey: gameKey, itemId: itemId);
    if (gameKey.trim().toLowerCase() == 'emociones') {
      return _prettyEmotionName(_emotionFromSource(defaultSource));
    }
    return _prettyNameFromSource(defaultSource);
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
        expectedConcepts: _expectedConceptsForGlobalItem(
          gameKey: gameKey,
          itemId: itemId,
        ),
        expectedEmotion: _expectedEmotionForGlobalItem(
          gameKey: gameKey,
          itemId: itemId,
        ),
        expectedDescription: _expectedDescriptionForGlobalItem(
          gameKey: gameKey,
          itemId: itemId,
        ),
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

  Future<void> _pickNewItemImage({
    required String targetKey,
    required String gameKey,
    required ImageSource source,
    required void Function(String url) onUploaded,
  }) async {
    if (_newItemBusyKey != null) return;
    if (!widget.controller.firebaseEnabled) {
      await NebulaSnack.show(
        context,
        message: 'Esta funci\u00f3n requiere Firebase habilitado.',
        ok: false,
      );
      return;
    }
    await widget.controller.refreshOnlineStatus();
    if (!widget.controller.isOnline) {
      await NebulaSnack.show(
        context,
        message: 'Necesitas internet para subir la imagen.',
        ok: false,
      );
      return;
    }
    setState(() => _newItemBusyKey = targetKey);
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (picked == null) return;
      if (!mounted) return;
      final prepared = await ImagePreparationService.cropAndValidate(
        context,
        picked.path,
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
      final file = File(prepared.filePath);
      final sizeBytes = file.lengthSync();
      if (sizeBytes > AppController.maxCustomImageBytes) {
        await NebulaSnack.show(
          context,
          message:
              'La imagen supera el tama\u00f1o m\u00e1ximo permitido de ${AppController.maxCustomImageMegabytes} MB.',
          ok: false,
        );
        return;
      }

      final upload = await widget.controller.authService.uploadGlobalGameImageFile(
        gameKey: gameKey,
        itemId: 'content_${DateTime.now().microsecondsSinceEpoch}',
        filePath: prepared.filePath,
      );
      if (!mounted) return;
      if (!upload.ok || upload.data == null) {
        await NebulaSnack.show(
          context,
          message: upload.message,
          ok: false,
        );
        return;
      }
      onUploaded(upload.data!.downloadUrl);
      await NebulaSnack.show(
        context,
        message: 'Imagen subida. Completa los campos y agrega el item.',
        ok: true,
      );
    } finally {
      if (mounted) {
        setState(() => _newItemBusyKey = null);
      }
    }
  }

  Future<void> _pickNewItemAudio({
    required String targetKey,
    required String gameKey,
    required void Function(String url) onUploaded,
  }) async {
    if (_newItemBusyKey != null) return;
    if (!widget.controller.firebaseEnabled) {
      await NebulaSnack.show(
        context,
        message: 'Esta funci\u00f3n requiere Firebase habilitado.',
        ok: false,
      );
      return;
    }
    await widget.controller.refreshOnlineStatus();
    if (!widget.controller.isOnline) {
      await NebulaSnack.show(
        context,
        message: 'Necesitas internet para subir el audio.',
        ok: false,
      );
      return;
    }
    setState(() => _newItemBusyKey = targetKey);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );
      if (picked == null || picked.files.isEmpty) return;
      final path = picked.files.single.path ?? '';
      if (path.trim().isEmpty) {
        await NebulaSnack.show(
          context,
          message: 'No se pudo leer el audio seleccionado.',
          ok: false,
        );
        return;
      }
      final upload = await widget.controller.authService.uploadGlobalGameAudioFile(
        gameKey: gameKey,
        itemId: 'audio_${DateTime.now().microsecondsSinceEpoch}',
        filePath: path,
      );
      if (!mounted) return;
      if (!upload.ok || upload.data == null) {
        await NebulaSnack.show(
          context,
          message: upload.message,
          ok: false,
        );
        return;
      }
      onUploaded(upload.data!.downloadUrl);
      await NebulaSnack.show(
        context,
        message: 'Audio subido. Completa los campos y agrega el item.',
        ok: true,
      );
    } finally {
      if (mounted) {
        setState(() => _newItemBusyKey = null);
      }
    }
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

    final audioSource = _puzzleAudioController.text.trim();
    if (audioSource.isNotEmpty) {
      final audioOk = await _validateAudioSource(audioSource);
      if (!audioOk) return;
    }

    final mime = _mimeForPath(picked.name);
    final sourceValue = 'data:$mime;base64,${base64Encode(bytes)}';
    final nextItem = PuzzleContentItem(
      id: 'puzzle_${DateTime.now().microsecondsSinceEpoch}',
      imageSource: sourceValue,
      audioSource: audioSource,
      width: width,
      height: height,
      enabled: true,
    );
    setState(() {
      _working = _working.copyWith(
        puzzleItems: [..._working.puzzleItems, nextItem],
      );
      _puzzleAudioController.clear();
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

  bool _looksLikeAbsolutePath(String path) {
    final normalized = path.trim();
    if (normalized.isEmpty) return false;
    if (RegExp(r'^[a-zA-Z]:\\').hasMatch(normalized)) return true;
    if (normalized.startsWith('/')) return true;
    if (normalized.startsWith(r'\\')) return true;
    return false;
  }

  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _validateImageSource(
    String raw, {
    required String label,
  }) async {
    final source = raw.trim();
    if (source.isEmpty) {
      await NebulaSnack.show(
        context,
        message: 'Completa la ruta de $label.',
        ok: false,
      );
      return false;
    }
    if (source.startsWith('data:image/')) return true;
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return true;
    }
    if (_looksLikeAbsolutePath(source)) {
      if (File(source).existsSync()) return true;
      await NebulaSnack.show(
        context,
        message: 'No encontramos el archivo local para $label.',
        ok: false,
      );
      return false;
    }
    if (source.startsWith('assets/')) {
      if (await _assetExists(source)) return true;
      await NebulaSnack.show(
        context,
        message: 'No encontramos el asset para $label.',
        ok: false,
      );
      return false;
    }
    final withAssets = 'assets/$source';
    if (await _assetExists(withAssets)) return true;
    if (await _assetExists(source)) return true;
    await NebulaSnack.show(
      context,
      message:
          'No encontramos la ruta de $label. Usa una URL válida, un asset o una ruta local existente.',
      ok: false,
    );
    return false;
  }

  Future<bool> _validateAudioSource(String raw) async {
    final source = raw.trim();
    if (source.isEmpty) {
      await NebulaSnack.show(
        context,
        message: 'Completa la ruta del audio.',
        ok: false,
      );
      return false;
    }
    if (source.startsWith('data:audio/')) return true;
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return true;
    }
    if (_looksLikeAbsolutePath(source)) {
      if (File(source).existsSync()) return true;
      await NebulaSnack.show(
        context,
        message: 'No encontramos el archivo de audio local.',
        ok: false,
      );
      return false;
    }
    if (source.startsWith('assets/')) {
      if (await _assetExists(source)) return true;
      await NebulaSnack.show(
        context,
        message: 'No encontramos el asset de audio.',
        ok: false,
      );
      return false;
    }
    final withAssets = 'assets/$source';
    if (await _assetExists(withAssets)) return true;
    if (await _assetExists(source)) return true;
    await NebulaSnack.show(
      context,
      message:
          'No encontramos la ruta del audio. Usa una URL válida, un asset o una ruta local existente.',
      ok: false,
    );
    return false;
  }

  Future<void> _addPuzzleSourceManually() async {
    final source = _puzzleSourceController.text.trim();
    final audioSource = _puzzleAudioController.text.trim();
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
    final ok = await _validateImageSource(
      source,
      label: 'imagen de puzzle',
    );
    if (!ok) return;
    if (audioSource.isNotEmpty) {
      final audioOk = await _validateAudioSource(audioSource);
      if (!audioOk) return;
    }
    final nextItem = PuzzleContentItem(
      id: 'puzzle_${DateTime.now().microsecondsSinceEpoch}',
      imageSource: source,
      audioSource: audioSource,
      width: 0,
      height: 0,
      enabled: true,
    );
    setState(() {
      _working = _working.copyWith(
        puzzleItems: [..._working.puzzleItems, nextItem],
      );
      _puzzleSourceController.clear();
      _puzzleAudioController.clear();
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
      child: ExpansionTile(
        title: Text(title),
        subtitle: Text('${items.length} im\u00e1genes \u00b7 $description'),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: items.map((item) {
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
            margin: const EdgeInsets.only(top: 10),
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
        }).toList(),
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
    final diloItems = [..._working.diloItems]
      ..sort((a, b) => a.difficultyStars.compareTo(b.difficultyStars));
    final memoryItems = [..._working.memoryItems];
    final defaultEmotionItems = _defaultEmotionImages
        .map(
          (source) => _GlobalDefaultImageItem(
            gameKey: 'emociones',
            itemId: source,
            title: _prettyNameFromSource(source),
            subtitle: _emotionDifficultyLabel(source),
            defaultSource: source,
            expectedEmotion: _emotionFromSource(source),
            expectedDescription: _prettyEmotionName(_emotionFromSource(source)),
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
            expectedConcepts: _expectedConceptsFromSource(source),
            expectedDescription: _prettyNameFromSource(source),
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
                      'Aqui defines recursos globales de juegos. Los cambios se reflejan en todas las cuentas, mientras las personalizaciones del nino tienen prioridad. Las nuevas imagenes pasan por validaciones de formato, recorte y revision de contenido antes de subirse.',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Emociones: ${_working.emotionItems.length}  |  Sonidos: ${_working.soundItems.length}  |  Dilo: ${_working.diloItems.length}  |  Cartas: ${_working.memoryItems.length}  |  Puzzle: ${_working.puzzleItems.length}',
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
                    Row(
                      children: [
                        Expanded(
                          child: NebulaSecondaryButton(
                            text: _newItemBusyKey == 'emotion'
                                ? 'Subiendo...'
                                : 'Subir desde galeria',
                            onPressed: _newItemBusyKey == 'emotion'
                                ? null
                                : () => _pickNewItemImage(
                                      targetKey: 'emotion',
                                      gameKey: 'emociones',
                                      source: ImageSource.gallery,
                                      onUploaded: (url) {
                                        setState(() {
                                          _emotionImageController.text = url;
                                        });
                                      },
                                    ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: NebulaSecondaryButton(
                            text: _newItemBusyKey == 'emotion'
                                ? 'Subiendo...'
                                : 'Tomar foto',
                            onPressed: _newItemBusyKey == 'emotion'
                                ? null
                                : () => _pickNewItemImage(
                                      targetKey: 'emotion',
                                      gameKey: 'emociones',
                                      source: ImageSource.camera,
                                      onUploaded: (url) {
                                        setState(() {
                                          _emotionImageController.text = url;
                                        });
                                      },
                                    ),
                          ),
                        ),
                      ],
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
                    Row(
                      children: [
                        Expanded(
                          child: NebulaSecondaryButton(
                            text: _newItemBusyKey == 'sound'
                                ? 'Subiendo...'
                                : 'Subir desde galeria',
                            onPressed: _newItemBusyKey == 'sound'
                                ? null
                                : () => _pickNewItemImage(
                                      targetKey: 'sound',
                                      gameKey: 'sonidos',
                                      source: ImageSource.gallery,
                                      onUploaded: (url) {
                                        setState(() {
                                          _soundImageController.text = url;
                                        });
                                      },
                                    ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: NebulaSecondaryButton(
                            text: _newItemBusyKey == 'sound'
                                ? 'Subiendo...'
                                : 'Tomar foto',
                            onPressed: _newItemBusyKey == 'sound'
                                ? null
                                : () => _pickNewItemImage(
                                      targetKey: 'sound',
                                      gameKey: 'sonidos',
                                      source: ImageSource.camera,
                                      onUploaded: (url) {
                                        setState(() {
                                          _soundImageController.text = url;
                                        });
                                      },
                                    ),
                          ),
                        ),
                      ],
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
                      'Dilo',
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
                          value: _diloDifficulty,
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('1')),
                            DropdownMenuItem(value: 2, child: Text('2')),
                            DropdownMenuItem(value: 3, child: Text('3')),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _diloDifficulty = value);
                          },
                        ),
                      ],
                    ),
                    TextField(
                      controller: _diloImageController,
                      decoration: const InputDecoration(
                        labelText: 'Ruta o URL de imagen',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _diloTextController,
                      decoration: const InputDecoration(
                        labelText: 'Texto/Palabra',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _diloAudioController,
                      decoration: const InputDecoration(
                        labelText: 'URL de audio (MP3/M4A/WAV)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: NebulaSecondaryButton(
                            text: _newItemBusyKey?.startsWith('dilo_image') ==
                                    true
                                ? 'Subiendo...'
                                : 'Subir imagen',
                            onPressed:
                                _newItemBusyKey?.startsWith('dilo') == true
                                    ? null
                                    : () => _pickNewItemImage(
                                          targetKey: 'dilo_image',
                                          gameKey: 'dilo',
                                          source: ImageSource.gallery,
                                          onUploaded: (url) {
                                            setState(() {
                                              _diloImageController.text = url;
                                            });
                                          },
                                        ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: NebulaSecondaryButton(
                            text: _newItemBusyKey?.startsWith('dilo_audio') ==
                                    true
                                ? 'Subiendo...'
                                : 'Subir audio',
                            onPressed:
                                _newItemBusyKey?.startsWith('dilo') == true
                                    ? null
                                    : () => _pickNewItemAudio(
                                          targetKey: 'dilo_audio',
                                          gameKey: 'dilo',
                                          onUploaded: (url) {
                                            setState(() {
                                              _diloAudioController.text = url;
                                            });
                                          },
                                        ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    NebulaSecondaryButton(
                      text: 'Agregar item de Dilo',
                      onPressed: _addDiloItem,
                    ),
                    const SizedBox(height: 10),
                    if (diloItems.isEmpty)
                      const Text('Sin items personalizados.')
                    else
                      ...diloItems.map((item) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Switch(
                              value: item.enabled,
                              onChanged: (value) =>
                                  _toggleDiloItem(item.id, value),
                            ),
                            title: Text(
                              'D${item.difficultyStars} | ${item.text}',
                            ),
                            subtitle: Text(
                              item.imagePath,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _removeDiloItem(item.id),
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
                      'Cartas gemelas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _memoryImageController,
                      decoration: const InputDecoration(
                        labelText: 'Ruta o URL de imagen',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _memoryAudioController,
                      decoration: const InputDecoration(
                        labelText: 'URL de audio (opcional)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: NebulaSecondaryButton(
                            text: _newItemBusyKey == 'memory_image'
                                ? 'Subiendo...'
                                : 'Subir imagen',
                            onPressed:
                                _newItemBusyKey?.startsWith('memory') == true
                                    ? null
                                    : () => _pickNewItemImage(
                                          targetKey: 'memory_image',
                                          gameKey: 'cartas_gemelas',
                                          source: ImageSource.gallery,
                                          onUploaded: (url) {
                                            setState(() {
                                              _memoryImageController.text = url;
                                            });
                                      },
                                    ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: NebulaSecondaryButton(
                            text: _newItemBusyKey == 'memory_image'
                                ? 'Subiendo...'
                                : 'Tomar foto',
                            onPressed:
                                _newItemBusyKey?.startsWith('memory') == true
                                    ? null
                                    : () => _pickNewItemImage(
                                          targetKey: 'memory_image',
                                          gameKey: 'cartas_gemelas',
                                          source: ImageSource.camera,
                                          onUploaded: (url) {
                                            setState(() {
                                              _memoryImageController.text = url;
                                            });
                                      },
                                    ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    NebulaSecondaryButton(
                      text: _newItemBusyKey == 'memory_audio'
                          ? 'Subiendo...'
                          : 'Subir audio',
                      onPressed:
                          _newItemBusyKey?.startsWith('memory') == true
                              ? null
                              : () => _pickNewItemAudio(
                                    targetKey: 'memory_audio',
                                    gameKey: 'cartas_gemelas',
                                    onUploaded: (url) {
                                      setState(() {
                                        _memoryAudioController.text = url;
                                      });
                                    },
                                  ),
                    ),
                    const SizedBox(height: 10),
                    NebulaSecondaryButton(
                      text: 'Agregar imagen',
                      onPressed: _addMemoryItem,
                    ),
                    const SizedBox(height: 10),
                    if (memoryItems.isEmpty)
                      const Text('Sin imagenes personalizadas.')
                    else
                      ...memoryItems.map((item) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Switch(
                              value: item.enabled,
                              onChanged: (value) =>
                                  _toggleMemoryItem(item.id, value),
                            ),
                            title: Text(item.id),
                            subtitle: Text(
                              item.audioSource.isEmpty
                                  ? item.imagePath
                                  : '${item.imagePath} | Audio: ${item.audioSource}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _removeMemoryItem(item.id),
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
                      controller: _puzzleAudioController,
                      decoration: const InputDecoration(
                        labelText: 'URL de audio (opcional)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    NebulaSecondaryButton(
                      text: _newItemBusyKey == 'puzzle_audio'
                          ? 'Subiendo...'
                          : 'Subir audio',
                      onPressed:
                          _newItemBusyKey?.startsWith('puzzle') == true
                              ? null
                              : () => _pickNewItemAudio(
                                    targetKey: 'puzzle_audio',
                                    gameKey: 'puzzle',
                                    onUploaded: (url) {
                                      setState(() {
                                        _puzzleAudioController.text = url;
                                      });
                                    },
                                  ),
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
                              item.audioSource.isEmpty
                                  ? item.imageSource
                                  : '${item.imageSource} | Audio: ${item.audioSource}',
                              maxLines: 2,
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explora',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Interfaz preparada. Este juego aún no tiene lógica de contenido editable.',
                    ),
                    const SizedBox(height: 10),
                    const NebulaSecondaryButton(
                      text: 'Subir imagen (próximamente)',
                      onPressed: null,
                    ),
                    const SizedBox(height: 8),
                    const NebulaSecondaryButton(
                      text: 'Subir audio (próximamente)',
                      onPressed: null,
                    ),
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
                      'Dónde va',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Interfaz preparada. Este juego aún no tiene lógica de contenido editable.',
                    ),
                    const SizedBox(height: 10),
                    const NebulaSecondaryButton(
                      text: 'Subir imagen (próximamente)',
                      onPressed: null,
                    ),
                    const SizedBox(height: 8),
                    const NebulaSecondaryButton(
                      text: 'Subir audio (próximamente)',
                      onPressed: null,
                    ),
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
    this.expectedConcepts = const <String>[],
    this.expectedEmotion = '',
    this.expectedDescription = '',
  });

  final String gameKey;
  final String itemId;
  final String title;
  final String subtitle;
  final String defaultSource;
  final List<String> expectedConcepts;
  final String expectedEmotion;
  final String expectedDescription;
}
