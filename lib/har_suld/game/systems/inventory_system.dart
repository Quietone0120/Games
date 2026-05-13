import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

enum ResourceType {
  wood,
  stone,
  iron,
  steel,
  gold,
  diamond,
  hide,
  sinew,
  blackWolfFang,
}

enum BuildType {
  woodenWall,
  cobbleWall,
  ironWall,
  steelWall,
  sacredWall,
  woodenGate,
  cobbleGate,
  ironGate,
  steelGate,
  sacredGate,
  woodenTower,
  cobbleTower,
  ironTower,
  steelTower,
  sacredTower,
}

enum CraftedTowerType { human, beast, siege }

enum ConsumableType { harSuldRepairKit, playerHealthKit }

extension CraftedTowerTypeExt on CraftedTowerType {
  String get label {
    switch (this) {
      case CraftedTowerType.human:
        return 'Human Tower';
      case CraftedTowerType.beast:
        return 'Beast Tower';
      case CraftedTowerType.siege:
        return 'Siege Tower';
    }
  }

  String get assetFolder {
    switch (this) {
      case CraftedTowerType.human:
        return 'human tower';
      case CraftedTowerType.beast:
        return 'beast tower';
      case CraftedTowerType.siege:
        return 'siege tower';
    }
  }

  String get shortDescription {
    switch (this) {
      case CraftedTowerType.human:
        return 'Excels against human raiders and archers.';
      case CraftedTowerType.beast:
        return 'Excels against wolves and beast threats.';
      case CraftedTowerType.siege:
        return 'Excels against battering and siege pressure.';
    }
  }

  String get shortLabel {
    switch (this) {
      case CraftedTowerType.human:
        return 'H';
      case CraftedTowerType.beast:
        return 'B';
      case CraftedTowerType.siege:
        return 'S';
    }
  }

  ResourceType get accentResource {
    switch (this) {
      case CraftedTowerType.human:
        return ResourceType.iron;
      case CraftedTowerType.beast:
        return ResourceType.hide;
      case CraftedTowerType.siege:
        return ResourceType.steel;
    }
  }
}

extension BuildTypeExt on BuildType {
  String get displayName {
    switch (this) {
      case BuildType.woodenWall:
        return 'Wooden Wall';
      case BuildType.cobbleWall:
        return 'Cobble Wall';
      case BuildType.ironWall:
        return 'Iron Wall';
      case BuildType.steelWall:
        return 'Steel Wall';
      case BuildType.sacredWall:
        return 'Sacred Wall';
      case BuildType.woodenGate:
        return 'Wooden Gate';
      case BuildType.cobbleGate:
        return 'Cobble Gate';
      case BuildType.ironGate:
        return 'Iron Gate';
      case BuildType.steelGate:
        return 'Steel Gate';
      case BuildType.sacredGate:
        return 'Sacred Gate';
      case BuildType.woodenTower:
        return 'Wooden Tower';
      case BuildType.cobbleTower:
        return 'Cobble Tower';
      case BuildType.ironTower:
        return 'Iron Tower';
      case BuildType.steelTower:
        return 'Steel Tower';
      case BuildType.sacredTower:
        return 'Sacred Tower';
    }
  }

  String get categoryLabel {
    if (isWall) return 'Walls';
    if (isGate) return 'Gates';
    return 'Towers';
  }

  String get shortDescription {
    switch (this) {
      case BuildType.woodenWall:
        return 'Cheap frontline cover.';
      case BuildType.cobbleWall:
        return 'Tougher stone barricade.';
      case BuildType.ironWall:
        return 'Heavy wall for sustained pressure.';
      case BuildType.steelWall:
        return 'Late-game fortified bulwark.';
      case BuildType.sacredWall:
        return 'Blessed wall for the inner ring.';
      case BuildType.woodenGate:
        return 'Light gate for early movement lanes.';
      case BuildType.cobbleGate:
        return 'Sturdier entry with stone bracing.';
      case BuildType.ironGate:
        return 'Defensive gate against raiders.';
      case BuildType.steelGate:
        return 'Strong gate for layered choke points.';
      case BuildType.sacredGate:
        return 'Blessed gate for the core defense.';
      case BuildType.woodenTower:
        return 'Starter tower for basic coverage.';
      case BuildType.cobbleTower:
        return 'Reliable tower with better durability.';
      case BuildType.ironTower:
        return 'Sharper damage against heavier waves.';
      case BuildType.steelTower:
        return 'High-tier tower for fortress lines.';
      case BuildType.sacredTower:
        return 'Elite tower worthy of Har Suld.';
    }
  }

  String previewAssetPath(
      {CraftedTowerType towerType = CraftedTowerType.human}) {
    switch (this) {
      case BuildType.woodenWall:
        return 'HarSuld_designs/walls/wooden wall/front-removebg-preview.png';
      case BuildType.cobbleWall:
        return 'HarSuld_designs/walls/stone wall/front-removebg-preview.png';
      case BuildType.ironWall:
        return 'HarSuld_designs/walls/iron wall/front-removebg-preview.png';
      case BuildType.steelWall:
        return 'HarSuld_designs/walls/steel wall/front-removebg-preview.png';
      case BuildType.sacredWall:
        return 'HarSuld_designs/walls/sacred wall/front-removebg-preview.png';
      case BuildType.woodenGate:
        return 'HarSuld_designs/gate/wooden-removebg-preview.png';
      case BuildType.cobbleGate:
        return 'HarSuld_designs/gate/stone-removebg-preview.png';
      case BuildType.ironGate:
        return 'HarSuld_designs/gate/iron-removebg-preview.png';
      case BuildType.steelGate:
        return 'HarSuld_designs/gate/steel-removebg-preview.png';
      case BuildType.sacredGate:
        return 'HarSuld_designs/gate/sacred-removebg-preview.png';
      case BuildType.woodenTower:
        return 'HarSuld_designs/towers/${towerType.assetFolder}/wooden-removebg-preview.png';
      case BuildType.cobbleTower:
        return 'HarSuld_designs/towers/${towerType.assetFolder}/stone-removebg-preview.png';
      case BuildType.ironTower:
        return 'HarSuld_designs/towers/${towerType.assetFolder}/iron-removebg-preview.png';
      case BuildType.steelTower:
        return towerType == CraftedTowerType.beast
            ? 'HarSuld_designs/towers/${towerType.assetFolder}/steel-removebg-preview.png'
            : 'HarSuld_designs/towers/${towerType.assetFolder}/steel.png';
      case BuildType.sacredTower:
        return towerType == CraftedTowerType.human
            ? 'HarSuld_designs/towers/${towerType.assetFolder}/sacred.png'
            : 'HarSuld_designs/towers/${towerType.assetFolder}/sacred-removebg-preview.png';
    }
  }

  String displayNameWithTowerType({
    CraftedTowerType towerType = CraftedTowerType.human,
  }) {
    if (!isTower) return displayName;
    return '${towerType.label} ${displayName.replaceAll(' Tower', '')}';
  }

  Map<ResourceType, int> get cost {
    switch (this) {
      case BuildType.woodenWall:
        return {ResourceType.wood: 20};
      case BuildType.cobbleWall:
        return {ResourceType.stone: 25, ResourceType.wood: 10};
      case BuildType.ironWall:
        return {ResourceType.iron: 30, ResourceType.stone: 20};
      case BuildType.steelWall:
        return {ResourceType.steel: 35, ResourceType.iron: 20};
      case BuildType.sacredWall:
        return {
          ResourceType.gold: 15,
          ResourceType.diamond: 8,
          ResourceType.steel: 20
        };
      case BuildType.woodenGate:
        return {ResourceType.wood: 25};
      case BuildType.cobbleGate:
        return {ResourceType.stone: 20, ResourceType.wood: 10};
      case BuildType.ironGate:
        return {ResourceType.iron: 25, ResourceType.stone: 15};
      case BuildType.steelGate:
        return {ResourceType.steel: 30, ResourceType.iron: 20};
      case BuildType.sacredGate:
        return {
          ResourceType.gold: 12,
          ResourceType.diamond: 6,
          ResourceType.steel: 17
        };
      case BuildType.woodenTower:
        return {ResourceType.wood: 35, ResourceType.stone: 15};
      case BuildType.cobbleTower:
        return {ResourceType.stone: 20, ResourceType.wood: 15};
      case BuildType.ironTower:
        return {ResourceType.iron: 25, ResourceType.stone: 15};
      case BuildType.steelTower:
        return {ResourceType.steel: 30, ResourceType.iron: 15};
      case BuildType.sacredTower:
        return {
          ResourceType.gold: 15,
          ResourceType.steel: 20,
          ResourceType.diamond: 5
        };
    }
  }

  bool get isWall => index <= BuildType.sacredWall.index;
  bool get isGate =>
      index >= BuildType.woodenGate.index &&
      index <= BuildType.sacredGate.index;
  bool get isTower => index >= BuildType.woodenTower.index;
}

const List<Map<ResourceType, int>> kBowUpgradeCosts = [
  {
    ResourceType.wood: 30,
    ResourceType.stone: 10,
  },
  {
    ResourceType.stone: 24,
    ResourceType.iron: 12,
  },
  {
    ResourceType.iron: 26,
    ResourceType.steel: 12,
  },
  {
    ResourceType.steel: 22,
    ResourceType.gold: 8,
    ResourceType.diamond: 3,
  },
];

class InventorySystem extends ChangeNotifier {
  final Map<ResourceType, int> resources = {
    for (final r in ResourceType.values) r: 0,
  };
  final Map<ConsumableType, int> consumables = {
    for (final c in ConsumableType.values) c: 0,
  };

  int bowTier = 0;
  int armorTier = 0;

  void add(ResourceType type, int amount) {
    resources[type] = (resources[type] ?? 0) + amount;
    notifyListeners();
  }

  bool canAfford(Map<ResourceType, int> cost) {
    for (final entry in cost.entries) {
      if ((resources[entry.key] ?? 0) < entry.value) return false;
    }
    return true;
  }

  bool spend(Map<ResourceType, int> cost) {
    if (!canAfford(cost)) return false;
    for (final entry in cost.entries) {
      resources[entry.key] = resources[entry.key]! - entry.value;
    }
    notifyListeners();
    return true;
  }

  int get(ResourceType type) => resources[type] ?? 0;

  bool canBuild(BuildType type) => canAfford(type.cost);

  bool tryBuild(BuildType type) => spend(type.cost);

  bool craftConsumable(ConsumableType type) {
    final cost = consumableCost(type);
    if (!spend(cost)) return false;
    consumables[type] = (consumables[type] ?? 0) + 1;
    notifyListeners();
    return true;
  }

  bool consumeConsumable(ConsumableType type, {int amount = 1}) {
    final current = consumables[type] ?? 0;
    if (current < amount) return false;
    consumables[type] = current - amount;
    notifyListeners();
    return true;
  }

  int getConsumable(ConsumableType type) => consumables[type] ?? 0;

  Map<ResourceType, int> consumableCost(ConsumableType type) {
    switch (type) {
      case ConsumableType.harSuldRepairKit:
        return {
          ResourceType.hide: 2,
          ResourceType.sinew: 1,
          ResourceType.blackWolfFang: 1,
        };
      case ConsumableType.playerHealthKit:
        return {
          ResourceType.hide: 1,
          ResourceType.sinew: 2,
        };
    }
  }

  bool canCraftConsumable(ConsumableType type) {
    return canAfford(consumableCost(type));
  }

  Map<ResourceType, int>? nextBowUpgradeCost(int currentTier) {
    if (currentTier >= kBowTiers.length - 1) return null;
    return kBowUpgradeCosts[currentTier];
  }

  bool canUpgradeBow(int currentTier) {
    final cost = nextBowUpgradeCost(currentTier);
    return cost != null && canAfford(cost);
  }

  bool tryUpgradeBow(int currentTier) {
    final cost = nextBowUpgradeCost(currentTier);
    if (cost == null) return false;
    return spend(cost);
  }
}
