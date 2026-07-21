import 'package:flutter/material.dart';

class SeasonalEvent {
  final String id;
  final String name;
  final String emoji;
  final String tagline;
  final int startDay;
  final int endDay; // inclusive
  final List<Color> backgroundGradient;
  final String? limitedFlowerId; // null = no exclusive flower

  const SeasonalEvent({
    required this.id,
    required this.name,
    required this.emoji,
    required this.tagline,
    required this.startDay,
    required this.endDay,
    required this.backgroundGradient,
    this.limitedFlowerId,
  });

  bool isActiveOnDay(int day) => day >= startDay && day <= endDay;
}
