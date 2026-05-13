import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../../systems/inventory_system.dart';
import '../../utils/constants.dart';
import '../../utils/direction.dart';

enum EnemyState { running, attacking, dying, dead }

enum EnemyClass { human, beast, siege }

abstract class BaseEnemy extends PositionComponent {
  // Stats
  double hp;
  double maxHp;
  double armor;
  double damage;
  double attackInterval;
  double attackRange;
  double moveSpeed;
  double aggroRange;
  double structureDamageMultiplier;
  EnemyClass enemyClass;

  // Wave scaling
  double hpMultiplier;
  double damageMultiplier;

  // State
  EnemyState state = EnemyState.running;
  Direction direction = Direction.south;

  // Timers
  double _attackCooldown = 0;
  double _deathTimer = 0;
  static const double _deathDuration = 1.0;
  bool _defeatHandled = false;

  // Target (Har Suld position or player)
  late Vector2 primaryTarget; // Har Suld center
  Vector2? playerTarget;
  Vector2 _activeTarget = Vector2.zero();
  bool _targetingPlayer = false;

  // Called when this enemy lands an attack — game wires this to harSuld.takeDamage
  void Function(double damage)? onHarSuldAttack;
  void Function(double damage)? onPlayerAttack;
  void Function(PositionComponent structure, double damage)? onStructureAttack;
  void Function(Map<ResourceType, int> loot)? onDefeated;
  PositionComponent? Function(BaseEnemy enemy, Vector2 nextPosition)?
      findBlockingStructure;

  // Animation components
  SpriteAnimationComponent? _animComp;
  Map<Direction, SpriteAnimation> runningAnims = {};
  Map<Direction, SpriteAnimation> attackAnims = {};
  Map<Direction, SpriteAnimation> deathAnims = {};

  bool get isDead => state == EnemyState.dead || state == EnemyState.dying;
  bool get isAlive => !isDead;
  bool get targetingPlayer => _targetingPlayer;
  Vector2 get activeTarget => _activeTarget;
  Map<ResourceType, int> get lootDrops => const {};

  BaseEnemy({
    required this.hp,
    required this.maxHp,
    required this.armor,
    required this.damage,
    required this.attackInterval,
    required this.attackRange,
    required this.moveSpeed,
    required this.aggroRange,
    required this.structureDamageMultiplier,
    required this.enemyClass,
    required Vector2 spawnPos,
    required this.hpMultiplier,
    required this.damageMultiplier,
    double spriteSize = kEnemySpriteSize,
  }) : super(
          position: spawnPos,
          size: Vector2.all(spriteSize),
          anchor: Anchor.center,
        ) {
    this.hp *= hpMultiplier;
    this.maxHp *= hpMultiplier;
    this.damage *= damageMultiplier;
    primaryTarget = kCenterPos.clone();
    _activeTarget = primaryTarget.clone();
  }

  @override
  Future<void> onLoad() async {
    await loadAnimations();
    if (runningAnims.isNotEmpty) {
      _animComp = SpriteAnimationComponent(
        animation: runningAnims[Direction.south]!,
        size: size,
        anchor: Anchor.center,
      );
      add(_animComp!);
    }
  }

  /// Subclasses override this to preload their sprite animations.
  Future<void> loadAnimations();

  void takeDamage(double rawDamage, {double armorPierce = 0}) {
    if (isDead) return;
    final effectiveArmor = max(0.0, armor - armorPierce);
    final absorbed = rawDamage * (1 - effectiveArmor);
    hp = max(0, hp - absorbed);
    if (hp <= 0) _startDying();
  }

  void _startDying() {
    if (!_defeatHandled) {
      _defeatHandled = true;
      onDefeated?.call(lootDrops);
    }
    state = EnemyState.dying;
    _deathTimer = 0;
    if (deathAnims.isNotEmpty) {
      _animComp?.animation =
          deathAnims[direction] ?? deathAnims[Direction.south]!;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (state == EnemyState.dying) {
      _deathTimer += dt;
      if (_deathTimer >= _deathDuration) {
        state = EnemyState.dead;
        removeFromParent();
      }
      return;
    }

    if (state == EnemyState.dead) return;

    _attackCooldown -= dt;
    _updateBehavior(dt);
  }

  void _updateBehavior(double dt) {
    _resolveActiveTarget();

    final distToTarget = (position - _activeTarget).length;

    if (distToTarget <= attackRange) {
      _performAttack();
      return;
    }

    final directionToTarget = _activeTarget - position;
    if (directionToTarget.length < 1) return;

    final stepDirection = directionToTarget.normalized();
    final nextPosition = position + stepDirection * moveSpeed * dt;
    final blocker = findBlockingStructure?.call(this, nextPosition);

    if (blocker != null) {
      final distToBlocker = _distanceToRect(position, _rectFor(blocker));
      final blockerCenter = blocker.position + blocker.size / 2;

      if (distToBlocker <= attackRange + 4) {
        _performAttack(structureTarget: blocker);
        return;
      }

      _moveToward(blockerCenter, dt);
      return;
    }

    _moveToward(_activeTarget, dt);
  }

  void _moveToward(Vector2 target, double dt) {
    final dir = target - position;
    if (dir.length < 1) return;

    dir.normalize();
    final newDir = DirectionExt.fromVector(dir);
    if (newDir != direction || state != EnemyState.running) {
      direction = newDir;
      if (state != EnemyState.dying) {
        state = EnemyState.running;
        if (runningAnims.isNotEmpty) {
          _animComp?.animation =
              runningAnims[direction] ?? runningAnims[Direction.south]!;
        }
      }
    }

    position += dir * moveSpeed * dt;
    position.x = position.x.clamp(0, kMapPixelSize);
    position.y = position.y.clamp(0, kMapPixelSize);
  }

  void _performAttack({PositionComponent? structureTarget}) {
    if (_attackCooldown > 0) {
      // Show attack idle while waiting
      if (state != EnemyState.attacking) {
        state = EnemyState.attacking;
        if (attackAnims.isNotEmpty) {
          final anim = attackAnims[direction] ?? attackAnims[Direction.south]!;
          _animComp?.animation = anim;
        }
      }
      return;
    }

    state = EnemyState.attacking;
    if (attackAnims.isNotEmpty) {
      final anim = attackAnims[direction] ?? attackAnims[Direction.south]!;
      _animComp?.animation = anim;
    }

    if (structureTarget != null) {
      onStructureAttack?.call(
        structureTarget,
        damage * structureDamageMultiplier,
      );
    } else {
      onAttack();
    }
    _attackCooldown = attackInterval;
  }

  /// Called when this enemy performs an attack.
  void onAttack() {
    if (_targetingPlayer) {
      onPlayerAttack?.call(damage);
      return;
    }
    onHarSuldAttack?.call(damage);
  }

  void _resolveActiveTarget() {
    final player = playerTarget;
    if (player != null && (player - position).length <= aggroRange) {
      _activeTarget = player;
      _targetingPlayer = true;
      return;
    }

    _activeTarget = primaryTarget;
    _targetingPlayer = false;
  }

  Rect _rectFor(PositionComponent component) {
    return Rect.fromLTWH(
      component.position.x,
      component.position.y,
      component.size.x,
      component.size.y,
    );
  }

  double _distanceToRect(Vector2 point, Rect rect) {
    final dx = max(rect.left - point.x, max(0, point.x - rect.right));
    final dy = max(rect.top - point.y, max(0, point.y - rect.bottom));
    return sqrt(dx * dx + dy * dy);
  }

  @override
  void render(Canvas canvas) {
    if (_animComp == null) {
      // Fallback colored rectangle
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: size.x * 0.8, height: size.y * 0.8),
        Paint()..color = fallbackColor,
      );
    }
    // HP bar
    if (hp < maxHp) {
      final barW = size.x;
      const barH = 4.0;
      canvas.drawRect(
        Rect.fromLTWH(-barW / 2, -size.y / 2 - 8, barW, barH),
        Paint()..color = const Color(0xFF330000),
      );
      canvas.drawRect(
        Rect.fromLTWH(-barW / 2, -size.y / 2 - 8, barW * (hp / maxHp), barH),
        Paint()..color = const Color(0xFFFF3333),
      );
    }
  }

  Color get fallbackColor => const Color(0xFFAA2222);
}
