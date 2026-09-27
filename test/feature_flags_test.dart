// Tripwire for reachable places and deliberately hidden online features.
import 'package:flutter_test/flutter_test.dart';
import 'package:bloom_and_deliver/config/feature_flags.dart';

void main() {
  test('commissions are playable and offline leaderboard stays hidden', () {
    expect(Features.bigOrders, isTrue);
    expect(Features.leaderboard, isFalse, reason: 'leaderboard is post-launch');
  });

  test('journey places and shop collection are accessible', () {
    expect(Features.townMap, isTrue);
    expect(Features.wholesale, isTrue);
    expect(Features.deliveries, isTrue);
    expect(Features.shopInterior, isTrue);
    expect(Features.shopStats, isTrue);
    expect(Features.achievements, isTrue);
    expect(
      Features.upgrades,
      isTrue,
      reason: 'coins buy lasting shop improvements',
    );
    expect(
      Features.shopDecor,
      isTrue,
      reason: 'decor is the Phase 2 money sink',
    );
    expect(
      Features.vibeNotebook,
      isTrue,
      reason: 'notebook is the Phase 4 collection axis (level-map entry)',
    );
  });
}
