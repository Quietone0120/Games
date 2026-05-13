import 'dart:math';
import 'package:flame/components.dart';
import '../utils/constants.dart';
import '../components/enemies/base_enemy.dart';
import '../components/enemies/raider.dart';
import '../components/enemies/archer_enemy.dart';
import '../components/enemies/wolf.dart';
import '../components/enemies/boss_enemy.dart';

enum GamePhase { wave, breakPhase, gameOver }

class WaveSystem {
  int currentWave = 0;
  GamePhase phase = GamePhase.breakPhase;
  double timer = 0;
  bool isFirstWave = true;

  // Callbacks
  void Function(BaseEnemy)? onEnemySpawn;
  void Function()? onWaveStart;
  void Function()? onWaveEnd;
  void Function()? onBreakEnd;
  void Function(int wave)? onBossWave;

  // Wolf break spawning
  bool _wolfSpawn1 = false;
  bool _wolfSpawn2 = false;
  bool _wolfSpawn3 = false;

  final _rng = Random();

  void update(double dt, List<BaseEnemy> activeEnemies) {
    if (phase == GamePhase.gameOver) return;

    if (phase == GamePhase.wave) {
      // Check if all enemies dead
      final alive = activeEnemies.where((e) => e.isAlive).length;
      if (alive == 0 && !isFirstWave) {
        _endWave();
      }
    } else if (phase == GamePhase.breakPhase) {
      timer -= dt;

      // Wolf spawns during break
      if (!_wolfSpawn1 && timer <= kBreakDuration - kWolfBreakTime1) {
        _wolfSpawn1 = true;
        _spawnWolfPack(isBlack: false);
      }
      if (!_wolfSpawn2 && timer <= kBreakDuration - kWolfBreakTime2) {
        _wolfSpawn2 = true;
        _spawnWolfPack(isBlack: _rng.nextDouble() < 0.2);
      }
      if (!_wolfSpawn3 && timer <= kBreakDuration - kWolfBreakTime3) {
        _wolfSpawn3 = true;
        _spawnWolfPack(isBlack: _rng.nextDouble() < 0.4);
      }

      if (timer <= 0) {
        startWave();
      }
    }
  }

  void startWave() {
    currentWave++;
    phase = GamePhase.wave;
    isFirstWave = false;
    timer = 0;

    final isBoss = currentWave % 10 == 0;
    if (isBoss) onBossWave?.call(currentWave);
    onWaveStart?.call();

    _spawnWave();
  }

  void startBreak() {
    phase = GamePhase.breakPhase;
    timer = kBreakDuration;
    _wolfSpawn1 = false;
    _wolfSpawn2 = false;
    _wolfSpawn3 = false;
    onBreakEnd?.call();
  }

  void skipBreak() {
    timer = 0;
  }

  void _endWave() {
    phase = GamePhase.breakPhase;
    timer = kBreakDuration;
    _wolfSpawn1 = false;
    _wolfSpawn2 = false;
    _wolfSpawn3 = false;
    onWaveEnd?.call();
  }

  void _spawnWave() {
    final wave = currentWave;
    final hpMul = waveHpMultiplier(wave);
    final dmgMul = waveDamageMultiplier(wave);
    final isBossWave = wave % 10 == 0;

    if (isBossWave) {
      _spawnBossWave(wave, hpMul, dmgMul);
      return;
    }

    final budget = waveThreatBudget(wave) * 0.88;
    _distributeBudget(budget, wave, hpMul, dmgMul);
  }

  void _distributeBudget(double budget, int wave, double hpMul, double dmgMul) {
    double remaining = budget;
    final sides = _getSpawnSides(wave);

    while (remaining > 1.0) {
      final type = _pickEnemyType(wave, remaining);
      final cost = kEnemyThreatCost[type]!;
      if (cost > remaining) break;

      final spawnPos = _getSpawnPos(sides);
      final enemy = _createEnemy(type, spawnPos, hpMul, dmgMul);
      if (enemy != null) onEnemySpawn?.call(enemy);
      remaining -= cost;
    }
  }

  String _pickEnemyType(int wave, double remaining) {
    if (wave <= 3) return 'raider';
    if (wave <= 6) {
      return _rng.nextDouble() < 0.75 ? 'raider' : 'archer';
    }
    if (wave <= 9) {
      final r = _rng.nextDouble();
      if (r < 0.60) return 'raider';
      if (r < 0.80) return 'archer';
      return 'veteran';
    }
    // Wave 11+
    if (wave <= 15) {
      final r = _rng.nextDouble();
      if (r < 0.40) return 'raider';
      if (r < 0.65) return 'archer';
      if (r < 0.80) return 'veteran';
      if (r < 0.90 && remaining >= kEnemyThreatCost['ram']!) return 'ram';
      return 'raider';
    }
    // Wave 16+
    final r = _rng.nextDouble();
    if (r < 0.30) return 'archer';
    if (r < 0.55) return 'veteran';
    if (r < 0.70 && remaining >= kEnemyThreatCost['ram']!) return 'ram';
    if (r < 0.80 && remaining >= kEnemyThreatCost['catapult']!)
      return 'catapult';
    return 'raider';
  }

  List<int> _getSpawnSides(int wave) {
    if (wave <= 4) return [0];
    if (wave <= 9) return [0, 1];
    if (wave <= 14) return [0, 1, 2];
    return [0, 1, 2, 3]; // all 4 sides
  }

  Vector2 _getSpawnPos(List<int> sides) {
    final side = sides[_rng.nextInt(sides.length)];
    final mapPx = kMapPixelSize;
    final margin = kTileSize * 2;
    final jitter = () => _rng.nextDouble() * mapPx * 0.8 + mapPx * 0.1;

    switch (side) {
      case 0:
        return Vector2(jitter(), margin); // Top
      case 1:
        return Vector2(mapPx - margin, jitter()); // Right
      case 2:
        return Vector2(jitter(), mapPx - margin); // Bottom
      case 3:
        return Vector2(margin, jitter()); // Left
      default:
        return Vector2(jitter(), margin);
    }
  }

  void _spawnBossWave(int wave, double hpMul, double dmgMul) {
    // Boss + support
    final bossPos = _getSpawnPos([0, 1, 2, 3]);
    final boss = BossEnemy(
      spawnPos: bossPos,
      hpMul: hpMul,
      dmgMul: dmgMul,
      bossWaveNumber: wave ~/ 10,
    );
    onEnemySpawn?.call(boss);

    // Support units
    int raiders = 8, archers = 3, veterans = 0, rams = 0, catapults = 0;
    if (wave >= 20) {
      raiders = 0;
      veterans = 6;
      archers = 3;
      rams = 2;
    }
    if (wave >= 30) {
      veterans = 8;
      archers = 5;
      rams = 2;
      catapults = 1;
    }

    _spawnGroup('raider', raiders, hpMul, dmgMul, [0, 1, 2, 3]);
    _spawnGroup('archer', archers, hpMul, dmgMul, [0, 1, 2, 3]);
    _spawnGroup('veteran', veterans, hpMul, dmgMul, [0, 1, 2, 3]);
    _spawnGroup('ram', rams, hpMul, dmgMul, [0, 1, 2, 3]);
    _spawnGroup('catapult', catapults, hpMul, dmgMul, [0, 1, 2, 3]);
  }

  void _spawnGroup(
      String type, int count, double hpMul, double dmgMul, List<int> sides) {
    for (int i = 0; i < count; i++) {
      final pos = _getSpawnPos(sides);
      final enemy = _createEnemy(type, pos, hpMul, dmgMul);
      if (enemy != null) onEnemySpawn?.call(enemy);
    }
  }

  BaseEnemy? _createEnemy(
      String type, Vector2 pos, double hpMul, double dmgMul) {
    switch (type) {
      case 'raider':
        return Raider(spawnPos: pos, hpMul: hpMul, dmgMul: dmgMul);
      case 'archer':
        return ArcherEnemy(spawnPos: pos, hpMul: hpMul, dmgMul: dmgMul);
      case 'veteran':
        // Veteran uses raider animations but with boosted stats
        return Raider(
          spawnPos: pos,
          hpMul: hpMul * 2.0, // 110 base hp
          dmgMul: dmgMul * 1.8,
        );
      case 'ram':
        return Raider(
          spawnPos: pos,
          hpMul: hpMul * 2.5,
          dmgMul: dmgMul * 3.5,
        );
      case 'catapult':
        return ArcherEnemy(
          spawnPos: pos,
          hpMul: hpMul * 2.2,
          dmgMul: dmgMul * 6.25,
        );
      case 'wolf':
        return GreyWolf(spawnPos: pos, hpMul: hpMul, dmgMul: dmgMul);
      default:
        return null;
    }
  }

  void _spawnWolfPack({required bool isBlack}) {
    final wave = currentWave;
    final wolfBudget = 3 + 0.8 * wave;
    final wolfHp = isBlack ? 2.5 : 1.0;
    final wolfDmg = isBlack ? 2.0 : 1.0;

    int count = wolfBudget.toInt();
    if (isBlack) count = max(1, count ~/ 3);

    final sides = [0, 1, 2, 3];
    for (int i = 0; i < count; i++) {
      final pos = _getSpawnPos(sides);
      final wolf = GreyWolf(spawnPos: pos, hpMul: wolfHp, dmgMul: wolfDmg);
      onEnemySpawn?.call(wolf);
    }
  }
}
