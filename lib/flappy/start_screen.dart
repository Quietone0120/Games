import 'package:flutter/material.dart';
import 'flappy_bird_game.dart';

class StartScreen extends StatelessWidget {
  final FlappyBirdGame game;

  const StartScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: game.startGame,
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Title ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAD02E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCC9900), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      offset: const Offset(0, 5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Text('🐦', style: TextStyle(fontSize: 52)),
                    SizedBox(height: 6),
                    Text(
                      'FLAPPY BIRD',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF5A3200),
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Color(0xFFCC9900),
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              // ── Instructions ──────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Tap to Flap!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C6E00),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Avoid the pipes',
                      style: TextStyle(fontSize: 14, color: Color(0xFF555555)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ── Tap to start button ────────────────────────────
              _PulsingButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingButton extends StatefulWidget {
  @override
  State<_PulsingButton> createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<_PulsingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.96,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
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
        child: const Text(
          'TAP TO START',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
            shadows: [Shadow(color: Color(0xFF1A5A00), offset: Offset(1, 2))],
          ),
        ),
      ),
    );
  }
}
