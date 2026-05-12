import 'package:supabase_flutter/supabase_flutter.dart';

class ScoreService {
  /// Тоглолтын оноог хадгалж, total_score-г тооцоолно.
  ///
  /// Тооцооллын дүрэм:
  ///   total_score = Σ ( тоглоом тус бүрийн хамгийн өндөр оноо )
  ///
  /// Жишээ:
  ///   Tetris:      1000, 900, 800  →  best = 1000
  ///   Flappy Bird: 30,  50,  20   →  best = 50
  ///   Tank War:    200, 300        →  best = 300
  ///   ──────────────────────────────────────────
  ///   total_score = 1000 + 50 + 300 = 1350
  static Future<void> submitScore({
    required String gameName,
    required int score,
    required int playtimeSeconds,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Тоглолтын оноог game_scores хүснэгтэд хадгална
      await Supabase.instance.client.from('game_scores').insert({
        'user_id': user.id,
        'game_name': gameName,
        'score': score,
        'playtime_seconds': playtimeSeconds,
      });

      // 2. Энэ тоглогчийн БҮХ тоглолтыг татна (шинэ оноо орсны дараа)
      final allScores = await Supabase.instance.client
          .from('game_scores')
          .select('game_name, score')
          .eq('user_id', user.id);

      // 3. Тоглоом тус бүрийн хамгийн өндөр оноог олно
      final Map<String, int> bestPerGame = {};
      for (final row in allScores) {
        final name = row['game_name'] as String;
        final s = row['score'] as int;
        if (!bestPerGame.containsKey(name) || s > bestPerGame[name]!) {
          bestPerGame[name] = s;
        }
      }

      // 4. Нийт оноо = тоглоом тус бүрийн best-үүдийн нийлбэр
      final int newTotal =
          bestPerGame.values.fold(0, (sum, s) => sum + s);

      // 5. profiles хүснэгтийн total_score-г шинэчилнэ
      await Supabase.instance.client
          .from('profiles')
          .update({'total_score': newTotal})
          .eq('id', user.id);

    } catch (e) {
      print('ScoreService error: $e');
    }
  }
}
