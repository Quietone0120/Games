import 'package:flame/components.dart';
import '../../systems/inventory_system.dart';
import '../../utils/direction.dart';
import '../../utils/animation_loader.dart';
import 'base_enemy.dart';

class Raider extends BaseEnemy {
  static Map<Direction, SpriteAnimation>? _runCache;
  static Map<Direction, SpriteAnimation>? _attackCache;
  static Map<Direction, SpriteAnimation>? _deathCache;

  static const String _path = 'HarSuld_designs/enemies/raider';

  Raider({
    required Vector2 spawnPos,
    required double hpMul,
    required double dmgMul,
  }) : super(
          hp: 55,
          maxHp: 55,
          armor: 0.0,
          damage: 10,
          attackInterval: 1.0,
          attackRange: kRaiderMeleeRange,
          moveSpeed: 2.6 * 32,
          aggroRange: 5 * 32,
          structureDamageMultiplier: 1.0,
          enemyClass: EnemyClass.human,
          spawnPos: spawnPos,
          hpMultiplier: hpMul,
          damageMultiplier: dmgMul,
        );

  @override
  Future<void> loadAnimations() async {
    _runCache ??= await AnimationLoader.loadDirectionalAnimations(
      characterPath: _path,
      animationName: 'Running',
      frameCount: 8,
      stepTime: 0.08,
    );
    _attackCache ??= await AnimationLoader.loadDirectionalAnimations(
      characterPath: _path,
      animationName: 'Lead_Jab',
      frameCount: 3,
      stepTime: 0.10,
      loop: false,
    );
    _deathCache ??= await AnimationLoader.loadDirectionalAnimations(
      characterPath: _path,
      animationName: 'Falling_Back_Death',
      frameCount: 7,
      stepTime: 0.10,
      loop: false,
    );
    runningAnims = _runCache!;
    attackAnims = _attackCache!;
    deathAnims = _deathCache!;
  }

  @override
  Map<ResourceType, int> get lootDrops => const {
        ResourceType.wood: 2,
        ResourceType.stone: 1,
      };
}

const double kRaiderMeleeRange = 38.0; // ~1.2 tiles
