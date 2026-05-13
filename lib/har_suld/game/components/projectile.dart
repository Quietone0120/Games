import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'enemies/base_enemy.dart';

class Projectile extends PositionComponent {
  static Sprite? _arrowSprite;

  final BaseEnemy target;
  final double damage;
  final double speed;
  final bool fromEnemy;
  final Vector2? targetPoint;

  bool _hit = false;

  Projectile({
    required Vector2 start,
    required this.target,
    required this.damage,
    this.speed = 400.0,
    this.fromEnemy = false,
    this.targetPoint,
  }) : super(
            position: start.clone(),
            size: Vector2(18, 8),
            anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    _arrowSprite ??=
        Sprite(await Flame.images.load('HarSuld_designs/arrow.png'));
  }

  @override
  void update(double dt) {
    if (_hit) return;

    final dest =
        target.isDead ? (targetPoint ?? target.position) : target.position;
    final dir = dest - position;
    final dist = dir.length;

    if (dist < speed * dt) {
      if (!target.isDead) {
        target.takeDamage(damage);
      }
      _hit = true;
      removeFromParent();
      return;
    }

    dir.normalize();
    position += dir * speed * dt;
    angle = atan2(dir.y, dir.x);
  }

  @override
  void render(Canvas canvas) {
    if (_arrowSprite != null) {
      _arrowSprite!.render(
        canvas,
        size: size,
        anchor: Anchor.center,
      );
      return;
    }

    final paint = Paint()
      ..color = fromEnemy ? const Color(0xFFFF6644) : const Color(0xFFD4A017);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 8, height: 3),
        const Radius.circular(1.5),
      ),
      paint,
    );
  }
}

class EnemyProjectile extends PositionComponent {
  static Sprite? _arrowSprite;

  final Vector2 targetPos;
  final double damage;
  final double speed;
  final Function(Vector2) onHit;

  bool _hit = false;

  EnemyProjectile({
    required Vector2 start,
    required this.targetPos,
    required this.damage,
    required this.onHit,
    this.speed = 320.0,
  }) : super(
            position: start.clone(),
            size: Vector2(18, 8),
            anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    _arrowSprite ??=
        Sprite(await Flame.images.load('HarSuld_designs/arrow.png'));
  }

  @override
  void update(double dt) {
    if (_hit) return;

    final dir = targetPos - position;
    final dist = dir.length;

    if (dist < speed * dt) {
      _hit = true;
      onHit(position.clone());
      removeFromParent();
      return;
    }

    dir.normalize();
    position += dir * speed * dt;
    angle = atan2(dir.y, dir.x);
  }

  @override
  void render(Canvas canvas) {
    if (_arrowSprite != null) {
      final enemyPaint = Paint()
        ..colorFilter = const ColorFilter.mode(
          Color(0xCCFF7A4D),
          BlendMode.modulate,
        );
      _arrowSprite!.render(
        canvas,
        size: size,
        anchor: Anchor.center,
        overridePaint: enemyPaint,
      );
      return;
    }

    final paint = Paint()..color = const Color(0xFFFF6644);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 8, height: 3),
        const Radius.circular(1.5),
      ),
      paint,
    );
  }
}
