import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/app_controller.dart';
import '../../core/data/donde_va_catalog.dart';
import '../../core/data/explore_catalog.dart';
import '../../core/data/memory_catalog.dart';
import '../../core/data/puzzle_catalog.dart';
import '../../models/game_content_config.dart';
import '../../services/image_ai_review_service.dart';
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
    'assets/images/conecta/ni\u00f1os.jpg',
    'assets/images/conecta/tormenta.jpg',
    'assets/images/conecta/coro.jpg',
  ];

  final _emotionImageController = TextEditingController();
  final _emotionCorrectController = TextEditingController();
  final _soundAssetController = TextEditingController();
  final _soundImageController = TextEditingController();
  final _soundCategoryController = TextEditingController();
  final _puzzleAudioController = TextEditingController();
  final _diloImageController = TextEditingController();
  final _diloTextController = TextEditingController();
  final _diloAudioController = TextEditingController();
  final _memoryImageController = TextEditingController();
  final _memoryAudioController = TextEditingController();
  final _exploreTitleController = TextEditingController();
  final _exploreDescriptionController = TextEditingController();
  final _picker = ImagePicker();

  static const int _maxPuzzleImages = 8;
  static const int _maxPuzzleBytes = 220 * 1024;
  static const int _minPuzzleSide = 256;
  static const int _maxPuzzleSide = 1024;

  int _emotionDifficulty = 1;
  int _soundDifficulty = 1;
  int _diloDifficulty = 1;
  String _exploreCategoryId = exploreCategoryDefinitions.first.id;
  String? _editingExploreItemId;
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
    _puzzleAudioController.dispose();
    _diloImageController.dispose();
    _diloTextController.dispose();
    _diloAudioController.dispose();
    _memoryImageController.dispose();
    _memoryAudioController.dispose();
    _exploreTitleController.dispose();
    _exploreDescriptionController.dispose();
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
        message:
            'Selecciona una imagen y completa la emoci\u00f3n correcta.',
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
        message: 'Completa el sonido base y selecciona la imagen correcta.',
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

  List<ExploreContentItem> _effectiveExploreItems() {
    return mergeExploreItems(_working.exploreItems);
  }

  ExploreContentItem? _effectiveExploreItemById(String id) {
    final normalized = id.trim().toLowerCase();
    for (final item in _effectiveExploreItems()) {
      if (item.id.trim().toLowerCase() == normalized) return item;
    }
    return null;
  }

  void _startExploreEdit(ExploreContentItem item) {
    setState(() {
      _editingExploreItemId = item.id;
      _exploreCategoryId = item.categoryId;
      _exploreTitleController.text = item.title;
      _exploreDescriptionController.text = item.description;
    });
  }

  void _cancelExploreEdit() {
    setState(() {
      _editingExploreItemId = null;
      _exploreCategoryId = exploreCategoryDefinitions.first.id;
      _exploreTitleController.clear();
      _exploreDescriptionController.clear();
    });
  }

  Future<void> _submitExploreItem() async {
    final title = _exploreTitleController.text.trim();
    final description = _exploreDescriptionController.text.trim();
    if (title.isEmpty || description.isEmpty) {
      await NebulaSnack.show(
        context,
        message: 'Completa el titulo y la descripcion del elemento.',
        ok: false,
      );
      return;
    }

    final editingId = _editingExploreItemId;
    final current =
        editingId == null ? null : _effectiveExploreItemById(editingId);
    final nextItem = ExploreContentItem(
      id: editingId ?? 'explore_${DateTime.now().microsecondsSinceEpoch}',
      categoryId: _exploreCategoryId,
      title: title,
      description: description,
      enabled: current?.enabled ?? true,
    );

    final nextItems = List<ExploreContentItem>.from(_working.exploreItems);
    final existingIndex = nextItems.indexWhere(
      (item) => item.id.trim().toLowerCase() == nextItem.id.trim().toLowerCase(),
    );
    if (existingIndex >= 0) {
      nextItems[existingIndex] = nextItem;
    } else {
      nextItems.add(nextItem);
    }

    setState(() {
      _working = _working.copyWith(exploreItems: nextItems);
    });
    _cancelExploreEdit();
    await NebulaSnack.show(
      context,
      message: editingId == null
          ? 'Elemento de Explora agregado.'
          : 'Elemento de Explora actualizado.',
      ok: true,
    );
  }

  void _toggleExploreItem(ExploreContentItem item, bool value) {
    final nextItems = List<ExploreContentItem>.from(_working.exploreItems);
    final existingIndex = nextItems.indexWhere(
      (entry) => entry.id.trim().toLowerCase() == item.id.trim().toLowerCase(),
    );
    final updated = item.copyWith(enabled: value);
    if (existingIndex >= 0) {
      nextItems[existingIndex] = updated;
    } else {
      nextItems.add(updated);
    }
    setState(() {
      _working = _working.copyWith(exploreItems: nextItems);
    });
  }

  Future<void> _deleteExploreItem(ExploreContentItem item) async {
    final isDefault = isDefaultExploreItemId(item.id);
    final accepted = await _confirmDeleteContentItem(
      title: isDefault
          ? 'Ocultar elemento predeterminado'
          : 'Eliminar elemento de Explora',
      message: isDefault
          ? 'Este elemento viene con la app. Si continuas, dejara de aparecer en Explora y aprende hasta que lo vuelvas a activar o edites de nuevo.'
          : 'Esta acci\u00f3n eliminar\u00e1 este elemento personalizado de Explora y aprende en futuras sesiones. \u00bfDeseas continuar?',
      confirmLabel: isDefault ? 'Ocultar' : 'Eliminar',
    );
    if (!accepted) return;

    final nextItems = List<ExploreContentItem>.from(_working.exploreItems);
    final existingIndex = nextItems.indexWhere(
      (entry) => entry.id.trim().toLowerCase() == item.id.trim().toLowerCase(),
    );

    if (isDefault) {
      final updated = item.copyWith(enabled: false);
      if (existingIndex >= 0) {
        nextItems[existingIndex] = updated;
      } else {
        nextItems.add(updated);
      }
    } else if (existingIndex >= 0) {
      nextItems.removeAt(existingIndex);
    }

    setState(() {
      _working = _working.copyWith(exploreItems: nextItems);
      if (_editingExploreItemId == item.id) {
        _editingExploreItemId = null;
        _exploreCategoryId = exploreCategoryDefinitions.first.id;
        _exploreTitleController.clear();
        _exploreDescriptionController.clear();
      }
    });
  }

  Future<bool> _addMemoryItemFromSource(String imagePath) async {
    final audioSource = _memoryAudioController.text.trim();
    if (imagePath.isEmpty) {
      NebulaSnack.show(
        context,
        message: 'Selecciona una imagen.',
        ok: false,
      );
      return false;
    }
    final imageOk = await _validateImageSource(
      imagePath,
      label: 'imagen',
    );
    if (!imageOk) return false;
    if (audioSource.isNotEmpty) {
      final audioOk = await _validateAudioSource(audioSource);
      if (!audioOk) return false;
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
    return true;
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

  Future<void> _replaceMemoryItemImage({
    required MemoryContentItem item,
    required ImageSource source,
  }) async {
    await _pickNewItemImage(
      targetKey: 'memory_edit_${item.id}',
      gameKey: 'cartas_gemelas',
      source: source,
      onUploaded: (url) {
        setState(() {
          final next = _working.memoryItems.map((current) {
            if (current.id != item.id) return current;
            return current.copyWith(imagePath: url);
          }).toList();
          _working = _working.copyWith(memoryItems: next);
        });
        return true;
      },
    );
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
    if (normalized.isEmpty) return 'emoci\u00f3n esperada';
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
          .replaceAll('\\u00e1', 'a')
          .replaceAll('\\u00e9', 'e')
          .replaceAll('\\u00ed', 'i')
          .replaceAll('\\u00f3', 'o')
          .replaceAll('\\u00fa', 'u')
          .replaceAll('\\u00fc', 'u')
          .replaceAll('\\u00f1', 'n')
          .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
          .replaceAll(RegExp(r'\\s+'), ' ')
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
      return 'Aparece en dificultad facil';
    }
    if (normalized.contains('/medio/')) {
      return 'Aparece en dificultad media';
    }
    if (normalized.contains('/dificil/')) {
      return 'Aparece en dificultad dificil';
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
      'puzzle' =>
        (_working.globalPuzzleImageOverrides[key]?.trim().isNotEmpty ?? false),
      'cartas_gemelas' =>
        (_working.globalMemoryImageOverrides[key]?.trim().isNotEmpty ?? false),
      'donde_va' =>
        (_working.globalDondeVaImageOverrides[key]?.trim().isNotEmpty ?? false),
      _ => false,
    };
  }

  Future<bool> _reviewAdminImageUpload({
    required String filePath,
    required String gameKey,
    required String itemId,
    List<String> expectedConcepts = const <String>[],
    String expectedEmotion = '',
    String expectedDescription = '',
  }) async {
    final concepts = expectedConcepts
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final review = await ImageAiReviewService.reviewImage(
      filePath: filePath,
      context: ImageAiReviewContext(
        gameKey: gameKey,
        itemId: itemId,
        expectedConcepts: concepts,
        expectedEmotion: expectedEmotion.trim(),
        expectedDescription: expectedDescription.trim(),
      ),
    );
    if (review.ok) return true;
    if (!mounted) return false;
    await NebulaSnack.show(
      context,
      message: review.message,
      ok: false,
    );
    return false;
  }

  bool _hasGlobalOverrideForItem(_GlobalDefaultImageItem item) {
    if (_hasGlobalOverride(gameKey: item.gameKey, itemId: item.itemId)) {
      return true;
    }
    final legacyItemId = item.defaultSource.trim();
    if (legacyItemId.isEmpty ||
        legacyItemId.toLowerCase() == item.itemId.trim().toLowerCase()) {
      return false;
    }
    return _hasGlobalOverride(gameKey: item.gameKey, itemId: legacyItemId);
  }

  String _effectiveGlobalImageSourceForItem(_GlobalDefaultImageItem item) {
    final primary = widget.controller.resolvedGameImageSourceFor(
      gameKey: item.gameKey,
      itemId: item.itemId,
      defaultSource: item.defaultSource,
    );
    if (primary.trim().isNotEmpty && primary.trim() != item.defaultSource) {
      return primary;
    }
    final legacyItemId = item.defaultSource.trim();
    if (legacyItemId.isEmpty ||
        legacyItemId.toLowerCase() == item.itemId.trim().toLowerCase()) {
      return primary;
    }
    return widget.controller.resolvedGameImageSourceFor(
      gameKey: item.gameKey,
      itemId: legacyItemId,
      defaultSource: item.defaultSource,
    );
  }

  Future<void> _pickGlobalImageForItem({
    required _GlobalDefaultImageItem item,
    required ImageSource source,
  }) async {
    final gameKey = item.gameKey;
    final itemId = item.itemId;
    final busyKey = '$gameKey::$itemId';
    setState(() => _globalBusyKey = busyKey);
    try {
      final previousSource = _effectiveGlobalImageSourceForItem(item);
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
        expectedConcepts: item.expectedConcepts,
        expectedEmotion: item.expectedEmotion,
        expectedDescription: item.expectedDescription,
      );
      if (!mounted) return;
      if (result.ok) {
        final nextSource = _effectiveGlobalImageSourceForItem(item);
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

  Future<void> _restoreGlobalImageForItem(_GlobalDefaultImageItem item) async {
    final restoreItemId =
        _hasGlobalOverride(gameKey: item.gameKey, itemId: item.itemId)
            ? item.itemId
            : item.defaultSource;
    final previousSource = _effectiveGlobalImageSourceForItem(item);
    final result = await widget.controller.restoreGlobalGameImage(
      gameKey: item.gameKey,
      itemId: restoreItemId,
    );
    if (!mounted) return;
    if (result.ok) {
      final nextSource = _effectiveGlobalImageSourceForItem(item);
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

  Future<void> _openGlobalSourceSheet(_GlobalDefaultImageItem item) async {
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
                  await _pickGlobalImageForItem(
                    item: item,
                    source: ImageSource.camera,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Usar galer\u00eda'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pickGlobalImageForItem(
                    item: item,
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

  Future<bool> _confirmDeleteContentItem({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC93C4C),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return accepted ?? false;
  }

  Future<void> _showContentImagePreview({
    required String title,
    required String imageSource,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Center(
                child: PuzzleImageAdapter(
                  imageSource: imageSource,
                  size: 260,
                  borderRadius: 20,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openExistingItemImageSheet({
    required String title,
    required Future<void> Function(ImageSource source) onPick,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar foto'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await onPick(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Usar galer\u00eda'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await onPick(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteMemoryItem(MemoryContentItem item) async {
    final accepted = await _confirmDeleteContentItem(
      title: 'Eliminar imagen de Cartas gemelas',
      message:
          'Esta acci\u00f3n quitar\u00e1 esta imagen del contenido global de Cartas gemelas en futuras partidas. No elimina personalizaciones de ni\u00f1os ni borra otros archivos ya usados. \u00bfDeseas continuar?',
      confirmLabel: 'Eliminar',
    );
    if (!accepted) return;
    setState(() {
      final next = _working.memoryItems
          .where((current) => current.id != item.id)
          .toList();
      _working = _working.copyWith(memoryItems: next);
    });
  }

  Future<void> _deletePuzzleItem(PuzzleContentItem item) async {
    final accepted = await _confirmDeleteContentItem(
      title: 'Eliminar imagen de rompecabezas',
      message:
          'Esta acci\u00f3n quitar\u00e1 esta imagen del contenido global de Arma la imagen en futuras partidas. No elimina personalizaciones de ni\u00f1os ni borra otros archivos ya usados. \u00bfDeseas continuar?',
      confirmLabel: 'Eliminar',
    );
    if (!accepted) return;
    setState(() {
      final next = _working.puzzleItems
          .where((current) => current.id != item.id)
          .toList();
      _working = _working.copyWith(puzzleItems: next);
    });
  }

  Future<bool> _ensureEmotionUploadContext() async {
    final emotion = _emotionCorrectController.text.trim();
    if (emotion.isNotEmpty) return true;
    await NebulaSnack.show(
      context,
      message:
          'Primero escribe la emoci\u00f3n correcta. La IA necesita ese contexto antes de revisar la imagen.',
      ok: false,
    );
    return false;
  }

  Future<void> _pickEmotionImage(ImageSource source) async {
    if (!await _ensureEmotionUploadContext()) return;
    final emotion = _emotionCorrectController.text.trim();
    await _pickNewItemImage(
      targetKey: 'emotion',
      gameKey: 'emociones',
      source: source,
      onUploaded: (url) {
        setState(() {
          _emotionImageController.text = url;
        });
        return true;
      },
      expectedEmotion: emotion,
      expectedDescription: emotion,
    );
  }

  Future<bool> _ensureSoundUploadContext() async {
    final soundAsset = _soundAssetController.text.trim();
    if (soundAsset.isNotEmpty) return true;
    await NebulaSnack.show(
      context,
      message:
          'Primero indica el sonido base. La IA necesita saber que debe representar la imagen correcta.',
      ok: false,
    );
    return false;
  }

  List<String> _currentSoundExpectedConcepts() => <String>[
        ..._expectedConceptsFromSource(_soundAssetController.text),
        _soundCategoryController.text.trim(),
      ];

  String _currentSoundExpectedDescription() {
    final soundName = _prettyNameFromSource(_soundAssetController.text);
    if (soundName != 'Elemento') return soundName;
    return _soundCategoryController.text.trim();
  }

  Future<void> _pickSoundImage(ImageSource source) async {
    if (!await _ensureSoundUploadContext()) return;
    await _pickNewItemImage(
      targetKey: 'sound',
      gameKey: 'sonidos',
      source: source,
      onUploaded: (url) {
        setState(() {
          _soundImageController.text = url;
        });
        return true;
      },
      expectedConcepts: _currentSoundExpectedConcepts(),
      expectedDescription: _currentSoundExpectedDescription(),
    );
  }

  Future<bool> _ensureDiloUploadContext() async {
    final text = _diloTextController.text.trim();
    if (text.isNotEmpty) return true;
    await NebulaSnack.show(
      context,
      message:
          'Primero escribe la palabra o texto. La IA usa ese contexto para validar la imagen.',
      ok: false,
    );
    return false;
  }

  Future<void> _pickDiloImage(ImageSource source) async {
    if (!await _ensureDiloUploadContext()) return;
    final text = _diloTextController.text.trim();
    await _pickNewItemImage(
      targetKey: 'dilo_image',
      gameKey: 'dilo',
      source: source,
      onUploaded: (url) {
        setState(() {
          _diloImageController.text = url;
        });
        return true;
      },
      expectedConcepts: <String>[text],
      expectedDescription: text,
    );
  }

  Future<void> _pickNewItemImage({
    required String targetKey,
    required String gameKey,
    required ImageSource source,
    required FutureOr<bool> Function(String url) onUploaded,
    String successMessage = 'Imagen subida. Completa los campos y agrega el item.',
    List<String> expectedConcepts = const <String>[],
    String expectedEmotion = '',
    String expectedDescription = '',
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
      final uploadItemId = 'content_${DateTime.now().microsecondsSinceEpoch}';
      final reviewOk = await _reviewAdminImageUpload(
        filePath: prepared.filePath,
        gameKey: gameKey,
        itemId: uploadItemId,
        expectedConcepts: expectedConcepts,
        expectedEmotion: expectedEmotion,
        expectedDescription: expectedDescription,
      );
      if (!reviewOk) return;

      final upload = await widget.controller.authService.uploadGlobalGameImageFile(
        gameKey: gameKey,
        itemId: uploadItemId,
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
      final handled = await onUploaded(upload.data!.downloadUrl);
      if (!handled) return;
      await NebulaSnack.show(
        context,
        message: successMessage,
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
        message: 'L\u00edmite alcanzado: m\u00e1ximo $_maxPuzzleImages im\u00e1genes.',
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
    final reviewOk = await _reviewAdminImageUpload(
      filePath: picked.path,
      gameKey: 'puzzle',
      itemId: 'puzzle_${DateTime.now().microsecondsSinceEpoch}',
      expectedDescription: 'rompecabezas',
    );
    if (!reviewOk) return;

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
        message: 'Completa la imagen de $label.',
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
          'No encontramos la imagen de $label. Usa una imagen seleccionada desde el dispositivo, un asset o una ruta local existente.',
      ok: false,
    );
    return false;
  }

  Future<bool> _validateAudioSource(String raw) async {
    final source = raw.trim();
    if (source.isEmpty) {
      await NebulaSnack.show(
        context,
        message: 'Completa el audio.',
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
          'No encontramos el audio. Usa un audio subido, un asset o una ruta local existente.',
      ok: false,
    );
    return false;
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

  Future<void> _replacePuzzleItemImage({
    required PuzzleContentItem item,
    required ImageSource source,
  }) async {
    await _pickNewItemImage(
      targetKey: 'puzzle_edit_${item.id}',
      gameKey: 'puzzle',
      source: source,
      onUploaded: (url) {
        setState(() {
          final next = _working.puzzleItems.map((current) {
            if (current.id != item.id) return current;
            return current.copyWith(
              imageSource: url,
              width: 0,
              height: 0,
            );
          }).toList();
          _working = _working.copyWith(puzzleItems: next);
        });
        return true;
      },
    );
  }

  List<_GlobalDefaultImageItem> _mergeConfiguredItemsIntoDefaults({
    required List<_GlobalDefaultImageItem> defaults,
    required Iterable<_GlobalDefaultImageItem> configuredItems,
  }) {
    final seen = <String>{
      ...defaults.map((item) => item.defaultSource.trim().toLowerCase()),
    };
    final merged = <_GlobalDefaultImageItem>[...defaults];
    for (final item in configuredItems) {
      final sourceKey = item.defaultSource.trim().toLowerCase();
      if (sourceKey.isEmpty || seen.contains(sourceKey)) continue;
      seen.add(sourceKey);
      merged.add(item);
    }
    return merged;
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
          final effectiveSource = _effectiveGlobalImageSourceForItem(item);
          final hasOverride = _hasGlobalOverrideForItem(item);
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
                            : (item.isOriginalAppDefault
                                ? 'Usando imagen original de la app.'
                                : 'Usando imagen agregada por admin.'),
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
                                : () => _openGlobalSourceSheet(item),
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
                                ? () => _restoreGlobalImageForItem(item)
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

  Widget _buildExploreAdminCard({
    required List<ExploreContentItem> items,
  }) {
    final isEditing = _editingExploreItemId != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Explora y aprende',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aqu\u00ed editas el contenido informativo que el juego muestra al tocar cada tarjeta. Puedes agregar elementos nuevos, ajustar la descripci\u00f3n y desactivar los que no quieras usar.',
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              key: ValueKey('explore_category_$_exploreCategoryId'),
              initialValue: _exploreCategoryId,
              decoration: const InputDecoration(
                labelText: 'Categor\u00eda',
              ),
              items: exploreCategoryDefinitions
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: category.id,
                      child: Text(category.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _exploreCategoryId = value);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _exploreTitleController,
              decoration: const InputDecoration(
                labelText: 'T\u00edtulo del elemento',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _exploreDescriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripci\u00f3n informativa',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: NebulaSecondaryButton(
                    text: isEditing ? 'Guardar cambios' : 'Agregar elemento',
                    onPressed: _submitExploreItem,
                  ),
                ),
                if (isEditing) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: NebulaSecondaryButton(
                      text: 'Cancelar edici\u00f3n',
                      onPressed: _cancelExploreEdit,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              const Text('Sin elementos configurados para Explora y aprende.')
            else
              ...exploreCategoryDefinitions.map((category) {
                final categoryItems = exploreItemsForCategory(
                  items: items,
                  categoryId: category.id,
                );
                if (categoryItems.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      ...categoryItems.map((item) {
                        final isDefault = isDefaultExploreItemId(item.id);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F8FC),
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: const Color(0xFFDCE4F2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.description,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          isDefault
                                              ? 'Elemento base de la app'
                                              : 'Elemento agregado por admin',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color:
                                                    const Color(0xFF54637E),
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: item.enabled,
                                    onChanged: (value) =>
                                        _toggleExploreItem(item, value),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  FilledButton.icon(
                                    onPressed: () => _startExploreEdit(item),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Editar'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _deleteExploreItem(item),
                                    icon: const Icon(Icons.delete_outline),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          const Color(0xFFC93C4C),
                                    ),
                                    label: Text(
                                      isDefault ? 'Ocultar' : 'Eliminar',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
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
    final diloItems = [..._working.diloItems]
      ..sort((a, b) => a.difficultyStars.compareTo(b.difficultyStars));
    final memoryItems = [..._working.memoryItems];
    final defaultEmotionItems = _defaultEmotionImages
        .map(
          (source) => _GlobalDefaultImageItem(
            gameKey: 'emociones',
            itemId: widget.controller.customContentItemId(source: source),
            title: _prettyNameFromSource(source),
            subtitle: _emotionDifficultyLabel(source),
            defaultSource: source,
            expectedEmotion: _emotionFromSource(source),
            expectedDescription: _prettyEmotionName(_emotionFromSource(source)),
          ),
        )
        .toList();
    final mergedEmotionItems = _mergeConfiguredItemsIntoDefaults(
      defaults: defaultEmotionItems,
      configuredItems: emotionItems
          .where(
            (item) =>
                item.imagePath.trim().isNotEmpty &&
                item.correctEmotion.trim().isNotEmpty,
          )
          .map(
            (item) => _GlobalDefaultImageItem(
              gameKey: 'emociones',
              itemId: widget.controller.customContentItemId(
                source: item.imagePath.trim(),
                rawId: item.id,
              ),
              title: _prettyNameFromSource(item.imagePath),
              subtitle: 'Imagen agregada por admin a Descubre emoci\u00f3n.',
              defaultSource: item.imagePath.trim(),
              expectedEmotion: item.correctEmotion.trim(),
              expectedDescription:
                  _prettyEmotionName(item.correctEmotion.trim()),
              isOriginalAppDefault: false,
            ),
          ),
    );
    final defaultSoundItems = _defaultSoundImages
        .map(
          (source) => _GlobalDefaultImageItem(
            gameKey: 'sonidos',
            itemId: widget.controller.customContentItemId(source: source),
            title: _prettyNameFromSource(source),
            subtitle: 'Se usa como imagen predeterminada en Conecta sonidos.',
            defaultSource: source,
            expectedConcepts: _expectedConceptsFromSource(source),
            expectedDescription: _prettyNameFromSource(source),
          ),
        )
        .toList();
    final mergedSoundItems = _mergeConfiguredItemsIntoDefaults(
      defaults: defaultSoundItems,
      configuredItems: soundItems
          .where(
            (item) =>
                item.correctImage.trim().isNotEmpty &&
                item.soundAsset.trim().isNotEmpty,
          )
          .map(
            (item) => _GlobalDefaultImageItem(
              gameKey: 'sonidos',
              itemId: widget.controller.customContentItemId(
                source: item.correctImage.trim(),
                rawId: item.id,
              ),
              title: _prettyNameFromSource(item.correctImage),
              subtitle: 'Imagen agregada por admin a Conecta sonidos.',
              defaultSource: item.correctImage.trim(),
              expectedConcepts: <String>[
                ..._expectedConceptsFromSource(item.soundAsset),
                item.category.trim(),
              ],
              expectedDescription: _prettyNameFromSource(item.soundAsset) ==
                      'Elemento'
                  ? item.category.trim()
                  : _prettyNameFromSource(item.soundAsset),
              isOriginalAppDefault: false,
            ),
          ),
    );
    final defaultMemoryItems = defaultMemoryImageSources
        .map(
          (source) => _GlobalDefaultImageItem(
            gameKey: 'cartas_gemelas',
            itemId: source,
            title: _prettyNameFromSource(source),
            subtitle: 'Se usa como imagen base global en Cartas gemelas.',
            defaultSource: source,
            expectedConcepts: _expectedConceptsFromSource(source),
            expectedDescription: _prettyNameFromSource(source),
          ),
        )
        .toList();
    final defaultPuzzleItems = defaultPuzzleImageSources
        .map(
          (source) => _GlobalDefaultImageItem(
            gameKey: 'puzzle',
            itemId: source,
            title: _prettyNameFromSource(source),
            subtitle: 'Se usa como imagen base global en Arma la imagen.',
            defaultSource: source,
            expectedConcepts: _expectedConceptsFromSource(source),
            expectedDescription: _prettyNameFromSource(source),
          ),
        )
        .toList();
    final mergedMemoryItems = _mergeConfiguredItemsIntoDefaults(
      defaults: defaultMemoryItems,
      configuredItems: memoryItems
          .where((item) => item.imagePath.trim().isNotEmpty)
          .map(
            (item) => _GlobalDefaultImageItem(
              gameKey: 'cartas_gemelas',
              itemId: item.imagePath.trim(),
              title: _prettyNameFromSource(item.imagePath),
              subtitle: 'Imagen agregada por admin a Cartas gemelas.',
              defaultSource: item.imagePath.trim(),
              expectedConcepts: _expectedConceptsFromSource(item.imagePath),
              expectedDescription: _prettyNameFromSource(item.imagePath),
              isOriginalAppDefault: false,
            ),
          ),
    );
    final mergedPuzzleItems = _mergeConfiguredItemsIntoDefaults(
      defaults: defaultPuzzleItems,
      configuredItems: puzzleItems
          .where((item) => item.imageSource.trim().isNotEmpty)
          .map(
            (item) => _GlobalDefaultImageItem(
              gameKey: 'puzzle',
              itemId: item.imageSource.trim(),
              title: _prettyNameFromSource(item.imageSource),
              subtitle: 'Imagen agregada por admin a Arma la imagen.',
              defaultSource: item.imageSource.trim(),
              expectedConcepts: _expectedConceptsFromSource(item.imageSource),
              expectedDescription: _prettyNameFromSource(item.imageSource),
              isOriginalAppDefault: false,
            ),
          ),
    );
    final effectiveExploreItems = _effectiveExploreItems();
    final dondeVaDefaultSections = <Widget>[
      for (final category in dondeVaCategories) ...[
        _buildGlobalDefaultsCard(
          title:
              'Predeterminadas globales \u00b7 D\u00f3nde va \u00b7 ${category.label}',
          description:
              'Puedes actualizar la imagen base de cada objeto de ${category.label.toLowerCase()} para todas las cuentas.',
          items: category.items
              .map(
                (item) => _GlobalDefaultImageItem(
                  gameKey: 'donde_va',
                  itemId: dondeVaGlobalItemId(
                    categoryId: category.id,
                    itemId: item.id,
                  ),
                  title: item.label,
                  subtitle: 'Categor\u00eda: ${category.label}',
                  defaultSource: dondeVaItemAssetPath(
                    categoryId: category.id,
                    itemId: item.id,
                    extension: item.assetExtension,
                  ),
                  expectedConcepts: <String>[category.label, item.label],
                  expectedDescription: '${item.label} en ${category.label}',
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 10),
      ],
    ];
    final totalDondeVaItems = dondeVaCategories.fold<int>(
      0,
      (sum, category) => sum + category.items.length,
    );

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
                      'Aqu\u00ed defines recursos globales de juegos. Los cambios se reflejan en todas las cuentas, mientras las personalizaciones del ni\u00f1o tienen prioridad. Las nuevas im\u00e1genes pasan por validaciones de formato, recorte y revisi\u00f3n de contenido antes de subirse.',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Emociones: ${_working.emotionItems.length}  |  Sonidos: ${_working.soundItems.length}  |  Dilo: ${_working.diloItems.length}  |  Cartas: ${_working.memoryItems.length}  |  Puzzle: ${_working.puzzleItems.length}  |  Explora: ${effectiveExploreItems.length}  |  D\u00f3nde va: $totalDondeVaItems',
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
              title: 'Predeterminadas globales \u00b7 Emociones',
              description:
                  'Si cambias una imagen aqu\u00ed, se actualiza para todos los usuarios que no tengan una personalizaci\u00f3n propia del ni\u00f1o.',
              items: mergedEmotionItems,
            ),
            const SizedBox(height: 10),
            _buildGlobalDefaultsCard(
              title: 'Predeterminadas globales \u00b7 Conecta sonidos',
              description:
                  'Estas im\u00e1genes son la base global del juego. Las personalizaciones del cuidador por ni\u00f1o siguen teniendo prioridad.',
              items: mergedSoundItems,
            ),
            const SizedBox(height: 10),
            _buildGlobalDefaultsCard(
              title: 'Predeterminadas globales \u00b7 Cartas gemelas',
              description:
                  'Estas im\u00e1genes base se usan en Cartas gemelas para todos los usuarios que no tengan una personalizaci\u00f3n propia.',
              items: mergedMemoryItems,
            ),
            const SizedBox(height: 10),
            _buildGlobalDefaultsCard(
              title: 'Predeterminadas globales \u00b7 Arma la imagen',
              description:
                  'Estas im\u00e1genes base se usan en Arma la imagen para todos los usuarios. Puedes verlas, cambiarlas o restaurarlas.',
              items: mergedPuzzleItems,
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Descubre emoci\u00f3n',
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
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Imagen seleccionada',
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
                                : 'Subir desde galer\u00eda',
                            onPressed: _newItemBusyKey == 'emotion'
                                ? null
                                : () => _pickEmotionImage(ImageSource.gallery),
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
                                : () => _pickEmotionImage(ImageSource.camera),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    NebulaSecondaryButton(
                      text: 'Agregar \u00edtem de emoci\u00f3n',
                      onPressed: _addEmotionItem,
                    ),
                    const SizedBox(height: 10),
                    if (emotionItems.isEmpty)
                      const Text('Sin \u00edtems personalizados.')
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
                        labelText: 'Sonido base (sounds/...)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _soundImageController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Imagen correcta seleccionada',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _soundCategoryController,
                      decoration: const InputDecoration(
                        labelText: 'Categor\u00eda (opcional)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: NebulaSecondaryButton(
                            text: _newItemBusyKey == 'sound'
                                ? 'Subiendo...'
                                : 'Subir desde galer\u00eda',
                            onPressed: _newItemBusyKey == 'sound'
                                ? null
                                : () => _pickSoundImage(ImageSource.gallery),
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
                                : () => _pickSoundImage(ImageSource.camera),
                          ),
                        ),
                      ],
                    ),
                    NebulaSecondaryButton(
                      text: 'Agregar \u00edtem de sonido',
                      onPressed: _addSoundItem,
                    ),
                    const SizedBox(height: 10),
                    if (soundItems.isEmpty)
                      const Text('Sin \u00edtems personalizados.')
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
                              'D${item.difficultyStars} | ${item.category.isEmpty ? 'sin categor\u00eda' : item.category}',
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
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Imagen seleccionada',
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
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Audio seleccionado',
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
                                    : () => _pickDiloImage(ImageSource.gallery),
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
                      text: 'Agregar \u00edtem de Dilo',
                      onPressed: _addDiloItem,
                    ),
                    const SizedBox(height: 10),
                    if (diloItems.isEmpty)
                      const Text('Sin \u00edtems personalizados.')
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
                      controller: _memoryAudioController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Audio seleccionado (opcional)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Si quieres asociar un audio, s\u00fabelo primero. Luego sube la imagen y se agregar\u00e1 de inmediato a Cartas gemelas.',
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
                                          onUploaded: (url) async {
                                            setState(() {
                                              _memoryImageController.text = url;
                                            });
                                            return _addMemoryItemFromSource(url);
                                          },
                                          successMessage:
                                              'Imagen subida y agregada a Cartas gemelas.',
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
                                          onUploaded: (url) async {
                                            setState(() {
                                              _memoryImageController.text = url;
                                            });
                                            return _addMemoryItemFromSource(url);
                                          },
                                          successMessage:
                                              'Imagen subida y agregada a Cartas gemelas.',
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
                    if (memoryItems.isEmpty)
                      const Text('Sin im\u00e1genes personalizadas.')
                    else
                      ...memoryItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final busy = _newItemBusyKey == 'memory_edit_${item.id}';
                        return Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F8FC),
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: const Color(0xFFDCE4F2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _showContentImagePreview(
                                      title: 'Carta ${index + 1}',
                                      imageSource: item.imagePath,
                                    ),
                                    child: PuzzleImageAdapter(
                                      imageSource: item.imagePath,
                                      size: 88,
                                      borderRadius: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Carta ${index + 1}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.audioSource.isEmpty
                                              ? item.imagePath
                                              : '${item.imagePath}\nAudio: ${item.audioSource}',
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: item.enabled,
                                    onChanged: (value) =>
                                        _toggleMemoryItem(item.id, value),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _showContentImagePreview(
                                      title: 'Carta ${index + 1}',
                                      imageSource: item.imagePath,
                                    ),
                                    icon: const Icon(Icons.visibility_outlined),
                                    label: const Text('Ver'),
                                  ),
                                  FilledButton.icon(
                                    onPressed: busy
                                        ? null
                                        : () => _openExistingItemImageSheet(
                                              title:
                                                  'Cambiar imagen de Carta ${index + 1}',
                                              onPick: (source) =>
                                                  _replaceMemoryItemImage(
                                                item: item,
                                                source: source,
                                              ),
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
                                      busy
                                          ? 'Subiendo...'
                                          : 'Cambiar imagen',
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _deleteMemoryItem(item),
                                    icon: const Icon(Icons.delete_outline),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          const Color(0xFFC93C4C),
                                    ),
                                    label: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
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
                      'Est\u00e1ndar recomendado: entre 256x256 y 1024x1024 px, m\u00e1ximo 220 KB por imagen.',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: NebulaSecondaryButton(
                            text: 'Subir desde galer\u00eda',
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
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Audio seleccionado (opcional)',
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
                    const Text(
                      'Si quieres asociar un audio, s\u00fabelo primero. Luego sube la imagen y se agregar\u00e1 de inmediato a Arma la imagen.',
                    ),
                    const SizedBox(height: 10),
                    if (puzzleItems.isEmpty)
                      const Text('Sin im\u00e1genes de puzzle configuradas.')
                    else
                      ...puzzleItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final busy = _newItemBusyKey == 'puzzle_edit_${item.id}';
                        final sizeLabel =
                            item.width > 0 && item.height > 0
                                ? '${item.width}x${item.height}'
                                : 'Imagen configurada';
                        return Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F8FC),
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: const Color(0xFFDCE4F2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _showContentImagePreview(
                                      title: 'Imagen ${index + 1}',
                                      imageSource: item.imageSource,
                                    ),
                                    child: PuzzleImageAdapter(
                                      imageSource: item.imageSource,
                                      size: 88,
                                      borderRadius: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Imagen ${index + 1}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$sizeLabel\n${item.audioSource.isEmpty ? item.imageSource : '${item.imageSource}\nAudio: ${item.audioSource}'}',
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: item.enabled,
                                    onChanged: (value) =>
                                        _togglePuzzleItem(item.id, value),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _showContentImagePreview(
                                      title: 'Imagen ${index + 1}',
                                      imageSource: item.imageSource,
                                    ),
                                    icon: const Icon(Icons.visibility_outlined),
                                    label: const Text('Ver'),
                                  ),
                                  FilledButton.icon(
                                    onPressed: busy
                                        ? null
                                        : () => _openExistingItemImageSheet(
                                              title:
                                                  'Cambiar imagen de rompecabezas ${index + 1}',
                                              onPick: (source) =>
                                                  _replacePuzzleItemImage(
                                                item: item,
                                                source: source,
                                              ),
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
                                      busy
                                          ? 'Subiendo...'
                                          : 'Cambiar imagen',
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _deletePuzzleItem(item),
                                    icon: const Icon(Icons.delete_outline),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          const Color(0xFFC93C4C),
                                    ),
                                    label: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildExploreAdminCard(items: effectiveExploreItems),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'D\u00f3nde va',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Este juego usa im\u00e1genes base por categor\u00eda. Desde aqu\u00ed puedes actualizar la predeterminada global de cada objeto sin tocar la mec\u00e1nica de clasificaci\u00f3n.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...dondeVaDefaultSections,
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
    this.isOriginalAppDefault = true,
  });

  final String gameKey;
  final String itemId;
  final String title;
  final String subtitle;
  final String defaultSource;
  final List<String> expectedConcepts;
  final String expectedEmotion;
  final String expectedDescription;
  final bool isOriginalAppDefault;
}
