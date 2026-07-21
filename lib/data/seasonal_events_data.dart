import 'package:flutter/material.dart';

import '../models/seasonal_event.dart';

/// The four seasonal events, each spanning 7 game days.
const List<SeasonalEvent> allSeasonalEvents = [
  SeasonalEvent(
    id: 'valentines',
    name: "Valentine's Week",
    emoji: '💝',
    tagline: 'Love is in the air — romantic orders abound!',
    startDay: 14,
    endDay: 20,
    backgroundGradient: [
      Color(0xFF4A1428),
      Color(0xFF7A2040),
      Color(0xFF5C1830),
      Color(0xFF3A0E1E),
    ],
    limitedFlowerId: 'gardenia',
  ),
  SeasonalEvent(
    id: 'mothers_day',
    name: "Mother's Day Rush",
    emoji: '🌺',
    tagline: 'The biggest bouquet day of the year!',
    startDay: 28,
    endDay: 34,
    backgroundGradient: [
      Color(0xFF2E1A3A),
      Color(0xFF4A2860),
      Color(0xFF361E48),
      Color(0xFF201030),
    ],
    limitedFlowerId: 'sweet_pea',
  ),
  SeasonalEvent(
    id: 'harvest',
    name: 'Harvest Festival',
    emoji: '🍂',
    tagline: 'Rustic blooms and warm autumn vibes.',
    startDay: 42,
    endDay: 48,
    backgroundGradient: [
      Color(0xFF3A2010),
      Color(0xFF6B3A1E),
      Color(0xFF4A2814),
      Color(0xFF2A1608),
    ],
    limitedFlowerId: 'chrysanthemum',
  ),
  SeasonalEvent(
    id: 'winter_blooms',
    name: 'Winter Blooms',
    emoji: '❄️',
    tagline: 'Crisp and elegant — the shop feels magical.',
    startDay: 56,
    endDay: 62,
    backgroundGradient: [
      Color(0xFF0E1E30),
      Color(0xFF162840),
      Color(0xFF101C30),
      Color(0xFF091220),
    ],
    limitedFlowerId: 'amaryllis',
  ),
];

/// Returns the active event for the given game day, or null.
SeasonalEvent? eventForDay(int day) {
  try {
    return allSeasonalEvents.firstWhere((e) => e.isActiveOnDay(day));
  } catch (_) {
    return null;
  }
}

/// Returns true if today is the first day of a new event.
bool isEventStartDay(int day) =>
    allSeasonalEvents.any((e) => e.startDay == day);
