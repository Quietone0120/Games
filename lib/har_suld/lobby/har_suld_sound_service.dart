import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Хар Сүлд тоглоомын дуу бичлэгийн түлхүүрүүд
class HarSuldSoundKeys {
  static const String playerDeath     = 'player_death';
  static const String playerHeal      = 'player_heal';
  static const String horseMount      = 'horse_mount';
  static const String arrowShoot      = 'arrow_shoot';
  static const String wolfAttack      = 'wolf_attack';
  static const String buildStructure  = 'build_structure';
  static const String harvestResource = 'harvest_resource';

  static const List<String> all = [
    playerDeath,
    playerHeal,
    horseMount,
    arrowShoot,
    wolfAttack,
    buildStructure,
    harvestResource,
  ];

  static String label(String key) => switch (key) {
    playerDeath     => 'Тоглогч үхэх',
    playerHeal      => 'Тоглогч амьлах',
    horseMount      => 'Моринд морьдох',
    arrowShoot      => 'Харвах',
    wolfAttack      => 'Чоно дайрах',
    buildStructure  => 'Байгуулалт барих',
    harvestResource => 'Нөөц цуглуулах',
    _               => key,
  };

  static double maxDuration(String key) => switch (key) {
    horseMount => 1.5,
    _          => 1.0,
  };
}

const _kBucket = 'har-suld-sounds';

/// Web → .webm (audio/webm), Mobile → .m4a (audio/mp4)
String get _ext => kIsWeb ? 'webm' : 'm4a';
String get _mime => kIsWeb ? 'audio/webm' : 'audio/mp4';

/// Supabase Storage дахь дуу бичлэгийн сервис.
/// Web болон Android хоёуланг дэмжинэ (.webm / .m4a).
class HarSuldSoundService {
  static SupabaseClient get _db => Supabase.instance.client;

  /// Бичсэн дуугаа Supabase-д хадгалах
  static Future<void> save(String soundKey, Uint8List audioBytes) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;

    final path = '$userId/$soundKey.$_ext';
    await _db.storage.from(_kBucket).uploadBinary(
      path,
      audioBytes,
      fileOptions: FileOptions(upsert: true, contentType: _mime),
    );
  }

  /// Тухайн дуугийн бичлэгийг татаж авах.
  /// Одоогийн платформын extension-г эхлээд туршаад, нөгөөг нь туршина.
  static Future<Uint8List?> download(String soundKey) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return null;
    // Платформын extension эхлээд, дараа нь fallback
    final exts = [_ext, _ext == 'webm' ? 'm4a' : 'webm'];
    for (final ext in exts) {
      try {
        return await _db.storage.from(_kBucket).download('$userId/$soundKey.$ext');
      } catch (_) {}
    }
    return null;
  }

  /// Тоглогчийн бүх бичигдсэн дуунуудыг татна.
  /// Буцаах утга: { soundKey → Uint8List }
  static Future<Map<String, Uint8List>> loadAll() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return {};

    final result = <String, Uint8List>{};
    await Future.wait(
      HarSuldSoundKeys.all.map((key) async {
        final bytes = await download(key);
        if (bytes != null) result[key] = bytes;
      }),
    );
    return result;
  }

  /// Бичигдсэн дуунуудын түлхүүр жагсаалт — .webm ба .m4a хоёуланг таних
  static Future<Set<String>> recordedKeys() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return {};
    try {
      final files = await _db.storage.from(_kBucket).list(path: userId);
      return files
          .map((f) => f.name
              .replaceAll('.webm', '')
              .replaceAll('.m4a', '')
              .replaceAll('.ogg', ''))
          .where(HarSuldSoundKeys.all.contains)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  /// Нэг дуугийн бичлэгийг устгах (аль ч extension-г устгана)
  static Future<void> delete(String soundKey) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    // Хоёр extension-г хоёуланг нь устгах оролдлого
    await _db.storage.from(_kBucket).remove([
      '$userId/$soundKey.webm',
      '$userId/$soundKey.m4a',
    ]).catchError((_) => <FileObject>[]);
  }
}
