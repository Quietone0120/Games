import 'package:supabase_flutter/supabase_flutter.dart';

class ScoreService {
  static Future<void> submitScore({
    required String gameName,
    required int score,
    required int playtimeSeconds,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return; // User not logged in, ignore saving score

    try {
      // 1. Insert into game_scores
      await Supabase.instance.client.from('game_scores').insert({
        'user_id': user.id,
        'game_name': gameName,
        'score': score,
        'playtime_seconds': playtimeSeconds,
      });

      // 2. Fetch current profile to get total_score
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('total_score')
          .eq('id', user.id)
          .single();
      
      final int currentTotal = profile['total_score'] ?? 0;
      
      // 3. Update total_score
      await Supabase.instance.client
          .from('profiles')
          .update({'total_score': currentTotal + score})
          .eq('id', user.id);
          
    } catch (e) {
      print('Error submitting score: $e');
    }
  }
}
