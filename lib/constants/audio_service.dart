import 'package:flame_audio/flame_audio.dart';

/// Тоглоомын бүх дуу авиаг удирдах сервис
///
/// BGM  → ар дэвсгэр хөгжим (давтагдан тоглоно)
/// SFX  → нэг удаагийн дуу авиа
class AudioService {
  AudioService._();

  static bool sfxEnabled   = true;
  static bool musicEnabled = true;

  static double _musicVol = 0.45;
  static double _sfxVol   = 0.80;

  static String? _currentBgm;

  // ── Файлын нэрс ─────────────────────────────────────────────
  static const String bgmFlappy   = 'bgm_flappy.mp3';
  static const String bgmTetris   = 'bgm_tetris.mp3';
  static const String bgmTank     = 'bgm_tank.mp3';

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
  static Future<void> playBgm(String file) async {
    if (!musicEnabled) return;
    if (_currentBgm == file) return;
    try {
      await FlameAudio.bgm.stop();
      await FlameAudio.bgm.play(file, volume: _musicVol);
      _currentBgm = file;
    } catch (e) {
      // Файл байхгүй бол тоглохгүй, алдаа гаргахгүй
    }
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
    if (!musicEnabled) stopBgm();
  }

  static void toggleSfx() {
    sfxEnabled = !sfxEnabled;
  }
}
