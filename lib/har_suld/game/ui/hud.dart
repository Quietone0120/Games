import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../components/player.dart';
import '../har_suld_game.dart';
import '../systems/inventory_system.dart';
import '../systems/wave_system.dart';

class HudOverlay extends StatefulWidget {
  final HarSuldGame game;
  const HudOverlay({super.key, required this.game});

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    widget.game.inventory.addListener(_refresh);
    _ticker = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _refresh(),
    );
  }

  @override
  void dispose() {
    widget.game.inventory.removeListener(_refresh);
    _ticker?.cancel();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  HarSuldGame get game => widget.game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _HudLayout.fromSize(constraints.biggest);
          final bottomWidth = math.max(
            220.0,
            constraints.maxWidth - layout.bottomSideReserve,
          );

          return Padding(
            padding: EdgeInsets.all(layout.edgePadding),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPlayerStatus(layout),
                      SizedBox(width: layout.sectionGap),
                      Expanded(
                        child: Center(
                          child: _buildWaveInfo(layout),
                        ),
                      ),
                      SizedBox(width: layout.sectionGap),
                      _buildHarSuldStatus(layout),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (game.player.selectedBuild != null)
                        Padding(
                          padding:
                              EdgeInsets.only(bottom: layout.compact ? 4 : 6),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: layout.compact ? 10 : 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.74),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              game.player.selectedBuild!.isWall
                                  ? 'Tap the battlefield to place ${game.player.selectedBuild!.displayName}. Use Rotate to switch 4x1 / 1x4.'
                                  : 'Tap the battlefield to place ${game.player.selectedBuild!.displayName}.',
                              style: _ts(
                                size: layout.smallText,
                                color: Colors.amber[200],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      SizedBox(
                        width: bottomWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _fitWidth(layout, _buildResourceBar(layout)),
                            SizedBox(height: layout.compact ? 4 : 6),
                            _fitWidth(layout, _buildHotbar(layout)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: layout.actionBottomInset,
                  child: _buildActionButtons(layout),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _fitWidth(_HudLayout layout, Widget child) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _buildPlayerStatus(_HudLayout layout) {
    final hp = game.player.hp;
    final maxHp = game.player.effectiveMaxHp;
    final lives = game.player.lives;
    final mounted = game.player.onHorse;

    return Container(
      padding: EdgeInsets.all(layout.panelPadding),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite, color: Colors.red, size: layout.iconSize),
              SizedBox(width: layout.inlineGap),
              Text('$lives', style: _ts(size: layout.textSize)),
              if (mounted) ...[
                SizedBox(width: layout.compact ? 5 : 8),
                Text(
                  'MOUNTED',
                  style: _ts(
                    color: Colors.amber,
                    size: layout.smallText,
                    bold: true,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: layout.compact ? 3 : 4),
          _buildBar(
            hp,
            maxHp,
            Colors.green,
            width: layout.playerBarWidth,
            height: layout.barHeight,
          ),
          const SizedBox(height: 2),
          Text(
            '${hp.toInt()}/${maxHp.toInt()}',
            style: _ts(size: layout.smallText),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveInfo(_HudLayout layout) {
    final ws = game.waveSystem;
    final phase = ws.phase;
    final wave = ws.currentWave;
    final displayedWave = phase == GamePhase.breakPhase ? wave + 1 : wave;
    final score = game.score;

    return Container(
      constraints: BoxConstraints(maxWidth: layout.wavePanelMaxWidth),
      padding: EdgeInsets.symmetric(
        horizontal: layout.compact ? 10 : 12,
        vertical: layout.compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: phase == GamePhase.wave
              ? Colors.red.withValues(alpha: 0.5)
              : Colors.amber.withValues(alpha: 0.35),
        ),
      ),
      child: phase == GamePhase.wave
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Colors.red,
                      size: layout.iconSize,
                    ),
                    SizedBox(width: layout.inlineGap),
                    Text(
                      'WAVE $displayedWave',
                      style: _ts(
                        color: Colors.red,
                        size: layout.textSize,
                        bold: true,
                      ),
                    ),
                    SizedBox(width: layout.compact ? 6 : 8),
                    Flexible(
                      child: Text(
                        '${game.world.children.whereType<dynamic>().where((c) {
                          try {
                            return c.runtimeType.toString().contains('Enemy');
                          } catch (_) {
                            return false;
                          }
                        }).length} enemies',
                        style: _ts(size: layout.smallText),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Оноо: $score',
                  style: _ts(size: layout.smallText, color: Colors.amber, bold: true),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'BREAK',
                  style: _ts(
                    color: Colors.amber,
                    size: layout.textSize,
                    bold: true,
                  ),
                ),
                Text(
                  'Оноо: $score',
                  style: _ts(size: layout.smallText, color: Colors.amber[300], bold: true),
                ),
                Text(
                  'Upcoming wave: $displayedWave',
                  style: _ts(
                    size: layout.smallText,
                    color: Colors.amber[200],
                    bold: true,
                  ),
                ),
                Text(
                  'Next wave: ${ws.timer.toInt()}s',
                  style: _ts(
                    size: layout.smallText,
                    color: Colors.grey[400],
                  ),
                ),
                SizedBox(height: layout.compact ? 4 : 5),
                GestureDetector(
                  onTap: () => game.waveSystem.skipBreak(),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: layout.compact ? 8 : 10,
                      vertical: layout.compact ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.45),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'SKIP BREAK',
                      style: _ts(
                        size: layout.smallText,
                        color: Colors.amber,
                        bold: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHarSuldStatus(_HudLayout layout) {
    final hp = game.harSuld.hp;
    final maxHp = game.harSuld.maxHp;

    return Container(
      padding: EdgeInsets.all(layout.panelPadding),
      decoration:
          _panelDecoration(borderColor: Colors.amber.withValues(alpha: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.castle, color: Colors.amber, size: layout.iconSize),
              SizedBox(width: layout.inlineGap),
              Text(
                'HAR SULD',
                style: _ts(
                  color: Colors.amber,
                  bold: true,
                  size: layout.textSize,
                ),
              ),
            ],
          ),
          SizedBox(height: layout.compact ? 3 : 4),
          _buildBar(
            hp,
            maxHp,
            Colors.amber,
            width: layout.harSuldBarWidth,
            height: layout.barHeight,
          ),
          const SizedBox(height: 2),
          Text(
            '${hp.toInt()}/${maxHp.toInt()}',
            style: _ts(size: layout.smallText, color: Colors.amber[200]),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceBar(_HudLayout layout) {
    final inv = game.inventory;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: layout.compact ? 10 : 12,
        vertical: layout.compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: layout.compact ? 4 : 6,
        runSpacing: 4,
        children: [
          _resource('🪵', inv.get(ResourceType.wood), layout),
          _resource('🪨', inv.get(ResourceType.stone), layout),
          _resource('⚙️', inv.get(ResourceType.iron), layout),
          _resource('🔩', inv.get(ResourceType.steel), layout),
          _resource('🏅', inv.get(ResourceType.gold), layout),
          _resource('💎', inv.get(ResourceType.diamond), layout),
          _resource('🐾', inv.get(ResourceType.hide), layout),
          _resource('🧵', inv.get(ResourceType.sinew), layout),
          _resource('🐺', inv.get(ResourceType.blackWolfFang), layout),
        ],
      ),
    );
  }

  Widget _resource(String icon, int amount, _HudLayout layout) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: layout.compact ? 4 : 5,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: TextStyle(fontSize: layout.resourceIconSize)),
          SizedBox(width: layout.inlineGap),
          Text('$amount', style: _ts(size: layout.resourceTextSize)),
        ],
      ),
    );
  }

  Widget _buildHotbar(_HudLayout layout) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: layout.compact ? 8 : 10,
        vertical: layout.compact ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToolSlot(
            layout: layout,
            slotLabel: '1',
            label: 'BOW',
            selected: game.player.activeTool == PlayerTool.bow,
            onTap: () {
              setState(() {
                game.player.equipTool(PlayerTool.bow);
              });
            },
            child: Padding(
              padding: EdgeInsets.all(layout.compact ? 7 : 8),
              child: Image.asset(
                'HarSuld_designs/bow.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(width: layout.compact ? 6 : 8),
          _buildToolSlot(
            layout: layout,
            slotLabel: '2',
            label: 'PICKAXE',
            selected: game.player.activeTool == PlayerTool.pickaxe,
            onTap: () {
              setState(() {
                game.player.equipTool(PlayerTool.pickaxe);
              });
            },
            child: Icon(
              Icons.construction,
              color: const Color(0xFFE0E0E0),
              size: layout.compact ? 18 : 20,
            ),
          ),
          ...List.generate(game.player.blueprintSlots.length, (index) {
            final build = game.player.blueprintSlots[index];
            final count = game.player.blueprintCounts[index];
            final towerType = game.player.blueprintTowerTypes[index];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: layout.compact ? 6 : 8),
                _buildBlueprintSlot(
                  layout: layout,
                  slotLabel: '${index + 3}',
                  build: build,
                  towerType: towerType,
                  count: count,
                  selected:
                      game.player.selectedBlueprintSlot == index && count > 0,
                  onTap: () {
                    setState(() {
                      if (build == null || count <= 0) return;
                      if (game.player.selectedBlueprintSlot == index) {
                        game.player.clearSelectedBlueprint();
                        game.setBuildType(null);
                      } else {
                        game.player.selectBlueprintSlot(index);
                        game.setBuildType(build, towerType: towerType);
                      }
                    });
                  },
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildToolSlot({
    required _HudLayout layout,
    required String slotLabel,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: layout.hotbarSlotSize + 12,
        height: layout.hotbarSlotSize,
        decoration: BoxDecoration(
          color: selected
              ? Colors.amber.withValues(alpha: 0.26)
              : Colors.black.withValues(alpha: 0.72),
          border: Border.all(
            color:
                selected ? Colors.amber : Colors.grey.withValues(alpha: 0.45),
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(layout.compact ? 7 : 8),
        ),
        child: Stack(
          children: [
            Center(child: child),
            Positioned(
              left: 4,
              top: 2,
              child: Text(
                slotLabel,
                style: _ts(
                  size: layout.hotbarNumberSize,
                  color: Colors.grey[400],
                ),
              ),
            ),
            Positioned(
              right: 5,
              bottom: 3,
              child: Text(
                label,
                style: _ts(
                  size: layout.compact ? 6.5 : 7.5,
                  color: Colors.grey[300],
                  bold: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlueprintSlot({
    required _HudLayout layout,
    required String slotLabel,
    required BuildType? build,
    required CraftedTowerType? towerType,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: layout.hotbarSlotSize,
        height: layout.hotbarSlotSize,
        decoration: BoxDecoration(
          color: selected
              ? Colors.amber.withValues(alpha: 0.26)
              : Colors.black.withValues(alpha: 0.72),
          border: Border.all(
            color:
                selected ? Colors.amber : Colors.grey.withValues(alpha: 0.45),
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(layout.compact ? 7 : 8),
        ),
        child: Stack(
          children: [
            Center(
              child: build == null || count <= 0
                  ? Text(
                      slotLabel,
                      style: _ts(
                        size: layout.compact ? 10 : 11,
                        color: Colors.grey[700],
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.all(layout.compact ? 7 : 8),
                      child: Image.asset(
                        build.previewAssetPath(
                          towerType: towerType ?? CraftedTowerType.human,
                        ),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Text(
                          slotLabel,
                          style: _ts(size: layout.smallText),
                        ),
                      ),
                    ),
            ),
            Positioned(
              left: 3,
              top: 2,
              child: Text(
                slotLabel,
                style: _ts(
                  size: layout.hotbarNumberSize,
                  color: Colors.grey[400],
                ),
              ),
            ),
            if (count > 0)
              Positioned(
                right: 3,
                bottom: 2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: _ts(
                      size: layout.hotbarNumberSize,
                      color: Colors.white,
                      bold: true,
                    ),
                  ),
                ),
              ),
            if (build?.isTower ?? false)
              Positioned(
                right: 3,
                top: 2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: _towerFamilyColor(
                      towerType ?? CraftedTowerType.human,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    (towerType ?? CraftedTowerType.human).shortLabel,
                    style: _ts(
                      size: layout.compact ? 7 : 8,
                      color: Colors.black,
                      bold: true,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(_HudLayout layout) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _actionBtn(
          layout: layout,
          label: game.player.onHorse ? 'DISMOUNT' : 'MOUNT',
          icon: Icons.directions_bike,
          color: Colors.amber,
          onTap: () {
            if (game.player.onHorse) {
              game.player.dismountExternal();
            } else {
              game.player.mountExternal();
            }
            _refresh();
          },
        ),
        SizedBox(height: layout.actionGap),
        _actionBtn(
          layout: layout,
          label:
              'HEAL ${game.inventory.getConsumable(ConsumableType.playerHealthKit)}',
          icon: Icons.favorite,
          color: Colors.redAccent,
          onTap: () => game.usePlayerHealthKit(),
        ),
        SizedBox(height: layout.actionGap),
        _actionBtn(
          layout: layout,
          label:
              'REPAIR ${game.inventory.getConsumable(ConsumableType.harSuldRepairKit)}',
          icon: Icons.build,
          color: Colors.lightBlue,
          onTap: () => game.repairNearbyStructure(),
        ),
        if (game.player.selectedBuild?.isWall ?? false) ...[
          SizedBox(height: layout.actionGap),
          _actionBtn(
            layout: layout,
            label: 'ROTATE',
            icon: Icons.rotate_right,
            color: Colors.orange,
            onTap: () => game.toggleWallRotation(),
          ),
        ],
        SizedBox(height: layout.actionGap),
        _actionBtn(
          layout: layout,
          label: 'CRAFT',
          icon: Icons.construction,
          color: Colors.green,
          onTap: () {
            if (game.overlays.isActive('BuildMenu')) {
              game.overlays.remove('BuildMenu');
            } else {
              game.overlays.add('BuildMenu');
            }
          },
        ),
        SizedBox(height: layout.actionGap),
        _actionBtn(
          layout: layout,
          label: 'MENU',
          icon: Icons.pause,
          color: Colors.white70,
          onTap: () => game.pauseGame(),
        ),
      ],
    );
  }

  Widget _actionBtn({
    required _HudLayout layout,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: layout.actionButtonWidth,
        height: layout.actionButtonHeight,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.65),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: layout.actionIconSize),
            SizedBox(height: layout.compact ? 2 : 3),
            Text(
              label,
              style: _ts(
                size: layout.actionTextSize,
                color: color,
                bold: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(
    double value,
    double max,
    Color color, {
    required double width,
    required double height,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Container(color: Colors.grey[900]),
          FractionallySizedBox(
            widthFactor: (value / max).clamp(0, 1),
            child: Container(color: color),
          ),
        ],
      ),
    );
  }

  BoxDecoration _panelDecoration({Color? borderColor}) {
    return BoxDecoration(
      color: Colors.black.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: borderColor ?? Colors.amber.withValues(alpha: 0.3),
      ),
    );
  }

  Color _towerFamilyColor(CraftedTowerType towerType) {
    switch (towerType) {
      case CraftedTowerType.human:
        return const Color(0xFF8FD3FF);
      case CraftedTowerType.beast:
        return const Color(0xFF8FE39E);
      case CraftedTowerType.siege:
        return const Color(0xFFFFC47A);
    }
  }

  TextStyle _ts({
    Color? color,
    double size = 12,
    bool bold = false,
  }) {
    return TextStyle(
      color: color ?? Colors.white,
      fontSize: size,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontFamily: 'monospace',
    );
  }
}

class GameOverOverlay extends StatelessWidget {
  final HarSuldGame game;
  final VoidCallback? onMainMenu;
  const GameOverOverlay({super.key, required this.game, this.onMainMenu});

  @override
  Widget build(BuildContext context) {
    final survived = game.waveSystem.currentWave;
    final score = game.score;
    final reason =
        game.harSuld.isAlive ? 'You fell in battle.' : 'Har Suld has fallen.';

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxHeight < 430 || constraints.maxWidth < 760;
          final width = math.min(
            compact ? 360.0 : 440.0,
            constraints.maxWidth - 24,
          );

          return Center(
            child: Container(
              width: width,
              padding: EdgeInsets.all(compact ? 20 : 28),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'THE LAST DEFENDER HAS FALLEN',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: compact ? 16 : 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: compact ? 10 : 12),
                  Text(
                    reason,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: compact ? 12 : 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Waves survived: $survived',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 14 : 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Score: $score',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: compact ? 18 : 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: compact ? 18 : 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 16 : 24,
                            vertical: compact ? 10 : 12,
                          ),
                        ),
                        onPressed: () => game.restartGame(),
                        child: const Text(
                          'DEFEND AGAIN',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (onMainMenu != null) ...[
                        SizedBox(width: compact ? 10 : 14),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 16 : 24,
                              vertical: compact ? 10 : 12,
                            ),
                          ),
                          onPressed: onMainMenu,
                          child: const Text(
                            'MAIN MENU',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PauseMenuOverlay extends StatelessWidget {
  final HarSuldGame game;
  final VoidCallback? onMainMenu;
  const PauseMenuOverlay({super.key, required this.game, this.onMainMenu});

  @override
  Widget build(BuildContext context) {
    final score = game.score;
    final wave = game.waveSystem.currentWave;

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 430 || constraints.maxWidth < 600;
            final width = math.min(compact ? 320.0 : 380.0, constraints.maxWidth - 24);

            return Container(
              width: width,
              padding: EdgeInsets.all(compact ? 20 : 28),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2A0E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.7),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ХАР СҮЛД',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: compact ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: compact ? 6 : 8),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 12 : 16,
                      vertical: compact ? 6 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text('ДАВАЛГАА', style: TextStyle(color: Colors.grey[400], fontSize: compact ? 9 : 10)),
                            Text('$wave', style: TextStyle(color: Colors.white, fontSize: compact ? 18 : 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(width: 1, height: 32, color: Colors.amber.withValues(alpha: 0.3)),
                        Column(
                          children: [
                            Text('ОНОО', style: TextStyle(color: Colors.grey[400], fontSize: compact ? 9 : 10)),
                            Text('$score', style: TextStyle(color: Colors.amber, fontSize: compact ? 18 : 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: compact ? 20 : 24),
                  _menuBtn(
                    label: 'ҮРГЭЛЖЛҮҮЛЭХ',
                    icon: Icons.play_arrow,
                    color: Colors.amber,
                    textColor: Colors.black,
                    compact: compact,
                    onTap: () => game.resumeGame(),
                  ),
                  SizedBox(height: compact ? 10 : 12),
                  _menuBtn(
                    label: 'ДАХИН ЭХЛЭХ',
                    icon: Icons.refresh,
                    color: Colors.transparent,
                    textColor: Colors.white,
                    borderColor: Colors.white38,
                    compact: compact,
                    onTap: () {
                      game.resumeEngine();
                      game.restartGame();
                    },
                  ),
                  SizedBox(height: compact ? 10 : 12),
                  _menuBtn(
                    label: 'ГАРАХ',
                    icon: Icons.exit_to_app,
                    color: Colors.transparent,
                    textColor: Colors.red[300]!,
                    borderColor: Colors.red.withValues(alpha: 0.4),
                    compact: compact,
                    onTap: () {
                      game.resumeEngine();
                      onMainMenu?.call();
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _menuBtn({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    Color? borderColor,
    required bool compact,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 20,
            vertical: compact ? 11 : 13,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            border: borderColor != null
                ? Border.all(color: borderColor, width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: compact ? 16 : 18),
              SizedBox(width: compact ? 6 : 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HudLayout {
  final bool compact;
  final double edgePadding;
  final double sectionGap;
  final double panelPadding;
  final double iconSize;
  final double inlineGap;
  final double textSize;
  final double smallText;
  final double resourceIconSize;
  final double resourceTextSize;
  final double playerBarWidth;
  final double harSuldBarWidth;
  final double barHeight;
  final double wavePanelMaxWidth;
  final double hotbarSlotSize;
  final double hotbarNumberSize;
  final double actionButtonWidth;
  final double actionButtonHeight;
  final double actionIconSize;
  final double actionTextSize;
  final double actionGap;
  final double actionBottomInset;
  final double bottomSideReserve;

  const _HudLayout({
    required this.compact,
    required this.edgePadding,
    required this.sectionGap,
    required this.panelPadding,
    required this.iconSize,
    required this.inlineGap,
    required this.textSize,
    required this.smallText,
    required this.resourceIconSize,
    required this.resourceTextSize,
    required this.playerBarWidth,
    required this.harSuldBarWidth,
    required this.barHeight,
    required this.wavePanelMaxWidth,
    required this.hotbarSlotSize,
    required this.hotbarNumberSize,
    required this.actionButtonWidth,
    required this.actionButtonHeight,
    required this.actionIconSize,
    required this.actionTextSize,
    required this.actionGap,
    required this.actionBottomInset,
    required this.bottomSideReserve,
  });

  factory _HudLayout.fromSize(Size size) {
    final compact = size.height < 430 || size.width < 760;
    return _HudLayout(
      compact: compact,
      edgePadding: compact ? 8 : 10,
      sectionGap: compact ? 6 : 10,
      panelPadding: compact ? 7 : 8,
      iconSize: compact ? 12 : 14,
      inlineGap: compact ? 2 : 3,
      textSize: compact ? 10.5 : 12,
      smallText: compact ? 9 : 10,
      resourceIconSize: compact ? 11 : 12,
      resourceTextSize: compact ? 9.5 : 11,
      playerBarWidth: compact ? 96 : 120,
      harSuldBarWidth: compact ? 104 : 130,
      barHeight: compact ? 6 : 7,
      wavePanelMaxWidth: compact ? 180 : 240,
      hotbarSlotSize: compact ? 42 : 46,
      hotbarNumberSize: compact ? 7 : 8,
      actionButtonWidth: compact ? 68 : 74,
      actionButtonHeight: compact ? 54 : 58,
      actionIconSize: compact ? 18 : 20,
      actionTextSize: compact ? 8 : 9,
      actionGap: compact ? 6 : 8,
      actionBottomInset: compact ? 92 : 104,
      bottomSideReserve: compact ? 270 : 320,
    );
  }
}
