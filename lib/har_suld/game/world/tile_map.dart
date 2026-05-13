import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import '../har_suld_game.dart';
import '../systems/inventory_system.dart';
import '../utils/constants.dart';

enum TileType {
  grass,
  forest,
  rock,
  ore,
  sacred,
}

class TileData {
  TileType type;
  double resourceHp;
  bool occupied;

  TileData(this.type, {this.resourceHp = 0, this.occupied = false});

  bool get isHarvestable =>
      (type == TileType.forest ||
          type == TileType.rock ||
          type == TileType.ore) &&
      resourceHp > 0;
}

class TileHarvestResult {
  final Map<ResourceType, int> drops;
  final bool depleted;

  const TileHarvestResult({
    required this.drops,
    required this.depleted,
  });
}

class TileMap extends Component with HasGameReference<HarSuldGame> {
  static const _sacredRadius = 18;

  late final List<List<TileData>> tiles;
  final _rng = Random(42);

  Sprite? _groundSprite;
  Sprite? _tree1Sprite;
  Sprite? _tree2Sprite;
  Sprite? _oreSprite;

  static final _fallbackPaints = <TileType, Paint>{
    TileType.grass: Paint()..color = const Color(0xFF5A8A3A),
    TileType.forest: Paint()..color = const Color(0xFF2D5A1B),
    TileType.rock: Paint()..color = const Color(0xFF7A7A7A),
    TileType.ore: Paint()..color = const Color(0xFF8B6310),
    TileType.sacred: Paint()..color = const Color(0xFF6A9A4A),
  };

  TileMap() {
    _generate();
  }

  @override
  Future<void> onLoad() async {
    try {
      _groundSprite =
          Sprite(await Flame.images.load('HarSuld_designs/ground_texture.png'));
      _tree1Sprite =
          Sprite(await Flame.images.load('HarSuld_designs/tree/tree1.png'));
      _tree2Sprite =
          Sprite(await Flame.images.load('HarSuld_designs/tree/tree2.png'));
      _oreSprite =
          Sprite(await Flame.images.load('HarSuld_designs/rare_ore_rock.png'));
    } catch (_) {
      // Texture fallback keeps the world playable even if an asset is missing.
    }
  }

  void _generate() {
    tiles = List.generate(
      kMapSize,
      (y) => List.generate(kMapSize, (x) {
        final dx = x - kMapCenter;
        final dy = y - kMapCenter;
        final dist = sqrt(dx * dx + dy * dy);

        if (dist <= _sacredRadius) {
          return TileData(TileType.sacred);
        }

        final rng = _rng.nextDouble();
        final resourceBonus = (dist / kMapCenter).clamp(0.0, 1.0) * 0.15;

        if (rng < 0.12 + resourceBonus) {
          return TileData(TileType.forest, resourceHp: 45);
        } else if (rng < 0.18 + resourceBonus) {
          return TileData(TileType.rock, resourceHp: 70);
        } else if (rng < 0.20 + resourceBonus * 0.5) {
          return TileData(TileType.ore, resourceHp: 90);
        }
        return TileData(TileType.grass);
      }),
    );
  }

  TileData? tileAt(int tx, int ty) {
    if (tx < 0 || ty < 0 || tx >= kMapSize || ty >= kMapSize) return null;
    return tiles[ty][tx];
  }

  TileData? tileAtPixel(double px, double py) {
    return tileAt((px / kTileSize).floor(), (py / kTileSize).floor());
  }

  void setOccupied(int tx, int ty, bool value) {
    tileAt(tx, ty)?.occupied = value;
  }

  TileHarvestResult? harvestTile(int tx, int ty) {
    final tile = tileAt(tx, ty);
    if (tile == null || !tile.isHarvestable) {
      return null;
    }

    const harvestDamage = 15.0;
    tile.resourceHp -= harvestDamage;
    final depleted = tile.resourceHp <= 0;
    final drops = depleted ? _getDrops(tile.type) : _getPartialDrop(tile.type);

    if (depleted) {
      tile.resourceHp = 0;
      tile.type = TileType.grass;
    }

    return TileHarvestResult(drops: drops, depleted: depleted);
  }

  Map<ResourceType, int> _getDrops(TileType type) {
    switch (type) {
      case TileType.forest:
        return {ResourceType.wood: 18};
      case TileType.rock:
        return {ResourceType.stone: 14};
      case TileType.ore:
        return {
          ResourceType.iron: 8,
          ResourceType.steel: 3,
          ResourceType.gold: 1,
        };
      case TileType.grass:
      case TileType.sacred:
        return const {};
    }
  }

  Map<ResourceType, int> _getPartialDrop(TileType type) {
    switch (type) {
      case TileType.forest:
        return {ResourceType.wood: 5};
      case TileType.rock:
        return {ResourceType.stone: 4};
      case TileType.ore:
        return {ResourceType.iron: 3};
      case TileType.grass:
      case TileType.sacred:
        return const {};
    }
  }

  @override
  void render(Canvas canvas) {
    final cam = game.camera;
    final zoom = cam.viewfinder.zoom;
    final screenSize = game.size;
    final camPos = cam.viewfinder.position;

    final halfW = screenSize.x / (2 * zoom);
    final halfH = screenSize.y / (2 * zoom);

    final startX = ((camPos.x - halfW) / kTileSize).floor() - 1;
    final endX = ((camPos.x + halfW) / kTileSize).ceil() + 1;
    final startY = ((camPos.y - halfH) / kTileSize).floor() - 1;
    final endY = ((camPos.y + halfH) / kTileSize).ceil() + 1;

    final x0 = startX.clamp(0, kMapSize - 1);
    final x1 = endX.clamp(0, kMapSize - 1);
    final y0 = startY.clamp(0, kMapSize - 1);
    final y1 = endY.clamp(0, kMapSize - 1);

    for (int y = y0; y <= y1; y++) {
      for (int x = x0; x <= x1; x++) {
        final tile = tiles[y][x];
        final tileRect = Rect.fromLTWH(
          x * kTileSize,
          y * kTileSize,
          kTileSize,
          kTileSize,
        );

        if (_groundSprite != null) {
          _groundSprite!.renderRect(canvas, tileRect);
        } else {
          canvas.drawRect(tileRect, _fallbackPaints[TileType.grass]!);
        }

        if (tile.type == TileType.sacred) {
          canvas.drawRect(
            tileRect,
            Paint()..color = const Color(0x224F7D2A),
          );
        } else if (tile.type == TileType.forest) {
          _renderTree(canvas, x, y);
        } else if (tile.type == TileType.rock) {
          _renderRock(canvas, x, y, oreVariant: false);
        } else if (tile.type == TileType.ore) {
          _renderRock(canvas, x, y, oreVariant: true);
        }
      }
    }

    final auraCenter = Offset(
      kMapCenter * kTileSize,
      kMapCenter * kTileSize,
    );
    final auraPaint = Paint()
      ..color = const Color(0x18FFD700)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(auraCenter, 16 * kTileSize, auraPaint);
  }

  void _renderTree(Canvas canvas, int x, int y) {
    final sprite = ((x + y) % 2 == 0 ? _tree1Sprite : _tree2Sprite);
    final rect = Rect.fromLTWH(
      x * kTileSize - kTileSize * 0.2,
      y * kTileSize - kTileSize * 0.55,
      kTileSize * 1.4,
      kTileSize * 1.6,
    );

    if (sprite != null) {
      sprite.renderRect(canvas, rect);
    } else {
      canvas.drawOval(
        rect,
        Paint()..color = _fallbackPaints[TileType.forest]!.color,
      );
    }
  }

  void _renderRock(Canvas canvas, int x, int y, {required bool oreVariant}) {
    final rect = Rect.fromLTWH(
      x * kTileSize + kTileSize * 0.05,
      y * kTileSize + kTileSize * 0.05,
      kTileSize * 0.9,
      kTileSize * 0.9,
    );

    if (_oreSprite != null) {
      final tint = oreVariant
          ? null
          : (Paint()
            ..colorFilter =
                const ColorFilter.mode(Color(0xAA9A9A9A), BlendMode.modulate));
      _oreSprite!.renderRect(canvas, rect, overridePaint: tint);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()
          ..color =
              _fallbackPaints[oreVariant ? TileType.ore : TileType.rock]!.color,
      );
    }
  }
}
