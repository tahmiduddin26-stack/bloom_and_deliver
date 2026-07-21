import 'package:flutter/material.dart';

import '../config/feature_flags.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/shop_decor_data.dart';
import '../models/shop_decoration.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

/// Full-screen shop decoration browser. Players browse categories via a tab
/// bar, preview items, and buy/equip them with coins.
class ShopDecorScreen extends ConsumerStatefulWidget {
  const ShopDecorScreen({super.key});

  @override
  ConsumerState<ShopDecorScreen> createState() => _ShopDecorScreenState();
}

class _ShopDecorScreenState extends ConsumerState<ShopDecorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  static const _categories = ShopDecorCategory.values;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A2C20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A3D2A),
        foregroundColor: Colors.white,
        title: Text(
          '🎨  Shop Decor',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '\$${state.money}',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.sunflowerGold,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.sunflowerGold,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
          tabs: _categories
              .map((c) => Tab(text: '${c.emoji} ${c.label}'))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: _categories
            .map((cat) => _CategoryGrid(category: cat))
            .toList(),
      ),
    );
  }
}

// ── Category grid ──────────────────────────────────────────────────────────────

class _CategoryGrid extends ConsumerWidget {
  final ShopDecorCategory category;

  const _CategoryGrid({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final items = decorForCategory(category);
    final activeId = state.activeDecorId(
      category.name,
      items.first.id, // default is always first
    );

    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final isActive = item.id == activeId;
        final isOwned = item.isDefault ||
            state.purchasedDecor.contains(item.id);

        return _DecorCard(
          item: item,
          isActive: isActive,
          isOwned: isOwned,
          money: state.money,
          onTap: () => _handleTap(context, ref, item, isOwned),
        );
      },
    );
  }

  void _handleTap(
    BuildContext context,
    WidgetRef ref,
    ShopDecoration item,
    bool isOwned,
  ) {
    final notifier = ref.read(gameProvider.notifier);
    if (isOwned) {
      notifier.equipDecor(item.category, item.id);
      AudioService.instance.play(GameSound.flowerDrop);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${item.name} equipped!',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
          ),
          backgroundColor: AppColors.gardenGreenMid,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      _showBuyDialog(context, ref, item);
    }
  }

  void _showBuyDialog(
    BuildContext context,
    WidgetRef ref,
    ShopDecoration item,
  ) {
    final state = ref.read(gameProvider);
    final canAfford = state.money >= item.cost;

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.parchment,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          item.name,
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: AppColors.inkBrown,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.description,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: AppColors.brownLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  '\$${item.cost}',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: canAfford
                        ? AppColors.sageDark
                        : AppColors.carnationCoral,
                  ),
                ),
              ],
            ),
            if (!canAfford) ...[
              const SizedBox(height: 6),
              Text(
                'You need \$${item.cost - state.money} more.',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: AppColors.carnationCoral,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(color: AppColors.brownLight),
            ),
          ),
          if (canAfford)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                final ok =
                    ref.read(gameProvider.notifier).purchaseDecor(item.id);
                if (ok) {
                  AudioService.instance.play(GameSound.coin);
                  // auto-equip on purchase
                  ref
                      .read(gameProvider.notifier)
                      .equipDecor(item.category, item.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${item.name} purchased & equipped!',
                        style:
                            GoogleFonts.nunito(fontWeight: FontWeight.w700),
                      ),
                      backgroundColor: AppColors.gardenGreenMid,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gardenGreenMid,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Buy  \$${item.cost}',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Decor card ─────────────────────────────────────────────────────────────────

class _DecorCard extends StatelessWidget {
  final ShopDecoration item;
  final bool isActive;
  final bool isOwned;
  final int money;
  final VoidCallback onTap;

  const _DecorCard({
    required this.item,
    required this.isActive,
    required this.isOwned,
    required this.money,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = money >= item.cost;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.gardenGreenMid.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? AppColors.gardenGreenMid
                : isOwned
                    ? Colors.white30
                    : Colors.white12,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Preview ────────────────────────────────────────────────────
            _DecorPreview(item: item),
            const SizedBox(height: 10),

            // ── Name ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                item.name,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),

            // ── Status badge ───────────────────────────────────────────────
            _StatusBadge(
              isActive: isActive,
              isOwned: isOwned,
              cost: item.cost,
              canAfford: canAfford,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Preview widget — renders a small visual of what the decor looks like ───────

class _DecorPreview extends StatelessWidget {
  final ShopDecoration item;

  const _DecorPreview({required this.item});

  @override
  Widget build(BuildContext context) {
    switch (item.category) {
      case ShopDecorCategory.wallpaper:
      case ShopDecorCategory.floorTile:
        final colors = item.gradientColors ??
            [const Color(0xFF2A3D2A), const Color(0xFF1A2C20)];
        return Container(
          width: 70,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
        );

      case ShopDecorCategory.counter:
        final color = item.accentColor ?? const Color(0xFF5C3A1E);
        return Container(
          width: 70,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
        );

      case ShopDecorCategory.windowPlant:
      case ShopDecorCategory.fairyLights:
      case ShopDecorCategory.windowDisplay:
        final emoji = item.decorEmoji ?? '';
        return SizedBox(
          height: 50,
          child: Center(
            child: Text(
              emoji.isEmpty ? '∅' : emoji,
              style: TextStyle(fontSize: emoji.isEmpty ? 20 : 36),
            ),
          ),
        );
    }
  }
}

// ── Status badge ───────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  final bool isOwned;
  final int cost;
  final bool canAfford;

  const _StatusBadge({
    required this.isActive,
    required this.isOwned,
    required this.cost,
    required this.canAfford,
  });

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      return _chip('✓ Equipped', AppColors.gardenGreenMid);
    }
    if (isOwned) {
      return _chip('Tap to equip', Colors.white38);
    }
    if (cost == 0) {
      return _chip('Free', AppColors.sageDark);
    }
    return _chip(
      '🪙 \$$cost',
      canAfford ? AppColors.sunflowerGold : AppColors.carnationCoral,
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      );
}

// ── Navigation helper ──────────────────────────────────────────────────────────

Future<void> openShopDecorScreen(BuildContext context) {
  if (!Features.shopDecor) return Future<void>.value();
  return Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ShopDecorScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );
}
