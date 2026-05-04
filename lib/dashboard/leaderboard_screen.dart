import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> _topPlayers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id, name, total_score')
          .order('total_score', ascending: false)
          .limit(50);
          
      if (mounted) {
        setState(() {
          _topPlayers = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading leaderboard')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leaderboard', style: GoogleFonts.bungee()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _topPlayers.isEmpty
              ? const Center(child: Text('No players yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _topPlayers.length,
                  itemBuilder: (context, index) {
                    final player = _topPlayers[index];
                    final bool isTop3 = index < 3;
                    
                    return Card(
                      color: isTop3 
                          ? Colors.amber.withOpacity(0.2 - (index * 0.05))
                          : Colors.white.withOpacity(0.05),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isTop3 ? Colors.amber : Colors.blueGrey,
                          child: Text(
                            '#${index + 1}',
                            style: TextStyle(
                              color: isTop3 ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          player['name'] ?? 'Unknown',
                          style: GoogleFonts.poppins(
                            fontWeight: isTop3 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: Text(
                          '${player['total_score'] ?? 0} pts',
                          style: GoogleFonts.bungee(
                            color: isTop3 ? Colors.amber : Colors.white70,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
