import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/level_data.dart';
import '../models/bouquet_order.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import 'customer_avatar.dart';

/// Day summary dialog. After reviewing results the player taps one of the
/// footer buttons (big commission, deliveries, or market) to continue.
class EndOfDayDialog extends ConsumerWidget {
  final VoidCallback onGoToMarket;
  final VoidCallback? onGoToDeliveries;
  final VoidCallback? onGoToBigOrder;

  const EndOfDayDialog({
    super.key,
    required this.onGoToMarket,
    this.onGoToDeliveries,
    this.onGoToBigOrder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: _SummaryPage(
        onGoToMarket: () {
          Navigator.of(context).pop();
          onGoToMarket();
        },
        onGoToDeliveries: onGoToDeliveries == null
            ? null
            : () {
                Navigator.of(context).pop();
                onGoToDeliveries!();
              },
        onGoToBigOrder: onGoToBigOrder == null
            ? null
            : () {
                Navigator.of(context).pop();
                onGoToBigOrder!();
              },
      ),
    );
  }
}

// ── Summary page ──────────────────────────────────────────────────────────────

class _SummaryPage extends ConsumerWidget {
  final VoidCallback onGoToMarket;
  final VoidCallback? onGoToDeliveries;
  final VoidCallback? onGoToBigOrder;

  const _SummaryPage({
    required this.onGoToMarket,
    this.onGoToDeliveries,
    this.onGoToBigOrder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final completed = state.completedToday;
    final earnings = state.dayEarnings;

    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      height: (MediaQuery.sizeOf(context).height - 48).clamp(0.0, 600.0),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.cartoonInk, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.brownDark.withValues(alpha: 0.3),
            blurRadius: 0,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _Header(day: state.day),
                _LevelStarsBanner(
                  level: levelForDay(state.day),
                  earnings: earnings,
                ),
                _EarningsBanner(earnings: earnings, total: state.money),
                _OrderSummaryList(completed: completed),
                const SizedBox(height: 12),
              ],
            ),
          ),
          _SummaryFooter(
            onGoToMarket: onGoToMarket,
            onGoToDeliveries: onGoToDeliveries,
            onGoToBigOrder: onGoToBigOrder,
            deliveryCount: onGoToDeliveries == null
                ? 0
                : state.pendingDeliveries.where((d) => !d.isCompleted).length,
            activeBigOrderName:
                (state.activeBigOrder?.canContributeOn(state.day) ?? false)
                ? state.activeBigOrder!.name
                : null,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int day;

  const _Header({required this.day});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
    decoration: const BoxDecoration(
      color: AppColors.gardenGreenDark,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.local_florist_rounded,
          color: AppColors.sunshine,
          size: 32,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'End of Day $day',
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.warmWhite,
                ),
              ),
              Text(
                'Bloom & Deliver — Daily Summary',
                style: GoogleFonts.nunito(fontSize: 12, color: AppColors.cream),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ── Level stars banner ────────────────────────────────────────────────────────

class _LevelStarsBanner extends StatelessWidget {
  final LevelDef level;
  final int earnings;

  const _LevelStarsBanner({required this.level, required this.earnings});

  @override
  Widget build(BuildContext context) {
    final stars = level.starsFor(earnings);
    final nextGoal = stars >= 3
        ? null
        : stars == 2
        ? level.star3Earnings
        : stars == 1
        ? level.star2Earnings
        : level.star1Earnings;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDEE2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cartoonInk, width: 2),
      ),
      child: Column(
        children: [
          if (stars == 0)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                'Almost! Restock and retry this level.',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          Text(
            '${level.emoji}  Level ${level.number} — ${level.title}',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.inkBrown,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final filled = i < stars;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 36,
                  color: filled
                      ? AppColors.sunflowerGold
                      : AppColors.brownLight,
                ),
              );
            }),
          ),
          if (nextGoal != null) ...[
            const SizedBox(height: 4),
            Text(
              stars == 0
                  ? 'Earn \$$nextGoal to pass. Restock and try again!'
                  : 'Earn \$$nextGoal for ${stars + 1} stars. Replay from the map!',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.brownLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EarningsBanner extends StatelessWidget {
  final int earnings;
  final int total;

  const _EarningsBanner({required this.earnings, required this.total});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.sage.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.sage.withValues(alpha: 0.4)),
    ),
    child: Row(
      children: [
        Expanded(
          child: _Stat(
            label: "Today's Earnings",
            value: '+\$$earnings',
            positive: true,
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: AppColors.brownLight.withValues(alpha: 0.3),
        ),
        Expanded(
          child: _Stat(label: 'Total Cash', value: '\$$total', positive: null),
        ),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final bool? positive;

  const _Stat({
    required this.label,
    required this.value,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: positive == true
              ? AppColors.sageDark
              : positive == false
              ? Colors.red
              : AppColors.inkBrown,
        ),
      ),
      Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
          fontSize: 11,
          color: AppColors.brownLight,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _OrderSummaryList extends StatelessWidget {
  final List<(BouquetOrder, int)> completed;

  const _OrderSummaryList({required this.completed});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      children: [
        for (var i = 0; i < completed.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          _OrderRow(order: completed[i].$1, earned: completed[i].$2),
        ],
      ],
    ),
  );
}

class _OrderRow extends StatelessWidget {
  final BouquetOrder order;
  final int earned;

  const _OrderRow({required this.order, required this.earned});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (order.result) {
      OrderResult.great => ('🌟', AppColors.sunflowerGold, 'Great!'),
      OrderResult.good => ('✅', AppColors.sage, 'Good'),
      OrderResult.poor => ('😔', AppColors.carnationCoral, 'Poor'),
      _ => ('⏳', AppColors.brownLight, 'Pending'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cartoonInk, width: 1.5),
      ),
      child: Row(
        children: [
          CustomerAvatar(name: order.customer.name, size: 30),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      order.customer.name,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkBrown,
                      ),
                    ),
                    if (order.customer.isRegular) ...[
                      const SizedBox(width: 4),
                      Text('⭐', style: const TextStyle(fontSize: 11)),
                    ],
                  ],
                ),
                Text(
                  order.description,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: AppColors.brownLight,
                  ),
                ),
              ],
            ),
          ),
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+\$$earned',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.sageDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryFooter extends StatelessWidget {
  final VoidCallback onGoToMarket;
  final VoidCallback? onGoToDeliveries;
  final VoidCallback? onGoToBigOrder;
  final int deliveryCount;
  final String? activeBigOrderName;

  const _SummaryFooter({
    required this.onGoToMarket,
    required this.deliveryCount,
    this.onGoToDeliveries,
    this.onGoToBigOrder,
    this.activeBigOrderName,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
    child: Column(
      children: [
        // Big commission button (only if a commission is awaiting contribution)
        if (activeBigOrderName != null && onGoToBigOrder != null) ...[
          GestureDetector(
            onTap: onGoToBigOrder,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE2AE),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.cartoonInk, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💒', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      activeBigOrderName!,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.gardenGreenDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        // Deliveries button (only if missions available)
        if (deliveryCount > 0) ...[
          GestureDetector(
            onTap: onGoToDeliveries,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFDCEBC6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.cartoonInk, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🚲', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Evening Deliveries ($deliveryCount)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.gardenGreenDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        ElevatedButton.icon(
          onPressed: onGoToMarket,
          icon: const Text('🌷', style: TextStyle(fontSize: 18)),
          label: Text(
            'Visit the Market →',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            backgroundColor: AppColors.gardenGreenMid,
            foregroundColor: Colors.white,
            shadowColor: AppColors.gardenGreenDark.withValues(alpha: 0.5),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ],
    ),
  );
}

// Convenience: show the dialog.
Future<void> showEndOfDayDialog(
  BuildContext context, {
  required VoidCallback onGoToMarket,
  VoidCallback? onGoToDeliveries,
  VoidCallback? onGoToBigOrder,
}) => showDialog(
  context: context,
  barrierDismissible: false,
  builder: (_) => EndOfDayDialog(
    onGoToMarket: onGoToMarket,
    onGoToDeliveries: onGoToDeliveries,
    onGoToBigOrder: onGoToBigOrder,
  ),
);
