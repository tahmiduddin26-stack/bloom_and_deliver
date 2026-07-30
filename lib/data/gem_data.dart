/// Gem packs — the premium currency catalogue.
///
/// Gems are bought with real money and spent only on optional time-savers.
/// They are deliberately **never earned from play**, so the coin economy (order
/// payments, flower costs, star goals) stays exactly as balanced for a player
/// who never spends a penny.
class GemPack {
  /// Store product identifier. Must match the SKU configured in Google Play
  /// Console / App Store Connect before purchases can work.
  final String productId;

  final String name;
  final String emoji;
  final int gems;

  /// Extra gems on top of [gems] for the larger packs (marketing value only).
  final int bonusGems;

  /// Display-only fallback price. The real, localised price comes from the
  /// store when a live [IapService] is wired — never charge from this string.
  final String fallbackPrice;

  const GemPack({
    required this.productId,
    required this.name,
    required this.emoji,
    required this.gems,
    required this.fallbackPrice,
    this.bonusGems = 0,
  });

  int get totalGems => gems + bonusGems;
}

const List<GemPack> gemPacks = [
  GemPack(
    productId: 'gems_handful',
    name: 'Handful of Gems',
    emoji: '💎',
    gems: 50,
    fallbackPrice: '\$0.99',
  ),
  GemPack(
    productId: 'gems_pouch',
    name: 'Pouch of Gems',
    emoji: '👛',
    gems: 150,
    bonusGems: 20,
    fallbackPrice: '\$2.99',
  ),
  GemPack(
    productId: 'gems_basket',
    name: 'Basket of Gems',
    emoji: '🧺',
    gems: 400,
    bonusGems: 80,
    fallbackPrice: '\$6.99',
  ),
  GemPack(
    productId: 'gems_greenhouse',
    name: 'Greenhouse Hoard',
    emoji: '🏡',
    gems: 1000,
    bonusGems: 300,
    fallbackPrice: '\$14.99',
  ),
];

// ── Gem sinks — what gems actually buy ──────────────────────────────────────
//
// Every sink saves the player *time*, never raw coins: gems must not become a
// way to buy score. Prices live here so they are tuned in one place.

/// Instantly top every unlocked flower up to a full shelf, skipping the
/// earn-then-shop loop for a day.
const int kGemCostInstantRestock = 30;

/// Reset the freshness clock on all stock, so nothing wilts tonight.
const int kGemCostFreshWater = 15;

/// Swap today's three challenges for a new set.
const int kGemCostRerollChallenges = 10;

/// One-off gems handed out when the tutorial completes, so the player learns
/// what gems do by spending real ones before ever seeing a price tag.
const int kTutorialGemGift = 25;
