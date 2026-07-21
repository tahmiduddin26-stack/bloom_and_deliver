/// 20-level campaign definitions.
///
/// Each level corresponds 1:1 to an in-game day (level N plays day N).
/// Completing a level (serving all its orders) always awards at least 1 star —
/// the game stays cozy, there is no fail state. Higher day earnings award
/// 2 or 3 stars, and any unlocked level can be replayed for a better score.
library;

class LevelDef {
  final int number;
  final String title;
  final String subtitle;
  final String emoji;

  /// Earnings needed for 2 and 3 stars (1 star = just finish the day).
  final int star2Earnings;
  final int star3Earnings;

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
    return 1;
  }
}

/// The 20 campaign levels. Order counts and payouts follow
/// `generateDayOrders`: 3 orders on day 1 growing to 8 by day 6, 10 from day 15.
const List<LevelDef> allLevels = [
  LevelDef(
    number: 1,
    title: 'Grand Opening',
    subtitle: 'Your first customers arrive',
    emoji: '🎀',
    star2Earnings: 100,
    star3Earnings: 120,
    unlockText: 'Learn the basics: drag, match vibes, submit!',
  ),
  LevelDef(
    number: 2,
    title: 'Word Gets Around',
    subtitle: 'A few more faces at the door',
    emoji: '🌷',
    star2Earnings: 135,
    star3Earnings: 160,
    unlockText: 'Restock at the market between days.',
  ),
  LevelDef(
    number: 3,
    title: 'Fresh Deliveries',
    subtitle: 'New flowers hit the market',
    emoji: '🌸',
    star2Earnings: 215,
    star3Earnings: 255,
    unlockText: 'Unlocks Tier 2 flowers: Orchid, Gerbera, Snapdragon…',
  ),
  LevelDef(
    number: 4,
    title: 'The Mystery Note',
    subtitle: 'A strange request appears',
    emoji: '🎭',
    star2Earnings: 260,
    star3Earnings: 310,
    unlockText: 'First mystery order — creativity pays!',
  ),
  LevelDef(
    number: 5,
    title: 'Regulars & Friends',
    subtitle: 'Loyal customers remember you',
    emoji: '💕',
    star2Earnings: 300,
    star3Earnings: 360,
    unlockText: 'Friendship hearts grow with every good bouquet.',
  ),
  LevelDef(
    number: 6,
    title: 'Busy Morning',
    subtitle: 'Eight orders, one florist',
    emoji: '☀️',
    star2Earnings: 345,
    star3Earnings: 410,
    unlockText: 'Unlocks Tier 3 flowers: Peony, Ranunculus, Wisteria…',
  ),
  LevelDef(
    number: 7,
    title: 'Greens & Grace',
    subtitle: 'A touch of eucalyptus goes far',
    emoji: '🌿',
    star2Earnings: 345,
    star3Earnings: 410,
    unlockText: 'Filler greens add a bonus to every bouquet.',
  ),
  LevelDef(
    number: 8,
    title: 'Rival in Town',
    subtitle: 'Petal & Co. opens across the street',
    emoji: '🏪',
    star2Earnings: 440,
    star3Earnings: 530,
    unlockText: 'Late-tier orders begin — bigger, fancier requests.',
  ),
  LevelDef(
    number: 9,
    title: 'Steady Blooms',
    subtitle: 'The shop hits its stride',
    emoji: '🌼',
    star2Earnings: 440,
    star3Earnings: 530,
    unlockText: 'Loyal regulars tip more — keep their bouquets beautiful.',
  ),
  LevelDef(
    number: 10,
    title: 'Rare Beauty',
    subtitle: 'The exotic protea arrives',
    emoji: '👑',
    star2Earnings: 440,
    star3Earnings: 530,
    unlockText: 'Unlocks the Protea — the rarest bloom in the shop.',
  ),
  LevelDef(
    number: 11,
    title: 'Bolder Bouquets',
    subtitle: 'The requests grow fancier',
    emoji: '💐',
    star2Earnings: 440,
    star3Earnings: 530,
    unlockText: 'Bigger orders ask for more vibes — read every hint closely.',
  ),
  LevelDef(
    number: 12,
    title: 'Mystery Season',
    subtitle: 'The masked patron returns',
    emoji: '🎭',
    star2Earnings: 440,
    star3Earnings: 530,
    unlockText: 'Mystery orders now visit more often.',
  ),
  LevelDef(
    number: 13,
    title: 'Shop Makeover',
    subtitle: 'Deck out your space',
    emoji: '🎨',
    star2Earnings: 440,
    star3Earnings: 530,
    unlockText: 'Spend coins on wallpaper, lights, and decor.',
  ),
  LevelDef(
    number: 14,
    title: "Valentine's Week",
    subtitle: 'Love is in the air',
    emoji: '💝',
    star2Earnings: 440,
    star3Earnings: 530,
    unlockText: "Valentine's Week begins — a special bloom appears in the market.",
  ),
  LevelDef(
    number: 15,
    title: 'Full Bloom',
    subtitle: 'Ten orders a day now!',
    emoji: '💐',
    star2Earnings: 620,
    star3Earnings: 740,
    unlockText: 'Premium landmark orders unlock — the fanciest requests.',
  ),
  LevelDef(
    number: 16,
    title: 'Peak Season',
    subtitle: 'Your busiest days yet',
    emoji: '🌟',
    star2Earnings: 620,
    star3Earnings: 740,
    unlockText: 'Keep your stock deep and aim for Great on every order.',
  ),
  LevelDef(
    number: 17,
    title: 'Festival Eve',
    subtitle: 'The town prepares to celebrate',
    emoji: '🏮',
    star2Earnings: 620,
    star3Earnings: 740,
    unlockText: 'Seasonal events bring exclusive flowers.',
  ),
  LevelDef(
    number: 18,
    title: 'Master Class',
    subtitle: 'Only your best work will do',
    emoji: '✨',
    star2Earnings: 620,
    star3Earnings: 740,
    unlockText: 'Aim for Great on every order.',
  ),
  LevelDef(
    number: 19,
    title: 'The Final Push',
    subtitle: 'Petal & Co. makes its move',
    emoji: '⚔️',
    star2Earnings: 620,
    star3Earnings: 740,
    unlockText: 'Show the town who the real florist is.',
  ),
  LevelDef(
    number: 20,
    title: 'Bloom Legend',
    subtitle: 'The best flower shop in town',
    emoji: '🏆',
    star2Earnings: 620,
    star3Earnings: 740,
    unlockText: 'Finish the campaign — endless mode awaits!',
  ),
];

/// Total number of campaign levels.
const int maxCampaignLevel = 20;

/// Look up a level definition (1-based). Days beyond 20 return an
/// auto-generated endless-mode definition.
LevelDef levelForDay(int day) {
  if (day >= 1 && day <= allLevels.length) return allLevels[day - 1];
  return LevelDef(
    number: day,
    title: 'Endless Bloom $day',
    subtitle: 'Free play — day $day',
    emoji: '🌼',
    star2Earnings: 620 + (day - 20) * 12,
    star3Earnings: 740 + (day - 20) * 16,
    unlockText: 'Keep the shop blooming!',
  );
}
