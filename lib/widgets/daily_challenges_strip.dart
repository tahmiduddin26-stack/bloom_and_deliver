import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/daily_challenge.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

/// A horizontally-scrollable row of the three daily challenge cards.
class DailyChallengesStrip extends ConsumerWidget {
  const DailyChallengesStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(
      gameProvider.select((s) => s.dailyChallenges),
    );
    if (challenges.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: challenges.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => _ChallengeCard(challenge: challenges[i]),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final DailyChallenge challenge;

  const _ChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final done = challenge.completed;
    final progress =
        (challenge.progress / challenge.target.clamp(1, 9999)).clamp(0.0, 1.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: 172,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: done
            ? const Color(0xFF3A9068).withValues(alpha: 0.8)
            : Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: done
              ? const Color(0xFF5DBB8A).withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.11),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Description + reward/done badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  challenge.description,
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: done ? 1.0 : 0.85),
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              done
                  ? const Text('✅', style: TextStyle(fontSize: 13))
                  : Text(
                      '+\$${challenge.reward}',
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.sunflowerGold,
                      ),
                    ),
            ],
          ),

          // Progress row
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Stack(
                  children: [
                    Container(
                      height: 5,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOutCubic,
                      widthFactor: done ? 1.0 : progress,
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: done
                                ? [
                                    Colors.white.withValues(alpha: 0.9),
                                    Colors.white.withValues(alpha: 0.6),
                                  ]
                                : [
                                    AppColors.sunflowerGold,
                                    AppColors.carnationCoral,
                                  ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                done
                    ? 'Complete! 🎉'
                    : '${challenge.progress} / ${challenge.target}',
                style: GoogleFonts.nunito(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
