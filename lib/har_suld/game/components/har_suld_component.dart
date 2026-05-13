import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import '../utils/constants.dart';

class HarSuldComponent extends PositionComponent {
  double hp = kHarSuldHp;
  double maxHp = kHarSuldHp;
  static const double armorReduction = kHarSuldArmorReduction;
  static const double auraRadius = kHarSuldAuraRadius;

  double auraRangeBonus = 0.0;
  double structureHpBonus = 0.0;
  double playerDamageBonus = 0.0;
  double enemySlowBonus = 0.0;

  Sprite? _sprite;

  bool get isAlive => hp > 0;

  HarSuldComponent()
      : super(
          position: kCenterPos.clone(),
          size: Vector2.all(kTileSize * 4),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    try {
      _sprite = Sprite(await Flame.images.load('HarSuld_designs/har_suld.png'));
    } catch (_) {
      // Keep painted fallback if the texture is unavailable.
    }
  }

  double get effectiveAuraRadius => auraRadius * (1 + auraRangeBonus);

  bool isInAura(Vector2 worldPos) {
    return (worldPos - position).length <= effectiveAuraRadius;
  }

  void takeDamage(double rawDamage) {
    final absorbed = rawDamage * (1 - armorReduction);
    hp = max(0, hp - absorbed);
  }

  void applyBlessing(String type) {
    const cap = 0.20;
    switch (type) {
      case 'aura_range':
        auraRangeBonus = min(cap, auraRangeBonus + 0.05);
        break;
      case 'structure_hp':
        structureHpBonus = min(cap, structureHpBonus + 0.05);
        break;
      case 'player_damage':
        playerDamageBonus = min(cap, playerDamageBonus + 0.05);
        break;
      case 'enemy_slow':
        enemySlowBonus = min(cap, enemySlowBonus + 0.05);
        break;
    }
  }

  @override
  void render(Canvas canvas) {
    final auraPaint = Paint()
      ..color = const Color(0x12FFD700)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(Offset.zero, effectiveAuraRadius, auraPaint);

    if (_sprite != null) {
      _sprite!.render(
        canvas,
        size: size,
        anchor: Anchor.center,
      );
    } else {
      final basePaint = Paint()..color = const Color(0xFF3A2A10);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: size.x, height: size.y),
        basePaint,
      );

      final stonePaint = Paint()..color = const Color(0xFF8B6914);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: size.x * 0.8, height: size.y * 0.8),
          const Radius.circular(8),
        ),
        stonePaint,
      );
    }

    final runePaint = Paint()
      ..color = const Color(0x88FFE680)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(Offset.zero, size.x * 0.18, runePaint);

    final barW = size.x + 16;
    const barH = 8.0;
    final hpFraction = hp / maxHp;
    canvas.drawRect(
      Rect.fromLTWH(-barW / 2, -size.y / 2 - 16, barW, barH),
      Paint()..color = const Color(0xFF330000),
    );
    canvas.drawRect(
      Rect.fromLTWH(-barW / 2, -size.y / 2 - 16, barW * hpFraction, barH),
      Paint()..color = const Color(0xFFFFD700),
    );
  }
}
