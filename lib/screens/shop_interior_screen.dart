import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/feature_flags.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/florist_rank.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/windowsill_plots.dart';
import 'achievements_screen.dart';
import 'leaderboard_screen.dart';
import 'shop_decor_screen.dart';
import 'shop_stats_screen.dart';
import 'upgrades_screen.dart';
import 'vibe_notebook_screen.dart';

// ── Entry point ───────────────────────────────────────────────────────────────

/// Open the shop interior screen (slides up from bottom, like the town map).
Future<void> openShopInteriorScreen(BuildContext context) {
  if (!Features.shopInterior) return Future<void>.value();
  return Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 360),
      pageBuilder: (_, __, ___) => const ShopInteriorScreen(),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ShopInteriorScreen extends ConsumerStatefulWidget {
  const ShopInteriorScreen({super.key});

  @override
  ConsumerState<ShopInteriorScreen> createState() => _ShopInteriorScreenState();
}

class _ShopInteriorScreenState extends ConsumerState<ShopInteriorScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final rank = state.rank;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3D2510), Color(0xFF1E1208)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────────────────
                _ShopHeader(rank: rank, onBack: () => Navigator.of(context).pop()),
                // ── Storefront illustration + status strip ────────────────────
                _StorefrontCard(state: state, rank: rank),
                const SizedBox(height: 12),
                // ── Windowsill garden (plant seeds, harvest free flowers) ─────
                const WindowsillPlots(),
                const SizedBox(height: 4),
                // ── Section title ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'MANAGE YOUR SHOP',
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.warmWhite.withValues(alpha: 0.45),
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // ── Tile grid ─────────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _TileGrid(
                      tiles: [
                        _ShopTile(
                          emoji: '🎨',
                          label: 'Decor',
                          sublabel: 'Dress up your shop',
                          gradient: const [Color(0xFF9B4DCA), Color(0xFF6B2FA0)],
                          onTap: () => openShopDecorScreen(context),
                        ),
                        _ShopTile(
                          emoji: '⬆️',
                          label: 'Upgrades',
                          sublabel: 'Expand your tools',
                          gradient: const [Color(0xFF2D7DD2), Color(0xFF1A5499)],
                          onTap: () => openUpgradesScreen(context),
                        ),
                        _ShopTile(
                          emoji: '🏆',
                          label: 'Achievements',
                          sublabel: 'See your milestones',
                          gradient: const [Color(0xFFD4A017), Color(0xFFA07010)],
                          onTap: () => openAchievementsScreen(context),
                        ),
                        _ShopTile(
                          emoji: '📊',
                          label: 'Stats',
                          sublabel: 'All-time records',
                          gradient: const [Color(0xFF3A7D44), Color(0xFF235229)],
                          onTap: () => openShopStatsScreen(context),
                        ),
                        _ShopTile(
                          emoji: '📓',
                          label: 'Vibe Notebook',
                          sublabel: 'Discovered vibes',
                          gradient: const [Color(0xFFD45A8A), Color(0xFF9E2E5E)],
                          onTap: () => openVibeNotebook(context),
                        ),
                        _ShopTile(
                          emoji: '🏅',
                          label: 'Leaderboard',
                          sublabel: 'Top florists',
                          gradient: const [Color(0xFFE07830), Color(0xFFB05010)],
                          onTap: () => openLeaderboardScreen(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ShopHeader extends StatelessWidget {
  final FloristRank rank;
  final VoidCallback onBack;

  const _ShopHeader({required this.rank, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C3010), Color(0xFF3E1E08)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onBack();
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text('🌷', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Flower Shop',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warmWhite,
                  ),
                ),
                Text(
                  'Bloom & Deliver',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: AppColors.cream.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Rank badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFD700).withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(rank.emoji, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(
                  rank.title,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFFD700),
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

// ── Storefront card ───────────────────────────────────────────────────────────

class _StorefrontCard extends StatelessWidget {
  final dynamic state; // GameState
  final FloristRank rank;

  const _StorefrontCard({required this.state, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C3318), Color(0xFF3A1E0A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.terracotta.withValues(alpha: 0.30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Decorative flower scatter
            const Positioned.fill(child: _FlowerScatter()),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Row(
                children: [
                  // Shop sign illustration
                  _ShopSign(rank: rank),
                  const SizedBox(width: 16),
                  // Stats column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StatRow(
                          icon: '📅',
                          label: 'Day',
                          value: '${state.day}',
                        ),
                        const SizedBox(height: 6),
                        _StatRow(
                          icon: '💵',
                          label: 'Cash',
                          value: '\$${state.money}',
                        ),
                        const SizedBox(height: 6),
                        _StatRow(
                          icon: '📦',
                          label: 'Orders served',
                          value: '${state.totalOrdersServed}',
                        ),
                        const SizedBox(height: 6),
                        _StatRow(
                          icon: '⭐',
                          label: 'XP',
                          value: '${state.xp}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.50),
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.warmWhite,
          ),
        ),
      ],
    );
  }
}

// ── Decorative shop sign illustration ─────────────────────────────────────────

class _ShopSign extends StatelessWidget {
  final FloristRank rank;

  const _ShopSign({required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF6B3A1E).withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.terracotta.withValues(alpha: 0.50),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            rank.emoji,
            style: const TextStyle(fontSize: 30),
          ),
          const SizedBox(height: 4),
          Text(
            'OPEN',
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF7CFC88),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            rank.title,
            style: GoogleFonts.nunito(
              fontSize: 8,
              color: Colors.white.withValues(alpha: 0.55),
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Flower scatter background ─────────────────────────────────────────────────

class _FlowerScatter extends StatelessWidget {
  const _FlowerScatter();

  static const _flowers = ['🌸', '🌺', '💐', '🌼', '🌷', '🌿'];

  @override
  Widget build(BuildContext context) {
    final rng = math.Random(42);
    return IgnorePointer(
      child: CustomPaint(
        painter: _FlowerScatterPainter(flowers: _flowers, rng: rng),
      ),
    );
  }
}

class _FlowerScatterPainter extends CustomPainter {
  final List<String> flowers;
  final math.Random rng;

  const _FlowerScatterPainter({required this.flowers, required this.rng});

  @override
  void paint(Canvas canvas, Size size) {
    final positions = [
      Offset(size.width * 0.88, size.height * 0.08),
      Offset(size.width * 0.78, size.height * 0.80),
      Offset(size.width * 0.05, size.height * 0.75),
      Offset(size.width * 0.92, size.height * 0.48),
      Offset(size.width * 0.12, size.height * 0.15),
    ];

    for (int i = 0; i < positions.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: flowers[i % flowers.length],
          style: TextStyle(
            fontSize: 18 + (i % 3) * 4.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(positions[i].dx, positions[i].dy);
      canvas.rotate((i - 2) * 0.25);
      canvas.drawColor(
        Colors.transparent,
        BlendMode.clear,
      );
      tp.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_FlowerScatterPainter old) => false;
}

// ── Tile grid ─────────────────────────────────────────────────────────────────

class _ShopTile {
  final String emoji;
  final String label;
  final String sublabel;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ShopTile({
    required this.emoji,
    required this.label,
    required this.sublabel,
    required this.gradient,
    required this.onTap,
  });
}

class _TileGrid extends StatelessWidget {
  final List<_ShopTile> tiles;

  const _TileGrid({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      // Scrollable so small screens can reach every tile now that the
      // windowsill garden sits above the grid.
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: tiles.length,
      itemBuilder: (_, i) => _TileCard(tile: tiles[i]),
    );
  }
}

class _TileCard extends StatefulWidget {
  final _ShopTile tile;

  const _TileCard({required this.tile});

  @override
  State<_TileCard> createState() => _TileCardState();
}

class _TileCardState extends State<_TileCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _pressCtrl;
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _pressCtrl.reverse();
  void _onTapUp(_) => _pressCtrl.forward();
  void _onTapCancel() => _pressCtrl.forward();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.tile.onTap();
      },
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.tile.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: widget.tile.gradient.first.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.tile.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(height: 6),
              Text(
                widget.tile.label,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  widget.tile.sublabel,
                  style: GoogleFonts.nunito(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
