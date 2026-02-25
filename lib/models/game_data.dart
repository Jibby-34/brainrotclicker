import 'dart:ui';

class CharacterBuilding {
  final String id;
  final String name;
  final String assetPath;
  final double baseCost;
  final double cpsPerUnit;
  final Color color;

  const CharacterBuilding({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.baseCost,
    required this.cpsPerUnit,
    required this.color,
  });

  double costForNext(int owned) {
    return (baseCost * _pow(1.15, owned)).ceilToDouble();
  }

  static double _pow(double base, int exp) {
    double result = 1.0;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }
}

class ClickUpgrade {
  final String id;
  final String name;
  final String description;
  final double cost;
  final double multiplier;

  const ClickUpgrade({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.multiplier,
  });
}

// ── Static game data ──────────────────────────────────────────────────────────
// Add more CharacterBuildings here to expand the roster.

const List<CharacterBuilding> kCharacters = [
  CharacterBuilding(
    id: 'tungtungsahur',
    name: 'Tung Tung Sahur',
    assetPath: 'assets/images/tungtungsahur.png',
    baseCost: 10,
    cpsPerUnit: 0.5,
    color: Color(0xFFFF6B6B),
  ),
  CharacterBuilding(
    id: 'brrbrrpatapim',
    name: 'Brr Brr Patapim',
    assetPath: 'assets/images/brrbrrpatapim.png',
    baseCost: 100,
    cpsPerUnit: 5,
    color: Color(0xFF4ECDC4),
  ),
  CharacterBuilding(
    id: 'tralalelotralala',
    name: 'Tralalelo Tralala',
    assetPath: 'assets/images/tralalelotralala.png',
    baseCost: 1100,
    cpsPerUnit: 40,
    color: Color(0xFFFFE66D),
  ),
];

const List<ClickUpgrade> kClickUpgrades = [
  ClickUpgrade(
    id: 'bigger_brain',
    name: 'Bigger Brain',
    description: 'Double your clicks per tap',
    cost: 50,
    multiplier: 2,
  ),
  ClickUpgrade(
    id: 'brainrot_mode',
    name: 'Brainrot Mode',
    description: 'Double your clicks per tap',
    cost: 500,
    multiplier: 2,
  ),
  ClickUpgrade(
    id: 'ultra_brainrot',
    name: 'Ultra Brainrot',
    description: 'Double your clicks per tap',
    cost: 5000,
    multiplier: 2,
  ),
  ClickUpgrade(
    id: 'maximum_overdrive',
    name: 'Maximum Overdrive',
    description: 'Triple your clicks per tap',
    cost: 50000,
    multiplier: 3,
  ),
];
