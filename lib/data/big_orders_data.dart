import '../models/big_order.dart';
import '../models/flower.dart';

// ── Pool of big commissions ───────────────────────────────────────────────────

const List<BigOrder> _bigOrderPool = [
  BigOrder(
    id: 'wedding_arbour',
    name: 'The Harrington Wedding',
    emoji: '💒',
    description: 'An intimate garden ceremony needs three matching archway pieces.',
    dayStories: [
      'Sophie Harrington stops by the shop, a little teary-eyed. "I just want it to feel like a garden come to life," she sighs.',
      'Her mum calls ahead to check progress. "Sophie keeps looking at her ring and smiling — please make it special."',
      "Wedding day. You drop off the final piece and spot Sophie through the florist's van window, beaming.",
    ],
    requiredVibes: [VibeTag.romantic, VibeTag.delicate, VibeTag.elegant],
    availableFromDay: 7,
    minFlowers: 5,
    maxFlowers: 9,
    dailyReward: 35,
    completionBonus: 50,
  ),
  BigOrder(
    id: 'gallery_opening',
    name: 'Meridian Gallery Opening',
    emoji: '🎨',
    description: 'Three striking arrangements to frame a contemporary art exhibition.',
    dayStories: [
      'Curator Yve Park emails a mood board — bold shapes, unusual textures. "Flowers that feel like art themselves."',
      'She visits mid-afternoon with press preview notes. "Clients love the drama. One more day — can you push it further?"',
      'Opening night. A journalist photographs your arrangement alongside the centrepiece painting.',
    ],
    requiredVibes: [VibeTag.bold, VibeTag.exotic, VibeTag.vibrant],
    availableFromDay: 10,
    minFlowers: 4,
    maxFlowers: 8,
    dailyReward: 30,
    completionBonus: 45,
  ),
  BigOrder(
    id: 'hotel_lobby',
    name: 'Grand Ellery Hotel',
    emoji: '🏨',
    description: 'Lobby centrepieces refreshed over three days for a luxury hotel launch.',
    dayStories: [
      'The event manager, Mr. Voss, arrives in a crisp suit. "Our guests expect the extraordinary. Can you deliver?"',
      'Day two review: guests have been photographing the arrangements. Mr. Voss looks almost pleased.',
      'Final install. A hotel guest stops you and says: "I came back just to look at these again."',
    ],
    requiredVibes: [VibeTag.elegant, VibeTag.luxurious, VibeTag.fresh],
    availableFromDay: 14,
    minFlowers: 5,
    maxFlowers: 10,
    dailyReward: 40,
    completionBonus: 60,
  ),
  BigOrder(
    id: 'harvest_feast',
    name: 'Harvest Moon Dinner',
    emoji: '🍂',
    description: 'A rustic long-table feast for 40 needs warm centrepieces each evening.',
    dayStories: [
      'Organiser Priya Nair wants "the feeling of an overgrown autumn meadow — cosy, not fussy."',
      'The first dinner was a hit. "Guests kept touching the flowers," she texts. "More texture on day two please."',
      'Final evening. The guests toast to "the florist who captured October in a jar."',
    ],
    requiredVibes: [VibeTag.rustic, VibeTag.cozy, VibeTag.festive],
    availableFromDay: 42, // aligns with Harvest Festival event
    minFlowers: 4,
    maxFlowers: 8,
    dailyReward: 32,
    completionBonus: 40,
  ),
  BigOrder(
    id: 'winter_gala',
    name: 'Frostlight Charity Gala',
    emoji: '❄️',
    description: 'An elegant winter fundraiser needs arrangements that feel like frozen magic.',
    dayStories: [
      'Lady Ashford-Wen explains the brief: "Pure white and silver. Something that makes people feel they\'ve stepped into a snow globe."',
      'Midway review. A committee member calls it "breathtaking." Lady Ashford-Wen simply nods.',
      'Gala night. The event raises record funds. Your name appears in the programme.',
    ],
    requiredVibes: [VibeTag.elegant, VibeTag.festive, VibeTag.delicate],
    availableFromDay: 56, // aligns with Winter Blooms event
    minFlowers: 5,
    maxFlowers: 9,
    dailyReward: 38,
    completionBonus: 55,
  ),
];

// ── Generator ─────────────────────────────────────────────────────────────────

/// Returns the big order that should be offered starting on [day], if any.
///
/// A new commission unlocks every ~14 days.  The exact commission chosen
/// cycles through the pool in order of [availableFromDay].  Returns null
/// on days that don't start a new commission window.
BigOrder? bigOrderForDay(int day) {
  // Commission windows start on days 7, 21, 35, 49, 63, …
  // i.e. day 7 + multiples of 14.
  if (day < 7) return null;
  final offset = day - 7;
  if (offset % 14 != 0) return null;

  // Pick from the pool — sort by availableFromDay, then cycle.
  final eligible = [..._bigOrderPool]
    ..sort((a, b) => a.availableFromDay.compareTo(b.availableFromDay));

  final index = (offset ~/ 14) % eligible.length;
  return eligible[index];
}

/// Look up a big order template by id.
BigOrder? bigOrderById(String id) {
  try {
    return _bigOrderPool.firstWhere((o) => o.id == id);
  } catch (_) {
    return null;
  }
}
