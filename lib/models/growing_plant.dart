/// A seed planted in one of the windowsill pots.
/// Growth progress is computed at read-time from wall-clock millis.
class GrowingPlant {
  final String flowerId;
  final int slot;           // 0–2
  final int plantedAtMs;    // DateTime.now().millisecondsSinceEpoch
  final int growthMinutes;  // how long until ready

  const GrowingPlant({
    required this.flowerId,
    required this.slot,
    required this.plantedAtMs,
    required this.growthMinutes,
  });

  int get readyAtMs => plantedAtMs + growthMinutes * 60 * 1000;

  bool get isReady => DateTime.now().millisecondsSinceEpoch >= readyAtMs;

  /// 0.0 → 1.0
  double get progress {
    final now = DateTime.now().millisecondsSinceEpoch;
    final total = growthMinutes * 60 * 1000;
    return ((now - plantedAtMs) / total).clamp(0.0, 1.0);
  }

  /// Human-readable time remaining, e.g. "42 min" or "Ready!"
  String get timeRemaining {
    if (isReady) return 'Ready! 🌸';
    final ms = readyAtMs - DateTime.now().millisecondsSinceEpoch;
    final mins = (ms / 60000).ceil();
    return mins >= 60
        ? '${(mins / 60).floor()}h ${mins % 60}m'
        : '$mins min';
  }

  Map<String, dynamic> toJson() => {
        'flowerId': flowerId,
        'slot': slot,
        'plantedAtMs': plantedAtMs,
        'growthMinutes': growthMinutes,
      };

  factory GrowingPlant.fromJson(Map<String, dynamic> json) => GrowingPlant(
        flowerId: json['flowerId'] as String,
        slot: (json['slot'] as num).toInt(),
        plantedAtMs: (json['plantedAtMs'] as num).toInt(),
        growthMinutes: (json['growthMinutes'] as num).toInt(),
      );
}
