import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

/// Android/Desktop платформд audioplayers ашиглан дуу тоглуулдаг сервис.
class HarSuldGameAudio {
  static final Map<String, AudioPlayer> _players = {};
  static final Map<String, Uint8List> _bytes = {};

  static void load(Map<String, Uint8List> recordings) {
    _dispose();
    _bytes.addAll(recordings);
    for (final key in recordings.keys) {
      _players[key] = AudioPlayer();
    }
  }

  static void play(String key) {
    final bytes = _bytes[key];
    final player = _players[key];
    if (bytes == null || player == null) return;
    player.play(BytesSource(bytes));
  }

  static void dispose() => _dispose();

  static void _dispose() {
    for (final p in _players.values) {
      p.stop();
      p.dispose();
    }
    _players.clear();
    _bytes.clear();
  }
}
