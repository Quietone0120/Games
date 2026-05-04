import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'flappy_bird_game.dart';

// ── Individual pipe rect for collision ───────────────────────────────────────
class PipeRect extends PositionComponent
    with HasGameRef<FlappyBirdGame>, CollisionCallbacks {
  final bool isTop;

  PipeRect({
    required Vector2 position,
    required Vector2 size,
    required this.isTop,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }
}

// ── PipePair: spawns at right edge, scrolls left ──────────────────────────────
class PipePair extends PositionComponent with HasGameRef<FlappyBirdGame> {
  static const double _pipeWidth = 60.0;
  static const double _capHeight = 22.0;
  static const double _capExtraW = 8.0;

  bool _scored = false;
  late double _gapTop;
  late double _gapBottom;

  late PipeRect _topPipe;
  late PipeRect _bottomPipe;

  final _rng = math.Random();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final playH = gameRef.size.y - FlappyBirdGame.groundHeight;
    final gap = FlappyBirdGame.pipeGap;
    final minPipeH = 55.0;
    final maxGapTop = playH - gap - minPipeH;

    _gapTop = minPipeH + _rng.nextDouble() * (maxGapTop - minPipeH);
    _gapBottom = _gapTop + gap;

    // Position this component at right edge
    position = Vector2(gameRef.size.x, 0);

    // Top pipe
    _topPipe = PipeRect(
      position: Vector2.zero(),
      size: Vector2(_pipeWidth, _gapTop),
      isTop: true,
    );
    add(_topPipe);

    // Bottom pipe
    _bottomPipe = PipeRect(
      position: Vector2(0, _gapBottom),
      size: Vector2(_pipeWidth, gameRef.size.y - _gapBottom),
      isTop: false,
    );
    add(_bottomPipe);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!gameRef.isPlaying) return;

    position.x -= FlappyBirdGame.pipeSpeed * dt;

    // Score: when pipe passes the bird's x
    final birdX = gameRef.bird.position.x;
    if (!_scored && position.x + _pipeWidth < birdX) {
      _scored = true;
      gameRef.addScore();
    }

    // Remove when off screen
    if (position.x + _pipeWidth < -20) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    _drawPipe(canvas, top: true, pipeH: _gapTop);
    _drawPipe(
      canvas,
      top: false,
      pipeH: gameRef.size.y - _gapBottom,
      offsetY: _gapBottom,
    );
  }

  void _drawPipe(
    Canvas canvas, {
    required bool top,
    required double pipeH,
    double offsetY = 0,
  }) {
    final w = _pipeWidth;
    final capH = _capHeight;
    final capExtra = _capExtraW;

    // ── Pipe shaft ───────────────────────────────────────────
    final shaftPaint = Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFF5EC43A), Color(0xFF3DA822), Color(0xFF2E8A17)],
        stops: const [0.0, 0.45, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, offsetY, w, pipeH));

    canvas.drawRect(Rect.fromLTWH(0, offsetY, w, pipeH), shaftPaint);

    // ── Highlight on shaft ────────────────────────────────────
    final highlightPaint = Paint()
      ..color = const Color(0xFF72E050).withOpacity(0.35)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(5, offsetY, w * 0.22, pipeH), highlightPaint);

    // ── Cap (end opening) ─────────────────────────────────────
    final capY = top ? offsetY + pipeH - capH : offsetY;
    final capPaint = Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFF68D840), Color(0xFF45BA1F), Color(0xFF307B10)],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(-capExtra / 2, capY, w + capExtra, capH));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-capExtra / 2, capY, w + capExtra, capH),
        const Radius.circular(4),
      ),
      capPaint,
    );

    // Cap highlight
    final capHighlight = Paint()
      ..color = const Color(0xFF7AEA58).withOpacity(0.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          -capExtra / 2 + 4,
          capY + 3,
          (w + capExtra) * 0.25,
          capH - 6,
        ),
        const Radius.circular(3),
      ),
      capHighlight,
    );

    // ── Dark edge outline ─────────────────────────────────────
    final outlinePaint = Paint()
      ..color = const Color(0xFF1E6B08).withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(Rect.fromLTWH(0, offsetY, w, pipeH), outlinePaint);
  }
}
