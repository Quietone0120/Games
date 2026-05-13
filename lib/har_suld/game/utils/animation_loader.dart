import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'direction.dart';

class AnimationLoader {
  /// Loads a sequence of frame_000.png … frame_NNN.png from [basePath].
  static Future<SpriteAnimation> loadFrameSequence({
    required String basePath,
    required int frameCount,
    required double stepTime,
    bool loop = true,
  }) async {
    final frames = <SpriteAnimationFrame>[];
    for (int i = 0; i < frameCount; i++) {
      final frameNum = i.toString().padLeft(3, '0');
      final img = await Flame.images.load('$basePath/frame_$frameNum.png');
      frames.add(SpriteAnimationFrame(Sprite(img), stepTime));
    }
    return SpriteAnimation(frames, loop: loop);
  }

  /// Loads directional animations for all 8 directions.
  /// [characterPath] e.g. 'HarSuld_designs/player'
  /// [animationName] e.g. 'Running'
  /// [dirFolderOverrides] for special folder names (like south-west variants).
  static Future<Map<Direction, SpriteAnimation>> loadDirectionalAnimations({
    required String characterPath,
    required String animationName,
    required int frameCount,
    required double stepTime,
    bool loop = true,
    Map<Direction, String>? dirFolderOverrides,
  }) async {
    final result = <Direction, SpriteAnimation>{};
    for (final dir in Direction.values) {
      final folderName = dirFolderOverrides?[dir] ?? dir.folderName;
      final path = '$characterPath/animations/$animationName/$folderName';
      result[dir] = await loadFrameSequence(
        basePath: path,
        frameCount: frameCount,
        stepTime: stepTime,
        loop: loop,
      );
    }
    return result;
  }

  /// Loads directional animations for a subset of directions.
  static Future<Map<Direction, SpriteAnimation>> loadDirectionalAnimationsSubset({
    required String characterPath,
    required String animationName,
    required int frameCount,
    required double stepTime,
    required List<Direction> directions,
    bool loop = true,
  }) async {
    final result = <Direction, SpriteAnimation>{};
    for (final dir in directions) {
      final path = '$characterPath/animations/$animationName/${dir.folderName}';
      result[dir] = await loadFrameSequence(
        basePath: path,
        frameCount: frameCount,
        stepTime: stepTime,
        loop: loop,
      );
    }
    return result;
  }
}
