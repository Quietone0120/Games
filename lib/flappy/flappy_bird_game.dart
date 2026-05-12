import 'dart:async';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'bird.dart';
import 'pipe_pair.dart';
import 'ground.dart';
import 'background.dart';
import 'scory_display.dart';
import '../constants/score_service.dart';
import '../constants/audio_service.dart';

class FlappyBirdGame extends FlameGame
    with TapCallbacks, HasCollisionDetection {
  // ─── Constants ───────────────────────────────────────────────
  static const double groundHeight = 90.0;
  static const double pipeSpeed = 160.0;
  static const double pipeSpawnInterval = 2.4;
  static const double pipeGap = 155.0;

  // ─── State ────────────────────────────────────────────────────
  late Bird bird;
  int score = 0;
  int bestScore = 0;
  bool isPlaying = false;
  DateTime? _startTime;

  double _timeSinceLastPipe = 0;

  // ─── Lifecycle ────────────────────────────────────────────────
  @override
  Color backgroundColor() => const Color(0xFF4EC0CA);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await AudioService.init();

    add(Background());
    add(
      Ground(
        position: Vector2(0, size.y - groundHeight),
        size: Vector2(size.x, groundHeight),
      ),
    );
    bird = Bird();
    add(bird);
    add(ScoreDisplay());
    overlays.add('startScreen');

    // Цэсний хөгжим
    await AudioService.playBgm(AudioService.bgmFlappy);
  }

  @override
  void onRemove() {
    AudioService.stopBgm();
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isPlaying) return;

    _timeSinceLastPipe += dt;
    if (_timeSinceLastPipe >= pipeSpawnInterval) {
      _timeSinceLastPipe = 0;
      _spawnPipe();
    }
  }

  // ─── Actions ─────────────────────────────────────────────────
  void _spawnPipe() {
    add(PipePair());
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isPlaying) {
      bird.flap();
      AudioService.playSfx(AudioService.sfxWing); // 🔊 дэвхрэх дуу
    }
  }

  void startGame() {
    score = 0;
    isPlaying = true;
    _startTime = DateTime.now();
    _timeSinceLastPipe = pipeSpawnInterval;

    children.whereType<PipePair>().toList().forEach(
      (p) => p.removeFromParent(),
    );
    bird.reset();

    overlays.remove('startScreen');
    overlays.remove('gameOver');
  }

  void addScore() {
    score++;
    if (score > bestScore) bestScore = score;
    AudioService.playSfx(AudioService.sfxPoint); // 🔊 оноо авах дуу
  }

  void triggerGameOver() {
    if (!isPlaying) return;
    isPlaying = false;
    bird.die();
    AudioService.playSfx(AudioService.sfxHit);    // 🔊 мөргөлдөх дуу
    overlays.add('gameOver');

    int playtime = 0;
    if (_startTime != null) {
      playtime = DateTime.now().difference(_startTime!).inSeconds;
    }
    ScoreService.submitScore(
      gameName: 'Flappy Bird',
      score: score,
      playtimeSeconds: playtime,
    );
  }
}
