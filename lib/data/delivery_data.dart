import 'dart:math';

import '../models/delivery_mission.dart';
import '../models/flower.dart';

// ── Mission pool ──────────────────────────────────────────────────────────────

const List<DeliveryMission> _allMissions = [
  DeliveryMission(
    id: 'hospital_cheer',
    location: "St. Mary's Hospital",
    emoji: '🏥',
    description: 'A patient in Ward 3 is feeling down. Cheer them up!',
    hint: '"Something bright and hopeful — they need a reason to smile today 💛"',
    requiredVibes: [VibeTag.cheerful, VibeTag.fresh],
    minFlowers: 3,
    maxFlowers: 5,
    reward: 18,
    storySnippet:
        'The nurse says the patient lit up when the flowers arrived. Sometimes a bouquet really is the best medicine.',
  ),
  DeliveryMission(
    id: 'hospital_sympathy',
    location: "St. Mary's Hospital",
    emoji: '🏥',
    description: "A family waiting in the corridor could use some comfort.",
    hint: '"Something gentle — we\'re just trying to get through the day 🤍"',
    requiredVibes: [VibeTag.sympathy, VibeTag.delicate],
    minFlowers: 3,
    maxFlowers: 6,
    reward: 20,
    storySnippet:
        'You left them quietly on the waiting room table. By the time you got to the lift, someone had already picked them up.',
  ),
  DeliveryMission(
    id: 'wedding_romantic',
    location: 'Rosewood Wedding Venue',
    emoji: '💒',
    description: 'Table centrepieces for an evening reception.',
    hint: '"Romantic and elegant — it\'s our big day and everything has to be perfect 🌹"',
    requiredVibes: [VibeTag.romantic, VibeTag.elegant],
    minFlowers: 5,
    maxFlowers: 8,
    reward: 35,
    storySnippet:
        'The bride paused when she saw them. "These are exactly what I pictured," she said, then hugged her partner.',
  ),
  DeliveryMission(
    id: 'wedding_luxurious',
    location: 'Rosewood Wedding Venue',
    emoji: '💒',
    description: "Bridal party bouquets for a garden ceremony.",
    hint: '"Lush and luxurious — the bridesmaids are counting on you 💐"',
    requiredVibes: [VibeTag.luxurious, VibeTag.romantic, VibeTag.delicate],
    minFlowers: 5,
    maxFlowers: 9,
    reward: 40,
    storySnippet:
        'Four bridesmaids carried your bouquets down the aisle. The photographer kept stopping to capture them.',
  ),
  DeliveryMission(
    id: 'school_cheerful',
    location: 'Meadowbrook Primary',
    emoji: '🏫',
    description: "Teacher appreciation flowers from the Year 4 class.",
    hint: '"Colourful and fun — the kids helped pick the vibes! 🌈"',
    requiredVibes: [VibeTag.cheerful, VibeTag.vibrant],
    minFlowers: 3,
    maxFlowers: 6,
    reward: 16,
    storySnippet:
        "Ms. Patel pressed the bouquet to her chest and blinked back tears. The kids erupted in cheers.",
  ),
  DeliveryMission(
    id: 'school_wild',
    location: 'Meadowbrook Primary',
    emoji: '🏫',
    description: 'Flowers for the Year 6 science garden display.',
    hint: '"Wild and natural-looking — the kids are learning about ecosystems 🌿"',
    requiredVibes: [VibeTag.wild, VibeTag.natural, VibeTag.fresh],
    minFlowers: 4,
    maxFlowers: 7,
    reward: 18,
    storySnippet:
        "The display went up in the main corridor. Three kids immediately pressed their noses against the glass.",
  ),
  DeliveryMission(
    id: 'cafe_cozy',
    location: 'The Amber Cup Café',
    emoji: '☕',
    description: 'Weekly table flowers for the café counter.',
    hint: '"Cozy and inviting — we want customers to feel at home 🍂"',
    requiredVibes: [VibeTag.cozy, VibeTag.rustic],
    minFlowers: 3,
    maxFlowers: 5,
    reward: 14,
    storySnippet:
        'Lena the barista arranged them herself and texted you a photo. The café regulars have already noticed.',
  ),
  DeliveryMission(
    id: 'gallery_elegant',
    location: 'The Linden Gallery',
    emoji: '🖼️',
    description: 'Opening night flowers for a contemporary art show.',
    hint: '"Striking and elegant — they\'ll be in every photo from tonight 🎨"',
    requiredVibes: [VibeTag.elegant, VibeTag.mystical],
    minFlowers: 4,
    maxFlowers: 7,
    reward: 28,
    storySnippet:
        "The artist shook your hand at the door. \"The flowers are half the exhibit,\" she said, only half joking.",
  ),
  DeliveryMission(
    id: 'community_sympathy',
    location: 'Town Community Hall',
    emoji: '🏛️',
    description: "Memorial flowers for a community vigil.",
    hint: '"Peaceful and thoughtful — something to honour the occasion 🕊️"',
    requiredVibes: [VibeTag.sympathy, VibeTag.soft],
    minFlowers: 4,
    maxFlowers: 6,
    reward: 22,
    storySnippet:
        'You set them down quietly and left before the service started. Bud said that was the right call.',
  ),
  DeliveryMission(
    id: 'library_natural',
    location: 'Willowmere Library',
    emoji: '📚',
    description: "Flowers for the children's reading corner.",
    hint: '"Something soft and natural — we want the kids to feel calm and curious 🌱"',
    requiredVibes: [VibeTag.natural, VibeTag.delicate, VibeTag.fresh],
    minFlowers: 3,
    maxFlowers: 5,
    reward: 15,
    storySnippet:
        "The librarian said three children immediately asked if the flowers were real. They very gently touched each petal.",
  ),
];

// ── Generator ─────────────────────────────────────────────────────────────────

/// Returns 2 or 3 delivery missions for the given game day.
/// Uses the day as a seed so missions are consistent within a day.
List<DeliveryMission> generateDeliveries(int day) {
  final rng = Random(day * 31 + 7);
  final shuffled = List<DeliveryMission>.from(_allMissions)..shuffle(rng);
  final count = 2 + (rng.nextBool() ? 1 : 0); // 2 or 3
  return shuffled.take(count).toList();
}
