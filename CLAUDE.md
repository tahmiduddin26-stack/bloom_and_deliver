# Bloom & Deliver — Project Reference

A cosy mobile game built in **Flutter** where the player runs a flower shop. Customers arrive with bouquet orders described through personality-driven hints. The player drags flowers from inventory into a workspace, submits the bouquet, and earns money based on how well the flowers match the order's vibe requirements. At end of day, the player restocks inventory before the next day begins.

---

## Tech Stack

- **Flutter** (Dart, SDK ^3.11.5)
- **Riverpod 2.x** (flutter_riverpod, NotifierProvider pattern — no code generation used)
- **Google Fonts** (Playfair Display + Nunito)
- **shared_preferences** for save/load persistence

---

## Project Structure

```
lib/
  main.dart                        # App entry — loads save, boots ProviderScope
  models/
    flower.dart                    # Flower + VibeTag models; unlockDay field gates progression
    bouquet_order.dart             # BouquetOrder + OrderResult; score() applies loyaltyMultiplier
    customer_profile.dart          # CustomerProfile with mood + loyaltyMultiplier
    game_state.dart                # Immutable state: day, money, inventory, workspace, orders
  data/
    flower_data.dart               # 30 flowers in 4 unlock tiers; unlockedFlowers(day) helper
    order_data.dart                # 32 orders + 15 customer profiles; generateDayOrders(day)
  providers/
    game_provider.dart             # GameNotifier — all game logic lives here
    saved_state_provider.dart      # Provider<GameState?> seeded at ProviderScope for save restore
  services/
    persistence_service.dart       # SharedPreferences save/load (day, money, inventory)
  screens/
    game_screen.dart               # Main screen: dark green garden bg, Stack layout (shelves → workspace → phone overlay)
  widgets/
    bouquet_workspace.dart         # Drag-target wooden table; enforces minFlowers/maxFlowers; 60px right margin for phone
    inventory_shelf.dart           # Terracotta pot-on-shelf design; rows of 5; wilt warnings; draggable pots
    customer_phone.dart            # Slide-out phone widget on right edge; shows customer DM + order details
    order_panel.dart               # (unused — replaced by customer_phone.dart)
    end_of_day_dialog.dart         # Two-page dialog: day summary → restock shop
    restock_shop.dart              # Shop widget: buy flowers, see freshness, see locked previews
    sparkle_overlay.dart           # Confetti animation on "great" bouquet result
  theme/
    app_theme.dart                 # AppColors + AppTheme (garden greens, terracotta pots, wood shelf palette)
```

---

## Core Game Loop

1. **Flowers** have `vibes` (e.g. romantic, elegant, fresh) and `cost` and `wiltsAfterDays`.
2. **Orders** require specific vibe combinations. The player reads the customer's hint to guess what vibes to target.
3. **Scoring** (`BouquetOrder.score()`): compares bouquet vibes to required vibes as a ratio. ≥80% → great (+30% bonus × loyalty); ≥50% → good (base × loyalty); <50% → poor (40% base, no loyalty bonus).
4. **Day ends** when all orders are served → `EndOfDayDialog` shows summary → `RestockShop` lets player spend money on flowers → `startNextDay()` processes wilting and advances the day counter.
5. **Wilting**: `inventoryDayAdded[flowerId]` tracks when stock was added. On `startNextDay()`, any flower where `(currentDay - addedDay) >= wiltsAfterDays` is removed from inventory.

---

## Flower Unlock Tiers

| Tier | Unlocks on Day | Examples |
|------|---------------|----------|
| 1    | Day 1         | Rose, Daisy, Lily, Sunflower, Lavender, Tulip, Carnation, Wildflower, Baby's Breath, Marigold, Zinnia, Eucalyptus, Fern, Freesia |
| 2    | Day 3         | Orchid, Gerbera, Snapdragon, Cosmos, Hyacinth, Chrysanthemum, Statice, Sweet Pea |
| 3    | Day 6         | Peony, Ranunculus, Lisianthus, Thistle, Berry Branch, Wisteria, Anemone |
| 4    | Day 10        | Protea |

Use `unlockedFlowers(int day)` from `flower_data.dart` to get the available list for any given day.

---

## Economy

- Starting money: **$120**, starting inventory: ~3–5 of each Tier 1 flower.
- Inventory is **persistent between days** — flowers used are gone, wilted flowers disappear automatically.
- Players must visit the **Restock Shop** (end-of-day) to replenish stock by spending money.
- `restockSpentToday` tracks the day's restock spend; `dayProfit = dayEarnings - restockSpentToday`.
- Goal: **stay profitable**. Spending too much on restocking or getting poor results loses money.

---

## Key State Fields (GameState)

| Field | Type | Purpose |
|-------|------|---------|
| `day` | int | Current day number |
| `money` | int | Player's cash |
| `inventory` | Map<String, int> | flowerId → quantity in stock |
| `inventoryDayAdded` | Map<String, int> | flowerId → day the stock was last added (for wilting) |
| `restockSpentToday` | int | Money spent in shop this session |
| `dayOrders` | List<BouquetOrder> | Orders for this day |
| `currentOrderIndex` | int | Which order is active |
| `bouquetWorkspace` | List<Flower> | Flowers currently in the workspace |
| `completedToday` | List<(BouquetOrder, int)> | (order, earned) pairs |
| `dayEnded` | bool | True when all orders are served |

---

## GameNotifier Key Methods

| Method | What it does |
|--------|-------------|
| `addFlowerToWorkspace(id)` | Moves flower from inventory → workspace; enforces `maxFlowers` |
| `removeFlowerFromWorkspace(i)` | Returns flower at index back to inventory |
| `clearWorkspace()` | Returns all workspace flowers to inventory |
| `submitBouquet()` | Scores current bouquet, earns money, advances order index |
| `restockFlower(id, qty)` | Buys stock from shop, deducts money, resets freshness clock |
| `startNextDay()` | Processes wilting, advances day, generates new orders, auto-saves |
| `freshnessRemaining(id)` | Days until a flower wilts (null if not in stock) |
| `isNearlyWilted(id)` | True if ≤1 day of freshness remains |

---

## Persistence

`PersistenceService` saves `day`, `money`, `inventory`, and `inventoryDayAdded` to SharedPreferences as JSON. State is saved automatically on `restockFlower()` and `startNextDay()`. On boot, `main.dart` loads the save and seeds `savedGameStateProvider` so `GameNotifier.build()` restores from it.

---

## Conventions & Notes

- All state mutations go through `GameNotifier` — widgets never mutate state directly.
- `withValues(alpha: x)` is used throughout instead of `withOpacity` (Flutter 3.27+ API).
- Flowers in the inventory shelf show a wilt warning badge (`⚠️`) when ≤2 days of freshness remain.
- The `starterFlowers` alias in `flower_data.dart` equals `allFlowers` for backward compatibility.
- Order count per day scales as `3 + (day - 1).clamp(0, 5)` — so Day 1 = 3 orders, Day 6+ = 8 orders.

---

## What's Working / What's Not (as of last update)

✅ All fixes and redesign applied:
- Economy loop: inventory persists, restock shop functional, profit/loss tracked
- Loyalty multiplier applied in scoring for regular customers
- Wilting system fully wired (tracks per-flower freshness, removes expired stock on day advance)
- maxFlowers enforced in workspace with visual "Full" indicator
- Flower unlock progression (4 tiers, gates premium flowers behind day milestones)
- Persistence via shared_preferences (auto-saves on restock and day advance)
- Full UI redesign: dark garden green background, terracotta pot inventory shelves, wooden edge strip, bouquet workspace as wooden table
- Customer DM phone widget (`customer_phone.dart`): slides out from right edge, shows chat bubble with hint + vibe chips; auto-expands on new order
- Tutorial / onboarding (`tutorial_screen.dart`): 5-step Lily & Bud walkthrough, grants starter reward on completion
- Difficulty-tuned order generation: 4 tiers (`_earlyOrders`, `_midOrders`, `_lateOrders`, `_premiumOrders`) gated by day; mystery orders inject every 3–4 days late game
- Sound & haptics infrastructure: `AudioService` singleton fully wired; haptics in inventory shelf; **audio `.mp3` files still need to be dropped into `assets/audio/`**
- Filler / greens mechanic: `eucalyptus`, `fern`, `babys_breath`, `statice` marked as `isFiller: true`; green pot style in inventory shelf; 🌿 counter badge in workspace header; 5% scoring bonus (10% on `prefersGreens` orders) when ≥1 filler + ≥3 non-filler flowers are submitted

## UI Layout (game_screen.dart)

```
Scaffold > SparkleOverlay > Container(green gradient) > SafeArea > Stack:
  ├─ Column:
  │   ├─ _TopBar                (brown gradient header: title, day chip, money chip)
  │   ├─ AnimatedSwitcher       (result banner: fades/sizes in below top bar)
  │   ├─ SizedBox(172)          (InventoryShelf — terracotta pots on wooden shelves)
  │   ├─ _WoodenEdge            (18px wood-grain strip separating shelves from workspace)
  │   └─ Expanded               (_WorkspaceSection: BouquetWorkspace + SubmitBar)
  └─ Positioned(right:0)        (CustomerPhone — floating slide-out, centred vertically)
```

## Flower image assets

Drop PNG files into `assets/flowers/` named exactly by flower ID (e.g. `rose.png`, `daisy.png`).
Recommended: 256×256 px, transparent background. The app shows emoji as a fallback until a PNG exists.
See `assets/flowers/README.md` for the full filename list.

## Audio assets

Drop `.mp3` files into `assets/audio/`. The app runs silently without them — no crashes.
See `assets/audio/README.md` for the full filename list and recommended specs.

🔲 Remaining to implement:
- Nothing left from the original list — all four items are now done.
