import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame/game.dart';
import 'tetris_game.dart';
import '../constants/score_service.dart';
import '../constants/audio_service.dart';

class TetrisMainMenuWrapper extends StatefulWidget {
  const TetrisMainMenuWrapper({super.key});

  @override
  State<TetrisMainMenuWrapper> createState() => _TetrisMainMenuWrapperState();
}

class _TetrisMainMenuWrapperState extends State<TetrisMainMenuWrapper> {
  bool isPlaying = false;
  int highScore = 0;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _startMenuMusic();
  }

  Future<void> _startMenuMusic() async {
    await AudioService.init();
    await AudioService.playBgm(AudioService.bgmTetris);
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  void _onGameOver(int finalScore) async {
    // 🔊 Game over дуу
    await AudioService.playSfx(AudioService.sfxGameover);

    final prefs = await SharedPreferences.getInstance();
    if (finalScore > highScore) {
      await prefs.setInt('highScore', finalScore);
      setState(() => highScore = finalScore);
    }

    int playtime = 0;
    if (_startTime != null) {
      playtime = DateTime.now().difference(_startTime!).inSeconds;
    }
    ScoreService.submitScore(
      gameName: 'Tetris',
      score: finalScore,
      playtimeSeconds: playtime,
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => isPlaying = false);
        // Цэс рүү буцаад хөгжим дахин эхлүүлнэ
        AudioService.playBgm(AudioService.bgmTetris);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text("Tetris"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: isPlaying
          ? _TetrisPlayView(onGameOver: _onGameOver)
          : ArcadeHomeMenu(
              highScore: highScore,
              onStart: () {
                AudioService.playSfx(AudioService.sfxClick);
                _startTime = DateTime.now();
                setState(() => isPlaying = true);
              },
            ),
    );
  }
}

// ─── Tetris play view with mobile controls ───────────────────────────────────
class _TetrisPlayView extends StatefulWidget {
  final void Function(int) onGameOver;
  const _TetrisPlayView({required this.onGameOver});

  @override
  State<_TetrisPlayView> createState() => _TetrisPlayViewState();
}

class _TetrisPlayViewState extends State<_TetrisPlayView> {
  late final TetrisGame _game;

  @override
  void initState() {
    super.initState();
    _game = TetrisGame(onGameOver: widget.onGameOver);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GameWidget(game: _game),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _MobileControls(game: _game),
        ),
      ],
    );
  }
}

class _MobileControls extends StatelessWidget {
  final TetrisGame game;
  const _MobileControls({required this.game});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.black54,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _btn(Icons.arrow_back, () => game.moveLeft()),
                const SizedBox(width: 8),
                _btn(Icons.arrow_forward, () => game.moveRight()),
              ],
            ),
            Row(
              children: [
                _btn(Icons.rotate_right, () => game.rotatePiece()),
                const SizedBox(width: 8),
                _btn(Icons.arrow_downward, () => game.softDrop()),
                const SizedBox(width: 8),
                _btn(Icons.keyboard_double_arrow_down, () => game.hardDrop(),
                    color: Colors.cyanAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap, {Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}

// ─── Falling block data ───────────────────────────────────────────────────────
class _FallingBlock {
  double x;
  double y;
  double speed;
  double size;
  Color color;
  double opacity;

  _FallingBlock({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
    required this.opacity,
  });
}

// ─── Background painter ───────────────────────────────────────────────────────
class _BlocksPainter extends CustomPainter {
  final List<_FallingBlock> blocks;
  final double screenW;
  final double screenH;
  _BlocksPainter(this.blocks, this.screenW, this.screenH);

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in blocks) {
      final paint = Paint()..color = b.color.withOpacity(b.opacity);
      canvas.drawRect(Rect.fromLTWH(b.x, b.y, b.size, b.size), paint);
      final border = Paint()
        ..color = b.color.withOpacity(b.opacity * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRect(Rect.fromLTWH(b.x, b.y, b.size, b.size), border);
    }
  }

  @override
  bool shouldRepaint(_BlocksPainter old) => true;
}

// ─── Main Menu ────────────────────────────────────────────────────────────────
class ArcadeHomeMenu extends StatefulWidget {
  final int highScore;
  final VoidCallback onStart;

  const ArcadeHomeMenu({
    super.key,
    required this.highScore,
    required this.onStart,
  });

  @override
  State<ArcadeHomeMenu> createState() => _ArcadeHomeMenuState();
}

class _ArcadeHomeMenuState extends State<ArcadeHomeMenu>
    with TickerProviderStateMixin {
  late AnimationController _blocksCtrl;
  late AnimationController _logoCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _scoreCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _scoreAnim;

  final _rng = Random();
  final List<_FallingBlock> _blocks = [];
  final List<Color> _tetrColors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.cyan,
    Colors.blue,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();

    // Falling blocks ticker
    _blocksCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..repeat();
    _blocksCtrl.addListener(_updateBlocks);

    // Logo stagger
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    // Play button pulse
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.96, end: 1.04)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Score board slide
    _scoreCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scoreAnim = CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOutBack);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _scoreCtrl.forward();
    });

    // Spawn initial blocks
    for (int i = 0; i < 20; i++) _spawnBlock(randomY: true);
  }

  double _screenW = 400;
  double _screenH = 800;

  void _spawnBlock({bool randomY = false}) {
    _blocks.add(_FallingBlock(
      x: _rng.nextDouble() * _screenW,
      y: randomY ? _rng.nextDouble() * _screenH : -30,
      speed: 0.5 + _rng.nextDouble() * 1.2,
      size: 14 + _rng.nextDouble() * 18,
      color: _tetrColors[_rng.nextInt(_tetrColors.length)],
      opacity: 0.08 + _rng.nextDouble() * 0.12,
    ));
  }

  void _updateBlocks() {
    if (!mounted) return;
    setState(() {
      for (final b in _blocks) {
        b.y += b.speed;
      }
      _blocks.removeWhere((b) => b.y > _screenH + 30);
      while (_blocks.length < 20) {
        _spawnBlock();
      }
    });
  }

  @override
  void dispose() {
    _blocksCtrl.dispose();
    _logoCtrl.dispose();
    _pulseCtrl.dispose();
    _scoreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        _screenW = w;
        _screenH = h;

        return Stack(
          children: [
            // Animated falling blocks background — дэлгэцийн бодит хэмжээ
            CustomPaint(
              size: Size(w, h),
              painter: _BlocksPainter(_blocks, w, h),
            ),

            // Content — бүхэлдээ голлосон
            SizedBox(
              width: w,
              height: h,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),

                  // Animated TETRIS logo — голдоо
                  Center(child: _buildAnimatedLogo()),

                  const Spacer(),

                  // Pulsing PLAY button
                  Center(
                    child: ScaleTransition(
                      scale: _pulseAnim,
                      child: _buildPlayButton(),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Animated score board
                  Center(
                    child: ScaleTransition(
                      scale: _scoreAnim,
                      child: _buildScoreBoard(),
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedLogo() {
    final letters = ['T', 'E', 'T', 'R', 'I', 'S'];
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.cyan,
      Colors.purple,
    ];

    // Дэлгэцийн өргөнд тохируулсан хэмжээ
    final double logoFontSize = (_screenW * 0.11).clamp(32.0, 52.0);
    final double frameW = (_screenW * 0.68).clamp(200.0, 300.0);
    final double frameH = logoFontSize * 2.4;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Хүрээ
        Container(
          width: frameW,
          height: frameH,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue.shade800, width: 7),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        // Үсгүүд
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: letters.asMap().entries.map((e) {
            final delay = e.key * 0.12;
            return AnimatedBuilder(
              animation: _logoCtrl,
              builder: (context, child) {
                final t = ((_logoCtrl.value - delay) / (1 - delay)).clamp(0.0, 1.0);
                final curve = Curves.easeOutBack.transform(t);
                return Transform.translate(
                  offset: Offset(0, (1 - curve) * -40),
                  child: Opacity(opacity: t, child: child),
                );
              },
              child: Text(
                e.value,
                style: GoogleFonts.bungee(
                  fontSize: logoFontSize,
                  color: colors[e.key],
                  shadows: const [
                    Shadow(offset: Offset(3, 3), blurRadius: 3, color: Colors.black),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: widget.onStart,
      child: Container(
        width: 200,
        height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFEB3B), Color(0xFFFBC02D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFEB3B).withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            _screw(top: 5, left: 5), _screw(top: 5, right: 5),
            _screw(bottom: 5, left: 5), _screw(bottom: 5, right: 5),
            Center(
              child: Text(
                'PLAY',
                style: GoogleFonts.bungee(
                  fontSize: 40,
                  color: const Color(0xFF424242),
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 220,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF8D6E63),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFF5D4037), width: 4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8D6E63).withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'BEST SCORE',
                style: GoogleFonts.bungee(color: Colors.black, fontSize: 18),
              ),
              const Divider(
                color: Color(0xFF5D4037),
                thickness: 2,
                indent: 20,
                endIndent: 20,
              ),
              Text(
                '${widget.highScore}',
                style: GoogleFonts.bungee(color: Colors.white, fontSize: 35),
              ),
            ],
          ),
        ),
        Positioned(
          top: -25,
          child: Row(
            children: [
              Icon(Icons.star, color: Colors.yellow.shade700, size: 30),
              Icon(Icons.star, color: Colors.yellow.shade700, size: 45),
              Icon(Icons.star, color: Colors.yellow.shade700, size: 30),
            ],
          ),
        ),
      ],
    );
  }

  Widget _screw({double? top, double? bottom, double? left, double? right}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: 8, height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF424242),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
