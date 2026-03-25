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
  static const List<String> _emotionOptions = <String>[
    'feliz',
    'triste',
    'enojado',
    'sorprendido',
    'asustado',
  ];

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
  final _diloImageController = TextEditingController();
  final _diloTextController = TextEditingController();
  final _diloAudioMaleController = TextEditingController();
  final _diloAudioFemaleController = TextEditingController();
  final _memoryImageController = TextEditingController();
  final _memoryAudioController = TextEditingController();
  final _exploreTitleController = TextEditingController();
  final _exploreDescriptionController = TextEditingController();
  final _exploreImageController = TextEditingController();
  final _exploreAudioMaleController = TextEditingController();
  final _exploreAudioFemaleController = TextEditingController();
  final _dondeVaLabelController = TextEditingController();
  final _dondeVaImageController = TextEditingController();
  final _picker = ImagePicker();

  static const int _maxPuzzleImages = 8;
  static const int _maxPuzzleBytes = 220 * 1024;
  static const int _minPuzzleSide = 256;
  static const int _maxPuzzleSide = 1024;

  int _emotionDifficulty = 1;
  int _soundDifficulty = 1;
  int _diloDifficulty = 1;
  String _exploreCategoryId = 'animales';
  String _dondeVaCategoryId = 'cocina';
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
    _diloImageController.dispose();
    _diloTextController.dispose();
    _diloAudioMaleController.dispose();
    _diloAudioFemaleController.dispose();
    _memoryImageController.dispose();
    _memoryAudioController.dispose();
    _exploreTitleController.dispose();
    _exploreDescriptionController.dispose();
    _exploreImageController.dispose();
    _exploreAudioMaleController.dispose();
    _exploreAudioFemaleController.dispose();
    _dondeVaLabelController.dispose();
    _dondeVaImageController.dispose();
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
        message: 'Selecciona una imagen y la emoci\u00f3n correcta.',
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
        message: 'Selecciona el audio y la imagen correcta.',
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

  Future<void> _replaceSoundItemImage({
    required SoundContentItem item,
    required ImageSource source,
  }) async {
    await _pickNewItemImage(
      targetKey: 'sound_edit_${item.id}',
      gameKey: 'sonidos',
      source: source,
      onUploaded: (url) {
        setState(() {
          final next = _working.soundItems.map((current) {
            if (current.id != item.id) return current;
            return current.copyWith(correctImage: url);
          }).toList();
          _working = _working.copyWith(soundItems: next);
        });
        return true;
      },
      expectedConcepts: _expectedConceptsFromSource(
        item.correctImage,
        extraLabels: <String>[
          if (item.category.trim().isNotEmpty) item.category.trim(),
        ],
      ),
      expectedDescription: item.category.trim().isEmpty
          ? _prettyNameFromSource(item.correctImage)
          : item.category.trim(),
    );
  }

  Future<void> _replaceSoundItemAudio(SoundContentItem item) async {
    await _pickNewItemAudio(
      targetKey: 'sound_audio_edit_${item.id}',
      gameKey: 'sonidos',
      onUploaded: (url) {
        setState(() {
          final next = _working.soundItems.map((current) {
            if (current.id != item.id) return current;
            return current.copyWith(soundAsset: url);
          }).toList();
          _working = _working.copyWith(soundItems: next);
        });
      },
    );
  }

  Future<void> _addDiloItem() async {
    final imagePath = _diloImageController.text.trim();
    final text = _diloTextController.text.trim();
    final audioMale = _diloAudioMaleController.text.trim();
    final audioFemale = _diloAudioFemaleController.text.trim();
    if (imagePath.isEmpty ||
        text.isEmpty ||
        audioMale.isEmpty ||
        audioFemale.isEmpty) {
      NebulaSnack.show(
        context,
        message:
            'Completa imagen, texto y los audios de narrador hombre y mujer.',
        ok: false,
      );
      return;
    }
    final imageOk = await _validateImageSource(
      imagePath,
      label: 'imagen',
    );
    if (!imageOk) return;
    final maleOk = await _validateAudioSource(audioMale);
    if (!maleOk) return;
    final femaleOk = await _validateAudioSource(audioFemale);
    if (!femaleOk) return;

    final item = DiloContentItem(
      id: 'dilo_${DateTime.now().microsecondsSinceEpoch}',
      difficultyStars: _diloDifficulty.clamp(1, 3),
      imagePath: imagePath,
      text: text,
      audioSource: audioMale,
      audioSourceMale: audioMale,
      audioSourceFemale: audioFemale,
      enabled: true,
    );

    setState(() {
      _working = _working.copyWith(
        diloItems: [..._working.diloItems, item],
      );
      _diloImageController.clear();
      _diloTextController.clear();
      _diloAudioMaleController.clear();
      _diloAudioFemaleController.clear();
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

  Future<void> _replaceDiloItemImage({
    required DiloContentItem item,
    required ImageSource source,
  }) async {
    await _pickNewItemImage(
      targetKey: 'dilo_edit_${item.id}',
      gameKey: 'dilo',
      source: source,
      onUploaded: (url) {
        setState(() {
          final next = _working.diloItems.map((current) {
            if (current.id != item.id) return current;
            return current.copyWith(imagePath: url);
          }).toList();
          _working = _working.copyWith(diloItems: next);
        });
        return true;
      },
      expectedConcepts: <String>[item.text],
      expectedDescription: item.text,
    );
  }

  Future<void> _replaceDiloItemAudio(
    DiloContentItem item, {
    required bool female,
  }) async {
    await _pickNewItemAudio(
      targetKey: female
          ? 'dilo_audio_female_${item.id}'
          : 'dilo_audio_male_${item.id}',
      gameKey: 'dilo',
      onUploaded: (url) {
        setState(() {
          final next = _working.diloItems.map((current) {
            if (current.id != item.id) return current;
            return current.copyWith(
              audioSource: female ? current.audioSource : url,
              audioSourceMale: female ? current.audioSourceMale : url,
              audioSourceFemale: female ? url : current.audioSourceFemale,
            );
          }).toList();
          _working = _working.copyWith(diloItems: next);
        });
      },
    );
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

  Future<void> _addMemoryItem() async {
    await _addMemoryItemFromSource(_memoryImageController.text.trim());
  }

  List<ExploreContentItem> _upsertExploreItem(ExploreContentItem item) {
    final next = [..._working.exploreItems];
    final index = next.indexWhere((current) => current.id == item.id);
    if (index >= 0) {
      next[index] = item;
    } else {
      next.add(item);
    }
    return next;
  }

  void _clearExploreDraft() {
    _exploreTitleController.clear();
    _exploreDescriptionController.clear();
    _exploreImageController.clear();
    _exploreAudioMaleController.clear();
    _exploreAudioFemaleController.clear();
  }

  Future<void> _addExploreItem() async {
    final title = _exploreTitleController.text.trim();
    final description = _exploreDescriptionController.text.trim();
    final imageSource = _exploreImageController.text.trim();
    final audioMale = _exploreAudioMaleController.text.trim();
    final audioFemale = _exploreAudioFemaleController.text.trim();
    if (title.isEmpty ||
        description.isEmpty ||
        imageSource.isEmpty ||
        audioMale.isEmpty ||
        audioFemale.isEmpty) {
      await NebulaSnack.show(
        context,
        message:
            'Completa categor\u00eda, t\u00edtulo, descripci\u00f3n, imagen y ambos audios del narrador.',
        ok: false,
      );
      return;
    }
    final imageOk = await _validateImageSource(imageSource, label: 'imagen');
    if (!imageOk) return;
    final maleOk = await _validateAudioSource(audioMale);
    if (!maleOk) return;
    final femaleOk = await _validateAudioSource(audioFemale);
    if (!femaleOk) return;

    final item = ExploreContentItem(
      id: 'explore_${_exploreCategoryId}_${DateTime.now().microsecondsSinceEpoch}',
      categoryId: _exploreCategoryId,
      title: title,
      description: description,
      imageSource: imageSource,
      audioSource: audioMale,
      audioSourceMale: audioMale,
      audioSourceFemale: audioFemale,
      enabled: true,
    );

    setState(() {
      _working = _working.copyWith(
        exploreItems: [..._working.exploreItems, item],
      );
      _clearExploreDraft();
    });
  }

  Future<void> _replaceExploreItemImage({
    required ExploreContentItem item,
    required ImageSource source,
  }) async {
    await _pickNewItemImage(
      targetKey: 'explore_edit_${item.id}',
      gameKey: 'explora_aprende',
      source: source,
      expectedConcepts: <String>[
        item.title,
        exploreCategoryLabelFor(item.categoryId),
      ],
      expectedDescription: item.title,
      onUploaded: (url) {
        setState(() {
          _working = _working.copyWith(
            exploreItems: _upsertExploreItem(
              item.copyWith(imageSource: url),
            ),
          );
        });
        return true;
      },
    );
  }

  Future<void> _replaceExploreItemNarration(
    ExploreContentItem item, {
    required bool female,
  }) async {
    await _pickNewItemAudio(
      targetKey: female
          ? 'explore_audio_female_${item.id}'
          : 'explore_audio_male_${item.id}',
      gameKey: 'explora_aprende',
      onUploaded: (url) {
        setState(() {
          _working = _working.copyWith(
            exploreItems: _upsertExploreItem(
              item.copyWith(
                audioSource: female ? item.audioSource : url,
                audioSourceMale: female ? item.audioSourceMale : url,
                audioSourceFemale: female ? url : item.audioSourceFemale,
              ),
            ),
          );
        });
      },
    );
  }

  void _toggleExploreItem(ExploreContentItem item, bool value) {
    if (isDefaultExploreItemId(item.id)) {
      final defaultItem = defaultExploreItemById(item.id) ?? item;
      setState(() {
        _working = _working.copyWith(
          exploreItems: _upsertExploreItem(
            defaultItem.copyWith(
              title: item.title,
              description: item.description,
              imageSource: item.imageSource,
              audioSource: item.audioSource,
              audioSourceMale: item.audioSourceMale,
              audioSourceFemale: item.audioSourceFemale,
              enabled: value,
            ),
          ),
        );
      });
      return;
    }
    setState(() {
      _working = _working.copyWith(
        exploreItems: _upsertExploreItem(item.copyWith(enabled: value)),
      );
    });
  }

  Future<void> _deleteExploreItem(ExploreContentItem item) async {
    final builtIn = isDefaultExploreItemId(item.id);
    final accepted = await _confirmDeleteContentItem(
      title: builtIn
          ? 'Ocultar contenido base de Explora'
          : 'Eliminar contenido de Explora',
      message: builtIn
          ? 'Esta acci\u00f3n ocultar\u00e1 este contenido base de Explora para futuras partidas. Podr\u00e1s restaurarlo despu\u00e9s. \u00bfDeseas continuar?'
          : 'Esta acci\u00f3n eliminar\u00e1 este contenido agregado por administraci\u00f3n en Explora. \u00bfDeseas continuar?',
      confirmLabel: builtIn ? 'Ocultar' : 'Eliminar',
    );
    if (!accepted) return;

    if (builtIn) {
      final defaultItem = defaultExploreItemById(item.id) ?? item;
      setState(() {
        _working = _working.copyWith(
          exploreItems:
              _upsertExploreItem(defaultItem.copyWith(enabled: false)),
        );
      });
      return;
    }

    setState(() {
      _working = _working.copyWith(
        exploreItems: _working.exploreItems
            .where((current) => current.id != item.id)
            .toList(),
      );
    });
  }

  void _restoreExploreItem(ExploreContentItem item) {
    if (!isDefaultExploreItemId(item.id)) return;
    setState(() {
      _working = _working.copyWith(
        exploreItems: _working.exploreItems
            .where((current) => current.id != item.id)
            .toList(),
      );
    });
  }

  List<DondeVaContentItem> _upsertDondeVaItem(DondeVaContentItem item) {
    final next = [..._working.dondeVaItems];
    final index = next.indexWhere((current) => current.id == item.id);
    if (index >= 0) {
      next[index] = item;
    } else {
      next.add(item);
    }
    return next;
  }

  void _clearDondeVaDraft() {
    _dondeVaLabelController.clear();
    _dondeVaImageController.clear();
  }

  Future<void> _addDondeVaItem() async {
    final label = _dondeVaLabelController.text.trim();
    final imageSource = _dondeVaImageController.text.trim();
    if (label.isEmpty || imageSource.isEmpty) {
      await NebulaSnack.show(
        context,
        message: 'Completa categor\u00eda, texto e imagen del objeto.',
        ok: false,
      );
      return;
    }
    final imageOk = await _validateImageSource(imageSource, label: 'imagen');
    if (!imageOk) return;

    final item = DondeVaContentItem(
      id: 'donde_va_${_dondeVaCategoryId}_${DateTime.now().microsecondsSinceEpoch}',
      categoryId: _dondeVaCategoryId,
      label: label,
      imageSource: imageSource,
      enabled: true,
    );

    setState(() {
      _working = _working.copyWith(
        dondeVaItems: [..._working.dondeVaItems, item],
      );
      _clearDondeVaDraft();
    });
  }

  void _toggleDondeVaItem(DondeVaContentItem item, bool value) {
    setState(() {
      _working = _working.copyWith(
        dondeVaItems: _upsertDondeVaItem(item.copyWith(enabled: value)),
      );
    });
  }

  Future<void> _replaceDondeVaItemImage({
    required DondeVaContentItem item,
    required ImageSource source,
  }) async {
    await _pickNewItemImage(
      targetKey: 'donde_va_edit_${item.id}',
      gameKey: 'donde_va',
      source: source,
      onUploaded: (url) {
        setState(() {
          _working = _working.copyWith(
            dondeVaItems: _upsertDondeVaItem(item.copyWith(imageSource: url)),
          );
        });
        return true;
      },
      successMessage:
          'Imagen seleccionada. Guarda el contenido para publicarla.',
    );
  }

  Future<void> _deleteDondeVaItem(DondeVaContentItem item) async {
    final accepted = await _confirmDeleteContentItem(
      title: 'Eliminar objeto de \u00bfD\u00f3nde va?',
      message:
          'Esta acci\u00f3n eliminar\u00e1 este objeto agregado por administraci\u00f3n en \u00bfD\u00f3nde va? para futuras partidas. \u00bfDeseas continuar?',
      confirmLabel: 'Eliminar',
    );
    if (!accepted) return;
    setState(() {
      _working = _working.copyWith(
        dondeVaItems: _working.dondeVaItems
            .where((current) => current.id != item.id)
            .toList(),
      );
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
          .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡', 'a')
          .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©', 'e')
          .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â­', 'i')
          .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â³', 'o')
          .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Âº', 'u')
          .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¼', 'u')
          .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â±', 'n')
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
      return 'Aparece en dificultad f\u00e1cil';
    }
    if (normalized.contains('/medio/')) {
      return 'Aparece en dificultad media';
    }
    if (normalized.contains('/dificil/')) {
      return 'Aparece en dificultad dif\u00edcil';
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

  String _defaultSourceFor({
    required String gameKey,
    required String itemId,
  }) {
    final normalizedGame = gameKey.trim().toLowerCase();
    final normalizedItemId = itemId.trim().toLowerCase();
    final pool = switch (normalizedGame) {
      'emociones' => _defaultEmotionImages,
      'sonidos' => _defaultSoundImages,
      'puzzle' => defaultPuzzleImageSources,
      'cartas_gemelas' => defaultMemoryImageSources,
      'donde_va' => dondeVaCategories
          .expand(
            (category) => category.items.map(
              (item) => dondeVaItemAssetPath(
                categoryId: category.id,
                itemId: item.id,
                extension: item.assetExtension,
              ),
            ),
          )
          .toList(growable: false),
      _ => const <String>[],
    };
    for (final source in pool) {
      final sourceItemId =
          widget.controller.customContentItemId(source: source);
      final normalizedSource = source.trim().toLowerCase();
      if (sourceItemId.trim().toLowerCase() == normalizedItemId ||
          normalizedSource == normalizedItemId) {
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
                title: const Text('Usar galer\u00eda'),
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

  String _soundLabelForReview() {
    final label = _soundCategoryController.text.trim();
    if (label.isNotEmpty) return label;
    final audioName = _prettyNameFromSource(_soundAssetController.text.trim());
    return audioName == 'Elemento' ? '' : audioName;
  }

  Widget _buildSelectedSourceCard({
    required String label,
    required String value,
    required IconData icon,
    String emptyMessage = 'A\u00fan no has seleccionado nada.',
    bool isImage = false,
    VoidCallback? onClear,
  }) {
    final trimmed = value.trim();
    final hasValue = trimmed.isNotEmpty;
    final title = hasValue ? _prettyNameFromSource(trimmed) : emptyMessage;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE4F2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isImage && hasValue)
            PuzzleImageAdapter(
              imageSource: trimmed,
              size: 64,
              borderRadius: 12,
            )
          else
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEF9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF49607E)),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: hasValue
                            ? const Color(0xFF21314D)
                            : const Color(0xFF6C7A90),
                      ),
                ),
              ],
            ),
          ),
          if (hasValue && onClear != null)
            IconButton(
              onPressed: onClear,
              tooltip: 'Quitar selecci\u00f3n',
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }

  Future<void> _pickEmotionImage(ImageSource source) async {
    final emotion = _emotionCorrectController.text.trim().toLowerCase();
    if (emotion.isEmpty) {
      await NebulaSnack.show(
        context,
        message: 'Selecciona primero la emoci\u00f3n en la lista.',
        ok: false,
      );
      return;
    }
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
      expectedDescription: _prettyEmotionName(emotion),
    );
  }

  Future<void> _pickSoundImage(ImageSource source) async {
    final soundAsset = _soundAssetController.text.trim();
    final soundLabel = _soundLabelForReview();
    if (soundAsset.isEmpty) {
      await NebulaSnack.show(
        context,
        message: 'Selecciona primero el archivo de audio.',
        ok: false,
      );
      return;
    }
    if (soundLabel.isEmpty) {
      await NebulaSnack.show(
        context,
        message: 'Escribe una etiqueta para identificar el sonido.',
        ok: false,
      );
      return;
    }
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
      expectedConcepts: _expectedConceptsFromSource(
        soundAsset,
        extraLabels: <String>[soundLabel],
      ),
      expectedDescription: soundLabel,
    );
  }

  Future<void> _pickDiloImage(ImageSource source) async {
    final text = _diloTextController.text.trim();
    if (text.isEmpty) {
      await NebulaSnack.show(
        context,
        message: 'Escribe primero la palabra o frase del ejercicio.',
        ok: false,
      );
      return;
    }
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
      expectedDescription: text,
      expectedConcepts: <String>[text],
    );
  }

  Future<void> _pickExploreImage(ImageSource source) async {
    final title = _exploreTitleController.text.trim();
    final description = _exploreDescriptionController.text.trim();
    if (title.isEmpty || description.isEmpty) {
      await NebulaSnack.show(
        context,
        message: 'Escribe primero el t\u00edtulo y la descripci\u00f3n.',
        ok: false,
      );
      return;
    }
    await _pickNewItemImage(
      targetKey: 'explore',
      gameKey: 'explora_aprende',
      source: source,
      onUploaded: (url) {
        setState(() {
          _exploreImageController.text = url;
        });
        return true;
      },
      expectedConcepts: <String>[
        title,
        exploreCategoryLabelFor(_exploreCategoryId),
      ],
      expectedDescription: title,
    );
  }

  Future<void> _pickDondeVaImage(ImageSource source) async {
    final label = _dondeVaLabelController.text.trim();
    if (label.isEmpty) {
      await NebulaSnack.show(
        context,
        message: 'Escribe primero el texto del objeto.',
        ok: false,
      );
      return;
    }
    await _pickNewItemImage(
      targetKey: 'donde_va_item',
      gameKey: 'donde_va',
      source: source,
      onUploaded: (url) {
        setState(() {
          _dondeVaImageController.text = url;
        });
        return true;
      },
      successMessage: 'Imagen seleccionada. Ahora agrega el objeto.',
    );
  }

  Future<void> _pickNewItemImage({
    required String targetKey,
    required String gameKey,
    required ImageSource source,
    required FutureOr<bool> Function(String url) onUploaded,
    String successMessage =
        'Imagen subida. Completa los campos y agrega el item.',
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
    if (!mounted) return;
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

      final upload =
          await widget.controller.authService.uploadGlobalGameImageFile(
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
      if (!mounted) return;
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
    if (!mounted) return;
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
        if (!mounted) return;
        await NebulaSnack.show(
          context,
          message: 'No se pudo leer el audio seleccionado.',
          ok: false,
        );
        return;
      }
      final upload =
          await widget.controller.authService.uploadGlobalGameAudioFile(
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
        message: 'Audio seleccionado. Completa los campos y agrega el item.',
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
      audioSource: '',
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
        message: 'Selecciona $label antes de continuar.',
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
      if (!mounted) return false;
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
    if (!mounted) return false;
    await NebulaSnack.show(
      context,
      message:
          'No pudimos encontrar $label. Vuelve a seleccionarla desde el dispositivo.',
      ok: false,
    );
    return false;
  }

  Future<bool> _validateAudioSource(String raw) async {
    final source = raw.trim();
    if (source.isEmpty) {
      await NebulaSnack.show(
        context,
        message: 'Selecciona el audio antes de continuar.',
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
      if (!mounted) return false;
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
    if (!mounted) return false;
    await NebulaSnack.show(
      context,
      message:
          'No pudimos encontrar el audio seleccionado. Vuelve a elegirlo desde el dispositivo.',
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
              title: _prettyEmotionName(item.correctEmotion),
              subtitle:
                  'Imagen agregada por admin a Descubre emoci\u00f3n (D${item.difficultyStars}).',
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
            itemId: source,
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
              title: item.category.trim().isEmpty
                  ? _prettyNameFromSource(item.correctImage)
                  : item.category.trim(),
              subtitle:
                  'Imagen agregada por admin a Conecta sonidos (D${item.difficultyStars}).',
              defaultSource: item.correctImage.trim(),
              expectedConcepts: _expectedConceptsFromSource(
                item.correctImage,
                extraLabels: <String>[
                  if (item.category.trim().isNotEmpty) item.category.trim(),
                ],
              ),
              expectedDescription: item.category.trim().isEmpty
                  ? _prettyNameFromSource(item.correctImage)
                  : item.category.trim(),
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
      configuredItems:
          memoryItems.where((item) => item.imagePath.trim().isNotEmpty).map(
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
    final mergedExploreItems = mergeExploreItems(_working.exploreItems);
    final exploreItemsByCategory = <String, List<ExploreContentItem>>{
      for (final category in exploreCategoryDefinitions)
        category.id: exploreItemsForCategory(
          items: mergedExploreItems,
          categoryId: category.id,
        ),
    };
    final dondeVaItems = [..._working.dondeVaItems]
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    final dondeVaItemsByCategory = <String, List<DondeVaContentItem>>{
      for (final category in dondeVaCategories)
        category.id: dondeVaItems
            .where(
              (item) => item.categoryId.trim().toLowerCase() == category.id,
            )
            .toList(),
    };
    final defaultDondeVaItems = _mergeConfiguredItemsIntoDefaults(
      defaults: dondeVaCategories
          .expand(
            (category) => category.items.map(
              (item) => _GlobalDefaultImageItem(
                gameKey: 'donde_va',
                itemId: dondeVaGlobalItemId(
                  categoryId: category.id,
                  itemId: item.id,
                ),
                title: item.label,
                subtitle:
                    'Objeto de ${category.label} en \u00bfD\u00f3nde va?.',
                defaultSource: item.imageSource.trim().isNotEmpty
                    ? item.imageSource.trim()
                    : dondeVaItemAssetPath(
                        categoryId: category.id,
                        itemId: item.id,
                        extension: item.assetExtension,
                      ),
                expectedConcepts: <String>[item.label, category.label],
                expectedDescription: item.label,
              ),
            ),
          )
          .toList(growable: false),
      configuredItems: dondeVaItems.map(
        (item) => _GlobalDefaultImageItem(
          gameKey: 'donde_va',
          itemId: dondeVaGlobalItemId(
            categoryId: item.categoryId,
            itemId: item.id,
          ),
          title: item.label,
          subtitle:
              'Objeto agregado por admin a ${dondeVaCategories.firstWhere((category) => category.id == item.categoryId, orElse: () => dondeVaCategories.first).label}.',
          defaultSource: item.imageSource,
          expectedConcepts: const <String>[],
          expectedDescription: '',
          isOriginalAppDefault: false,
        ),
      ),
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
                      'Aquí defines recursos globales de juegos. Los cambios se reflejan en todas las cuentas, mientras las personalizaciones del niño tienen prioridad. Las nuevas imágenes pasan por validaciones de formato, recorte y revisión de contenido antes de subirse.',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Emociones: ${_working.emotionItems.length}  |  Sonidos: ${_working.soundItems.length}  |  Dilo: ${_working.diloItems.length}  |  Cartas: ${_working.memoryItems.length}  |  Puzzle: ${_working.puzzleItems.length}  |  Explora: ${mergedExploreItems.length}  |  ¿Dónde va?: ${defaultDondeVaItems.length}',
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
                  'Si cambias una imagen aquí, se actualiza para todos los usuarios que no tengan una personalización propia del niño.',
              items: mergedEmotionItems,
            ),
            const SizedBox(height: 10),
            _buildGlobalDefaultsCard(
              title: 'Predeterminadas globales \u00b7 Conecta sonidos',
              description:
                  'Estas imágenes son la base global del juego. Las personalizaciones del cuidador por niño siguen teniendo prioridad.',
              items: mergedSoundItems,
            ),
            const SizedBox(height: 10),
            _buildGlobalDefaultsCard(
              title: 'Predeterminadas globales \u00b7 Cartas gemelas',
              description:
                  'Estas imágenes base se usan en Cartas gemelas para todos los usuarios que no tengan una personalización propia.',
              items: mergedMemoryItems,
            ),
            const SizedBox(height: 10),
            _buildGlobalDefaultsCard(
              title: 'Predeterminadas globales \u00b7 Arma la imagen',
              description:
                  'Estas imágenes base se usan en Arma la imagen para todos los usuarios. Puedes verlas, cambiarlas o restaurarlas.',
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
                      'Descubre emoción',
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
                    DropdownButtonFormField<String>(
                      initialValue: _emotionCorrectController.text
                              .trim()
                              .isEmpty
                          ? null
                          : _emotionCorrectController.text.trim().toLowerCase(),
                      decoration: const InputDecoration(
                        labelText: 'Emoci\u00f3n',
                      ),
                      items: _emotionOptions
                          .map(
                            (emotion) => DropdownMenuItem<String>(
                              value: emotion,
                              child: Text(_prettyEmotionName(emotion)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _emotionCorrectController.text = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildSelectedSourceCard(
                      label: 'Imagen seleccionada',
                      value: _emotionImageController.text,
                      icon: Icons.image_outlined,
                      isImage: true,
                      emptyMessage:
                          'Toma una foto o elige una imagen desde la galer\u00eda.',
                      onClear: _emotionImageController.text.trim().isEmpty
                          ? null
                          : () => setState(_emotionImageController.clear),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: NebulaSecondaryButton(
                            text: _newItemBusyKey == 'emotion'
                                ? 'Subiendo...'
                                : 'Elegir de la galer\u00eda',
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
                      text: 'Agregar ítem de emoción',
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
                            subtitle: const Text(
                              'Imagen personalizada lista para esta emoci\u00f3n.',
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
                      controller: _soundCategoryController,
                      decoration: const InputDecoration(
                        labelText: 'Etiqueta del sonido',
                        hintText: 'Ejemplo: Perro, Guitarra, Tormenta',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildSelectedSourceCard(
                      label: 'Audio seleccionado',
                      value: _soundAssetController.text,
                      icon: Icons.audiotrack_rounded,
                      emptyMessage:
                          'Elige el archivo de audio desde el dispositivo.',
                      onClear: _soundAssetController.text.trim().isEmpty
                          ? null
                          : () => setState(_soundAssetController.clear),
                    ),
                    const SizedBox(height: 8),
                    NebulaSecondaryButton(
                      text: _newItemBusyKey == 'sound_audio'
                          ? 'Subiendo...'
                          : 'Seleccionar audio',
                      onPressed: _newItemBusyKey?.startsWith('sound') == true
                          ? null
                          : () => _pickNewItemAudio(
                                targetKey: 'sound_audio',
                                gameKey: 'sonidos',
                                onUploaded: (url) {
                                  setState(() {
                                    _soundAssetController.text = url;
                                  });
                                },
                              ),
                    ),
                    const SizedBox(height: 10),
                    _buildSelectedSourceCard(
                      label: 'Imagen seleccionada',
                      value: _soundImageController.text,
                      icon: Icons.image_outlined,
                      isImage: true,
                      emptyMessage:
                          'Sube la imagen que corresponde a ese sonido.',
                      onClear: _soundImageController.text.trim().isEmpty
                          ? null
                          : () => setState(_soundImageController.clear),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: NebulaSecondaryButton(
                            text: _newItemBusyKey == 'sound'
                                ? 'Subiendo...'
                                : 'Elegir de la galer\u00eda',
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
                    const SizedBox(height: 10),
                    NebulaSecondaryButton(
                      text: 'Agregar item de sonido',
                      onPressed: _addSoundItem,
                    ),
                    const SizedBox(height: 10),
                    if (soundItems.isEmpty)
                      const Text('Sin ítems personalizados.')
                    else
                      ...soundItems.map((item) {
                        final imageBusy =
                            _newItemBusyKey == 'sound_edit_${item.id}';
                        final audioBusy =
                            _newItemBusyKey == 'sound_audio_edit_${item.id}';
                        return Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F8FC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFDCE4F2)),
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
                                      title: item.category.trim().isEmpty
                                          ? 'Sonido'
                                          : item.category.trim(),
                                      imageSource: item.correctImage,
                                    ),
                                    child: PuzzleImageAdapter(
                                      imageSource: item.correctImage,
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
                                          'D${item.difficultyStars} | ${item.category.trim().isEmpty ? 'Sin etiqueta' : item.category.trim()}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Imagen y audio vinculados para este sonido.',
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
                                        _toggleSoundItem(item.id, value),
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
                                      title: item.category.trim().isEmpty
                                          ? 'Sonido'
                                          : item.category.trim(),
                                      imageSource: item.correctImage,
                                    ),
                                    icon: const Icon(Icons.visibility_outlined),
                                    label: const Text('Ver'),
                                  ),
                                  FilledButton.icon(
                                    onPressed: imageBusy
                                        ? null
                                        : () => _openExistingItemImageSheet(
                                              title:
                                                  'Cambiar imagen de ${item.category.trim().isEmpty ? 'sonido' : item.category.trim()}',
                                              onPick: (source) =>
                                                  _replaceSoundItemImage(
                                                item: item,
                                                source: source,
                                              ),
                                            ),
                                    icon: imageBusy
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.image_outlined),
                                    label: Text(
                                      imageBusy
                                          ? 'Subiendo...'
                                          : 'Cambiar imagen',
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: audioBusy
                                        ? null
                                        : () => _replaceSoundItemAudio(item),
                                    icon: audioBusy
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.audiotrack_rounded),
                                    label: Text(
                                      audioBusy
                                          ? 'Subiendo...'
                                          : 'Cambiar audio',
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _removeSoundItem(item.id),
                                    icon: const Icon(Icons.delete_outline),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFC93C4C),
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
                      controller: _diloTextController,
                      decoration: const InputDecoration(
                        labelText: 'Texto/Palabra',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildSelectedSourceCard(
                      label: 'Imagen seleccionada',
                      value: _diloImageController.text,
                      icon: Icons.image_outlined,
                      isImage: true,
                      emptyMessage:
                          'Primero escribe la palabra y luego selecciona la imagen.',
                      onClear: _diloImageController.text.trim().isEmpty
                          ? null
                          : () => setState(_diloImageController.clear),
                    ),
                    const SizedBox(height: 8),
                    _buildSelectedSourceCard(
                      label: 'Audio narrador hombre',
                      value: _diloAudioMaleController.text,
                      icon: Icons.record_voice_over_rounded,
                      emptyMessage: 'Selecciona el audio del narrador hombre.',
                      onClear: _diloAudioMaleController.text.trim().isEmpty
                          ? null
                          : () => setState(_diloAudioMaleController.clear),
                    ),
                    const SizedBox(height: 8),
                    _buildSelectedSourceCard(
                      label: 'Audio narrador mujer',
                      value: _diloAudioFemaleController.text,
                      icon: Icons.record_voice_over_rounded,
                      emptyMessage: 'Selecciona el audio del narrador mujer.',
                      onClear: _diloAudioFemaleController.text.trim().isEmpty
                          ? null
                          : () => setState(_diloAudioFemaleController.clear),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: NebulaSecondaryButton(
                            text: _newItemBusyKey?.startsWith('dilo_image') ==
                                    true
                                ? 'Subiendo...'
                                : 'Elegir imagen',
                            onPressed:
                                _newItemBusyKey?.startsWith('dilo') == true
                                    ? null
                                    : () => _pickDiloImage(ImageSource.gallery),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: NebulaSecondaryButton(
                            text: _newItemBusyKey?.startsWith('dilo_image') ==
                                    true
                                ? 'Subiendo...'
                                : 'Tomar foto',
                            onPressed:
                                _newItemBusyKey?.startsWith('dilo') == true
                                    ? null
                                    : () => _pickDiloImage(ImageSource.camera),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: NebulaSecondaryButton(
                            text: _newItemBusyKey == 'dilo_audio_male'
                                ? 'Subiendo...'
                                : 'Audio hombre',
                            onPressed: _newItemBusyKey?.startsWith('dilo') ==
                                    true
                                ? null
                                : () => _pickNewItemAudio(
                                      targetKey: 'dilo_audio_male',
                                      gameKey: 'dilo',
                                      onUploaded: (url) {
                                        setState(() {
                                          _diloAudioMaleController.text = url;
                                        });
                                      },
                                    ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: NebulaSecondaryButton(
                            text: _newItemBusyKey == 'dilo_audio_female'
                                ? 'Subiendo...'
                                : 'Audio mujer',
                            onPressed: _newItemBusyKey?.startsWith('dilo') ==
                                    true
                                ? null
                                : () => _pickNewItemAudio(
                                      targetKey: 'dilo_audio_female',
                                      gameKey: 'dilo',
                                      onUploaded: (url) {
                                        setState(() {
                                          _diloAudioFemaleController.text = url;
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
                      ...diloItems.map((item) {
                        final imageBusy =
                            _newItemBusyKey == 'dilo_edit_${item.id}';
                        final maleBusy =
                            _newItemBusyKey == 'dilo_audio_male_${item.id}';
                        final femaleBusy =
                            _newItemBusyKey == 'dilo_audio_female_${item.id}';
                        return Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F8FC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFDCE4F2)),
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
                                      title: item.text,
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
                                          'D${item.difficultyStars} | ${item.text}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Narrador hombre: ${item.audioSourceMale.trim().isEmpty ? 'pendiente' : 'cargado'}\nNarrador mujer: ${item.audioSourceFemale.trim().isEmpty ? 'pendiente' : 'cargado'}',
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
                                        _toggleDiloItem(item.id, value),
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
                                      title: item.text,
                                      imageSource: item.imagePath,
                                    ),
                                    icon: const Icon(Icons.visibility_outlined),
                                    label: const Text('Ver'),
                                  ),
                                  FilledButton.icon(
                                    onPressed: imageBusy
                                        ? null
                                        : () => _openExistingItemImageSheet(
                                              title:
                                                  'Cambiar imagen de ${item.text}',
                                              onPick: (source) =>
                                                  _replaceDiloItemImage(
                                                item: item,
                                                source: source,
                                              ),
                                            ),
                                    icon: imageBusy
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.edit_outlined),
                                    label: Text(
                                      imageBusy
                                          ? 'Subiendo...'
                                          : 'Cambiar imagen',
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: maleBusy
                                        ? null
                                        : () => _replaceDiloItemAudio(
                                              item,
                                              female: false,
                                            ),
                                    icon: maleBusy
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.mic_outlined),
                                    label: Text(
                                      maleBusy ? 'Subiendo...' : 'Audio hombre',
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: femaleBusy
                                        ? null
                                        : () => _replaceDiloItemAudio(
                                              item,
                                              female: true,
                                            ),
                                    icon: femaleBusy
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.mic_none_outlined),
                                    label: Text(
                                      femaleBusy
                                          ? 'Subiendo...'
                                          : 'Audio mujer',
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _removeDiloItem(item.id),
                                    icon: const Icon(Icons.delete_outline),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFC93C4C),
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
                      'Cartas gemelas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Si quieres asociar audio a la carta, selecciona primero el audio y luego la imagen.',
                    ),
                    const SizedBox(height: 10),
                    _buildSelectedSourceCard(
                      label: 'Audio seleccionado',
                      value: _memoryAudioController.text,
                      icon: Icons.audiotrack_rounded,
                      emptyMessage: 'Este audio es opcional.',
                      onClear: _memoryAudioController.text.trim().isEmpty
                          ? null
                          : () => setState(_memoryAudioController.clear),
                    ),
                    const SizedBox(height: 8),
                    _buildSelectedSourceCard(
                      label: 'Imagen seleccionada',
                      value: _memoryImageController.text,
                      icon: Icons.image_outlined,
                      isImage: true,
                      emptyMessage: 'Selecciona la imagen de la nueva carta.',
                      onClear: _memoryImageController.text.trim().isEmpty
                          ? null
                          : () => setState(_memoryImageController.clear),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: NebulaSecondaryButton(
                            text: _newItemBusyKey == 'memory_image'
                                ? 'Subiendo...'
                                : 'Elegir imagen',
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
                                            return true;
                                          },
                                          successMessage:
                                              'Imagen seleccionada. Ahora agrega la carta.',
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
                                            return true;
                                          },
                                          successMessage:
                                              'Imagen seleccionada. Ahora agrega la carta.',
                                        ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    NebulaSecondaryButton(
                      text: _newItemBusyKey == 'memory_audio'
                          ? 'Subiendo...'
                          : 'Seleccionar audio',
                      onPressed: _newItemBusyKey?.startsWith('memory') == true
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
                      text: 'Agregar carta',
                      onPressed: _addMemoryItem,
                    ),
                    const SizedBox(height: 10),
                    if (memoryItems.isEmpty)
                      const Text('Sin imágenes personalizadas.')
                    else
                      ...memoryItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final busy =
                            _newItemBusyKey == 'memory_edit_${item.id}';
                        return Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F8FC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFDCE4F2)),
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
                                              ? 'Imagen lista para usar en la carta.'
                                              : 'Imagen y audio vinculados para esta carta.',
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
                                      busy ? 'Subiendo...' : 'Cambiar imagen',
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _deleteMemoryItem(item),
                                    icon: const Icon(Icons.delete_outline),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFC93C4C),
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
                            text: 'Elegir imagen',
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
                    if (puzzleItems.isEmpty)
                      const Text('Sin imágenes de puzzle configuradas.')
                    else
                      ...puzzleItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final busy =
                            _newItemBusyKey == 'puzzle_edit_${item.id}';
                        final sizeLabel = item.width > 0 && item.height > 0
                            ? '${item.width}x${item.height}'
                            : 'Imagen configurada';
                        return Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F8FC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFDCE4F2)),
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
                                          '$sizeLabel\nLista para usarse en el rompecabezas.',
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
                                      busy ? 'Subiendo...' : 'Cambiar imagen',
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _deletePuzzleItem(item),
                                    icon: const Icon(Icons.delete_outline),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFC93C4C),
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
                      'Explora y aprende',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Agrega contenido a Animales, Historia y Arte. Cada elemento debe quedar completo con imagen, texto y los dos narradores.',
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
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
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _exploreCategoryId = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _exploreTitleController,
                      decoration: const InputDecoration(
                        labelText: 'T\u00edtulo',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _exploreDescriptionController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Descripci\u00f3n',
                        helperText:
                            'Este texto se muestra en pantalla y tambi\u00e9n sirve de apoyo para la narraci\u00f3n.',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildSelectedSourceCard(
                      label: 'Imagen seleccionada',
                      value: _exploreImageController.text,
                      icon: Icons.image_outlined,
                      isImage: true,
                      emptyMessage:
                          'Elige una imagen desde la galer\u00eda o toma una foto.',
                      onClear: _exploreImageController.text.trim().isEmpty
                          ? null
                          : () => setState(_exploreImageController.clear),
                    ),
                    const SizedBox(height: 8),
                    _buildSelectedSourceCard(
                      label: 'Audio narrador hombre',
                      value: _exploreAudioMaleController.text,
                      icon: Icons.record_voice_over_rounded,
                      emptyMessage: 'Selecciona el audio del narrador hombre.',
                      onClear: _exploreAudioMaleController.text.trim().isEmpty
                          ? null
                          : () => setState(_exploreAudioMaleController.clear),
                    ),
                    const SizedBox(height: 8),
                    _buildSelectedSourceCard(
                      label: 'Audio narrador mujer',
                      value: _exploreAudioFemaleController.text,
                      icon: Icons.record_voice_over_rounded,
                      emptyMessage: 'Selecciona el audio del narrador mujer.',
                      onClear: _exploreAudioFemaleController.text.trim().isEmpty
                          ? null
                          : () => setState(
                                _exploreAudioFemaleController.clear,
                              ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: NebulaSecondaryButton(
                            text: _newItemBusyKey == 'explore'
                                ? 'Subiendo...'
                                : 'Elegir imagen',
                            onPressed: _newItemBusyKey?.startsWith('explore') ==
                                    true
                                ? null
                                : () => _pickExploreImage(ImageSource.gallery),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: NebulaSecondaryButton(
                            text: _newItemBusyKey == 'explore'
                                ? 'Subiendo...'
                                : 'Tomar foto',
                            onPressed: _newItemBusyKey?.startsWith('explore') ==
                                    true
                                ? null
                                : () => _pickExploreImage(ImageSource.camera),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: NebulaSecondaryButton(
                            text: _newItemBusyKey == 'explore_audio_male'
                                ? 'Subiendo...'
                                : 'Audio hombre',
                            onPressed:
                                _newItemBusyKey?.startsWith('explore') == true
                                    ? null
                                    : () => _pickNewItemAudio(
                                          targetKey: 'explore_audio_male',
                                          gameKey: 'explora_aprende',
                                          onUploaded: (url) {
                                            setState(() {
                                              _exploreAudioMaleController.text =
                                                  url;
                                            });
                                          },
                                        ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: NebulaSecondaryButton(
                            text: _newItemBusyKey == 'explore_audio_female'
                                ? 'Subiendo...'
                                : 'Audio mujer',
                            onPressed: _newItemBusyKey?.startsWith('explore') ==
                                    true
                                ? null
                                : () => _pickNewItemAudio(
                                      targetKey: 'explore_audio_female',
                                      gameKey: 'explora_aprende',
                                      onUploaded: (url) {
                                        setState(() {
                                          _exploreAudioFemaleController.text =
                                              url;
                                        });
                                      },
                                    ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    NebulaPrimaryButton(
                      text: 'Agregar elemento a Explora',
                      onPressed: _addExploreItem,
                    ),
                    const SizedBox(height: 12),
                    ...exploreCategoryDefinitions.map((category) {
                      final items = exploreItemsByCategory[category.id] ??
                          const <ExploreContentItem>[];
                      return Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F8FC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFDCE4F2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${items.length} elementos disponibles.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (items.isEmpty) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'A\u00fan no hay elementos visibles en esta categor\u00eda.',
                              ),
                            ] else
                              ...items.map((item) {
                                final isBuiltIn =
                                    isDefaultExploreItemId(item.id);
                                final isConfigured = _working.exploreItems.any(
                                  (current) => current.id == item.id,
                                );
                                final imageBusy = _newItemBusyKey ==
                                    'explore_edit_${item.id}';
                                final maleBusy = _newItemBusyKey ==
                                    'explore_audio_male_${item.id}';
                                final femaleBusy = _newItemBusyKey ==
                                    'explore_audio_female_${item.id}';
                                final maleStatus = item.audioSourceMale
                                        .trim()
                                        .isNotEmpty
                                    ? 'cargado por admin'
                                    : (isBuiltIn ? 'base app' : 'pendiente');
                                final femaleStatus = item.audioSourceFemale
                                        .trim()
                                        .isNotEmpty
                                    ? 'cargado por admin'
                                    : (isBuiltIn ? 'base app' : 'pendiente');
                                return Container(
                                  margin: const EdgeInsets.only(top: 10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFDCE4F2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          InkWell(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            onTap: () =>
                                                _showContentImagePreview(
                                              title: item.title,
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
                                                  item.title,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  item.description,
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  isBuiltIn
                                                      ? (isConfigured
                                                          ? 'Contenido base ajustado por admin.'
                                                          : 'Contenido base de la app.')
                                                      : 'Contenido agregado por admin.',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: const Color(
                                                          0xFF54637E,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Narrador hombre: $maleStatus\nNarrador mujer: $femaleStatus',
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
                                                _toggleExploreItem(item, value),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: () =>
                                                _showContentImagePreview(
                                              title: item.title,
                                              imageSource: item.imageSource,
                                            ),
                                            icon: const Icon(
                                              Icons.visibility_outlined,
                                            ),
                                            label: const Text('Ver'),
                                          ),
                                          FilledButton.icon(
                                            onPressed: imageBusy
                                                ? null
                                                : () =>
                                                    _openExistingItemImageSheet(
                                                      title:
                                                          'Cambiar imagen de ${item.title}',
                                                      onPick: (source) =>
                                                          _replaceExploreItemImage(
                                                        item: item,
                                                        source: source,
                                                      ),
                                                    ),
                                            icon: imageBusy
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.edit_outlined,
                                                  ),
                                            label: Text(
                                              imageBusy
                                                  ? 'Subiendo...'
                                                  : 'Cambiar imagen',
                                            ),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: maleBusy
                                                ? null
                                                : () =>
                                                    _replaceExploreItemNarration(
                                                      item,
                                                      female: false,
                                                    ),
                                            icon: maleBusy
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.mic_outlined),
                                            label: Text(
                                              maleBusy
                                                  ? 'Subiendo...'
                                                  : 'Audio hombre',
                                            ),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: femaleBusy
                                                ? null
                                                : () =>
                                                    _replaceExploreItemNarration(
                                                      item,
                                                      female: true,
                                                    ),
                                            icon: femaleBusy
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.mic_none_outlined,
                                                  ),
                                            label: Text(
                                              femaleBusy
                                                  ? 'Subiendo...'
                                                  : 'Audio mujer',
                                            ),
                                          ),
                                          if (isBuiltIn)
                                            OutlinedButton.icon(
                                              onPressed: isConfigured
                                                  ? () => _restoreExploreItem(
                                                        item,
                                                      )
                                                  : null,
                                              icon: const Icon(
                                                Icons.restore_rounded,
                                              ),
                                              label: const Text(
                                                'Restaurar base',
                                              ),
                                            )
                                          else
                                            OutlinedButton.icon(
                                              onPressed: () =>
                                                  _deleteExploreItem(item),
                                              icon: const Icon(
                                                Icons.delete_outline,
                                              ),
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
                      '\u00bfD\u00f3nde va?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sube una imagen, elige la categor\u00eda correcta y agrega el texto del objeto. La revisi\u00f3n con IA aqu\u00ed solo valida si la imagen es apropiada.',
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _dondeVaCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Categor\u00eda',
                      ),
                      items: dondeVaCategories
                          .map(
                            (category) => DropdownMenuItem<String>(
                              value: category.id,
                              child: Text(category.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _dondeVaCategoryId = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _dondeVaLabelController,
                      decoration: const InputDecoration(
                        labelText: 'Texto del objeto',
                        hintText: 'Ejemplo: Olla, Almohada, Cuaderno',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildSelectedSourceCard(
                      label: 'Imagen seleccionada',
                      value: _dondeVaImageController.text,
                      icon: Icons.image_outlined,
                      isImage: true,
                      emptyMessage:
                          'Elige la imagen del objeto desde la galer\u00eda o toma una foto.',
                      onClear: _dondeVaImageController.text.trim().isEmpty
                          ? null
                          : () => setState(_dondeVaImageController.clear),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: NebulaSecondaryButton(
                            text: _newItemBusyKey == 'donde_va_item'
                                ? 'Subiendo...'
                                : 'Elegir imagen',
                            onPressed:
                                _newItemBusyKey?.startsWith('donde_va') == true
                                    ? null
                                    : () => _pickDondeVaImage(
                                          ImageSource.gallery,
                                        ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: NebulaSecondaryButton(
                            text: _newItemBusyKey == 'donde_va_item'
                                ? 'Subiendo...'
                                : 'Tomar foto',
                            onPressed:
                                _newItemBusyKey?.startsWith('donde_va') == true
                                    ? null
                                    : () =>
                                        _pickDondeVaImage(ImageSource.camera),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    NebulaPrimaryButton(
                      text: 'Agregar objeto a \u00bfD\u00f3nde va?',
                      onPressed: _addDondeVaItem,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Los objetos nuevos tambi\u00e9n aparecer\u00e1n arriba en Predeterminadas globales.',
                    ),
                    const SizedBox(height: 12),
                    ...dondeVaCategories.map((category) {
                      final items = dondeVaItemsByCategory[category.id] ??
                          const <DondeVaContentItem>[];
                      return Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F8FC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFDCE4F2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${items.length} objetos personalizados.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (items.isEmpty) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'A\u00fan no hay objetos personalizados en esta categor\u00eda.',
                              ),
                            ] else
                              ...items.map((item) {
                                final imageBusy = _newItemBusyKey ==
                                    'donde_va_edit_${item.id}';
                                return Container(
                                  margin: const EdgeInsets.only(top: 10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFDCE4F2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          InkWell(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            onTap: () =>
                                                _showContentImagePreview(
                                              title: item.label,
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
                                                  item.label,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Objeto personalizado de ${category.label}.',
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
                                                _toggleDondeVaItem(item, value),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: () =>
                                                _showContentImagePreview(
                                              title: item.label,
                                              imageSource: item.imageSource,
                                            ),
                                            icon: const Icon(
                                              Icons.visibility_outlined,
                                            ),
                                            label: const Text('Ver'),
                                          ),
                                          FilledButton.icon(
                                            onPressed: imageBusy
                                                ? null
                                                : () =>
                                                    _openExistingItemImageSheet(
                                                      title:
                                                          'Cambiar imagen de ${item.label}',
                                                      onPick: (source) =>
                                                          _replaceDondeVaItemImage(
                                                        item: item,
                                                        source: source,
                                                      ),
                                                    ),
                                            icon: imageBusy
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.edit_outlined,
                                                  ),
                                            label: Text(
                                              imageBusy
                                                  ? 'Subiendo...'
                                                  : 'Cambiar imagen',
                                            ),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () =>
                                                _deleteDondeVaItem(item),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
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
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildGlobalDefaultsCard(
              title: 'Predeterminadas globales \u00b7 \u00bfD\u00f3nde va?',
              description:
                  'Estas im\u00e1genes base se usan en \u00bfD\u00f3nde va? para todos los ni\u00f1os que no tengan personalizaci\u00f3n propia.',
              items: defaultDondeVaItems,
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
