import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/flower_data.dart';
import '../models/florist_rank.dart';
import '../models/flower.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/flower_image.dart';

/// Read-only statistics screen showing all-time shop performance.
class ShopStatsScreen extends ConsumerWidget {
  const ShopStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final favId = state.favoriteFlower;
    final Flower? favFlower = favId != null ? flowerById[favId] : null;
    final rank = state.rank;

    return Scaffold(
      backgroundColor: const Color(0xFF1A2C20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A3D2A),
        foregroundColor: Colors.white,
        title: Text(
          '📊  Shop Stats',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header card ─────────────────────────────────────────────────
            _HeaderCard(
              day: state.day,
              rankEmoji: rank.emoji,
              rankTitle: rank.title,
            ),
            const SizedBox(height: 14),

            // ── Earnings row ────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    emoji: '🪙',
                    label: 'All-Time Earned',
                    value: '\$${state.totalEarnings}',
                    color: AppColors.sunflowerGold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    emoji: '🏆',
                    label: 'Best Single Day',
                    value: '\$${state.bestDayEarnings}',
                    color: AppColors.sunflowerGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Order counts row ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    emoji: '🎀',
                    label: 'Bouquets Made',
                    value: '${state.totalOrdersServed}',
                    color: AppColors.carnationCoral,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    emoji: '🧑‍🤝‍🧑',
                    label: 'Customers Served',
                    value: '${state.totalOrdersServed}',
                    color: AppColors.carnationCoral,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Vibes & discoveries ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    emoji: '📓',
                    label: 'Vibes Discovered',
                    value: '${state.vibeDiscoveries.length} / 18',
                    color: AppColors.lavenderPurple,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    emoji: '⭐',
                    label: 'Reputation Score',
                    value: '${state.reputationScore}',
                    color: AppColors.lavenderPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Favorite flower ─────────────────────────────────────────────
            _FavoriteFlowerCard(
              flower: favFlower,
              useCount: favId != null
                  ? (state.allTimeFlowerUse[favId] ?? 0)
                  : 0,
            ),
            const SizedBox(height: 14),

            // ── Top 5 flowers ───────────────────────────────────────────────
            if (state.allTimeFlowerUse.isNotEmpty)
              _TopFlowersCard(flowerUse: state.allTimeFlowerUse),
          ],
        ),
      ),
    );
  }
}

// ── Header card ────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final int day;
  final String rankEmoji;
  final String rankTitle;

  const _HeaderCard({
    required this.day,
    required this.rankEmoji,
    required this.rankTitle,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3D2010), Color(0xFF6B3A1E)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(rankEmoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bloom & Deliver',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warmWhite,
                    ),
                  ),
                  Text(
                    rankTitle,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.sunflowerGold,
                    ),
                  ),
                  Text(
                    'Day $day',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── Generic stat card ──────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                color: Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

// ── Favorite flower card ───────────────────────────────────────────────────────

class _FavoriteFlowerCard extends StatelessWidget {
  final Flower? flower;
  final int useCount;

  const _FavoriteFlowerCard({required this.flower, required this.useCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Text('🌸', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Favourite Flower',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  flower != null ? flower!.name : 'None yet',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (useCount > 0)
                  Text(
                    'Used $useCount time${useCount == 1 ? '' : 's'}',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
              ],
            ),
          ),
          if (flower != null)
            FlowerImage(flower: flower!, size: 44),
        ],
      ),
    );
  }
}

// ── Top flowers leaderboard ────────────────────────────────────────────────────

class _TopFlowersCard extends StatelessWidget {
  final Map<String, int> flowerUse;

  const _TopFlowersCard({required this.flowerUse});

  @override
  Widget build(BuildContext context) {
    final sorted = flowerUse.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏵️  Most Used Flowers',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ...top.asMap().entries.map((e) {
            final rank = e.key + 1;
            final flowerId = e.value.key;
            final count = e.value.value;
            final flower = flowerById[flowerId];
            if (flower == null) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '#$rank',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: rank == 1
                            ? AppColors.sunflowerGold
                            : Colors.white38,
                      ),
                    ),
                  ),
                  FlowerImage(flower: flower, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      flower.name,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    '×$count',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Navigation helper ──────────────────────────────────────────────────────────

Future<void> openShopStatsScreen(BuildContext context) =>
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ShopStatsScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );
