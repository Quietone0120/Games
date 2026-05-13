import 'dart:ui';
import 'package:flame/components.dart';
import '../../systems/inventory_system.dart';
import '../../utils/direction.dart';
import '../../utils/animation_loader.dart';
import 'base_enemy.dart';

class ArcherEnemy extends BaseEnemy {
  static Map<Direction, SpriteAnimation>? _runCache;
  static Map<Direction, SpriteAnimation>? _shootCache;
  static Map<Direction, SpriteAnimation>? _deathCache;

  static const String _path = 'HarSuld_designs/enemies/archer';

  // Callback to spawn arrow projectile
  void Function(Vector2 from, Vector2 to, double damage)? onShoot;

  ArcherEnemy({
    required Vector2 spawnPos,
    required double hpMul,
    required double dmgMul,
    this.onShoot,
  }) : super(
          hp: 45,
          maxHp: 45,
          armor: 0.0,
          damage: 8,
          attackInterval: 1.25,
          attackRange: 6 * 32,
          moveSpeed: 2.3 * 32,
          aggroRange: 7 * 32,
          structureDamageMultiplier: 0.8,
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
    _shootCache ??= await AnimationLoader.loadDirectionalAnimations(
      characterPath: _path,
      animationName: 'shooting',
      frameCount: 4,
      stepTime: 0.10,
    );
    _deathCache ??= await AnimationLoader.loadDirectionalAnimations(
      characterPath: _path,
      animationName: 'Falling_Back_Death',
      frameCount: 7,
      stepTime: 0.10,
      loop: false,
    );
    runningAnims = _runCache!;
    attackAnims = _shootCache!;
    deathAnims = _deathCache!;
  }

  @override
  void onAttack() {
    onShoot?.call(position.clone(), activeTarget.clone(), damage);
  }

  @override
  Color get fallbackColor => const Color(0xFFAA6622);

  @override
  Map<ResourceType, int> get lootDrops => const {
        ResourceType.wood: 1,
        ResourceType.iron: 1,
      };
}
