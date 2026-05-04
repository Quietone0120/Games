import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://zxtoakxryqyyeikwdjvc.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_4MaJa2G9ubQzEu-0EsbN9Q_aWetMKZ4';

  static Future<void> initialize() async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      print('Supabase config is empty. Please add your URL and Anon Key.');
      return;
    }
    
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}
