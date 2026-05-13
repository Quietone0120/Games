import 'dart:math' as math;
import 'package:flame/components.dart';

enum Direction {
  north,
  northEast,
  east,
  southEast,
  south,
  southWest,
  west,
  northWest,
}

extension DirectionExt on Direction {
  String get folderName {
    switch (this) {
      case Direction.north:
        return 'north';
      case Direction.northEast:
        return 'north-east';
      case Direction.east:
        return 'east';
      case Direction.southEast:
        return 'south-east';
      case Direction.south:
        return 'south';
      case Direction.southWest:
        return 'south-west';
      case Direction.west:
        return 'west';
      case Direction.northWest:
        return 'north-west';
    }
  }

  static Direction fromVector(Vector2 v) {
    if (v.x == 0 && v.y == 0) return Direction.south;
    final angle = math.atan2(v.y, v.x) * 180 / math.pi;
    // Normalize to 0–360
    final norm = (angle + 360) % 360;
    if (norm < 22.5 || norm >= 337.5) return Direction.east;
    if (norm < 67.5) return Direction.southEast;
    if (norm < 112.5) return Direction.south;
    if (norm < 157.5) return Direction.southWest;
    if (norm < 202.5) return Direction.west;
    if (norm < 247.5) return Direction.northWest;
    if (norm < 292.5) return Direction.north;
    return Direction.northEast;
  }
}
