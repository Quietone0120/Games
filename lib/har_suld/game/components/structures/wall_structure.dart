import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import '../../systems/inventory_system.dart';
import '../../utils/constants.dart';

enum WallTier { wooden, cobble, iron, steel, sacred }

enum GateTier { wooden, cobble, iron, steel, sacred }

enum WallOrientation { horizontal, vertical }

class WallStructure extends PositionComponent {
  static const List<double> _maxHp = [220, 420, 760, 1180, 1600];
  static const List<double> _armor = [0.0, 0.08, 0.15, 0.22, 0.28];
  static const List<String> _frontSpriteNames = [
    'HarSuld_designs/walls/wooden wall/front-removebg-preview.png',
    'HarSuld_designs/walls/stone wall/front-removebg-preview.png',
    'HarSuld_designs/walls/iron wall/front-removebg-preview.png',
    'HarSuld_designs/walls/steel wall/front-removebg-preview.png',
    'HarSuld_designs/walls/sacred wall/front-removebg-preview.png',
  ];
  static const List<String> _sideSpriteNames = [
    'HarSuld_designs/walls/wooden wall/side-removebg-preview.png',
    'HarSuld_designs/walls/stone wall/side-removebg-preview.png',
    'HarSuld_designs/walls/iron wall/side-removebg-preview.png',
    'HarSuld_designs/walls/steel wall/side-removebg-preview.png',
    'HarSuld_designs/walls/sacred wall/side-removebg-preview.png',
  ];

  final WallTier tier;
  final int tileX;
  final int tileY;
  final WallOrientation orientation;
  final VoidCallback? onDestroyed;

  double hp;
  double maxHp;
  double armor;

  Sprite? _frontSprite;
  Sprite? _sideSprite;

  WallStructure({
    required this.tier,
    required this.tileX,
    required this.tileY,
    required this.orientation,
    this.onDestroyed,
  })  : hp = _maxHp[tier.index],
        maxHp = _maxHp[tier.index],
        armor = _armor[tier.index],
        super(
          position: Vector2(tileX * kTileSize, tileY * kTileSize),
          size: Vector2(
            orientation == WallOrientation.horizontal
                ? kTileSize * 4
                : kTileSize,
            orientation == WallOrientation.horizontal
                ? kTileSize
                : kTileSize * 4,
          ),
        );

  bool get isAlive => hp > 0;
  BuildType get buildType => WallStructure.buildTypeForTier(tier);
  Vector2 get centerPoint => position + size / 2;

  @override
  Future<void> onLoad() async {
    try {
      _frontSprite =
          Sprite(await Flame.images.load(_frontSpriteNames[tier.index]));
      _sideSprite =
          Sprite(await Flame.images.load(_sideSpriteNames[tier.index]));
    } catch (_) {
      // Fallback rendering keeps walls visible even if art is missing.
    }
  }

  void takeDamage(double rawDamage) {
    final absorbed = rawDamage * (1 - armor);
    hp -= absorbed;
    if (hp <= 0) {
      hp = 0;
      onDestroyed?.call();
      removeFromParent();
    }
  }

  void repair(double amount) {
    hp = (hp + amount).clamp(0, maxHp);
  }

  @override
  void render(Canvas canvas) {
    final sprite =
        orientation == WallOrientation.horizontal ? _frontSprite : _sideSprite;
    if (sprite != null) {
      if (orientation == WallOrientation.horizontal) {
        sprite.render(
          canvas,
          position: Vector2(0, -kTileSize),
          size: Vector2(kTileSize * 4, kTileSize * 2),
        );
      } else {
        sprite.render(
          canvas,
          position: Vector2(-kTileSize / 2, 0),
          size: Vector2(kTileSize * 2, kTileSize * 4),
        );
      }
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0xFF777777),
      );
    }

    if (hp < maxHp) {
      final hpFrac = hp / maxHp;
      canvas.drawRect(
        Rect.fromLTWH(0, size.y - 4, size.x * hpFrac, 4),
        Paint()..color = const Color(0xFF44FF44),
      );
    }
    if (hp / maxHp < 0.3) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()
          ..color = const Color(0xAAFF4400)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  static BuildType buildTypeForTier(WallTier tier) {
    switch (tier) {
      case WallTier.wooden:
        return BuildType.woodenWall;
      case WallTier.cobble:
        return BuildType.cobbleWall;
      case WallTier.iron:
        return BuildType.ironWall;
      case WallTier.steel:
        return BuildType.steelWall;
      case WallTier.sacred:
        return BuildType.sacredWall;
    }
  }
}

class GateStructure extends PositionComponent {
  static const List<double> _maxHp = [180, 360, 650, 980, 1400];
  static const List<double> _armor = [0.0, 0.06, 0.12, 0.20, 0.28];
  static const List<String> _spriteNames = [
    'HarSuld_designs/gate/wooden-removebg-preview.png',
    'HarSuld_designs/gate/stone-removebg-preview.png',
    'HarSuld_designs/gate/iron-removebg-preview.png',
    'HarSuld_designs/gate/steel-removebg-preview.png',
    'HarSuld_designs/gate/sacred-removebg-preview.png',
  ];

  final GateTier tier;
  final int tileX;
  final int tileY;
  final VoidCallback? onDestroyed;

  double hp;
  double maxHp;
  double armor;
  bool isOpen = false;
  double _openTimer = 0;
  Sprite? _sprite;

  GateStructure({
    required this.tier,
    required this.tileX,
    required this.tileY,
    this.onDestroyed,
  })  : hp = _maxHp[tier.index],
        maxHp = _maxHp[tier.index],
        armor = _armor[tier.index],
        super(
          position: Vector2(tileX * kTileSize, tileY * kTileSize),
          size: Vector2.all(kTileSize * 3),
        );

  bool get isAlive => hp > 0;
  BuildType get buildType => GateStructure.buildTypeForTier(tier);
  Vector2 get centerPoint => position + size / 2;

  @override
  Future<void> onLoad() async {
    try {
      final img = await Flame.images.load(_spriteNames[tier.index]);
      _sprite = Sprite(img);
    } catch (_) {
      // Fallback to primitive rendering below.
    }
  }

  void takeDamage(double rawDamage) {
    final absorbed = rawDamage * (1 - armor);
    hp -= absorbed;
    if (hp <= 0) {
      hp = 0;
      onDestroyed?.call();
      removeFromParent();
    }
  }

  void repair(double amount) {
    hp = (hp + amount).clamp(0, maxHp);
  }

  void open() {
    isOpen = true;
    _openTimer = 1.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isOpen) {
      _openTimer -= dt;
      if (_openTimer <= 0) isOpen = false;
    }
  }

  @override
  void render(Canvas canvas) {
    if (!isOpen) {
      if (_sprite != null) {
        _sprite!.render(canvas, size: size);
      } else {
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.x, size.y),
          Paint()..color = const Color(0xFFAA6622),
        );
      }
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0x22332211),
      );
    }

    if (hp < maxHp) {
      canvas.drawRect(
        Rect.fromLTWH(0, size.y - 4, size.x * (hp / maxHp), 4),
        Paint()..color = const Color(0xFF44FF44),
      );
    }
  }

  static BuildType buildTypeForTier(GateTier tier) {
    switch (tier) {
      case GateTier.wooden:
        return BuildType.woodenGate;
      case GateTier.cobble:
        return BuildType.cobbleGate;
      case GateTier.iron:
        return BuildType.ironGate;
      case GateTier.steel:
        return BuildType.steelGate;
      case GateTier.sacred:
        return BuildType.sacredGate;
    }
  }
}
