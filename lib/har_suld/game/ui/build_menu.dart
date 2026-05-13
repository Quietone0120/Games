import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../components/structures/tower_structure.dart';
import '../har_suld_game.dart';
import '../systems/inventory_system.dart';
import '../utils/constants.dart';

class BuildMenuOverlay extends StatelessWidget {
  final HarSuldGame game;
  const BuildMenuOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxHeight < 430 || constraints.maxWidth < 760;
          final width = math.min(
            compact ? 380.0 : 480.0,
            constraints.maxWidth - 20,
          );
          final height = math.min(
            compact ? constraints.maxHeight - 16 : 560.0,
            constraints.maxHeight - 16,
          );

          return DefaultTabController(
            length: 4,
            child: Center(
              child: Container(
                width: width,
                height: height,
                padding: EdgeInsets.all(compact ? 12 : 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0E0C).withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CRAFTING HALL',
                                style: TextStyle(
                                  color: Colors.amber[300],
                                  fontSize: compact ? 18 : 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Forge blueprints, then place them on open grass tiles around Har Suld.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: compact ? 11 : 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => game.overlays.remove('BuildMenu'),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 10 : 12),
                    _buildResourceSummary(compact),
                    SizedBox(height: compact ? 10 : 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TabBar(
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.white70,
                        indicator: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        tabs: const [
                          Tab(text: 'Walls'),
                          Tab(text: 'Gates'),
                          Tab(text: 'Towers'),
                          Tab(text: 'Gear'),
                        ],
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 12),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildList(_wallTypes),
                          _buildList(_gateTypes),
                          _buildTowerList(),
                          _buildGearList(),
                        ],
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 10),
                    Text(
                      'Tip: pick a blueprint here, then tap the battlefield to build. Trees and ore need to be cleared first.',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: compact ? 10 : 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<BuildType> get _wallTypes => const [
        BuildType.woodenWall,
        BuildType.cobbleWall,
        BuildType.ironWall,
        BuildType.steelWall,
        BuildType.sacredWall,
      ];

  List<BuildType> get _gateTypes => const [
        BuildType.woodenGate,
        BuildType.cobbleGate,
        BuildType.ironGate,
        BuildType.steelGate,
        BuildType.sacredGate,
      ];

  List<BuildType> get _towerTypes => const [
        BuildType.woodenTower,
        BuildType.cobbleTower,
        BuildType.ironTower,
        BuildType.steelTower,
        BuildType.sacredTower,
      ];

  Widget _buildResourceSummary(bool compact) {
    final inv = game.inventory;
    final chips = [
      ('🪵', inv.get(ResourceType.wood)),
      ('🪨', inv.get(ResourceType.stone)),
      ('⚙️', inv.get(ResourceType.iron)),
      ('🔩', inv.get(ResourceType.steel)),
      ('🏅', inv.get(ResourceType.gold)),
      ('💎', inv.get(ResourceType.diamond)),
      ('🐾', inv.get(ResourceType.hide)),
      ('🧵', inv.get(ResourceType.sinew)),
      ('🐺', inv.get(ResourceType.blackWolfFang)),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final chip in chips)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 10,
              vertical: compact ? 4 : 5,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              '${chip.$1} ${chip.$2}',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildList(List<BuildType> types) {
    return ListView.separated(
      itemCount: types.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildCard(types[index]),
    );
  }

  Widget _buildTowerList() {
    return ListView(
      children: [
        _buildTowerSection(CraftedTowerType.human),
        const SizedBox(height: 12),
        _buildTowerSection(CraftedTowerType.beast),
        const SizedBox(height: 12),
        _buildTowerSection(CraftedTowerType.siege),
      ],
    );
  }

  Widget _buildGearList() {
    final nextCost = game.inventory.nextBowUpgradeCost(game.player.bowTier);
    final canUpgrade = game.inventory.canUpgradeBow(game.player.bowTier);
    final maxed = nextCost == null;
    final repairKitCount =
        game.inventory.getConsumable(ConsumableType.harSuldRepairKit);
    final healthKitCount =
        game.inventory.getConsumable(ConsumableType.playerHealthKit);

    return ListView(
      children: [
        _buildConsumableCard(
          title: 'Har Suld Repair Kit',
          description:
              'Used by the repair button to restore walls, gates, and towers.',
          count: repairKitCount,
          consumableType: ConsumableType.harSuldRepairKit,
          icon: Icons.shield_outlined,
          accent: Colors.lightBlueAccent,
        ),
        const SizedBox(height: 8),
        _buildConsumableCard(
          title: 'Player Health Kit',
          description: 'Use from the HUD to quickly heal the player.',
          count: healthKitCount,
          consumableType: ConsumableType.playerHealthKit,
          icon: Icons.favorite,
          accent: Colors.redAccent,
        ),
        const SizedBox(height: 12),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: maxed
              ? null
              : () {
                  if (!game.inventory.tryUpgradeBow(game.player.bowTier)) {
                    return;
                  }
                  game.player.bowTier++;
                  game.inventory.bowTier = game.player.bowTier;
                  game.overlays.remove('BuildMenu');
                },
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: canUpgrade
                  ? Colors.amber.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: maxed
                    ? Colors.amber
                    : canUpgrade
                        ? Colors.lightBlueAccent.withValues(alpha: 0.8)
                        : Colors.white12,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(
                    'HarSuld_designs/bow.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        maxed
                            ? 'Bow Mastery Complete'
                            : 'Upgrade Bow to Tier ${game.player.bowTier + 2}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        maxed
                            ? 'Your bow is already at the final tier.'
                            : 'Damage ${kBowTiers[game.player.bowTier]['damage']!.toInt()} -> ${kBowTiers[game.player.bowTier + 1]['damage']!.toInt()}  |  Range ${kBowTiers[game.player.bowTier]['range']!.toStringAsFixed(1)} -> ${kBowTiers[game.player.bowTier + 1]['range']!.toStringAsFixed(1)} tiles.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (nextCost != null)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: nextCost.entries
                              .map(
                                (entry) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${_resourceIcon(entry.key)} ${entry.value}',
                                    style: TextStyle(
                                      color: canUpgrade
                                          ? Colors.white
                                          : Colors.red[300],
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTowerSection(CraftedTowerType towerType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          towerType.label.toUpperCase(),
          style: TextStyle(
            color: Colors.amber[200],
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          towerType.shortDescription,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 8),
        ..._towerTypes.map((type) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildCard(type, towerType: towerType),
            )),
      ],
    );
  }

  Widget _buildCard(BuildType type,
      {CraftedTowerType towerType = CraftedTowerType.human}) {
    final canAfford = game.inventory.canBuild(type);
    final isSelected = game.player.selectedBuild == type &&
        (!type.isTower || game.player.selectedTowerType == towerType);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        if (!canAfford) return;
        if (!game.inventory.tryBuild(type)) return;
        game.player.craftBlueprint(type, towerType: towerType);
        game.setBuildType(type, towerType: towerType);
        game.overlays.remove('BuildMenu');
      },
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.amber.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.amber
                : canAfford
                    ? Colors.white12
                    : Colors.red.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 68,
              height: 68,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      type.previewAssetPath(towerType: towerType),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          _buildIcon(type),
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                  if (type.isTower)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: _towerFamilyBadge(towerType),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          type.displayNameWithTowerType(towerType: towerType),
                          style: TextStyle(
                            color: canAfford ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!canAfford)
                        const Icon(Icons.lock, color: Colors.red, size: 16),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type.isTower
                        ? '${type.shortDescription} Range: ${_towerRange(type).toStringAsFixed(1)} tiles.'
                        : type.shortDescription,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          type.isTower ? towerType.label : type.categoryLabel,
                          style: TextStyle(
                            color: Colors.amber[200],
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      ...type.cost.entries.map(
                        (entry) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${_resourceIcon(entry.key)} ${entry.value}',
                            style: TextStyle(
                              color: canAfford ? Colors.white : Colors.red[300],
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _towerRange(BuildType type) {
    return type.isTower ? TowerStructure.rangeTilesForBuildType(type) : 0;
  }

  Widget _buildConsumableCard({
    required String title,
    required String description,
    required int count,
    required ConsumableType consumableType,
    required IconData icon,
    required Color accent,
  }) {
    final cost = game.inventory.consumableCost(consumableType);
    final canAfford = game.inventory.canCraftConsumable(consumableType);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        if (!game.inventory.craftConsumable(consumableType)) return;
        game.overlays.remove('BuildMenu');
      },
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: canAfford
                ? accent.withValues(alpha: 0.7)
                : Colors.red.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Owned $count',
                          style: TextStyle(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: cost.entries
                        .map(
                          (entry) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${_resourceIcon(entry.key)} ${entry.value}',
                              style: TextStyle(
                                color:
                                    canAfford ? Colors.white : Colors.red[300],
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _towerFamilyBadge(CraftedTowerType towerType) {
    final color = _towerFamilyColor(towerType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        towerType.shortLabel,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
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

  String _buildIcon(BuildType type) {
    switch (type) {
      case BuildType.woodenWall:
        return '🪵';
      case BuildType.cobbleWall:
        return '🪨';
      case BuildType.ironWall:
        return '⚙️';
      case BuildType.steelWall:
        return '🔩';
      case BuildType.sacredWall:
        return '✨';
      case BuildType.woodenGate:
      case BuildType.cobbleGate:
        return '🚪';
      case BuildType.ironGate:
      case BuildType.steelGate:
        return '🛡️';
      case BuildType.sacredGate:
        return '🌟';
      case BuildType.woodenTower:
        return '🏰';
      case BuildType.cobbleTower:
        return '🗼';
      case BuildType.ironTower:
        return '⚔️';
      case BuildType.steelTower:
        return '🏯';
      case BuildType.sacredTower:
        return '⭐';
    }
  }

  String _resourceIcon(ResourceType type) {
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
