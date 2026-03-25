import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/app_controller.dart';
import '../../core/data/donde_va_catalog.dart';
import '../../core/data/explore_catalog.dart';
import '../../core/data/puzzle_catalog.dart';
import '../../services/image_preparation_service.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/nebula_button.dart';
import '../../widgets/nebula_snack.dart';
import '../../widgets/puzzle_image_adapter.dart';

class PersonalizationScreen extends StatefulWidget {
  const PersonalizationScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends State<PersonalizationScreen> {
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

  final ImagePicker _picker = ImagePicker();

  String _selectedChildId = '';
  String? _busyKey;
  int _previewRevision = 0;
  List<_GameImageSection> _sections = const <_GameImageSection>[];

  @override
  void initState() {
    super.initState();
    final selected = widget.controller.childProfile?.id.trim() ?? '';
    if (selected.isNotEmpty) {
      _selectedChildId = selected;
    } else if (widget.controller.childProfiles.isNotEmpty) {
      _selectedChildId = widget.controller.childProfiles.first.id;
    }
    _buildSections();
  }

  void _buildSections() {
    final sections = <_GameImageSection>[
      _emotionSection(),
      _soundSection(),
      _puzzleSection(),
      _exploreSection(),
      _dondeVaSection(),
    ];
    if (!mounted) return;
    setState(() => _sections = sections);
  }

  _GameImageSection _emotionSection() {
    final items = <String, _GameImageItem>{};

    for (final source in _defaultEmotionImages) {
      final itemId = widget.controller.customContentItemId(source: source);
      final expectedEmotion = _emotionFromSource(source);
      items[itemId] = _GameImageItem(
        gameKey: 'emociones',
        itemId: itemId,
        title: _prettyNameFromSource(source),
        subtitle: _emotionLevelLabel(source),
        defaultSource: source,
        expectedEmotion: expectedEmotion,
        expectedDescription: _prettyEmotionName(expectedEmotion),
      );
    }

    for (final item in widget.controller.gameContentConfig.emotionItems) {
      if (!item.enabled || item.imagePath.trim().isEmpty) continue;
      final source = item.imagePath.trim();
      final itemId = widget.controller.customContentItemId(
        source: source,
        rawId: item.id,
      );
      items[itemId] = _GameImageItem(
        gameKey: 'emociones',
        itemId: itemId,
        title: item.correctEmotion.trim().isEmpty
            ? _prettyNameFromSource(source)
            : item.correctEmotion.trim(),
        subtitle: 'Nivel ${item.difficultyStars} Â· contenido actual',
        defaultSource: source,
        expectedEmotion: item.correctEmotion.trim(),
        expectedDescription: item.correctEmotion.trim(),
      );
    }

    final sorted = items.values.toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return _GameImageSection(
      title: 'Emociones',
      description: 'ImÃ¡genes usadas en reconocimiento emocional.',
      items: sorted,
    );
  }

  _GameImageSection _soundSection() {
    final items = <String, _GameImageItem>{};

    for (final source in _defaultSoundImages) {
      final itemId = widget.controller.customContentItemId(source: source);
      items[itemId] = _GameImageItem(
        gameKey: 'sonidos',
        itemId: itemId,
        title: _prettyNameFromSource(source),
        subtitle: 'Set actual de sonidos e imÃ¡genes',
        defaultSource: source,
        expectedConcepts: _expectedConceptsFromSource(source),
        expectedDescription: _prettyNameFromSource(source),
      );
    }

    for (final item in widget.controller.gameContentConfig.soundItems) {
      if (!item.enabled || item.correctImage.trim().isEmpty) continue;
      final source = item.correctImage.trim();
      final itemId = widget.controller.customContentItemId(
        source: source,
        rawId: item.id,
      );
      final category = item.category.trim();
      items[itemId] = _GameImageItem(
        gameKey: 'sonidos',
        itemId: itemId,
        title: _prettyNameFromSource(source),
        subtitle: category.isEmpty
            ? 'Nivel ${item.difficultyStars} Â· contenido actual'
            : '$category Â· nivel ${item.difficultyStars}',
        defaultSource: source,
        expectedConcepts: _expectedConceptsFromSource(
          source,
          extraLabels: <String>[category],
        ),
        expectedDescription: _prettyNameFromSource(source),
      );
    }

    final sorted = items.values.toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return _GameImageSection(
      title: 'Conecta sonidos',
      description: 'ImÃ¡genes que acompaÃ±an sonidos y opciones del juego.',
      items: sorted,
    );
  }

  _GameImageSection _puzzleSection() {
    final items = <String, _GameImageItem>{};

    for (final source in defaultPuzzleImageSources) {
      final itemId = widget.controller.customContentItemId(source: source);
      items[itemId] = _GameImageItem(
        gameKey: 'puzzle',
        itemId: itemId,
        title: _prettyNameFromSource(source),
        subtitle: 'Imagen base del rompecabezas',
        defaultSource: source,
        expectedConcepts: _expectedConceptsFromSource(source),
        expectedDescription: _prettyNameFromSource(source),
      );
    }

    for (final item in widget.controller.gameContentConfig.puzzleItems) {
      if (!item.enabled || item.imageSource.trim().isEmpty) continue;
      final source = item.imageSource.trim();
      final itemId = widget.controller.customContentItemId(
        source: source,
        rawId: item.id,
      );
      items[itemId] = _GameImageItem(
        gameKey: 'puzzle',
        itemId: itemId,
        title: item.id.trim().isEmpty
            ? _prettyNameFromSource(source)
            : item.id.trim(),
        subtitle: 'Imagen actual del rompecabezas',
        defaultSource: source,
        expectedConcepts: _expectedConceptsFromSource(source),
        expectedDescription: _prettyNameFromSource(source),
      );
    }

    final sorted = items.values.toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return _GameImageSection(
      title: 'Arma la imagen',
      description: 'Im\u00e1genes usadas en los rompecabezas del ni\u00f1o.',
      items: sorted,
    );
  }

  _GameImageSection _exploreSection() {
    final merged = mergeExploreItems(
      widget.controller.gameContentConfig.exploreItems,
    );
    final items = merged
        .where((item) => item.enabled)
        .map((item) {
          final builtIn = defaultExploreBuiltInItemById(item.id);
          final categoryLabel = exploreCategoryLabelFor(item.categoryId);
          final defaultSource = item.imageSource.trim().isNotEmpty
              ? item.imageSource.trim()
              : builtIn?.imageSource ?? '';
          final title = item.title.trim().isNotEmpty
              ? item.title.trim()
              : builtIn?.title ?? 'Explora';
          return _GameImageItem(
            gameKey: 'explora_aprende',
            itemId: item.id,
            title: title,
            subtitle: '$categoryLabel \u00b7 contenido actual',
            defaultSource: defaultSource,
            expectedConcepts: <String>[title, categoryLabel],
            expectedDescription: title,
          );
        })
        .toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return _GameImageSection(
      title: 'Explora y aprende',
      description: 'Im\u00e1genes usadas en Animales, Historia y Arte.',
      items: items,
    );
  }

  _GameImageSection _dondeVaSection() {
    final mergedCategories = mergeDondeVaCategories(
      widget.controller.gameContentConfig.dondeVaItems,
    );
    final items = <_GameImageItem>[];
    for (final category in mergedCategories) {
      for (final item in category.items) {
        items.add(
          _GameImageItem(
            gameKey: 'donde_va',
            itemId: dondeVaGlobalItemId(
              categoryId: category.id,
              itemId: item.id,
            ),
            title: item.label,
            subtitle: '${category.label} \u00b7 contenido actual',
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
        );
      }
    }
    items.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return _GameImageSection(
      title: '\u00bfD\u00f3nde va?',
      description: 'Objetos que el ni\u00f1o clasifica por categor\u00eda.',
      items: items,
    );
  }

  String _emotionLevelLabel(String source) {
    final normalized = source.toLowerCase();
    if (normalized.contains('/facil/')) {
      return 'Aparece en dificultad fÃ¡cil Â· contenido actual';
    }
    if (normalized.contains('/medio/')) {
      return 'Aparece en dificultad media Â· contenido actual';
    }
    if (normalized.contains('/dificil/')) {
      return 'Aparece en dificultad difÃ­cil Â· contenido actual';
    }
    return 'Contenido actual';
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
          .replaceAll('Ã¡', 'a')
          .replaceAll('Ã©', 'e')
          .replaceAll('Ã­', 'i')
          .replaceAll('Ã³', 'o')
          .replaceAll('Ãº', 'u')
          .replaceAll('Ã¼', 'u')
          .replaceAll('Ã±', 'n')
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

  String _selectedChildName() {
    for (final child in widget.controller.childProfiles) {
      if (child.id != _selectedChildId) continue;
      final name = child.name.trim();
      return name.isEmpty ? 'niÃ±o sin nombre' : name;
    }
    return 'este perfil';
  }

  Future<void> _pickImage({
    required _GameImageItem item,
    required ImageSource source,
  }) async {
    final childId = _selectedChildId.trim();
    if (childId.isEmpty) return;
    final busyKey = '$childId::${item.gameKey}::${item.itemId}';
    setState(() => _busyKey = busyKey);
    try {
      final previousSource = widget.controller.resolvedGameImageSourceFor(
        gameKey: item.gameKey,
        itemId: item.itemId,
        defaultSource: item.defaultSource,
        childId: childId,
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
      final result = await widget.controller.saveCustomGameImage(
        gameKey: item.gameKey,
        itemId: item.itemId,
        filePath: prepared.filePath,
        childId: childId,
        expectedConcepts: item.expectedConcepts,
        expectedEmotion: item.expectedEmotion,
        expectedDescription: item.expectedDescription,
      );
      if (!mounted) return;
      if (result.ok) {
        final nextSource = widget.controller.resolvedGameImageSourceFor(
          gameKey: item.gameKey,
          itemId: item.itemId,
          defaultSource: item.defaultSource,
          childId: childId,
        );
        await evictPuzzleImageSource(previousSource);
        if (nextSource != previousSource) {
          await evictPuzzleImageSource(nextSource);
        }
        setState(() => _previewRevision++);
      }
      if (!mounted) return;
      await NebulaSnack.show(context, message: result.message, ok: result.ok);
      _buildSections();
    } finally {
      if (mounted) {
        setState(() => _busyKey = null);
      }
    }
  }

  Future<void> _restoreImage(_GameImageItem item) async {
    final childId = _selectedChildId.trim();
    if (childId.isEmpty) return;
    final previousSource = widget.controller.resolvedGameImageSourceFor(
      gameKey: item.gameKey,
      itemId: item.itemId,
      defaultSource: item.defaultSource,
      childId: childId,
    );
    final result = await widget.controller.restoreCustomGameImage(
      gameKey: item.gameKey,
      itemId: item.itemId,
      childId: childId,
    );
    if (!mounted) return;
    if (result.ok) {
      final nextSource = widget.controller.resolvedGameImageSourceFor(
        gameKey: item.gameKey,
        itemId: item.itemId,
        defaultSource: item.defaultSource,
        childId: childId,
      );
      await evictPuzzleImageSource(previousSource);
      if (nextSource != previousSource) {
        await evictPuzzleImageSource(nextSource);
      }
      setState(() => _previewRevision++);
    }
    if (!mounted) return;
    await NebulaSnack.show(context, message: result.message, ok: result.ok);
    _buildSections();
  }

  Future<void> _openSourceSheet(_GameImageItem item) async {
    if (_selectedChildId.trim().isEmpty) {
      await NebulaSnack.show(
        context,
        message: 'Primero selecciona un perfil de niÃ±o.',
        ok: false,
      );
      return;
    }

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
                  await _pickImage(item: item, source: ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Usar galerÃ­a'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pickImage(item: item, source: ImageSource.gallery);
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

    final children = widget.controller.childProfiles;
    var previewChildId = _selectedChildId.trim();
    if (previewChildId.isEmpty ||
        !children.any((child) => child.id == previewChildId)) {
      previewChildId = children.isNotEmpty ? children.first.id : '';
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('PersonalizaciÃ³n de contenido'),
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
                      'Personaliza imÃ¡genes por niÃ±o y por juego',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Las imÃ¡genes se sincronizan entre dispositivos del cuidador. Formatos permitidos: JPG y PNG. TamaÃ±o mÃ¡ximo: 5 MB por imagen. Antes de guardarlas tambiÃ©n se revisa que el recorte y el contenido sean adecuados para el juego.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (children.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'No hay perfiles de niÃ±o disponibles. Crea uno primero desde la zona de cuidador.',
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: DropdownButtonFormField<String>(
                    initialValue: previewChildId,
                    decoration: const InputDecoration(
                      labelText: 'Perfil de niÃ±o',
                    ),
                    items: children
                        .map(
                          (child) => DropdownMenuItem<String>(
                            value: child.id,
                            child: Text(
                              child.name.trim().isEmpty
                                  ? 'NiÃ±o sin nombre'
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
            ..._sections.map((section) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ExpansionTile(
                    title: Text(section.title),
                    subtitle: Text(
                      '${section.items.length} imÃ¡genes Â· ${section.description}',
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    children: section.items.map((item) {
                      final busyKey =
                          '$previewChildId::${item.gameKey}::${item.itemId}';
                      final busy = _busyKey == busyKey;
                      final effectiveSource =
                          widget.controller.resolvedGameImageSourceFor(
                        gameKey: item.gameKey,
                        itemId: item.itemId,
                        defaultSource: item.defaultSource,
                        childId: previewChildId,
                      );
                      final isCustomized = widget.controller.hasCustomGameImage(
                        gameKey: item.gameKey,
                        itemId: item.itemId,
                        childId: previewChildId,
                      );
                      final provider =
                          puzzleImageProviderFromSource(effectiveSource);
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
                            SizedBox(
                              width: 72,
                              height: 72,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: provider == null
                                    ? const ColoredBox(
                                        color: Color(0xFFE8ECF7),
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                        ),
                                      )
                                    : Image(
                                        key: ValueKey(
                                          '$previewChildId::${item.gameKey}::${item.itemId}::$_previewRevision::$effectiveSource',
                                        ),
                                        image: provider,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const ColoredBox(
                                          color: Color(0xFFE8ECF7),
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.subtitle,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isCustomized
                                        ? 'Imagen personalizada para ${_selectedChildName()}.'
                                        : 'Usando imagen original del juego.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: isCustomized
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
                                            : () => _openSourceSheet(item),
                                        icon: busy
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Icon(Icons.edit_outlined),
                                        label: Text(
                                          busy ? 'Guardando...' : 'Cambiar',
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: isCustomized
                                            ? () => _restoreImage(item)
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
                ),
              );
            }),
            const SizedBox(height: 8),
            NebulaSecondaryButton(
              text: 'Recargar contenido',
              onPressed: _buildSections,
            ),
          ],
        ),
      ),
    );
  }
}

class _GameImageSection {
  const _GameImageSection({
    required this.title,
    required this.description,
    required this.items,
  });

  final String title;
  final String description;
  final List<_GameImageItem> items;
}

class _GameImageItem {
  const _GameImageItem({
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
