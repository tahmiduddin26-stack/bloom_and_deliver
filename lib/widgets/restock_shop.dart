import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/flower_data.dart';
import '../models/flower.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

/// Full-screen restock shop shown between days.
/// Lets the player spend money to buy flowers before the next day starts.
class RestockShop extends ConsumerWidget {
  final VoidCallback onStartNextDay;

  const RestockShop({super.key, required this.onStartNextDay});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final nextDay = state.day + 1;
    final available = unlockedFlowers(state.day); // shop uses current day's unlocks
    final notifier = ref.read(gameProvider.notifier);

    // Flowers unlocking on next day (preview)
    final comingSoon = allFlowers
        .where((f) => f.unlockDay == nextDay)
        .toList();

    return Container(
      constraints: const BoxConstraints(maxWidth: 440, maxHeight: 680),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.brownDark.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          _ShopHeader(money: state.money, nextDay: nextDay),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              children: [
                _SectionLabel(label: '🌸 Available to Buy'),
                const SizedBox(height: 8),
                ...available.map((flower) {
                  final qty = state.inventory[flower.id] ?? 0;
                  final freshness = notifier.freshnessRemaining(flower.id);
                  final nearlyWilted = notifier.isNearlyWilted(flower.id);
                  return _ShopFlowerRow(
                    flower: flower,
                    currentQty: qty,
                    freshnessDays: freshness,
                    nearlyWilted: nearlyWilted,
                    canAfford: state.money >= flower.cost,
                    onBuyOne: () => notifier.restockFlower(flower.id, 1),
                    onBuyFive: () => notifier.restockFlower(flower.id, 5),
                  );
                }),
                if (comingSoon.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionLabel(label: '🔒 Unlocks Day $nextDay'),
                  const SizedBox(height: 8),
                  ...comingSoon.map((f) => _LockedFlowerRow(flower: f, unlockDay: f.unlockDay)),
                ],
              ],
            ),
          ),
          _ShopFooter(
            spentToday: state.restockSpentToday,
            money: state.money,
            nextDay: nextDay,
            onStartNextDay: onStartNextDay,
          ),
        ],
      ),
    );
  }
}

class _ShopHeader extends StatelessWidget {
  final int money;
  final int nextDay;

  const _ShopHeader({required this.money, required this.nextDay});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5C3A1E), Color(0xFF8B5E3C)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Row(
          children: [
            const Text('🛒', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Restock Shop',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warmWhite,
                    ),
                  ),
                  Text(
                    'Stock up before Day $nextDay',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppColors.cream,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.sunflowerGold.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.sunflowerGold.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💵', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '\$$money',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
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

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.brownLight,
          letterSpacing: 0.3,
        ),
      );
}

class _ShopFlowerRow extends StatelessWidget {
  final Flower flower;
  final int currentQty;
  final int? freshnessDays;
  final bool nearlyWilted;
  final bool canAfford;
  final VoidCallback onBuyOne;
  final VoidCallback onBuyFive;

  const _ShopFlowerRow({
    required this.flower,
    required this.currentQty,
    required this.freshnessDays,
    required this.nearlyWilted,
    required this.canAfford,
    required this.onBuyOne,
    required this.onBuyFive,
  });

  @override
  Widget build(BuildContext context) {
    final wiltColor = nearlyWilted ? Colors.red[400]! : AppColors.sageDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: nearlyWilted
            ? Colors.red.withValues(alpha: 0.06)
            : flower.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: nearlyWilted
              ? Colors.red.withValues(alpha: 0.3)
              : flower.color.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Text(flower.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      flower.name,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.inkBrown,
                      ),
                    ),
                    if (nearlyWilted) ...[
                      const SizedBox(width: 5),
                      const Text('⚠️', style: TextStyle(fontSize: 11)),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'In stock: $currentQty',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: AppColors.brownLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (freshnessDays != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        freshnessDays == 0
                            ? 'Wilts today!'
                            : 'Wilts in ${freshnessDays}d',
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          color: wiltColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Cost badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.sunflowerGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '\$${flower.cost}',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.inkBrown,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Buy +1
          _BuyButton(
            label: '+1',
            enabled: canAfford,
            onTap: onBuyOne,
          ),
          const SizedBox(width: 5),
          // Buy +5
          _BuyButton(
            label: '+5',
            enabled: canAfford,
            onTap: onBuyFive,
            accent: true,
          ),
        ],
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final bool accent;

  const _BuyButton({
    required this.label,
    required this.enabled,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = accent ? AppColors.brown : AppColors.brownLight;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: enabled
              ? bg.withValues(alpha: accent ? 0.9 : 0.15)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? bg.withValues(alpha: 0.5)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: enabled
                ? (accent ? AppColors.warmWhite : AppColors.inkBrown)
                : Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _LockedFlowerRow extends StatelessWidget {
  final Flower flower;
  final int unlockDay;

  const _LockedFlowerRow({required this.flower, required this.unlockDay});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Opacity(
              opacity: 0.35,
              child:
                  Text(flower.emoji, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                flower.name,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brownLight,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.lilac.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.lilac.withValues(alpha: 0.4)),
              ),
              child: Text(
                '🔒 Day $unlockDay',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brownLight,
                ),
              ),
            ),
          ],
        ),
      );
}

class _ShopFooter extends StatelessWidget {
  final int spentToday;
  final int money;
  final int nextDay;
  final VoidCallback onStartNextDay;

  const _ShopFooter({
    required this.spentToday,
    required this.money,
    required this.nextDay,
    required this.onStartNextDay,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.warmWhite,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: AppColors.brownDark.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (spentToday > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Spent on restock: ',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: AppColors.brownLight,
                      ),
                    ),
                    Text(
                      '-\$$spentToday',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.terracottaDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Remaining: ',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: AppColors.brownLight,
                      ),
                    ),
                    Text(
                      '\$$money',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.sageDark,
                      ),
                    ),
                  ],
                ),
              ),
            ElevatedButton.icon(
              onPressed: onStartNextDay,
              icon: const Text('🌅', style: TextStyle(fontSize: 18)),
              label: Text(
                'Start Day $nextDay',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ],
        ),
      );
}
