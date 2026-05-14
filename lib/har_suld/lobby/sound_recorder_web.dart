// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data' show ByteBuffer, Uint8List;

/// Browser-ын MediaRecorder API-г ашиглан mic-ийн дуу бичдэг (Web only).
class SoundRecorder {
  html.MediaRecorder? _recorder;
  html.MediaStream? _stream;
  final List<html.Blob> _chunks = [];
  bool _isRecording = false;
  Timer? _autoStopTimer;

  bool get isRecording => _isRecording;

  Future<Uint8List?> record(double maxDuration) async {
    if (_isRecording) return null;

    _chunks.clear();
    final completer = Completer<Uint8List?>();

    try {
      // Stream-г дахин ашиглана — getUserMedia нэг л удаа дуудна
      _stream ??= await html.window.navigator.mediaDevices!.getUserMedia({
        'audio': true,
        'video': false,
      });

      final mimeType = _bestMimeType();
      _recorder = mimeType != null
          ? html.MediaRecorder(_stream!, {'mimeType': mimeType})
          : html.MediaRecorder(_stream!);

      _recorder!.addEventListener('dataavailable', (event) {
        final blob = (event as html.BlobEvent).data;
        if (blob != null && blob.size > 0) _chunks.add(blob);
      });

      _recorder!.addEventListener('stop', (_) async {
        _isRecording = false;
        if (_chunks.isEmpty) {
          completer.complete(null);
          return;
        }
        final combined = html.Blob(_chunks);
        _blobToBytes(combined).then(completer.complete).catchError((_) {
          completer.complete(null);
        });
      });

      _recorder!.addEventListener('error', (_) {
        _isRecording = false;
        _releaseStream();
        if (!completer.isCompleted) completer.complete(null);
      });

      _isRecording = true;
      _recorder!.start();

      _autoStopTimer = Timer(
        Duration(milliseconds: (maxDuration * 1000).toInt()),
        stop,
      );
    } catch (e) {
      _isRecording = false;
      _releaseStream();
      if (!completer.isCompleted) completer.complete(null);
    }

    return completer.future;
  }

  void stop() {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    if (_isRecording &&
        _recorder != null &&
        _recorder!.state == 'recording') {
      _recorder!.stop();
    }
  }

  void cancel() {
    stop();
    _releaseStream();
    _isRecording = false;
  }

  void dispose() => cancel();

  String? _bestMimeType() {
    final candidates = [
      'audio/webm;codecs=opus',
      'audio/webm',
      'audio/ogg;codecs=opus',
      'audio/ogg',
    ];
    for (final t in candidates) {
      if (html.MediaRecorder.isTypeSupported(t)) return t;
    }
    return null;
  }

  Future<Uint8List> _blobToBytes(html.Blob blob) {
    final c = Completer<Uint8List>();
    final reader = html.FileReader();
    reader.onLoad.listen((_) {
      c.complete((reader.result as ByteBuffer).asUint8List());
    });
    reader.onError.listen((_) => c.completeError('FileReader error'));
    reader.readAsArrayBuffer(blob);
    return c.future;
  }

  void _releaseStream() {
    if (_stream == null) return;
    try {
      final tracks = _stream!.getTracks();
      for (final t in tracks) {
        t.stop();
      }
    } catch (_) {}
    _stream = null;
  }
}
