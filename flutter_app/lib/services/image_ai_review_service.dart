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
    required this.detectedEmotion,
    required this.emotionSignals,
  });

  const ImageAiReviewResult.pass({
    bool reviewed = true,
    String detectedEmotion = '',
    Map<String, int> emotionSignals = const <String, int>{},
  }) : this._(
          ok: true,
          reviewed: reviewed,
          message: '',
          detectedEmotion: detectedEmotion,
          emotionSignals: emotionSignals,
        );

  const ImageAiReviewResult.block(
    String message, {
    String detectedEmotion = '',
    Map<String, int> emotionSignals = const <String, int>{},
  }) : this._(
          ok: false,
          reviewed: true,
          message: message,
          detectedEmotion: detectedEmotion,
          emotionSignals: emotionSignals,
        );

  final bool ok;
  final bool reviewed;
  final String message;
  final String detectedEmotion;
  final Map<String, int> emotionSignals;
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
      final detectedEmotion = (data['detectedEmotion'] as String?)?.trim() ?? '';
      final emotionSignals = _asIntMap(data['emotionSignals']);
      if (ok) {
        return ImageAiReviewResult.pass(
          reviewed: reviewed,
          detectedEmotion: detectedEmotion,
          emotionSignals: emotionSignals,
        );
      }
      final fallbackMessage = message.isEmpty
          ? 'La imagen no pudo validarse correctamente.'
          : message;
      return ImageAiReviewResult.block(
        _decorateEmotionMessage(
          baseMessage: fallbackMessage,
          context: context,
          detectedEmotion: detectedEmotion,
        ),
        detectedEmotion: detectedEmotion,
        emotionSignals: emotionSignals,
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

  static Map<String, int> _asIntMap(Object? value) {
    final map = _asMap(value);
    return map.map((key, rawValue) => MapEntry(
          key,
          rawValue is num ? rawValue.toInt() : 0,
        ));
  }

  static String _decorateEmotionMessage({
    required String baseMessage,
    required ImageAiReviewContext context,
    required String detectedEmotion,
  }) {
    if (context.expectedEmotion.trim().isEmpty) return baseMessage;
    if (detectedEmotion.isEmpty) return baseMessage;
    if (baseMessage.toLowerCase().contains('la ia la percibe')) {
      return baseMessage;
    }

    final detectedLabel = _prettyEmotionLabel(detectedEmotion);
    if (detectedLabel.isEmpty) return baseMessage;

    if (detectedEmotion == 'indefinida' || detectedEmotion == 'mezclada') {
      return '$baseMessage La IA no detecta una emoción dominante con suficiente claridad.';
    }

    return '$baseMessage La IA la percibe más como $detectedLabel.';
  }

  static String _prettyEmotionLabel(String emotionId) {
    switch (emotionId.trim().toLowerCase()) {
      case 'feliz':
        return 'feliz';
      case 'triste':
        return 'triste';
      case 'enojado':
        return 'enojado';
      case 'sorprendido':
        return 'sorprendido';
      case 'asustado':
        return 'asustado';
      default:
        return '';
    }
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
