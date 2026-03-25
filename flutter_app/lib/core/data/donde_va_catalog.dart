import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/game_content_config.dart';

class DondeVaItem {
  const DondeVaItem({
    required this.id,
    required this.label,
    required this.emoji,
    this.assetExtension = 'png',
    this.imageSource = '',
  });

  final String id;
  final String label;
  final String emoji;
  final String assetExtension;
  final String imageSource;
}

class DondeVaCategory {
  const DondeVaCategory({
    required this.id,
    required this.label,
    required this.emoji,
    required this.emojis,
    required this.color,
    required this.items,
  });

  final String id;
  final String label;
  final String emoji;
  final List<String> emojis;
  final Color color;
  final List<DondeVaItem> items;
}

class DondeVaRound {
  const DondeVaRound({
    required this.item,
    required this.correctCategory,
  });

  final DondeVaItem item;
  final DondeVaCategory correctCategory;
}

class DondeVaGameConfig {
  const DondeVaGameConfig({
    required this.visibleCategoryCount,
    required this.roundCount,
  });

  final int visibleCategoryCount;
  final int roundCount;
}

class DondeVaGameSession {
  const DondeVaGameSession({
    required this.visibleCategories,
    required this.rounds,
  });

  final List<DondeVaCategory> visibleCategories;
  final List<DondeVaRound> rounds;
}

String dondeVaItemAssetPath({
  required String categoryId,
  required String itemId,
  String extension = 'png',
}) {
  return 'assets/images/donde_va/$categoryId/$itemId.$extension';
}

String dondeVaGlobalItemId({
  required String categoryId,
  required String itemId,
}) {
  final normalizedCategory = categoryId.trim().toLowerCase();
  final normalizedItem = itemId.trim().toLowerCase();
  return '$normalizedCategory::$normalizedItem';
}

const List<DondeVaCategory> dondeVaCategories = <DondeVaCategory>[
  DondeVaCategory(
    id: 'cocina',
    label: 'Cocina',
    emoji: '🍔',
    emojis: <String>['🍔', '🍗', '👨‍🍳'],
    color: Color(0xFFFFD39A),
    items: <DondeVaItem>[
      DondeVaItem(id: 'olla', label: 'Olla', emoji: '🍲'),
      DondeVaItem(id: 'sarten', label: 'Sarten', emoji: '🍳'),
      DondeVaItem(id: 'licuadora', label: 'Licuadora', emoji: '🥤'),
      DondeVaItem(id: 'espatula', label: 'Espatula', emoji: '🥄'),
      DondeVaItem(id: 'cucharon', label: 'Cucharon', emoji: '🥣'),
      DondeVaItem(
        id: 'tabla_de_cortar',
        label: 'Tabla de cortar',
        emoji: '🪵',
      ),
      DondeVaItem(id: 'tetera', label: 'Tetera', emoji: '🫖'),
      DondeVaItem(id: 'colador', label: 'Colador', emoji: '🍜'),
    ],
  ),
  DondeVaCategory(
    id: 'dormitorio',
    label: 'Dormitorio',
    emoji: '🛏️',
    emojis: <String>['🛏️', '🧸', '🌙'],
    color: Color(0xFFCFE2FF),
    items: <DondeVaItem>[
      DondeVaItem(id: 'cama', label: 'Cama', emoji: '🛏️'),
      DondeVaItem(id: 'almohada', label: 'Almohada', emoji: '🛌'),
      DondeVaItem(id: 'cobija', label: 'Cobija', emoji: '🧣'),
      DondeVaItem(
        id: 'nochero',
        label: 'Nochero',
        emoji: '🪑',
        assetExtension: 'jpeg',
      ),
      DondeVaItem(
        id: 'lampara_de_noche',
        label: 'Lámpara de noche',
        emoji: '💡',
      ),
      DondeVaItem(id: 'armario', label: 'Armario', emoji: '🚪'),
      DondeVaItem(id: 'perchero', label: 'Perchero', emoji: '🧥'),
      DondeVaItem(
        id: 'espejo_de_cuarto',
        label: 'Espejo',
        emoji: '🪞',
      ),
    ],
  ),
  DondeVaCategory(
    id: 'escuela',
    label: 'Escuela',
    emoji: '🎒',
    emojis: <String>['🎒', '📓', '✏️'],
    color: Color(0xFFFFE9A8),
    items: <DondeVaItem>[
      DondeVaItem(id: 'cuaderno', label: 'Cuaderno', emoji: '📓'),
      DondeVaItem(id: 'lapiz', label: 'Lápiz', emoji: '✏️'),
      DondeVaItem(id: 'borrador', label: 'Borrador', emoji: '🩹'),
      DondeVaItem(id: 'regla', label: 'Regla', emoji: '📏'),
      DondeVaItem(id: 'mochila', label: 'Mochila', emoji: '🎒'),
      DondeVaItem(id: 'pupitre', label: 'Pupitre', emoji: '🪑'),
      DondeVaItem(id: 'tablero', label: 'Tablero', emoji: '🟩'),
      DondeVaItem(id: 'crayones', label: 'Crayones', emoji: '🖍️'),
      DondeVaItem(
        id: 'tijeras_escolares',
        label: 'Tijeras escolares',
        emoji: '✂️',
      ),
      DondeVaItem(
        id: 'pegante_escolar',
        label: 'Pegante escolar',
        emoji: '🧴',
      ),
    ],
  ),
  DondeVaCategory(
    id: 'centro_comercial',
    label: 'Centro comercial',
    emoji: '🛍️',
    emojis: <String>['🛍️', '🛒', '🏬'],
    color: Color(0xFFFFD6EB),
    items: <DondeVaItem>[
      DondeVaItem(id: 'vitrina', label: 'Vitrina', emoji: '🪟'),
      DondeVaItem(id: 'maniqui', label: 'Maniquí', emoji: '🧍'),
      DondeVaItem(
        id: 'bolsa_de_compras',
        label: 'Bolsa de compras',
        emoji: '🛍️',
      ),
      DondeVaItem(
        id: 'escalera_electrica',
        label: 'Escalera eléctrica',
        emoji: '🛗',
      ),
      DondeVaItem(
        id: 'carrito_de_compras',
        label: 'Carrito de compras',
        emoji: '🛒',
      ),
      DondeVaItem(
        id: 'caja_registradora',
        label: 'Caja registradora',
        emoji: '💵',
      ),
      DondeVaItem(id: 'mostrador', label: 'Mostrador', emoji: '🧾'),
      DondeVaItem(
        id: 'letrero_de_ofertas',
        label: 'Letrero de ofertas',
        emoji: '🏷️',
      ),
      DondeVaItem(id: 'ascensor', label: 'Ascensor', emoji: '🛗'),
      DondeVaItem(
        id: 'canasta',
        label: 'Canasta',
        emoji: '🧺',
        assetExtension: 'jpg',
      ),
    ],
  ),
  DondeVaCategory(
    id: 'granja',
    label: 'Granja',
    emoji: '🚜',
    emojis: <String>['🚜', '🐄', '🐔'],
    color: Color(0xFFD8F2C2),
    items: <DondeVaItem>[
      DondeVaItem(id: 'vaca', label: 'Vaca', emoji: '🐄'),
      DondeVaItem(id: 'gallina', label: 'Gallina', emoji: '🐔'),
      DondeVaItem(id: 'cerdo', label: 'Cerdo', emoji: '🐖'),
      DondeVaItem(id: 'tractor', label: 'Tractor', emoji: '🚜'),
      DondeVaItem(
        id: 'paca_de_heno',
        label: 'Paca de heno',
        emoji: '🌾',
      ),
      DondeVaItem(id: 'establo', label: 'Establo', emoji: '🐴'),
      DondeVaItem(id: 'caballo', label: 'Caballo', emoji: '🐎'),
      DondeVaItem(id: 'oveja', label: 'Oveja', emoji: '🐑'),
      DondeVaItem(id: 'granero', label: 'Granero', emoji: '🏚️'),
      DondeVaItem(id: 'molino', label: 'Molino', emoji: '🌬️'),
    ],
  ),
];

DondeVaGameConfig dondeVaConfigForDifficulty(int difficultyStars) {
  switch (difficultyStars.clamp(1, 3)) {
    case 1:
      return const DondeVaGameConfig(visibleCategoryCount: 2, roundCount: 6);
    case 2:
      return const DondeVaGameConfig(visibleCategoryCount: 3, roundCount: 8);
    default:
      return const DondeVaGameConfig(visibleCategoryCount: 4, roundCount: 10);
  }
}

DondeVaGameSession buildDondeVaGameSession(int difficultyStars, Random random) {
  return buildDondeVaGameSessionWithItems(
    difficultyStars,
    random,
    const <DondeVaContentItem>[],
  );
}

List<DondeVaCategory> mergeDondeVaCategories(
  Iterable<DondeVaContentItem> configuredItems,
) {
  final merged = <DondeVaCategory>[
    for (final category in dondeVaCategories)
      DondeVaCategory(
        id: category.id,
        label: category.label,
        emoji: category.emoji,
        emojis: List<String>.from(category.emojis),
        color: category.color,
        items: List<DondeVaItem>.from(category.items),
      ),
  ];

  for (final item in configuredItems) {
    if (!item.enabled) continue;
    final categoryIndex = merged.indexWhere(
      (category) =>
          category.id.trim().toLowerCase() ==
          item.categoryId.trim().toLowerCase(),
    );
    if (categoryIndex < 0) continue;
    final category = merged[categoryIndex];
    final normalizedItemId = item.id.trim().toLowerCase();
    final nextItems = <DondeVaItem>[
      for (final current in category.items)
        if (current.id.trim().toLowerCase() != normalizedItemId) current,
      DondeVaItem(
        id: item.id.trim(),
        label: item.label.trim(),
        emoji: '📦',
        imageSource: item.imageSource.trim(),
      ),
    ];
    merged[categoryIndex] = DondeVaCategory(
      id: category.id,
      label: category.label,
      emoji: category.emoji,
      emojis: List<String>.from(category.emojis),
      color: category.color,
      items: nextItems,
    );
  }

  return merged;
}

DondeVaGameSession buildDondeVaGameSessionWithItems(
  int difficultyStars,
  Random random,
  Iterable<DondeVaContentItem> configuredItems,
) {
  final config = dondeVaConfigForDifficulty(difficultyStars);
  final visibleCategories = List<DondeVaCategory>.from(
    mergeDondeVaCategories(configuredItems),
  )..shuffle(random);
  final selectedCategories =
      visibleCategories.take(config.visibleCategoryCount).toList();

  final guaranteedRounds = <DondeVaRound>[];
  final remainingPool = <DondeVaRound>[];

  for (final category in selectedCategories) {
    final items = List<DondeVaItem>.from(category.items)..shuffle(random);
    if (items.isEmpty) continue;
    guaranteedRounds.add(
      DondeVaRound(item: items.first, correctCategory: category),
    );
    remainingPool.addAll(
      items.skip(1).map(
            (item) => DondeVaRound(
              item: item,
              correctCategory: category,
            ),
          ),
    );
  }

  remainingPool.shuffle(random);
  final roundCount = config.roundCount.clamp(
    selectedCategories.length,
    100,
  );
  final selectedRounds = <DondeVaRound>[
    ...guaranteedRounds,
    ...remainingPool.take(roundCount - guaranteedRounds.length),
  ]..shuffle(random);

  return DondeVaGameSession(
    visibleCategories: selectedCategories,
    rounds: selectedRounds,
  );
}
