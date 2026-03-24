import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';

class ImageAiReviewContext {
  const ImageAiReviewContext({
    required this.gameKey,
    required this.itemId,
    this.expectedConcepts = const <String>[],
    this.expectedEmotion = '',
    this.expectedDescription = '',
  });

  final String gameKey;
  final String itemId;
  final List<String> expectedConcepts;
  final String expectedEmotion;
  final String expectedDescription;
}

class ImageAiReviewResult {
  const ImageAiReviewResult._({
    required this.ok,
    required this.reviewed,
    required this.message,
  });

  const ImageAiReviewResult.pass({bool reviewed = true})
      : this._(ok: true, reviewed: reviewed, message: '');

  const ImageAiReviewResult.block(String message)
      : this._(ok: false, reviewed: true, message: message);

  final bool ok;
  final bool reviewed;
  final String message;
}

class ImageAiReviewService {
  ImageAiReviewService._();

  static const String _callableName = 'reviewCustomImage';
  static const Duration _timeout = Duration(seconds: 25);

  static Future<ImageAiReviewResult> reviewImage({
    required String filePath,
    required ImageAiReviewContext context,
  }) async {
    final normalizedPath = filePath.trim();
    if (normalizedPath.isEmpty) {
      return const ImageAiReviewResult.block(
        'No encontramos la imagen para validarla.',
      );
    }

    final file = File(normalizedPath);
    if (!file.existsSync()) {
      return const ImageAiReviewResult.block(
        'La imagen seleccionada ya no esta disponible para validacion.',
      );
    }

    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return const ImageAiReviewResult.block(
          'No pudimos leer la imagen seleccionada.',
        );
      }

      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable(
        _callableName,
        options: HttpsCallableOptions(timeout: _timeout),
      );
      final response = await callable.call(<String, dynamic>{
        'imageBase64': base64Encode(bytes),
        'gameKey': context.gameKey,
        'itemId': context.itemId,
        'expectedConcepts': context.expectedConcepts,
        'expectedEmotion': context.expectedEmotion,
        'expectedDescription': context.expectedDescription,
      });

      final data = _asMap(response.data);
      final ok = data['ok'] == true;
      final reviewed = data['reviewed'] != false;
      final message = (data['message'] as String?)?.trim() ?? '';
      if (ok) {
        return ImageAiReviewResult.pass(reviewed: reviewed);
      }
      return ImageAiReviewResult.block(
        message.isEmpty
            ? 'La imagen no pudo validarse correctamente.'
            : message,
      );
    } on FirebaseFunctionsException catch (error) {
      final message = _messageForFunctionsError(error);
      return ImageAiReviewResult.block(
        message.isEmpty
            ? 'No pudimos validar la imagen en este momento.'
            : message,
      );
    } catch (_) {
      return const ImageAiReviewResult.block(
        'No pudimos validar la imagen en este momento. Intenta de nuevo.',
      );
    }
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  static String _messageForFunctionsError(FirebaseFunctionsException error) {
    final serverMessage = error.message?.trim() ?? '';
    switch (error.code) {
      case 'not-found':
        return 'La validacion inteligente aun no esta desplegada en Firebase. Debes publicar la funcion reviewCustomImage en us-central1.';
      case 'unavailable':
        return 'El servicio de validacion no esta disponible en este momento. Intenta de nuevo en unos minutos.';
      case 'unauthenticated':
        return 'Debes iniciar sesion para validar imagenes.';
      case 'deadline-exceeded':
        return 'La validacion de la imagen tardo demasiado. Intenta con otra imagen o prueba de nuevo.';
      case 'invalid-argument':
        return serverMessage;
      case 'permission-denied':
        return serverMessage.isEmpty
            ? 'La funcion reviewCustomImage esta rechazando la llamada por permisos. Revisa en Cloud Run que permita invocaciones y que tu sesion de Firebase siga activa.'
            : serverMessage;
      case 'internal':
        return serverMessage;
      default:
        return serverMessage;
    }
  }
}
