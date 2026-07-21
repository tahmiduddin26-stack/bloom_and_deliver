import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/bouquet_order.dart';
import '../models/customer_profile.dart';
import '../models/flower.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class OrderPanel extends ConsumerWidget {
  const OrderPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(gameProvider.select((s) => s.currentOrder));
    final remaining = ref.watch(gameProvider.select((s) => s.ordersRemaining));

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        return SlideTransition(position: slide, child: FadeTransition(opacity: animation, child: child));
      },
      child: order == null
          ? const _AllDoneCard(key: ValueKey('done'))
          : _OrderCard(key: ValueKey(order.id), order: order, remaining: remaining),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final BouquetOrder order;
  final int remaining;

  const _OrderCard({super.key, required this.order, required this.remaining});

  @override
  Widget build(BuildContext context) {
    final headerColor = _moodColor(order.customer.mood);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: headerColor.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: headerColor.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(3, 6),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          _CustomerHeader(customer: order.customer, remaining: remaining, headerColor: headerColor),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.description,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.inkBrown,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SpeechBubble(text: order.hint, color: headerColor),
                  const SizedBox(height: 12),
                  _OrderRequirements(order: order),
                  const SizedBox(height: 12),
                  _PaymentBadge(basePayment: order.basePayment),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _moodColor(CustomerMood mood) => switch (mood) {
        CustomerMood.happy => AppColors.sunflowerGold,
        CustomerMood.excited => AppColors.pink,
        CustomerMood.neutral => AppColors.mint,
        CustomerMood.anxious => AppColors.terracotta,
        CustomerMood.sad => AppColors.lilac,
      };
}

class _CustomerHeader extends StatelessWidget {
  final CustomerProfile customer;
  final int remaining;
  final Color headerColor;

  const _CustomerHeader({
    required this.customer,
    required this.remaining,
    required this.headerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            headerColor.withValues(alpha: 0.35),
            headerColor.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Row(
        children: [
          _Portrait(customer: customer, borderColor: headerColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        customer.name,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: AppColors.inkBrown,
                        ),
                      ),
                    ),
                    if (customer.isRegular) ...[
                      const SizedBox(width: 5),
                      const _RegularBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(customer.mood.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      customer.mood.name[0].toUpperCase() +
                          customer.mood.name.substring(1),
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: AppColors.brownLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _QueueBadge(remaining: remaining, color: headerColor),
        ],
      ),
    );
  }
}

class _Portrait extends StatelessWidget {
  final CustomerProfile customer;
  final Color borderColor;

  const _Portrait({required this.customer, required this.borderColor});

  @override
  Widget build(BuildContext context) => Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.warmWhite,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(customer.portrait, style: const TextStyle(fontSize: 26)),
        ),
      );
}

class _RegularBadge extends StatelessWidget {
  const _RegularBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.mint.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.mint),
        ),
        child: Text(
          '⭐ Regular',
          style: GoogleFonts.nunito(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppColors.sageDark,
          ),
        ),
      );
}

class _QueueBadge extends StatelessWidget {
  final int remaining;
  final Color color;

  const _QueueBadge({required this.remaining, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Text(
              '$remaining',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.inkBrown,
              ),
            ),
            Text(
              'left',
              style: GoogleFonts.nunito(
                fontSize: 10,
                color: AppColors.brownLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

class _SpeechBubble extends StatelessWidget {
  final String text;
  final Color color;

  const _SpeechBubble({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // triangle tail pointing up-left toward portrait
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: CustomPaint(
              size: const Size(16, 9),
              painter: _TailPainter(color: AppColors.warmWhite, borderColor: color.withValues(alpha: 0.35)),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warmWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              text,
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                color: AppColors.brownDark,
                height: 1.45,
              ),
            ),
          ),
        ],
      );
}

class _TailPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  const _TailPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..color = color;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(_TailPainter old) =>
      old.color != color || old.borderColor != borderColor;
}

class _OrderRequirements extends StatelessWidget {
  final BouquetOrder order;

  const _OrderRequirements({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              'Vibes needed',
              style: GoogleFonts.nunito(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.brownLight,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 5,
          runSpacing: 6,
          children: order.requiredVibes.map(_VibeChip.new).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('🌸', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            Text(
              '${order.minFlowers}–${order.maxFlowers} flowers',
              style: GoogleFonts.nunito(
                fontSize: 11,
                color: AppColors.brownLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VibeChip extends StatelessWidget {
  final VibeTag vibe;

  const _VibeChip(this.vibe);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: vibe.color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: vibe.color.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: vibe.color.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: vibe.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              vibe.label,
              style: GoogleFonts.nunito(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.inkBrown,
              ),
            ),
          ],
        ),
      );
}

class _PaymentBadge extends StatelessWidget {
  final int basePayment;

  const _PaymentBadge({required this.basePayment});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.sunflowerGold.withValues(alpha: 0.2),
              AppColors.terracotta.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.sunflowerGold.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💰', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Up to \$${(basePayment * 1.3).round()}',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.sageDark,
                  ),
                ),
                Text(
                  'base \$$basePayment',
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    color: AppColors.brownLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _AllDoneCard extends StatelessWidget {
  const _AllDoneCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.pinkLight, AppColors.mintLight],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.pink.withValues(alpha: 0.4), width: 2),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'All orders done!',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.inkBrown,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'End of day summary coming up…',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: AppColors.brownLight,
                ),
              ),
            ],
          ),
        ),
      );
}
