/// Lightweight analytics seam.
///
/// The game ships with a no-op implementation so there is no hard dependency on
/// any analytics SDK. To start collecting events (e.g. tutorial-funnel drop-off,
/// which SHIP_PLAN Phase 1 calls for), assign a real implementation once at
/// startup:
///
/// ```dart
/// AnalyticsService.instance = MyFirebaseAnalytics();
/// ```
///
/// Nothing else in the app needs to change — call sites already log through
/// `AnalyticsService.instance`.
abstract class AnalyticsService {
  const AnalyticsService();

  /// The active analytics implementation. Defaults to a no-op.
  static AnalyticsService instance = const NoopAnalytics();

  /// Log a named event with optional string/number/bool parameters.
  void logEvent(String name, [Map<String, Object?>? params]);

  // ── Tutorial funnel (Phase 1 FTUE instrumentation) ──────────────────────
  void tutorialStep(int index, String name) =>
      logEvent('tutorial_step', {'index': index, 'name': name});

  void tutorialFirstBouquetSubmitted() =>
      logEvent('tutorial_first_bouquet_submitted');

  void tutorialCompleted() => logEvent('tutorial_completed');

  void tutorialSkipped(int atIndex) =>
      logEvent('tutorial_skipped', {'at_index': atIndex});

  // ── Retention (Phase 4) ─────────────────────────────────────────────────
  /// Fires once per real calendar day the app is opened — [days] is the
  /// consecutive-day streak, so day-2 / day-3 / day-7 returns are measurable.
  void loginStreak(int days) => logEvent('login_streak', {'days': days});

  void friendshipLevelUp(String customerId, int level) => logEvent(
      'friendship_level_up', {'customer': customerId, 'level': level});

  // ── Monetisation ────────────────────────────────────────────────────────
  /// A gem sink was used. [sink] is a stable slug, e.g. 'instant_restock'.
  void gemsSpent(String sink, int amount) =>
      logEvent('gems_spent', {'sink': sink, 'amount': amount});

  /// A store purchase completed. Log only after payment is confirmed.
  void gemsPurchased(String productId, int gems) =>
      logEvent('gems_purchased', {'product_id': productId, 'gems': gems});

  /// The gem shop was opened — [source] says which entry point led there.
  void gemShopOpened(String source) =>
      logEvent('gem_shop_opened', {'source': source});
}

/// Default implementation: does nothing. Swap out `AnalyticsService.instance`
/// with a real backend to begin collecting events.
class NoopAnalytics extends AnalyticsService {
  const NoopAnalytics();

  @override
  void logEvent(String name, [Map<String, Object?>? params]) {
    // Intentionally empty — no analytics backend wired yet.
  }
}
