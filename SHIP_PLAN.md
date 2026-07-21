# Bloom & Deliver — Road to Ship

A phased plan from the current build to a store-ready launch, grounded in (a) a headless
simulation of the actual game (`test/sim_test.dart`), and (b) research into shipped cozy
shop-sim and flower games.

---

## What the research says

**The closest shipped comparables**

| Game | Loop | What it proves |
|---|---|---|
| [Good Pizza, Great Pizza](https://play.google.com/store/apps/details?id=com.tapblaze.pizzabusiness) (TapBlaze) | Customer states an order in dialogue → you assemble it → get paid → buy upgrades | This is *our exact loop*. It shipped, has 100+ named customers with personalities, and is explicitly beatable without IAP. The draw is **characters and their requests**, not the assembly minigame. |
| [The Cozy Florist](https://play.google.com/store/apps/details?id=com.riftsky.mhg.gb.gp) | Arrange bouquets, decorate shop, collect rare seeds, visit other players | Our nearest direct competitor, already live. It leans on **collection** (rare seeds) and **social visiting** for retention, and monetises cosmetics + progression speed. |
| [Flowers And Favours: Florist Simulator](https://store.steampowered.com/app/3269600/Flowers_And_Favours_Florist_Simulator/), [BloomTale](https://store.steampowered.com/app/3168520/BloomTale/) | Florist sim, PC | The florist-sim fantasy has a proven audience; both compete on **atmosphere and character writing**, not systems depth. |
| [Florescence: Merge Garden](https://play.google.com/store/apps/details?id=com.gamegarden.florescence), Blooming Flowers Merge | Merge | The flower *merge* space is crowded and commoditised. Staying an order-matching shop sim is the right differentiation — don't drift toward merge. |

**The uncomfortable numbers.** Industry retention targets are D1 40% / D7 20% / D30 10%, but
actual 2024–25 top performers land at [D1 31–33% on iOS, 25–27% on Android](https://www.gameanalytics.com/reports/2025-mobile-gaming-benchmarks);
median D7 across all projects is **3.4–3.9%**, and 75% of games see D28 under 3%. Anything
that isn't excellent on day one has no day seven. Tutorial-completion is the single most
diagnostic early metric — [build a tutorial funnel with an event per step](https://www.gameanalytics.com/blog/soft-launch-guide)
before you have players, not after.

**What this means for us, concretely:**

1. Our current build is a **systems buffet** — 67 files, 14 screens, wholesale/deliveries/
   big orders/decor/seeds/presets/leaderboard/town map. Good Pizza shipped with a fraction of
   that. Depth of *systems* is not what retains cozy players; **characters, atmosphere, and a
   clean loop** are. The plan below deliberately cuts and buries before it adds.
2. Our art is emoji placeholders (3 of 30 flower PNGs exist) and **there is no audio at all**
   (`assets/audio/` holds only a README). For a genre where "cozy atmosphere" and
   "pizza-making ASMR" are the top review praise, this is not polish — it's the product.
3. The economy has no tension after level 3 (see Phase 2).

---

## Phase 0 — Correctness

*Nothing else matters while the game lies to the player.*

- **Unobtainable vibes.** `VibeTag.traditional` is required by 12 orders and carried by **zero**
  flowers; `VibeTag.soft` is required by 9 and carried only by `sweet_pea`, which is gated behind
  the Mother's Day event. **21 distinct orders can never score Great** — the player matches every
  chip on the card and still gets a middling result. Add both vibes to Tier-1 flowers.
- **`exotic` is required by 18 orders but only Protea has it**, and Protea unlocks day 10 — while
  two mid-tier orders (day 3+) and most late orders (day 8+) demand it. Give a Tier-1/2 flower
  `exotic`, or move Protea earlier. Same for `luxurious` (18 orders / 2 flowers) and `natural`
  (14 / 2).
- Clear the 57 analyzer infos (`unnecessary_underscores`, deprecated `withOpacity` in
  `bouquet_share_card.dart`).
- Keep `test/sim_test.dart` green in CI — it is the regression net for all of the above.

**Exit:** the satisfiability test passes; every order in the pool is Great-able on the day it can appear.

---

## Phase 1 — Cut to the core loop

*The riskiest thing in the repo is how much of it there is.*

- Pick the **shipping surface**: level map → play a day → market → repeat, plus the customer
  phone. That is the whole game.
- Everything else — town map, wholesale, big orders, delivery missions, leaderboard, presets,
  shop stats — gets **feature-flagged off**, not deleted. `GAME_PLAN.md` already says these are
  "cut from the core flow"; make that true in the build so QA, tuning, and store screenshots
  only ever cover the shipped surface.
- Re-examine the tutorial as a **funnel**, not a cutscene: 5 steps, an analytics event per step,
  and the player making a real bouquet for a real customer by step 3.

**Exit:** a new player reaches "served my first customer" in under 90 seconds, and the app has
no reachable screen that isn't part of the shipping loop.

---

## Phase 2 — Economy and difficulty

*Simulated with a naive greedy bot: it three-starred every level from 3 to 19.*

| level | earned | 2★/3★ goal | money after |
|---|---|---|---|
| 1 | 111 | 90 / 120 | 181 |
| 5 | 411 | 240 / 320 | 1,178 |
| 10 | 493 | 335 / 445 | 2,870 |
| 15 | 694 | 430 / 575 | 5,314 |
| 20 | 648 | 525 / 700 | 8,293 |

**57 of 60 stars, zero Poor results across 161 orders, and $8,293 in the bank** while spending
60% of cash on restock every night. Star goals stop constraining at level 3; by level 10 every
sink (upgrades $50–100, decor, seeds) is trivially affordable.

Cozy means *no fail state* — it does not mean *no decision*. The fix is to make the interesting
choice scarcity, not failure:

- Rebalance `star2Earnings`/`star3Earnings` upward from level 3 so 3★ demands mostly Greats,
  **or** raise flower costs so restock genuinely competes with upgrades. Pick one lever; both is
  a difficulty spike.
- Give money somewhere meaningful to go late-game — the decor/collection axis is the
  research-backed answer (it's what The Cozy Florist monetises).
- Re-run the sim after every tuning pass. The bot playthrough is the balance harness.

**Exit:** the greedy bot lands ~35–45/60 stars, and a level-15 player still has to choose
between restocking and buying.

---

## Phase 3 — Atmosphere

*This is the product, not the polish.*

- **Audio, from zero.** `AudioService` is fully wired and silently no-ops; `assets/audio/` is
  empty. Ambient shop loop, flower-pickup, snip, wrap, till/coin, customer-arrive chime, Great
  sting. Reviews of the genre leaders praise "soothing soundscapes" above every mechanic.
- **Flower art.** 3 of 30 PNGs exist. The remaining 27 at 256×256 transparent, named by flower id.
- **Character portraits** beyond Lily and Bud — customers are the retention engine, and right now
  they're an emoji.
- **Juice:** the drag/drop, the match glow, the coin payout, the result overlay. Small,
  high-leverage, and cheap once audio exists.

**Exit:** a 60-second silent screen recording still reads as "cozy" — and with sound on, it reads
as *the* cozy flower game.

---

## Phase 4 — Retention

*Only meaningful once Phases 1–3 make day one worth returning from.*

- **Characters as the hook.** Backstory snippets, friendship levels, and life events already
  exist in `order_data.dart` and are the most valuable unused asset in the repo. Surface them —
  a returning regular whose story advances is what Good Pizza built a franchise on.
- **A collection axis.** The vibe notebook and rare flowers are the natural home; The Cozy
  Florist proves rare-seed collection carries this genre.
- Daily challenges and login streak are built — verify they *read* as gifts, not chores.
- Local notifications are wired (`flutter_local_notifications`) but must be gentle and
  opt-in; a cozy game that nags is uninstalled.

**Exit:** an instrumented reason to open the app on day 2, day 3, and day 7 that isn't a timer.

---

## Phase 5 — Compliance and infrastructure

*Currently blocking submission. All of this is unglamorous and none of it is optional.*

- **Signing:** `android/app/build.gradle.kts` still ships `signingConfig = signingConfigs.getByName("debug")`
  with a `TODO`. Real keystore, stored outside the repo.
- **Target API:** from **31 Aug 2026**, new apps and updates must target
  [Android 16 / API 36](https://developer.android.com/google/play/requirements/target-sdk);
  existing apps need API 35 minimum to stay available on Android 16/17 devices. Publish as AAB,
  not APK.
- **AdMob:** `ad_service.dart` still holds Google's test unit IDs plus
  `ca-app-pub-XXXX/XXXX` placeholders. Real IDs — shipping test IDs violates AdMob policy, and
  shipping the placeholders crashes the ad load. Decide seriously whether ads belong in a cozy
  game at all; Good Pizza's "no IAP required to beat the game" stance is a large part of its
  goodwill.
- **Data Safety form + privacy policy**, and they must agree with each other — mismatches get
  apps suspended. Same for the iOS privacy manifest.
- **Analytics**, installed *before* soft launch: install → tutorial step 1..5 → first bouquet →
  day 2 return. Without the tutorial funnel you cannot diagnose a bad D1.
- App icon (still the default Flutter launcher), store listing, screenshots, feature graphic,
  age rating, crash reporting + deobfuscation upload.
- Real-device test matrix, and a **save-migration test** — `PersistenceService.loadState()`
  wipes the save on any exception, so a schema change silently deletes player progress.

**Exit:** a signed release AAB and iOS build that pass store review requirements on paper.

---

## Phase 6 — Soft launch

- Limited-geo release, small paid or organic cohort. Objectives and KPIs defined *before* the
  build goes out.
- Watch, in order: **crash-free rate → tutorial completion → D1 → session length → D7**.
- Benchmarks to judge against: D1 ≥ 30% is competitive; D7 above ~8% puts you in the top
  quartile. Below ~20% D1, the problem is FTUE and you return to Phase 1 — not Phase 4.
- Fix, patch, re-measure. Do not proceed on a bad D1 in the hope that content fixes it.

**Exit:** D1 and tutorial-completion at or above benchmark, crash-free rate ≥ 99%, two
consecutive stable weeks.

---

## Phase 7 — Ship

- Global release from the same signed build lineage that survived soft launch.
- Store listing localised for the top markets the soft launch data actually justified.
- Post-launch: the feature-flagged systems from Phase 1 become the **content roadmap** —
  wholesale, big orders, deliveries and the town map ship as updates, each one a reason for
  lapsed players to return, rather than as day-one complexity that buries the loop.
- Support burden planned: review responses, crash triage, one patch window budgeted.

**Exit:** live, stable, with the next three content drops already built and waiting.

---

### The through-line

Phases 0–2 make the game *correct and tense*. Phase 3 makes it *the thing people want*.
Phase 4 makes them come back. Phases 5–7 are the tax on shipping. The temptation will be to
start at Phase 4 because the systems are already written — resist it. The research is
unanimous that in this genre, atmosphere and characters retain, and systems do not.
