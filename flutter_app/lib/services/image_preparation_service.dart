import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../screens/image_crop_editor_screen.dart';

class PreparedImageResult {
  const PreparedImageResult._({
    required this.filePath,
    required this.message,
    required this.cancelled,
  });

  const PreparedImageResult.success(String filePath)
      : this._(filePath: filePath, message: '', cancelled: false);

  const PreparedImageResult.error(String message)
      : this._(filePath: '', message: message, cancelled: false);

  const PreparedImageResult.cancelled()
      : this._(filePath: '', message: '', cancelled: true);

  final String filePath;
  final String message;
  final bool cancelled;

  bool get ok => filePath.trim().isNotEmpty;
}

class ImagePreparationService {
  ImagePreparationService._();

  static const int minCropSide = 384;
  static const double minAspectRatio = 0.75;
  static const double maxAspectRatio = 1.35;

  static Future<PreparedImageResult> cropAndValidate(
    BuildContext context,
    String sourcePath,
  ) async {
    final normalized = sourcePath.trim();
    if (normalized.isEmpty) {
      return const PreparedImageResult.error(
        'No se encontr\u00f3 la imagen seleccionada.',
      );
    }

    final file = File(normalized);
    if (!file.existsSync()) {
      return const PreparedImageResult.error(
        'La imagen seleccionada ya no est\u00e1 disponible.',
      );
    }

    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return const PreparedImageResult.error(
          'No se pudo leer la imagen seleccionada.',
        );
      }
      if (!context.mounted) {
        return const PreparedImageResult.cancelled();
      }

      final croppedBytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          builder: (_) => ImageCropEditorScreen(imageBytes: bytes),
          fullscreenDialog: true,
        ),
      );
      if (croppedBytes == null || croppedBytes.isEmpty) {
        return const PreparedImageResult.cancelled();
      }

      final preparedPath = await _writePreparedImageFile(
        originalPath: normalized,
        imageBytes: croppedBytes,
      );
      final validation = await _validateCrop(preparedPath);
      if (validation != null) {
        return PreparedImageResult.error(validation);
      }
      return PreparedImageResult.success(preparedPath);
    } catch (_) {
      return const PreparedImageResult.error(
        'No pudimos preparar la imagen seleccionada.',
      );
    }
  }

  static Future<String> _writePreparedImageFile({
    required String originalPath,
    required Uint8List imageBytes,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}${Platform.pathSeparator}nebula_prepared_images');
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }
    final extension = _safeExtension(originalPath);
    final outputPath =
        '${cacheDir.path}${Platform.pathSeparator}prepared_${DateTime.now().microsecondsSinceEpoch}.$extension';
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(imageBytes, flush: true);
    return outputFile.path;
  }

  static String _safeExtension(String originalPath) {
    final dot = originalPath.lastIndexOf('.');
    if (dot < 0 || dot >= originalPath.length - 1) return 'png';
    final extension = originalPath.substring(dot + 1).trim().toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => extension,
      'png' => 'png',
      _ => 'png',
    };
  }

  static Future<String?> _validateCrop(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      return 'No se pudo preparar la imagen recortada.';
    }
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final width = image.width;
      final height = image.height;
      image.dispose();
      codec.dispose();

      if (width < minCropSide || height < minCropSide) {
        return 'El recorte qued\u00f3 muy peque\u00f1o. Usa un \u00e1rea de al menos ${minCropSide}x$minCropSide px.';
      }

      final ratio = width / height;
      if (ratio < minAspectRatio || ratio > maxAspectRatio) {
        return 'El recorte debe quedar con proporciones parecidas a las imágenes predeterminadas: no muy vertical ni demasiado ancho.';
      }
      return null;
    } catch (_) {
      return 'No pudimos validar el recorte de la imagen.';
    }
  }
}
