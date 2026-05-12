import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/login_screen.dart';
import 'game_chart_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final _user = Supabase.instance.client.auth.currentUser;
  Map<String, dynamic>? _profileData;
  List<dynamic> _gameScores = [];
  bool _isLoading = true;

  late AnimationController _avatarCtrl;
  late AnimationController _cardsCtrl;
  late Animation<double> _avatarAnim;
  late Animation<double> _cardsAnim;

  // Grouped: gameName -> {best, count, scores}
  Map<String, Map<String, dynamic>> _grouped = {};

  @override
  void initState() {
    super.initState();
    _avatarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _cardsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _avatarAnim = CurvedAnimation(parent: _avatarCtrl, curve: Curves.easeOutBack);
    _cardsAnim = CurvedAnimation(parent: _cardsCtrl, curve: Curves.easeOut);
    _fetchProfileData();
  }

  @override
  void dispose() {
    _avatarCtrl.dispose();
    _cardsCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    if (_user == null) return;
    try {
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', _user.id)
          .single();

      final scoresResponse = await Supabase.instance.client
          .from('game_scores')
          .select()
          .eq('user_id', _user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        final grouped = <String, Map<String, dynamic>>{};
        for (final s in scoresResponse) {
          final name = s['game_name'] as String;
          final score = s['score'] as int;
          if (!grouped.containsKey(name)) {
            grouped[name] = {'best': score, 'count': 0};
          }
          grouped[name]!['count'] = (grouped[name]!['count'] as int) + 1;
          if (score > (grouped[name]!['best'] as int)) {
            grouped[name]!['best'] = score;
          }
        }

        setState(() {
          _profileData = profileResponse;
          _gameScores = scoresResponse;
          _grouped = grouped;
          _isLoading = false;
        });

        _avatarCtrl.forward();
        await Future.delayed(const Duration(milliseconds: 300));
        _cardsCtrl.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading profile data')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) Navigator.pop(context);
  }

  Color _colorFor(String name) {
    switch (name) {
      case 'Tank War': return const Color(0xFFFF8C42);
      case 'Tetris': return const Color(0xFF00E5FF);
      case 'Flappy Bird': return const Color(0xFFFFEB3B);
      default: return const Color(0xFFB388FF);
    }
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'Tank War': return Icons.military_tech;
      case 'Tetris': return Icons.grid_view_rounded;
      case 'Flappy Bird': return Icons.air;
      default: return Icons.sports_esports;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const LoginScreen();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: Text('Профайл', style: GoogleFonts.bungee(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final name = _profileData?['name'] ?? 'Unknown';
    final totalScore = _profileData?['total_score'] ?? 0;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + name
          ScaleTransition(
            scale: _avatarAnim,
            child: Center(
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF00E5FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: GoogleFonts.bungee(fontSize: 36, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _user!.email ?? '',
                    style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Total score card
          ScaleTransition(
            scale: _avatarAnim,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6C63FF).withOpacity(0.2),
                    const Color(0xFF00E5FF).withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.4),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Нийт оноо',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalScore',
                    style: GoogleFonts.bungee(fontSize: 42, color: Colors.white),
                  ),
                  Text(
                    'тоглоом тус бүрийн best оноонуудын нийлбэр',
                    style: GoogleFonts.poppins(color: Colors.white24, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          FadeTransition(
            opacity: _cardsAnim,
            child: Text(
              'Тоглоомуудын статистик',
              style: GoogleFonts.bungee(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(height: 12),

          if (_grouped.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Тоглоом тоглоогүй байна. Эхлэх үү?',
                  style: GoogleFonts.poppins(color: Colors.white38),
                ),
              ),
            )
          else
            ..._grouped.entries.toList().asMap().entries.map((entry) {
              final idx = entry.key;
              final gameName = entry.value.key;
              final data = entry.value.value;
              return _buildGameCard(idx, gameName, data);
            }),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGameCard(int idx, String gameName, Map<String, dynamic> data) {
    final color = _colorFor(gameName);
    final icon = _iconFor(gameName);
    final best = data['best'] as int;
    final count = data['count'] as int;

    return AnimatedBuilder(
      animation: _cardsAnim,
      builder: (context, child) {
        final delay = (idx * 0.15).clamp(0.0, 0.7);
        final animVal = ((_cardsAnim.value - delay) / (1 - delay)).clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, (1 - animVal) * 30),
          child: Opacity(opacity: animVal, child: child),
        );
      },
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, anim, __) => GameChartScreen(gameName: gameName),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                child: child,
              ),
            ),
            transitionDuration: const Duration(milliseconds: 350),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),

              // Name + count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gameName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '$count тоглолт',
                      style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),

              // Best score
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$best',
                    style: GoogleFonts.bungee(color: color, fontSize: 22),
                  ),
                  Text('best', style: TextStyle(color: color.withOpacity(0.5), fontSize: 10)),
                ],
              ),
              const SizedBox(width: 8),

              // Arrow
              Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.4), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
