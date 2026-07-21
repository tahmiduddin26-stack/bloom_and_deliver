import 'dart:math';

import 'flower_data.dart';

/// Represents a single active flash sale on a flower.
class FlashSale {
  final String flowerId;

  /// Discounted cost (70% of normal cost, i.e. 30% off).
  final int discountedCost;

  const FlashSale({required this.flowerId, required this.discountedCost});

  int get originalCost => (discountedCost / 0.7).round();
  int get savings => originalCost - discountedCost;
}

/// Returns the 1–2 flowers currently on flash sale, seeded by the current
/// real-time 2-hour block so the sale is stable within the window.
List<FlashSale> activeFlashSales() {
  final now = DateTime.now();
  final block = now.hour ~/ 2; // 0–11, changes every 2 hours
  final seed = now.year * 10000 + now.month * 100 + now.day + block * 37;
  final rng = Random(seed);

  // Pick from flowers that have a defined cost (all of them, but shuffle randomly)
  final candidates = List<String>.from(allFlowers
      .where((f) => !f.isEventExclusive) // event flowers on normal sale is weird
      .map((f) => f.id))
    ..shuffle(rng);

  final count = rng.nextBool() ? 1 : 2;
  return candidates.take(count).map((id) {
    final flower = flowerById[id]!;
    return FlashSale(
      flowerId: id,
      discountedCost: (flower.cost * 0.7).round().clamp(1, flower.cost - 1),
    );
  }).toList();
}

/// Time remaining in the current 2-hour sale block.
Duration timeUntilNextFlashSale() {
  final now = DateTime.now();
  final currentBlock = now.hour ~/ 2;
  final nextBlockHour = (currentBlock + 1) * 2;
  final next = DateTime(now.year, now.month, now.day, nextBlockHour);
  final diff = next.difference(now);
  return diff.isNegative ? Duration.zero : diff;
}

/// Human-readable countdown, e.g. "1h 23m".
String flashSaleCountdown() {
  final d = timeUntilNextFlashSale();
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h > 0) return '${h}h ${m}m';
  return '${m}m';
}
