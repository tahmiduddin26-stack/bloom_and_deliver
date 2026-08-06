import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/big_orders_data.dart';
import '../data/daily_challenges_data.dart';
import '../data/delivery_data.dart';
import '../data/flower_data.dart';
import '../data/gem_data.dart';
import '../data/level_data.dart';
import '../data/order_data.dart';
import '../data/seasonal_events_data.dart';
import '../data/shop_decor_data.dart';
import '../data/story_arc_data.dart';
import '../models/achievement.dart';
import '../models/big_order.dart';
import '../models/bouquet_order.dart';
import '../models/bouquet_preset.dart';
import '../models/daily_challenge.dart';
import '../models/delivery_mission.dart';
import '../models/florist_rank.dart';
import '../models/flower.dart';
import '../models/game_state.dart';
import '../models/growing_plant.dart';
import '../models/shop_decoration.dart';
import '../models/shop_upgrades.dart';
import '../services/analytics_service.dart';
import '../services/persistence_service.dart';
import 'saved_state_provider.dart';

/// A descriptive split of one order's payout, so the result card can show *why*
/// a bouquet paid what it did.
///
/// Every field is derived from values the payout already produced — the parts
/// sum to [total] exactly. It is a read-out, never an input to the economy.
class EarningsBreakdown {
  /// The order's advertised base payment.
  final int base;

  /// Adjustment for how well the bouquet matched (Great/Good/Poor), or the
  /// creativity bonus on a mystery order. Negative on a Poor result.
  final int resultBonus;

  /// Extra from a regular customer's loyalty multiplier.
  final int loyaltyBonus;

  /// Extra from shop upgrades.
  final int upgradeBonus;

  /// Extra for having completed a vibe-notebook chapter.
  final int vibeBonus;

  /// Extra for including filler greens.
  final int greensBonus;

  final int total;
  final bool isMystery;

  const EarningsBreakdown({
    required this.base,
    required this.resultBonus,
    required this.loyaltyBonus,
    required this.upgradeBonus,
    required this.vibeBonus,
    required this.greensBonus,
    required this.total,
    required this.isMystery,
  });

  /// The non-base parts worth naming, largest first, as (label, amount).
  List<(String, int)> get namedParts => [
        if (resultBonus != 0) (isMystery ? 'creativity' : 'match', resultBonus),
        if (loyaltyBonus != 0) ('loyalty', loyaltyBonus),
        if (upgradeBonus != 0) ('upgrades', upgradeBonus),
        if (vibeBonus != 0) ('notebook', vibeBonus),
        if (greensBonus != 0) ('greens', greensBonus),
      ]..sort((a, b) => b.$2.compareTo(a.$2));
}

class GameNotifier extends Notifier<GameState> {
  /// Breakdown of the most recent [submitBouquet] payout. Display only.
  EarningsBreakdown? lastEarnings;

  @override
  GameState build() {
    final saved = ref.read(savedGameStateProvider);
    return saved ?? _freshState(day: 1, money: 120);
  }

  static GameState _freshState({required int day, required int money}) {
    final challenges = generateDailyChallenges(day);
    return GameState(
      day: day,
      money: money,
      inventory: defaultInventory,
      inventoryDayAdded: defaultInventoryDayAdded,
      restockSpentToday: 0,
      dayOrders: generateDayOrders(day),
      currentOrderIndex: 0,
      bouquetWorkspace: [],
      completedToday: [],
      dailyChallenges: challenges,
      challengeGameDay: day,
    );
  }

  // ── Workspace ─────────────────────────────────────────────────────────────────

  void addFlowerToWorkspace(String flowerId) {
    final order = state.currentOrder;
    final effectiveMax =
        (order?.maxFlowers ?? 8) + state.upgrades.workspaceBonusSlots;
    if (order != null && state.bouquetWorkspace.length >= effectiveMax) return;

    final inventory = Map<String, int>.from(state.inventory);
    if ((inventory[flowerId] ?? 0) <= 0) return;
    inventory[flowerId] = inventory[flowerId]! - 1;

    final flower = flowerById[flowerId]!;
    state = state.copyWith(
      inventory: inventory,
      bouquetWorkspace: [...state.bouquetWorkspace, flower],
    );
  }

  void removeFlowerFromWorkspace(int index) {
    final workspace = List<Flower>.from(state.bouquetWorkspace);
    if (index >= workspace.length) return;
    final flower = workspace.removeAt(index);

    final inventory = Map<String, int>.from(state.inventory);
    inventory[flower.id] = (inventory[flower.id] ?? 0) + 1;

    state = state.copyWith(
      bouquetWorkspace: workspace,
      inventory: inventory,
    );
  }

  /// Undo the last flower added to the workspace (returns it to inventory).
  void undoLastFlower() {
    if (state.bouquetWorkspace.isEmpty) return;
    final workspace = List<Flower>.from(state.bouquetWorkspace);
    final flower = workspace.removeLast();

    final inventory = Map<String, int>.from(state.inventory);
    inventory[flower.id] = (inventory[flower.id] ?? 0) + 1;

    state = state.copyWith(
      bouquetWorkspace: workspace,
      inventory: inventory,
    );
  }

  void clearWorkspace() {
    final inventory = Map<String, int>.from(state.inventory);
    for (final flower in state.bouquetWorkspace) {
      inventory[flower.id] = (inventory[flower.id] ?? 0) + 1;
    }
    state = state.copyWith(bouquetWorkspace: [], inventory: inventory);
  }

  // ── Scoring ───────────────────────────────────────────────────────────────────

  OrderResult submitBouquet() {
    final order = state.currentOrder;
    if (order == null) return OrderResult.poor;

    final (result, baseEarned) = order.score(state.bouquetWorkspace);

    // Apply wrapping station bonus on great orders
    final upgradedEarned = result == OrderResult.great
        ? (baseEarned * state.upgrades.greatOrderBonus).round()
        : baseEarned;

    // ── Vibe notebook category bonus ─────────────────────────────────────────────
    // If the player has discovered ALL 6 vibes in a chapter AND this order's
    // required vibes overlap that chapter, apply a flat 10% bonus.
    const chapterVibes = [
      ['romantic', 'soft', 'delicate', 'sympathy', 'cozy', 'elegant'],
      ['cheerful', 'vibrant', 'bold', 'wild', 'fresh', 'natural'],
      ['mystical', 'luxurious', 'exotic', 'festive', 'rustic', 'traditional'],
    ];
    final requiredVibeNames =
        order.requiredVibes.map((v) => v.name).toSet();
    final discoveredChapterBonus = !order.isMystery && requiredVibeNames.isNotEmpty
        ? chapterVibes.any((chapter) =>
            state.vibeDiscoveries.containsAll(chapter) &&
            requiredVibeNames.any((v) => chapter.contains(v)))
        : false;
    final vibeBonus = discoveredChapterBonus ? (upgradedEarned * 0.10).round() : 0;

    // ── Greens / filler bonus ─────────────────────────────────────────────────────
    // Including at least one filler (eucalyptus, fern, baby's breath, statice)
    // alongside at least 3 non-filler flowers earns a 5% bonus.
    // Orders that explicitly prefersGreens get a 10% bonus instead.
    final hasGreens = state.bouquetWorkspace.any((f) => f.isFiller);
    final nonFillerCount = state.bouquetWorkspace.where((f) => !f.isFiller).length;
    final greensBonus = (hasGreens && nonFillerCount >= 3 && result != OrderResult.poor)
        ? (upgradedEarned * (order.prefersGreens ? 0.10 : 0.05)).round()
        : 0;

    // Total earned for this order — bonuses included so day earnings,
    // stats, and the money balance all agree.
    final earned = upgradedEarned + vibeBonus + greensBonus;

    // ── Explain the payout ───────────────────────────────────────────────────────
    // Purely descriptive: split `earned` into the parts that produced it so the
    // result card can teach what pays more. Every term is a delta between values
    // already computed above, so the parts always sum back to `earned` exactly —
    // this changes no payment.
    final basePay = order.basePayment;
    final int resultBonus;
    final int loyaltyBonus;
    if (order.isMystery) {
      // Mystery orders score on variety and ignore loyalty entirely.
      resultBonus = baseEarned - basePay;
      loyaltyBonus = 0;
    } else {
      final beforeLoyalty = switch (result) {
        OrderResult.great => (basePay * 1.3).round(),
        OrderResult.good => basePay,
        _ => (basePay * 0.4).round(),
      };
      resultBonus = beforeLoyalty - basePay;
      loyaltyBonus = baseEarned - beforeLoyalty;
    }
    lastEarnings = EarningsBreakdown(
      base: basePay,
      resultBonus: resultBonus,
      loyaltyBonus: loyaltyBonus,
      upgradeBonus: upgradedEarned - baseEarned,
      vibeBonus: vibeBonus,
      greensBonus: greensBonus,
      total: earned,
      isMystery: order.isMystery,
    );

    final updatedOrder = order.copyWith(result: result);
    final updatedOrders = List<BouquetOrder>.from(state.dayOrders);
    updatedOrders[state.currentOrderIndex] = updatedOrder;

    final completed = [...state.completedToday, (updatedOrder, earned)];

    final newMoney = state.money + earned;
    final nextIndex = state.currentOrderIndex + 1;
    final dayEnded = nextIndex >= state.dayOrders.length;

    // ── XP ──────────────────────────────────────────────────────────────────────
    final xpGain = switch (result) {
      OrderResult.great => 30,
      OrderResult.good => 15,
      OrderResult.poor => 5,
      _ => 0,
    };
    final oldRank = state.rank;
    final newXp = state.xp + xpGain;
    final newRank = FloristRankInfo.fromXp(newXp);
    final rankedUp = newRank != oldRank;

    // ── Great streak ─────────────────────────────────────────────────────────────
    final newStreak =
        result == OrderResult.great ? state.greatStreak + 1 : 0;

    // ── Stats ────────────────────────────────────────────────────────────────────
    final newTotalServed = state.totalOrdersServed + 1;
    final newTotalEarnings = state.totalEarnings + earned;

    // ── Vibe tracking ────────────────────────────────────────────────────────────
    Set<String> newVibes = Set<String>.from(state.servedVibeIds);
    if (result != OrderResult.poor) {
      for (final vibe in order.requiredVibes) {
        newVibes.add(vibe.name);
      }
    }

    // ── Vibe notebook discovery (Tier 4) ─────────────────────────────────────────
    // Any vibe present in the submitted bouquet flowers gets discovered, regardless
    // of whether the order required it — rewarding experimentation.
    final newVibeDiscoveries = Set<String>.from(state.vibeDiscoveries);
    if (result != OrderResult.poor) {
      for (final flower in state.bouquetWorkspace) {
        for (final vibe in flower.vibes) {
          newVibeDiscoveries.add(vibe.name);
        }
      }
    }

    // ── Tier 5: All-time flower use tracking ─────────────────────────────────────
    final newFlowerUse = Map<String, int>.from(state.allTimeFlowerUse);
    if (result != OrderResult.poor) {
      for (final flower in state.bouquetWorkspace) {
        newFlowerUse[flower.id] = (newFlowerUse[flower.id] ?? 0) + 1;
      }
    }

    // ── Daily challenges ─────────────────────────────────────────────────────────
    final updatedChallenges = _updateChallenges(
      challenges: state.dailyChallenges,
      result: result,
      order: order,
      bouquet: state.bouquetWorkspace,
      dayEarnings: (completed.fold(0, (s, e) => s + e.$2)),
      servedToday: completed.length,
    );

    // Pay out rewards for any challenges newly completed this submit
    final prevCompletedIds =
        state.dailyChallenges.where((c) => c.completed).map((c) => c.id).toSet();
    final nowCompletedIds =
        updatedChallenges.where((c) => c.completed).map((c) => c.id).toSet();
    final newlyCompletedIds = nowCompletedIds.difference(prevCompletedIds);
    final challengeBonus = updatedChallenges
        .where((c) => newlyCompletedIds.contains(c.id))
        .fold(0, (sum, c) => sum + c.reward);

    // ── Achievements ─────────────────────────────────────────────────────────────
    final (newUnlocked, newProgress, newAchievementQueue) = _checkAchievements(
      current: state.unlockedAchievements,
      progress: {}, // passed per-field below
      result: result,
      newTotalServed: newTotalServed,
      newTotalEarnings: newTotalEarnings,
      newGreatStreak: newStreak,
      newVibes: newVibes,
      newRank: newRank,
      challengesCompleted: updatedChallenges.where((c) => c.completed).length,
      prevChallengesCompleted:
          state.dailyChallenges.where((c) => c.completed).length,
    );

    // ── Friendship & memory snippets ─────────────────────────────────────────────
    final customer = order.customer;
    final currentFriendship = state.customerFriendship[customer.id] ?? 0;
    final newFriendship = result == OrderResult.poor
        ? currentFriendship
        : (currentFriendship + 1).clamp(0, customer.maxFriendship);

    final newFriendshipMap = Map<String, int>.from(state.customerFriendship);
    newFriendshipMap[customer.id] = newFriendship;

    if (newFriendship > currentFriendship) {
      AnalyticsService.instance.friendshipLevelUp(customer.id, newFriendship);
    }

    // Check if a new snippet tier was crossed
    final newPendingMemories = List<String>.from(state.pendingMemories);
    for (final level in [1, 3, 5]) {
      if (currentFriendship < level && newFriendship >= level) {
        final snippet = customer.snippetForLevel(level);
        if (snippet != null) {
          final snippetIdx = level == 1 ? 0 : level == 3 ? 1 : 2;
          newPendingMemories.add('${customer.id}:$snippetIdx');
        }
      }
    }

    // ── Reputation ───────────────────────────────────────────────────────────────
    final repGain = switch (result) {
      OrderResult.great => 3,
      OrderResult.good => 2,
      OrderResult.poor => 1,
      _ => 0,
    };
    final newReputation = state.reputationScore + repGain;

    // ── Level stars (awarded when the day's last order is served) ────────────────
    Map<int, int>? newLevelStars;
    if (dayEnded) {
      final dayTotal = completed.fold(0, (s, e) => s + e.$2);
      final stars = levelForDay(state.day).starsFor(dayTotal);
      final best = state.levelStars[state.day] ?? 0;
      if (stars > best) {
        newLevelStars = Map<int, int>.from(state.levelStars);
        newLevelStars[state.day] = stars;
      }
    }

    state = state.copyWith(
      money: newMoney + challengeBonus,
      dayOrders: updatedOrders,
      currentOrderIndex: nextIndex,
      bouquetWorkspace: [],
      completedToday: completed,
      dayEnded: dayEnded,
      xp: newXp,
      greatStreak: newStreak,
      totalOrdersServed: newTotalServed,
      totalEarnings: newTotalEarnings,
      servedVibeIds: newVibes,
      dailyChallenges: updatedChallenges,
      unlockedAchievements: newUnlocked,
      customerFriendship: newFriendshipMap,
      pendingMemories: newPendingMemories,
      reputationScore: newReputation,
      pendingRankUp: rankedUp ? newRank : null,
      pendingAchievements: [
        ...state.pendingAchievements,
        ...newAchievementQueue,
      ],
      vibeDiscoveries: newVibeDiscoveries,
      allTimeFlowerUse: newFlowerUse,
      levelStars: newLevelStars,
    );

    if (dayEnded) PersistenceService.saveState(state);

    return result;
  }

  // ── Challenge update helper ───────────────────────────────────────────────────

  List<DailyChallenge> _updateChallenges({
    required List<DailyChallenge> challenges,
    required OrderResult result,
    required BouquetOrder order,
    required List<Flower> bouquet,
    required int dayEarnings,
    required int servedToday,
  }) {
    return challenges.map((c) {
      if (c.completed) return c;

      int newProgress = c.progress;

      switch (c.type) {
        case ChallengeType.serveCount:
          // "Serve N customers today" — count today's orders, not all-time.
          newProgress = servedToday;
        case ChallengeType.qualityGreat:
          if (result == OrderResult.great) newProgress = c.progress + 1;
        case ChallengeType.earnMoney:
          newProgress = dayEarnings;
        case ChallengeType.vibeCount:
          if (result != OrderResult.poor && c.filter != null) {
            final matches = order.requiredVibes.any((v) => v.name == c.filter);
            if (matches) newProgress = c.progress + 1;
          }
        case ChallengeType.flowerUse:
          if (c.filter != null) {
            final count = bouquet.where((f) => f.id == c.filter).length;
            newProgress = c.progress + count;
          }
      }

      final done = newProgress >= c.target;
      return c.copyWith(progress: newProgress, completed: done);
    }).toList();
  }

  // ── Achievement check helper ──────────────────────────────────────────────────

  (Set<String>, Map<String, int>, List<String>) _checkAchievements({
    required Set<String> current,
    required Map<String, int> progress,
    required OrderResult result,
    required int newTotalServed,
    required int newTotalEarnings,
    required int newGreatStreak,
    required Set<String> newVibes,
    required FloristRank newRank,
    required int challengesCompleted,
    required int prevChallengesCompleted,
  }) {
    final unlocked = Set<String>.from(current);
    final newQueue = <String>[];

    void tryUnlock(AchievementId id) {
      final key = id.name;
      if (!unlocked.contains(key)) {
        unlocked.add(key);
        newQueue.add(key);
      }
    }

    // Binary achievements
    if (newTotalServed == 1) tryUnlock(AchievementId.firstBouquet);
    if (result == OrderResult.great) tryUnlock(AchievementId.firstGreat);
    if (newGreatStreak >= 3) tryUnlock(AchievementId.greatStreak3);
    if (newTotalServed >= 50) tryUnlock(AchievementId.serve50);
    if (newTotalServed >= 100) tryUnlock(AchievementId.serve100);
    if (newTotalEarnings >= 500) tryUnlock(AchievementId.earn500);
    if (newTotalEarnings >= 2000) tryUnlock(AchievementId.earn2000);
    if (newVibes.length >= 18) tryUnlock(AchievementId.allVibes);
    if (challengesCompleted > prevChallengesCompleted) {
      tryUnlock(AchievementId.firstChallenge);
    }
    if (newRank == FloristRank.masterFlorist) {
      tryUnlock(AchievementId.rankMaster);
    }
    if (newRank == FloristRank.bloomLegend) {
      tryUnlock(AchievementId.rankLegend);
    }

    return (unlocked, progress, newQueue);
  }

  // ── UI event acknowledgement ──────────────────────────────────────────────────

  void clearPendingRankUp() {
    state = state.copyWith(clearPendingRankUp: true);
  }

  /// Pop the first pending achievement from the queue.
  void popPendingAchievement() {
    if (state.pendingAchievements.isEmpty) return;
    state = state.copyWith(
      pendingAchievements: state.pendingAchievements.sublist(1),
    );
  }

  /// Pop the first pending memory snippet from the queue.
  void popPendingMemory() {
    if (state.pendingMemories.isEmpty) return;
    state = state.copyWith(
      pendingMemories: state.pendingMemories.sublist(1),
    );
  }

  void clearPendingStoryChapter() {
    state = state.copyWith(clearPendingStoryChapter: true);
  }

  void clearPendingReputationBoard() {
    state = state.copyWith(pendingReputationBoard: false);
  }

  // ── Tier 3 — Flower growing ───────────────────────────────────────────────────

  /// Buy a seed packet and plant it in [slot] (0–2).
  /// Returns false if can't afford or slot is occupied.
  bool plantSeed(String flowerId, int slot) {
    final flower = flowerById[flowerId];
    if (flower == null || !flower.isGrowable) return false;
    final seedCost = flower.seedPrice!;
    if (state.money < seedCost) return false;
    if (state.windowsillPlots.any((p) => p.slot == slot)) return false;

    final newPlot = GrowingPlant(
      flowerId: flowerId,
      slot: slot,
      plantedAtMs: DateTime.now().millisecondsSinceEpoch,
      growthMinutes: flower.growthMinutes!,
    );
    state = state.copyWith(
      money: state.money - seedCost,
      windowsillPlots: [...state.windowsillPlots, newPlot],
    );
    PersistenceService.saveState(state);
    return true;
  }

  /// Harvest a ready plant, adding the flower to inventory and clearing the slot.
  bool harvestPlant(int slot) {
    final idx = state.windowsillPlots.indexWhere((p) => p.slot == slot);
    if (idx < 0) return false;
    final plot = state.windowsillPlots[idx];
    if (!plot.isReady) return false;

    final inventory = Map<String, int>.from(state.inventory);
    final dayAdded = Map<String, int>.from(state.inventoryDayAdded);
    inventory[plot.flowerId] = (inventory[plot.flowerId] ?? 0) + 1;
    dayAdded[plot.flowerId] = state.day;

    final remaining = state.windowsillPlots.where((p) => p.slot != slot).toList();
    state = state.copyWith(
      inventory: inventory,
      inventoryDayAdded: dayAdded,
      windowsillPlots: remaining,
    );
    PersistenceService.saveState(state);
    return true;
  }

  // ── Tier 3 — Delivery missions ────────────────────────────────────────────────

  /// Submit a bouquet for a delivery mission. Returns the result.
  DeliveryResult submitDelivery(String missionId, List<Flower> bouquet) {
    final idx = state.pendingDeliveries.indexWhere((m) => m.id == missionId);
    if (idx < 0) return DeliveryResult.poor;
    final mission = state.pendingDeliveries[idx];

    // Score: count how many required vibes are represented in the bouquet
    final bouquetVibes = bouquet.expand((f) => f.vibes).toSet();
    final matched =
        mission.requiredVibes.where((v) => bouquetVibes.contains(v)).length;
    final total = mission.requiredVibes.length;
    final ratio = total > 0 ? matched / total : 0.0;

    final result = ratio >= 0.8
        ? DeliveryResult.great
        : ratio >= 0.5
            ? DeliveryResult.good
            : DeliveryResult.poor;

    final baseReward = mission.reward;
    final earned = result == DeliveryResult.great
        ? (baseReward * 1.25).round()
        : result == DeliveryResult.good
            ? baseReward
            : (baseReward * 0.5).round();

    final updated = List<DeliveryMission>.from(state.pendingDeliveries);
    updated[idx] = mission.copyWith(result: result, earned: earned);

    state = state.copyWith(
      money: state.money + earned,
      totalEarnings: state.totalEarnings + earned,
      pendingDeliveries: updated,
    );
    PersistenceService.saveState(state);
    return result;
  }

  // ── Tier 7 — Onboarding reward ───────────────────────────────────────────────

  /// Called once when the tutorial finishes. Grants a starter pack:
  /// +$50 bonus coins, 2 peonies, 2 orchids, 1 ranunculus, and a small pouch of
  /// gems so the player owns the premium currency before ever being asked to
  /// buy it.
  void claimTutorialReward() {
    final inv = Map<String, int>.from(state.inventory);
    final dayAdded = Map<String, int>.from(state.inventoryDayAdded);
    for (final entry in {'peony': 2, 'orchid': 2, 'ranunculus': 1}.entries) {
      inv[entry.key] = (inv[entry.key] ?? 0) + entry.value;
      dayAdded[entry.key] = state.day;
    }
    state = state.copyWith(
      money: state.money + 50,
      gems: state.gems + kTutorialGemGift,
      inventory: inv,
      inventoryDayAdded: dayAdded,
    );
    PersistenceService.saveState(state);
  }

  // ── Gems (premium currency) ─────────────────────────────────────────────────
  //
  // Gems only ever enter the wallet from a confirmed store purchase or the
  // one-off tutorial gift — never from play — so the coin economy stays exactly
  // as balanced for a player who never spends.

  /// Credit [amount] gems. Call only after the store confirms payment (or for
  /// the tutorial gift).
  void grantGems(int amount) {
    if (amount <= 0) return;
    state = state.copyWith(gems: state.gems + amount);
    PersistenceService.saveState(state);
  }

  /// Deduct [cost] gems. Returns false (and changes nothing) if too poor.
  bool _spendGems(int cost) {
    if (cost <= 0 || state.gems < cost) return false;
    state = state.copyWith(gems: state.gems - cost);
    return true;
  }

  /// Instantly top every unlocked flower up to a full shelf. Saves the player a
  /// market run; grants no coins.
  bool gemInstantRestock() {
    if (!_spendGems(kGemCostInstantRestock)) return false;
    const shelfTarget = 5;
    final inv = Map<String, int>.from(state.inventory);
    final dayAdded = Map<String, int>.from(state.inventoryDayAdded);
    for (final f in unlockedFlowers(state.day)) {
      if ((inv[f.id] ?? 0) < shelfTarget) {
        inv[f.id] = shelfTarget;
        dayAdded[f.id] = state.day; // arrives fresh
      }
    }
    state = state.copyWith(inventory: inv, inventoryDayAdded: dayAdded);
    PersistenceService.saveState(state);
    AnalyticsService.instance.gemsSpent('instant_restock', kGemCostInstantRestock);
    return true;
  }

  /// Reset the freshness clock on everything in stock — nothing wilts tonight.
  bool gemFreshWater() {
    if (!_spendGems(kGemCostFreshWater)) return false;
    final dayAdded = Map<String, int>.from(state.inventoryDayAdded);
    state.inventory.forEach((id, qty) {
      if (qty > 0) dayAdded[id] = state.day;
    });
    state = state.copyWith(inventoryDayAdded: dayAdded);
    PersistenceService.saveState(state);
    AnalyticsService.instance.gemsSpent('fresh_water', kGemCostFreshWater);
    return true;
  }

  /// Swap today's three challenges for a different set. Progress on the old set
  /// is discarded; rewards themselves are unchanged.
  bool gemRerollChallenges() {
    if (!_spendGems(kGemCostRerollChallenges)) return false;
    final salt = state.dailyChallenges.fold<int>(
          1,
          (acc, c) => acc + c.id.hashCode.abs() % 97,
        ) +
        state.totalOrdersServed;
    state = state.copyWith(
      dailyChallenges: generateDailyChallenges(state.day, salt: salt),
    );
    PersistenceService.saveState(state);
    AnalyticsService.instance
        .gemsSpent('reroll_challenges', kGemCostRerollChallenges);
    return true;
  }

  // ── Tier 3 — Login streak ─────────────────────────────────────────────────────

  /// Call once on app start. Compares today's real date to lastLoginDate.
  /// Updates streak and optionally grants a rare flower on day-7 milestone.
  void checkLoginStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final last = state.lastLoginDateMs;

    if (last == today) return; // Already checked today

    final lastDate = DateTime.fromMillisecondsSinceEpoch(last);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final isConsecutive = DateTime(lastDate.year, lastDate.month, lastDate.day)
        .isAtSameMomentAs(yesterday);

    final newStreak = last == 0
        ? 1
        : isConsecutive
            ? state.loginStreak + 1
            : 1;

    // Every 7-day streak milestone: grant a free peony (rare flower)
    Map<String, int>? bonusInventory;
    Map<String, int>? bonusDayAdded;
    if (newStreak % 7 == 0) {
      bonusInventory = Map<String, int>.from(state.inventory);
      bonusInventory['peony'] = (bonusInventory['peony'] ?? 0) + 2;
      bonusDayAdded = Map<String, int>.from(state.inventoryDayAdded);
      bonusDayAdded['peony'] = state.day;
    }

    state = state.copyWith(
      loginStreak: newStreak,
      lastLoginDateMs: today,
      inventory: bonusInventory,
      inventoryDayAdded: bonusDayAdded,
    );
    AnalyticsService.instance.loginStreak(newStreak);
    PersistenceService.saveState(state);
  }

  // ── Restock / market ──────────────────────────────────────────────────────────

  /// [costPerUnit] lets the caller pass a flash-sale price instead of the
  /// normal flower cost (optional; defaults to [Flower.cost]).
  bool restockFlower(String flowerId, int qty, {int? costPerUnit}) {
    final flower = flowerById[flowerId];
    if (flower == null) return false;

    // Extra Shelf upgrade: 10% off all market restocks.
    final basePrice = costPerUnit ?? flower.cost;
    final unitPrice = state.upgrades.hasExtraShelf
        ? (basePrice * 0.9).round()
        : basePrice;
    final totalCost = unitPrice * qty;
    if (state.money < totalCost) return false;

    final inventory = Map<String, int>.from(state.inventory);
    inventory[flowerId] = (inventory[flowerId] ?? 0) + qty;

    final dayAdded = Map<String, int>.from(state.inventoryDayAdded);
    dayAdded[flowerId] = state.day;

    state = state.copyWith(
      money: state.money - totalCost,
      inventory: inventory,
      inventoryDayAdded: dayAdded,
      restockSpentToday: state.restockSpentToday + totalCost,
    );

    PersistenceService.saveState(state);
    return true;
  }

  // ── Shop upgrades ─────────────────────────────────────────────────────────────

  bool purchaseUpgrade(UpgradeId id) {
    if (state.upgrades.has(id)) return false; // already owned
    if (state.money < id.cost) return false;

    final newUpgrades = state.upgrades.withUpgrade(id);
    final unlockedAchs = Set<String>.from(state.unlockedAchievements);
    final newQueue = List<String>.from(state.pendingAchievements);

    // Achievement: first upgrade
    if (!unlockedAchs.contains(AchievementId.firstUpgrade.name)) {
      unlockedAchs.add(AchievementId.firstUpgrade.name);
      newQueue.add(AchievementId.firstUpgrade.name);
    }

    state = state.copyWith(
      money: state.money - id.cost,
      upgrades: newUpgrades,
      unlockedAchievements: unlockedAchs,
      pendingAchievements: newQueue,
    );

    PersistenceService.saveState(state);
    return true;
  }

  // ── Day progression ───────────────────────────────────────────────────────────

  void startNextDay() {
    // Next level up — after replaying an old level this still jumps to the
    // frontier of the campaign rather than re-walking already-beaten days.
    final nextDay = state.nextLevel > state.day ? state.nextLevel : state.day + 1;

    // Check perfectDay achievement before resetting completedToday
    final hadPoorToday =
        state.completedToday.any((e) => e.$1.result == OrderResult.poor);
    final unlockedAchs = Set<String>.from(state.unlockedAchievements);
    final newQueue = List<String>.from(state.pendingAchievements);

    if (!hadPoorToday &&
        state.completedToday.isNotEmpty &&
        !unlockedAchs.contains(AchievementId.perfectDay.name)) {
      unlockedAchs.add(AchievementId.perfectDay.name);
      newQueue.add(AchievementId.perfectDay.name);
    }

    // Day milestone achievements
    void tryDay(AchievementId id) {
      if (!unlockedAchs.contains(id.name)) {
        unlockedAchs.add(id.name);
        newQueue.add(id.name);
      }
    }

    if (nextDay >= 5) tryDay(AchievementId.day5);
    if (nextDay >= 10) tryDay(AchievementId.day10);

    // Wilting
    final inventory = Map<String, int>.from(state.inventory);
    final dayAdded = Map<String, int>.from(state.inventoryDayAdded);
    final bonusDays = state.upgrades.freshnessBonusDays;

    for (final id in inventory.keys.toList()) {
      final flower = flowerById[id];
      if (flower == null) continue;
      // Flowers without a recorded add-day are treated as added today
      // (never wilt them by accident).
      final addedDay = dayAdded[id] ?? state.day;
      final daysInStock = state.day - addedDay;
      if (daysInStock >= flower.wiltsAfterDays + bonusDays) {
        inventory.remove(id);
        dayAdded.remove(id);
      }
    }

    final newChallenges = generateDailyChallenges(nextDay);

    // ── Story arc chapter check ───────────────────────────────────────────────
    final storyChapter = chapterForDay(nextDay);
    final int? newStoryChapterDay = storyChapter != null ? nextDay : null;

    // ── Weekly reputation board (every 7 days, starting from day 8) ──────────
    final showRepBoard = nextDay > 7 && (nextDay - 1) % 7 == 0;

    // ── Delivery missions for the new day ─────────────────────────────────────
    final newDeliveries = generateDeliveries(nextDay);

    // ── Tier 5: Best day earnings ─────────────────────────────────────────────
    final todayEarnings = state.dayEarnings;
    final newBestDay = todayEarnings > state.bestDayEarnings
        ? todayEarnings
        : state.bestDayEarnings;

    // ── Tier 4: Seasonal event banner ─────────────────────────────────────────
    final showSeasonalBanner = isEventStartDay(nextDay);

    // ── Tier 4: Big order commission ──────────────────────────────────────────
    // Offer a new big order when one becomes available AND none is active yet.
    BigOrder? nextBigOrder = state.activeBigOrder;
    if (nextBigOrder == null || nextBigOrder.isComplete) {
      final offered = bigOrderForDay(nextDay);
      nextBigOrder = offered; // may be null (non-window days)
    }

    // ── Tier 4: Wholesale delivery ────────────────────────────────────────────
    // Flowers ordered wholesale yesterday arrive this morning.
    if (state.wholesalePending.isNotEmpty) {
      for (final entry in state.wholesalePending.entries) {
        inventory[entry.key] = (inventory[entry.key] ?? 0) + entry.value;
        dayAdded[entry.key] = nextDay;
      }
    }

    state = GameState(
      day: nextDay,
      money: state.money,
      gems: state.gems, // purchased currency must survive the day rollover
      inventory: inventory,
      inventoryDayAdded: dayAdded,
      restockSpentToday: 0,
      dayOrders: generateDayOrders(
        nextDay,
        extraOrders: state.upgrades.extraCustomersPerDay,
      ),
      currentOrderIndex: 0,
      bouquetWorkspace: [],
      completedToday: [],
      xp: state.xp,
      upgrades: state.upgrades,
      unlockedAchievements: unlockedAchs,
      totalOrdersServed: state.totalOrdersServed,
      totalEarnings: state.totalEarnings,
      greatStreak: state.greatStreak,
      servedVibeIds: state.servedVibeIds,
      dailyChallenges: newChallenges,
      challengeGameDay: nextDay,
      customerFriendship: state.customerFriendship,
      pendingMemories: state.pendingMemories,
      reputationScore: state.reputationScore,
      pendingAchievements: newQueue,
      pendingStoryChapterDay: newStoryChapterDay,
      pendingReputationBoard: showRepBoard,
      windowsillPlots: state.windowsillPlots, // plots persist across days
      pendingDeliveries: newDeliveries,
      loginStreak: state.loginStreak,
      lastLoginDateMs: state.lastLoginDateMs,
      vibeDiscoveries: state.vibeDiscoveries,
      activeBigOrder: nextBigOrder,
      wholesalePending: const {}, // reset — just delivered
      pendingSeasonalBanner: showSeasonalBanner,
      purchasedDecor: state.purchasedDecor,
      activeDecor: state.activeDecor,
      bouquetPresets: state.bouquetPresets,
      bestDayEarnings: newBestDay,
      allTimeFlowerUse: state.allTimeFlowerUse,
      levelStars: state.levelStars,
    );

    PersistenceService.saveState(state);
  }

  // ── Level campaign ────────────────────────────────────────────────────────────

  /// Jump to a specific level (replay or continue). Only unlocked levels are
  /// playable. Money, inventory, XP, upgrades, and all meta progress carry over.
  /// Returns false if the level is locked.
  bool startLevel(int level) {
    if (level < 1 || !state.isLevelUnlocked(level)) return false;

    // Already mid-way through this level? Just keep playing.
    if (state.day == level && !state.dayEnded) return true;

    // Advancing to the next day from a just-finished one must run the full
    // day-advance pipeline (wilting, wholesale arrivals, deliveries, events)
    // — otherwise skipping the market would skip all of that too.
    if (state.dayEnded && level == state.day + 1 && level == state.nextLevel) {
      startNextDay();
      return true;
    }

    state = GameState(
      day: level,
      money: state.money,
      gems: state.gems, // purchased currency must survive replaying a level
      inventory: state.inventory,
      inventoryDayAdded: state.inventoryDayAdded,
      restockSpentToday: 0,
      dayOrders: generateDayOrders(
        level,
        extraOrders: state.upgrades.extraCustomersPerDay,
      ),
      currentOrderIndex: 0,
      bouquetWorkspace: [],
      completedToday: [],
      xp: state.xp,
      upgrades: state.upgrades,
      unlockedAchievements: state.unlockedAchievements,
      totalOrdersServed: state.totalOrdersServed,
      totalEarnings: state.totalEarnings,
      greatStreak: state.greatStreak,
      servedVibeIds: state.servedVibeIds,
      dailyChallenges: generateDailyChallenges(level),
      challengeGameDay: level,
      customerFriendship: state.customerFriendship,
      pendingMemories: state.pendingMemories,
      reputationScore: state.reputationScore,
      windowsillPlots: state.windowsillPlots,
      pendingDeliveries: generateDeliveries(level),
      loginStreak: state.loginStreak,
      lastLoginDateMs: state.lastLoginDateMs,
      vibeDiscoveries: state.vibeDiscoveries,
      activeBigOrder: state.activeBigOrder,
      wholesalePending: state.wholesalePending,
      purchasedDecor: state.purchasedDecor,
      activeDecor: state.activeDecor,
      bouquetPresets: state.bouquetPresets,
      bestDayEarnings: state.bestDayEarnings,
      allTimeFlowerUse: state.allTimeFlowerUse,
      levelStars: state.levelStars,
    );
    PersistenceService.saveState(state);
    return true;
  }

  // ── Tier 4 — Big orders ───────────────────────────────────────────────────────

  /// Submit today's bouquet as the day's contribution to the active big order.
  /// Returns the contribution result, or null if no active order / already submitted.
  ContributionResult? contributeBigOrder(List<Flower> bouquet) {
    final order = state.activeBigOrder;
    if (order == null || order.isComplete) return null;

    final dayIdx = order.nextDayIndex;
    if (dayIdx == null) return null;

    // Score: vibe-match ratio, same logic as deliveries
    final bouquetVibes = bouquet.expand((f) => f.vibes).toSet();
    final matched =
        order.requiredVibes.where((v) => bouquetVibes.contains(v)).length;
    final total = order.requiredVibes.length;
    final ratio = total > 0 ? matched / total : 0.0;

    final result = ratio >= 0.8
        ? ContributionResult.great
        : ratio >= 0.5
            ? ContributionResult.good
            : ContributionResult.poor;

    final earned = result == ContributionResult.poor
        ? 0
        : result == ContributionResult.great
            ? (order.dailyReward * 1.25).round()
            : order.dailyReward;

    final updatedContributions =
        List<DayContribution>.from(order.contributions);
    updatedContributions[dayIdx] = DayContribution(
      flowerIds: bouquet.map((f) => f.id).toList(),
      result: result,
      earned: earned,
    );

    final updatedOrder = order.copyWith(contributions: updatedContributions);
    final isNowComplete = updatedOrder.isComplete;

    // Pay out: daily reward + completion bonus if all 3 days done
    final totalPayout = earned + (isNowComplete ? order.completionBonus : 0);

    // Flowers in the workspace were already deducted from inventory when added.
    // Clear the workspace without returning them (they're now part of the delivery).
    state = state.copyWith(
      activeBigOrder: updatedOrder,
      money: state.money + totalPayout,
      totalEarnings: state.totalEarnings + totalPayout,
      bouquetWorkspace: [],
    );
    PersistenceService.saveState(state);
    return result;
  }

  // ── Tier 6 — Clearance sale ───────────────────────────────────────────────────

  /// Sell [qty] units of a near-wilted flower at 50% of its purchase cost.
  /// Returns false if the flower isn't in inventory or qty is invalid.
  bool sellClearance(String flowerId, int qty) {
    final flower = flowerById[flowerId];
    if (flower == null) return false;
    final inStock = state.inventory[flowerId] ?? 0;
    if (qty <= 0 || qty > inStock) return false;

    final earned = (flower.cost * 0.5 * qty).round();
    final inventory = Map<String, int>.from(state.inventory);
    inventory[flowerId] = inStock - qty;
    if (inventory[flowerId] == 0) inventory.remove(flowerId);

    state = state.copyWith(
      money: state.money + earned,
      inventory: inventory,
    );
    PersistenceService.saveState(state);
    return true;
  }

  // ── Tier 4 — Wholesale ordering ───────────────────────────────────────────────

  /// Queue a wholesale order for [qty] of [flowerId]; flowers arrive tomorrow.
  /// Deducts [totalCost] immediately. Returns false if can't afford.
  bool placeWholesaleOrder(String flowerId, int qty, int totalCost) {
    if (state.money < totalCost) return false;
    final pending = Map<String, int>.from(state.wholesalePending);
    pending[flowerId] = (pending[flowerId] ?? 0) + qty;

    state = state.copyWith(
      money: state.money - totalCost,
      wholesalePending: pending,
      restockSpentToday: state.restockSpentToday + totalCost,
    );
    PersistenceService.saveState(state);
    return true;
  }

  // ── Tier 4 — UI acknowledgements ─────────────────────────────────────────────

  void clearPendingSeasonalBanner() {
    state = state.copyWith(pendingSeasonalBanner: false);
  }

  // ── Tier 5 — Shop decoration ──────────────────────────────────────────────────

  /// Buy a decoration item. Returns false if already owned or can't afford.
  bool purchaseDecor(String decorId) {
    final decor = decorById[decorId];
    if (decor == null) return false;
    if (decor.isDefault) return true; // always owned
    if (state.purchasedDecor.contains(decorId)) return false;
    if (state.money < decor.cost) return false;

    final owned = Set<String>.from(state.purchasedDecor)..add(decorId);
    state = state.copyWith(
      money: state.money - decor.cost,
      purchasedDecor: owned,
    );
    PersistenceService.saveState(state);
    return true;
  }

  /// Equip an owned decoration. Returns false if not owned.
  bool equipDecor(ShopDecorCategory category, String decorId) {
    final decor = decorById[decorId];
    if (decor == null) return false;
    if (!decor.isDefault && !state.purchasedDecor.contains(decorId)) {
      return false;
    }
    final updated = Map<String, String>.from(state.activeDecor);
    updated[category.name] = decorId;
    state = state.copyWith(activeDecor: updated);
    PersistenceService.saveState(state);
    return true;
  }

  // ── Tier 5 — Bouquet presets ──────────────────────────────────────────────────

  /// Save current workspace as a named preset (max 5).
  /// Returns false if workspace is empty or already at 5 presets.
  bool savePreset(String name) {
    if (state.bouquetWorkspace.isEmpty) return false;
    if (state.bouquetPresets.length >= 5) return false;
    final preset = BouquetPreset(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? 'Preset ${state.bouquetPresets.length + 1}' : name.trim(),
      flowerIds: state.bouquetWorkspace.map((f) => f.id).toList(),
    );
    state = state.copyWith(
      bouquetPresets: [...state.bouquetPresets, preset],
    );
    PersistenceService.saveState(state);
    return true;
  }

  /// Load a preset into the workspace, adding as many flowers as inventory allows.
  /// Clears the current workspace first.
  void loadPreset(String presetId) {
    final idx = state.bouquetPresets.indexWhere((p) => p.id == presetId);
    if (idx < 0) return;
    final preset = state.bouquetPresets[idx];

    // Clear workspace, returning flowers to inventory
    clearWorkspace();

    // Add each flower in the preset if available
    for (final flowerId in preset.flowerIds) {
      final qty = state.inventory[flowerId] ?? 0;
      if (qty > 0) {
        addFlowerToWorkspace(flowerId);
      }
    }
  }

  /// Delete a saved preset by ID.
  void deletePreset(String presetId) {
    state = state.copyWith(
      bouquetPresets:
          state.bouquetPresets.where((p) => p.id != presetId).toList(),
    );
    PersistenceService.saveState(state);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  bool get canSubmit =>
      state.bouquetWorkspace.length >=
      (state.currentOrder?.minFlowers ?? 999);

  int effectiveMaxFlowers() =>
      (state.currentOrder?.maxFlowers ?? 8) + state.upgrades.workspaceBonusSlots;

  bool get isAtMaxFlowers => state.bouquetWorkspace.length >= effectiveMaxFlowers();

  /// Rough number of days the current shelf can supply, based on how many
  /// customers arrive per day and the average order size at this tier.
  ///
  /// Read-only and deliberately approximate — it answers the only question the
  /// market really poses ("is this enough?") without pretending to predict the
  /// random order draw.
  int stockCoversDays() {
    final stems = state.inventory.values.fold<int>(0, (a, b) => a + b);
    if (stems <= 0) return 0;
    final perDay = ordersOnDay(state.day) * averageMinStems(state.day);
    if (perDay <= 0) return 0;
    return (stems / perDay).floor();
  }

  /// Stock that will be lost to wilting when the day next advances, as
  /// flowerId → quantity.
  ///
  /// Read-only, and deliberately mirrors the removal rule in [startNextDay]:
  /// a flower expires once it has been in stock for `wiltsAfterDays` (plus any
  /// freshness upgrade) days. Surfacing this on the end-of-day summary — while
  /// the player still has a market visit left — turns an invisible loss into a
  /// decision: use them tonight, or sell them off.
  ///
  /// If the wilt rule in [startNextDay] ever changes, change it here too.
  Map<String, int> wiltingTonight() {
    final doomed = <String, int>{};
    final bonusDays = state.upgrades.freshnessBonusDays;
    state.inventory.forEach((id, qty) {
      if (qty <= 0) return;
      final flower = flowerById[id];
      if (flower == null) return;
      final addedDay = state.inventoryDayAdded[id] ?? state.day;
      // +1: we are predicting the state after the day advances.
      final daysInStock = (state.day + 1) - addedDay;
      if (daysInStock >= flower.wiltsAfterDays + bonusDays) {
        doomed[id] = qty;
      }
    });
    return doomed;
  }

  int? freshnessRemaining(String flowerId) {
    final flower = flowerById[flowerId];
    if (flower == null) return null;
    final addedDay = state.inventoryDayAdded[flowerId];
    if (addedDay == null) return null;
    final elapsed = state.day - addedDay;
    final total = flower.wiltsAfterDays + state.upgrades.freshnessBonusDays;
    return (total - elapsed).clamp(0, total);
  }

  bool isNearlyWilted(String flowerId) {
    final remaining = freshnessRemaining(flowerId);
    return remaining != null && remaining <= 1;
  }
}

final gameProvider =
    NotifierProvider<GameNotifier, GameState>(GameNotifier.new);
