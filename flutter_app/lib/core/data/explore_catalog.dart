import '../../models/game_content_config.dart';

class ExploreCategoryDefinition {
  const ExploreCategoryDefinition({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

const List<ExploreCategoryDefinition> exploreCategoryDefinitions =
    <ExploreCategoryDefinition>[
  ExploreCategoryDefinition(id: 'animales', label: 'Animales'),
  ExploreCategoryDefinition(id: 'cosas', label: 'Cosas'),
  ExploreCategoryDefinition(id: 'emociones', label: 'Emociones'),
];

const List<ExploreContentItem> defaultExploreItems = <ExploreContentItem>[
  ExploreContentItem(
    id: 'animales_perro',
    categoryId: 'animales',
    title: 'Perro',
    description:
        'El perro suele convivir con las personas y puede aprender rutinas sencillas.',
  ),
  ExploreContentItem(
    id: 'animales_gato',
    categoryId: 'animales',
    title: 'Gato',
    description:
        'El gato se mueve con cuidado, escucha bien y suele descansar muchas horas.',
  ),
  ExploreContentItem(
    id: 'animales_pajaro',
    categoryId: 'animales',
    title: 'Pajaro',
    description:
        'Muchos pajaros tienen plumas, alas y hacen sonidos para comunicarse.',
  ),
  ExploreContentItem(
    id: 'animales_leon',
    categoryId: 'animales',
    title: 'Leon',
    description:
        'El leon es un animal fuerte que vive en grupo y se reconoce por su melena.',
  ),
  ExploreContentItem(
    id: 'animales_elefante',
    categoryId: 'animales',
    title: 'Elefante',
    description:
        'El elefante tiene trompa, orejas grandes y muy buena memoria.',
  ),
  ExploreContentItem(
    id: 'animales_pinguino',
    categoryId: 'animales',
    title: 'Pinguino',
    description:
        'El pinguino camina erguido, vive en lugares frios y se desplaza bien en el agua.',
  ),
  ExploreContentItem(
    id: 'animales_delfin',
    categoryId: 'animales',
    title: 'Delfin',
    description:
        'El delfin nada rapido, respira aire y suele vivir en grupos.',
  ),
  ExploreContentItem(
    id: 'animales_lobo',
    categoryId: 'animales',
    title: 'Lobo',
    description:
        'El lobo se comunica con aullidos y trabaja en equipo con su manada.',
  ),
  ExploreContentItem(
    id: 'cosas_pelota',
    categoryId: 'cosas',
    title: 'Pelota',
    description:
        'La pelota puede botar o rodar y se usa en muchos juegos de movimiento.',
  ),
  ExploreContentItem(
    id: 'cosas_libro',
    categoryId: 'cosas',
    title: 'Libro',
    description:
        'El libro guarda historias e informacion en hojas ordenadas.',
  ),
  ExploreContentItem(
    id: 'cosas_avion',
    categoryId: 'cosas',
    title: 'Avion',
    description:
        'El avion despega, vuela alto y transporta personas o carga.',
  ),
  ExploreContentItem(
    id: 'cosas_bicicleta',
    categoryId: 'cosas',
    title: 'Bicicleta',
    description:
        'La bicicleta tiene dos ruedas y se mueve con pedales.',
  ),
  ExploreContentItem(
    id: 'cosas_reloj',
    categoryId: 'cosas',
    title: 'Reloj',
    description:
        'El reloj ayuda a medir el tiempo y a organizar actividades del dia.',
  ),
  ExploreContentItem(
    id: 'cosas_luna',
    categoryId: 'cosas',
    title: 'Luna',
    description:
        'La luna cambia de forma segun la fase y se ve con frecuencia en la noche.',
  ),
  ExploreContentItem(
    id: 'cosas_cohete',
    categoryId: 'cosas',
    title: 'Cohete',
    description:
        'El cohete se diseña para viajar muy alto y explorar el espacio.',
  ),
  ExploreContentItem(
    id: 'cosas_planeta',
    categoryId: 'cosas',
    title: 'Planeta',
    description:
        'Un planeta gira alrededor de una estrella y puede tener lunas.',
  ),
  ExploreContentItem(
    id: 'emociones_feliz',
    categoryId: 'emociones',
    title: 'Feliz',
    description:
        'Cuando una persona esta feliz suele sonreir, jugar y disfrutar el momento.',
  ),
  ExploreContentItem(
    id: 'emociones_triste',
    categoryId: 'emociones',
    title: 'Triste',
    description:
        'La tristeza puede hacer que alguien quiera estar en calma o necesite consuelo.',
  ),
  ExploreContentItem(
    id: 'emociones_enojado',
    categoryId: 'emociones',
    title: 'Enojado',
    description:
        'El enojo aparece cuando algo molesta y se puede regular con ayuda y respiracion.',
  ),
  ExploreContentItem(
    id: 'emociones_sorprendido',
    categoryId: 'emociones',
    title: 'Sorprendido',
    description:
        'La sorpresa aparece cuando pasa algo inesperado o nuevo.',
  ),
  ExploreContentItem(
    id: 'emociones_calmado',
    categoryId: 'emociones',
    title: 'Calmado',
    description:
        'Sentirse calmado ayuda a pensar mejor y a responder sin prisa.',
  ),
  ExploreContentItem(
    id: 'emociones_asustado',
    categoryId: 'emociones',
    title: 'Asustado',
    description:
        'El miedo avisa de un posible peligro y poco a poco puede bajar al sentirse seguro.',
  ),
];

final Set<String> _defaultExploreItemIds = defaultExploreItems
    .map((item) => item.id.trim().toLowerCase())
    .toSet();

String exploreCategoryLabelFor(String categoryId) {
  final normalized = categoryId.trim().toLowerCase();
  for (final category in exploreCategoryDefinitions) {
    if (category.id == normalized) return category.label;
  }
  return 'Categoria';
}

bool isDefaultExploreItemId(String itemId) {
  return _defaultExploreItemIds.contains(itemId.trim().toLowerCase());
}

ExploreContentItem? defaultExploreItemById(String itemId) {
  final normalized = itemId.trim().toLowerCase();
  for (final item in defaultExploreItems) {
    if (item.id.trim().toLowerCase() == normalized) return item;
  }
  return null;
}

List<ExploreContentItem> mergeExploreItems(
  Iterable<ExploreContentItem> configuredItems,
) {
  final configuredById = <String, ExploreContentItem>{};
  for (final item in configuredItems) {
    final key = item.id.trim().toLowerCase();
    if (key.isEmpty) continue;
    configuredById[key] = item;
  }

  final merged = <ExploreContentItem>[];
  for (final item in defaultExploreItems) {
    final key = item.id.trim().toLowerCase();
    merged.add(configuredById.remove(key) ?? item);
  }

  final extras = configuredById.values.toList()
    ..sort((a, b) {
      final categoryCompare = a.categoryId.compareTo(b.categoryId);
      if (categoryCompare != 0) return categoryCompare;
      return a.title.compareTo(b.title);
    });
  merged.addAll(extras);
  return merged;
}

List<ExploreContentItem> exploreItemsForCategory({
  required Iterable<ExploreContentItem> items,
  required String categoryId,
  bool onlyEnabled = false,
}) {
  final normalized = categoryId.trim().toLowerCase();
  return items
      .where((item) => item.categoryId.trim().toLowerCase() == normalized)
      .where((item) => !onlyEnabled || item.enabled)
      .toList(growable: false);
}
