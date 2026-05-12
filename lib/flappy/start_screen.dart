import 'dart:math';
import 'package:flutter/material.dart';
import 'flappy_bird_game.dart';

class StartScreen extends StatefulWidget {
  final FlappyBirdGame game;
  const StartScreen({super.key, required this.game});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> with TickerProviderStateMixin {
  late AnimationController _birdCtrl;
  late AnimationController _titleCtrl;
  late AnimationController _btnCtrl;
  late AnimationController _particleCtrl;

  late Animation<double> _birdFloat;
  late Animation<double> _birdTilt;
  late Animation<double> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<double> _btnPulse;
  late Animation<double> _btnGlow;

  final _rng = Random();
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();

    // Bird floating up/down
    _birdCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _birdFloat = Tween<double>(begin: -12.0, end: 12.0)
        .animate(CurvedAnimation(parent: _birdCtrl, curve: Curves.easeInOut));
    _birdTilt = Tween<double>(begin: -0.12, end: 0.12)
        .animate(CurvedAnimation(parent: _birdCtrl, curve: Curves.easeInOut));

    // Title drop-in
    _titleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _titleSlide = Tween<double>(begin: -60.0, end: 0.0)
        .animate(CurvedAnimation(parent: _titleCtrl, curve: Curves.easeOutBack));
    _titleFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _titleCtrl, curve: Curves.easeIn));

    // Button pulse + glow
    _btnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _btnPulse = Tween<double>(begin: 0.96, end: 1.05)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOut));
    _btnGlow = Tween<double>(begin: 4.0, end: 18.0)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOut));

    // Particle ticker
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..repeat();
    _particleCtrl.addListener(_updateParticles);

    for (int i = 0; i < 18; i++) _spawnParticle(randomY: true);
  }

  void _spawnParticle({bool randomY = false}) {
    _particles.add(_Particle(
      x: _rng.nextDouble() * 400,
      y: randomY ? _rng.nextDouble() * 700 : 720.0,
      speed: 0.4 + _rng.nextDouble() * 0.7,
      size: 2.0 + _rng.nextDouble() * 4.0,
      opacity: 0.15 + _rng.nextDouble() * 0.25,
    ));
  }

  void _updateParticles() {
    if (!mounted) return;
    setState(() {
      for (final p in _particles) p.y -= p.speed;
      _particles.removeWhere((p) => p.y < -10);
      while (_particles.length < 18) _spawnParticle();
    });
  }

  @override
  void dispose() {
    _birdCtrl.dispose();
    _titleCtrl.dispose();
    _btnCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.game.startGame,
      child: Stack(
        children: [
          // Floating particles
          CustomPaint(
            size: Size(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height,
            ),
            painter: _ParticlePainter(_particles),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Floating bird
                AnimatedBuilder(
                  animation: _birdCtrl,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _birdFloat.value),
                    child: Transform.rotate(
                      angle: _birdTilt.value,
                      child: const Text('🐦', style: TextStyle(fontSize: 64)),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Animated title
                AnimatedBuilder(
                  animation: _titleCtrl,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _titleSlide.value),
                    child: Opacity(opacity: _titleFade.value, child: child),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAD02E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCC9900), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFEB3B).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 3,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          offset: const Offset(0, 5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Text(
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
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Instruction box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
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

                // Pulsing glow button
                AnimatedBuilder(
                  animation: _btnCtrl,
                  builder: (_, child) => Transform.scale(
                    scale: _btnPulse.value,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6BD425).withOpacity(0.5),
                            blurRadius: _btnGlow.value,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  ),
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
                    ),
                    child: const Text(
                      'TAP TO START',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(color: Color(0xFF1A5A00), offset: Offset(1, 2)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  double x, y, speed, size, opacity;
  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (final p in particles) {
      paint.color = Colors.white.withOpacity(p.opacity);
      canvas.drawCircle(Offset(p.x, p.y), p.size / 2, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}
