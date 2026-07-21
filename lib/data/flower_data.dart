import '../models/flower.dart';
import '../theme/app_theme.dart';
import 'seasonal_events_data.dart';

// ── Unlock tiers ─────────────────────────────────────────────────────────────
// Day 1  → Tier 1: core starter set
// Day 3  → Tier 2: mid-range / specialty
// Day 6  → Tier 3: premium bouquet flowers
// Day 10 → Tier 4: exotic / luxury

final List<Flower> allFlowers = [
  // ── Tier 1 — Day 1 ──────────────────────────────────────────────────────
  Flower(
    id: 'rose',
    name: 'Rose',
    emoji: '🌹',
    color: AppColors.roseRed,
    vibes: [VibeTag.romantic, VibeTag.elegant, VibeTag.traditional],
    cost: 8,
    wiltsAfterDays: 4,
    unlockDay: 1,
  ),
  Flower(
    id: 'daisy',
    name: 'Daisy',
    emoji: '🌼',
    color: AppColors.daisyYellow,
    vibes: [VibeTag.cheerful, VibeTag.fresh],
    cost: 3,
    wiltsAfterDays: 3,
    unlockDay: 1,
    seedPrice: 2,
    growthMinutes: 30,
  ),
  Flower(
    id: 'lily',
    name: 'Lily',
    emoji: '🌸',
    color: AppColors.lilyWhite,
    vibes: [VibeTag.sympathy, VibeTag.elegant, VibeTag.delicate, VibeTag.traditional],
    cost: 6,
    wiltsAfterDays: 3,
    unlockDay: 1,
  ),
  Flower(
    id: 'sunflower',
    name: 'Sunflower',
    emoji: '🌻',
    color: AppColors.sunflowerGold,
    vibes: [VibeTag.cheerful, VibeTag.vibrant, VibeTag.wild],
    cost: 5,
    wiltsAfterDays: 5,
    unlockDay: 1,
    seedPrice: 3,
    growthMinutes: 30,
  ),
  Flower(
    id: 'lavender',
    name: 'Lavender',
    emoji: '💜',
    color: AppColors.lavenderPurple,
    vibes: [VibeTag.cozy, VibeTag.fresh, VibeTag.delicate, VibeTag.soft],
    cost: 4,
    wiltsAfterDays: 6,
    unlockDay: 1,
    seedPrice: 2,
    growthMinutes: 40,
  ),
  Flower(
    id: 'tulip',
    name: 'Tulip',
    emoji: '🌷',
    color: AppColors.tulipPink,
    vibes: [VibeTag.romantic, VibeTag.fresh, VibeTag.vibrant],
    cost: 5,
    wiltsAfterDays: 3,
    unlockDay: 1,
  ),
  Flower(
    id: 'carnation',
    name: 'Carnation',
    emoji: '🌺',
    color: AppColors.carnationCoral,
    vibes: [VibeTag.sympathy, VibeTag.cozy, VibeTag.traditional],
    cost: 4,
    wiltsAfterDays: 5,
    unlockDay: 1,
  ),
  Flower(
    id: 'wildflower',
    name: 'Wildflower',
    emoji: '💐',
    color: AppColors.wildflowerBlue,
    vibes: [VibeTag.wild, VibeTag.cheerful, VibeTag.fresh],
    cost: 3,
    wiltsAfterDays: 2,
    unlockDay: 1,
    seedPrice: 2,
    growthMinutes: 30,
  ),
  Flower(
    id: 'babys_breath',
    name: "Baby's Breath",
    emoji: '🤍',
    color: AppColors.babysBreathWhite,
    vibes: [VibeTag.delicate, VibeTag.fresh, VibeTag.romantic, VibeTag.soft],
    cost: 2,
    wiltsAfterDays: 4,
    unlockDay: 1,
    isFiller: true,
  ),
  Flower(
    id: 'marigold',
    name: 'Marigold',
    emoji: '🟡',
    color: AppColors.marigoldOrange,
    vibes: [VibeTag.cheerful, VibeTag.bold, VibeTag.festive],
    cost: 3,
    wiltsAfterDays: 5,
    unlockDay: 1,
    seedPrice: 2,
    growthMinutes: 30,
  ),
  Flower(
    id: 'zinnia',
    name: 'Zinnia',
    emoji: '🧡',
    color: AppColors.zinniaOrange,
    vibes: [VibeTag.vibrant, VibeTag.bold, VibeTag.cheerful],
    cost: 4,
    wiltsAfterDays: 5,
    unlockDay: 1,
  ),
  Flower(
    id: 'eucalyptus',
    name: 'Eucalyptus',
    emoji: '🌿',
    color: AppColors.eucalyptusGreen,
    vibes: [VibeTag.fresh, VibeTag.natural],
    cost: 3,
    wiltsAfterDays: 8,
    unlockDay: 1,
    isFiller: true,
  ),
  Flower(
    id: 'fern',
    name: 'Fern',
    emoji: '🌾',
    color: AppColors.fernGreen,
    vibes: [VibeTag.natural, VibeTag.wild],
    cost: 2,
    wiltsAfterDays: 7,
    unlockDay: 1,
    isFiller: true,
  ),
  Flower(
    id: 'freesia',
    name: 'Freesia',
    emoji: '🍋',
    color: AppColors.freesiaYellow,
    vibes: [VibeTag.fresh, VibeTag.delicate, VibeTag.cozy],
    cost: 6,
    wiltsAfterDays: 4,
    unlockDay: 1,
  ),

  // ── Tier 2 — Day 3 ──────────────────────────────────────────────────────
  Flower(
    id: 'orchid',
    name: 'Orchid',
    emoji: '🪷',
    color: AppColors.orchidDeep,
    vibes: [VibeTag.elegant, VibeTag.mystical, VibeTag.delicate],
    cost: 12,
    wiltsAfterDays: 7,
    unlockDay: 3,
  ),
  Flower(
    id: 'gerbera_daisy',
    name: 'Gerbera',
    emoji: '🌼',
    color: AppColors.gerberaOrange,
    vibes: [VibeTag.cheerful, VibeTag.vibrant, VibeTag.bold],
    cost: 6,
    wiltsAfterDays: 4,
    unlockDay: 3,
  ),
  Flower(
    id: 'snapdragon',
    name: 'Snapdragon',
    emoji: '🫧',
    color: AppColors.snapdragonViolet,
    vibes: [VibeTag.wild, VibeTag.bold, VibeTag.vibrant],
    cost: 5,
    wiltsAfterDays: 3,
    unlockDay: 3,
  ),
  Flower(
    id: 'cosmos',
    name: 'Cosmos',
    emoji: '✿',
    color: AppColors.cosmosPink,
    vibes: [VibeTag.wild, VibeTag.cheerful, VibeTag.delicate],
    cost: 4,
    wiltsAfterDays: 3,
    unlockDay: 3,
  ),
  Flower(
    id: 'hyacinth',
    name: 'Hyacinth',
    emoji: '💙',
    color: AppColors.hyacinthBlue,
    vibes: [VibeTag.fresh, VibeTag.elegant, VibeTag.cozy],
    cost: 7,
    wiltsAfterDays: 4,
    unlockDay: 3,
  ),
  Flower(
    id: 'chrysanthemum',
    name: 'Chrysanthemum',
    emoji: '🌸',
    color: AppColors.chrysanthemumCream,
    vibes: [VibeTag.sympathy, VibeTag.festive, VibeTag.rustic],
    cost: 5,
    wiltsAfterDays: 6,
    eventId: 'harvest',
  ),
  Flower(
    id: 'statice',
    name: 'Statice',
    emoji: '💠',
    color: AppColors.staticeBlue,
    vibes: [VibeTag.elegant, VibeTag.delicate],
    cost: 2,
    wiltsAfterDays: 14,
    unlockDay: 3,
    isFiller: true,
  ),
  Flower(
    id: 'sweet_pea',
    name: 'Sweet Pea',
    emoji: '🩷',
    color: AppColors.sweetPeaPink,
    vibes: [VibeTag.delicate, VibeTag.soft, VibeTag.romantic],
    cost: 5,
    wiltsAfterDays: 2,
    eventId: 'mothers_day',
  ),

  // ── Tier 3 — Day 6 ──────────────────────────────────────────────────────
  Flower(
    id: 'peony',
    name: 'Peony',
    emoji: '🌸',
    color: AppColors.peonPink,
    vibes: [VibeTag.romantic, VibeTag.luxurious, VibeTag.elegant],
    cost: 14,
    wiltsAfterDays: 4,
    unlockDay: 6,
    seedPrice: 6,
    growthMinutes: 75,
  ),
  Flower(
    id: 'ranunculus',
    name: 'Ranunculus',
    emoji: '🌺',
    color: AppColors.ranunculusOrange,
    vibes: [VibeTag.romantic, VibeTag.delicate, VibeTag.vibrant],
    cost: 9,
    wiltsAfterDays: 3,
    unlockDay: 6,
    seedPrice: 5,
    growthMinutes: 60,
  ),
  Flower(
    id: 'lisianthus',
    name: 'Lisianthus',
    emoji: '🪻',
    color: AppColors.lisianthusLavender,
    vibes: [VibeTag.elegant, VibeTag.delicate, VibeTag.mystical],
    cost: 10,
    wiltsAfterDays: 5,
    unlockDay: 6,
  ),
  Flower(
    id: 'thistle',
    name: 'Thistle',
    emoji: '🍀',
    color: AppColors.thistlePurple,
    vibes: [VibeTag.bold, VibeTag.wild, VibeTag.rustic],
    cost: 4,
    wiltsAfterDays: 6,
    unlockDay: 6,
  ),
  Flower(
    id: 'berry_branch',
    name: 'Berry Branch',
    emoji: '🫐',
    color: AppColors.berryDeep,
    vibes: [VibeTag.festive, VibeTag.bold, VibeTag.wild],
    cost: 4,
    wiltsAfterDays: 5,
    unlockDay: 6,
  ),
  Flower(
    id: 'wisteria',
    name: 'Wisteria',
    emoji: '🪻',
    color: AppColors.wisteriaDeep,
    vibes: [VibeTag.mystical, VibeTag.romantic, VibeTag.delicate],
    cost: 12,
    wiltsAfterDays: 3,
    unlockDay: 6,
  ),
  Flower(
    id: 'anemone',
    name: 'Anemone',
    emoji: '🌑',
    color: AppColors.anemoneDeep,
    vibes: [VibeTag.mystical, VibeTag.bold, VibeTag.wild],
    cost: 7,
    wiltsAfterDays: 3,
    unlockDay: 6,
  ),

  // ── Tier 4 — Day 10 ─────────────────────────────────────────────────────
  Flower(
    id: 'protea',
    name: 'Protea',
    emoji: '🌿',
    color: AppColors.proteaRust,
    vibes: [VibeTag.bold, VibeTag.wild, VibeTag.exotic],
    cost: 15,
    wiltsAfterDays: 7,
    unlockDay: 10,
  ),

  // ── Seasonal exclusives — only appear during their event ─────────────────
  Flower(
    id: 'gardenia',
    name: 'Gardenia',
    emoji: '🤍',
    color: AppColors.gardeniaBlush,
    vibes: [VibeTag.romantic, VibeTag.luxurious, VibeTag.delicate],
    cost: 10,
    wiltsAfterDays: 2,
    eventId: 'valentines',
  ),
  Flower(
    id: 'amaryllis',
    name: 'Amaryllis',
    emoji: '🌹',
    color: AppColors.amaryllisCrimson,
    vibes: [VibeTag.elegant, VibeTag.bold, VibeTag.festive],
    cost: 12,
    wiltsAfterDays: 5,
    eventId: 'winter_blooms',
  ),
];

// Keep the old name as an alias so existing code still compiles.
final List<Flower> starterFlowers = allFlowers;

final Map<String, Flower> flowerById = {
  for (final f in allFlowers) f.id: f,
};

/// Returns flowers available in the shop for the given day.
/// Event-exclusive flowers (eventId != null) are only shown during their event.
/// All other flowers unlock when day >= unlockDay.
List<Flower> unlockedFlowers(int day) {
  final activeEvent = eventForDay(day);
  return allFlowers.where((f) {
    if (f.eventId != null) {
      return f.eventId == activeEvent?.id;
    }
    return f.unlockDay <= day;
  }).toList();
}

/// Returns the event-exclusive flower for the active event on [day], if any.
Flower? limitedFlowerForDay(int day) {
  final event = eventForDay(day);
  if (event?.limitedFlowerId == null) return null;
  return flowerById[event!.limitedFlowerId];
}

/// Tiny day-1 starter inventory — players must restock to grow stock.
Map<String, int> get defaultInventory => {
      'rose': 3,
      'daisy': 5,
      'lily': 3,
      'sunflower': 3,
      'lavender': 4,
      'tulip': 3,
      'carnation': 4,
      'wildflower': 4,
      'babys_breath': 5,
      'marigold': 4,
      'zinnia': 3,
      'eucalyptus': 5,
      'fern': 5,
      'freesia': 3,
    };

/// Tracks the day each flower in defaultInventory was "added".
/// Used to initialise inventoryDayAdded on day 1.
Map<String, int> get defaultInventoryDayAdded => {
      for (final id in defaultInventory.keys) id: 1,
    };
