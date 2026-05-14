import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Android/Desktop платформд [record] package ашиглан дуу бичдэг.
/// Mic зөвшөөрлийг автоматаар хүснэ.
class SoundRecorder {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  Timer? _autoStopTimer;
  Completer<Uint8List?>? _completer;
  String? _tempPath;

  bool get isRecording => _isRecording;

  Future<Uint8List?> record(double maxDuration) async {
    if (_isRecording) return null;

    // Mic зөвшөөрлийг хүснэ — системийн dialog харуулна
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return null;

    _completer = Completer<Uint8List?>();

    try {
      final dir = await getTemporaryDirectory();
      _tempPath =
          '${dir.path}/hs_rec_${DateTime.now().millisecondsSinceEpoch}.m4a';

      _isRecording = true;
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          bitRate: 128000,
          numChannels: 1,
        ),
        path: _tempPath!,
      );

      // Автомат зогсолт
      _autoStopTimer = Timer(
        Duration(milliseconds: (maxDuration * 1000).toInt()),
        stop,
      );
    } catch (_) {
      _isRecording = false;
      if (!(_completer?.isCompleted ?? true)) {
        _completer!.complete(null);
      }
    }

    return _completer!.future;
  }

  void stop() {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    if (!_isRecording) return;

    // then/catchError-ийн оронд unawaited async block ашиглана
    _stopAndComplete();
  }

  Future<void> _stopAndComplete() async {
    try {
      final path = await _recorder.stop();
      _isRecording = false;
      if (path == null) { _completer?.complete(null); return; }
      try {
        final bytes = await File(path).readAsBytes();
        File(path).delete().ignore();
        _completer?.complete(bytes);
      } catch (_) {
        _completer?.complete(null);
      }
    } catch (_) {
      _isRecording = false;
      _completer?.complete(null);
    }
  }

  void cancel() {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _recorder.stop().ignore();
    _isRecording = false;
    if (!(_completer?.isCompleted ?? true)) {
      _completer!.complete(null);
    }
  }

  void dispose() {
    cancel();
    _recorder.dispose();
  }
}
