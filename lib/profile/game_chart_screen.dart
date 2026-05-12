import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GameChartScreen extends StatefulWidget {
  final String gameName;
  const GameChartScreen({super.key, required this.gameName});

  @override
  State<GameChartScreen> createState() => _GameChartScreenState();
}

class _GameChartScreenState extends State<GameChartScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _scores = [];
  bool _isLoading = true;

  late AnimationController _lineCtrl;
  late AnimationController _statsCtrl;
  late AnimationController _listCtrl;
  late Animation<double> _lineAnim;
  late Animation<double> _statsAnim;
  late Animation<double> _listAnim;

  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _lineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _statsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _listCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _lineAnim = CurvedAnimation(parent: _lineCtrl, curve: Curves.easeInOut);
    _statsAnim = CurvedAnimation(parent: _statsCtrl, curve: Curves.easeOutBack);
    _listAnim = CurvedAnimation(parent: _listCtrl, curve: Curves.easeOut);
    _fetchScores();
  }

  @override
  void dispose() {
    _lineCtrl.dispose();
    _statsCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchScores() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final response = await Supabase.instance.client
          .from('game_scores')
          .select()
          .eq('user_id', user.id)
          .eq('game_name', widget.gameName)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _scores = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
        _statsCtrl.forward();
        await Future.delayed(const Duration(milliseconds: 200));
        _lineCtrl.forward();
        await Future.delayed(const Duration(milliseconds: 800));
        _listCtrl.forward();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Compute "is new personal best at this point in time"
  List<int> _computeRunningBest() {
    int best = 0;
    return _scores.map((s) {
      final score = s['score'] as int;
      if (score > best) {
        best = score;
        return 1; // new best
      } else if (score == best) {
        return 0; // tie
      }
      return -1; // below best
    }).toList();
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'Tank War': return Icons.military_tech;
      case 'Tetris': return Icons.grid_view_rounded;
      case 'Flappy Bird': return Icons.air;
      default: return Icons.sports_esports;
    }
  }

  Color _colorFor(String name) {
    switch (name) {
      case 'Tank War': return const Color(0xFFFF8C42);
      case 'Tetris': return const Color(0xFF00E5FF);
      case 'Flappy Bird': return const Color(0xFFFFEB3B);
      default: return const Color(0xFFB388FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(widget.gameName);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Icon(_iconFor(widget.gameName), color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              widget.gameName,
              style: GoogleFonts.bungee(color: color, fontSize: 18),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: color),
            )
          : _scores.isEmpty
              ? _buildEmpty(color)
              : _buildContent(color),
    );
  }

  Widget _buildEmpty(Color color) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(widget.gameName), color: color.withOpacity(0.4), size: 80),
          const SizedBox(height: 16),
          Text(
            'Тоглоогүй байна',
            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 18),
          ),
          Text(
            'Go play a game first!',
            style: GoogleFonts.poppins(color: Colors.white24, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Color color) {
    final runningBest = _computeRunningBest();
    final scores = _scores.map((s) => s['score'] as int).toList();
    final best = scores.reduce((a, b) => a > b ? a : b);
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    final total = scores.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          ScaleTransition(
            scale: _statsAnim,
            child: _buildStatsRow(best, total, avg, color),
          ),
          const SizedBox(height: 20),

          // Chart title
          FadeTransition(
            opacity: _lineAnim,
            child: Text(
              'Онооны өсөлт',
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Chart
          AnimatedBuilder(
            animation: _lineAnim,
            builder: (context, _) {
              return Container(
                height: 260,
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.08),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _lineAnim.value > 0.05
                    ? _buildChart(color, runningBest)
                    : const SizedBox.shrink(),
              );
            },
          ),

          const SizedBox(height: 12),

          // Legend
          FadeTransition(
            opacity: _lineAnim,
            child: Row(
              children: [
                _legendItem(Colors.greenAccent, 'Шинэ рекорд'),
                const SizedBox(width: 20),
                _legendItem(Colors.redAccent, 'Рекордоос доогуур'),
                const SizedBox(width: 20),
                _legendItem(Colors.white54, 'Тэнцүү'),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // History list title
          FadeTransition(
            opacity: _listAnim,
            child: Text(
              'Тоглолтын түүх',
              style: GoogleFonts.bungee(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(height: 12),

          // History items
          ..._buildHistoryList(runningBest, color),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int best, int total, double avg, Color color) {
    return Row(
      children: [
        Expanded(child: _statCard('BEST', '$best', Colors.amber)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('GAMES', '$total', color)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('AVG', avg.toStringAsFixed(0), const Color(0xFFCE93D8))),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.poppins(color: color, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.bungee(color: Colors.white, fontSize: 22)),
        ],
      ),
    );
  }

  Widget _buildChart(Color lineColor, List<int> runningBest) {
    final spots = _scores.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['score'] as int).toDouble());
    }).toList();

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.3;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        clipData: const FlClipData.all(),
        lineTouchData: LineTouchData(
          touchCallback: (event, response) {
            setState(() {
              _touchedIndex = response?.lineBarSpots?.first.spotIndex;
            });
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1E2530),
            tooltipRoundedRadius: 10,
            getTooltipItems: (spots) => spots.map((s) {
              final idx = s.spotIndex;
              final date = DateTime.tryParse(_scores[idx]['created_at'] ?? '');
              final dateStr = date != null
                  ? '${date.month}/${date.day}/${date.year}'
                  : '';
              return LineTooltipItem(
                '${s.y.toInt()} pts\n',
                GoogleFonts.bungee(color: lineColor, fontSize: 14),
                children: [
                  TextSpan(
                    text: dateStr,
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withOpacity(0.06),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (val, _) => Text(
                '${val.toInt()}',
                style: const TextStyle(color: Colors.white24, fontSize: 9),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: _scores.length <= 7 ? 1 : (_scores.length / 5).ceilToDouble(),
              getTitlesWidget: (val, _) {
                final idx = val.toInt();
                if (idx < 0 || idx >= _scores.length) return const SizedBox();
                final date = DateTime.tryParse(_scores[idx]['created_at'] ?? '');
                if (date == null) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${date.month}/${date.day}',
                    style: const TextStyle(color: Colors.white38, fontSize: 9),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: spots.length > 2,
            curveSmoothness: 0.35,
            color: lineColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, index) {
                final isBest = runningBest[index] == 1;
                final isTie = runningBest[index] == 0;
                final dotColor = isBest
                    ? Colors.greenAccent
                    : isTie
                        ? Colors.white54
                        : Colors.redAccent;
                final isTouched = _touchedIndex == index;
                return FlDotCirclePainter(
                  radius: isTouched ? 7 : 5,
                  color: dotColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withOpacity(0.25),
                  lineColor.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  List<Widget> _buildHistoryList(List<int> runningBest, Color gameColor) {
    // Show newest first in list
    final reversed = _scores.reversed.toList();
    final reversedBest = runningBest.reversed.toList();

    return reversed.asMap().entries.map((entry) {
      final idx = entry.key;
      final s = entry.value;
      final score = s['score'] as int;
      final date = DateTime.tryParse(s['created_at'] ?? '');
      final bestStatus = reversedBest[idx];
      final isNewBest = bestStatus == 1;
      final isTie = bestStatus == 0;
      final dotColor = isNewBest
          ? Colors.greenAccent
          : isTie
              ? Colors.white54
              : Colors.redAccent;

      return AnimatedBuilder(
        animation: _listAnim,
        builder: (context, child) {
          final delay = (idx * 0.1).clamp(0.0, 0.9);
          final animVal = ((_listAnim.value - delay) / (1 - delay)).clamp(0.0, 1.0);
          return Transform.translate(
            offset: Offset((1 - animVal) * 40, 0),
            child: Opacity(opacity: animVal, child: child),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: dotColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: dotColor.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              // Status dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: dotColor.withOpacity(0.5), blurRadius: 6)],
                ),
              ),
              const SizedBox(width: 10),
              // Label
              if (isNewBest)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
                  ),
                  child: Text(
                    '🏆 Шинэ рекорд',
                    style: TextStyle(color: Colors.greenAccent, fontSize: 10),
                  ),
                )
              else
                Text(
                  isTie ? 'Тэнцүү' : 'Доогуур',
                  style: TextStyle(color: dotColor, fontSize: 11),
                ),
              const Spacer(),
              // Score
              Text(
                '$score',
                style: GoogleFonts.bungee(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(width: 4),
              Text('pts', style: TextStyle(color: Colors.white38, fontSize: 10)),
              const SizedBox(width: 14),
              // Date
              if (date != null)
                Text(
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
