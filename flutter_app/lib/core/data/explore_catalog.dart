import '../../models/game_content_config.dart';

class ExploreCategoryDefinition {
  const ExploreCategoryDefinition({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.coverImagePath,
  });

  final String id;
  final String label;
  final String subtitle;
  final String coverImagePath;
}

class ExploreBuiltInItem {
  const ExploreBuiltInItem({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.imageSource,
    required this.audioKey,
    this.historyPrefix = '',
  });

  final String id;
  final String categoryId;
  final String title;
  final String description;
  final String imageSource;
  final String audioKey;
  final String historyPrefix;

  bool get usesHistoryNarration => historyPrefix.isNotEmpty;

  String audioSourceForNarrator(String narratorId) {
    final normalizedNarrator = narratorId.trim().toLowerCase();
    if (usesHistoryNarration) {
      final fileName = normalizedNarrator == 'narrator_2'
          ? 'm${historyPrefix}1.mp3'
          : '${historyPrefix}1.mp3';
      return 'sounds/explora/historia/$audioKey/$fileName';
    }
    final voice = normalizedNarrator == 'narrator_2' ? 'f' : 'm';
    return 'sounds/explora/$categoryId/$audioKey/${voice}_1.mp3';
  }

  ExploreContentItem toContentItem() {
    return ExploreContentItem(
      id: id,
      categoryId: categoryId,
      title: title,
      description: description,
      imageSource: imageSource,
    );
  }
}

ExploreBuiltInItem _animal(String id, String title, String description) {
  return ExploreBuiltInItem(
    id: 'explora_animales_$id',
    categoryId: 'animales',
    title: title,
    description: description,
    imageSource: 'assets/images/explora/animales/$id.png',
    audioKey: id,
  );
}

ExploreBuiltInItem _art(String id, String title, String description) {
  return ExploreBuiltInItem(
    id: 'explora_arte_$id',
    categoryId: 'arte',
    title: title,
    description: description,
    imageSource: 'assets/images/explora/arte/$id.png',
    audioKey: id,
  );
}

ExploreBuiltInItem _history(
  String id,
  String title,
  String description,
  String prefix,
) {
  return ExploreBuiltInItem(
    id: 'explora_historia_$id',
    categoryId: 'historia',
    title: title,
    description: description,
    imageSource: 'assets/images/explora/historia/$id.png',
    audioKey: id,
    historyPrefix: prefix,
  );
}

const List<ExploreCategoryDefinition> exploreCategoryDefinitions =
    <ExploreCategoryDefinition>[
  ExploreCategoryDefinition(
    id: 'animales',
    label: 'Animales',
    subtitle: 'Curiosidades del mundo animal',
    coverImagePath: 'assets/images/explora/animales.png',
  ),
  ExploreCategoryDefinition(
    id: 'historia',
    label: 'Historia',
    subtitle: 'Viajes y datos del pasado',
    coverImagePath: 'assets/images/explora/historia.png',
  ),
  ExploreCategoryDefinition(
    id: 'arte',
    label: 'Arte',
    subtitle: 'Obras y artistas famosos',
    coverImagePath: 'assets/images/explora/arte.png',
  ),
];

final List<ExploreBuiltInItem> defaultExploreBuiltInItems =
    <ExploreBuiltInItem>[
  _animal(
    'perro',
    'Perro',
    'Los perros tienen un olfato muy fuerte y suelen ser compa\u00f1eros leales.',
  ),
  _animal(
    'gato',
    'Gato',
    'Los gatos son \u00e1giles, curiosos y pueden ver mejor que nosotros en la oscuridad.',
  ),
  _animal(
    'conejo',
    'Conejo',
    'Los conejos tienen orejas largas, saltan r\u00e1pido y comen muchas plantas.',
  ),
  _animal(
    'vaca',
    'Vaca',
    'Las vacas producen leche, pasan mucho tiempo comiendo pasto y tienen gran memoria.',
  ),
  _animal(
    'caballo',
    'Caballo',
    'Los caballos pueden correr r\u00e1pido y han acompa\u00f1ado a las personas durante siglos.',
  ),
  _animal(
    'elefante',
    'Elefante',
    'Los elefantes son enormes, usan la trompa para muchas tareas y recuerdan mucho.',
  ),
  _animal(
    'leon',
    'Le\u00f3n',
    'El le\u00f3n vive en manadas, ruge muy fuerte y es uno de los grandes felinos.',
  ),
  _animal(
    'tigre',
    'Tigre',
    'Cada tigre tiene rayas \u00fanicas y es uno de los felinos m\u00e1s grandes del planeta.',
  ),
  _animal(
    'jirafa',
    'Jirafa',
    'La jirafa es el animal m\u00e1s alto del mundo y usa su cuello para alcanzar hojas altas.',
  ),
  _animal(
    'mono',
    'Mono',
    'Los monos viven en grupos, trepan \u00e1rboles y usan manos y cola para moverse.',
  ),
  _animal(
    'oso',
    'Oso',
    'Los osos son fuertes, huelen muy bien y algunos hibernan durante el invierno.',
  ),
  _animal(
    'delfin',
    'Delf\u00edn',
    'Los delfines son mam\u00edferos marinos inteligentes que se comunican con sonidos.',
  ),
  _animal(
    'tucan',
    'Tuc\u00e1n',
    'El tuc\u00e1n destaca por su pico grande y colorido, ideal para alcanzar frutas.',
  ),
  _animal(
    'pinguino',
    'Ping\u00fcino',
    'Los ping\u00fcinos no vuelan, pero nadan muy bien y viven en lugares fr\u00edos.',
  ),
  _animal(
    'tortuga',
    'Tortuga',
    'Las tortugas tienen caparaz\u00f3n, se mueven despacio y algunas viven much\u00edsimos a\u00f1os.',
  ),
  _art(
    'mona_lisa',
    'La Mona Lisa',
    'La Mona Lisa es una de las pinturas m\u00e1s famosas del mundo y su sonrisa parece misteriosa.',
  ),
  _art(
    'noche_estrellada',
    'La noche estrellada',
    'Van Gogh pint\u00f3 un cielo lleno de movimiento y colores brillantes en esta obra.',
  ),
  _art(
    'girasoles',
    'Los girasoles',
    'Los girasoles de Van Gogh usan el amarillo para transmitir luz, energ\u00eda y vida.',
  ),
  _art(
    'el_grito',
    'El grito',
    'Esta obra de Edvard Munch transmite una emoci\u00f3n intensa de miedo o ansiedad.',
  ),
  _art(
    'joven_perla',
    'La joven de la perla',
    'La joven de la perla es famosa por su mirada, la luz en su rostro y su gran misterio.',
  ),
  _art(
    'da_vinci',
    'Leonardo da Vinci',
    'Leonardo da Vinci fue pintor, inventor y uno de los grandes genios del Renacimiento.',
  ),
  _art(
    'van_gogh',
    'Vincent van Gogh',
    'Van Gogh pint\u00f3 con colores intensos y pinceladas muy expresivas.',
  ),
  _art(
    'picasso',
    'Pablo Picasso',
    'Picasso fue un artista espa\u00f1ol muy famoso y creador del cubismo.',
  ),
  _art(
    'frida_kahlo',
    'Frida Kahlo',
    'Frida Kahlo fue una artista mexicana conocida por sus autorretratos y su estilo \u00fanico.',
  ),
  _art(
    'dali',
    'Salvador Dal\u00ed',
    'Salvador Dal\u00ed es uno de los artistas m\u00e1s reconocidos del surrealismo.',
  ),
  _history(
    'dinosaurios',
    'Dinosaurios',
    'Los dinosaurios vivieron hace millones de a\u00f1os y algunos eran enormes, tranquilos o feroces.',
    'DIN',
  ),
  _history(
    'ciudades',
    'Ciudades antiguas',
    'Las primeras ciudades ten\u00edan casas simples, mercados y reglas para convivir.',
    'CIU',
  ),
  _history(
    'piratas',
    'Piratas',
    'Los piratas viajaban por el mar, segu\u00edan mapas y buscaban tesoros escondidos.',
    'PIR',
  ),
  _history(
    'egipcios',
    'Egipcios',
    'Los egipcios construyeron pir\u00e1mides, escribieron jerogl\u00edficos y vivieron junto al Nilo.',
    'EGI',
  ),
  _history(
    'castillos',
    'Castillos',
    'Los castillos ten\u00edan muros altos, torres y caballeros que proteg\u00edan a sus reinos.',
    'CAS',
  ),
  _history(
    'vikingos',
    'Vikingos',
    'Los vikingos navegaban en barcos largos y contaban historias de dioses y h\u00e9roes.',
    'VIK',
  ),
  _history(
    'romanos',
    'Romanos',
    'Los romanos construyeron caminos, coliseos y un imperio enorme.',
    'ROM',
  ),
  _history(
    'exploradores',
    'Exploradores',
    'Muchos exploradores viajaron durante meses, gui\u00e1ndose por mapas, estrellas y diarios.',
    'EXP',
  ),
  _history(
    'reyes',
    'Reyes',
    'Reyes y reinas viv\u00edan en palacios, usaban coronas y tomaban decisiones importantes.',
    'REY',
  ),
  _history(
    'transportes',
    'Transportes antiguos',
    'Antes la gente viajaba en barcos de vela, carros con caballos y trenes de vapor.',
    'TRA',
  ),
  _history(
    'civilizaciones',
    'Civilizaciones',
    'Las civilizaciones antiguas levantaron ciudades, calendarios y sistemas de escritura.',
    'CIV',
  ),
  _history(
    'descubrimientos',
    'Descubrimientos',
    'Inventos como el fuego, la rueda y la imprenta cambiaron la historia.',
    'DES',
  ),
  _history(
    'inventos',
    'Inventos',
    'El papel, la br\u00fajula y el \u00e1baco ayudaron a aprender, viajar y hacer cuentas.',
    'INV',
  ),
  _history(
    'ninos',
    'Ni\u00f1os de la antig\u00fcedad',
    'En otras \u00e9pocas, muchos ni\u00f1os ayudaban a sus familias y jugaban con objetos simples.',
    'NIN',
  ),
  _history(
    'maravillas',
    'Maravillas',
    'Obras como la Gran Muralla, Machu Picchu o Chich\u00e9n Itz\u00e1 siguen sorprendiendo al mundo.',
    'MAR',
  ),
];

final List<ExploreContentItem> defaultExploreItems = defaultExploreBuiltInItems
    .map((item) => item.toContentItem())
    .toList(growable: false);

final Map<String, ExploreBuiltInItem> _defaultExploreBuiltInById = {
  for (final item in defaultExploreBuiltInItems) item.id.trim().toLowerCase(): item,
};

final Set<String> _defaultExploreItemIds = defaultExploreItems
    .map((item) => item.id.trim().toLowerCase())
    .toSet();

ExploreCategoryDefinition? exploreCategoryDefinitionFor(String categoryId) {
  final normalized = categoryId.trim().toLowerCase();
  for (final category in exploreCategoryDefinitions) {
    if (category.id == normalized) return category;
  }
  return null;
}

String exploreCategoryLabelFor(String categoryId) {
  return exploreCategoryDefinitionFor(categoryId)?.label ?? 'Categor\u00eda';
}

ExploreBuiltInItem? defaultExploreBuiltInItemById(String itemId) {
  return _defaultExploreBuiltInById[itemId.trim().toLowerCase()];
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
