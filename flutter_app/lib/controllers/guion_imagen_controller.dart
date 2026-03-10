import 'package:flutter/material.dart';

class GuionImagenController extends ChangeNotifier {

  // TEXTO DEL GUIÓN
  String guion = '';

  // LISTA DE IMÁGENES
  List<String> imagenes = [];

  // CAMBIAR TEXTO DEL GUIÓN
  void cambiarGuion(String nuevoTexto) {
    guion = nuevoTexto;
    notifyListeners();
  }

  // AGREGAR IMAGEN
  void agregarImagen(String rutaImagen) {
    imagenes.add(rutaImagen);
    notifyListeners();
  }

  // ELIMINAR IMAGEN
  void eliminarImagen(int index) {
    imagenes.removeAt(index);
    notifyListeners();
  }

}