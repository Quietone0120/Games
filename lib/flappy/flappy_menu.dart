import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'flappy_bird_game.dart';
import 'start_screen.dart';
import 'game_over_screen.dart';

class FlappyBirdWrapper extends StatelessWidget {
  const FlappyBirdWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flappy Bird"),
        backgroundColor: const Color(0xFF4EC0CA),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: GameWidget<FlappyBirdGame>(
        game: FlappyBirdGame(),
        overlayBuilderMap: {
          'startScreen': (context, game) => StartScreen(game: game),
          'gameOver': (context, game) => GameOverScreen(game: game),
        },
        initialActiveOverlays: const ['startScreen'],
      ),
    );
  }
}
