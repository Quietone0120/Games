import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'flappy_bird_game.dart';
import 'pipe_pair.dart';
import 'ground.dart';

class Bird extends PositionComponent
    with HasGameRef<FlappyBirdGame>, CollisionCallbacks {
  // ─── Physics ─────────────────────────────────────────────────
  static const double _gravity = 950.0;
  static const double _flapVelocity = -330.0;
  static const double _birdW = 38.0;
  static const double _birdH = 30.0;
  static const double _maxFallSpeed = 600.0;

  double _velocityY = 0.0;
  bool _isDead = false;

  // ─── Wing animation ──────────────────────────────────────────
  double _wingPhase = 0.0;

  Bird() : super(size: Vector2(_birdW, _birdH), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(
      RectangleHitbox(
        size: Vector2(_birdW * 0.75, _birdH * 0.75),
        position: Vector2(_birdW * 0.125, _birdH * 0.125),
      ),
    );
    reset();
  }

  void reset() {
    _velocityY = 0;
    _isDead = false;
    _wingPhase = 0;
    position = Vector2(gameRef.size.x * 0.28, gameRef.size.y * 0.44);
    angle = 0;
  }

  void die() {
    _isDead = true;
  }

  void flap() {
    if (_isDead) return;
    _velocityY = _flapVelocity;
    _wingPhase = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!gameRef.isPlaying || _isDead) return;

    // Wing flap animation
    _wingPhase += dt * 8;

    // Physics
    _velocityY += _gravity * dt;
    _velocityY = _velocityY.clamp(-_flapVelocity.abs(), _maxFallSpeed);
    position.y += _velocityY * dt;

    // Rotation: tilt up on flap, tilt down on fall
    final targetAngle = (_velocityY / _maxFallSpeed) * (math.pi / 2.5);
    angle = targetAngle.clamp(-0.45, math.pi / 2.2);

    // Hit ground
    final groundY = gameRef.size.y - FlappyBirdGame.groundHeight;
    if (position.y + _birdH / 2 >= groundY) {
      position.y = groundY - _birdH / 2;
      _velocityY = 0;
      gameRef.triggerGameOver();
    }

    // Hit ceiling
    if (position.y - _birdH / 2 <= 0) {
      position.y = _birdH / 2;
      _velocityY = 0;
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PipeRect || other is Ground) {
      gameRef.triggerGameOver();
    }
  }

  @override
  void render(Canvas canvas) {
    final w = _birdW;
    final h = _birdH;

    // ── Body ──────────────────────────────────────────────────
    final bodyPaint = Paint()..color = const Color(0xFFFFD93D);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, h * 0.15, w * 0.85, h * 0.75),
        topLeft: const Radius.circular(12),
        topRight: const Radius.circular(10),
        bottomLeft: const Radius.circular(12),
        bottomRight: const Radius.circular(10),
      ),
      bodyPaint,
    );

    // ── Wing ─────────────────────────────────────────────────
    final wingY = gameRef.isPlaying
        ? h * 0.38 + math.sin(_wingPhase) * h * 0.18
        : h * 0.42;
    final wingPaint = Paint()..color = const Color(0xFFF4A01C);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.3, wingY),
        width: w * 0.55,
        height: h * 0.28,
      ),
      wingPaint,
    );

    // ── White eye circle ──────────────────────────────────────
    final eyeWhitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.64, h * 0.36), 8.5, eyeWhitePaint);

    // ── Pupil ─────────────────────────────────────────────────
    final pupilPaint = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawCircle(Offset(w * 0.68, h * 0.37), 4.5, pupilPaint);

    // ── Eye gleam ─────────────────────────────────────────────
    final gleamPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.71, h * 0.33), 2.0, gleamPaint);

    // ── Beak ─────────────────────────────────────────────────
    final beakPaint = Paint()..color = const Color(0xFFFF6B2B);
    final beak = Path()
      ..moveTo(w * 0.82, h * 0.45)
      ..lineTo(w * 1.06, h * 0.52)
      ..lineTo(w * 0.82, h * 0.62)
      ..close();
    canvas.drawPath(beak, beakPaint);

    // Beak highlight
    final beakHighlight = Paint()
      ..color = const Color(0xFFFF9055)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.83, h * 0.48)
        ..lineTo(w * 1.0, h * 0.52),
      beakHighlight,
    );

    // ── Belly ─────────────────────────────────────────────────
    final bellyPaint = Paint()
      ..color = const Color(0xFFFFF4B0).withOpacity(0.6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.38, h * 0.60),
        width: w * 0.38,
        height: h * 0.32,
      ),
      bellyPaint,
    );
  }
}
