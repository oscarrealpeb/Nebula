class PlanetLevel {
  const PlanetLevel({
    required this.name,
    required this.minStars,
    required this.maxStars,
    required this.reward,
  });

  final String name;
  final int minStars;
  final int maxStars;
  final String reward;
}
