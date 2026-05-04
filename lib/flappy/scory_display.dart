import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'flappy_bird_game.dart';

/// Score text rendered as a Flame TextComponent
class ScoreDisplay extends TextComponent with HasGameRef<FlappyBirdGame> {
  ScoreDisplay()
    : super(
        text: '0',
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black54,
                offset: Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        anchor: Anchor.topCenter,
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = Vector2(gameRef.size.x / 2, 48);
  }

  @override
  void update(double dt) {
    super.update(dt);
    text = '${gameRef.score}';
  }
}
