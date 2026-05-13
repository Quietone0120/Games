import 'dart:ui';
import 'package:flame/components.dart';
import '../../systems/inventory_system.dart';
import '../../utils/constants.dart';
import '../../utils/direction.dart';
import '../../utils/animation_loader.dart';
import 'base_enemy.dart';

class GreyWolf extends BaseEnemy {
  static Map<Direction, SpriteAnimation>? _runCache;
  static Map<Direction, SpriteAnimation>? _attackCache;

  static const String _path = 'HarSuld_designs/grey_wolf';
  static const double _meleeRange = 36.0;

  GreyWolf({
    required Vector2 spawnPos,
    required double hpMul,
    required double dmgMul,
  }) : super(
          hp: 38,
          maxHp: 38,
          armor: 0.0,
          damage: 9,
          attackInterval: 0.85,
          attackRange: _meleeRange,
          moveSpeed: 3.6 * 32,
          aggroRange: 6 * 32,
          structureDamageMultiplier: 0.8,
          enemyClass: EnemyClass.beast,
          spawnPos: spawnPos,
          hpMultiplier: hpMul,
          damageMultiplier: dmgMul,
          spriteSize: kWolfSpriteSize,
        );

  @override
  Future<void> loadAnimations() async {
    _runCache ??= await AnimationLoader.loadDirectionalAnimations(
      characterPath: _path,
      animationName: 'animation-14aae4b8',
      frameCount: 8,
      stepTime: 0.07,
    );
    _attackCache ??= await AnimationLoader.loadDirectionalAnimations(
      characterPath: _path,
      animationName: 'animation-814ef521',
      frameCount: 6,
      stepTime: 0.10,
    );
    runningAnims = _runCache!;
    attackAnims = _attackCache!;
    // Wolf has no dedicated death animation; use attack as fallback
    deathAnims = _attackCache!;
  }

  @override
  void update(double dt) {
    // Override primaryTarget to chase player if nearby
    if (playerTarget != null) {
      primaryTarget = playerTarget!;
    }
    super.update(dt);
  }

  @override
  Color get fallbackColor => const Color(0xFF888866);

  @override
  Map<ResourceType, int> get lootDrops {
    if (hpMultiplier >= 2.0) {
      return const {
        ResourceType.hide: 2,
        ResourceType.sinew: 2,
        ResourceType.blackWolfFang: 1,
      };
    }

    return const {
      ResourceType.hide: 1,
      ResourceType.sinew: 1,
    };
  }
}
