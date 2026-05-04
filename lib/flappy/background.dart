import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'flappy_bird_game.dart';

class _Cloud {
  double x, y, speed, scale;
  _Cloud({
    required this.x,
    required this.y,
    required this.speed,
    required this.scale,
  });
}

class Background extends PositionComponent with HasGameRef<FlappyBirdGame> {
  final List<_Cloud> _clouds = [];
  final _rng = math.Random(42);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = gameRef.size;
    _initClouds();
  }

  void _initClouds() {
    for (int i = 0; i < 6; i++) {
      _clouds.add(
        _Cloud(
          x: _rng.nextDouble() * gameRef.size.x,
          y: 30 + _rng.nextDouble() * (gameRef.size.y * 0.38),
          speed: 18 + _rng.nextDouble() * 22,
          scale: 0.5 + _rng.nextDouble() * 0.8,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!gameRef.isPlaying) return;
    for (final cloud in _clouds) {
      cloud.x -= cloud.speed * dt;
      if (cloud.x + 120 < 0) {
        cloud.x = gameRef.size.x + 10;
        cloud.y = 30 + _rng.nextDouble() * (gameRef.size.y * 0.38);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, gameRef.size.x, gameRef.size.y);

    // Sky gradient
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF87CEEB), Color(0xFF4EC0CA)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // Draw clouds
    for (final cloud in _clouds) {
      _drawCloud(canvas, cloud);
    }
  }

  void _drawCloud(Canvas canvas, _Cloud c) {
    canvas.save();
    canvas.translate(c.x, c.y);
    canvas.scale(c.scale);

    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.88);

    final puffs = [
      Offset(0, 10),
      Offset(20, 2),
      Offset(40, 0),
      Offset(60, 4),
      Offset(80, 10),
    ];
    final radii = [18.0, 22.0, 26.0, 22.0, 16.0];

    for (int i = 0; i < puffs.length; i++) {
      canvas.drawCircle(puffs[i], radii[i], cloudPaint);
    }

    // Base fill
    canvas.drawRect(Rect.fromLTWH(-4, 10, 90, 18), cloudPaint);

    canvas.restore();
  }
}
