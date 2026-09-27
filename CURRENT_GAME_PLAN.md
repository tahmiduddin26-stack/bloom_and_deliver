# Bloom & Deliver — Current Build and Finish Line

Updated 26 September 2026. This is the working plan; `GAME_PLAN.md` and
`SHIP_PLAN.md` record earlier design decisions and contain outdated numbers.

## Playable journey

1. A new player learns the shop in a five-step tutorial and receives starting
   supplies and gems.
2. The garden map shows a 20-level campaign. Each level serves a day of customer
   orders. The order count and quick-service tip window tighten as the journey
   advances; every fifth level is a festival rush.
3. Customers ask for flower vibes. Players choose flowers from their stock and
   see the exact bouquet build on the counter. Great bouquets, quick service,
   and consecutive Great results earn extra coins. Missing the tip window never
   prevents finishing an order.
4. The end-of-day result awards 0–3 stars from the day's earnings. One star
   opens the next level. A missed goal can be retried without a lives cost.
   Improving a previous best grants five gems per new star.
5. Coins restock the market, buy eight functional upgrades, and furnish the
   storefront. Gems buy optional restock and freshness shortcuts and a challenge
   reroll. Gems are earnable from the journey; real-money packs are hidden when
   no store is connected.
6. The flower notebook tracks discoveries. The campaign continues into an
   endless level sequence after level 20.

## Places around Bloomfield

- The journey header opens the town, shop, market, and settings. Town is a
  simple hub for the shop, market, flower notebook, and Day 3 depot. It shows the live
  storefront rather than promising places that cannot yet be visited.
- The shop groups upgrades, decor, the windowsill garden, notebook,
  achievements, and records. The storefront preview changes when decor is
  bought, so coins spent here have a visible result.
- Settings saves the sound choice and lets players opt into a daily reminder.
  Progress saves automatically. Records show actual order, earnings, star, and
  flower-use totals from the current save.
- The Wholesale Depot opens on Day 3. Players can prepay for discounted
  five-stem bundles (at most four bundles a day), which arrive fresh when the
  next level begins. It rewards planning ahead without replacing same-day
  market restocks.
- From Day 4, the end-of-day result offers optional evening deliveries.
  Players build each delivery from their existing stock, see the finished
  bouquet, and earn a one-time reward. Skipping or backing out proceeds to the
  market. Missions only ask for moods available from unlocked flowers.
- From Day 7, a three-day commission can appear. Players hand in at most one
  arrangement per distinct campaign day, using their current stock. The card
  shows its deadline, progress, requested moods, daily pay and completion bonus.
  Skipping a day can cost the finish bonus; an expired commission disappears
  without blocking the journey. The day summary routes through both the
  commission and evening deliveries before the market when both are available.

## Next playable additions

1. **Records and social scope:** Keep Shop Records as the honest local progress
   view. Leave the separate leaderboard hidden unless an actual online service
   and fair comparison rules are built; do not show fictional competitors.
2. **Release pass:** Play the entire loop on a physical device, tune late-level
   difficulty with people, verify large text and screen readers, and prepare
   private signing and store materials.

## Visual and sound direction

Keep a cheerful illustrated shop: warm paper backgrounds, deep garden-green
headers, ink outlines, chunky rounded controls, clear flower colours and soft
petal accents. Flower and customer portraits are drawn in the app, so they stay
sharp at small phone sizes. The storefront preview reflects purchased decor.
Every chosen flower combination has a bouquet preview. Short plucked chimes and
a quiet shop loop support interactions; the player can mute them. The Android
launcher uses the same hand-drawn sunflower style and the public game name.

## Checks already in place

- `flutter analyze --no-pub` and `flutter test --no-pub` are the release checks.
- The headless test plays all 20 levels, checks stock and stars, and proves all
  generated orders can be satisfied by flowers available on their day.
- Widget checks cover the market, decor, notebook, and tutorial at 390 px and
  320 px widths. The journey and order screen also render at 320 px with 130%
  text sizing. Town, shop, records, and settings also render at these sizes.
  Wholesale checkout, evening delivery, and three-day commission hand-ins are
  covered at these sizes. Commission regression checks cover saves, day changes,
  one contribution per day, expiration, later offers, replay rejection, and the
  summary with both optional routes visible together.
  A failed stage correctly offers a retry. Reward sequencing is checked so
  bouquet feedback appears before rank-up and the day summary.
- The Android simulator has launched the release-mode APK, restored an in-progress
  bouquet, accepted a mixed-flower hand-in, awarded coins, and advanced to the
  next customer without a crash in the device log.

## Finish line for a public release

- Complete a fresh-install and returning-save playthrough on a physical Android
  device, including audio, mute, interruptions, the market, and decor purchase.
- Tune the difficulty with human playtesting. The simulation proves progression
  is possible but cannot judge whether late days feel repetitive or too long.
- Verify accessibility at larger text sizes and with screen reading enabled.
- Supply a private release signing key and store listing. Real-money gem packs
  need a store billing integration and payment verification before being shown.

The local APK is suitable for device testing; it is not a signed store release.
