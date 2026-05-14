// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

/// Web платформд тоглогчийн бичсэн дуунуудыг тоглуулдаг сервис.
class HarSuldGameAudio {
  static final Map<String, _AudioEntry> _entries = {};

  static void load(Map<String, Uint8List> recordings) {
    _dispose();
    for (final entry in recordings.entries) {
      final blob = html.Blob([entry.value], 'audio/webm');
      final url  = html.Url.createObjectUrlFromBlob(blob);
      final audio = html.AudioElement()
        ..src = url
        ..preload = 'auto';
      _entries[entry.key] = _AudioEntry(audio: audio, objectUrl: url);
    }
  }

  static void play(String key) {
    final entry = _entries[key];
    if (entry == null) return;
    entry.audio.currentTime = 0;
    entry.audio.play();
  }

  static void dispose() => _dispose();

  static void _dispose() {
    for (final e in _entries.values) {
      e.audio.pause();
      e.audio.src = '';
      html.Url.revokeObjectUrl(e.objectUrl);
    }
    _entries.clear();
  }
}

class _AudioEntry {
  final html.AudioElement audio;
  final String objectUrl;
  const _AudioEntry({required this.audio, required this.objectUrl});
}
