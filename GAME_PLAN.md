# Bloom & Deliver — Full Game Plan (Opening → Level 20)

A cozy, girly flower-shop game. You run a little florist's, matching bouquets to customer vibes, earning coins, and spending them back into the shop — restocking flowers, buying upgrades, and decorating. No fail states, no timers: finishing a level always earns at least 1 star, and better earnings earn 2–3 stars. Any unlocked level can be replayed for more stars.

This plan reflects what is now implemented in code, informed by cozy-game design research (safety, abundance, softness — see [Lostgarden's cozy games essay](https://lostgarden.com/2018/01/24/cozy-games/)) and Candy Crush-style saga map conventions (linear node path, 1–3 stars, visible progress — see [level design breakdowns](https://cjleo.com/blog/1001-levels-of-candy-crush/)).

---

## Player Journey

1. **First launch** → 5-step tutorial with Lily & Bud (existing) → starter reward (+$50, premium flowers) → **Level Map**.
2. **Level Map** (new `level_map_screen.dart`) — a winding garden path of 20 nodes, bottom to top. Tap a node → level sheet (title, star goals, what unlocks) → Play.
3. **Playing a level** = one shop day on the streamlined `play_screen.dart`: the customer's card sits at the top (avatar, hint, vibe chips that light up ✓ live), the bouquet builds in the middle, and a big horizontal flower tray sits at the bottom — **tap or drag** to add, matching flowers sort first with a golden ✓ MATCH glow. Result pops as a juicy overlay with coins earned.
4. **Day ends** → summary dialog with the level's star result → Market to restock → **back to the map**, next node unlocked. Secondary systems (wholesale, big orders, deliveries, presets, leaderboard, town map) are cut from the core flow — their code remains in the repo for later.
5. **After Level 20** → endless mode ("Endless Bloom") — the path keeps growing with auto-generated levels.

## Matching (simplified)

- The customer's phone shows the required vibe chips directly.
- Shelf pots that carry a wanted vibe get a **golden halo + "✓ MATCH" badge**.
- The workspace shows a live **Match checklist** — each required vibe lights up with a ✓ as soon as a covering flower is added.
- Scoring: ≥80% of vibes matched = Great (+30% pay), ≥50% = Good, otherwise Poor (40% pay). Bonuses for greens and discovered vibe chapters are folded into the order's earnings.

## Currency loop (all sinks working)

| Sink | Where | Notes |
|---|---|---|
| Restock flowers | Market (end of day) | Core loop; flash sales + clearance |
| Shop upgrades | 🔨 Upgrades screen | All 5 now have real effects (see below) |
| Shop decor | 🎨 Decor screen | Wallpaper, lights, plants, counter, display |
| Seeds | Windowsill | Grow free flowers in real time |
| Wholesale | Town map → Wholesale | Bulk orders arrive next morning |

Upgrades: Workspace XL (+2 bouquet slots — now respected by the UI too), Extra Shelf (**now** 10% off restocks), Flower Cooler (+1 freshness day), Wrapping Station (+15% on Greats), Display Window (**now** +1 customer/day).

---

## The 20 Levels

Stars: ⭐ finish the day · ⭐⭐ reach the earnings goal · ⭐⭐⭐ reach the stretch goal.

| # | Title | Beat / What unlocks | 2⭐ | 3⭐ |
|---|---|---|---|---|
| 1 | 🎀 Grand Opening | Tutorial vibes; 3 gentle orders | $90 | $120 |
| 2 | 🌷 Word Gets Around | First market restock matters | $120 | $165 |
| 3 | 🌸 Fresh Deliveries | Tier 2 flowers unlock (Orchid, Gerbera…) | $160 | $215 |
| 4 | 🎭 The Mystery Note | First mystery order (creativity scoring) | $200 | $265 |
| 5 | 💕 Regulars & Friends | Friendship hearts pay loyalty bonuses | $240 | $320 |
| 6 | ☀️ Busy Morning | 8 orders/day; Tier 3 flowers (Peony…) | $280 | $370 |
| 7 | 🌿 Greens & Grace | Filler-greens bonus spotlight | $300 | $395 |
| 8 | 🏪 Rival in Town | Story: Petal & Co.; late-tier orders begin | $310 | $410 |
| 9 | 🪴 Windowsill Garden | Seed growing spotlight | $320 | $425 |
| 10 | 👑 Rare Beauty | Protea unlocks (Tier 4) | $335 | $445 |
| 11 | 🚲 Evening Rounds | Delivery missions spotlight | $345 | $460 |
| 12 | 🎭 Mystery Season | Mystery orders more frequent | $355 | $475 |
| 13 | 🎨 Shop Makeover | Decor spending spotlight | $365 | $490 |
| 14 | 💒 The Big Commission | 3-day wedding order arrives | $375 | $500 |
| 15 | 💐 Full Bloom | 10 orders/day; premium orders unlock | $430 | $575 |
| 16 | 📦 Wholesale Wisdom | Bulk-buying spotlight | $445 | $595 |
| 17 | 🏮 Festival Eve | Seasonal event + exclusive flowers | $460 | $615 |
| 18 | ✨ Master Class | Push for all-Great days | $480 | $640 |
| 19 | ⚔️ The Final Push | Story climax vs Petal & Co. | $500 | $665 |
| 20 | 🏆 Bloom Legend | Campaign finale → endless mode | $525 | $700 |

Difficulty follows the casual-game rhythm: a new mechanic level is always slightly easier than the level before it, and stretch goals assume Greats + greens bonuses, not perfection.

## Economy curve (rough)

- Start: $120 + free Tier 1 stock. Orders pay ~$18–45 early, ~$40–90 late.
- Flower costs ~$2–12 (Tier 1) up to ~$20+ (Tier 4); a Good day should net ~30–50% profit.
- Upgrades ($50–100) are 1–2 days of profit each — meaningful but quick to reach.
- Replaying earlier levels is the gentle "grind" valve: relaxed money-making with easier orders, never required.

## Assets (placeholders fine)

Everything renders with emoji + colour placeholders today. Drop-in upgrade paths (no code changes needed):

- `assets/flowers/{flower_id}.png` — replaces a flower's emoji everywhere (30 flowers; see `flower_data.dart` for ids).
- `assets/characters/lily.png`, `bud.png` — tutorial/tip characters (already present).
- `assets/audio/*.mp3` — see `assets/audio/README.md` for expected filenames (submit, coin, great order, ambient…).
- Level map: nodes/doodles are emoji; can later swap in painted path + node art.

## Possible next steps (not yet built)

Chest rewards every 5 levels, a star-gated bonus shop, cloud save, Lily & Bud story cutscenes between chapters (data already exists in `story_arc_data.dart`), and haptic/audio polish once real sound files are added.
