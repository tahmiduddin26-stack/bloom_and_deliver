import 'dart:async';

import 'package:flutter/material.dart';

import '../config/feature_flags.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/flash_sale_data.dart';
import '../data/flower_data.dart';
import '../data/seasonal_events_data.dart';
import '../models/flower.dart';
import '../models/seasonal_event.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/flower_image.dart';
import '../widgets/tip_character.dart';
import 'wholesale_screen.dart';

class MarketScreen extends ConsumerStatefulWidget {
  /// Called when the player taps "Start Day N". When null the market opens in
  /// browse mode (e.g. visited from the town map) and the footer just closes.
  final VoidCallback? onStartNextDay;

  const MarketScreen({super.key, this.onStartNextDay});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideIn;

  bool _showTip = true;
  String _tipText = '';
  TipCharacterType _tipChar = TipCharacterType.florist;

  // Flash sale countdown ticker
  late Timer _countdownTimer;
  String _countdown = '';

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _slideIn = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideCtrl.forward();

    _countdown = flashSaleCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _countdown = flashSaleCountdown());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickTip();
      _fireFlashSaleNotification();
    });
  }

  void _pickTip() {
    final state = ref.read(gameProvider);
    final money = state.money;
    final day = state.day;
    final totalStock = state.inventory.values.fold(0, (a, b) => a + b);
    final nextUnlock = [3, 6, 10].firstWhere((d) => d > day, orElse: () => -1);

    String tip;
    TipCharacterType char;

    if (money < 25) {
      tip = "Your wallet's looking thin! Only buy what you really need — save some for tomorrow. 💸";
      char = TipCharacterType.helper;
    } else if (totalStock < 12) {
      tip = "Your shelves are almost empty! Stock up — customers hate seeing bare pots. 🪴";
      char = TipCharacterType.florist;
    } else if (nextUnlock != -1 && day == nextUnlock - 1) {
      tip = "New exotic flowers unlock tomorrow on Day $nextUnlock! Come back to the market then. ✨";
      char = TipCharacterType.florist;
    } else if (day == 1) {
      tip = "Welcome to the market! Buy a good mix of flowers — variety helps you match any vibe! 🌸";
      char = TipCharacterType.florist;
    } else {
      const tips = [
        ("Match stock to your regulars — they love their favourite flowers! ⭐", TipCharacterType.helper),
        ("Roses and tulips are great for romantic orders. Sunflowers for cheerful vibes! 🌻", TipCharacterType.florist),
        ("Buy at least 5 of each — you'll burn through stock faster than you think! 📦", TipCharacterType.helper),
        ("Lavender and baby's breath add elegance. Great for those mysterious customers. 💜", TipCharacterType.florist),
      ];
      final pick = tips[day % tips.length];
      tip = pick.$1;
      char = pick.$2;
    }

    setState(() {
      _tipText = tip;
      _tipChar = char;
    });
  }

  /// If there are active flash sales when the market opens, fire a push
  /// notification so the player knows even if they close the app.
  void _fireFlashSaleNotification() {
    final sales = activeFlashSales();
    if (sales.isEmpty) return;
    final flower = allFlowers.firstWhere(
      (f) => f.id == sales.first.flowerId,
      orElse: () => allFlowers.first,
    );
    NotificationService.instance.showFlashSaleNotification(flower.name);
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _countdownTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final activeEvent = eventForDay(state.day);
    final unlocked = unlockedFlowers(state.day);
    // Only show day-locked flowers in the teaser (event-exclusives are handled separately)
    final locked = allFlowers
        .where((f) => f.unlockDay > state.day && !f.isEventExclusive)
        .toList();

    // Compute clearance items once here so both banner and grid can use them
    final notifier = ref.read(gameProvider.notifier);
    final clearanceIds = state.inventory.keys
        .where((id) => notifier.isNearlyWilted(id) && (state.inventory[id] ?? 0) > 0)
        .toList();

    // Active flash sales
    final sales = activeFlashSales();

    return Scaffold(
      body: SlideTransition(
        position: _slideIn,
        child: Container(
          // Sandy market background
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF0DFA8),
                Color(0xFFE2C87A),
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _MarketHeader(
                      money: state.money,
                      day: state.day,
                      spent: state.restockSpentToday,
                    ),
                    // Green + cream striped awning
                    const _MarketAwning(),
                    // Flash sale banner (if any)
                    if (sales.isNotEmpty)
                      _FlashSaleBanner(sales: sales, countdown: _countdown),
                    // Flower display area
                    Expanded(
                      child: _FlowerGrid(
                        unlocked: unlocked,
                        locked: locked,
                        inventory: state.inventory,
                        money: state.money,
                        activeEvent: activeEvent,
                        flashSales: sales,
                        clearanceIds: clearanceIds,
                      ),
                    ),
                    // Wooden counter ledge
                    const _CounterLedge(),
                    // Footer
                    _MarketFooter(
                      spent: state.restockSpentToday,
                      // startNextDay jumps to the campaign frontier after a
                      // replay, so show the day it will actually start.
                      nextDay: state.nextLevel > state.day
                          ? state.nextLevel
                          : state.day + 1,
                      onStartDay: widget.onStartNextDay == null
                          ? null
                          : () {
                              AudioService.instance
                                  .play(GameSound.notification);
                              Navigator.of(context).pop();
                              widget.onStartNextDay!();
                            },
                      onClose: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                // Character tip — bottom left, above footer
                if (_showTip && _tipText.isNotEmpty)
                  Positioned(
                    left: 0,
                    bottom: 110,
                    child: TipCharacter(
                      character: _tipChar,
                      tip: _tipText,
                      onDismiss: () => setState(() => _showTip = false),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Flash sale banner ─────────────────────────────────────────────────────────

class _FlashSaleBanner extends StatelessWidget {
  final List<FlashSale> sales;
  final String countdown;

  const _FlashSaleBanner({required this.sales, required this.countdown});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8400A), Color(0xFFFF6B35)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FLASH SALE — 30% OFF',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  sales.map((s) => flowerById[s.flowerId]?.name ?? '').join(' & '),
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Countdown pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⏱', style: TextStyle(fontSize: 10)),
                const SizedBox(width: 3),
                Text(
                  countdown,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Market header ─────────────────────────────────────────────────────────────

class _MarketHeader extends StatelessWidget {
  final int money;
  final int day;
  final int spent;

  const _MarketHeader({
    required this.money,
    required this.day,
    required this.spent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C3A1E), Color(0xFF8B5E3C)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🛒', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Flower Market',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warmWhite,
                  ),
                ),
                Text(
                  'Day $day — Restock your shop',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: AppColors.cream.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          // Wholesale button
          if (Features.wholesale)
            GestureDetector(
              onTap: () => openWholesaleScreen(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.gardenGreenMid.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.gardenGreenMid.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏭', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 3),
                  Text(
                    'Wholesale',
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.warmWhite,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Money remaining
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.mint.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.mint.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💵', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(
                  '\$$money',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.warmWhite,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Awning ────────────────────────────────────────────────────────────────────

class _MarketAwning extends StatelessWidget {
  const _MarketAwning();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Row(
        children: List.generate(
          14,
          (i) => Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: i.isEven
                    ? const Color(0xFF4A8A5A)  // green stripe
                    : const Color(0xFFF5F0E8), // cream stripe
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Counter ledge ─────────────────────────────────────────────────────────────

class _CounterLedge extends StatelessWidget {
  const _CounterLedge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.shelfWoodLight,
            AppColors.shelfWoodMid,
            AppColors.shelfWoodDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(
          16,
          (_) => Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
              height: 1,
              color: AppColors.shelfWoodDark.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Flower grid ───────────────────────────────────────────────────────────────

class _FlowerGrid extends StatelessWidget {
  final List<Flower> unlocked;
  final List<Flower> locked;
  final Map<String, int> inventory;
  final int money;
  final SeasonalEvent? activeEvent;
  final List<FlashSale> flashSales;
  final List<String> clearanceIds;

  const _FlowerGrid({
    required this.unlocked,
    required this.locked,
    required this.inventory,
    required this.money,
    this.activeEvent,
    required this.flashSales,
    required this.clearanceIds,
  });

  @override
  Widget build(BuildContext context) {
    // Split into regular and event-exclusive buckets
    final regular = unlocked.where((f) => !f.isEventExclusive).toList();
    final eventFlowers = unlocked.where((f) => f.isEventExclusive).toList();
    final hasEvent = eventFlowers.isNotEmpty && activeEvent != null;

    // Build flash sale lookup map for quick access
    final saleMap = {for (final s in flashSales) s.flowerId: s};

    // Item list: regular flowers, optional teaser, optional event section header + flowers
    final items = <_GridItem>[
      for (final f in regular)
        _GridItem.flower(f, inventory[f.id] ?? 0, money >= (saleMap[f.id]?.discountedCost ?? f.cost),
            sale: saleMap[f.id]),
      if (locked.isNotEmpty)
        _GridItem.lockedTeaser(locked.first.unlockDay, locked.take(3).toList()),
      if (hasEvent) ...[
        _GridItem.eventHeader(activeEvent!),
        for (final f in eventFlowers)
          _GridItem.flower(f, inventory[f.id] ?? 0, money >= f.cost, isEvent: true),
      ],
    ];

    final hasClearance = clearanceIds.isNotEmpty;

    return Container(
      color: const Color(0xFFD4B87A).withValues(alpha: 0.4),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 110,
                crossAxisSpacing: 10,
                mainAxisSpacing: 14,
                childAspectRatio: 0.62,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                return switch (item.type) {
                  // FittedBox: the bucket's content is fixed-size, so scale it
                  // down instead of overflowing on narrow grid cells.
                  _GridItemType.flower => Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _FlowerBucket(
                          flower: item.flower!,
                          currentStock: item.stock!,
                          canAfford: item.canAfford!,
                          isEventExclusive: item.isEvent,
                          flashSale: item.sale,
                        ),
                      ),
                    ),
                  _GridItemType.lockedTeaser => _LockedTeaser(
                      nextUnlockDay: item.nextUnlockDay!,
                      previewFlowers: item.previewFlowers!,
                    ),
                  _GridItemType.eventHeader => _EventSectionHeader(
                      event: item.event!,
                    ),
                };
              },
            ),
          ),
          // Clearance section
          if (hasClearance)
            SliverToBoxAdapter(
              child: _ClearanceSection(clearanceIds: clearanceIds),
            ),
          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
        ],
      ),
    );
  }
}

enum _GridItemType { flower, lockedTeaser, eventHeader }

class _GridItem {
  final _GridItemType type;
  final Flower? flower;
  final int? stock;
  final bool? canAfford;
  final bool isEvent;
  final int? nextUnlockDay;
  final List<Flower>? previewFlowers;
  final SeasonalEvent? event;
  final FlashSale? sale;

  const _GridItem._({
    required this.type,
    this.flower,
    this.stock,
    this.canAfford,
    this.isEvent = false,
    this.nextUnlockDay,
    this.previewFlowers,
    this.event,
    this.sale,
  });

  factory _GridItem.flower(Flower f, int stock, bool canAfford,
          {bool isEvent = false, FlashSale? sale}) =>
      _GridItem._(
        type: _GridItemType.flower,
        flower: f,
        stock: stock,
        canAfford: canAfford,
        isEvent: isEvent,
        sale: sale,
      );

  factory _GridItem.lockedTeaser(int nextDay, List<Flower> preview) =>
      _GridItem._(
        type: _GridItemType.lockedTeaser,
        nextUnlockDay: nextDay,
        previewFlowers: preview,
      );

  factory _GridItem.eventHeader(SeasonalEvent event) =>
      _GridItem._(type: _GridItemType.eventHeader, event: event);
}

// ── Event section header (spans full grid width via aspect ratio trick) ────────

class _EventSectionHeader extends StatelessWidget {
  final SeasonalEvent event;

  const _EventSectionHeader({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: event.backgroundGradient),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${event.emoji} ${event.name}',
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        maxLines: 2,
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Clearance section ─────────────────────────────────────────────────────────

class _ClearanceSection extends ConsumerWidget {
  final List<String> clearanceIds;

  const _ClearanceSection({required this.clearanceIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    // Re-filter so UI reacts as items are sold
    final active = clearanceIds
        .where((id) => (state.inventory[id] ?? 0) > 0 && notifier.isNearlyWilted(id))
        .toList();

    if (active.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8C00), Color(0xFFFFB347)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                const Text('🍂', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CLEARANCE',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        'Near-wilted stock — sell at 50% back',
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Clearance items
          ...active.map((id) {
            final flower = flowerById[id];
            if (flower == null) return const SizedBox.shrink();
            final qty = state.inventory[id] ?? 0;
            final salePrice = (flower.cost * 0.5).round();

            return _ClearanceRow(
              flower: flower,
              qty: qty,
              salePrice: salePrice,
              onSellAll: () {
                HapticFeedback.lightImpact();
                if (notifier.sellClearance(id, qty)) {
                  AudioService.instance.play(GameSound.coin);
                }
              },
              onSellOne: () {
                HapticFeedback.selectionClick();
                if (notifier.sellClearance(id, 1)) {
                  AudioService.instance.play(GameSound.coin);
                }
              },
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ClearanceRow extends StatelessWidget {
  final Flower flower;
  final int qty;
  final int salePrice;
  final VoidCallback onSellAll;
  final VoidCallback onSellOne;

  const _ClearanceRow({
    required this.flower,
    required this.qty,
    required this.salePrice,
    required this.onSellAll,
    required this.onSellOne,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFFF9800).withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          FlowerImage(flower: flower, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  flower.name,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkBrown,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '\$${flower.cost}',
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        color: AppColors.brownLight,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.brownLight,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '→ \$$salePrice ea',
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        color: const Color(0xFFE65100),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$qty left',
                        style: GoogleFonts.nunito(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Sell buttons
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SellBtn(label: 'Sell 1', onTap: onSellOne),
              const SizedBox(height: 4),
              _SellBtn(label: 'Sell All', onTap: onSellAll, primary: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _SellBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const _SellBtn({required this.label, required this.onTap, this.primary = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: primary
              ? const Color(0xFFE65100)
              : const Color(0xFFFF9800).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: primary
              ? null
              : Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: primary ? Colors.white : const Color(0xFFE65100),
          ),
        ),
      ),
    );
  }
}

// ── Flower bucket card ────────────────────────────────────────────────────────

class _FlowerBucket extends ConsumerStatefulWidget {
  final Flower flower;
  final int currentStock;
  final bool canAfford;
  final bool isEventExclusive;
  final FlashSale? flashSale;

  const _FlowerBucket({
    required this.flower,
    required this.currentStock,
    required this.canAfford,
    this.isEventExclusive = false,
    this.flashSale,
  });

  @override
  ConsumerState<_FlowerBucket> createState() => _FlowerBucketState();
}

class _FlowerBucketState extends ConsumerState<_FlowerBucket>
    with SingleTickerProviderStateMixin {
  late final AnimationController _popCtrl;
  late final Animation<double> _pop;

  @override
  void initState() {
    super.initState();
    _popCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pop = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _popCtrl, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _popCtrl.dispose();
    super.dispose();
  }

  void _buy(int qty) {
    HapticFeedback.lightImpact();
    final costPerUnit = widget.flashSale?.discountedCost;
    final success = ref.read(gameProvider.notifier).restockFlower(
          widget.flower.id,
          qty,
          costPerUnit: costPerUnit,
        );
    if (success) {
      AudioService.instance.play(GameSound.coin);
      _popCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stock = ref.watch(
      gameProvider.select((s) => s.inventory[widget.flower.id] ?? 0),
    );
    final money = ref.watch(gameProvider.select((s) => s.money));
    final effectiveCost =
        widget.flashSale?.discountedCost ?? widget.flower.cost;
    final canBuy1 = money >= effectiveCost;
    final canBuy5 = money >= effectiveCost * 5;
    final onSale = widget.flashSale != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Flower emoji above bucket (with event sparkle badge if exclusive)
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            ScaleTransition(
              scale: _pop,
              child: FlowerImage(flower: widget.flower, size: 38),
            ),
            if (widget.isEventExclusive)
              Positioned(
                top: -4,
                right: -6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE67E22),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('✨',
                      style: TextStyle(fontSize: 8)),
                ),
              ),
            // 🔥 flash sale badge
            if (onSale)
              Positioned(
                top: -4,
                left: -6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8400A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('🔥',
                      style: TextStyle(fontSize: 8)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        // Metal bucket
        Container(
          width: 58,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: onSale
                  ? const [Color(0xFF7A3A1E), Color(0xFF4A1E0E)]
                  : const [Color(0xFF6A6A6A), Color(0xFF3A3A3A)],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$stock',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: stock > 0 ? Colors.white : Colors.white38,
                ),
              ),
              Text(
                'in stock',
                style: GoogleFonts.nunito(
                  fontSize: 7.5,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
        // Bucket rim
        Container(
          width: 64,
          height: 7,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: onSale
                  ? const [Color(0xFFAA5533), Color(0xFF7A3322)]
                  : const [Color(0xFF888888), Color(0xFF555555)],
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 4),
        // Flower name
        Text(
          widget.flower.name,
          style: GoogleFonts.nunito(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: AppColors.inkBrown,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Price — strikethrough original + sale price when on sale
        if (onSale) ...[
          Text(
            '\$${widget.flower.cost} ea',
            style: GoogleFonts.nunito(
              fontSize: 8,
              color: AppColors.brownLight.withValues(alpha: 0.6),
              decoration: TextDecoration.lineThrough,
              decorationColor: AppColors.brownLight,
            ),
          ),
          Text(
            '\$${widget.flashSale!.discountedCost} ea',
            style: GoogleFonts.nunito(
              fontSize: 9.5,
              color: const Color(0xFFE8400A),
              fontWeight: FontWeight.w800,
            ),
          ),
        ] else
          Text(
            '\$${widget.flower.cost} ea',
            style: GoogleFonts.nunito(
              fontSize: 9,
              color: AppColors.brownDark.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 4),
        // Buy buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _BuyBtn(label: '+1', enabled: canBuy1, onTap: () => _buy(1)),
            const SizedBox(width: 4),
            _BuyBtn(label: '+5', enabled: canBuy5, onTap: () => _buy(5)),
          ],
        ),
      ],
    );
  }
}

class _BuyBtn extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _BuyBtn({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.gardenGreenMid
              : AppColors.brownLight.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.gardenGreenMid.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: enabled ? Colors.white : Colors.white38,
          ),
        ),
      ),
    );
  }
}

// ── Locked teaser card ────────────────────────────────────────────────────────

class _LockedTeaser extends StatelessWidget {
  final int nextUnlockDay;
  final List<Flower> previewFlowers;

  const _LockedTeaser({
    required this.nextUnlockDay,
    required this.previewFlowers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.brownDark.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.brownLight.withValues(alpha: 0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔒', style: TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: previewFlowers
                .map((f) => Opacity(
                      opacity: 0.3,
                      child: FlowerImage(flower: f, size: 20),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          Text(
            'Day $nextUnlockDay',
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.brownLight,
            ),
          ),
          Text(
            'new arrivals',
            style: GoogleFonts.nunito(
              fontSize: 8.5,
              color: AppColors.brownLight.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Market footer ─────────────────────────────────────────────────────────────

class _MarketFooter extends StatelessWidget {
  final int spent;
  final int nextDay;
  final VoidCallback? onStartDay;
  final VoidCallback onClose;

  const _MarketFooter({
    required this.spent,
    required this.nextDay,
    required this.onStartDay,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Spent today
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spent today',
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    color: AppColors.brownLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '-\$$spent',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: spent > 0 ? AppColors.potTerracottaDark : AppColors.brownLight,
                  ),
                ),
              ],
            ),
          ),
          // Start next day button (or plain close in browse mode)
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: onStartDay ?? onClose,
              icon: Text(onStartDay != null ? '🌅' : '🌷',
                  style: const TextStyle(fontSize: 18)),
              label: Text(
                onStartDay != null ? 'Start Day $nextDay →' : 'Done  ✓',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 52),
                backgroundColor: AppColors.gardenGreenMid,
                foregroundColor: Colors.white,
                shadowColor: AppColors.gardenGreenDark.withValues(alpha: 0.5),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Push the market screen on top of the current route.
/// Omit [onStartNextDay] to open in browse mode (restock only, no day change).
Future<void> openMarketScreen(
  BuildContext context, {
  VoidCallback? onStartNextDay,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) =>
          MarketScreen(onStartNextDay: onStartNextDay),
      transitionsBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 420),
    ),
  );
}
