import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../controllers/app_controller.dart';

class NarrationService {
  NarrationService._();

  static final NarrationService instance = NarrationService._();

  final AudioPlayer _player = AudioPlayer();
  final Map<String, String> _cache = {};

  Future<void> play(
    AppController controller, {
    required String key,
    bool stopBeforePlay = true,
  }) async {
    if (!controller.soundEffectsEnabled) return;
    final assetPath = _assetPathForNarrator(controller.selectedNarratorId, key);
    if (assetPath.isEmpty) return;
    await _playFromAssetPath(assetPath, stopBeforePlay: stopBeforePlay);
  }

  Future<void> playSequence(
    AppController controller, {
    required List<String> keys,
  }) async {
    if (!controller.soundEffectsEnabled) return;
    for (final key in keys) {
      final assetPath = _assetPathForNarrator(controller.selectedNarratorId, key);
      if (assetPath.isEmpty) continue;
      await _playFromAssetPath(
        assetPath,
        stopBeforePlay: true,
        waitForComplete: true,
      );
    }
  }

  Future<void> playForNarrator({
    required String narratorId,
    required String key,
    required bool enabled,
    bool stopBeforePlay = true,
  }) async {
    if (!enabled) return;
    final assetPath = _assetPathForNarrator(narratorId, key);
    if (assetPath.isEmpty) return;
    await _playFromAssetPath(assetPath, stopBeforePlay: stopBeforePlay);
  }

  Future<void> _playFromAssetPath(
    String assetPath, {
    required bool stopBeforePlay,
    bool waitForComplete = false,
  }) async {
    try {
      if (stopBeforePlay) {
        await _player.stop();
      }
      await _player.play(AssetSource(assetPath), volume: 1.0);
      if (waitForComplete) {
        await _player.onPlayerComplete.first;
      }
      return;
    } catch (_) {
      // Seguimos al fallback.
    }

    final filePath = await _loadToTempFile(assetPath);
    if (filePath.isEmpty) return;
    try {
      if (stopBeforePlay) {
        await _player.stop();
      }
      await _player.play(DeviceFileSource(filePath), volume: 1.0);
      if (waitForComplete) {
        await _player.onPlayerComplete.first;
      }
    } catch (_) {
      // Evitar romper el flujo si el audio falla.
    }
  }

  String _assetPathForNarrator(String narratorId, String key) {
    final isFemale = narratorId.trim() == 'narrator_2';
    final folder = isFemale
        ? 'narration/narrador-mujer'
        : 'narration/narrador-hombre';
    final fileBase = _fileBaseForKey(key);
    if (fileBase.isEmpty) return '';
    final suffix = isFemale ? '-m' : '-h';
    return '$folder/$fileBase$suffix.mp3';
  }

  Future<String> _loadToTempFile(String assetPath) async {
    if (_cache.containsKey(assetPath)) {
      return _cache[assetPath] ?? '';
    }

    final byteData = await _tryLoadFromBundle(assetPath);
    if (byteData == null) return '';
    final dir = await getTemporaryDirectory();
    final safeName = assetPath.replaceAll('/', '_');
    final file = File('${dir.path}/$safeName');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    _cache[assetPath] = file.path;
    return file.path;
  }

  Future<ByteData?> _tryLoadFromBundle(String assetPath) async {
    try {
      return await rootBundle.load('assets/$assetPath');
    } catch (_) {
      try {
        return await rootBundle.load(assetPath);
      } catch (_) {
        return null;
      }
    }
  }

  String _fileBaseForKey(String key) {
    switch (key.trim().toLowerCase()) {
      case 'preferences':
        return 'preferencias';
      case 'profile':
        return 'perfil';
      case 'connect_intro':
        return 'c1';
      case 'cartas_gemelas_intro':
        return 'cg';
      case 'puzzle_intro':
        return 'ai';
      case 'emotion_intro_1':
        return 'd1';
      case 'emotion_intro_2':
        return 'd2';
      case 'logro':
        return 'logro';
      case 'niveles':
        return 'niveles';
      case 'feliz':
        return 'feliz';
      case 'triste':
        return 'triste';
      case 'sorprendido':
        return 'sorprendido';
      case 'asustado':
        return 'asustado';
      case 'enojado':
        return 'enojado';
      case 'presentacion':
        return 'presentacion';
      case 'dilo_intro':
        return 'dilo';
      default:
        return _planetAudioBaseFor(key);
    }
  }

  String _planetAudioBaseFor(String key) {
    final normalized = _normalizeKey(key);
    switch (normalized) {
      case 'mercurio':
        return 'p-mercurio';
      case 'venus':
        return 'p-venus';
      case 'tierra':
        return 'p-tierra';
      case 'marte':
        return 'p-marte';
      case 'jupiter':
        return 'p-jupiter';
      case 'saturno':
        return 'p-saturno';
      case 'urano':
        return 'p-urano';
      case 'neptuno':
        return 'p-neptuno';
      case 'nebulosa dorada':
        return 'nebulosa';
      case 'galaxia prisma':
        return 'galaxia';
      case 'universo infinito':
        return 'universo';
      default:
        return '';
    }
  }

  String _normalizeKey(String raw) {
    final lower = raw.trim().toLowerCase();
    return lower
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ã¡', 'a')
        .replaceAll('ã©', 'e')
        .replaceAll('ã­', 'i')
        .replaceAll('ã³', 'o')
        .replaceAll('ãº', 'u')
        .replaceAll('Ã¡', 'a')
        .replaceAll('Ã©', 'e')
        .replaceAll('Ã­', 'i')
        .replaceAll('Ã³', 'o')
        .replaceAll('Ãº', 'u')
        .replaceAll('Ã¼', 'u');
  }
}
