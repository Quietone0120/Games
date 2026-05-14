import 'dart:async';
import 'package:flutter/material.dart';
import '../components/structures/tower_structure.dart';
import '../components/structures/wall_structure.dart';
import '../har_suld_game.dart';
import '../systems/inventory_system.dart';

class StructureMenuOverlay extends StatefulWidget {
  final HarSuldGame game;
  const StructureMenuOverlay({super.key, required this.game});

  @override
  State<StructureMenuOverlay> createState() => _StructureMenuOverlayState();
}

class _StructureMenuOverlayState extends State<StructureMenuOverlay> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    widget.game.inventory.addListener(_refresh);
    _ticker =
        Timer.periodic(const Duration(milliseconds: 200), (_) => _refresh());
  }

  @override
  void dispose() {
    widget.game.inventory.removeListener(_refresh);
    _ticker?.cancel();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  HarSuldGame get game => widget.game;

  @override
  Widget build(BuildContext context) {
    final structure = game.selectedStructure;
    if (structure == null) return const SizedBox.shrink();

    final buildType = _buildTypeForStructure(structure);
    final nextType = _nextBuildType(buildType);
    final canUpgrade = nextType != null && game.inventory.canBuild(nextType);
    final hp = _currentHp(structure);
    final maxHp = _maxHp(structure);
    final title = _title(structure);
    final repairCount =
        game.inventory.getConsumable(ConsumableType.harSuldRepairKit);
    final canRepair = hp < maxHp && repairCount > 0;

    return SafeArea(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 8, top: 24),
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        game.selectedStructure = null;
                        game.overlays.remove('StructureMenu');
                      },
                      icon: const Icon(Icons.close, color: Colors.white70),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _line('Health', '${hp.toInt()} / ${maxHp.toInt()}'),
                _buildBar(hp, maxHp),
                const SizedBox(height: 8),
                ..._stats(structure),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canRepair
                            ? () {
                                game.repairSelectedStructure();
                                _refresh();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue,
                          foregroundColor: Colors.black,
                        ),
                        child: Text(
                          hp >= maxHp
                              ? 'Fully Repaired'
                              : 'Use Har Suld Kit ($repairCount)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canUpgrade
                            ? () {
                                game.upgradeSelectedStructure();
                                _refresh();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: Colors.grey[800],
                          disabledForegroundColor: Colors.white54,
                        ),
                        child: Text(
                          nextType == null
                              ? 'Max Tier'
                              : 'Upgrade ${_formatCost(nextType.cost)}',
                        ),
                      ),
                    ),
                  ],
                ),
                if (nextType != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Next: ${nextType.displayNameWithTowerType(towerType: _towerType(structure))}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  BuildType _buildTypeForStructure(Object structure) {
    if (structure is WallStructure) return structure.buildType;
    if (structure is GateStructure) return structure.buildType;
    if (structure is TowerStructure) return structure.buildType;
    throw ArgumentError('Unknown structure');
  }

  CraftedTowerType _towerType(Object structure) {
    if (structure is TowerStructure) return structure.towerType;
    return CraftedTowerType.human;
  }

  double _currentHp(Object structure) {
    if (structure is WallStructure) return structure.hp;
    if (structure is GateStructure) return structure.hp;
    if (structure is TowerStructure) return structure.hp;
    return 0;
  }

  double _maxHp(Object structure) {
    if (structure is WallStructure) return structure.maxHp;
    if (structure is GateStructure) return structure.maxHp;
    if (structure is TowerStructure) return structure.maxHp;
    return 1;
  }

  String _title(Object structure) {
    if (structure is TowerStructure) {
      return structure.buildType
          .displayNameWithTowerType(towerType: structure.towerType);
    }
    return _buildTypeForStructure(structure).displayName;
  }

  List<Widget> _stats(Object structure) {
    if (structure is WallStructure) {
      return [
        _line(
            'Footprint',
            structure.orientation == WallOrientation.horizontal
                ? '4 x 1'
                : '1 x 4'),
        _line('Armor', '${(structure.armor * 100).toStringAsFixed(0)}%'),
      ];
    }
    if (structure is GateStructure) {
      return [
        const SizedBox(height: 2),
        _line('Footprint', '3 x 3'),
        _line('Armor', '${(structure.armor * 100).toStringAsFixed(0)}%'),
      ];
    }
    if (structure is TowerStructure) {
      return [
        _line('Focus', structure.towerType.label),
        _line('Damage', structure.damage.toStringAsFixed(0)),
        _line('Range', '${(structure.range / 32).toStringAsFixed(1)} tiles'),
        _line(
            'Attack Speed', '${structure.attackInterval.toStringAsFixed(2)}s'),
        _line('Footprint', '3 x 3'),
      ];
    }
    return const [];
  }

  BuildType? _nextBuildType(BuildType current) {
    const walls = [
      BuildType.woodenWall,
      BuildType.cobbleWall,
      BuildType.ironWall,
      BuildType.steelWall,
      BuildType.sacredWall,
    ];
    const gates = [
      BuildType.woodenGate,
      BuildType.cobbleGate,
      BuildType.ironGate,
      BuildType.steelGate,
      BuildType.sacredGate,
    ];
    const towers = [
      BuildType.woodenTower,
      BuildType.cobbleTower,
      BuildType.ironTower,
      BuildType.steelTower,
      BuildType.sacredTower,
    ];

    final chain = current.isWall
        ? walls
        : current.isGate
            ? gates
            : towers;
    final index = chain.indexOf(current);
    if (index == -1 || index == chain.length - 1) return null;
    return chain[index + 1];
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double hp, double maxHp) {
    return Container(
      width: double.infinity,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(999),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: (hp / maxHp).clamp(0, 1),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }

  String _formatCost(Map<ResourceType, int> cost) {
    return cost.entries
        .map((entry) => '${_icon(entry.key)}${entry.value}')
        .join(' ');
  }

  String _icon(ResourceType type) {
    switch (type) {
      case ResourceType.wood:
        return '🪵';
      case ResourceType.stone:
        return '🪨';
      case ResourceType.iron:
        return '⚙️';
      case ResourceType.steel:
        return '🔩';
      case ResourceType.gold:
        return '🏅';
      case ResourceType.diamond:
        return '💎';
      case ResourceType.hide:
        return '🐾';
      case ResourceType.sinew:
        return '🧵';
      case ResourceType.blackWolfFang:
        return '🐺';
    }
  }
}
