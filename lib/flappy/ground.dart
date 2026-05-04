import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'flappy_bird_game.dart';

class Ground extends PositionComponent
    with HasGameRef<FlappyBirdGame>, CollisionCallbacks {
  double _scrollOffset = 0;
  static const double _tileWidth = 24.0;

  Ground({required Vector2 position, required Vector2 size})
    : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!gameRef.isPlaying) return;
    _scrollOffset += FlappyBirdGame.pipeSpeed * dt;
    if (_scrollOffset >= _tileWidth) {
      _scrollOffset -= _tileWidth;
    }
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // ── Dirt base ─────────────────────────────────────────────
    final dirtPaint = Paint()..color = const Color(0xFFDEB887);
    canvas.drawRect(Rect.fromLTWH(0, 12, w, h - 12), dirtPaint);

    // ── Grass strip ───────────────────────────────────────────
    final grassPaint = Paint()..color = const Color(0xFF78C928);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 0, w, 18),
        topLeft: const Radius.circular(0),
        topRight: const Radius.circular(0),
      ),
      grassPaint,
    );

    // ── Scrolling dirt texture ─────────────────────────────────
    final linePaint = Paint()
      ..color = const Color(0xFFC49A5A)
      ..strokeWidth = 1.0;

    double x = -_scrollOffset;
    while (x < w) {
      canvas.drawLine(Offset(x, 20), Offset(x + 8, h), linePaint);
      x += _tileWidth;
    }

    // ── Top border ────────────────────────────────────────────
    final borderPaint = Paint()
      ..color = const Color(0xFF5A9E1A)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, 17), Offset(w, 17), borderPaint);
  }
}
