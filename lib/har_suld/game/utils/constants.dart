import 'package:flame/components.dart';

const double kTileSize = 32.0;
const int kMapSize = 256;
const int kMapCenter = 128;
const double kMapPixelSize = kMapSize * kTileSize; // 8192.0

final Vector2 kCenterPos = Vector2(kMapCenter * kTileSize, kMapCenter * kTileSize);

// Player stats
const double kPlayerBaseSpeed = 134.4; // 4.2 tiles/sec * 32
const double kHorseSpeed = 272.0; // 8.5 tiles/sec * 32
const double kPlayerBaseHp = 120.0;
const int kPlayerLives = 10;
const double kPlayerRespawnTime = 8.0;

// Har Suld
const double kHarSuldHp = 2000.0;
const double kHarSuldArmorReduction = 0.15;
const double kHarSuldAuraRadius = 16 * kTileSize; // 512px

// Aura buffs (for player inside aura)
const double kAuraPlayerHpBonus = 0.15;
const double kAuraPlayerDamageBonus = 0.10;
const double kAuraPlayerRangeBonus = 0.10;
const double kAuraPlayerRepairBonus = 0.10;
// Aura debuffs (for human/siege enemies inside aura)
const double kAuraEnemyDamageDebuff = 0.10;
const double kAuraEnemySpeedDebuff = 0.08;

// Bow tiers (index 0 = basic)
const List<Map<String, double>> kBowTiers = [
  {'damage': 14, 'interval': 0.90, 'range': 7},
  {'damage': 18, 'interval': 0.85, 'range': 7.5},
  {'damage': 24, 'interval': 0.80, 'range': 8, 'armorPierce': 0.05},
  {'damage': 31, 'interval': 0.72, 'range': 8.5, 'critChance': 0.10},
  {'damage': 40, 'interval': 0.65, 'range': 9, 'armorPierce': 0.10, 'critChance': 0.15},
];

// Armor tiers (index 0 = traveler)
const List<Map<String, double>> kArmorTiers = [
  {'reduction': 0.05, 'speedBonus': 0.0, 'hpBonus': 0},
  {'reduction': 0.10, 'speedBonus': 6.4, 'hpBonus': 10},  // 0.2 * 32
  {'reduction': 0.16, 'speedBonus': 12.8, 'hpBonus': 20},
  {'reduction': 0.24, 'speedBonus': 19.2, 'hpBonus': 35},
  {'reduction': 0.30, 'speedBonus': 25.6, 'hpBonus': 50},
  {'reduction': 0.36, 'speedBonus': 32.0, 'hpBonus': 70},
];

// Wave system
const double kBreakDuration = 180.0;
const double kWolfBreakTime1 = 30.0;   // grey pack
const double kWolfBreakTime2 = 90.0;   // mixed
const double kWolfBreakTime3 = 150.0;  // black wolf chance

// HP scaling
double waveHpMultiplier(int wave) {
  if (wave <= 10) return 1 + 0.12 * (wave - 1);
  return 2.08 + 0.10 * (wave - 10);
}

double waveDamageMultiplier(int wave) {
  if (wave <= 10) return 1 + 0.08 * (wave - 1);
  return 1.72 + 0.07 * (wave - 10);
}

double waveThreatBudget(int wave) {
  final base = wave ~/ 3;
  return 6 + 2.8 * wave + (base * base).toDouble();
}

// Enemy costs in threat budget
const Map<String, double> kEnemyThreatCost = {
  'raider': 1.0,
  'archer': 1.5,
  'veteran': 2.5,
  'wolf': 0.8,
  'black_wolf': 2.0,
  'ram': 4.0,
  'catapult': 6.0,
  'boss': 12.0,
};

// Repair
const double kRepairHpPerSec = 35.0;
const double kRepairMaterialPer80Hp = 1.0;
const double kRepairKitHp = 120.0;
const double kRepairKitCooldown = 8.0;

// Sprite / display
const double kPlayerSpriteSize = 48.0;
const double kEnemySpriteSize = 48.0;
const double kHorseSpriteSize = 64.0;
const double kWolfSpriteSize = 40.0;

// Combat damage class multipliers
const double kCounterClassMultiplier = 1.35;
const double kNeutralClassMultiplier = 1.00;
const double kNonIdealClassMultiplier = 0.90;
