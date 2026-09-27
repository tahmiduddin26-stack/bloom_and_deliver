import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/feature_flags.dart';
import '../data/wholesale_data.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shop_scene.dart';
import 'vibe_notebook_screen.dart';

/// The town is a small, useful hub for places the player can actually visit.
void openTownMapScreen(
  BuildContext context, {
  VoidCallback? onGoToShop,
  VoidCallback? onGoToMarket,
  VoidCallback? onGoToWholesale,
}) {
  if (!Features.townMap) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => TownMapScreen(
        onGoToShop: onGoToShop,
        onGoToMarket: onGoToMarket,
        onGoToWholesale: onGoToWholesale,
      ),
    ),
  );
}

class TownMapScreen extends ConsumerWidget {
  final VoidCallback? onGoToShop;
  final VoidCallback? onGoToMarket;
  final VoidCallback? onGoToWholesale;

  const TownMapScreen({
    super.key,
    this.onGoToShop,
    this.onGoToMarket,
    this.onGoToWholesale,
  });

  void _visit(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => action());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.gardenGreenDark,
        foregroundColor: Colors.white,
        title: Text(
          'Bloomfield Town',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Container(
            height: 205,
            decoration: BoxDecoration(
              color: const Color(0xFFBFE4A5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.cartoonInk, width: 2.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _TownPainter()),
                ),
                Positioned(
                  left: 16,
                  top: 14,
                  child: _TownLabel(
                    day: state.day,
                    orders: state.totalOrdersServed,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: 270,
                    height: 132,
                    child: ShopScene(
                      upgrades: state.upgrades,
                      activeDecor: state.activeDecor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Where to, florist?',
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.gardenGreenDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Take a little walk around your flower-filled town.',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.brownDark,
            ),
          ),
          const SizedBox(height: 18),
          if (onGoToShop != null)
            _PlaceCard(
              icon: Icons.storefront_rounded,
              title: 'Your Flower Shop',
              subtitle: 'Grow flowers, decorate, and see your progress',
              color: const Color(0xFFFFE2AE),
              onTap: () => _visit(context, onGoToShop!),
            ),
          if (onGoToMarket != null)
            _PlaceCard(
              icon: Icons.local_florist_rounded,
              title: 'Bloomfield Market',
              subtitle: 'Restock fresh flowers for the next order',
              color: const Color(0xFFFFD7D8),
              onTap: () => _visit(context, onGoToMarket!),
            ),
          if (Features.vibeNotebook)
            _PlaceCard(
              icon: Icons.auto_stories_rounded,
              title: 'Flower Notebook',
              subtitle: 'Browse the moods you have discovered',
              color: const Color(0xFFE5D8F1),
              onTap: () => openVibeNotebook(context),
            ),
          if (Features.wholesale &&
              state.day >= wholesaleUnlockDay &&
              onGoToWholesale != null)
            _PlaceCard(
              icon: Icons.inventory_2_rounded,
              title: 'Wholesale Depot',
              subtitle: 'Buy bulk flowers for the shop',
              color: const Color(0xFFD9E9C2),
              onTap: () => _visit(context, onGoToWholesale!),
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warmWhite,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cartoonInk, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite_rounded, color: AppColors.petalCoral),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${state.totalOrdersServed} bouquets have brightened Bloomfield so far.',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800,
                      color: AppColors.gardenGreenDark,
                    ),
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

class _TownLabel extends StatelessWidget {
  final int day;
  final int orders;
  const _TownLabel({required this.day, required this.orders});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.warmWhite,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.cartoonInk, width: 1.5),
    ),
    child: Text(
      'Day $day  ·  $orders orders served',
      style: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: AppColors.gardenGreenDark,
      ),
    ),
  );
}

class _PlaceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _PlaceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(19),
        side: const BorderSide(color: AppColors.cartoonInk, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.warmWhite,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cartoonInk, width: 1.5),
                ),
                child: Icon(icon, color: AppColors.gardenGreenDark, size: 28),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.gardenGreenDark,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brownDark,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.cartoonInk,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TownPainter extends CustomPainter {
  const _TownPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final hill = Paint()..color = const Color(0xFF8DC67E);
    canvas.drawOval(
      Rect.fromLTWH(-40, size.height * .46, size.width * .8, 110),
      hill,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .42, size.height * .4, size.width * .8, 120),
      hill,
    );
    canvas.drawCircle(
      Offset(size.width - 36, 36),
      22,
      Paint()..color = AppColors.sunshine,
    );
    final path = Path()
      ..moveTo(-15, size.height)
      ..quadraticBezierTo(
        size.width * .25,
        size.height * .72,
        size.width * .45,
        size.height,
      )
      ..lineTo(size.width * .65, size.height)
      ..quadraticBezierTo(size.width * .34, size.height * .55, 15, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFEED6AC));
    for (final p in [
      Offset(28, size.height * .63),
      Offset(size.width - 30, size.height * .69),
      Offset(size.width - 67, size.height * .45),
    ]) {
      canvas.drawLine(
        p.translate(0, 7),
        p.translate(0, 17),
        Paint()
          ..color = AppColors.gardenGreenDark
          ..strokeWidth = 2,
      );
      for (var i = 0; i < 5; i++) {
        final angle = i * 1.256;
        canvas.drawCircle(
          p.translate(7 * math.cos(angle), 7 * math.sin(angle)),
          4,
          Paint()..color = i.isEven ? AppColors.petalCoral : AppColors.sunshine,
        );
      }
      canvas.drawCircle(p, 3, Paint()..color = AppColors.cartoonInk);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
