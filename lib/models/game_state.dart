import 'big_order.dart';
import 'bouquet_order.dart';
import 'bouquet_preset.dart';
import 'daily_challenge.dart';
import 'delivery_mission.dart';
import 'florist_rank.dart';
import 'flower.dart';
import 'growing_plant.dart';
import 'shop_upgrades.dart';

class GameState {
  // ── Core ─────────────────────────────────────────────────────────────────────
  final int day;
  final int money;
  final Map<String, int> inventory; // flowerId -> quantity
  final Map<String, int> inventoryDayAdded;
  final int restockSpentToday;
  final List<BouquetOrder> dayOrders;
  final int currentOrderIndex;
  final List<Flower> bouquetWorkspace;
  final List<(BouquetOrder, int)> completedToday;
  final bool dayEnded;

  // ── Progression ───────────────────────────────────────────────────────────────
  final int xp;
  final ShopUpgrades upgrades;

  // ── Achievements ──────────────────────────────────────────────────────────────
  final Set<String> unlockedAchievements; // AchievementId.name strings
  final int totalOrdersServed;
  final int totalEarnings;
  final int greatStreak; // consecutive great orders (resets on non-great)
  final Set<String> servedVibeIds; // VibeTag.name strings for allVibes ach.

  // ── Daily challenges ──────────────────────────────────────────────────────────
  final List<DailyChallenge> dailyChallenges;
  final int challengeGameDay; // which game day these challenges were generated for

  // ── Tier 2 — Narrative & friendship ──────────────────────────────────────────

  /// customerId → friendship level (0–5). Regulars cap at 5; casuals at 2.
  final Map<String, int> customerFriendship;

  /// Queue of memory snippets to display. Format: "customerId:snippetIndex".
  final List<String> pendingMemories;

  /// Cumulative reputation score (increases per order quality).
  final int reputationScore;

  // ── Pending UI events ─────────────────────────────────────────────────────────
  /// Non-null when a rank-up just happened — UI should show rank-up dialog.
  final FloristRank? pendingRankUp;

  /// Queue of achievement id strings to celebrate. UI pops one at a time.
  final List<String> pendingAchievements;

  /// Non-null when a story chapter should be shown (set to the day number).
  final int? pendingStoryChapterDay;

  /// True when the weekly reputation board should be shown.
  final bool pendingReputationBoard;

  // ── Tier 3 — Second loops ─────────────────────────────────────────────────────

  /// Active windowsill growing plots (max 3).
  final List<GrowingPlant> windowsillPlots;

  /// Delivery missions available after the current day ends.
  final List<DeliveryMission> pendingDeliveries;

  /// Real-world consecutive login days.
  final int loginStreak;

  /// Midnight timestamp (ms) of the last login day for streak tracking.
  final int lastLoginDateMs;

  // ── Tier 4 — Content & Events ─────────────────────────────────────────────────

  /// Vibe tags the player has discovered (used in at least one accepted bouquet).
  /// Stored as VibeTag.name strings.
  final Set<String> vibeDiscoveries;

  /// Active multi-day big-order commission, if any.
  final BigOrder? activeBigOrder;

  /// Flowers ordered wholesale from the market — delivered at start of next day.
  /// flowerId → quantity pending delivery.
  final Map<String, int> wholesalePending;

  /// True on the first game-day of a seasonal event — cleared after banner shown.
  final bool pendingSeasonalBanner;

  // ── Tier 5 — Shop customisation ───────────────────────────────────────────────

  /// Decoration IDs the player has purchased. Defaults always count as owned.
  final Set<String> purchasedDecor;

  /// Active decoration per category. Key = ShopDecorCategory.name string.
  final Map<String, String> activeDecor;

  /// Saved bouquet recipes. Max 5.
  final List<BouquetPreset> bouquetPresets;

  /// Best earnings achieved in a single day (for stats screen).
  final int bestDayEarnings;

  /// All-time flower use count. flowerId → total uses across all bouquets.
  final Map<String, int> allTimeFlowerUse;

  // ── Level campaign ────────────────────────────────────────────────────────────

  /// Best star rating earned per level. level number → stars (1–3).
  /// A level appears here once it has been completed at least once.
  final Map<int, int> levelStars;

  const GameState({
    required this.day,
    required this.money,
    required this.inventory,
    required this.inventoryDayAdded,
    this.restockSpentToday = 0,
    required this.dayOrders,
    required this.currentOrderIndex,
    required this.bouquetWorkspace,
    required this.completedToday,
    this.dayEnded = false,
    this.xp = 0,
    this.upgrades = const ShopUpgrades(),
    this.unlockedAchievements = const {},
    this.totalOrdersServed = 0,
    this.totalEarnings = 0,
    this.greatStreak = 0,
    this.servedVibeIds = const {},
    this.dailyChallenges = const [],
    this.challengeGameDay = 0,
    this.customerFriendship = const {},
    this.pendingMemories = const [],
    this.reputationScore = 0,
    this.pendingRankUp,
    this.pendingAchievements = const [],
    this.pendingStoryChapterDay,
    this.pendingReputationBoard = false,
    this.windowsillPlots = const [],
    this.pendingDeliveries = const [],
    this.loginStreak = 0,
    this.lastLoginDateMs = 0,
    this.vibeDiscoveries = const {},
    this.activeBigOrder,
    this.wholesalePending = const {},
    this.pendingSeasonalBanner = false,
    this.purchasedDecor = const {},
    this.activeDecor = const {},
    this.bouquetPresets = const [],
    this.bestDayEarnings = 0,
    this.allTimeFlowerUse = const {},
    this.levelStars = const {},
  });

  // ── Derived ── Level campaign helpers ────────────────────────────────────────

  /// Highest completed level (0 if none).
  int get highestCompletedLevel =>
      levelStars.keys.isEmpty ? 0 : levelStars.keys.reduce((a, b) => a > b ? a : b);

  /// The next level available to play.
  int get nextLevel => highestCompletedLevel + 1;

  /// True if [level] can be played (completed before, or the next one up).
  bool isLevelUnlocked(int level) => level <= nextLevel;

  /// Best stars earned on [level], or 0 if not completed.
  int starsForLevel(int level) => levelStars[level] ?? 0;

  /// Total stars collected across all levels.
  int get totalStars => levelStars.values.fold(0, (a, b) => a + b);

  // ── Derived ───────────────────────────────────────────────────────────────────

  BouquetOrder? get currentOrder =>
      currentOrderIndex < dayOrders.length ? dayOrders[currentOrderIndex] : null;

  bool get allOrdersServed => currentOrderIndex >= dayOrders.length;
  int get ordersRemaining => dayOrders.length - currentOrderIndex;
  int get dayEarnings => completedToday.fold(0, (s, e) => s + e.$2);
  int get dayProfit => dayEarnings - restockSpentToday;

  FloristRank get rank => FloristRankInfo.fromXp(xp);

  int friendshipFor(String customerId) => customerFriendship[customerId] ?? 0;

  // ── Derived ── Tier 5 helpers ─────────────────────────────────────────────────

  /// Returns the active decoration ID for a given category name key,
  /// falling back to the default ID if none is set.
  String activeDecorId(String categoryKey, String defaultId) =>
      activeDecor[categoryKey] ?? defaultId;

  bool ownsDecor(String id) =>
      purchasedDecor.contains(id);

  String? get favoriteFlower {
    if (allTimeFlowerUse.isEmpty) return null;
    return allTimeFlowerUse.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  // ── copyWith ─────────────────────────────────────────────────────────────────

  GameState copyWith({
    int? day,
    int? money,
    Map<String, int>? inventory,
    Map<String, int>? inventoryDayAdded,
    int? restockSpentToday,
    List<BouquetOrder>? dayOrders,
    int? currentOrderIndex,
    List<Flower>? bouquetWorkspace,
    List<(BouquetOrder, int)>? completedToday,
    bool? dayEnded,
    int? xp,
    ShopUpgrades? upgrades,
    Set<String>? unlockedAchievements,
    int? totalOrdersServed,
    int? totalEarnings,
    int? greatStreak,
    Set<String>? servedVibeIds,
    List<DailyChallenge>? dailyChallenges,
    int? challengeGameDay,
    Map<String, int>? customerFriendship,
    List<String>? pendingMemories,
    int? reputationScore,
    FloristRank? pendingRankUp,
    bool clearPendingRankUp = false,
    List<String>? pendingAchievements,
    int? pendingStoryChapterDay,
    bool clearPendingStoryChapter = false,
    bool? pendingReputationBoard,
    List<GrowingPlant>? windowsillPlots,
    List<DeliveryMission>? pendingDeliveries,
    int? loginStreak,
    int? lastLoginDateMs,
    Set<String>? vibeDiscoveries,
    BigOrder? activeBigOrder,
    bool clearActiveBigOrder = false,
    Map<String, int>? wholesalePending,
    bool? pendingSeasonalBanner,
    Set<String>? purchasedDecor,
    Map<String, String>? activeDecor,
    List<BouquetPreset>? bouquetPresets,
    int? bestDayEarnings,
    Map<String, int>? allTimeFlowerUse,
    Map<int, int>? levelStars,
  }) =>
      GameState(
        day: day ?? this.day,
        money: money ?? this.money,
        inventory: inventory ?? this.inventory,
        inventoryDayAdded: inventoryDayAdded ?? this.inventoryDayAdded,
        restockSpentToday: restockSpentToday ?? this.restockSpentToday,
        dayOrders: dayOrders ?? this.dayOrders,
        currentOrderIndex: currentOrderIndex ?? this.currentOrderIndex,
        bouquetWorkspace: bouquetWorkspace ?? this.bouquetWorkspace,
        completedToday: completedToday ?? this.completedToday,
        dayEnded: dayEnded ?? this.dayEnded,
        xp: xp ?? this.xp,
        upgrades: upgrades ?? this.upgrades,
        unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
        totalOrdersServed: totalOrdersServed ?? this.totalOrdersServed,
        totalEarnings: totalEarnings ?? this.totalEarnings,
        greatStreak: greatStreak ?? this.greatStreak,
        servedVibeIds: servedVibeIds ?? this.servedVibeIds,
        dailyChallenges: dailyChallenges ?? this.dailyChallenges,
        challengeGameDay: challengeGameDay ?? this.challengeGameDay,
        customerFriendship: customerFriendship ?? this.customerFriendship,
        pendingMemories: pendingMemories ?? this.pendingMemories,
        reputationScore: reputationScore ?? this.reputationScore,
        pendingRankUp: clearPendingRankUp
            ? null
            : (pendingRankUp ?? this.pendingRankUp),
        pendingAchievements: pendingAchievements ?? this.pendingAchievements,
        pendingStoryChapterDay: clearPendingStoryChapter
            ? null
            : (pendingStoryChapterDay ?? this.pendingStoryChapterDay),
        pendingReputationBoard:
            pendingReputationBoard ?? this.pendingReputationBoard,
        windowsillPlots: windowsillPlots ?? this.windowsillPlots,
        pendingDeliveries: pendingDeliveries ?? this.pendingDeliveries,
        loginStreak: loginStreak ?? this.loginStreak,
        lastLoginDateMs: lastLoginDateMs ?? this.lastLoginDateMs,
        vibeDiscoveries: vibeDiscoveries ?? this.vibeDiscoveries,
        activeBigOrder: clearActiveBigOrder
            ? null
            : (activeBigOrder ?? this.activeBigOrder),
        wholesalePending: wholesalePending ?? this.wholesalePending,
        pendingSeasonalBanner:
            pendingSeasonalBanner ?? this.pendingSeasonalBanner,
        purchasedDecor: purchasedDecor ?? this.purchasedDecor,
        activeDecor: activeDecor ?? this.activeDecor,
        bouquetPresets: bouquetPresets ?? this.bouquetPresets,
        bestDayEarnings: bestDayEarnings ?? this.bestDayEarnings,
        allTimeFlowerUse: allTimeFlowerUse ?? this.allTimeFlowerUse,
        levelStars: levelStars ?? this.levelStars,
      );
}
