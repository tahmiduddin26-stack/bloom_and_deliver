# Bloom & Deliver — Project Reference

A cosy mobile game built in **Flutter** where the player runs a flower shop. Customers arrive with bouquet orders described through personality-driven hints. The player taps or drags flowers from a tray into a workspace, submits the bouquet, and earns money based on how well the flowers match the order's vibe requirements. Between days the player restocks at the market.

> **Roadmap:** `SHIP_PLAN.md` is the phased plan to ship. Read it before large changes — it explains *why* much of the codebase is deliberately switched off.

---

## Tech Stack

- **Flutter** (Dart, SDK ^3.11.5)
- **Riverpod 2.x** (`NotifierProvider`, no code generation)
- **Google Fonts** (Playfair Display + Nunito)
- **shared_preferences** for save/load

---

## The shipping surface (read this first)

The repo contains far more systems than the game ships with. `lib/config/feature_flags.dart` gates them, and **the reachable game is only**:

```
main.dart → TutorialScreen (new players) → LevelMapScreen (hub)
              → PlayScreen → end-of-day dialog → MarketScreen → back to hub
              → GemShopScreen / VibeNotebookScreen / ShopDecorScreen
```

| Flag | State | Notes |
|---|---|---|
| `shopDecor`, `vibeNotebook` | **on** | Money sink + collection axis |
| `townMap`, `wholesale`, `bigOrders`, `deliveries`, `leaderboard`, `shopStats`, `shopInterior`, `upgrades`, `achievements` | **off** | Built, kept as the post-launch content roadmap |
| `ads` | **off** | No live screen shows a banner; `ad_service.dart` still has placeholder unit IDs |

Gating is enforced in two layers, so a missed button can't leak a screen:
1. Every `open<Screen>()` helper early-returns when its flag is off.
2. Hub UIs hide the entry points.

`test/feature_flags_test.dart` is a tripwire — flipping a flag fails it on purpose, forcing a deliberate scope decision.

**Anything reachable must be real.** Don't write level text or tutorial copy that promises a flagged-off system.

---

## Project structure

```
lib/
  main.dart                   # Boots services, loads save, picks tutorial vs level map
  config/feature_flags.dart   # The shipping surface (above)
  models/                     # flower, bouquet_order, customer_profile, game_state, …
  data/                       # flower_data, order_data, level_data, gem_data, …
  providers/game_provider.dart  # GameNotifier — ALL game logic lives here
  services/
    persistence_service.dart  # SharedPreferences save/load
    analytics_service.dart    # No-op seam; swap `instance` for a real backend
    iap_service.dart          # No-op seam; gem purchases (no billing SDK wired)
    audio_service.dart        # Silently no-ops until assets/audio/ has files
    notification_service.dart # Opt-in daily reminder (off by default)
    ad_service.dart           # Disabled; refuses to run on placeholder IDs
  screens/                    # play_screen + level_map_screen are the live core
  widgets/                    # ambient_petals, end_of_day_dialog, memory_popup, …
  theme/app_theme.dart
```

Screens/widgets not in the live flow above exist only for flagged-off systems.

---

## Core loop

1. **Flowers** have `vibes`, `cost`, `wiltsAfterDays`; some are `isFiller` (greens).
2. **Orders** require vibe combinations; the customer's hint is the clue.
3. **Scoring** (`BouquetOrder.score()`): matched/required ratio × `loyaltyMultiplier`. ≥80% → great (+30%); ≥50% → good; <50% → poor (40%, no loyalty). Mystery orders score on distinct species instead.
4. **Day ends** when all orders are served → summary → market restock → `startNextDay()`.
5. **Wilting**: `inventoryDayAdded[flowerId]` tracks freshness; expired stock is removed on day advance.

### Economy — treat as load-bearing

Star goals in `level_data.dart` were derived from expected per-level earnings (`star2` ≈ all-Good, `star3` ≈ 0.90 × all-Great) so 3★ demands mostly-Great play. `test/sim_test.dart` runs a greedy bot through all 20 levels and asserts the campaign total stays in **[24, 50]/60** — if you change payments, costs, or star goals, re-run it and re-tune.

**Do not casually change:** `star2Earnings`/`star3Earnings`, `basePayment`, flower `cost`, decor cost, restock amounts, `loyaltyMultiplier`.

Every `VibeTag` must be carried by at least one non-event flower, or orders needing it become unwinnable. `sim_test.dart` guards this too.

### Gems (premium currency)

Bought with real money, **never earned from play**, so the coin economy is unaffected for non-paying players. Spent only on time-savers: instant restock, freshness reset, challenge reroll (`gem_data.dart`).

`IapService` defaults to `UnavailableIap`, which **refuses every purchase** — no billing SDK is wired. `DebugIap` (kDebugMode only) exists for testing. Going live needs store products, a billing plugin, and **server-side receipt validation**.

⚠️ `GameState` is rebuilt from scratch in `startNextDay()` and `startLevel()`. Any new long-lived field (like `gems`) **must be carried through both**, or it silently resets.

---

## Persistence

`PersistenceService` saves to SharedPreferences. New fields must default gracefully (`prefs.getInt(key) ?? 0`) so old saves still load.

⚠️ `loadState()` deliberately **preserves the save on a parse failure** and starts the session fresh. It used to call `clearSave()`, which silently destroyed all progress on any schema change. Don't reintroduce that.

---

## Conventions

- All state mutations go through `GameNotifier`; widgets never mutate state.
- `withValues(alpha: x)`, not `withOpacity` (Flutter 3.27+).
- Analytics goes through `AnalyticsService.instance` — never call an SDK directly.
- Order count per day: `3 + (day-1).clamp(0,5)`, rising to 10 from day 15.

---

## Assets (all degrade gracefully — the app runs without them)

- `assets/flowers/<flowerId>.png` — 256×256 transparent. Emoji fallback until present.
- `assets/audio/*.mp3` — silent until present.
- `assets/characters/lily.png`, `bud.png`.

---

## Status

Phases 0–5 of `SHIP_PLAN.md` are largely done: vibe fixes, scope cut, economy rebalance, code-only atmosphere polish, retention hooks, and release signing/ads compliance.

Outstanding: audio + flower art + portraits + app icon, real store/IAP/analytics backends, privacy policy & Data Safety form, `targetSdk` 36, then soft launch.
