enum UpgradeId {
  workspaceXL,
  extraShelf,
  flowerCooler,
  wrappingStation,
  displayWindow,
}

extension UpgradeInfo on UpgradeId {
  String get title => switch (this) {
        UpgradeId.workspaceXL => 'Workspace XL',
        UpgradeId.extraShelf => 'Extra Shelf',
        UpgradeId.flowerCooler => 'Flower Cooler',
        UpgradeId.wrappingStation => 'Wrapping Station',
        UpgradeId.displayWindow => 'Display Window',
      };

  String get description => switch (this) {
        UpgradeId.workspaceXL =>
          'Craft bouquets with up to 10 flowers instead of 8',
        UpgradeId.extraShelf => 'Market restocks cost 10% less',
        UpgradeId.flowerCooler => 'Flowers stay fresh 1 extra day',
        UpgradeId.wrappingStation => 'Earn +15% coins on every Great order',
        UpgradeId.displayWindow => 'Attract 1 extra customer each day',
      };

  String get emoji => switch (this) {
        UpgradeId.workspaceXL => '✂️',
        UpgradeId.extraShelf => '🪴',
        UpgradeId.flowerCooler => '❄️',
        UpgradeId.wrappingStation => '🎀',
        UpgradeId.displayWindow => '🪟',
      };

  int get cost => switch (this) {
        UpgradeId.workspaceXL => 80,
        UpgradeId.extraShelf => 60,
        UpgradeId.flowerCooler => 100,
        UpgradeId.wrappingStation => 90,
        UpgradeId.displayWindow => 50,
      };
}

class ShopUpgrades {
  final Set<UpgradeId> purchased;

  const ShopUpgrades({this.purchased = const {}});

  bool has(UpgradeId id) => purchased.contains(id);

  bool get hasWorkspaceXL => has(UpgradeId.workspaceXL);
  bool get hasExtraShelf => has(UpgradeId.extraShelf);
  bool get hasFlowerCooler => has(UpgradeId.flowerCooler);
  bool get hasWrappingStation => has(UpgradeId.wrappingStation);
  bool get hasDisplayWindow => has(UpgradeId.displayWindow);

  /// Extra bouquet slots added to every order's maxFlowers.
  int get workspaceBonusSlots => hasWorkspaceXL ? 2 : 0;

  /// Extra freshness days for all flowers.
  int get freshnessBonusDays => hasFlowerCooler ? 1 : 0;

  /// Multiplier applied to earned coins on a Great order.
  double get greatOrderBonus => hasWrappingStation ? 1.15 : 1.0;

  /// Extra customers generated per day.
  int get extraCustomersPerDay => hasDisplayWindow ? 1 : 0;

  ShopUpgrades withUpgrade(UpgradeId id) =>
      ShopUpgrades(purchased: {...purchased, id});

  List<String> toJson() => purchased.map((e) => e.name).toList();

  static ShopUpgrades fromJson(List<dynamic> list) => ShopUpgrades(
        purchased: list
            .map((e) {
              try {
                return UpgradeId.values.firstWhere((id) => id.name == e);
              } catch (_) {
                return null;
              }
            })
            .whereType<UpgradeId>()
            .toSet(),
      );
}
