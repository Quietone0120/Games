import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'components/player.dart';
import 'components/har_suld_component.dart';
import 'components/horse_component.dart';
import 'components/enemies/base_enemy.dart';
import 'components/enemies/archer_enemy.dart';
import 'components/enemies/wolf.dart';
import 'components/projectile.dart';
import 'components/structures/wall_structure.dart';
import 'components/structures/tower_structure.dart';
import 'systems/wave_system.dart';
import 'systems/inventory_system.dart';
import 'world/tile_map.dart';
import 'utils/constants.dart';

class HarSuldGame extends FlameGame
    with KeyboardEvents, TapCallbacks, MouseMovementDetector, PanDetector {
  // Core components
  late Player player;
  late HarSuldComponent harSuld;
  late HorseComponent horse;
  late TileMap tileMap;

  // Systems
  late WaveSystem waveSystem;
  late InventorySystem inventory;

  // Joystick
  late JoystickComponent _joystick;

  // State
  bool isGameOver = false;
  bool isPaused = false;
  int highestWave = 0;
  PositionComponent? selectedStructure;

  // Score tracking
  int score = 0;
  double _playSeconds = 0;
  void Function(int score, int waves, int playtime)? onGameOver;

  /// Тоглогчийн бичсэн дуугаргах callback.
  /// Lobby-оос тохируулна. [key] = HarSuldSoundKeys-ийн нэг.
  void Function(String key)? onPlayCustomSound;

  // Build mode
  BuildType? _pendingBuildType;
  WallOrientation _wallOrientation = WallOrientation.horizontal;
  Vector2 _cursorWorldPos = Vector2.zero();

  // Ghost preview (tile coordinates)
  int _ghostTileX = 0;
  int _ghostTileY = 0;

  // Harvest timer
  double _harvestCooldown = 0;
  static const double _harvestInterval = 0.8;

  @override
  Color backgroundColor() => const Color(0xFF2A3A1A);

  @override
  Future<void> onLoad() async {
    Flame.images.prefix = '';

    overlays.add('Loading');

    await _loadWorld();
    await _loadPlayer();
    _setupWaveSystem();
    _setupInventory();
    _setupJoystick();

    // Follow player with a zoom that adapts to compact landscape screens.
    camera.follow(player);
    _updateCameraZoom(size);

    overlays.remove('Loading');
    overlays.add('HUD');
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _updateCameraZoom(size);
  }

  Future<void> _loadWorld() async {
    tileMap = TileMap();
    world.add(tileMap);

    harSuld = HarSuldComponent();
    world.add(harSuld);

    horse = HorseComponent();
    world.add(horse);
  }

  Future<void> _loadPlayer() async {
    player = Player();
    player.getEnemies = _getAliveEnemies;
    player.onProjectileSpawned = (proj) {
      world.add(proj);
      onPlayCustomSound?.call('arrow_shoot');
    };
    player.onDeath = _onPlayerDeath;
    player.onMountHorse = _onPlayerMount;
    player.canMoveTo = _canPlayerMoveTo;
    world.add(player);
  }

  void _setupJoystick() {
    _joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 18,
        paint: Paint()..color = const Color(0xCCFFFFFF),
      ),
      background: CircleComponent(
        radius: 48,
        paint: Paint()..color = const Color(0x44FFFFFF),
      ),
      margin: const EdgeInsets.only(left: 60, bottom: 60),
    );
    // Add to camera viewport so it stays fixed on screen
    camera.viewport.add(_joystick);
  }

  void _setupWaveSystem() {
    waveSystem = WaveSystem();
    waveSystem.onEnemySpawn = (enemy) {
      enemy.onHarSuldAttack = (dmg) => harSuld.takeDamage(dmg);
      enemy.onPlayerAttack = (dmg) {
        player.takeDamage(dmg);
        if (enemy is GreyWolf) {
          onPlayCustomSound?.call('wolf_attack');
        }
      };
      enemy.onDefeated = (loot) {
        for (final entry in loot.entries) {
          inventory.add(entry.key, entry.value);
        }
        score += 10;
      };
      enemy.playerTarget = player.position;
      enemy.findBlockingStructure = _findBlockingStructureForEnemy;
      enemy.onStructureAttack = _damageStructure;

      if (enemy is GreyWolf) {
        enemy.playerTarget = player.position;
      }

      if (enemy is ArcherEnemy) {
        enemy.onShoot = (from, to, damage) {
          final aimedAtPlayer = enemy.targetingPlayer;
          world.add(
            EnemyProjectile(
              start: from,
              targetPos: to,
              damage: damage,
              onHit: (_) {
                if (aimedAtPlayer) {
                  player.takeDamage(damage);
                } else {
                  harSuld.takeDamage(damage);
                }
              },
            ),
          );
        };
      }
      world.add(enemy);
    };
    waveSystem.onWaveStart = () {
      highestWave = max(highestWave, waveSystem.currentWave);
    };
    waveSystem.onWaveEnd = () {
      score += waveSystem.currentWave * 50;
    };
  }

  void _setupInventory() {
    inventory = InventorySystem();
    inventory.add(ResourceType.wood, 50);
  }

  List<BaseEnemy> _getAliveEnemies() {
    return world.children
        .whereType<BaseEnemy>()
        .where((e) => e.isAlive)
        .toList();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;

    _playSeconds += dt;

    // Pass joystick delta to player every frame
    player.joystickDelta = _joystick.relativeDelta.clone();

    waveSystem.update(dt, _getAliveEnemies());

    _updateEnemyTargets();

    // Player harvest interaction (proximity auto-harvest)
    _handleHarvest(dt);

    // Gate auto-open near player
    _handleGateAutoOpen();

    // Tower attacks — handled by TowerStructure.update internally

    // Check game over conditions
    if (!harSuld.isAlive || player.lives <= 0) {
      _triggerGameOver();
    }
  }

  void _updateEnemyTargets() {
    for (final enemy in world.children.whereType<BaseEnemy>()) {
      enemy.playerTarget = player.position;
    }

    for (final wolf in world.children.whereType<GreyWolf>()) {
      wolf.playerTarget = player.position;
    }
  }

  void _handleHarvest(double dt) {
    _harvestCooldown -= dt;
    if (_harvestCooldown > 0) return;
    if (player.onHorse) return;

    final playerTileX = (player.position.x / kTileSize).floor();
    final playerTileY = (player.position.y / kTileSize).floor();

    for (int y = playerTileY - 1; y <= playerTileY + 1; y++) {
      for (int x = playerTileX - 1; x <= playerTileX + 1; x++) {
        final tile = tileMap.tileAt(x, y);
        if (tile == null || !tile.isHarvestable) continue;

        final tileCenter = Vector2(
          x * kTileSize + kTileSize / 2,
          y * kTileSize + kTileSize / 2,
        );
        if ((tileCenter - player.position).length > kTileSize * 1.6) continue;

        final result = tileMap.harvestTile(x, y);
        if (result != null) {
          for (final entry in result.drops.entries) {
            inventory.add(entry.key, entry.value);
          }
          player.playUtilityAction();
          onPlayCustomSound?.call('harvest_resource');
          _harvestCooldown = _harvestInterval;
          return;
        }
      }
    }
  }

  void _handleGateAutoOpen() {
    for (final gate in world.children.whereType<GateStructure>()) {
      final dist = (player.position - gate.centerPoint).length;
      if (dist < kTileSize * 1.5) {
        gate.open();
      }
    }
  }

  void _onPlayerDeath() {
    if (player.lives <= 0) {
      _triggerGameOver();
    }
  }

  void _onPlayerMount() {
    horse.position = player.position.clone();
    horse.setMoving(true);
    onPlayCustomSound?.call('horse_mount');
  }

  void _triggerGameOver() {
    if (isGameOver) return;
    isGameOver = true;
    onPlayCustomSound?.call('player_death');
    onGameOver?.call(score, waveSystem.currentWave, _playSeconds.toInt());
    overlays.add('GameOver');
  }

  // ─── Build System ───────────────────────────────────────────────────────────

  void setBuildType(BuildType? type, {CraftedTowerType? towerType}) {
    _pendingBuildType = type;
    if (type != null) {
      player.selectedBuild = type;
      player.selectedTowerType = type.isTower
          ? (towerType ?? player.selectedTowerType ?? CraftedTowerType.human)
          : null;
      overlays.remove('StructureMenu');
    }
    if (type == null) {
      player.clearSelectedBlueprint();
      overlays.remove('BuildGhost');
    }
  }

  void toggleWallRotation() {
    _wallOrientation = _wallOrientation == WallOrientation.horizontal
        ? WallOrientation.vertical
        : WallOrientation.horizontal;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_pendingBuildType != null) {
      if (player.onHorse) return;
      _setGhostFromPosition(event.canvasPosition);
      _tryPlaceStructure(_ghostTileX, _ghostTileY);
      return;
    }

    final worldPos = camera.globalToLocal(event.canvasPosition);
    _selectStructureAt(worldPos);
  }

  @override
  void onPanDown(DragDownInfo info) {
    _updateGhostFromGlobalPosition(info.eventPosition.global);
  }

  @override
  void onPanStart(DragStartInfo info) {
    _updateGhostFromGlobalPosition(info.eventPosition.global);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    _updateGhostFromGlobalPosition(info.eventPosition.global);
  }

  void _tryPlaceStructure(int tx, int ty) {
    final build = _pendingBuildType!;
    final footprint = _footprintForBuild(build);
    if (!_canPlaceFootprint(tx, ty, footprint.x, footprint.y)) return;
    if (!player.consumeSelectedBlueprint()) return;

    _setFootprintOccupied(tx, ty, footprint.x, footprint.y, true);
    player.playUtilityAction(duration: 0.28);
    onPlayCustomSound?.call('build_structure');

    if (build.isWall) {
      final tier = WallTier.values[_wallTierFromBuildType(build)];
      final wall = WallStructure(
        tier: tier,
        tileX: tx,
        tileY: ty,
        orientation: _wallOrientation,
        onDestroyed: () =>
            _setFootprintOccupied(tx, ty, footprint.x, footprint.y, false),
      );
      world.add(wall);
    } else if (build.isGate) {
      final tier = GateTier.values[_gateTierFromBuildType(build)];
      final gate = GateStructure(
        tier: tier,
        tileX: tx,
        tileY: ty,
        onDestroyed: () =>
            _setFootprintOccupied(tx, ty, footprint.x, footprint.y, false),
      );
      world.add(gate);
    } else if (build.isTower) {
      final tier = TowerTier.values[_towerTierFromBuildType(build)];
      final tower = TowerStructure(
        tier: tier,
        tileX: tx,
        tileY: ty,
        towerType: player.selectedTowerType ?? CraftedTowerType.human,
        getEnemies: _getAliveEnemies,
        onDestroyed: () =>
            _setFootprintOccupied(tx, ty, footprint.x, footprint.y, false),
      );
      world.add(tower);
    }

    _pendingBuildType = player.selectedBuild;
  }

  int _wallTierFromBuildType(BuildType t) {
    const tiers = [
      BuildType.woodenWall,
      BuildType.cobbleWall,
      BuildType.ironWall,
      BuildType.steelWall,
      BuildType.sacredWall,
    ];
    return tiers.indexOf(t);
  }

  int _gateTierFromBuildType(BuildType t) {
    const tiers = [
      BuildType.woodenGate,
      BuildType.cobbleGate,
      BuildType.ironGate,
      BuildType.steelGate,
      BuildType.sacredGate,
    ];
    return tiers.indexOf(t);
  }

  int _towerTierFromBuildType(BuildType t) {
    const tiers = [
      BuildType.woodenTower,
      BuildType.cobbleTower,
      BuildType.ironTower,
      BuildType.steelTower,
      BuildType.sacredTower,
    ];
    return tiers.indexOf(t);
  }

  // ─── Repair ──────────────────────────────────────────────────────────────

  void repairNearbyStructure() {
    if (player.onHorse) return;
    const repairRange = kTileSize * 1.5;
    PositionComponent? bestStructure;
    double bestDistance = double.infinity;

    for (final comp in world.children) {
      if (comp is WallStructure && comp.isAlive) {
        final dist = (player.position - comp.centerPoint).length;
        if (dist < repairRange && comp.hp < comp.maxHp && dist < bestDistance) {
          bestStructure = comp;
          bestDistance = dist;
        }
      }
      if (comp is GateStructure && comp.isAlive) {
        final dist = (player.position - comp.centerPoint).length;
        if (dist < repairRange && comp.hp < comp.maxHp && dist < bestDistance) {
          bestStructure = comp;
          bestDistance = dist;
        }
      }
      if (comp is TowerStructure && comp.isAlive) {
        final dist = (player.position - comp.centerPoint).length;
        if (dist < repairRange && comp.hp < comp.maxHp && dist < bestDistance) {
          bestStructure = comp;
          bestDistance = dist;
        }
      }
    }

    if (bestStructure == null) return;
    if (!inventory.consumeConsumable(ConsumableType.harSuldRepairKit)) {
      return;
    }

    player.playUtilityAction(duration: 0.32);
    if (bestStructure is WallStructure) bestStructure.repair(kRepairKitHp);
    if (bestStructure is GateStructure) bestStructure.repair(kRepairKitHp);
    if (bestStructure is TowerStructure) bestStructure.repair(kRepairKitHp);
  }

  @override
  void onMouseMove(PointerHoverInfo info) {
    _updateGhostFromGlobalPosition(info.eventPosition.global);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_pendingBuildType != null) {
      final footprint = _footprintForBuild(_pendingBuildType!);
      final valid = _canPlaceFootprint(
          _ghostTileX, _ghostTileY, footprint.x, footprint.y);
      final color = valid ? const Color(0x8844FF44) : const Color(0x88FF4444);
      for (int y = 0; y < footprint.y; y++) {
        for (int x = 0; x < footprint.x; x++) {
          final screenPos = camera.localToGlobal(
            Vector2(
              (_ghostTileX + x) * kTileSize.toDouble(),
              (_ghostTileY + y) * kTileSize.toDouble(),
            ),
          );
          canvas.drawRect(
            Rect.fromLTWH(
              screenPos.x,
              screenPos.y,
              kTileSize * camera.viewfinder.zoom,
              kTileSize * camera.viewfinder.zoom,
            ),
            Paint()..color = color,
          );
        }
      }

      if (_pendingBuildType!.isTower) {
        final range =
            TowerStructure.rangeTilesForBuildType(_pendingBuildType!) *
                kTileSize *
                camera.viewfinder.zoom;
        final center = camera.localToGlobal(
          Vector2(
            (_ghostTileX + footprint.x / 2) * kTileSize,
            (_ghostTileY + footprint.y / 2) * kTileSize,
          ),
        );
        canvas.drawCircle(
          Offset(center.x, center.y),
          range,
          Paint()..color = const Color(0x223FA7FF),
        );
        canvas.drawCircle(
          Offset(center.x, center.y),
          range,
          Paint()
            ..color = const Color(0x774FC3FF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }

    final selected = selectedStructure;
    if (selected is TowerStructure) {
      final center = camera.localToGlobal(selected.centerPoint);
      final range = selected.range * camera.viewfinder.zoom;
      canvas.drawCircle(
        Offset(center.x, center.y),
        range,
        Paint()..color = const Color(0x183FA7FF),
      );
      canvas.drawCircle(
        Offset(center.x, center.y),
        range,
        Paint()
          ..color = const Color(0x664FC3FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    super.onKeyEvent(event, keysPressed);

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (isPaused) {
          resumeGame();
        } else if (_pendingBuildType != null) {
          setBuildType(null);
        } else {
          pauseGame();
        }
      }
      if (event.logicalKey == LogicalKeyboardKey.keyR) {
        repairNearbyStructure();
      }
      if (event.logicalKey == LogicalKeyboardKey.keyQ) {
        toggleWallRotation();
      }
      if (event.logicalKey == LogicalKeyboardKey.space &&
          waveSystem.phase == GamePhase.breakPhase) {
        waveSystem.skipBreak();
      }
      if (event.logicalKey == LogicalKeyboardKey.keyB) {
        if (overlays.isActive('BuildMenu')) {
          overlays.remove('BuildMenu');
        } else {
          overlays.add('BuildMenu');
        }
      }
    }
    return KeyEventResult.handled;
  }

  void pauseGame() {
    if (isGameOver || isPaused) return;
    isPaused = true;
    pauseEngine();
    overlays.add('PauseMenu');
  }

  void resumeGame() {
    if (!isPaused) return;
    isPaused = false;
    resumeEngine();
    overlays.remove('PauseMenu');
  }

  void restartGame() {
    world.removeAll(world.children.toList());
    camera.viewport.removeAll(camera.viewport.children.toList());
    overlays.clear();
    isGameOver = false;
    isPaused = false;
    selectedStructure = null;
    score = 0;
    _playSeconds = 0;
    resumeEngine();
    onLoad();
  }

  void _setGhostFromPosition(Vector2 position) {
    _cursorWorldPos = camera.globalToLocal(position);
    _ghostTileX = (_cursorWorldPos.x / kTileSize).floor();
    _ghostTileY = (_cursorWorldPos.y / kTileSize).floor();
  }

  void _updateGhostFromGlobalPosition(Vector2 globalPosition) {
    if (_pendingBuildType == null) return;
    _setGhostFromPosition(globalPosition);
  }

  void _updateCameraZoom(Vector2 viewportSize) {
    if (viewportSize.x <= 0 || viewportSize.y <= 0) return;

    final visibleTilesHigh = viewportSize.y < 400
        ? 8.5
        : viewportSize.y < 500
            ? 10.0
            : 12.0;

    camera.viewfinder.zoom =
        (viewportSize.y / (kTileSize * visibleTilesHigh)).clamp(1.15, 2.2);
  }

  Vector2 _footprintForBuild(BuildType build) {
    if (build.isWall) {
      return _wallOrientation == WallOrientation.horizontal
          ? Vector2(4, 1)
          : Vector2(1, 4);
    }
    if (build.isGate || build.isTower) {
      return Vector2.all(3);
    }
    return Vector2.all(1);
  }

  bool _canPlaceFootprint(int tx, int ty, double width, double height) {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final tileX = tx + x.toInt();
        final tileY = ty + y.toInt();
        final tile = tileMap.tileAt(tileX, tileY);
        if (tile == null || tile.occupied) return false;
        if (tile.type != TileType.grass && tile.type != TileType.sacred) {
          return false;
        }
        if (_intersectsHarSuld(tileX, tileY)) {
          return false;
        }
      }
    }
    return true;
  }

  bool _intersectsHarSuld(int tileX, int tileY) {
    final coreLeft =
        ((harSuld.position.x - harSuld.size.x / 2) / kTileSize).floor();
    final coreTop =
        ((harSuld.position.y - harSuld.size.y / 2) / kTileSize).floor();
    final coreWidth = (harSuld.size.x / kTileSize).round();
    final coreHeight = (harSuld.size.y / kTileSize).round();
    return tileX >= coreLeft &&
        tileX < coreLeft + coreWidth &&
        tileY >= coreTop &&
        tileY < coreTop + coreHeight;
  }

  void _setFootprintOccupied(
      int tx, int ty, double width, double height, bool value) {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        tileMap.setOccupied(tx + x.toInt(), ty + y.toInt(), value);
      }
    }
  }

  void _selectStructureAt(Vector2 worldPos) {
    PositionComponent? found;
    for (final comp in world.children) {
      if (comp is WallStructure ||
          comp is GateStructure ||
          comp is TowerStructure) {
        final structure = comp as PositionComponent;
        final rect = Rect.fromLTWH(
          structure.position.x,
          structure.position.y,
          structure.size.x,
          structure.size.y,
        );
        if (rect.contains(Offset(worldPos.x, worldPos.y))) {
          found = structure;
        }
      }
    }

    selectedStructure = found;
    if (found != null) {
      if (!overlays.isActive('StructureMenu')) {
        overlays.add('StructureMenu');
      }
    } else {
      overlays.remove('StructureMenu');
    }
  }

  bool repairSelectedStructure() {
    final structure = selectedStructure;
    if (structure == null) return false;
    if (_currentHp(structure) >= _maxHp(structure)) return false;

    if (!inventory.consumeConsumable(ConsumableType.harSuldRepairKit)) {
      return false;
    }

    player.playUtilityAction(duration: 0.32);
    if (structure is WallStructure) structure.repair(kRepairKitHp);
    if (structure is GateStructure) structure.repair(kRepairKitHp);
    if (structure is TowerStructure) structure.repair(kRepairKitHp);
    return true;
  }

  bool usePlayerHealthKit() {
    if (player.hp >= player.effectiveMaxHp) return false;
    if (!inventory.consumeConsumable(ConsumableType.playerHealthKit)) {
      return false;
    }
    player.heal(65);
    onPlayCustomSound?.call('player_heal');
    return true;
  }

  bool upgradeSelectedStructure() {
    final structure = selectedStructure;
    if (structure == null) return false;

    final current = _buildTypeForStructure(structure);
    final next = _nextBuildType(current);
    if (next == null || !inventory.spend(next.cost)) return false;

    if (structure is WallStructure) {
      final upgraded = WallStructure(
        tier: WallTier.values[_wallTierFromBuildType(next)],
        tileX: structure.tileX,
        tileY: structure.tileY,
        orientation: structure.orientation,
        onDestroyed: structure.onDestroyed,
      );
      world.add(upgraded);
      structure.removeFromParent();
      selectedStructure = upgraded;
      return true;
    }
    if (structure is GateStructure) {
      final upgraded = GateStructure(
        tier: GateTier.values[_gateTierFromBuildType(next)],
        tileX: structure.tileX,
        tileY: structure.tileY,
        onDestroyed: structure.onDestroyed,
      );
      world.add(upgraded);
      structure.removeFromParent();
      selectedStructure = upgraded;
      return true;
    }
    if (structure is TowerStructure) {
      final upgraded = TowerStructure(
        tier: TowerTier.values[_towerTierFromBuildType(next)],
        tileX: structure.tileX,
        tileY: structure.tileY,
        towerType: structure.towerType,
        getEnemies: _getAliveEnemies,
        onDestroyed: structure.onDestroyed,
      );
      world.add(upgraded);
      structure.removeFromParent();
      selectedStructure = upgraded;
      return true;
    }
    return false;
  }

  BuildType _buildTypeForStructure(PositionComponent structure) {
    if (structure is WallStructure) return structure.buildType;
    if (structure is GateStructure) return structure.buildType;
    if (structure is TowerStructure) return structure.buildType;
    throw ArgumentError('Unsupported structure type');
  }

  BuildType? _nextBuildType(BuildType current) {
    const walls = [
      BuildType.woodenWall,
      BuildType.cobbleWall,
      BuildType.ironWall,
      BuildType.steelWall,
      BuildType.sacredWall,
    ];
    const gates = [
      BuildType.woodenGate,
      BuildType.cobbleGate,
      BuildType.ironGate,
      BuildType.steelGate,
      BuildType.sacredGate,
    ];
    const towers = [
      BuildType.woodenTower,
      BuildType.cobbleTower,
      BuildType.ironTower,
      BuildType.steelTower,
      BuildType.sacredTower,
    ];

    final chain = current.isWall
        ? walls
        : current.isGate
            ? gates
            : towers;
    final index = chain.indexOf(current);
    if (index == -1 || index == chain.length - 1) return null;
    return chain[index + 1];
  }

  bool _canPlayerMoveTo(Vector2 nextPosition, bool mounted) {
    final collisionRect = Rect.fromCenter(
      center: Offset(nextPosition.x, nextPosition.y),
      width: mounted ? kTileSize * 1.15 : kTileSize * 0.8,
      height: mounted ? kTileSize * 1.15 : kTileSize * 0.8,
    );

    for (final structure in _blockingStructures()) {
      if (structure is GateStructure) continue;
      if (collisionRect.overlaps(_structureRect(structure))) {
        return false;
      }
    }
    return true;
  }

  PositionComponent? _findBlockingStructureForEnemy(
    BaseEnemy enemy,
    Vector2 nextPosition,
  ) {
    final collisionRect = Rect.fromCenter(
      center: Offset(nextPosition.x, nextPosition.y),
      width: enemy.size.x * 0.65,
      height: enemy.size.y * 0.65,
    );

    PositionComponent? blocker;
    double nearestDistance = double.infinity;

    for (final structure in _blockingStructures()) {
      final rect = _structureRect(structure);
      if (!collisionRect.overlaps(rect)) continue;

      final center = _structureCenter(structure);
      final distance = (center - enemy.position).length;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        blocker = structure;
      }
    }

    return blocker;
  }

  Iterable<PositionComponent> _blockingStructures() sync* {
    for (final child in world.children) {
      if (child is WallStructure && child.isAlive) yield child;
      if (child is GateStructure && child.isAlive) yield child;
      if (child is TowerStructure && child.isAlive) yield child;
    }
  }

  Rect _structureRect(PositionComponent structure) {
    return Rect.fromLTWH(
      structure.position.x,
      structure.position.y,
      structure.size.x,
      structure.size.y,
    );
  }

  Vector2 _structureCenter(PositionComponent structure) {
    if (structure is WallStructure) return structure.centerPoint;
    if (structure is GateStructure) return structure.centerPoint;
    if (structure is TowerStructure) return structure.centerPoint;
    return structure.position + structure.size / 2;
  }

  void _damageStructure(PositionComponent structure, double damage) {
    if (structure is WallStructure) structure.takeDamage(damage);
    if (structure is GateStructure) structure.takeDamage(damage);
    if (structure is TowerStructure) structure.takeDamage(damage);
  }

  double _currentHp(PositionComponent structure) {
    if (structure is WallStructure) return structure.hp;
    if (structure is GateStructure) return structure.hp;
    if (structure is TowerStructure) return structure.hp;
    return 0;
  }

  double _maxHp(PositionComponent structure) {
    if (structure is WallStructure) return structure.maxHp;
    if (structure is GateStructure) return structure.maxHp;
    if (structure is TowerStructure) return structure.maxHp;
    return 1;
  }
}
