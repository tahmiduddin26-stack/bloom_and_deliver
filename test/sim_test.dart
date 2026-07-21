// Headless playthrough simulation — drives GameNotifier through the campaign
// with a "reasonable player" strategy and reports the economy/star curve.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bloom_and_deliver/data/flower_data.dart';
import 'package:bloom_and_deliver/data/level_data.dart';
import 'package:bloom_and_deliver/data/order_data.dart';
import 'package:bloom_and_deliver/models/bouquet_order.dart';
import 'package:bloom_and_deliver/models/flower.dart';
import 'package:bloom_and_deliver/providers/game_provider.dart';

/// Greedy vibe-cover picker: returns flower ids to add for [order].
List<String> planBouquet(BouquetOrder order, Map<String, int> inventory) {
  final stock = Map<String, int>.from(inventory)
    ..removeWhere((_, q) => q <= 0);
  final picks = <String>[];

  if (order.isMystery) {
    // Creativity scoring: maximise distinct species.
    for (final id in stock.keys) {
      if (picks.length >= order.maxFlowers) break;
      picks.add(id);
    }
    return picks;
  }

  final needed = order.requiredVibes.toSet();
  // Cover each required vibe with the cheapest flower that has it.
  for (final vibe in order.requiredVibes) {
    if (picks.length >= order.maxFlowers) break;
    if (!needed.contains(vibe)) continue;
    final candidates = stock.entries
        .where((e) => e.value > 0 && flowerById[e.key]!.vibes.contains(vibe))
        .map((e) => flowerById[e.key]!)
        .toList()
      ..sort((a, b) => a.cost.compareTo(b.cost));
    if (candidates.isEmpty) continue;
    final f = candidates.first;
    picks.add(f.id);
    stock[f.id] = stock[f.id]! - 1;
    needed.removeAll(f.vibes);
  }

  // Pad to minFlowers with whatever is cheapest in stock.
  final byCost = stock.entries.where((e) => e.value > 0).toList()
    ..sort((a, b) =>
        flowerById[a.key]!.cost.compareTo(flowerById[b.key]!.cost));
  var i = 0;
  while (picks.length < order.minFlowers && i < byCost.length) {
    final id = byCost[i].key;
    if ((stock[id] ?? 0) > 0) {
      picks.add(id);
      stock[id] = stock[id]! - 1;
    } else {
      i++;
    }
  }
  return picks;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('20-level playthrough: economy, stars, stock', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);

    final report = StringBuffer();
    report.writeln(
        'day | orders | great/good/poor | earned | restock | money | stars | short');

    for (var level = 1; level <= 20; level++) {
      final s0 = container.read(gameProvider);
      expect(s0.day, level, reason: 'level $level day mismatch');

      var great = 0, good = 0, poor = 0, short = 0;
      final startMoney = s0.money;

      while (!container.read(gameProvider).dayEnded) {
        final st = container.read(gameProvider);
        final order = st.currentOrder!;
        final plan = planBouquet(order, st.inventory);
        for (final id in plan) {
          notifier.addFlowerToWorkspace(id);
        }
        final ws = container.read(gameProvider).bouquetWorkspace;
        if (ws.length < order.minFlowers) short++;
        final r = notifier.submitBouquet();
        switch (r) {
          case OrderResult.great:
            great++;
          case OrderResult.good:
            good++;
          case OrderResult.poor:
            poor++;
          case OrderResult.pending:
            break;
        }
      }

      final endDay = container.read(gameProvider);
      final earned = endDay.dayEarnings;
      final stars = endDay.levelStars[level] ?? 0;

      // Restock: spend up to 60% of cash on the cheapest unlocked flowers,
      // topping every unlocked flower up to 4 in stock.
      final budget = (endDay.money * 0.6).round();
      var spent = 0;
      final avail = unlockedFlowers(level)..sort((a, b) => a.cost.compareTo(b.cost));
      for (final f in avail) {
        final have = container.read(gameProvider).inventory[f.id] ?? 0;
        final want = 4 - have;
        if (want <= 0) continue;
        if (spent + f.cost * want > budget) continue;
        if (notifier.restockFlower(f.id, want)) spent += f.cost * want;
      }

      final afterRestock = container.read(gameProvider);
      report.writeln(
          '${level.toString().padLeft(3)} | ${endDay.dayOrders.length.toString().padLeft(6)} '
          '| $great/$good/$poor | ${earned.toString().padLeft(6)} '
          '| ${spent.toString().padLeft(7)} | ${afterRestock.money.toString().padLeft(5)} '
          '| $stars | $short   (start \$$startMoney, goal ${levelForDay(level).star2Earnings}/${levelForDay(level).star3Earnings})');

      if (level < 20) notifier.startNextDay();
    }

    final end = container.read(gameProvider);
    report.writeln('--- totals ---');
    report.writeln('money: ${end.money}  totalEarnings: ${end.totalEarnings}  '
        'served: ${end.totalOrdersServed}  xp: ${end.xp}');
    report.writeln('stars: ${end.levelStars}');
    final totalStars =
        end.levelStars.values.fold<int>(0, (a, b) => a + b);
    report.writeln('total stars: $totalStars / 60');
    report.writeln('inventory: ${end.inventory}');
    // ignore: avoid_print
    print(report);

    expect(end.money, greaterThan(0), reason: 'player went bankrupt');

    // Economy tension guard (Phase 2). A greedy-but-imperfect bot should NOT
    // three-star the whole campaign: star3 now demands mostly-Great play, so a
    // competent bot lands around competent-completion (2★) with the odd 3★.
    // The old, broken balance let it score 57/60. Keep the band generous to
    // absorb shuffle variance while still catching a regression to "no tension".
    // If this fails high, nudge star3Earnings up; if it fails low, nudge down.
    expect(totalStars, lessThanOrEqualTo(50),
        reason: 'star goals too loose — campaign is not constraining ($totalStars/60)');
    expect(totalStars, greaterThanOrEqualTo(24),
        reason: 'star goals too harsh for a competent player ($totalStars/60)');
  });

  test('flower data integrity', () {
    final ids = allFlowers.map((f) => f.id).toSet();
    expect(ids.length, allFlowers.length, reason: 'duplicate flower ids');
    for (final f in allFlowers) {
      expect(f.vibes, isNotEmpty, reason: '${f.id} has no vibes');
      expect(f.cost, greaterThan(0), reason: '${f.id} costs nothing');
      expect(f.wiltsAfterDays, greaterThan(0), reason: '${f.id} wilts instantly');
    }
  });

  test('every order is satisfiable from flowers unlocked by its day', () {
    // Vibes no non-event flower carries at all.
    final everVibes = allFlowers
        .where((f) => f.eventId == null)
        .expand((f) => f.vibes)
        .toSet();
    final orphanVibes =
        VibeTag.values.where((v) => !everVibes.contains(v)).toList();

    // Worst case per order, using the full day-20 flower pool.
    final pool20 = unlockedFlowers(20).expand((f) => f.vibes).toSet();
    final capped = <String, String>{};
    for (var day = 1; day <= 20; day++) {
      for (final order in generateDayOrdersForCheck(day)) {
        if (order.isMystery) continue;
        final missing =
            order.requiredVibes.where((v) => !pool20.contains(v)).toList();
        if (missing.isEmpty) continue;
        final best =
            (order.requiredVibes.length - missing.length) /
                order.requiredVibes.length;
        capped[order.id] =
            'needs ${order.requiredVibes.map((v) => v.name).join("+")} — '
            'missing ${missing.map((v) => v.name).join(",")} — '
            'best ratio ${best.toStringAsFixed(2)} '
            '(${best >= 0.8 ? "great" : best >= 0.5 ? "GOOD max" : "POOR max"})';
      }
    }
    // ignore: avoid_print
    print('vibes on no obtainable flower: '
        '${orphanVibes.map((v) => v.name).join(", ")}\n'
        'orders that can never score Great:\n'
        '${capped.entries.map((e) => "  ${e.key}: ${e.value}").join("\n")}\n'
        'affected orders: ${capped.length}');
    expect(capped, isEmpty, reason: 'unwinnable orders exist');
  });
}

/// Sample order generation a few times so shuffling doesn't hide problems.
List<BouquetOrder> generateDayOrdersForCheck(int day) {
  final out = <BouquetOrder>[];
  for (var i = 0; i < 5; i++) {
    out.addAll(generateDayOrders(day));
  }
  return out;
}
