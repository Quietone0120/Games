import 'dart:typed_data';

/// Android/Desktop платформд дуу бичлэг дэмжигдэхгүй — stub implementation.
class SoundRecorder {
  bool get isRecording => false;
  Future<Uint8List?> record(double maxDuration) async => null;
  void stop() {}
  void cancel() {}
  void dispose() {}
}
