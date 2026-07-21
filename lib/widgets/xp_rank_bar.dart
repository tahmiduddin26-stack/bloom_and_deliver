import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/florist_rank.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class XpRankBar extends ConsumerWidget {
  const XpRankBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final rank = state.rank;
    final xp = state.xp;

    final isMax = rank.isMax;
    final bandXp = isMax ? rank.xpToNext : rank.xpInBand(xp);
    final bandMax = isMax ? 1 : rank.xpToNext;
    final progress = isMax ? 1.0 : (bandXp / bandMax).clamp(0.0, 1.0);

    // Rank colour palette
    final rankColor = _rankColor(rank);

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
      ),
      child: Row(
        children: [
          // Rank emoji badge
          Text(rank.emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          // Rank title
          Text(
            rank.title,
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: rankColor,
            ),
          ),
          const SizedBox(width: 8),
          // Progress bar
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  // Track
                  Container(
                    height: 7,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                  // Fill
                  AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    widthFactor: progress,
                    child: Container(
                      height: 7,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [rankColor, rankColor.withValues(alpha: 0.7)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: rankColor.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // XP label
          Text(
            isMax ? 'MAX' : '$xp XP',
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  static Color _rankColor(FloristRank rank) => switch (rank) {
        FloristRank.apprentice => AppColors.sage,
        FloristRank.florist => AppColors.mint,
        FloristRank.seniorFlorist => AppColors.sunflowerGold,
        FloristRank.masterFlorist => AppColors.carnationCoral,
        FloristRank.bloomLegend => const Color(0xFFD4AF37),
      };
}
