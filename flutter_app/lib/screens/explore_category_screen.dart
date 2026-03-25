import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../core/data/explore_catalog.dart';
import '../models/game_content_config.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/puzzle_image_adapter.dart';

class ExploreCategoryScreen extends StatefulWidget {
  const ExploreCategoryScreen({
    super.key,
    required this.controller,
    required this.categoryId,
  });

  final AppController controller;
  final String categoryId;

  @override
  State<ExploreCategoryScreen> createState() => _ExploreCategoryScreenState();
}

class _ExploreCategoryScreenState extends State<ExploreCategoryScreen> {
  final AudioPlayer _player = AudioPlayer();
  final Random _random = Random();

  String _currentItemId = '';

  ExploreCategoryDefinition get _categoryDefinition =>
      exploreCategoryDefinitionFor(widget.categoryId) ??
      ExploreCategoryDefinition(
        id: widget.categoryId,
        label: 'Explora',
        subtitle: 'Descubre nuevos temas',
        coverImagePath: '',
      );

  List<ExploreContentItem> get _categoryItems {
    final merged = mergeExploreItems(widget.controller.gameContentConfig.exploreItems);
    return exploreItemsForCategory(
      items: merged,
      categoryId: widget.categoryId,
      onlyEnabled: true,
    );
  }

  ExploreContentItem? get _currentItem {
    final items = _categoryItems;
    if (items.isEmpty) return null;
    for (final item in items) {
      if (item.id == _currentItemId) return item;
    }
    return items.first;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectRandomItem(forceDifferent: false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _playAudioForCurrentItem() async {
    final item = _currentItem;
    if (item == null) return;
    final display = _displayForItem(item);
    final source = display.audioSource.trim();
    if (source.isEmpty) return;

    await _player.stop();
    if (source.startsWith('http://') || source.startsWith('https://')) {
      await _player.play(UrlSource(source));
      return;
    }
    if (source.startsWith('assets/')) {
      await _player.play(AssetSource(source.substring('assets/'.length)));
      return;
    }
    await _player.play(DeviceFileSource(source));
  }

  void _selectRandomItem({required bool forceDifferent}) {
    final items = _categoryItems;
    if (items.isEmpty) {
      if (mounted) {
        setState(() => _currentItemId = '');
      }
      return;
    }

    final previousId = _currentItemId;
    ExploreContentItem selected = items[_random.nextInt(items.length)];
    if (forceDifferent && items.length > 1) {
      for (var attempt = 0; attempt < 8; attempt++) {
        final candidate = items[_random.nextInt(items.length)];
        if (candidate.id != previousId) {
          selected = candidate;
          break;
        }
      }
    }

    if (!mounted) return;
    setState(() => _currentItemId = selected.id);
    Future<void>.delayed(const Duration(milliseconds: 160), () {
      if (!mounted) return;
      _playAudioForCurrentItem();
    });
  }

  _ExploreDisplayItem _displayForItem(ExploreContentItem item) {
    final builtIn = defaultExploreBuiltInItemById(item.id);
    final defaultImageSource = item.imageSource.trim().isEmpty
        ? builtIn?.imageSource ?? ''
        : item.imageSource.trim();
    final resolvedImageSource = widget.controller.resolvedGameImageSourceFor(
      gameKey: 'explora_aprende',
      itemId: item.id,
      defaultSource: defaultImageSource,
    );
    if (builtIn != null) {
      return _ExploreDisplayItem(
        itemId: item.id,
        title: item.title.trim().isEmpty ? builtIn.title : item.title,
        description: item.description.trim().isEmpty
            ? builtIn.description
            : item.description,
        imageSource: resolvedImageSource,
        audioSource: item.audioSourceForNarrator(
                  widget.controller.selectedNarratorId,
                )
                .trim()
                .isEmpty
            ? builtIn.audioSourceForNarrator(
                widget.controller.selectedNarratorId,
              )
            : item.audioSourceForNarrator(widget.controller.selectedNarratorId),
      );
    }
    return _ExploreDisplayItem(
      itemId: item.id,
      title: item.title.trim().isEmpty ? builtIn?.title ?? 'Explora' : item.title,
      description: item.description.trim().isEmpty
          ? builtIn?.description ?? 'Sin descripci\u00f3n disponible.'
          : item.description,
      imageSource: resolvedImageSource,
      audioSource: item.audioSourceForNarrator(widget.controller.selectedNarratorId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = _currentItem;
    final display = item == null ? null : _displayForItem(item);
    final color = widget.controller.accentButtonColor;

    return Scaffold(
      appBar: AppBar(title: Text(_categoryDefinition.label)),
      body: CosmicBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: item == null || display == null
                ? _ExploreEmptyState(category: _categoryDefinition)
                : Column(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final imageSize = min(
                                    constraints.maxWidth,
                                    constraints.maxHeight,
                                  );
                                  return Center(
                                    child: PuzzleImageAdapter(
                                      imageSource: display.imageSource,
                                      size: imageSize,
                                      borderRadius: 28,
                                      fit: BoxFit.contain,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              display.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF203666),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        flex: 3,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: color.withValues(alpha: 0.15),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 16,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: SingleChildScrollView(
                              child: Text(
                                display.description,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _selectRandomItem(forceDifferent: true),
                                icon: const Icon(Icons.shuffle, size: 28),
                                label: const Text(
                                  'Cambiar',
                                  style: TextStyle(fontSize: 18),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: color,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _playAudioForCurrentItem,
                                icon: const Icon(Icons.volume_up, size: 28),
                                label: const Text(
                                  'Escuchar',
                                  style: TextStyle(fontSize: 18),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade400,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
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
      ),
    );
  }
}

class _ExploreDisplayItem {
  const _ExploreDisplayItem({
    required this.itemId,
    required this.title,
    required this.description,
    required this.imageSource,
    required this.audioSource,
  });

  final String itemId;
  final String title;
  final String description;
  final String imageSource;
  final String audioSource;
}

class _ExploreEmptyState extends StatelessWidget {
  const _ExploreEmptyState({required this.category});

  final ExploreCategoryDefinition category;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.explore_off_rounded, size: 54),
            const SizedBox(height: 12),
            Text(
              'Sin contenido activo en ${category.label}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF203666),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cuando el administrador active o agregue elementos, aparecer\u00e1n aqu\u00ed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.35,
                color: Color(0xFF5B6C8B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
