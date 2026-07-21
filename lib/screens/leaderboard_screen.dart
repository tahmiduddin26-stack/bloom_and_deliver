import 'package:flutter/material.dart';

import '../config/feature_flags.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

// ── Leaderboard screen (Tier 8) ───────────────────────────────────────────────
//
// A personal-records / local leaderboard screen.
// Shows a fictional top-10 of Bloomfield florists with the player
// interpolated at the correct position based on their score.
// "Score" = money earned + 10× deliveries completed + 5× great orders.

void openLeaderboardScreen(BuildContext context) {
  if (!Features.leaderboard) return;
  Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => const LeaderboardScreen(),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  );
}

// ── Fictional competitors ─────────────────────────────────────────────────────

class _Competitor {
  final String name;
  final String shopName;
  final String emoji;
  final int score;

  const _Competitor({
    required this.name,
    required this.shopName,
    required this.emoji,
    required this.score,
  });
}

const _competitors = [
  _Competitor(
    name: 'Rosie Thorn',
    shopName: 'Thorn & Petal',
    emoji: '🌹',
    score: 4800,
  ),
  _Competitor(
    name: 'Daisy Bloom',
    shopName: 'Daisy\'s Meadow',
    emoji: '🌼',
    score: 4200,
  ),
  _Competitor(
    name: 'Violet Marsh',
    shopName: 'Violet\'s Garden',
    emoji: '💜',
    score: 3750,
  ),
  _Competitor(
    name: 'Iris Chen',
    shopName: 'Blue Iris Studio',
    emoji: '🪻',
    score: 3300,
  ),
  _Competitor(
    name: 'Poppy Field',
    shopName: 'Poppy & Co.',
    emoji: '🌺',
    score: 2900,
  ),
  _Competitor(
    name: 'Fern Green',
    shopName: 'The Fern House',
    emoji: '🌿',
    score: 2500,
  ),
  _Competitor(
    name: 'Lily Moss',
    shopName: 'Mossy Lane Florals',
    emoji: '🌸',
    score: 2100,
  ),
  _Competitor(
    name: 'Sage Winter',
    shopName: 'Winter Bloom',
    emoji: '❄️',
    score: 1700,
  ),
  _Competitor(
    name: 'Blossom Hart',
    shopName: 'Hart\'s Garden',
    emoji: '🌷',
    score: 1300,
  ),
  _Competitor(
    name: 'Reed Stone',
    shopName: 'Stonefield Flowers',
    emoji: '🪨',
    score: 900,
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  /// score = money + 10 × orders served + reputation score
  int _playerScore(int money, int ordersServed, int repScore) =>
      money + ordersServed * 10 + repScore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final playerScore = _playerScore(
      state.money,
      state.totalOrdersServed,
      state.reputationScore,
    );

    // Build combined list of competitors + player, sorted descending.
    final entries = <_LeaderEntry>[
      for (final c in _competitors)
        _LeaderEntry(
          name: c.name,
          shopName: c.shopName,
          emoji: c.emoji,
          score: c.score,
          isPlayer: false,
        ),
      _LeaderEntry(
        name: 'You',
        shopName: 'Bloom & Deliver',
        emoji: '🌸',
        score: playerScore,
        isPlayer: true,
      ),
    ]..sort((a, b) => b.score.compareTo(a.score));

    final playerRank = entries.indexWhere((e) => e.isPlayer) + 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B3A2A), Color(0xFF2D5438), Color(0xFF1A2E20)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white70, size: 20),
                    ),
                    Text(
                      '🏅  Bloomfield Rankings',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ── Player rank summary card ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2D5438), Color(0xFF3A6B47)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.gardenGreenMid.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gardenGreenMid.withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Rank badge
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color:
                              AppColors.sunflowerGold.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.sunflowerGold
                                .withValues(alpha: 0.60),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '#$playerRank',
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.sunflowerGold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bloom & Deliver',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Score: $playerScore pts',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF7CFC88),
                              ),
                            ),
                            Text(
                              '📦 ${state.totalOrdersServed} orders  '
                              '⭐ ${state.reputationScore} rep',
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── Score formula hint ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Score = money + 10 × orders served + reputation',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: Colors.white38,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── Leaderboard list ─────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: entries.length,
                  itemBuilder: (_, i) {
                    final entry = entries[i];
                    final rank = i + 1;
                    return _LeaderRow(
                      rank: rank,
                      entry: entry,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Entry model ───────────────────────────────────────────────────────────────

class _LeaderEntry {
  final String name;
  final String shopName;
  final String emoji;
  final int score;
  final bool isPlayer;

  _LeaderEntry({
    required this.name,
    required this.shopName,
    required this.emoji,
    required this.score,
    required this.isPlayer,
  });
}

// ── Row widget ────────────────────────────────────────────────────────────────

class _LeaderRow extends StatelessWidget {
  final int rank;
  final _LeaderEntry entry;

  const _LeaderRow({required this.rank, required this.entry});

  Color get _rankColor {
    if (rank == 1) return const Color(0xFFFFD700); // gold
    if (rank == 2) return const Color(0xFFC0C0C0); // silver
    if (rank == 3) return const Color(0xFFCD7F32); // bronze
    return Colors.white38;
  }

  String get _rankEmoji {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '$rank.';
  }

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final highlight = entry.isPlayer;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.gardenGreenMid.withValues(alpha: 0.20)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? AppColors.gardenGreenMid.withValues(alpha: 0.50)
              : Colors.white.withValues(alpha: isTop3 ? 0.14 : 0.06),
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 38,
            child: Text(
              _rankEmoji,
              style: TextStyle(
                fontSize: isTop3 ? 22 : 14,
                color: _rankColor,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          // Emoji avatar
          Text(
            entry.emoji,
            style: const TextStyle(fontSize: 26),
          ),
          const SizedBox(width: 10),
          // Name + shop
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: highlight ? Colors.white : Colors.white70,
                  ),
                ),
                Text(
                  entry.shopName,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
          // Score
          Text(
            '${entry.score} pts',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: highlight ? const Color(0xFF7CFC88) : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}
