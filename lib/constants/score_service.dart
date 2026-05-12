import 'package:supabase_flutter/supabase_flutter.dart';

class ScoreService {
  /// total_score = тоглоом тус бүрийн ХАМГИЙН ӨНДӨР оноонуудын нийлбэр
  ///
  /// Flappy Bird: 10, 5, 15, 3  →  best = 15
  /// Tetris:      1000, 900      →  best = 1000
  /// ──────────────────────────
  /// total_score = 15 + 1000 = 1015
  static Future<void> submitScore({
    required String gameName,
    required int score,
    required int playtimeSeconds,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Тоглолтыг хадгална
      await Supabase.instance.client.from('game_scores').insert({
        'user_id': user.id,
        'game_name': gameName,
        'score': score,
        'playtime_seconds': playtimeSeconds,
      });

      // 2. Энэ тоглогчийн бүх тоглолтыг татна
      final List allScores = await Supabase.instance.client
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

      // Debug: юу тооцоолж байгааг харуулна
      print('=== ScoreService DEBUG ===');
      print('Submitted: $gameName → $score pts');
      print('Best per game: $bestPerGame');

      // 4. Нийт = best-үүдийн нийлбэр
      final int newTotal = bestPerGame.values.fold(0, (sum, s) => sum + s);
      print('New total_score = $newTotal');
      print('==========================');

      // 5. total_score-г ШУУД ТОХИРУУЛНА (нэмэхгүй, орлуулна)
      await Supabase.instance.client
          .from('profiles')
          .update({'total_score': newTotal})
          .eq('id', user.id);

      // 6. Баталгаажуулна — update хийсний дараа утгыг уншина
      final check = await Supabase.instance.client
          .from('profiles')
          .select('total_score')
          .eq('id', user.id)
          .single();
      print('DB total_score after update: ${check['total_score']}');

    } catch (e) {
      print('ScoreService error: $e');
    }
  }
}
