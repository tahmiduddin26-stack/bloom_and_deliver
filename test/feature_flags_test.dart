// Release guard for the Phase 1 shipping surface.
//
// SHIP_PLAN Phase 1 cuts the reachable game down to: level map → play → market
// → repeat, plus the customer phone and the vibe notebook aid. Every other
// system is built but flagged off until it ships as a post-launch content drop.
//
// This test is intentionally a tripwire: if someone flips a system on, they must
// consciously update this expectation, which forces a deliberate scope decision
// rather than an accidental one.
import 'package:flutter_test/flutter_test.dart';
import 'package:bloom_and_deliver/config/feature_flags.dart';

void main() {
  test('shipping surface: non-core systems are flagged off', () {
    expect(Features.townMap, isFalse, reason: 'town map is post-launch');
    expect(Features.wholesale, isFalse, reason: 'wholesale is post-launch');
    expect(Features.bigOrders, isFalse, reason: 'big orders are post-launch');
    expect(Features.deliveries, isFalse, reason: 'deliveries are post-launch');
    expect(Features.leaderboard, isFalse, reason: 'leaderboard is post-launch');
    expect(Features.shopStats, isFalse, reason: 'shop stats are post-launch');
    expect(Features.shopInterior, isFalse, reason: 'shop interior is post-launch');
    expect(Features.upgrades, isFalse, reason: 'upgrades are post-launch');
    expect(Features.achievements, isFalse, reason: 'achievements are post-launch');
  });

  test('core-supporting aids stay on', () {
    expect(Features.vibeNotebook, isTrue, reason: 'notebook aids the core loop');
    expect(Features.shopDecor, isTrue, reason: 'decor is the Phase 2 money sink');
  });
}
