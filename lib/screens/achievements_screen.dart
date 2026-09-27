import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/feature_flags.dart';
import '../data/achievements_data.dart';
import '../models/achievement.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

void openAchievementsScreen(BuildContext context) {
  if (!Features.achievements) return;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _AchievementsSheet(),
  );
}

class _AchievementsSheet extends ConsumerWidget {
  const _AchievementsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(
      gameProvider.select((s) => s.unlockedAchievements),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.94,
      minChildSize: 0.4,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.brownLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.gardenGreenDark,
                    size: 27,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Achievements',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.gardenGreenDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE6A8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.cartoonInk,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '${unlocked.length} / ${allAchievements.length}',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.gardenGreenDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Grid
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 148,
                ),
                itemCount: allAchievements.length,
                itemBuilder: (context, i) {
                  final ach = allAchievements[i];
                  final isUnlocked = unlocked.contains(ach.id.name);
                  return _AchievementTile(
                    achievement: ach,
                    unlocked: isUnlocked,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Single achievement tile ────────────────────────────────────────────────────

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;

  const _AchievementTile({required this.achievement, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unlocked ? const Color(0xFFFFE6A8) : AppColors.warmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cartoonInk, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedOpacity(
                opacity: unlocked ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  achievement.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
              const Spacer(),
              if (unlocked)
                const Text(
                  '✓',
                  style: TextStyle(
                    color: AppColors.gardenGreenDark,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            unlocked ? achievement.title : '???',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: unlocked ? AppColors.gardenGreenDark : AppColors.brownDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Text(
              unlocked ? achievement.description : 'Keep playing to unlock',
              style: GoogleFonts.nunito(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: AppColors.brownDark,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
