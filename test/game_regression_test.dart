import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bloom_and_deliver/providers/game_provider.dart';
import 'package:bloom_and_deliver/providers/saved_state_provider.dart';
import 'package:bloom_and_deliver/data/flower_data.dart';
import 'package:bloom_and_deliver/data/wholesale_data.dart';
import 'package:bloom_and_deliver/data/delivery_data.dart';
import 'package:bloom_and_deliver/models/game_state.dart';
import 'package:bloom_and_deliver/models/shop_upgrades.dart';
import 'package:bloom_and_deliver/services/persistence_service.dart';
import 'sim_test.dart' show planBouquet;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  late ProviderContainer container;
  late GameNotifier game;
  GameState getState() => container.read(gameProvider);
  setUp(() async {
    await PersistenceService.clearSave();
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
    game = container.read(gameProvider.notifier);
  });
  tearDown(() async {
    await PersistenceService.saveState(getState());
    container.dispose();
  });

  void seed(GameState state) {
    container.dispose();
    container = ProviderContainer(
      overrides: [savedGameStateProvider.overrideWithValue(state)],
    );
    game = container.read(gameProvider.notifier);
  }

  void finishDay() {
    while (getState().currentOrder != null) {
      final order = getState().currentOrder!;
      for (final f in unlockedFlowers(getState().day)) {
        game.restockFlower(f.id, 5);
      }
      for (final id in planBouquet(order, getState().inventory)) {
        game.addFlowerToWorkspace(id);
      }
      expect(game.canSubmit, isTrue);
      game.submitBouquet();
    }
  }

  test('invalid purchases and indices cannot corrupt the wallet', () {
    final before = getState();
    expect(game.restockFlower('rose', -5), isFalse);
    expect(game.restockFlower('rose', 1, costPerUnit: -5), isFalse);
    expect(game.placeWholesaleOrder('rose', 5, -10), isFalse);
    expect(game.placeWholesaleOrder('missing', 5, 10), isFalse);
    expect(game.plantSeed('rose', -1), isFalse);
    game.removeFlowerFromWorkspace(-1);
    game.addFlowerToWorkspace('missing');
    expect(getState(), same(before));
  });

  test('wholesale bundles pay atomically and arrive fresh once', () async {
    expect(game.placeWholesaleCart({'daisy': wholesalePackSize}), isFalse);
    seed(
      getState().copyWith(
        day: 3,
        dayEnded: true,
        money: 200,
        inventory: const {},
        inventoryDayAdded: const {},
        levelStars: const {1: 1, 2: 1, 3: 1},
      ),
    );
    final before = getState();
    final locked = allFlowers.firstWhere(
      (flower) => flower.unlockDay > 3 && !flower.isEventExclusive,
    );
    expect(game.placeWholesaleCart({'daisy': 5, locked.id: 5}), isFalse);
    expect(game.placeWholesaleCart({'daisy': 6}), isFalse);
    expect(getState(), same(before));

    expect(game.placeWholesaleCart({'daisy': 5, 'rose': 5}), isTrue);
    final firstCost =
        wholesalePackPrice(flowerById['daisy']!) +
        wholesalePackPrice(flowerById['rose']!);
    expect(getState().money, 200 - firstCost);
    expect(getState().wholesalePending, {'daisy': 5, 'rose': 5});
    expect(game.placeWholesaleCart({'daisy': 15}), isFalse);
    expect(game.placeWholesaleCart({'daisy': 10}), isTrue);
    expect(game.placeWholesaleCart({'rose': 5}), isFalse);
    expect(wholesalePendingStems(getState().wholesalePending), 20);

    await PersistenceService.saveState(getState());
    seed((await PersistenceService.loadState())!);
    expect(getState().wholesalePending, {'daisy': 15, 'rose': 5});
    // Simulate finishing the current level after restoring its pending order.
    seed(getState().copyWith(dayEnded: true));
    game.startNextDay();
    expect(getState().day, 4);
    expect(getState().inventory['daisy'], 15);
    expect(getState().inventory['rose'], 5);
    expect(getState().inventoryDayAdded['daisy'], 4);
    expect(getState().wholesalePending, isEmpty);
    final arrived = getState();
    game.startNextDay();
    expect(getState(), same(arrived));
  });

  test('missing the first star cannot skip to a locked level', () {
    seed(getState().copyWith(dayEnded: true));
    game.startNextDay();
    expect(getState().day, 1);
    expect(getState().isLevelUnlocked(2), isFalse);
    expect(getState().dayEnded, isFalse);
  });

  test('quick tips have a boundary and cannot pay on an empty resubmit', () {
    final initial = getState();
    int serve(Duration? elapsed) {
      seed(initial);
      for (final id in planBouquet(
        getState().currentOrder!,
        getState().inventory,
      )) {
        game.addFlowerToWorkspace(id);
      }
      game.submitBouquet(serviceTime: elapsed);
      return getState().completedToday.single.$2;
    }

    final untimed = serve(null);
    final onTime = serve(Duration(seconds: game.serviceSeconds));
    final late = serve(Duration(seconds: game.serviceSeconds + 1));
    final invalid = serve(const Duration(seconds: -1));
    expect(onTime, greaterThan(untimed));
    expect(late, untimed);
    expect(invalid, untimed);
    final money = getState().money;
    game.submitBouquet(serviceTime: Duration.zero);
    expect(getState().money, money);
  });

  test(
    'new shop equipment persists and purchases cannot charge twice',
    () async {
      seed(getState().copyWith(money: 2000));
      final initialTime = game.serviceSeconds;
      for (final item in [
        UpgradeId.teaCart,
        UpgradeId.ribbonRack,
        UpgradeId.tipJar,
      ]) {
        expect(game.purchaseUpgrade(item), isTrue);
        final money = getState().money;
        expect(game.purchaseUpgrade(item), isFalse);
        expect(getState().money, money);
      }
      expect(game.serviceSeconds, initialTime + 8);
      final decoded = ShopUpgrades.fromJson(getState().upgrades.toJson());
      expect(decoded.has(UpgradeId.teaCart), isTrue);
      expect(decoded.has(UpgradeId.ribbonRack), isTrue);
      expect(decoded.has(UpgradeId.tipJar), isTrue);
    },
  );
  test('empty bouquet cannot skip an order or award XP', () {
    final before = getState();
    game.submitBouquet();
    game.startNextDay();
    expect(getState(), same(before));
  });

  test('bankrupt shop receives only enough stems to keep playing', () {
    seed(getState().copyWith(money: 0, inventory: {}));
    expect(game.needsCommunityFlowers, isTrue);
    expect(game.requestCommunityFlowers(), isTrue);
    expect(getState().inventory['daisy'], getState().currentOrder!.minFlowers);
    expect(game.requestCommunityFlowers(), isFalse);
    expect(getState().money, 0);
  });
  test('tutorial reward can only be claimed once', () {
    game.claimTutorialReward();
    final before = getState();
    game.claimTutorialReward();
    expect(getState(), same(before));
  });
  test(
    'save restores current customer, stock, workspace and spending',
    () async {
      for (final id in planBouquet(
        getState().currentOrder!,
        getState().inventory,
      )) {
        game.addFlowerToWorkspace(id);
      }
      game.submitBouquet();
      game.addFlowerToWorkspace('rose');
      game.restockFlower('daisy', 2);
      final before = getState();
      await PersistenceService.saveState(before);
      final restored = (await PersistenceService.loadState())!;
      expect(restored.money, before.money);
      expect(restored.currentOrderIndex, 1);
      expect(restored.currentOrder!.id, before.currentOrder!.id);
      expect(restored.bouquetWorkspace.map((f) => f.id), ['rose']);
      expect(restored.inventory, before.inventory);
      expect(restored.dayEarnings, before.dayEarnings);
      expect(restored.restockSpentToday, before.restockSpentToday);
    },
  );
  test('new journey stars pay once, including across saved replays', () async {
    seed(getState().copyWith(money: 10000));
    finishDay();
    final first = getState();
    expect(first.gems, first.totalStars * 5);
    await PersistenceService.saveState(first);
    final restored = (await PersistenceService.loadState())!;
    expect(restored.dayEnded, isTrue);
    seed(restored);
    expect(game.startLevel(1), isTrue);
    finishDay();
    expect(getState().gems, first.gems);
  });
  test('changing levels returns reserved flowers and preserves their age', () {
    seed(getState().copyWith(day: 2, levelStars: {1: 2}));
    final count = getState().inventory['rose'];
    game.addFlowerToWorkspace('rose');
    expect(game.startLevel(1), isTrue);
    expect(getState().inventory['rose'], count);
    expect(getState().bouquetWorkspace, isEmpty);
    expect(getState().day - getState().inventoryDayAdded['rose']!, 1);
  });
  test(
    'deliveries consume inventory and cannot pay twice after a save',
    () async {
      final mission = generateDeliveries(4).first;
      final flower = flowerById['rose']!;
      seed(
        getState().copyWith(
          pendingDeliveries: [mission],
          inventory: {'rose': 20},
        ),
      );
      final bouquet = List.filled(mission.minFlowers, flower);
      expect(game.submitDelivery(mission.id, bouquet), isNotNull);
      expect(getState().inventory['rose'], 20 - mission.minFlowers);
      await PersistenceService.saveState(getState());
      seed((await PersistenceService.loadState())!);
      final after = getState();
      expect(game.submitDelivery(mission.id, bouquet), isNull);
      expect(getState(), same(after));
    },
  );
  test('delivery cannot spend missing stock', () {
    final mission = generateDeliveries(4).first;
    seed(getState().copyWith(pendingDeliveries: [mission], inventory: {}));
    final before = getState();
    expect(
      game.submitDelivery(
        mission.id,
        List.filled(mission.minFlowers, flowerById['rose']!),
      ),
      isNull,
    );
    expect(getState(), same(before));
  });
  test('useless gem shortcuts do not charge', () {
    seed(
      getState().copyWith(
        gems: 100,
        inventory: {for (final f in unlockedFlowers(1)) f.id: 5},
      ),
    );
    expect(game.gemInstantRestock(), isFalse);
    expect(game.gemFreshWater(), isFalse);
    expect(getState().gems, 100);
  });
  test(
    'display upgrade does not change saved current-day order count',
    () async {
      final count = getState().dayOrders.length;
      game.purchaseUpgrade(UpgradeId.displayWindow);
      await PersistenceService.saveState(getState());
      expect((await PersistenceService.loadState())!.dayOrders.length, count);
    },
  );
  test('clear save clears gems and snapshot too', () async {
    game.grantGems(100);
    await PersistenceService.clearSave();
    expect(await PersistenceService.loadState(), isNull);
  });
}
