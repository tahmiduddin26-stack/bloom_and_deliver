/// 20-level campaign definitions.
///
/// Each level corresponds 1:1 to an in-game day (level N plays day N).
/// Complete the orders and meet the first coin goal to unlock the next stage.
/// Missed goals can be retried without a lives or energy cost.
library;

import 'order_data.dart';

class LevelDef {
  /// Service target tightens across the campaign; festival stages push harder.
  bool get isRush => number >= 5 && number % 5 == 0;
  int get serviceSeconds => (55 - number * 2 - (isRush ? 5 : 0)).clamp(16, 55);
  String get paceLabel => isRush
      ? 'Festival rush'
      : number < 4
      ? 'Warm up'
      : 'Quick service';
  final int number;
  final String title;
  final String subtitle;
  final String emoji;

  /// Earnings needed for 2 and 3 stars (1 star = just finish the day).
  final int star2Earnings;
  final int star3Earnings;
  int get star1Earnings => (star2Earnings * 0.7).round();

  /// Short description of what this level introduces or unlocks.
  final String unlockText;

  const LevelDef({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.star2Earnings,
    required this.star3Earnings,
    required this.unlockText,
  });

  /// Stars for a completed day given its total order earnings.
  int starsFor(int earnings) {
    if (earnings >= star3Earnings) return 3;
    if (earnings >= star2Earnings) return 2;
    if (earnings >= star1Earnings) return 1;
    return 0;
  }
}

/// The 20 campaign levels. Order counts and payouts follow
/// `generateDayOrders`: 3 orders on day 1 growing to 8 by day 6, 10 from day 15.
const List<LevelDef> _levelThemes = [
  LevelDef(
    number: 1,
    title: 'Grand Opening',
    subtitle: 'Your first customers arrive',
    emoji: '🎀',
    star2Earnings: 100,
    star3Earnings: 160,
    unlockText: 'Learn the basics: drag, match vibes, submit!',
  ),
  LevelDef(
    number: 2,
    title: 'Word Gets Around',
    subtitle: 'A few more faces at the door',
    emoji: '🌷',
    star2Earnings: 135,
    star3Earnings: 210,
    unlockText: 'Restock at the market between days.',
  ),
  LevelDef(
    number: 3,
    title: 'Fresh Deliveries',
    subtitle: 'New flowers hit the market',
    emoji: '🌸',
    star2Earnings: 215,
    star3Earnings: 335,
    unlockText: 'Unlocks Tier 2 flowers: Orchid, Gerbera, Snapdragon…',
  ),
  LevelDef(
    number: 4,
    title: 'The Mystery Note',
    subtitle: 'A strange request appears',
    emoji: '🎭',
    star2Earnings: 260,
    star3Earnings: 405,
    unlockText: 'First mystery order — creativity pays!',
  ),
  LevelDef(
    number: 5,
    title: 'Regulars & Friends',
    subtitle: 'Loyal customers remember you',
    emoji: '💕',
    star2Earnings: 300,
    star3Earnings: 470,
    unlockText: 'Friendship hearts grow with every good bouquet.',
  ),
  LevelDef(
    number: 6,
    title: 'Busy Morning',
    subtitle: 'Eight orders, one florist',
    emoji: '☀️',
    star2Earnings: 345,
    star3Earnings: 535,
    unlockText: 'Unlocks Tier 3 flowers: Peony, Ranunculus, Wisteria…',
  ),
  LevelDef(
    number: 7,
    title: 'Greens & Grace',
    subtitle: 'A touch of eucalyptus goes far',
    emoji: '🌿',
    star2Earnings: 345,
    star3Earnings: 535,
    unlockText: 'Filler greens add a bonus to every bouquet.',
  ),
  LevelDef(
    number: 8,
    title: 'Rival in Town',
    subtitle: 'Petal & Co. opens across the street',
    emoji: '🏪',
    star2Earnings: 440,
    star3Earnings: 690,
    unlockText: 'Late-tier orders begin — bigger, fancier requests.',
  ),
  LevelDef(
    number: 9,
    title: 'Steady Blooms',
    subtitle: 'The shop hits its stride',
    emoji: '🌼',
    star2Earnings: 440,
    star3Earnings: 690,
    unlockText: 'Loyal regulars tip more — keep their bouquets beautiful.',
  ),
  LevelDef(
    number: 10,
    title: 'Rare Beauty',
    subtitle: 'The exotic protea arrives',
    emoji: '👑',
    star2Earnings: 440,
    star3Earnings: 690,
    unlockText: 'Unlocks the Protea — the rarest bloom in the shop.',
  ),
  LevelDef(
    number: 11,
    title: 'Bolder Bouquets',
    subtitle: 'The requests grow fancier',
    emoji: '💐',
    star2Earnings: 440,
    star3Earnings: 690,
    unlockText: 'Bigger orders ask for more vibes — read every hint closely.',
  ),
  LevelDef(
    number: 12,
    title: 'Mystery Season',
    subtitle: 'The masked patron returns',
    emoji: '🎭',
    star2Earnings: 440,
    star3Earnings: 690,
    unlockText: 'Mystery orders now visit more often.',
  ),
  LevelDef(
    number: 13,
    title: 'Shop Makeover',
    subtitle: 'Deck out your space',
    emoji: '🎨',
    star2Earnings: 440,
    star3Earnings: 690,
    unlockText: 'Spend coins on wallpaper, lights, and decor.',
  ),
  LevelDef(
    number: 14,
    title: "Valentine's Week",
    subtitle: 'Love is in the air',
    emoji: '💝',
    star2Earnings: 440,
    star3Earnings: 690,
    unlockText:
        "Valentine's Week begins — a special bloom appears in the market.",
  ),
  LevelDef(
    number: 15,
    title: 'Full Bloom',
    subtitle: 'Ten orders a day now!',
    emoji: '💐',
    star2Earnings: 620,
    star3Earnings: 965,
    unlockText: 'Premium landmark orders unlock — the fanciest requests.',
  ),
  LevelDef(
    number: 16,
    title: 'Peak Season',
    subtitle: 'Your busiest days yet',
    emoji: '🌟',
    star2Earnings: 620,
    star3Earnings: 965,
    unlockText: 'Keep your stock deep and aim for Great on every order.',
  ),
  LevelDef(
    number: 17,
    title: 'Festival Eve',
    subtitle: 'The town prepares to celebrate',
    emoji: '🏮',
    star2Earnings: 620,
    star3Earnings: 965,
    unlockText: 'Seasonal events bring exclusive flowers.',
  ),
  LevelDef(
    number: 18,
    title: 'Master Class',
    subtitle: 'Only your best work will do',
    emoji: '✨',
    star2Earnings: 620,
    star3Earnings: 965,
    unlockText: 'Aim for Great on every order.',
  ),
  LevelDef(
    number: 19,
    title: 'The Final Push',
    subtitle: 'Petal & Co. makes its move',
    emoji: '⚔️',
    star2Earnings: 620,
    star3Earnings: 965,
    unlockText: 'Show the town who the real florist is.',
  ),
  LevelDef(
    number: 20,
    title: 'Bloom Legend',
    subtitle: 'The best flower shop in town',
    emoji: '🏆',
    star2Earnings: 620,
    star3Earnings: 965,
    unlockText: 'Finish the campaign — endless mode awaits!',
  ),
];

/// Total number of campaign levels.
const int maxCampaignLevel = 20;

/// Goals follow the actual deterministic orders, including mystery payouts.
/// This avoids impossible three-star goals on low-paying random selections.
LevelDef _balancedLevel(LevelDef theme) {
  final orders = generateDayOrders(theme.number);
  final greatBase = orders.fold<double>(
    0,
    (total, order) =>
        total +
        order.basePayment *
            (order.isMystery ? 2.5 : 1.3 * order.customer.loyaltyMultiplier),
  );
  return LevelDef(
    number: theme.number,
    title: theme.title,
    subtitle: theme.subtitle,
    emoji: theme.emoji,
    star2Earnings: (greatBase * 0.8).round(),
    star3Earnings:
        (greatBase *
                (theme.number < 4
                    ? 1.0
                    : (1.18 + theme.number * 0.008).clamp(1.18, 1.34)))
            .round(),
    unlockText:
        '${theme.unlockText}\n${theme.paceLabel}: ${theme.serviceSeconds}s for a quick-service tip. Chain Great bouquets for more coins.',
  );
}

final List<LevelDef> allLevels = List.unmodifiable(
  _levelThemes.map(_balancedLevel),
);

/// Look up a level definition (1-based). Days beyond 20 return an
/// auto-generated endless-mode definition.
LevelDef levelForDay(int day) {
  if (day >= 1 && day <= allLevels.length) return allLevels[day - 1];
  return _balancedLevel(
    LevelDef(
      number: day,
      title: 'Endless Bloom $day',
      subtitle: 'Free play — day $day',
      emoji: '🌼',
      star2Earnings: 620 + (day - 20) * 12,
      star3Earnings: 740 + (day - 20) * 16,
      unlockText: 'Keep the shop blooming!',
    ),
  );
}
