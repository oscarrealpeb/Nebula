import 'dart:io';
import 'package:image/image.dart' as img;

class ImageResizeService {

  /// Ajusta una imagen a tamaño cuadrado
  /// recomendado para móviles (512x512 o 1024x1024)

  static Future<File> resizeImage(File imageFile, {int size = 512}) async {

    // leer imagen
    final bytes = await imageFile.readAsBytes();

    // decodificar imagen
    img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception("No se pudo procesar la imagen");
    }

    // redimensionar imagen
    img.Image resized = img.copyResize(
      image,
      width: size,
      height: size,
    );

    // guardar imagen nueva
    final resizedFile = File(imageFile.path)
      ..writeAsBytesSync(img.encodeJpg(resized));

    return resizedFile;
  }
}