import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

/// Android/Desktop платформд audioplayers ашиглан preview дуу тоглуулна.
class LobbyAudioPlayer {
  AudioPlayer? _player;

  Future<void> play(
    Uint8List bytes, {
    void Function()? onEnded,
    void Function()? onError,
  }) async {
    await _player?.stop();
    await _player?.dispose();
    _player = AudioPlayer();
    _player!.onPlayerComplete.listen((_) => onEnded?.call());
    try {
      await _player!.play(BytesSource(bytes));
    } catch (_) {
      onError?.call();
    }
  }

  void stop() {
    _player?.stop();
  }

  void dispose() {
    _player?.stop();
    _player?.dispose();
    _player = null;
  }
}
