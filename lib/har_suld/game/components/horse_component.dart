import 'dart:ui';
import 'package:flame/components.dart';
import '../utils/constants.dart';
import '../utils/direction.dart';
import '../utils/animation_loader.dart';

class HorseComponent extends PositionComponent {
  static Map<Direction, SpriteAnimation>? _runCache;
  static Map<Direction, SpriteAnimation>? _idleCache;

  static const String _path = 'HarSuld_designs/horse/horse_alone';

  SpriteAnimationComponent? _animComp;
  Direction direction = Direction.south;
  bool riderMounted = false;

  HorseComponent()
      : super(
          // Start near Har Suld
          position: kCenterPos.clone() + Vector2(kTileSize * 4, 0),
          size: Vector2.all(kHorseSpriteSize),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    _runCache ??= await AnimationLoader.loadDirectionalAnimations(
      characterPath: _path,
      animationName: 'animation-f2b7a373',
      frameCount: 8,
      stepTime: 0.07,
    );
    _idleCache ??= await AnimationLoader.loadDirectionalAnimations(
      characterPath: _path,
      animationName: 'Idle_Shaking_Head-2cb3e72f',
      frameCount: 11,
      stepTime: 0.10,
    );

    _animComp = SpriteAnimationComponent(
      animation: _idleCache![Direction.south],
      size: size,
      anchor: Anchor.center,
    );
    add(_animComp!);
  }

  void setDirection(Direction dir) {
    if (dir == direction) return;
    direction = dir;
    _updateAnim();
  }

  void setMoving(bool moving) {
    if (moving) {
      _animComp?.animation = _runCache?[direction] ?? _runCache?[Direction.south];
    } else {
      _animComp?.animation = _idleCache?[direction] ?? _idleCache?[Direction.south];
    }
  }

  void _updateAnim() {
    _animComp?.animation = _idleCache?[direction] ?? _idleCache?[Direction.south];
  }

  @override
  void render(Canvas canvas) {
    if (_animComp == null) {
      // Fallback horse shape
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: size.x * 0.9, height: size.y * 0.6),
        Paint()..color = const Color(0xFF8B4513),
      );
    }
  }
}
