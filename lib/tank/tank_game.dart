import 'dart:async';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/score_service.dart';
import '../constants/audio_service.dart';

// --- Global State ---
class GameProgress {
  static Map<int, int> mapStars = {0: 0, 1: 0, 2: 0};
  static Color selectedColor = Colors.greenAccent;
  static int currentMapIndex = 0;
  static ValueNotifier<int> playerLives = ValueNotifier(3);
  static ValueNotifier<int> enemiesLeft = ValueNotifier(5);
}

// --- MAIN MENU ---
class TankMainMenu extends StatefulWidget {
  const TankMainMenu({super.key});
  @override
  State<TankMainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<TankMainMenu> with TickerProviderStateMixin {
  final List<Color> tankColors = [
    Colors.greenAccent,
    Colors.blueAccent,
    Colors.orangeAccent,
    Colors.redAccent,
    Colors.yellowAccent,
  ];

  late AnimationController _titleCtrl;
  late AnimationController _btnCtrl;
  late AnimationController _tankCtrl;
  late AnimationController _slideCtrl;

  late Animation<double> _titleGlow;
  late Animation<double> _titleScale;
  late Animation<double> _btnPulse;
  late Animation<double> _tankFloat;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initAudio();

    _titleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _titleGlow = Tween<double>(begin: 4.0, end: 22.0)
        .animate(CurvedAnimation(parent: _titleCtrl, curve: Curves.easeInOut));
    _titleScale = Tween<double>(begin: 0.97, end: 1.03)
        .animate(CurvedAnimation(parent: _titleCtrl, curve: Curves.easeInOut));

    _btnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _btnPulse = Tween<double>(begin: 0.95, end: 1.06)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOut));

    _tankCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _tankFloat = Tween<double>(begin: -8.0, end: 8.0)
        .animate(CurvedAnimation(parent: _tankCtrl, curve: Curves.easeInOut));

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _slideAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutBack);
  }

  Future<void> _initAudio() async {
    await AudioService.init();
    await AudioService.playBgm(AudioService.bgmTank);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _titleCtrl.dispose();
    _btnCtrl.dispose();
    _tankCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tank Game"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF121212),
      body: Row(
        children: [
          // MISSIONS panel
          Expanded(
            flex: 2,
            child: AnimatedBuilder(
              animation: _slideAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset((1 - _slideAnim.value) * -80, 0),
                child: Opacity(opacity: _slideAnim.value, child: child),
              ),
              child: Container(
                color: Colors.black26,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        "MISSIONS",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: 3,
                        itemBuilder: (context, i) => _mapTile(i),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // CENTER panel
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing pulsing title
                AnimatedBuilder(
                  animation: _titleCtrl,
                  builder: (_, __) => Transform.scale(
                    scale: _titleScale.value,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.4),
                            blurRadius: _titleGlow.value,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Text(
                        "TANK WAR",
                        style: TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.amber,
                              blurRadius: 12,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Pulsing START GAME button
                AnimatedBuilder(
                  animation: _btnCtrl,
                  builder: (_, child) => Transform.scale(
                    scale: _btnPulse.value,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.5),
                            blurRadius: 16 * _btnPulse.value,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      AudioService.playSfx(AudioService.sfxClick);
                      GameProgress.playerLives.value = 3;
                      GameProgress.enemiesLeft.value = 5;
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, anim, __) => const GamePlayPage(),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(opacity: anim, child: child),
                          transitionDuration: const Duration(milliseconds: 400),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 20,
                      ),
                    ),
                    child: const Text(
                      "START GAME",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // GARAGE panel
          Expanded(
            flex: 2,
            child: AnimatedBuilder(
              animation: _slideAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset((1 - _slideAnim.value) * 80, 0),
                child: Opacity(opacity: _slideAnim.value, child: child),
              ),
              child: Container(
                color: Colors.black26,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "GARAGE",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyan,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _animatedTankIcon(),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: tankColors.asMap().entries.map((e) =>
                          _colorBtn(e.value, e.key)).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapTile(int i) {
    bool sel = GameProgress.currentMapIndex == i;
    return AnimatedBuilder(
      animation: _slideAnim,
      builder: (_, child) {
        final delay = (i * 0.15).clamp(0.0, 0.5);
        final t = ((_slideAnim.value - delay) / (1 - delay)).clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset((1 - t) * -40, 0),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: ListTile(
        selected: sel,
        onTap: () => setState(() => GameProgress.currentMapIndex = i),
        selectedTileColor: Colors.amber.withOpacity(0.1),
        title: Text(
          "MAP 0${i + 1}",
          style: TextStyle(
            color: sel ? Colors.amber : Colors.white,
            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Row(
          children: List.generate(
            3,
            (index) => Icon(
              Icons.star,
              size: 16,
              color: index < GameProgress.mapStars[i]!
                  ? Colors.amber
                  : Colors.grey,
            ),
          ),
        ),
        leading: Icon(Icons.map, color: sel ? Colors.amber : Colors.white24),
      ),
    );
  }

  Widget _animatedTankIcon() {
    return AnimatedBuilder(
      animation: _tankCtrl,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _tankFloat.value),
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: GameProgress.selectedColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: GameProgress.selectedColor.withOpacity(0.5),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.shield, size: 50, color: Colors.black38),
          ),
        ),
      ),
    );
  }

  Widget _colorBtn(Color c, int idx) {
    final isSelected = GameProgress.selectedColor == c;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + idx * 80),
      curve: Curves.easeOutBack,
      builder: (_, val, child) => Transform.scale(scale: val, child: child),
      child: GestureDetector(
        onTap: () => setState(() => GameProgress.selectedColor = c),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isSelected ? 44 : 38,
          height: isSelected ? 44 : 38,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            boxShadow: isSelected
                ? [BoxShadow(color: c.withOpacity(0.7), blurRadius: 12, spreadRadius: 2)]
                : [],
            border: isSelected
                ? Border.all(color: Colors.white, width: 2.5)
                : null,
          ),
          child: isSelected
              ? const Icon(Icons.check, color: Colors.black, size: 20)
              : null,
        ),
      ),
    );
  }
}

// --- GAMEPLAY PAGE ---
class GamePlayPage extends StatefulWidget {
  const GamePlayPage({super.key});

  @override
  State<GamePlayPage> createState() => _GamePlayPageState();
}

class _GamePlayPageState extends State<GamePlayPage> {
  final game = TankGame();
  final DateTime _startTime = DateTime.now();
  bool _scoreSubmitted = false;

  @override
  void initState() {
    super.initState();
    GameProgress.playerLives.addListener(_checkGameOver);
    GameProgress.enemiesLeft.addListener(_checkGameOver);
  }

  @override
  void dispose() {
    GameProgress.playerLives.removeListener(_checkGameOver);
    GameProgress.enemiesLeft.removeListener(_checkGameOver);
    super.dispose();
  }

  void _checkGameOver() {
    if ((GameProgress.playerLives.value <= 0 || GameProgress.enemiesLeft.value <= 0) && !_scoreSubmitted) {
      _submitScore();
    }
  }

  void _submitScore() {
    if (_scoreSubmitted) return;
    _scoreSubmitted = true;
    
    int playtime = DateTime.now().difference(_startTime).inSeconds;
    int enemiesKilled = 5 - GameProgress.enemiesLeft.value; // initial 5
    int score = enemiesKilled * 100;
    
    ScoreService.submitScore(
      gameName: 'Tank War',
      score: score,
      playtimeSeconds: playtime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: game),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ValueListenableBuilder(
                      valueListenable: GameProgress.playerLives,
                      builder: (context, val, _) =>
                          _statChip("LIVES: $val", Colors.green, Icons.favorite),
                    ),
                    ValueListenableBuilder(
                      valueListenable: GameProgress.enemiesLeft,
                      builder: (context, val, _) =>
                          _statChip("ENEMIES: $val", Colors.red, Icons.adb),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _controls(game, context),
        ],
      ),
    );
  }

  Widget _statChip(String label, Color col, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: col),
      ),
      child: Row(
        children: [
          Icon(icon, color: col, size: 20),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _controls(TankGame game, BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_joystick(game), _fireBtn(game, context)],
          ),
        ),
      ),
    );
  }

  Widget _joystick(TankGame game) {
    return Column(
      children: [
        _btn(
          Icons.arrow_drop_up,
          () => game.player.moveDir = Direction.up,
          () => game.player.moveDir = null,
        ),
        Row(
          children: [
            _btn(
              Icons.arrow_left,
              () => game.player.moveDir = Direction.left,
              () => game.player.moveDir = null,
            ),
            const SizedBox(width: 50),
            _btn(
              Icons.arrow_right,
              () => game.player.moveDir = Direction.right,
              () => game.player.moveDir = null,
            ),
          ],
        ),
        _btn(
          Icons.arrow_drop_down,
          () => game.player.moveDir = Direction.down,
          () => game.player.moveDir = null,
        ),
      ],
    );
  }

  Widget _btn(IconData icon, Function() down, Function() up) {
    return GestureDetector(
      onTapDown: (_) => down(),
      onTapUp: (_) => up(),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 40),
      ),
    );
  }

  Widget _fireBtn(TankGame game, BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => game.player.fire(),
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text("FIRE")),
          ),
        ),
        const SizedBox(height: 20),
        IconButton(
          onPressed: () {
            _submitScore();
            Navigator.pop(context);
          },
          icon: const Icon(Icons.close, size: 30),
        ),
      ],
    );
  }
}

// --- FLAME ENGINE ---
enum Direction { up, down, left, right }

class TankGame extends FlameGame with HasCollisionDetection {
  late PlayerTank player;
  int spawnedEnemies = 0;
  double spawnTimer = 0;
  bool _initialized = false;

  @override
  Future<void> onLoad() async {
    add(ScreenHitbox());
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!_initialized && size.x > 0 && size.y > 0) {
      _initialized = true;
      _loadMap();
      player = PlayerTank(position: Vector2(size.x / 2, size.y - 60));
      add(player);
    }
  }

  void _loadMap() {
    double w = size.x;
    double h = size.y;
    int map = GameProgress.currentMapIndex;
    if (map == 0) {
      for (int i = 0; i < 5; i++) {
        add(Wall(position: Vector2(w * 0.2 + i * 60, h * 0.4)));
        add(Wall(position: Vector2(w * 0.8 - i * 60, h * 0.6)));
      }
    } else if (map == 1) {
      for (int i = 0; i < 6; i++) {
        add(Wall(position: Vector2(w * 0.5, h * 0.2 + i * 60)));
        add(Wall(position: Vector2(w * 0.3, h * 0.5)));
        add(Wall(position: Vector2(w * 0.7, h * 0.5)));
      }
    } else {
      for (int i = 0; i < 4; i++) {
        add(Wall(position: Vector2(100.0 + i * 100, 150.0 + i * 100)));
        add(Wall(position: Vector2(w - 100 - i * 100, 150.0 + i * 100)));
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    spawnTimer += dt;
    if (spawnTimer > 3 && spawnedEnemies < 5) {
      add(
        EnemyTank(
          position: Vector2(Random().nextDouble() * (size.x - 60) + 30, 50),
        ),
      );
      spawnedEnemies++;
      spawnTimer = 0;
    }
  }
}

// --- COMPONENTS ---
abstract class Tank extends PositionComponent
    with CollisionCallbacks, HasGameRef<TankGame> {
  Direction facing = Direction.up;
  double speed = 120;
  Color color;

  Tank({required super.position, required this.color})
    : super(size: Vector2.all(40), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // ЭНД ХИТБОКС НЭМСНЭЭР МӨРГӨЛДӨӨН МЭДЭРДЭГ БОЛНО
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final p = Paint()..color = color;
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    if (facing == Direction.down) canvas.rotate(pi);
    if (facing == Direction.left) canvas.rotate(-pi / 2);
    if (facing == Direction.right) canvas.rotate(pi / 2);
    canvas.translate(-size.x / 2, -size.y / 2);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), p);
    canvas.drawRect(Rect.fromLTWH(size.x / 2 - 3, -10, 6, 20), p);
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      10,
      Paint()..color = Colors.black26,
    );
    canvas.restore();
  }

  void fire() {
    AudioService.playSfx(AudioService.sfxShoot); // 🔊 буудах дуу
    gameRef.add(
      Bullet(
        position: position.clone(),
        direction: facing,
        isPlayer: this is PlayerTank,
      ),
    );
  }
}

class PlayerTank extends Tank {
  Direction? moveDir;
  PlayerTank({required super.position})
    : super(color: GameProgress.selectedColor);

  @override
  void update(double dt) {
    super.update(dt);
    if (moveDir != null) {
      facing = moveDir!;
      Vector2 next = position + _getDelta(dt);
      if (next.x > 20 &&
          next.x < gameRef.size.x - 20 &&
          next.y > 20 &&
          next.y < gameRef.size.y - 20) {
        position = next;
      }
    }
  }

  Vector2 _getDelta(double dt) {
    if (facing == Direction.up) return Vector2(0, -speed * dt);
    if (facing == Direction.down) return Vector2(0, speed * dt);
    if (facing == Direction.left) return Vector2(-speed * dt, 0);
    return Vector2(speed * dt, 0);
  }

  void hit() {
    GameProgress.playerLives.value--;
    if (GameProgress.playerLives.value > 0) {
      position = Vector2(gameRef.size.x / 2, gameRef.size.y - 60);
    } else {
      removeFromParent();
    }
  }
}

class EnemyTank extends Tank {
  double aiTime = 0;
  EnemyTank({required super.position}) : super(color: Colors.redAccent) {
    speed = 80;
    facing = Direction.down;
  }

  @override
  void update(double dt) {
    super.update(dt);
    aiTime += dt;
    if (aiTime > 2) {
      facing = Direction.values[Random().nextInt(4)];
      if (Random().nextBool()) fire();
      aiTime = 0;
    }
    position += _getDelta(dt);
    if (position.x < 20 ||
        position.x > gameRef.size.x - 20 ||
        position.y < 20 ||
        position.y > gameRef.size.y - 20) {
      facing = Direction.values[Random().nextInt(4)];
    }
  }

  Vector2 _getDelta(double dt) {
    if (facing == Direction.up) return Vector2(0, -speed * dt);
    if (facing == Direction.down) return Vector2(0, speed * dt);
    if (facing == Direction.left) return Vector2(-speed * dt, 0);
    return Vector2(speed * dt, 0);
  }

  void die() {
    GameProgress.enemiesLeft.value--;
    if (GameProgress.enemiesLeft.value == 0) {
      GameProgress.mapStars[GameProgress.currentMapIndex] = 3;
    }
    removeFromParent();
  }
}

class Bullet extends RectangleComponent
    with CollisionCallbacks, HasGameRef<TankGame> {
  final Direction direction;
  final bool isPlayer;
  Bullet({
    required Vector2 position,
    required this.direction,
    required this.isPlayer,
  }) : super(position: position, size: Vector2.all(6), anchor: Anchor.center);

  @override
  void onLoad() {
    paint.color = isPlayer ? Colors.white : Colors.yellow;
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    double s = 300;
    if (direction == Direction.up) position.y -= s * dt;
    if (direction == Direction.down) position.y += s * dt;
    if (direction == Direction.left) position.x -= s * dt;
    if (direction == Direction.right) position.x += s * dt;
    if (position.y < 0 ||
        position.y > gameRef.size.y ||
        position.x < 0 ||
        position.x > gameRef.size.x) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> pts, PositionComponent other) {
    super.onCollisionStart(pts, other);
    if (isPlayer && other is EnemyTank) {
      AudioService.playSfx(AudioService.sfxExplode); // 🔊 дэлбэрэх дуу
      other.die();
      removeFromParent();
    } else if (!isPlayer && other is PlayerTank) {
      AudioService.playSfx(AudioService.sfxExplode); // 🔊 өөрийн танк цохигдох
      other.hit();
      removeFromParent();
    } else if (other is Wall) {
      removeFromParent();
    }
  }
}

class Wall extends RectangleComponent with CollisionCallbacks {
  Wall({required Vector2 position})
    : super(position: position, size: Vector2.all(40), anchor: Anchor.center);
  @override
  void onLoad() {
    paint.color = Colors.grey[700]!;
    add(RectangleHitbox());
  }
}
