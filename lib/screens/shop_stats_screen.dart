import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/feature_flags.dart';
import '../data/flower_data.dart';
import '../models/florist_rank.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/flower_image.dart';

Future<void> openShopStatsScreen(BuildContext context) {
  if (!Features.shopStats) return Future<void>.value();
  return Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const ShopStatsScreen()));
}

class ShopStatsScreen extends ConsumerWidget {
  const ShopStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final favorite = state.favoriteFlower == null
        ? null
        : flowerById[state.favoriteFlower];
    final usedFlowers = state.allTimeFlowerUse.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.gardenGreenDark,
        foregroundColor: Colors.white,
        title: Text(
          'Shop Records',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFDCEBC6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cartoonInk, width: 2),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_florist_rounded,
                  color: AppColors.gardenGreenDark,
                  size: 42,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.rank.title,
                        style: GoogleFonts.nunito(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: AppColors.gardenGreenDark,
                        ),
                      ),
                      Text(
                        'Day ${state.day} in Bloomfield',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          color: AppColors.brownDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Your shop in numbers',
            style: GoogleFonts.nunito(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: AppColors.gardenGreenDark,
            ),
          ),
          const SizedBox(height: 10),
          _StatRow(
            first: _Stat(
              Icons.paid_rounded,
              'Coins earned',
              '\$${state.totalEarnings}',
            ),
            second: _Stat(
              Icons.stars_rounded,
              'Best day',
              '\$${state.bestDayEarnings}',
            ),
          ),
          _StatRow(
            first: _Stat(
              Icons.favorite_rounded,
              'Customers served',
              '${state.totalOrdersServed}',
            ),
            second: _Stat(
              Icons.star_rounded,
              'Journey stars',
              '${state.totalStars}',
            ),
          ),
          _StatRow(
            first: _Stat(
              Icons.auto_stories_rounded,
              'Vibes found',
              '${state.vibeDiscoveries.length} / 18',
            ),
            second: _Stat(
              Icons.workspace_premium_rounded,
              'Reputation',
              '${state.reputationScore}',
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5C0),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cartoonInk, width: 1.5),
            ),
            child: Row(
              children: [
                if (favorite != null)
                  FlowerImage(flower: favorite, size: 48)
                else
                  const Icon(
                    Icons.local_florist_outlined,
                    color: AppColors.gardenGreenDark,
                    size: 44,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Favourite flower',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          color: AppColors.brownDark,
                        ),
                      ),
                      Text(
                        favorite?.name ?? 'Make a bouquet to discover it',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.gardenGreenDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (usedFlowers.isNotEmpty) ...[
            const SizedBox(height: 21),
            Text(
              'Most used blooms',
              style: GoogleFonts.nunito(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: AppColors.gardenGreenDark,
              ),
            ),
            const SizedBox(height: 9),
            for (final entry in usedFlowers.take(5))
              if (flowerById[entry.key] != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warmWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cartoonInk, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      FlowerImage(flower: flowerById[entry.key]!, size: 32),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          flowerById[entry.key]!.name,
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w900,
                            color: AppColors.gardenGreenDark,
                          ),
                        ),
                      ),
                      Text(
                        '×${entry.value}',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w900,
                          color: AppColors.brownDark,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _Stat {
  final IconData icon;
  final String label;
  final String value;
  const _Stat(this.icon, this.label, this.value);
}

class _StatRow extends StatelessWidget {
  final _Stat first;
  final _Stat second;
  const _StatRow({required this.first, required this.second});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      children: [
        Expanded(child: _StatTile(stat: first)),
        const SizedBox(width: 9),
        Expanded(child: _StatTile(stat: second)),
      ],
    ),
  );
}

class _StatTile extends StatelessWidget {
  final _Stat stat;
  const _StatTile({required this.stat});

  @override
  Widget build(BuildContext context) => Container(
    height: 122,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.warmWhite,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.cartoonInk, width: 1.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(stat.icon, color: AppColors.gardenGreenDark, size: 22),
        Text(
          stat.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.gardenGreenDark,
          ),
        ),
        Text(
          stat.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.brownDark,
          ),
        ),
      ],
    ),
  );
}
