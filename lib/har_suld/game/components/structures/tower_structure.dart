import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import '../../systems/inventory_system.dart';
import '../../utils/constants.dart';
import '../enemies/base_enemy.dart';
import '../projectile.dart';

enum TowerTier { wooden, cobble, iron, steel, sacred }

class TowerStructure extends PositionComponent {
  static const List<double> _maxHp = [180, 300, 450, 650, 850];
  static const List<double> _damage = [10, 14, 20, 27, 35];
  static const List<double> _interval = [1.20, 1.10, 1.00, 0.90, 0.82];
  static const List<double> _range = [5.5, 6.0, 6.5, 7.0, 7.5];
  final TowerTier tier;
  final CraftedTowerType towerType;
  final int tileX;
  final int tileY;
  final VoidCallback? onDestroyed;

  double hp;
  double maxHp;
  double damage;
  double attackInterval;
  double range;
  double _attackCooldown = 0;

  List<BaseEnemy> Function()? getEnemies;
  void Function(EnemyProjectile)? onProjectileSpawned;
  Sprite? _sprite;

  TowerStructure({
    required this.tier,
    required this.tileX,
    required this.tileY,
    this.towerType = CraftedTowerType.human,
    this.getEnemies,
    this.onProjectileSpawned,
    this.onDestroyed,
  })  : hp = _maxHp[tier.index],
        maxHp = _maxHp[tier.index],
        damage = _damage[tier.index],
        attackInterval = _interval[tier.index],
        range = rangeTilesForTier(tier) * kTileSize,
        super(
          position: Vector2(tileX * kTileSize, tileY * kTileSize),
          size: Vector2.all(kTileSize * 3),
        );

  bool get isAlive => hp > 0;
  BuildType get buildType => TowerStructure.buildTypeForTier(tier);
  Vector2 get centerPoint => position + size / 2;

  static double rangeTilesForTier(TowerTier tier) => _range[tier.index];

  static double rangeTilesForBuildType(BuildType buildType) {
    return rangeTilesForTier(
        TowerTier.values[buildType.index - BuildType.woodenTower.index]);
  }

  @override
  Future<void> onLoad() async {
    try {
      final img = await Flame.images.load(
        buildType.previewAssetPath(towerType: towerType),
      );
      _sprite = Sprite(img);
    } catch (_) {
      // Fallback to primitive rendering below.
    }
  }

  void takeDamage(double rawDamage) {
    hp -= rawDamage;
    if (hp <= 0) {
      hp = 0;
      onDestroyed?.call();
      removeFromParent();
    }
  }

  void repair(double amount) {
    hp = (hp + amount).clamp(0, maxHp);
  }

  double _getDamageVsEnemy(BaseEnemy enemy) {
    final match = _specializationMatchesClass(towerType, enemy.enemyClass);
    final multiplier = match == 1
        ? kCounterClassMultiplier
        : match == -1
            ? kNonIdealClassMultiplier
            : kNeutralClassMultiplier;
    return damage * multiplier;
  }

  int _specializationMatchesClass(CraftedTowerType spec, EnemyClass cls) {
    if (spec == CraftedTowerType.human && cls == EnemyClass.human) return 1;
    if (spec == CraftedTowerType.beast && cls == EnemyClass.beast) return 1;
    if (spec == CraftedTowerType.siege && cls == EnemyClass.siege) return 1;
    return 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hp <= 0) return;

    _attackCooldown -= dt;
    if (_attackCooldown > 0) return;

    final enemies = getEnemies?.call() ?? [];
    BaseEnemy? target;
    double nearestDist = range;

    for (final e in enemies) {
      if (e.isDead) continue;
      if (e.enemyClass == EnemyClass.siege) {
        final dist = (e.position - centerPoint).length;
        if (dist < range) {
          target = e;
          break;
        }
      }
    }

    if (target == null) {
      for (final e in enemies) {
        if (e.isDead) continue;
        final dist = (e.position - centerPoint).length;
        if (dist < nearestDist) {
          nearestDist = dist;
          target = e;
        }
      }
    }

    if (target != null) {
      final dmg = _getDamageVsEnemy(target);
      target.takeDamage(dmg);
      _attackCooldown = attackInterval;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_sprite != null) {
      _sprite!.render(canvas, size: size);
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0xFF885533),
      );
    }
    if (hp < maxHp) {
      canvas.drawRect(
        Rect.fromLTWH(0, -6, size.x, 4),
        Paint()..color = const Color(0xFF330000),
      );
      canvas.drawRect(
        Rect.fromLTWH(0, -6, size.x * (hp / maxHp), 4),
        Paint()..color = const Color(0xFF44FF44),
      );
    }
  }

  static BuildType buildTypeForTier(TowerTier tier) {
    switch (tier) {
      case TowerTier.wooden:
        return BuildType.woodenTower;
      case TowerTier.cobble:
        return BuildType.cobbleTower;
      case TowerTier.iron:
        return BuildType.ironTower;
      case TowerTier.steel:
        return BuildType.steelTower;
      case TowerTier.sacred:
        return BuildType.sacredTower;
    }
  }
}
