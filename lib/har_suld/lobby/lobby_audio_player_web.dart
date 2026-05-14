// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

/// Web платформд AudioElement ашиглан preview дуу тоглуулна.
class LobbyAudioPlayer {
  html.AudioElement? _audio;
  String? _blobUrl;

  Future<void> play(
    Uint8List bytes, {
    void Function()? onEnded,
    void Function()? onError,
  }) async {
    stop();
    _revokeBlobUrl();

    const mimeType = 'audio/webm;codecs=opus';
    final blob = html.Blob([bytes], mimeType);
    final url  = html.Url.createObjectUrlFromBlob(blob);
    _blobUrl = url;

    final audio = html.AudioElement();
    audio.src = url;
    audio.onEnded.listen((_) => onEnded?.call());
    audio.onError.listen((_) => onError?.call());
    _audio = audio;

    try {
      await audio.play();
    } catch (_) {
      onError?.call();
    }
  }

  void stop() {
    _audio?.pause();
    _audio = null;
  }

  void dispose() {
    stop();
    _revokeBlobUrl();
  }

  void _revokeBlobUrl() {
    if (_blobUrl != null) {
      html.Url.revokeObjectUrl(_blobUrl!);
      _blobUrl = null;
    }
  }
}
