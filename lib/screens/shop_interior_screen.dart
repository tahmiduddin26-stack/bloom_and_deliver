import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/feature_flags.dart';
import '../models/florist_rank.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shop_scene.dart';
import '../widgets/windowsill_plots.dart';
import 'achievements_screen.dart';
import 'shop_decor_screen.dart';
import 'shop_stats_screen.dart';
import 'upgrades_screen.dart';
import 'vibe_notebook_screen.dart';

Future<void> openShopInteriorScreen(BuildContext context) {
  if (!Features.shopInterior) return Future<void>.value();
  return Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const ShopInteriorScreen()));
}

/// Home for all the ways coins and playtime visibly improve the shop.
class ShopInteriorScreen extends ConsumerWidget {
  const ShopInteriorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.gardenGreenDark,
        foregroundColor: Colors.white,
        title: Text(
          'Your Flower Shop',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          Container(
            height: 178,
            decoration: BoxDecoration(
              color: AppColors.warmWhite,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.cartoonInk, width: 2.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: ShopScene(
              upgrades: state.upgrades,
              activeDecor: state.activeDecor,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ShopChip(
                icon: Icons.workspace_premium_rounded,
                label: state.rank.title,
              ),
              _ShopChip(
                icon: Icons.paid_rounded,
                label: '\$${state.money} coins',
              ),
              _ShopChip(
                icon: Icons.favorite_rounded,
                label: '${state.totalOrdersServed} served',
              ),
            ],
          ),
          const SizedBox(height: 23),
          _SectionHeading(
            title: 'Make it yours',
            subtitle: 'Every choice changes the little shop you see above.',
          ),
          if (Features.shopDecor)
            _ShopAction(
              icon: Icons.palette_rounded,
              title: 'Dress the Shop',
              subtitle: 'Wallpaper, counters, plants, lights and displays',
              color: const Color(0xFFFFD8DB),
              onTap: () => openShopDecorScreen(context),
            ),
          if (Features.upgrades)
            _ShopAction(
              icon: Icons.handyman_rounded,
              title: 'Shop Upgrades',
              subtitle: 'Useful tools that improve your working day',
              color: const Color(0xFFFFE2AE),
              onTap: () => openUpgradesScreen(context),
            ),
          const SizedBox(height: 15),
          _SectionHeading(
            title: 'Windowsill Garden',
            subtitle: 'Plant a seed, come back, and harvest a fresh flower.',
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFDDEBC5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cartoonInk, width: 2),
            ),
            child: const WindowsillPlots(),
          ),
          const SizedBox(height: 23),
          _SectionHeading(
            title: 'Your story',
            subtitle: 'Look back at the blooms and milestones you have earned.',
          ),
          if (Features.vibeNotebook)
            _ShopAction(
              icon: Icons.auto_stories_rounded,
              title: 'Flower Notebook',
              subtitle: 'The moods you have discovered in bouquets',
              color: const Color(0xFFE7DDF2),
              onTap: () => openVibeNotebook(context),
            ),
          if (Features.achievements)
            _ShopAction(
              icon: Icons.emoji_events_rounded,
              title: 'Achievements',
              subtitle: 'Celebrate your florist milestones',
              color: const Color(0xFFFFE2AE),
              onTap: () => openAchievementsScreen(context),
            ),
          if (Features.shopStats)
            _ShopAction(
              icon: Icons.insights_rounded,
              title: 'Shop Records',
              subtitle: 'Your orders, earnings, stars and favourite blooms',
              color: const Color(0xFFD9EACB),
              onTap: () => openShopStatsScreen(context),
            ),
        ],
      ),
    );
  }
}

class _ShopChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ShopChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.warmWhite,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: AppColors.cartoonInk, width: 1.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: AppColors.gardenGreenDark),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppColors.gardenGreenDark,
          ),
        ),
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 21,
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
  );
}

class _ShopAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ShopAction({
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
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.cartoonInk, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Icon(icon, size: 30, color: AppColors.gardenGreenDark),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.gardenGreenDark,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brownDark,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.cartoonInk,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
