import 'package:flutter/material.dart';
import 'flappy_bird_game.dart';
import 'start_screen.dart';

class GameOverScreen extends StatelessWidget {
  final FlappyBirdGame game;

  const GameOverScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final score = game.score;
    final best = game.bestScore;

    return Container(
      color: Colors.black.withOpacity(0.45),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Game Over banner ───────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8B0000), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Text(
                'GAME OVER',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 3,
                  shadows: [
                    Shadow(color: Color(0xFF8B0000), offset: Offset(2, 2)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Score panel ───────────────────────────────────
            Container(
              width: 220,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF5DEB3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC49A6C), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _ScoreRow(label: 'SCORE', value: score, highlight: true),
                  const SizedBox(height: 4),
                  const Divider(color: Color(0xFFC49A6C), height: 16),
                  _ScoreRow(label: 'BEST', value: best),
                  if (score > 0 && score == best)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFCC9900),
                          width: 2,
                        ),
                      ),
                      child: const Text(
                        '🏆 NEW BEST!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF5A3200),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Play Again button ──────────────────────────────
            GestureDetector(
              onTap: () {
                game.startGame(); // Тоглоом дахин эхлүүлэх
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 38,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6BD425), Color(0xFF3DA512)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: const Color(0xFF2A7A0A), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '▶  ',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      'PLAY AGAIN',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Color(0xFF1A5A00),
                            offset: Offset(1, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Back to Start button (Засварласан хувилбар) ───────────────────────────
            GestureDetector(
              onTap: () {
                // Апп-ийн үндсэн нүүр хуудас руу буцах
                Navigator.of(context).pop();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFF0055CC), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Text(
                  'BACK TO START',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int value;
  final bool highlight;

  const _ScoreRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF7A5C30),
            letterSpacing: 1,
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: highlight ? 26 : 18,
            color: highlight
                ? const Color(0xFF2E5F00)
                : const Color(0xFF7A5C30),
          ),
        ),
      ],
    );
  }
}
