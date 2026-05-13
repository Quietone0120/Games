import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';
import '../utils/direction.dart';
import '../utils/animation_loader.dart';
import '../systems/inventory_system.dart';
import 'enemies/base_enemy.dart';
import 'projectile.dart';

enum PlayerState { idle, running, attacking, placing, dead }

enum PlayerTool { bow, pickaxe }

class Player extends PositionComponent with KeyboardHandler {
  // Stats
  double hp = kPlayerBaseHp;
  double maxHp = kPlayerBaseHp;
  int lives = kPlayerLives;
  int bowTier = 0;
  int armorTier = 0;
  bool onHorse = false;

  // Computed stats
  double get moveSpeed {
    final armorBonus = armorTier < kArmorTiers.length
        ? kArmorTiers[armorTier]['speedBonus']!
        : 0.0;
    return kPlayerBaseSpeed + armorBonus;
  }

  double get effectiveMaxHp {
    final armorBonus = armorTier < kArmorTiers.length
        ? kArmorTiers[armorTier]['hpBonus']!
        : 0.0;
    return kPlayerBaseHp + armorBonus;
  }

  double get bowDamage => kBowTiers[bowTier]['damage']!;
  double get bowInterval => kBowTiers[bowTier]['interval']!;
  double get bowRange => kBowTiers[bowTier]['range']! * kTileSize;
  double get bowArmorPierce => kBowTiers[bowTier]['armorPierce'] ?? 0.0;
  double get bowCritChance => kBowTiers[bowTier]['critChance'] ?? 0.0;

  // State
  PlayerState state = PlayerState.idle;
  Direction direction = Direction.south;

  // Build
  BuildType? selectedBuild;
  CraftedTowerType? selectedTowerType;
  PlayerTool activeTool = PlayerTool.bow;
  final List<BuildType?> blueprintSlots = List<BuildType?>.filled(6, null);
  final List<CraftedTowerType?> blueprintTowerTypes =
      List<CraftedTowerType?>.filled(6, null);
  final List<int> blueprintCounts = List<int>.filled(6, 0);
  int? selectedBlueprintSlot;

  // Animations
  Map<Direction, SpriteAnimation> _runAnims = {};
  Map<Direction, SpriteAnimation> _idleAnims = {};
  Map<Direction, SpriteAnimation> _bowAnims = {};
  Map<Direction, SpriteAnimation> _placeAnims = {};
  SpriteAnimation? _deathAnim;
  Map<Direction, SpriteAnimation> _onHorseRunAnims = {};
  Map<Direction, SpriteAnimation> _onHorseIdleAnims = {};

  SpriteAnimationComponent? _animComp;

  // Input
  Set<LogicalKeyboardKey> _keysPressed = {};
  Vector2 joystickDelta = Vector2.zero(); // set by game from JoystickComponent
  double _bowCooldown = 0;
  double _respawnTimer = 0;
  bool _isRespawning = false;
  double _utilityActionTimer = 0;

  // Callbacks
  void Function(double damage)? onHarSuldDamage;
  List<BaseEnemy> Function()? getEnemies;
  void Function(Projectile)? onProjectileSpawned;
  void Function()? onDeath;
  void Function()? onMountHorse;
  bool Function(Vector2 nextPosition, bool mounted)? canMoveTo;

  static const String _playerPath = 'HarSuld_designs/player';
  static const String _onHorsePath =
      'HarSuld_designs/horse/player_mounted_horse';

  Player()
      : super(
          position: kCenterPos.clone() + Vector2(0, kTileSize * 3),
          size: Vector2.all(kPlayerSpriteSize),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await _loadAnimations();
    final startAnim = _idleAnims[Direction.south] ?? _runAnims[Direction.south];
    if (startAnim != null) {
      _animComp = SpriteAnimationComponent(
        animation: startAnim,
        size: size,
        anchor: Anchor.center,
      );
      add(_animComp!);
    }
  }

  Future<void> _loadAnimations() async {
    try {
      _runAnims = await AnimationLoader.loadDirectionalAnimations(
        characterPath: _playerPath,
        animationName: 'Running',
        frameCount: 8,
        stepTime: 0.08,
      );
    } catch (_) {}
    try {
      _idleAnims = await AnimationLoader.loadDirectionalAnimations(
        characterPath: _playerPath,
        animationName: 'Breathing_Idle',
        frameCount: 4,
        stepTime: 0.25,
      );
    } catch (_) {}
    try {
      _bowAnims = await AnimationLoader.loadDirectionalAnimations(
        characterPath: _playerPath,
        animationName: 'Bow_attack',
        frameCount: 17,
        stepTime: 0.055,
        dirFolderOverrides: {Direction.southWest: 'south-west-883226e0'},
      );
    } catch (_) {}
    try {
      _placeAnims = await AnimationLoader.loadDirectionalAnimations(
        characterPath: _playerPath,
        animationName: 'Place_structure',
        frameCount: 5,
        stepTime: 0.12,
      );
    } catch (_) {}
    try {
      _deathAnim = await AnimationLoader.loadFrameSequence(
        basePath: '$_playerPath/animations/Falling_Back_Death/south',
        frameCount: 7,
        stepTime: 0.10,
        loop: false,
      );
    } catch (_) {}
    try {
      _onHorseRunAnims = await AnimationLoader.loadDirectionalAnimations(
        characterPath: _onHorsePath,
        animationName: 'running_with_horse',
        frameCount: 8,
        stepTime: 0.07,
      );
    } catch (_) {}
    try {
      _onHorseIdleAnims = await AnimationLoader.loadDirectionalAnimations(
        characterPath: _onHorsePath,
        animationName: 'Idle_Shaking_Head',
        frameCount: 11,
        stepTime: 0.10,
      );
    } catch (_) {}
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keysPressed = keysPressed;

    if (event is KeyDownEvent) {
      // Mount/dismount horse
      if (event.logicalKey == LogicalKeyboardKey.keyE) {
        _toggleMount();
      }
      // Dismount automatically when doing actions
      if (onHorse &&
          (event.logicalKey == LogicalKeyboardKey.keyF ||
              event.logicalKey == LogicalKeyboardKey.keyR)) {
        _dismount();
      }
    }
    return true;
  }

  void _toggleMount() {
    if (onHorse) {
      _dismount();
    } else {
      _mount();
    }
  }

  void mountExternal() => _mount();
  void dismountExternal() => _dismount();
  void equipTool(PlayerTool tool) => activeTool = tool;
  int _findBlueprintSlot(BuildType type, CraftedTowerType towerType) {
    for (int i = 0; i < blueprintSlots.length; i++) {
      if (blueprintSlots[i] == type &&
          (type.isTower ? blueprintTowerTypes[i] == towerType : true) &&
          blueprintCounts[i] > 0) {
        return i;
      }
    }
    return -1;
  }

  int craftBlueprint(
    BuildType type, {
    CraftedTowerType towerType = CraftedTowerType.human,
  }) {
    final existingIndex = _findBlueprintSlot(type, towerType);
    if (existingIndex != -1) {
      blueprintCounts[existingIndex]++;
      selectedBlueprintSlot = existingIndex;
      selectedBuild = type;
      selectedTowerType = type.isTower ? towerType : null;
      return existingIndex;
    }

    final emptyIndex = blueprintSlots.indexOf(null);
    final targetIndex = emptyIndex != -1
        ? emptyIndex
        : (selectedBlueprintSlot ?? (blueprintSlots.length - 1));

    blueprintSlots[targetIndex] = type;
    blueprintTowerTypes[targetIndex] = type.isTower ? towerType : null;
    blueprintCounts[targetIndex] = 1;
    selectedBlueprintSlot = targetIndex;
    selectedBuild = type;
    selectedTowerType = type.isTower ? towerType : null;
    return targetIndex;
  }

  int assignBlueprint(
    BuildType type, {
    CraftedTowerType towerType = CraftedTowerType.human,
  }) {
    final existingIndex = _findBlueprintSlot(type, towerType);
    if (existingIndex != -1) {
      selectedBlueprintSlot = existingIndex;
      selectedBuild = type;
      selectedTowerType = type.isTower ? towerType : null;
      return existingIndex;
    }

    final emptyIndex = blueprintSlots.indexOf(null);
    final targetIndex = emptyIndex != -1
        ? emptyIndex
        : (selectedBlueprintSlot ?? (blueprintSlots.length - 1));

    blueprintSlots[targetIndex] = type;
    blueprintTowerTypes[targetIndex] = type.isTower ? towerType : null;
    blueprintCounts[targetIndex] =
        blueprintCounts[targetIndex] == 0 ? 1 : blueprintCounts[targetIndex];
    selectedBlueprintSlot = targetIndex;
    selectedBuild = type;
    selectedTowerType = type.isTower ? towerType : null;
    return targetIndex;
  }

  void selectBlueprintSlot(int index) {
    final build = blueprintSlots[index];
    final count = blueprintCounts[index];
    selectedBlueprintSlot = build == null || count <= 0 ? null : index;
    selectedBuild = count <= 0 ? null : build;
    selectedTowerType = count <= 0 ? null : blueprintTowerTypes[index];
  }

  void clearSelectedBlueprint() {
    selectedBlueprintSlot = null;
    selectedBuild = null;
    selectedTowerType = null;
  }

  bool consumeSelectedBlueprint() {
    final index = selectedBlueprintSlot;
    if (index == null || blueprintCounts[index] <= 0) return false;

    blueprintCounts[index]--;
    if (blueprintCounts[index] <= 0) {
      blueprintSlots[index] = null;
      blueprintTowerTypes[index] = null;
      blueprintCounts[index] = 0;
      clearSelectedBlueprint();
    }
    return true;
  }

  void _mount() {
    onHorse = true;
    onMountHorse?.call();
    _updateAnimation();
  }

  void _dismount() {
    onHorse = false;
    _updateAnimation();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isRespawning) {
      _respawnTimer -= dt;
      if (_respawnTimer <= 0) _respawn();
      return;
    }

    if (state == PlayerState.dead) return;

    _updateUtilityAction(dt);
    _handleMovement(dt);
    _handleBowAttack(dt);
  }

  void _updateUtilityAction(double dt) {
    if (_utilityActionTimer <= 0) return;

    _utilityActionTimer -= dt;
    if (_utilityActionTimer <= 0 && state == PlayerState.placing) {
      state = joystickDelta.length > 0.1 || _keysPressed.isNotEmpty
          ? PlayerState.running
          : PlayerState.idle;
      _updateAnimation();
    }
  }

  void _handleMovement(double dt) {
    final vel = Vector2.zero();
    if (_keysPressed.contains(LogicalKeyboardKey.keyW) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      vel.y -= 1;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.keyS) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      vel.y += 1;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.keyA) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      vel.x -= 1;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.keyD) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      vel.x += 1;
    }

    // Merge joystick input (takes priority if keyboard is idle)
    if (vel.isZero() && joystickDelta.length > 0.1) {
      vel.setFrom(joystickDelta);
    }

    final isMoving = vel.x != 0 || vel.y != 0;

    if (isMoving) {
      vel.normalize();
      final speed = onHorse ? kHorseSpeed : moveSpeed;
      final desiredPosition = position + vel * speed * dt;
      final canMoveFreely =
          canMoveTo == null || canMoveTo!(desiredPosition, onHorse);

      if (canMoveFreely) {
        position.setFrom(desiredPosition);
      } else {
        final xOnly = position + Vector2(vel.x * speed * dt, 0);
        if (canMoveTo == null || canMoveTo!(xOnly, onHorse)) {
          position.setFrom(xOnly);
        }

        final yOnly = position + Vector2(0, vel.y * speed * dt);
        if (canMoveTo == null || canMoveTo!(yOnly, onHorse)) {
          position.setFrom(yOnly);
        }
      }

      position.x = position.x.clamp(kTileSize, kMapPixelSize - kTileSize);
      position.y = position.y.clamp(kTileSize, kMapPixelSize - kTileSize);

      final newDir = DirectionExt.fromVector(vel);
      if (newDir != direction || state == PlayerState.idle) {
        direction = newDir;
        if (state != PlayerState.attacking && state != PlayerState.placing) {
          state = PlayerState.running;
          _updateAnimation();
        }
      }
    } else {
      if (state == PlayerState.running) {
        state = PlayerState.idle;
        _updateAnimation();
      }
    }
  }

  void _handleBowAttack(double dt) {
    if (onHorse) return; // No shooting while onHorse
    if (state == PlayerState.dead) return;
    if (_utilityActionTimer > 0) return;

    _bowCooldown -= dt;
    if (_bowCooldown > 0) return;

    final enemies = getEnemies?.call() ?? [];
    BaseEnemy? nearestTarget;
    double nearestDist = bowRange;

    // Priority: closest to Har Suld → siege → nearest
    for (final enemy in enemies) {
      if (enemy.isDead) continue;
      final dist = (enemy.position - position).length;
      if (dist < nearestDist) {
        nearestDist = dist;
        nearestTarget = enemy;
      }
    }

    if (nearestTarget != null) {
      // Face target
      final toTarget = (nearestTarget.position - position);
      direction = DirectionExt.fromVector(toTarget);
      state = PlayerState.attacking;
      _updateAnimation();

      // Crit check
      final rng = Random();
      double finalDamage = bowDamage;
      if (rng.nextDouble() < bowCritChance) finalDamage *= 2;

      final proj = Projectile(
        start: position.clone(),
        target: nearestTarget,
        damage: finalDamage,
      );
      onProjectileSpawned?.call(proj);
      _bowCooldown = bowInterval;
    } else {
      if (state == PlayerState.attacking) {
        state = (_keysPressed.isEmpty) ? PlayerState.idle : PlayerState.running;
        _updateAnimation();
      }
    }
  }

  void _updateAnimation() {
    if (_animComp == null) return;

    SpriteAnimation? anim;
    if (onHorse) {
      anim = state == PlayerState.running
          ? (_onHorseRunAnims[direction] ?? _onHorseRunAnims[Direction.south])
          : (_onHorseIdleAnims[direction] ??
              _onHorseIdleAnims[Direction.south]);
    } else {
      switch (state) {
        case PlayerState.idle:
          anim = _idleAnims[direction] ?? _idleAnims[Direction.south];
          break;
        case PlayerState.running:
          anim = _runAnims[direction] ?? _runAnims[Direction.south];
          break;
        case PlayerState.attacking:
          anim = _bowAnims[direction] ?? _bowAnims[Direction.south];
          break;
        case PlayerState.placing:
          anim = _placeAnims[direction] ?? _placeAnims[Direction.south];
          break;
        case PlayerState.dead:
          anim = _deathAnim;
          break;
      }
    }

    if (anim != null && _animComp!.animation != anim) {
      _animComp!.animation = anim;
    }
  }

  void takeDamage(double dmg) {
    if (state == PlayerState.dead) return;
    final armorReduction = armorTier < kArmorTiers.length
        ? kArmorTiers[armorTier]['reduction']!
        : 0.05;
    final absorbed = dmg * (1 - armorReduction);
    hp -= absorbed;
    if (hp <= 0) _die();
  }

  void _die() {
    lives--;
    state = PlayerState.dead;
    _animComp?.animation = _deathAnim;
    onDeath?.call();

    if (lives > 0) {
      _isRespawning = true;
      _respawnTimer = kPlayerRespawnTime;
    }
    // If lives == 0, the game handles game over
  }

  void _respawn() {
    _isRespawning = false;
    state = PlayerState.idle;
    hp = effectiveMaxHp;
    position = kCenterPos.clone() + Vector2(0, kTileSize * 3);
    _updateAnimation();
  }

  void heal(double amount) {
    hp = min(effectiveMaxHp, hp + amount);
  }

  void playUtilityAction({double duration = 0.35}) {
    if (state == PlayerState.dead) return;

    activeTool = PlayerTool.pickaxe;
    _utilityActionTimer = duration;
    state = PlayerState.placing;
    _updateAnimation();
  }

  @override
  void render(Canvas canvas) {
    if (_animComp == null) {
      // Fallback
      canvas.drawCircle(
          Offset.zero, 20, Paint()..color = const Color(0xFF4488FF));
    }
    // HP bar
    if (hp < effectiveMaxHp) {
      final barW = size.x;
      const barH = 5.0;
      canvas.drawRect(
        Rect.fromLTWH(-barW / 2, -size.y / 2 - 10, barW, barH),
        Paint()..color = const Color(0xFF330000),
      );
      canvas.drawRect(
        Rect.fromLTWH(
            -barW / 2, -size.y / 2 - 10, barW * (hp / effectiveMaxHp), barH),
        Paint()..color = const Color(0xFF44FF44),
      );
    }
  }
}
