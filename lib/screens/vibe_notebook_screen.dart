import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/flower.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

// All 18 vibes, grouped into 3 thematic chapters.
const _chapters = [
  _Chapter(
    title: 'Heart & Soul',
    emoji: '❤️',
    vibes: [
      VibeTag.romantic,
      VibeTag.soft,
      VibeTag.delicate,
      VibeTag.sympathy,
      VibeTag.cozy,
      VibeTag.elegant,
    ],
  ),
  _Chapter(
    title: 'Life & Energy',
    emoji: '🌿',
    vibes: [
      VibeTag.cheerful,
      VibeTag.vibrant,
      VibeTag.bold,
      VibeTag.wild,
      VibeTag.fresh,
      VibeTag.natural,
    ],
  ),
  _Chapter(
    title: 'Wonder & World',
    emoji: '✨',
    vibes: [
      VibeTag.mystical,
      VibeTag.luxurious,
      VibeTag.exotic,
      VibeTag.festive,
      VibeTag.rustic,
      VibeTag.traditional,
    ],
  ),
];

class _Chapter {
  final String title;
  final String emoji;
  final List<VibeTag> vibes;

  const _Chapter({
    required this.title,
    required this.emoji,
    required this.vibes,
  });
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class VibeNotebookScreen extends ConsumerWidget {
  const VibeNotebookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final discovered = state.vibeDiscoveries;
    final total = VibeTag.values.length;
    final found = discovered.length;

    return Scaffold(
      backgroundColor: AppColors.parchment,
      appBar: AppBar(
        backgroundColor: AppColors.brownDark,
        foregroundColor: AppColors.warmWhite,
        title: Text(
          '📓  Vibe Notebook',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.warmWhite,
          ),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // ── Progress header ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ProgressHeader(found: found, total: total),
          ),

          // ── Chapter sections ─────────────────────────────────────────────────
          for (final chapter in _chapters) ...[
            SliverToBoxAdapter(
              child: _ChapterHeader(chapter: chapter, discovered: discovered),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverGrid.count(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.1,
                children: chapter.vibes
                    .map((v) => _VibeCard(
                          vibe: v,
                          isDiscovered: discovered.contains(v.name),
                        ))
                    .toList(),
              ),
            ),
          ],

          // ── Completion bonus note ─────────────────────────────────────────────
          if (found == total)
            const SliverToBoxAdapter(
              child: _CompletionBanner(),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ── Progress header ────────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  final int found;
  final int total;

  const _ProgressHeader({required this.found, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = found / total;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brownLight.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brownDark.withValues(alpha: 0.06),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vibes Discovered',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.inkBrown,
                ),
              ),
              Text(
                '$found / $total',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.sageDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: AppColors.cream,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.sageDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            found == total
                ? '🌟 Complete collection! You\'ve found every vibe.'
                : 'Craft bouquets to unlock new vibe entries.',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: AppColors.brownLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chapter header ─────────────────────────────────────────────────────────────

class _ChapterHeader extends StatelessWidget {
  final _Chapter chapter;
  final Set<String> discovered;

  const _ChapterHeader({
    required this.chapter,
    required this.discovered,
  });

  @override
  Widget build(BuildContext context) {
    final chapterFound =
        chapter.vibes.where((v) => discovered.contains(v.name)).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Text(chapter.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              chapter.title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.inkBrown,
              ),
            ),
          ),
          Text(
            '$chapterFound / ${chapter.vibes.length}',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.brownLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vibe card ──────────────────────────────────────────────────────────────────

class _VibeCard extends StatelessWidget {
  final VibeTag vibe;
  final bool isDiscovered;

  const _VibeCard({required this.vibe, required this.isDiscovered});

  @override
  Widget build(BuildContext context) {
    final col = isDiscovered ? vibe.color : AppColors.cream;
    final textCol =
        isDiscovered ? Colors.white : AppColors.brownLight.withValues(alpha: 0.4);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isDiscovered
            ? col.withValues(alpha: 0.85)
            : AppColors.warmWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDiscovered
              ? col.withValues(alpha: 0.6)
              : AppColors.cream,
          width: isDiscovered ? 1.5 : 1,
        ),
        boxShadow: isDiscovered
            ? [
                BoxShadow(
                  color: col.withValues(alpha: 0.25),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isDiscovered)
            Text(
              _vibeEmoji(vibe),
              style: const TextStyle(fontSize: 22),
            )
          else
            Icon(Icons.lock_outline_rounded,
                size: 22,
                color: AppColors.brownLight.withValues(alpha: 0.25)),
          const SizedBox(height: 4),
          Text(
            isDiscovered ? vibe.label : '???',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textCol,
            ),
          ),
        ],
      ),
    );
  }

  String _vibeEmoji(VibeTag v) => switch (v) {
        VibeTag.romantic => '💕',
        VibeTag.soft => '🩷',
        VibeTag.delicate => '🌸',
        VibeTag.sympathy => '🕊️',
        VibeTag.cozy => '☕',
        VibeTag.elegant => '🪷',
        VibeTag.cheerful => '🌻',
        VibeTag.vibrant => '🎆',
        VibeTag.bold => '🔥',
        VibeTag.wild => '🌿',
        VibeTag.fresh => '💧',
        VibeTag.natural => '🍃',
        VibeTag.mystical => '🌙',
        VibeTag.luxurious => '✨',
        VibeTag.exotic => '🦜',
        VibeTag.festive => '🎊',
        VibeTag.rustic => '🍂',
        VibeTag.traditional => '🏵️',
      };
}

// ── Completion banner ──────────────────────────────────────────────────────────

class _CompletionBanner extends StatelessWidget {
  const _CompletionBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A5C3A), Color(0xFF1A3A25)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A5C3A).withValues(alpha: 0.35),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🌟', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vibe Master!',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You\'ve discovered all 18 vibes. Your floral intuition is unmatched.',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
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

// ── Navigation helper ──────────────────────────────────────────────────────────

void openVibeNotebook(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => const VibeNotebookScreen(),
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        );
      },
    ),
  );
}
