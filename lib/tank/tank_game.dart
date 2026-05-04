import 'dart:async';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../constants/score_service.dart';

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

class _MainMenuState extends State<TankMainMenu> {
  final List<Color> tankColors = [
    Colors.greenAccent,
    Colors.blueAccent,
    Colors.orangeAccent,
    Colors.redAccent,
    Colors.yellowAccent,
  ];

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
          Expanded(
            flex: 2,
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
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "TANK WAR",
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    GameProgress.playerLives.value = 3;
                    GameProgress.enemiesLeft.value = 5;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GamePlayPage(),
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
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
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
                    ),
                  ),
                  const SizedBox(height: 20),
                  _tankIcon(),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: tankColors.map((c) => _colorBtn(c)).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapTile(int i) {
    bool sel = GameProgress.currentMapIndex == i;
    return ListTile(
      selected: sel,
      onTap: () => setState(() => GameProgress.currentMapIndex = i),
      title: Text(
        "MAP 0${i + 1}",
        style: TextStyle(color: sel ? Colors.amber : Colors.white),
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
    );
  }

  Widget _tankIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: GameProgress.selectedColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Center(
        child: Icon(Icons.shield, size: 50, color: Colors.black38),
      ),
    );
  }

  Widget _colorBtn(Color c) {
    return GestureDetector(
      onTap: () => setState(() => GameProgress.selectedColor = c),
      child: CircleAvatar(
        backgroundColor: c,
        radius: 20,
        child: GameProgress.selectedColor == c
            ? const Icon(Icons.check, color: Colors.black)
            : null,
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
            top: 20,
            left: 20,
            right: 20,
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
      bottom: 30,
      left: 30,
      right: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_joystick(game), _fireBtn(game, context)],
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

  @override
  Future<void> onLoad() async {
    add(ScreenHitbox());
    _loadMap();
    player = PlayerTank(position: Vector2(size.x / 2, size.y - 60));
    add(player);
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
      other.die();
      removeFromParent();
    } else if (!isPlayer && other is PlayerTank) {
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
