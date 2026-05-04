import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _user = Supabase.instance.client.auth.currentUser;
  Map<String, dynamic>? _profileData;
  List<dynamic> _gameScores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    if (_user == null) return;
    
    try {
      // Fetch profile
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', _user.id)
          .single();
          
      // Fetch scores for this user
      final scoresResponse = await Supabase.instance.client
          .from('game_scores')
          .select()
          .eq('user_id', _user.id)
          .order('score', ascending: false);

      if (mounted) {
        setState(() {
          _profileData = profileResponse;
          _gameScores = scoresResponse;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading profile data')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.bungee()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blueAccent,
                      child: Text(
                        _profileData?['name']?.substring(0, 1).toUpperCase() ?? 'U',
                        style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      _profileData?['name'] ?? 'Unknown User',
                      style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Center(
                    child: Text(
                      _user.email ?? '',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Total Score
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Total Score',
                          style: GoogleFonts.poppins(fontSize: 16, color: Colors.amber),
                        ),
                        Text(
                          '${_profileData?['total_score'] ?? 0}',
                          style: GoogleFonts.bungee(fontSize: 36),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  Text(
                    'Recent Games',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_gameScores.isEmpty)
                    const Text('No games played yet. Go play something!')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _gameScores.length,
                      itemBuilder: (context, index) {
                        final scoreItem = _gameScores[index];
                        return Card(
                          color: Colors.white.withOpacity(0.05),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              _getGameIcon(scoreItem['game_name']),
                              color: Colors.white,
                            ),
                            title: Text(scoreItem['game_name']),
                            subtitle: Text('Score: ${scoreItem['score']} | Played for: ${scoreItem['playtime_seconds'] ?? 0}s'),
                            trailing: Text(
                              _formatDate(scoreItem['created_at']),
                              style: const TextStyle(fontSize: 12, color: Colors.white54),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  IconData _getGameIcon(String gameName) {
    switch (gameName) {
      case 'Tank War': return Icons.shield;
      case 'Tetris': return Icons.grid_view;
      case 'Flappy Bird': return Icons.flight;
      default: return Icons.games;
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
