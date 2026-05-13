import 'dart:ui';
import 'package:flame/components.dart';
import '../utils/constants.dart';
import '../systems/inventory_system.dart';

enum ResourceNodeType { tree, rock, ore }

class ResourceNode extends PositionComponent {
  final ResourceNodeType nodeType;
  final int tileX;
  final int tileY;
  double hp;
  bool depleted = false;

  static const Map<ResourceNodeType, double> _maxHp = {
    ResourceNodeType.tree: 45,
    ResourceNodeType.rock: 70,
    ResourceNodeType.ore: 90,
  };

  static final Map<ResourceNodeType, Paint> _paints = {
    ResourceNodeType.tree: Paint()..color = const Color(0xFF1A4010),
    ResourceNodeType.rock: Paint()..color = const Color(0xFF555555),
    ResourceNodeType.ore: Paint()..color = const Color(0xFF6B4E10),
  };

  ResourceNode({
    required this.nodeType,
    required this.tileX,
    required this.tileY,
  }) : hp = _maxHp[nodeType]!,
       super(
         position: Vector2(tileX * kTileSize + kTileSize / 2, tileY * kTileSize + kTileSize / 2),
         size: Vector2.all(kTileSize * 0.8),
         anchor: Anchor.center,
       );

  bool get isAlive => hp > 0;

  /// Returns resources harvested (15 damage per cycle).
  Map<ResourceType, int>? harvest() {
    if (depleted) return null;
    const harvestDamage = 15.0;
    hp -= harvestDamage;
    if (hp <= 0) {
      hp = 0;
      depleted = true;
      removeFromParent();
      return _getDrops();
    }
    return _getPartialDrop();
  }

  Map<ResourceType, int> _getDrops() {
    switch (nodeType) {
      case ResourceNodeType.tree:
        return {ResourceType.wood: 18 + _maxHp[nodeType]!.toInt() ~/ 10};
      case ResourceNodeType.rock:
        return {ResourceType.stone: 14, ResourceType.iron: 0};
      case ResourceNodeType.ore:
        final roll = (hp / _maxHp[nodeType]!);
        if (roll > 0.55) return {ResourceType.iron: 10};
        if (roll > 0.25) return {ResourceType.steel: 5};
        if (roll > 0.15) return {ResourceType.gold: 4};
        return {ResourceType.diamond: 1};
    }
  }

  Map<ResourceType, int> _getPartialDrop() {
    switch (nodeType) {
      case ResourceNodeType.tree:
        return {ResourceType.wood: 5};
      case ResourceNodeType.rock:
        return {ResourceType.stone: 4};
      case ResourceNodeType.ore:
        return {ResourceType.iron: 3};
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect().translate(-size.x / 2, -size.y / 2);
    canvas.drawRect(rect, _paints[nodeType]!);

    // Draw HP bar
    if (hp < _maxHp[nodeType]!) {
      final barW = size.x;
      final barH = 4.0;
      final barRect = Rect.fromLTWH(-barW / 2, -size.y / 2 - 6, barW * (hp / _maxHp[nodeType]!), barH);
      canvas.drawRect(barRect, Paint()..color = const Color(0xFF44AA44));
    }
  }
}
