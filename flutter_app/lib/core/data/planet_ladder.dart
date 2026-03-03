import '../../models/planet_level.dart';
import 'avatar_catalog.dart';


const List<PlanetLevel> planetLadder = [
  PlanetLevel(
    name: 'Mercurio',
    minStars: 0,
    maxStars: 300,
    reward: 'Avatar explorador + animales base',
  ),
  PlanetLevel(
    name: 'Venus',
    minStars: 300,
    maxStars: 700,
    reward: 'Avatar lunar + objetos nuevos',
  ),
  PlanetLevel(
    name: 'Tierra',
    minStars: 700,
    maxStars: 1200,
    reward: 'Avatar rover + animales del desierto',
  ),
  PlanetLevel(
    name: 'Marte',
    minStars: 1200,
    maxStars: 1800,
    reward: 'Avatar tormenta + objetos avanzados',
  ),
  PlanetLevel(
    name: 'Jupiter',
    minStars: 1800,
    maxStars: 2500,
    reward: 'Avatar anillos + animales marinos',
  ),
  PlanetLevel(
    name: 'Saturno',
    minStars: 2500,
    maxStars: 3300,
    reward: 'Avatar oceano + coleccion premium',
  ),
  PlanetLevel(
    name: 'Urano',
    minStars: 3300,
    maxStars: 4200,
    reward: 'Avatar cosmico + expansion de objetos',
  ),
  PlanetLevel(
    name: 'Neptuno',
    minStars: 4200,
    maxStars: 5200,
    reward: 'Avatar dorado + recompensas especiales',
  ),
  PlanetLevel(
    name: 'Nebulosa Dorada',
    minStars: 5200,
    maxStars: 6300,
    reward: 'Avatar legendario + todo desbloqueado',
  ),
  PlanetLevel(
    name: 'Galaxia Prisma',
    minStars: 6300,
    maxStars: 7500,
    reward: 'Avatar legendario + todo desbloqueado',
  ),
  // PlanetLevel(
  //   name: 'Constelación Zen',
  //   minStars: 7500,
  //   maxStars: 8800,
  //   reward: 'Avatar legendario + todo desbloqueado',
  // ),
  PlanetLevel(
    name: 'Universo Infinito',
    minStars: 8800,
    maxStars: 10000,
    reward: 'Avatar legendario + todo desbloqueado',
  ),
];

PlanetLevel planetForStars(int stars) {
  for (final planet in planetLadder) {
    if (stars >= planet.minStars && stars < planet.maxStars) {
      return planet;
    }
  }
  return planetLadder.last;
}

double planetProgress(int stars) {
  final planet = planetForStars(stars);
  final total = planet.maxStars - planet.minStars;
  if (total <= 0) return 1;
  final value = (stars - planet.minStars) / total;
  return value.clamp(0.0, 1.0).toDouble();
}

int starsToNextPlanet(int stars) {
  final planet = planetForStars(stars);
  if (planet == planetLadder.last) return 0;
  final remaining = planet.maxStars - stars;
  return remaining <= 0 ? 0 : remaining;
}

int unlockedAvatarCount(int stars) {
  final currentPlanet = planetForStars(stars);
  final index = planetLadder.indexOf(currentPlanet);

  int count = 3; // empieza con 3

  if (index <= 6) {
    // Mercurio hasta Urano -> +1 por nivel
    count += (index + 1);
  } else {
    // Primero sumamos los 7 niveles que daban 1 cada uno
    count += 7;

    // Desde Neptuno en adelante -> +2 por nivel
    final extraLevels = index - 6;
    count += extraLevels * 2;
  }

  if (count > 18) return 18;
  return count;
}


List<String> avatarsUnlockedAtLevel(int levelIndex) {
  if (levelIndex < 0) return [];

  int previousCount;
  int currentCount;

  if (levelIndex == 0) {
    previousCount = 3;
  } else {
    previousCount = unlockedAvatarCount(
      planetLadder[levelIndex - 1].minStars,
    );
  }

  currentCount = unlockedAvatarCount(
    planetLadder[levelIndex].minStars,
  );

  return avatarCatalog.sublist(
    previousCount,
    currentCount > avatarCatalog.length
        ? avatarCatalog.length
        : currentCount,
  );
}