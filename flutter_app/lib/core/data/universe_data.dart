class UniverseItem {
  final String id;
  final String title;
  final String image;
  final List<String> audios;

  UniverseItem({
    required this.id,
    required this.title,
    required this.image,
    required this.audios,
  });

  /// Genera automáticamente los 5 audios (SE MANTIENE IGUAL)
  static List<String> generateAudioPaths(String id) {
    return List.generate(
      5,
      (index) => "assets/sounds/universe/${id}_${index + 1}.mp3",
    );
  }
}

/// Helper para crear items de forma limpia
UniverseItem createItem(String id, String title) {
  return UniverseItem(
    id: id,
    title: title,
    image: "assets/images/universe/$id.png",
    audios: UniverseItem.generateAudioPaths(id),
  );
}

/// Lista completa (IDs sin tildes ni ñ)
final List<UniverseItem> universeItems = [
  createItem("arenoso", "Arenoso"),
  createItem("dragon", "Dragón"),
  createItem("dulces", "Dulces"),
  createItem("galaxia", "Galaxia"),
  createItem("jupiter", "Júpiter"),
  createItem("laberinto", "Laberinto"),
  createItem("luna", "Luna"),
  createItem("mundo", "Mundo"),
  createItem("nino", "Niño"), // ⚠️ importante: archivo sin ñ 
  createItem("nuevo", "Nuevo"),
  createItem("planeta", "Planeta"),
  createItem("portal", "Portal"),
  createItem("rompecabezas", "Rompecabezas"),
  createItem("serpiente", "Serpiente"),
  createItem("tierra", "Tierra"),
];