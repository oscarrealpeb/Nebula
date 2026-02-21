import '../../models/planet_level.dart';

const List<PlanetLevel> planetLadder = [
  PlanetLevel(
    name: 'Tierra',
    minStars: 0,
    maxStars: 400,
    reward: 'Avatar explorador + animales base',
  ),
  PlanetLevel(
    name: 'Luna',
    minStars: 400,
    maxStars: 900,
    reward: 'Avatar lunar + objetos nuevos',
  ),
  PlanetLevel(
    name: 'Marte',
    minStars: 900,
    maxStars: 1600,
    reward: 'Avatar rover + animales del desierto',
  ),
  PlanetLevel(
    name: 'Jupiter',
    minStars: 1600,
    maxStars: 2500,
    reward: 'Avatar tormenta + objetos avanzados',
  ),
  PlanetLevel(
    name: 'Saturno',
    minStars: 2500,
    maxStars: 3600,
    reward: 'Avatar anillos + animales marinos',
  ),
  PlanetLevel(
    name: 'Neptuno',
    minStars: 3600,
    maxStars: 5000,
    reward: 'Avatar oceano + coleccion premium',
  ),
  PlanetLevel(
    name: 'Galaxia Azul',
    minStars: 5000,
    maxStars: 7000,
    reward: 'Avatar cosmico + expansion de objetos',
  ),
  PlanetLevel(
    name: 'Nebulosa Dorada',
    minStars: 7000,
    maxStars: 9500,
    reward: 'Avatar dorado + recompensas especiales',
  ),
  PlanetLevel(
    name: 'Universo Supremo',
    minStars: 9500,
    maxStars: 13000,
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
  final count = 3 + (index * 2);
  if (count < 3) return 3;
  if (count > 18) return 18;
  return count;
}
