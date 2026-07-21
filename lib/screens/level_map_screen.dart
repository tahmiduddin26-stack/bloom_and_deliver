import 'package:flutter/material.dart';

import '../config/feature_flags.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/level_data.dart';
import '../data/seasonal_events_data.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/daily_challenges_strip.dart';
import '../widgets/reputation_board.dart';
import '../widgets/seasonal_banner.dart';
import '../widgets/story_arc_dialog.dart';
import 'market_screen.dart';
import 'play_screen.dart';
import 'shop_decor_screen.dart';
import 'shop_interior_screen.dart';
import 'town_map_screen.dart';
import 'upgrades_screen.dart';
import 'wholesale_screen.dart';

/// Candy-Crush-style campaign map: a winding garden path of 20 level nodes.
/// Level 1 sits at the bottom; the path climbs to the Bloom Legend finale.
class LevelMapScreen extends ConsumerStatefulWidget {
  const LevelMapScreen({super.key});

  @override
  ConsumerState<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends ConsumerState<LevelMapScreen> {
  static const double _nodeSpacing = 118.0;
  static const double _topPadding = 140.0;
  static const double _bottomPadding = 90.0;

  final _scrollCtrl = ScrollController();
  bool _didAutoScroll = false;
  bool _showSeasonalBanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(gameProvider.notifier);
      notifier.checkLoginStreak();

      // Pending events queued by startNextDay land here (the map is the hub).
      final state = ref.read(gameProvider);
      if (state.pendingStoryChapterDay != null) {
        final day = state.pendingStoryChapterDay!;
        notifier.clearPendingStoryChapter();
        showStoryArcDialog(context, day, () {});
      }
      if (state.pendingReputationBoard) {
        notifier.clearPendingReputationBoard();
        final week = ((state.day - 1) / 7).ceil();
        showReputationBoard(
          context,
          week: week,
          playerScore: state.reputationScore,
          onClose: () {},
        );
      }
      if (state.pendingSeasonalBanner && eventForDay(state.day) != null) {
        setState(() => _showSeasonalBanner = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _openTownMap() {
    openTownMapScreen(
      context,
      onGoToShop: () => openShopInteriorScreen(context),
      // Browse mode: restock without advancing the day.
      onGoToMarket: () => openMarketScreen(context),
      onGoToWholesale: () => openWholesaleScreen(context),
    );
  }

  double _mapHeight(int nodeCount) =>
      _topPadding + _bottomPadding + (nodeCount - 1) * _nodeSpacing;

  /// Node centre position. Level 1 at the bottom, winding left/right.
  Offset _nodeCenter(int index, double width, int nodeCount) {
    final y = _mapHeight(nodeCount) - _bottomPadding - index * _nodeSpacing;
    // Gentle serpentine: alternate across the width in a repeating pattern
    const pattern = [0.28, 0.62, 0.76, 0.48, 0.24, 0.50];
    final x = width * pattern[index % pattern.length];
    return Offset(x, y);
  }

  void _autoScrollToCurrent(int nextLevel, int nodeCount) {
    if (_didAutoScroll || !_scrollCtrl.hasClients) return;
    _didAutoScroll = true;
    final idx = (nextLevel - 1).clamp(0, nodeCount - 1);
    final y = _mapHeight(nodeCount) - _bottomPadding - idx * _nodeSpacing;
    final target = (y - 320).clamp(0.0, _scrollCtrl.position.maxScrollExtent);
    _scrollCtrl.jumpTo(target);
  }

  void _playLevel(int level) {
    final ok = ref.read(gameProvider.notifier).startLevel(level);
    if (!ok) return;
    AudioService.instance.play(GameSound.submit);
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const PlayScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeIn),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final nextLevel = state.nextLevel;
    // Show 20 campaign nodes + one endless node once the campaign is done.
    final nodeCount =
        nextLevel > maxCampaignLevel ? nextLevel : maxCampaignLevel;

    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _autoScrollToCurrent(nextLevel, nodeCount));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFCE4EC), // soft pink sky
              Color(0xFFF8E8F5),
              Color(0xFFE8F5E9), // meadow green
              Color(0xFFDCEDC8),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
          Column(
            children: [
              _MapHeader(
                money: state.money,
                totalStars: state.totalStars,
                nextLevel: nextLevel,
                onTownMap: _openTownMap,
              ),
              // Today's challenges (rewards pay out while playing)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: DailyChallengesStrip(),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = _mapHeight(nodeCount);
                    final centers = List.generate(
                        nodeCount, (i) => _nodeCenter(i, width, nodeCount));

                    return SingleChildScrollView(
                      controller: _scrollCtrl,
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: Stack(
                          children: [
                            // Winding path
                            CustomPaint(
                              size: Size(width, height),
                              painter: _PathPainter(centers: centers),
                            ),
                            // Scattered garden doodles
                            ..._gardenDoodles(width, height),
                            // Level nodes
                            for (var i = 0; i < nodeCount; i++)
                              _positionedNode(i + 1, centers[i], state),
                            // Finish banner above node 20
                            if (nodeCount >= maxCampaignLevel)
                              Positioned(
                                left: 0,
                                right: 0,
                                top: centers[maxCampaignLevel - 1].dy - 108,
                                child: const _FinishBanner(),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
              // Seasonal event banner overlay
              if (_showSeasonalBanner)
                Builder(builder: (context) {
                  final event = eventForDay(ref.read(gameProvider).day);
                  if (event == null) return const SizedBox.shrink();
                  return Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SeasonalBanner(
                      event: event,
                      onDismissed: () =>
                          setState(() => _showSeasonalBanner = false),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _positionedNode(int level, Offset center, dynamic state) {
    final stars = state.starsForLevel(level);
    final unlocked = state.isLevelUnlocked(level);
    final isCurrent = level == state.nextLevel;
    final def = levelForDay(level);

    return Positioned(
      left: center.dx - 44,
      top: center.dy - 44,
      child: _LevelNode(
        def: def,
        stars: stars,
        unlocked: unlocked,
        isCurrent: isCurrent,
        isEndless: level > maxCampaignLevel,
        onTap: unlocked ? () => _showLevelSheet(def, stars, isCurrent) : null,
      ),
    );
  }

  void _showLevelSheet(LevelDef def, int stars, bool isCurrent) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LevelSheet(
        def: def,
        stars: stars,
        isCurrent: isCurrent,
        onPlay: () {
          Navigator.of(context).pop();
          _playLevel(def.number);
        },
      ),
    );
  }

  List<Widget> _gardenDoodles(double width, double height) {
    const doodles = ['🌳', '🌷', '🌻', '🍄', '🦋', '🌿', '🌼', '🐝', '🌸', '🪻'];
    final widgets = <Widget>[];
    var seed = 7;
    for (var y = 60.0; y < height - 40; y += 96) {
      seed = (seed * 31 + 17) % 1000;
      final leftSide = seed.isEven;
      final x = leftSide ? 8.0 + (seed % 30) : width - 46.0 - (seed % 30);
      widgets.add(Positioned(
        left: x,
        top: y,
        child: Opacity(
          opacity: 0.55,
          child: Text(
            doodles[(y ~/ 96 + seed) % doodles.length],
            style: TextStyle(fontSize: 22.0 + (seed % 12)),
          ),
        ),
      ));
    }
    return widgets;
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _MapHeader extends StatelessWidget {
  final int money;
  final int totalStars;
  final int nextLevel;
  final VoidCallback onTownMap;

  const _MapHeader({
    required this.money,
    required this.totalStars,
    required this.nextLevel,
    required this.onTownMap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE1BEE7).withValues(alpha: 0.6),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🌸', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bloom & Deliver',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.inkBrown,
                  ),
                ),
                Text(
                  nextLevel > maxCampaignLevel
                      ? 'Campaign complete — endless bloom!'
                      : 'Level $nextLevel of $maxCampaignLevel',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brownLight,
                  ),
                ),
              ],
            ),
          ),
          _HeaderChip(emoji: '⭐', label: '$totalStars'),
          const SizedBox(width: 6),
          _HeaderChip(emoji: '🪙', label: '\$$money'),
          if (Features.townMap) ...[
            const SizedBox(width: 6),
            _HeaderIconButton(
              emoji: '🗺️',
              tooltip: 'Town Map',
              onTap: onTownMap,
            ),
          ],
          if (Features.upgrades) ...[
            const SizedBox(width: 4),
            _HeaderIconButton(
              emoji: '🔨',
              tooltip: 'Shop Upgrades',
              onTap: () => openUpgradesScreen(context),
            ),
          ],
          if (Features.shopDecor) ...[
            const SizedBox(width: 4),
            _HeaderIconButton(
              emoji: '🎨',
              tooltip: 'Shop Decor',
              onTap: () => openShopDecorScreen(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final String emoji;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.emoji,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE1BEE7).withValues(alpha: 0.45),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFBA68C8).withValues(alpha: 0.5),
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 15)),
            ),
          ),
        ),
      );
}

class _HeaderChip extends StatelessWidget {
  final String emoji;
  final String label;

  const _HeaderChip({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8BBD0).withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFF48FB1).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.inkBrown,
              ),
            ),
          ],
        ),
      );
}

// ── Path painter ───────────────────────────────────────────────────────────────

class _PathPainter extends CustomPainter {
  final List<Offset> centers;

  _PathPainter({required this.centers});

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.length < 2) return;

    final path = Path()..moveTo(centers.first.dx, centers.first.dy);
    for (var i = 1; i < centers.length; i++) {
      final prev = centers[i - 1];
      final curr = centers[i];
      final midY = (prev.dy + curr.dy) / 2;
      path.cubicTo(prev.dx, midY, curr.dx, midY, curr.dx, curr.dy);
    }

    // Soft wide base
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFF8BBD0).withValues(alpha: 0.5),
    );

    // Dotted centre line
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 26) {
        final pos = metric.getTangentForOffset(d)?.position;
        if (pos != null) canvas.drawCircle(pos, 3.4, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) => old.centers != centers;
}

// ── Level node ─────────────────────────────────────────────────────────────────

class _LevelNode extends StatefulWidget {
  final LevelDef def;
  final int stars;
  final bool unlocked;
  final bool isCurrent;
  final bool isEndless;
  final VoidCallback? onTap;

  const _LevelNode({
    required this.def,
    required this.stars,
    required this.unlocked,
    required this.isCurrent,
    required this.isEndless,
    this.onTap,
  });

  @override
  State<_LevelNode> createState() => _LevelNodeState();
}

class _LevelNodeState extends State<_LevelNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.09).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    if (widget.isCurrent) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _LevelNode old) {
    super.didUpdateWidget(old);
    if (widget.isCurrent && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.isCurrent && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locked = !widget.unlocked;

    final circleColors = locked
        ? [Colors.grey.shade400, Colors.grey.shade500]
        : widget.isCurrent
            ? [const Color(0xFFF06292), const Color(0xFFEC407A)]
            : widget.isEndless
                ? [const Color(0xFFBA68C8), const Color(0xFF9C27B0)]
                : [const Color(0xFF81C784), const Color(0xFF4CAF50)];

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 88,
        height: 88,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: widget.isCurrent
                  ? _pulse
                  : const AlwaysStoppedAnimation(1.0),
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: circleColors,
                  ),
                  border: Border.all(
                    color: Colors.white,
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: circleColors.last.withValues(
                          alpha: locked ? 0.2 : 0.55),
                      blurRadius: widget.isCurrent ? 18 : 10,
                      spreadRadius: widget.isCurrent ? 2 : 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: locked
                      ? const Text('🔒', style: TextStyle(fontSize: 20))
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(widget.def.emoji,
                                style: const TextStyle(fontSize: 17)),
                            Text(
                              '${widget.def.number}',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                height: 1.0,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            // Star row
            if (!locked)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final filled = i < widget.stars;
                  return Text(
                    filled ? '⭐' : '☆',
                    style: TextStyle(
                      fontSize: 11,
                      color: filled ? null : Colors.grey.shade400,
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Finish banner ──────────────────────────────────────────────────────────────

class _FinishBanner extends StatelessWidget {
  const _FinishBanner();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB300).withValues(alpha: 0.5),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          '🏆 Bloom Legend 🏆',
          style: GoogleFonts.playfairDisplay(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5D4037),
          ),
        ),
      ),
    );
  }
}

// ── Level detail bottom sheet ──────────────────────────────────────────────────

class _LevelSheet extends StatelessWidget {
  final LevelDef def;
  final int stars;
  final bool isCurrent;
  final VoidCallback onPlay;

  const _LevelSheet({
    required this.def,
    required this.stars,
    required this.isCurrent,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(def.emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 6),
          Text(
            'Level ${def.number} — ${def.title}',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.inkBrown,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            def.subtitle,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.brownLight,
            ),
          ),
          const SizedBox(height: 10),
          // Best stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  i < stars ? '⭐' : '☆',
                  style: TextStyle(
                    fontSize: 26,
                    color: i < stars ? null : Colors.grey.shade400,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          // Star goals
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8BBD0).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _GoalRow(stars: '⭐', text: 'Serve every customer'),
                _GoalRow(stars: '⭐⭐', text: 'Earn \$${def.star2Earnings}'),
                _GoalRow(stars: '⭐⭐⭐', text: 'Earn \$${def.star3Earnings}'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            def.unlockText,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.brownLight,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onPlay,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: const Color(0xFFEC407A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              isCurrent ? 'Play  🌸' : (stars > 0 ? 'Replay  🔁' : 'Play  🌸'),
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final String stars;
  final String text;

  const _GoalRow({required this.stars, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: Text(stars, style: const TextStyle(fontSize: 11)),
            ),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkBrown,
                ),
              ),
            ),
          ],
        ),
      );
}

/// Convenience: open the level map, clearing everything else off the stack.
void openLevelMapAsRoot(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => const LevelMapScreen(),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeIn),
        child: child,
      ),
    ),
    (route) => false,
  );
}
