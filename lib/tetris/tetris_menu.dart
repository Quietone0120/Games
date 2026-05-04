import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame/game.dart';
import 'package:flame/game.dart';
import 'tetris_game.dart';
import '../constants/score_service.dart';

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
  }

  _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  void _onGameOver(int finalScore) async {
    final prefs = await SharedPreferences.getInstance();
    if (finalScore > highScore) {
      await prefs.setInt('highScore', finalScore);
      setState(() {
        highScore = finalScore;
      });
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
    // Хожигдох үед 1.5 секундын дараа нүүр рүү буцна
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => isPlaying = false);
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
          ? GameWidget(game: TetrisGame(onGameOver: _onGameOver))
          : ArcadeHomeMenu(
              highScore: highScore,
              onStart: () {
                _startTime = DateTime.now();
                setState(() => isPlaying = true);
              },
            ),
    );
  }
}

class ArcadeHomeMenu extends StatelessWidget {
  final int highScore;
  final VoidCallback onStart;

  const ArcadeHomeMenu({
    super.key,
    required this.highScore,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFF0A0E21)),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // --- TETRIS LOGO WITH T-FRAME ---
          Stack(
            alignment: Alignment.topCenter,
            children: [
              // Blue T-Frame
              Container(
                margin: const EdgeInsets.only(top: 20),
                width: 250,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue.shade800, width: 8),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // The Logo Letters
              Container(
                padding: const EdgeInsets.all(15),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _logoLetter("T", Colors.red),
                    _logoLetter("E", Colors.orange),
                    _logoLetter("T", Colors.yellow),
                    _logoLetter("R", Colors.green),
                    _logoLetter("I", Colors.cyan),
                    _logoLetter("S", Colors.purple),
                  ],
                ),
              ),
            ],
          ),

          const Spacer(),

          // --- YELLOW PLAY BUTTON ---
          GestureDetector(
            onTap: onStart,
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
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Corner Screws
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
          ),

          const SizedBox(height: 40),

          // --- WOODEN SCORE BOARD ---
          Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              // Wooden Sign
              Container(
                width: 220,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF8D6E63),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xFF5D4037), width: 4),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://www.transparenttextures.com/patterns/wood-pattern.png',
                    ),
                    repeat: ImageRepeat.repeat,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'BEST SCORE',
                      style: GoogleFonts.bungee(
                        color: Colors.black,
                        fontSize: 18,
                      ),
                    ),
                    const Divider(
                      color: Color(0xFF5D4037),
                      thickness: 2,
                      indent: 20,
                      endIndent: 20,
                    ),
                    Text(
                      '$highScore',
                      style: GoogleFonts.bungee(
                        color: Colors.white,
                        fontSize: 35,
                      ),
                    ),
                  ],
                ),
              ),
              // Stars on top
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
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _logoLetter(String char, Color color) {
    return Text(
      char,
      style: GoogleFonts.bungee(
        fontSize: 45,
        color: color,
        shadows: [
          const Shadow(
            offset: Offset(3, 3),
            blurRadius: 3,
            color: Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _screw({double? top, double? bottom, double? left, double? right}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF424242),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
