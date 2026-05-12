import 'package:flame_audio/flame_audio.dart';

/// Тоглоомын бүх дуу авиаг удирдах сервис
///
/// BGM  → ар дэвсгэр хөгжим (давтагдан тоглоно)
/// SFX  → нэг удаагийн дуу авиа
///
/// Web platform: autoplay policy-г зохицуулна.
/// Аль нэг SFX эсвэл товч дарсны дараа BGM эхэлнэ.
class AudioService {
  AudioService._();

  static bool sfxEnabled   = true;
  static bool musicEnabled = true;

  static double _musicVol = 0.50;
  static double _sfxVol   = 0.85;

  static String? _pendingBgm;   // Web autoplay-г хүлээж буй BGM
  static String? _currentBgm;
  static bool _userInteracted = false;

  // ── Файлын нэрс (WAV — бүх platform дэмжинэ) ────────────────
  static const String bgmFlappy   = 'bgm_flappy.wav';
  static const String bgmTetris   = 'bgm_tetris.wav';
  static const String bgmTank     = 'bgm_tank.wav';

  static const String sfxClick    = 'sfx_click.wav';
  // Flappy Bird
  static const String sfxWing     = 'sfx_wing.wav';
  static const String sfxPoint    = 'sfx_point.wav';
  static const String sfxHit      = 'sfx_hit.wav';
  // Tetris
  static const String sfxMove     = 'sfx_move.wav';
  static const String sfxRotate   = 'sfx_rotate.wav';
  static const String sfxClear    = 'sfx_clear.wav';
  static const String sfxGameover = 'sfx_gameover.wav';
  // Tank
  static const String sfxShoot    = 'sfx_shoot.wav';
  static const String sfxExplode  = 'sfx_explode.wav';

  // ── Эхлүүлэх ────────────────────────────────────────────────
  static Future<void> init() async {
    try {
      FlameAudio.bgm.initialize();
    } catch (_) {}
  }

  // ── BGM ─────────────────────────────────────────────────────
  /// BGM тоглох. Web дээр хэрэглэгч харилцаагүй бол хадгалж,
  /// эхний SFX дарсны дараа автоматаар эхэлнэ.
  static Future<void> playBgm(String file) async {
    if (!musicEnabled) return;
    if (_currentBgm == file) return;
    _pendingBgm = file;
    if (!_userInteracted) return; // Web autoplay хязгаарлалт
    await _startBgm(file);
  }

  static Future<void> _startBgm(String file) async {
    try {
      await FlameAudio.bgm.stop();
      await FlameAudio.bgm.play(file, volume: _musicVol);
      _currentBgm = file;
      _pendingBgm = null;
    } catch (_) {}
  }

  static Future<void> stopBgm() async {
    try {
      await FlameAudio.bgm.stop();
      _currentBgm = null;
    } catch (_) {}
  }

  static Future<void> pauseBgm() async {
    try { await FlameAudio.bgm.pause(); } catch (_) {}
  }

  static Future<void> resumeBgm() async {
    if (!musicEnabled) return;
    try { await FlameAudio.bgm.resume(); } catch (_) {}
  }

  // ── SFX ─────────────────────────────────────────────────────
  static Future<void> playSfx(String file) async {
    if (!sfxEnabled) return;

    // Эхний хэрэглэгчийн харилцаа → pending BGM эхлүүлнэ
    if (!_userInteracted) {
      _userInteracted = true;
      if (_pendingBgm != null && musicEnabled) {
        await _startBgm(_pendingBgm!);
      }
    }

    try {
      await FlameAudio.play(file, volume: _sfxVol);
    } catch (_) {}
  }

  // ── Тохиргоо ────────────────────────────────────────────────
  static void setMusicVolume(double v) {
    _musicVol = v.clamp(0.0, 1.0);
  }

  static void setSfxVolume(double v) {
    _sfxVol = v.clamp(0.0, 1.0);
  }

  static void toggleMusic() {
    musicEnabled = !musicEnabled;
    if (!musicEnabled) {
      stopBgm();
    } else if (_pendingBgm != null && _userInteracted) {
      _startBgm(_pendingBgm!);
    }
  }

  static void toggleSfx() {
    sfxEnabled = !sfxEnabled;
  }
}
