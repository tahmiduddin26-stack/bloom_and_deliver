/// Feature flags gating non-core surfaces for the shipping build.
///
/// Per SHIP_PLAN Phase 1 ("Cut to the core loop"), the shipping surface is:
///   level map → play a day → market → repeat, plus the decor shop.
///
/// Everything else is built and kept in the codebase, but flagged **off** so
/// QA, tuning, and store screenshots only ever cover the shipped loop. Flipping
/// a flag back to `true` re-enables that system as a post-launch content drop
/// (wholesale, big orders, deliveries, the town map, and so on).
///
/// Gating is enforced in two places:
///   1. The `open<Screen>` navigation helpers early-return when their flag is
///      off, so no non-core screen is ever reachable even if a button is missed.
///   2. The hub UIs (level map, market, end-of-day dialog) hide the entry
///      points for flagged-off systems, so there are no dead buttons.
///
/// Flags are mutable `static bool`s rather than `const` so that (a) QA and
/// widget tests can flip a system back on at runtime, and (b) the analyzer does
/// not treat `if (Features.x)` gates as compile-time-constant dead code.
abstract final class Features {
  // ── Flagged off for launch (post-launch content roadmap) ────────────────
  static bool townMap = false;
  static bool wholesale = false;
  static bool bigOrders = false;
  static bool deliveries = false;
  static bool leaderboard = false;
  static bool shopStats = false;
  static bool shopInterior = false;
  static bool upgrades = false;
  static bool achievements = false;

  // ── Kept on ─────────────────────────────────────────────────────────────
  /// Vibe notebook — the collection axis (Phase 4 retention). The player is
  /// already accumulating `vibeDiscoveries` in the live flow; the notebook gives
  /// that a home and a "complete all 18" pull. Entry point: the 📓 button on the
  /// level-map header.
  static bool vibeNotebook = true;

  /// Shop decor / collection — the late-game money sink (Phase 2). Decor gives
  /// accumulated cash somewhere meaningful to go, so restocking a deep, diverse
  /// inventory competes with saving toward an aspirational showpiece.
  static bool shopDecor = true;
}
