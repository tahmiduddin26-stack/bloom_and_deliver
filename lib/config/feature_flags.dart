/// Feature flags for optional game systems.
///
/// The playable surface is journey → town / shop → market / orders, with
/// the Day 3 wholesale depot, Day 4 evening deliveries, Day 7 commissions, records,
/// achievements, upgrades, decor and settings.
///
/// The leaderboard is kept hidden until real online comparison exists.
///
/// Gating is enforced in two places:
///   1. The `open<Screen>` navigation helpers early-return when their flag is
///      off, so an unfinished screen is not reachable through a missed button.
///   2. The hub UIs (level map, market, end-of-day dialog) hide the entry
///      points for flagged-off systems, so there are no dead buttons.
///
/// Flags are mutable `static bool`s rather than `const` so that (a) QA and
/// widget tests can flip a system back on at runtime, and (b) the analyzer does
/// not treat `if (Features.x)` gates as compile-time-constant dead code.
abstract final class Features {
  // ── Places and extras ───────────────────────────────────────────────────
  static bool townMap = true;
  static bool wholesale = true;
  static bool bigOrders = true;
  static bool deliveries = true;
  static bool leaderboard = false;
  static bool shopStats = true;
  static bool shopInterior = true;
  static bool upgrades = true; // Coins buy lasting improvements to the shop.
  static bool achievements = true;

  /// AdMob banners. Off for launch, deliberately:
  ///   * no live screen shows a banner (the only one died with GameScreen), so
  ///     initialising the SDK bought nothing but a privacy-disclosure burden;
  ///   * `ad_service.dart` still holds placeholder unit IDs, which fail to load;
  ///   * gems are now the monetisation, and a cozy game keeps more goodwill
  ///     without ads.
  /// Turn on only after real AdMob unit IDs are in place AND the Data Safety
  /// form is updated to match.
  static bool ads = false;

  // ── Kept on ─────────────────────────────────────────────────────────────
  /// Vibe notebook — the collection axis (Phase 4 retention). The player is
  /// already accumulating `vibeDiscoveries` in the live flow; the notebook gives
  /// that a home and a "complete all 18" pull. Entry points: town and shop.
  static bool vibeNotebook = true;

  /// Shop decor / collection — the late-game money sink (Phase 2). Decor gives
  /// accumulated cash somewhere meaningful to go, so restocking a deep, diverse
  /// inventory competes with saving toward an aspirational showpiece.
  static bool shopDecor = true;
}
