import 'dart:ui';
import 'package:flame/components.dart';
import '../../systems/inventory_system.dart';
import '../../utils/direction.dart';
import '../../utils/animation_loader.dart';
import 'base_enemy.dart';

class BossEnemy extends BaseEnemy {
  static Map<Direction, SpriteAnimation>? _runCache;
  static Map<Direction, SpriteAnimation>? _idleCache;
  static Map<Direction, SpriteAnimation>? _punchCache;
  static Map<Direction, SpriteAnimation>? _deathCache;

  static const String _path = 'HarSuld_designs/enemies/boss';
  static const double _meleeRange = 56.0; // boss has larger reach

  int bossWaveNumber;
  static const double _baseBossHp = 950;
  static const double _baseBossDamage = 32;

  BossEnemy({
    required Vector2 spawnPos,
    required double hpMul,
    required double dmgMul,
    required this.bossWaveNumber,
  }) : super(
          hp: _baseBossHp,
          maxHp: _baseBossHp,
          armor: 0.18,
          damage: _baseBossDamage,
          attackInterval: 0.95,
          attackRange: _meleeRange,
          moveSpeed: 2.4 * 32,
          aggroRange: 7 * 32,
          structureDamageMultiplier: 1.5,
          enemyClass: EnemyClass.human,
          spawnPos: spawnPos,
          hpMultiplier: hpMul,
          damageMultiplier: dmgMul,
          spriteSize: 64,
        );

  @override
  Future<void> loadAnimations() async {
    _runCache ??= await AnimationLoader.loadDirectionalAnimations(
      characterPath: _path,
      animationName: 'Running',
      frameCount: 8,
      stepTime: 0.08,
    );
    _idleCache ??= await AnimationLoader.loadDirectionalAnimations(
      characterPath: _path,
      animationName: 'Fight_Stance_Idle',
      frameCount: 8,
      stepTime: 0.10,
    );
    _punchCache ??= await AnimationLoader.loadDirectionalAnimations(
      characterPath: _path,
      animationName: 'Cross_Punch',
      frameCount: 6,
      stepTime: 0.09,
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
    attackAnims = _punchCache!;
    deathAnims = _deathCache!;
  }

  @override
  Color get fallbackColor => const Color(0xFF6600AA);

  @override
  Map<ResourceType, int> get lootDrops => const {
        ResourceType.gold: 8,
        ResourceType.iron: 6,
        ResourceType.steel: 3,
      };
}
