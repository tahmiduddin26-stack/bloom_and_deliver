import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/big_orders_data.dart';
import '../data/daily_challenges_data.dart';
import '../data/delivery_data.dart';
import '../data/flower_data.dart';
import '../data/order_data.dart';
import '../models/big_order.dart';
import '../models/bouquet_preset.dart';
import '../models/daily_challenge.dart';
import '../models/delivery_mission.dart';
import '../models/game_state.dart';
import '../models/growing_plant.dart';
import '../models/shop_upgrades.dart';

// ── Keys ─────────────────────────────────────────────────────────────────────

const _kDay = 'game_day';
const _kMoney = 'game_money';
const _kInventory = 'game_inventory';
const _kInventoryDayAdded = 'game_inventory_day_added';

// Tier 1 additions
const _kXp = 'game_xp';
const _kUpgrades = 'game_upgrades';
const _kAchievements = 'game_achievements';
const _kTotalServed = 'game_total_served';
const _kTotalEarnings = 'game_total_earnings';
const _kGreatStreak = 'game_great_streak';
const _kServedVibes = 'game_served_vibes';
const _kChallengeDay = 'game_challenge_day';
const _kChallenges = 'game_challenges';

// Tier 2 additions
const _kFriendship = 'game_friendship';
const _kReputation = 'game_reputation';

// Tier 3 additions
const _kWindowsill = 'game_windowsill';
const _kDeliveries = 'game_deliveries';
const _kLoginStreak = 'game_login_streak';
const _kLastLoginMs = 'game_last_login_ms';

// Tier 4 additions
const _kVibeDiscoveries = 'game_vibe_discoveries';
const _kActiveBigOrder  = 'game_active_big_order';
const _kWholesalePending = 'game_wholesale_pending';

// Tier 5 additions
const _kPurchasedDecor  = 'game_purchased_decor';
const _kActiveDecor     = 'game_active_decor';
const _kPresets         = 'game_bouquet_presets';
const _kBestDayEarnings = 'game_best_day_earnings';
const _kAllTimeFlowerUse = 'game_all_time_flower_use';

// Level campaign
const _kLevelStars = 'game_level_stars';

// ── Service ──────────────────────────────────────────────────────────────────

class PersistenceService {
  static Future<void> saveState(GameState state) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_kDay, state.day);
    await prefs.setInt(_kMoney, state.money);
    await prefs.setString(_kInventory, jsonEncode(state.inventory));
    await prefs.setString(
        _kInventoryDayAdded, jsonEncode(state.inventoryDayAdded));

    // Tier 1
    await prefs.setInt(_kXp, state.xp);
    await prefs.setString(
        _kUpgrades, jsonEncode(state.upgrades.toJson()));
    await prefs.setString(
        _kAchievements, jsonEncode(state.unlockedAchievements.toList()));
    await prefs.setInt(_kTotalServed, state.totalOrdersServed);
    await prefs.setInt(_kTotalEarnings, state.totalEarnings);
    await prefs.setInt(_kGreatStreak, state.greatStreak);
    await prefs.setString(
        _kServedVibes, jsonEncode(state.servedVibeIds.toList()));
    await prefs.setInt(_kChallengeDay, state.challengeGameDay);
    await prefs.setString(
        _kChallenges,
        jsonEncode(state.dailyChallenges.map((c) => c.toJson()).toList()));

    // Tier 2
    await prefs.setString(
        _kFriendship,
        jsonEncode(state.customerFriendship));
    await prefs.setInt(_kReputation, state.reputationScore);

    // Tier 3
    await prefs.setString(
        _kWindowsill,
        jsonEncode(state.windowsillPlots.map((p) => p.toJson()).toList()));
    await prefs.setString(
        _kDeliveries,
        jsonEncode(state.pendingDeliveries.map((d) => d.toJson()).toList()));
    await prefs.setInt(_kLoginStreak, state.loginStreak);
    await prefs.setInt(_kLastLoginMs, state.lastLoginDateMs);

    // Tier 4
    await prefs.setString(
        _kVibeDiscoveries,
        jsonEncode(state.vibeDiscoveries.toList()));
    if (state.activeBigOrder != null) {
      await prefs.setString(
          _kActiveBigOrder,
          jsonEncode(state.activeBigOrder!.toJson()));
    } else {
      await prefs.remove(_kActiveBigOrder);
    }
    await prefs.setString(
        _kWholesalePending,
        jsonEncode(state.wholesalePending));

    // Tier 5
    await prefs.setString(
        _kPurchasedDecor,
        jsonEncode(state.purchasedDecor.toList()));
    await prefs.setString(
        _kActiveDecor,
        jsonEncode(state.activeDecor));
    await prefs.setString(
        _kPresets,
        jsonEncode(state.bouquetPresets.map((p) => p.toJson()).toList()));
    await prefs.setInt(_kBestDayEarnings, state.bestDayEarnings);
    await prefs.setString(
        _kAllTimeFlowerUse,
        jsonEncode(state.allTimeFlowerUse));

    // Level campaign
    await prefs.setString(
        _kLevelStars,
        jsonEncode(
            state.levelStars.map((k, v) => MapEntry(k.toString(), v))));
  }

  static Future<GameState?> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_kDay)) return null;

    try {
      final day = prefs.getInt(_kDay)!;
      final money = prefs.getInt(_kMoney)!;

      // ── Inventory ──────────────────────────────────────────────────────────
      final rawInv = prefs.getString(_kInventory);
      final rawDayAdded = prefs.getString(_kInventoryDayAdded);

      final inventory = rawInv != null
          ? Map<String, int>.from(
              (jsonDecode(rawInv) as Map).map(
                (k, v) => MapEntry(k as String, (v as num).toInt()),
              ),
            )
          : defaultInventory;

      final inventoryDayAdded = rawDayAdded != null
          ? Map<String, int>.from(
              (jsonDecode(rawDayAdded) as Map).map(
                (k, v) => MapEntry(k as String, (v as num).toInt()),
              ),
            )
          : defaultInventoryDayAdded;

      // ── Tier 1 fields (graceful defaults for old saves) ────────────────────
      final xp = prefs.getInt(_kXp) ?? 0;

      final rawUpgrades = prefs.getString(_kUpgrades);
      final upgrades = rawUpgrades != null
          ? ShopUpgrades.fromJson(jsonDecode(rawUpgrades) as List)
          : const ShopUpgrades();

      final rawAch = prefs.getString(_kAchievements);
      final achievements = rawAch != null
          ? Set<String>.from((jsonDecode(rawAch) as List).cast<String>())
          : <String>{};

      final totalServed = prefs.getInt(_kTotalServed) ?? 0;
      final totalEarnings = prefs.getInt(_kTotalEarnings) ?? 0;
      final greatStreak = prefs.getInt(_kGreatStreak) ?? 0;

      final rawVibes = prefs.getString(_kServedVibes);
      final servedVibes = rawVibes != null
          ? Set<String>.from((jsonDecode(rawVibes) as List).cast<String>())
          : <String>{};

      final challengeDay = prefs.getInt(_kChallengeDay) ?? 0;
      final rawChallenges = prefs.getString(_kChallenges);

      // Tier 2
      final rawFriendship = prefs.getString(_kFriendship);
      final customerFriendship = rawFriendship != null
          ? Map<String, int>.from(
              (jsonDecode(rawFriendship) as Map).map(
                (k, v) => MapEntry(k as String, (v as num).toInt()),
              ),
            )
          : <String, int>{};
      final reputation = prefs.getInt(_kReputation) ?? 0;

      // Tier 3
      final rawWindowsill = prefs.getString(_kWindowsill);
      final windowsillPlots = rawWindowsill != null
          ? (jsonDecode(rawWindowsill) as List)
              .map((e) => GrowingPlant.fromJson(e as Map<String, dynamic>))
              .toList()
          : <GrowingPlant>[];

      final rawDeliveries = prefs.getString(_kDeliveries);
      List<DeliveryMission> deliveries;

      final loginStreak = prefs.getInt(_kLoginStreak) ?? 0;
      final lastLoginMs = prefs.getInt(_kLastLoginMs) ?? 0;

      if (rawDeliveries != null) {
        try {
          deliveries = (jsonDecode(rawDeliveries) as List)
              .map((e) => DeliveryMission.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (_) {
          deliveries = generateDeliveries(day);
        }
      } else {
        deliveries = generateDeliveries(day);
      }

      List<DailyChallenge> challenges;
      if (rawChallenges != null && challengeDay == day) {
        // Restore saved challenges (same game day)
        final list = jsonDecode(rawChallenges) as List;
        challenges = list
            .map((e) => DailyChallenge.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        // New day or no saved challenges — generate fresh
        challenges = generateDailyChallenges(day);
      }

      // Tier 4
      final rawVibeDisc = prefs.getString(_kVibeDiscoveries);
      final vibeDiscoveries = rawVibeDisc != null
          ? Set<String>.from((jsonDecode(rawVibeDisc) as List).cast<String>())
          : <String>{};

      final rawBigOrder = prefs.getString(_kActiveBigOrder);
      BigOrder? activeBigOrder;
      if (rawBigOrder != null) {
        try {
          final j = jsonDecode(rawBigOrder) as Map<String, dynamic>;
          final template = bigOrderById(j['id'] as String);
          if (template != null) {
            activeBigOrder = BigOrder.fromJson(j, template);
          }
        } catch (_) {
          activeBigOrder = null;
        }
      }

      final rawWholesale = prefs.getString(_kWholesalePending);
      final wholesalePending = rawWholesale != null
          ? Map<String, int>.from(
              (jsonDecode(rawWholesale) as Map).map(
                (k, v) => MapEntry(k as String, (v as num).toInt()),
              ),
            )
          : <String, int>{};

      // Tier 5
      final rawPurchasedDecor = prefs.getString(_kPurchasedDecor);
      final purchasedDecor = rawPurchasedDecor != null
          ? Set<String>.from((jsonDecode(rawPurchasedDecor) as List).cast<String>())
          : <String>{};

      final rawActiveDecor = prefs.getString(_kActiveDecor);
      final activeDecor = rawActiveDecor != null
          ? Map<String, String>.from(
              (jsonDecode(rawActiveDecor) as Map).map(
                (k, v) => MapEntry(k as String, v as String),
              ),
            )
          : <String, String>{};

      final rawPresets = prefs.getString(_kPresets);
      final bouquetPresets = rawPresets != null
          ? (jsonDecode(rawPresets) as List)
              .map((e) => BouquetPreset.fromJson(e as Map<String, dynamic>))
              .toList()
          : <BouquetPreset>[];

      final bestDayEarnings = prefs.getInt(_kBestDayEarnings) ?? 0;

      final rawFlowerUse = prefs.getString(_kAllTimeFlowerUse);
      final allTimeFlowerUse = rawFlowerUse != null
          ? Map<String, int>.from(
              (jsonDecode(rawFlowerUse) as Map).map(
                (k, v) => MapEntry(k as String, (v as num).toInt()),
              ),
            )
          : <String, int>{};

      // Level campaign
      final rawLevelStars = prefs.getString(_kLevelStars);
      var levelStars = rawLevelStars != null
          ? Map<int, int>.from(
              (jsonDecode(rawLevelStars) as Map).map(
                (k, v) => MapEntry(int.parse(k as String), (v as num).toInt()),
              ),
            )
          : <int, int>{};
      // Migration: old saves have a day counter but no level records —
      // credit 1 star for every day already beaten so the map matches.
      if (levelStars.isEmpty && day > 1) {
        levelStars = {for (var i = 1; i < day; i++) i: 1};
      }

      return GameState(
        day: day,
        money: money,
        inventory: inventory,
        inventoryDayAdded: inventoryDayAdded,
        restockSpentToday: 0,
        dayOrders: generateDayOrders(
          day,
          extraOrders: upgrades.extraCustomersPerDay,
        ),
        currentOrderIndex: 0,
        bouquetWorkspace: [],
        completedToday: [],
        xp: xp,
        upgrades: upgrades,
        unlockedAchievements: achievements,
        totalOrdersServed: totalServed,
        totalEarnings: totalEarnings,
        greatStreak: greatStreak,
        servedVibeIds: servedVibes,
        dailyChallenges: challenges,
        challengeGameDay: day,
        customerFriendship: customerFriendship,
        reputationScore: reputation,
        windowsillPlots: windowsillPlots,
        pendingDeliveries: deliveries,
        loginStreak: loginStreak,
        lastLoginDateMs: lastLoginMs,
        vibeDiscoveries: vibeDiscoveries,
        activeBigOrder: activeBigOrder,
        wholesalePending: wholesalePending,
        purchasedDecor: purchasedDecor,
        activeDecor: activeDecor,
        bouquetPresets: bouquetPresets,
        bestDayEarnings: bestDayEarnings,
        allTimeFlowerUse: allTimeFlowerUse,
        levelStars: levelStars,
      );
    } catch (_) {
      await clearSave();
      return null;
    }
  }

  static Future<void> clearSave() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      _kDay, _kMoney, _kInventory, _kInventoryDayAdded,
      _kXp, _kUpgrades, _kAchievements, _kTotalServed,
      _kTotalEarnings, _kGreatStreak, _kServedVibes,
      _kChallengeDay, _kChallenges,
      _kFriendship, _kReputation,
      _kWindowsill, _kDeliveries, _kLoginStreak, _kLastLoginMs,
      _kVibeDiscoveries, _kActiveBigOrder, _kWholesalePending,
      _kPurchasedDecor, _kActiveDecor, _kPresets,
      _kBestDayEarnings, _kAllTimeFlowerUse,
      _kLevelStars,
    ]) {
      await prefs.remove(key);
    }
  }
}
