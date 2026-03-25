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
    '\xbfSab\xedas que los perros tienen un olfato mucho m\xe1s fuerte que los humanos? Gracias a esto pueden encontrar personas o cosas escondidas.',
  ),
  _animal(
    'gato',
    'Gato',
    '\xbfSab\xedas que los gatos duermen la mayor parte del d\xeda? Ellos descansan mucho para tener energ\xeda cuando est\xe1n activos.',
  ),
  _animal(
    'conejo',
    'Conejo',
    '\xbfSab\xedas que los conejos tienen orejas muy largas y sensibles? Las usan para escuchar peligros desde lejos.',
  ),
  _animal(
    'vaca',
    'Vaca',
    '\xbfSab\xedas que las vacas producen la leche que muchas personas beben? Esa leche tambi\xe9n se usa para hacer queso y yogur.',
  ),
  _animal(
    'caballo',
    'Caballo',
    '\xbfSab\xedas que los caballos pueden correr muy r\xe1pido en distancias largas? Por eso han sido usados en carreras y viajes durante muchos a\xf1os.',
  ),
  _animal(
    'elefante',
    'Elefante',
    '\xbfSab\xedas que los elefantes son los animales terrestres m\xe1s grandes del mundo? Su enorme cuerpo los hace muy fuertes.',
  ),
  _animal(
    'leon',
    'Le\u00f3n',
    '\xbfSab\xedas que el le\xf3n es conocido como el rey de la selva? Es un animal fuerte y respetado por otros animales.',
  ),
  _animal(
    'tigre',
    'Tigre',
    '\xbfSab\xedas que cada tigre tiene un patr\xf3n de rayas \xfanico? Es como su huella digital.',
  ),
  _animal(
    'jirafa',
    'Jirafa',
    '\xbfSab\xedas que la jirafa es el animal m\xe1s alto del mundo? Su largo cuello le ayuda a alcanzar hojas en \xe1rboles altos.',
  ),
  _animal(
    'mono',
    'Mono',
    '\xbfSab\xedas que los monos viven en los \xe1rboles? All\xed se sienten seguros y pueden moverse con facilidad.',
  ),
  _animal(
    'oso',
    'Oso',
    '\xbfSab\xedas que algunos osos hibernan durante el invierno? Duermen por mucho tiempo para ahorrar energ\xeda.',
  ),
  _animal(
    'delfin',
    'Delf\u00edn',
    '\xbfSab\xedas que los delfines son animales muy inteligentes? Pueden aprender trucos y comunicarse entre ellos.',
  ),
  _animal(
    'tucan',
    'Tuc\u00e1n',
    '\xbfSab\xedas que el tuc\xe1n tiene un pico grande y muy colorido? Su pico es ligero y no pesa tanto como parece.',
  ),
  _animal(
    'pinguino',
    'Ping\u00fcino',
    '\xbfSab\xedas que los ping\xfcinos no pueden volar? Sus alas est\xe1n adaptadas para nadar.',
  ),
  _animal(
    'tortuga',
    'Tortuga',
    '\xbfSab\xedas que las tortugas tienen un caparaz\xf3n duro que las protege? Es como una armadura natural.',
  ),
  _art(
    'mona_lisa',
    'La Mona Lisa',
    'La Mona Lisa fue pintada por Leonardo da Vinci hace m\xe1s de 500 a\xf1os. Es una de las obras m\xe1s famosas de toda la historia.',
  ),
  _art(
    'noche_estrellada',
    'La noche estrellada',
    'Esta pintura fue creada por Vincent van Gogh mientras estaba en un hospital. Desde all\xed observaba el cielo por la ventana.',
  ),
  _art(
    'girasoles',
    'Los girasoles',
    'Vincent van Gogh pint\xf3 varias versiones de los girasoles. Todas tienen colores muy intensos.',
  ),
  _art(
    'el_grito',
    'El grito',
    'Esta pintura fue creada por el artista Edvard Munch. Es muy famosa por su expresi\xf3n intensa.',
  ),
  _art(
    'joven_perla',
    'La joven de la perla',
    'Esta pintura fue hecha por Johannes Vermeer. Es muy admirada por su belleza y detalle.',
  ),
  _art(
    'da_vinci',
    'Leonardo da Vinci',
    'Leonardo da Vinci pint\xf3 la famosa Mona Lisa. Fue uno de los artistas m\xe1s importantes del Renacimiento.',
  ),
  _art(
    'van_gogh',
    'Vincent van Gogh',
    'Van Gogh pint\xf3 m\xe1s de 800 cuadros en su vida. Su estilo es muy f\xe1cil de reconocer.',
  ),
  _art(
    'picasso',
    'Pablo Picasso',
    'Pablo Picasso fue un artista espa\xf1ol muy famoso. Comenz\xf3 a dibujar desde ni\xf1o.',
  ),
  _art(
    'frida_kahlo',
    'Frida Kahlo',
    'Frida Kahlo fue una artista mexicana muy reconocida. Sus obras son muy personales.',
  ),
  _art(
    'dali',
    'Salvador Dal\u00ed',
    'Salvador Dal\xed fue un artista espa\xf1ol muy creativo. Ten\xeda una imaginaci\xf3n muy grande.',
  ),
  _history(
    'dinosaurios',
    'Dinosaurios',
    '\xbfSab\xedas que algunos dinosaurios no ten\xedan piel como los reptiles, sino plumas suaves como las de un p\xe1jaro? Imagina un dinosaurio grande caminando\u2026 \xa1pero cubierto de plumas!',
    'DIN',
  ),
  _history(
    'ciudades',
    'Ciudades antiguas',
    '\xbfSab\xedas que las primeras ciudades no ten\xedan edificios altos, sino casas hechas de barro y paja? Imagina caminar por calles de tierra rodeado de casitas simples.',
    'CIU',
  ),
  _history(
    'piratas',
    'Piratas',
    '\xbfSab\xedas que los piratas escond\xedan tesoros en islas lejanas y misteriosas? Imagina un cofre enterrado bajo la arena esperando ser encontrado.',
    'PIR',
  ),
  _history(
    'egipcios',
    'Egipcios',
    '\xbfSab\xedas que las pir\xe1mides son construcciones gigantes hechas hace miles de a\xf1os? Imagina bloques enormes apilados uno sobre otro hasta tocar el cielo.',
    'EGI',
  ),
  _history(
    'castillos',
    'Castillos',
    '\xbfSab\xedas que los castillos ten\xedan muros enormes y torres alt\xedsimas? Parec\xedan gigantes de piedra vigilando todo.',
    'CAS',
  ),
  _history(
    'vikingos',
    'Vikingos',
    '\xbfSab\xedas que los vikingos viajaban en barcos largos con cabezas de drag\xf3n? Parec\xedan criaturas del mar.',
    'VIK',
  ),
  _history(
    'romanos',
    'Romanos',
    '\xbfSab\xedas que los romanos construyeron caminos tan fuertes que algunos todav\xeda existen? Parecen hechos para durar para siempre.',
    'ROM',
  ),
  _history(
    'exploradores',
    'Exploradores',
    '\xbfSab\xedas que algunos exploradores viajaban por meses sin saber a d\xf3nde llegar\xedan? Era como una aventura sin mapa claro.',
    'EXP',
  ),
  _history(
    'reyes',
    'Reyes',
    '\xbfSab\xedas que los reyes viv\xedan en palacios enormes con muchas habitaciones? Algunos parec\xedan laberintos.',
    'REY',
  ),
  _history(
    'transportes',
    'Transportes antiguos',
    '\xbfSab\xedas que los primeros trenes funcionaban con vapor y echaban humo? Parec\xedan dragones de hierro.',
    'TRA',
  ),
  _history(
    'civilizaciones',
    'Civilizaciones',
    '\xbfSab\xedas que algunas civilizaciones construyeron enormes ciudades sin m\xe1quinas? Solo con esfuerzo humano.',
    'CIV',
  ),
  _history(
    'descubrimientos',
    'Descubrimientos',
    '\xbfSab\xedas que el fuego ayud\xf3 a los humanos a cocinar y calentarse? Cambi\xf3 todo.',
    'DES',
  ),
  _history(
    'inventos',
    'Inventos',
    '\xbfSab\xedas que el papel se invent\xf3 para escribir y guardar ideas? Antes se usaban piedras o pieles.',
    'INV',
  ),
  _history(
    'ninos',
    'Ni\u00f1os de la antig\u00fcedad',
    '\xbfSab\xedas que muchos ni\xf1os ayudaban a sus familias desde peque\xf1os? Trabajaban como los adultos.',
    'NIN',
  ),
  _history(
    'maravillas',
    'Maravillas',
    '\xbfSab\xedas que la Gran Muralla China es tan larga que atraviesa monta\xf1as y desiertos? Fue construida para proteger a un imperio entero.',
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
