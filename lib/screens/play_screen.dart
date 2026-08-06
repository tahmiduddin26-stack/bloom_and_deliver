import 'package:flutter/material.dart';

import '../config/feature_flags.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/flower_data.dart';
import '../data/level_data.dart';
import '../models/bouquet_order.dart';
import '../models/customer_profile.dart';
import '../models/daily_challenge.dart';
import '../models/florist_rank.dart';
import '../models/flower.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/achievement_popup.dart';
import '../widgets/ambient_petals.dart';
import '../widgets/end_of_day_dialog.dart';
import '../widgets/flower_image.dart';
import '../widgets/memory_popup.dart';
import '../widgets/sparkle_overlay.dart';
import 'big_order_screen.dart';
import 'delivery_screen.dart';
import 'level_map_screen.dart';
import 'market_screen.dart';

/// The streamlined play screen — one level, one clear loop:
/// read the customer card → tap (or drag) flowers → submit.
/// Everything else lives on the level map or in the market.
class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({super.key});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> {
  bool _showConfetti = false;

  // Transient result overlay
  OrderResult? _resultShown;
  int _resultEarned = 0;

  // Celebration popup queues (achievements, friendship memories)
  String? _activeAchievementId;
  String? _activeMemoryKey;

  // Transient "challenge complete" celebration
  DailyChallenge? _challengeDone;

  void _handleSubmit() {
    HapticFeedback.mediumImpact();
    AudioService.instance.play(GameSound.submit);

    final beforeState = ref.read(gameProvider);
    final before = beforeState.money;
    final doneBefore = beforeState.dailyChallenges
        .where((c) => c.completed)
        .map((c) => c.id)
        .toSet();
    final result = ref.read(gameProvider.notifier).submitBouquet();
    final afterState = ref.read(gameProvider);
    final earned = (afterState.money - before).clamp(0, 99999);
    final justCompleted = afterState.dailyChallenges
        .where((c) => c.completed && !doneBefore.contains(c.id))
        .toList();

    AudioService.instance.play(
      result == OrderResult.great
          ? GameSound.greatOrder
          : result == OrderResult.poor
              ? GameSound.poorOrder
              : GameSound.coin,
    );
    if (result == OrderResult.great) {
      Future.delayed(
          const Duration(milliseconds: 150), HapticFeedback.heavyImpact);
    }

    setState(() {
      _resultShown = result;
      _resultEarned = earned;
      _showConfetti = result == OrderResult.great;
      if (justCompleted.isNotEmpty) _challengeDone = justCompleted.first;
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _resultShown = null;
          _showConfetti = false;
        });
      }
    });

    if (justCompleted.isNotEmpty) {
      AudioService.instance.play(GameSound.notification);
      final completed = justCompleted.first;
      Future.delayed(const Duration(milliseconds: 3000), () {
        if (mounted && _challengeDone == completed) {
          setState(() => _challengeDone = null);
        }
      });
    }
  }

  void _openMarket() {
    openMarketScreen(
      context,
      onStartNextDay: () {
        ref.read(gameProvider.notifier).startNextDay();
        if (mounted) openLevelMapAsRoot(context);
      },
    );
  }

  void _openDeliveries() => openDeliveryScreen(context, onDone: _openMarket);

  void _openBigOrder() => openBigOrderScreen(context, onDone: _openMarket);

  void _onAchievementDismissed() {
    ref.read(gameProvider.notifier).popPendingAchievement();
    setState(() => _activeAchievementId = null);
    final next = ref.read(gameProvider).pendingAchievements;
    if (next.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _activeAchievementId = next.first);
      });
    }
  }

  void _onMemoryDismissed() {
    ref.read(gameProvider.notifier).popPendingMemory();
    setState(() => _activeMemoryKey = null);
    final next = ref.read(gameProvider).pendingMemories;
    if (next.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _activeMemoryKey = next.first);
      });
    }
  }

  void _showRankUpDialog(FloristRank newRank) {
    ref.read(gameProvider.notifier).clearPendingRankUp();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _RankUpDialog(rank: newRank),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final order = state.currentOrder;
    final level = levelForDay(state.day);

    // Day finished → summary, then deliveries / big order / market.
    ref.listen(gameProvider.select((s) => s.dayEnded), (prev, next) {
      if (next && prev == false) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          showEndOfDayDialog(
            context, // ignore: use_build_context_synchronously
            onGoToMarket: _openMarket,
            onGoToDeliveries: Features.deliveries ? _openDeliveries : null,
            onGoToBigOrder: Features.bigOrders ? _openBigOrder : null,
          );
        });
      }
    });

    // Rank-up celebration
    ref.listen(gameProvider.select((s) => s.pendingRankUp), (prev, next) {
      if (next != null && next != prev) {
        AudioService.instance.play(GameSound.greatOrder);
        _showRankUpDialog(next);
      }
    });

    // Achievement popups (one at a time). Gated: the achievements system is
    // flagged off for launch, and its screen is unreachable, so its popups must
    // not fire either — otherwise a cut system keeps interrupting play.
    ref.listen(gameProvider.select((s) => s.pendingAchievements), (prev, next) {
      if (!Features.achievements) return;
      if (next.isNotEmpty && _activeAchievementId == null) {
        AudioService.instance.play(GameSound.notification);
        setState(() => _activeAchievementId = next.first);
      }
    });

    // Friendship memory popups
    ref.listen(gameProvider.select((s) => s.pendingMemories), (prev, next) {
      if (next.isNotEmpty && _activeMemoryKey == null) {
        AudioService.instance.play(GameSound.notification);
        setState(() => _activeMemoryKey = next.first);
      }
    });

    return Scaffold(
      body: SparkleOverlay(
        active: _showConfetti,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFCE4EC),
                Color(0xFFF8EDF3),
                Color(0xFFE8F5E9),
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                const Positioned.fill(child: AmbientPetals()),
                Column(
                  children: [
                    _Header(
                      level: level,
                      money: state.money,
                      ordersDone: state.currentOrderIndex,
                      ordersTotal: state.dayOrders.length,
                      onBack: () => openLevelMapAsRoot(context),
                    ),
                    const SizedBox(height: 6),
                    if (order != null)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 420),
                        switchInCurve: Curves.easeOutCubic,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, -0.14),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: _CustomerCard(
                          key: ValueKey(state.currentOrderIndex),
                          order: order,
                          workspace: state.bouquetWorkspace,
                          friendship: state.friendshipFor(order.customer.id),
                        ),
                      )
                    else
                      const Expanded(
                        child: Center(child: Text('🌙', style: TextStyle(fontSize: 48))),
                      ),
                    if (order != null) ...[
                      const SizedBox(height: 8),
                      Expanded(
                        child: _BouquetArea(order: order),
                      ),
                      _FlowerTray(day: state.day, inventory: state.inventory, order: order),
                      _SubmitBar(
                        order: order,
                        count: state.bouquetWorkspace.length,
                        onSubmit: _handleSubmit,
                      ),
                    ],
                  ],
                ),
                // Result overlay
                if (_resultShown != null)
                  _ResultOverlay(result: _resultShown!, earned: _resultEarned),
                // Achievement popup
                if (Features.achievements && _activeAchievementId != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: AchievementPopup(
                      achievementId: _activeAchievementId!,
                      onDismiss: _onAchievementDismissed,
                    ),
                  ),
                // Memory popup
                if (_activeMemoryKey != null)
                  Positioned(
                    top: _activeAchievementId != null ? 80 : 0,
                    left: 0,
                    right: 0,
                    child: MemoryPopup(
                      memoryKey: _activeMemoryKey!,
                      onDismiss: _onMemoryDismissed,
                    ),
                  ),
                // Daily-challenge completion celebration
                if (_challengeDone != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 88,
                    child: _ChallengeToast(challenge: _challengeDone!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Rank-up dialog ─────────────────────────────────────────────────────────────

class _RankUpDialog extends StatelessWidget {
  final FloristRank rank;

  const _RankUpDialog({required this.rank});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8F0),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: const Color(0xFFFFD54F).withValues(alpha: 0.8),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB300).withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(rank.emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 8),
            Text(
              'Rank Up!',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.inkBrown,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You are now a ${rank.title}',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.brownLight,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: const Color(0xFFEC407A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                'Keep Blooming  🌸',
                style: GoogleFonts.nunito(
                  fontSize: 15,
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

// ── Header ─────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final LevelDef level;
  final int money;
  final int ordersDone;
  final int ordersTotal;
  final VoidCallback onBack;

  const _Header({
    required this.level,
    required this.money,
    required this.ordersDone,
    required this.ordersTotal,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          // Back to map
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE1BEE7).withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 22, color: Color(0xFF6D4C41)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${level.emoji} Level ${level.number} — ${level.title}',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.inkBrown,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                // Order progress dots (scale down rather than overflow on
                // narrow screens / 10+ order days)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                  children: List.generate(ordersTotal.clamp(0, 12), (i) {
                    final done = i < ordersDone;
                    final current = i == ordersDone;
                    return Container(
                      width: current ? 10 : 7,
                      height: current ? 10 : 7,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? const Color(0xFFEC407A)
                            : current
                                ? const Color(0xFFF48FB1)
                                : Colors.white.withValues(alpha: 0.9),
                        border: Border.all(
                          color: const Color(0xFFF48FB1),
                          width: 1.2,
                        ),
                      ),
                    );
                  }),
                  ),
                ),
              ],
            ),
          ),
          // Money chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF81C784), Color(0xFF4CAF50)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Text(
                '🪙 \$$money',
                key: ValueKey(money),
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Customer card ──────────────────────────────────────────────────────────────

class _CustomerCard extends StatelessWidget {
  final BouquetOrder order;
  final List<Flower> workspace;
  final int friendship;

  const _CustomerCard({
    super.key,
    required this.order,
    required this.workspace,
    required this.friendship,
  });

  @override
  Widget build(BuildContext context) {
    final covered = workspace.expand((f) => f.vibes).toSet();
    final customer = order.customer;
    final maxF = customer.maxFriendship;
    // A maxed-out regular unlocks their life-event moment — the emotional payoff
    // of the relationship, and the reason to keep serving them.
    final showLifeEvent = customer.isRegular &&
        friendship >= maxF &&
        customer.lifeEventHint != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF48FB1).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFCE4EC),
                  border: Border.all(color: const Color(0xFFF48FB1), width: 2),
                ),
                child: Center(
                  child: Text(order.customer.portrait,
                      style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          order.customer.name,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.inkBrown,
                          ),
                        ),
                        if (order.customer.isRegular) ...[
                          const SizedBox(width: 4),
                          const Text('⭐', style: TextStyle(fontSize: 11)),
                        ],
                        const Spacer(),
                        Text(
                          order.customer.mood.emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    if (customer.isRegular) ...[
                      const SizedBox(height: 4),
                      _FriendshipHearts(level: friendship, max: maxF),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      order.hint,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                        color: AppColors.brownDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // What they want — live match chips
          if (order.isMystery)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF9575CD)),
              ),
              child: Text(
                '🎭 Surprise me! Use 4+ different flowers for the best tip.',
                style: GoogleFonts.nunito(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5E35B1),
                ),
              ),
            )
          else
            Wrap(
              spacing: 5,
              runSpacing: 5,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final vibe in order.requiredVibes)
                  _MatchChip(vibe: vibe, covered: covered.contains(vibe)),
                const SizedBox(width: 2),
                Text(
                  '· ${order.minFlowers}–${order.maxFlowers} flowers · up to \$${(order.basePayment * 1.3).round()}',
                  style: GoogleFonts.nunito(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brownLight,
                  ),
                ),
              ],
            ),
          if (showLifeEvent) ...[
            const SizedBox(height: 10),
            _LifeEventBanner(
              name: customer.name,
              hint: customer.lifeEventHint!,
            ),
          ],
        ],
      ),
    );
  }
}

// Friendship hearts (0–max) shown under a regular's name.
class _FriendshipHearts extends StatelessWidget {
  final int level;
  final int max;

  const _FriendshipHearts({required this.level, required this.max});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < max; i++)
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Text(
              i < level ? '❤️' : '🤍',
              style: const TextStyle(fontSize: 10),
            ),
          ),
      ],
    );
  }
}

// The life-event payoff for a maxed-out regular — their story's big moment.
class _LifeEventBanner extends StatelessWidget {
  final String name;
  final String hint;

  const _LifeEventBanner({required this.name, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0F5), Color(0xFFFCE4EC)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF48FB1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💖 $name trusts you completely',
            style: GoogleFonts.nunito(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFC2185B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              height: 1.35,
              color: AppColors.brownDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchChip extends StatefulWidget {
  final VibeTag vibe;
  final bool covered;

  const _MatchChip({required this.vibe, required this.covered});

  @override
  State<_MatchChip> createState() => _MatchChipState();
}

class _MatchChipState extends State<_MatchChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 440),
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 1.28).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.28, end: 1.0)
          .chain(CurveTween(curve: Curves.elasticOut)),
      weight: 65,
    ),
  ]).animate(_pop);

  @override
  void didUpdateWidget(_MatchChip old) {
    super.didUpdateWidget(old);
    // Pop when this vibe goes from unmatched → matched.
    if (widget.covered && !old.covered) {
      HapticFeedback.selectionClick();
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vibe = widget.vibe;
    final covered = widget.covered;
    return ScaleTransition(
      scale: _scale,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: covered ? vibe.color : vibe.color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: vibe.color, width: 1.5),
          boxShadow: covered
              ? [BoxShadow(color: vibe.color.withValues(alpha: 0.5), blurRadius: 8)]
              : [],
        ),
        child: Text(
          covered ? '✓ ${vibe.label}' : vibe.label,
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: covered ? Colors.white : vibe.color,
          ),
        ),
      ),
    );
  }
}

// ── Bouquet area ───────────────────────────────────────────────────────────────

class _BouquetArea extends ConsumerWidget {
  final BouquetOrder order;

  const _BouquetArea({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(gameProvider.select((s) => s.bouquetWorkspace));
    final notifier = ref.read(gameProvider.notifier);
    final maxFlowers = notifier.effectiveMaxFlowers();

    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => workspace.length < maxFlowers,
      onAcceptWithDetails: (d) {
        AudioService.instance.play(GameSound.flowerDrop);
        notifier.addFlowerToWorkspace(d.data);
      },
      builder: (context, candidates, _) {
        final hovering = candidates.isNotEmpty;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: hovering
                ? const Color(0xFFFFF9C4).withValues(alpha: 0.75)
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: hovering
                  ? const Color(0xFFFFB300)
                  : const Color(0xFFF48FB1).withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              // Slim header row
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 8, 0),
                child: Row(
                  children: [
                    Text(
                      '💐 ${workspace.length}/$maxFlowers',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.inkBrown,
                      ),
                    ),
                    const Spacer(),
                    if (workspace.isNotEmpty) ...[
                      _SmallAction(
                          label: '↩️ Undo', onTap: notifier.undoLastFlower),
                      const SizedBox(width: 6),
                      _SmallAction(
                          label: '🗑 Clear', onTap: notifier.clearWorkspace),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: workspace.isEmpty
                    ? Center(
                        child: Text(
                          'Tap flowers below\nto build the bouquet 🌸',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brownLight,
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(8),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var i = 0; i < workspace.length; i++)
                              _BouquetFlower(
                                flower: workspace[i],
                                onTap: () =>
                                    notifier.removeFlowerFromWorkspace(i),
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SmallAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SmallAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: AppColors.brownLight.withValues(alpha: 0.4)),
          ),
          child: Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.brownDark,
            ),
          ),
        ),
      );
}

class _BouquetFlower extends StatefulWidget {
  final Flower flower;
  final VoidCallback onTap;

  const _BouquetFlower({required this.flower, required this.onTap});

  @override
  State<_BouquetFlower> createState() => _BouquetFlowerState();
}

class _BouquetFlowerState extends State<_BouquetFlower>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          AudioService.instance.play(GameSound.flowerDrop);
          widget.onTap();
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.flower.color.withValues(alpha: 0.18),
            border: Border.all(
                color: widget.flower.color.withValues(alpha: 0.8), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: widget.flower.color.withValues(alpha: 0.35),
                blurRadius: 8,
              ),
            ],
          ),
          child: Center(child: FlowerImage(flower: widget.flower, size: 32)),
        ),
      ),
    );
  }
}

// ── Flower tray ────────────────────────────────────────────────────────────────

class _FlowerTray extends ConsumerWidget {
  final int day;
  final Map<String, int> inventory;
  final BouquetOrder order;

  const _FlowerTray({
    required this.day,
    required this.inventory,
    required this.order,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final flowers = unlockedFlowers(day);
    final wanted =
        order.isMystery ? <VibeTag>{} : order.requiredVibes.toSet();

    // In-stock first, matching flowers before the rest.
    final sorted = List<Flower>.from(flowers)
      ..sort((a, b) {
        final aStock = (inventory[a.id] ?? 0) > 0 ? 0 : 1;
        final bStock = (inventory[b.id] ?? 0) > 0 ? 0 : 1;
        if (aStock != bStock) return aStock - bStock;
        final aMatch = a.vibes.any(wanted.contains) ? 0 : 1;
        final bMatch = b.vibes.any(wanted.contains) ? 0 : 1;
        return aMatch - bMatch;
      });

    return Container(
      height: 108,
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: sorted.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final flower = sorted[i];
          final qty = inventory[flower.id] ?? 0;
          final matches = flower.vibes.any(wanted.contains);
          return _TrayPot(
            flower: flower,
            qty: qty,
            matches: matches,
            onAdd: qty > 0
                ? () {
                    HapticFeedback.selectionClick();
                    AudioService.instance.play(GameSound.flowerDrop);
                    notifier.addFlowerToWorkspace(flower.id);
                  }
                : null,
          );
        },
      ),
    );
  }
}

class _TrayPot extends StatelessWidget {
  final Flower flower;
  final int qty;
  final bool matches;
  final VoidCallback? onAdd;

  const _TrayPot({
    required this.flower,
    required this.qty,
    required this.matches,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final empty = qty <= 0;

    final body = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: empty ? 0.38 : 1.0,
      child: Container(
        width: 78,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: matches && !empty
                ? const Color(0xFFFFB300)
                : const Color(0xFFF48FB1).withValues(alpha: 0.45),
            width: matches && !empty ? 2.4 : 1.5,
          ),
          boxShadow: matches && !empty
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.65),
                    blurRadius: 10,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 13,
              child: matches && !empty
                  ? Text(
                      '✓ MATCH',
                      style: GoogleFonts.nunito(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFB8860B),
                      ),
                    )
                  : null,
            ),
            FlowerImage(flower: flower, size: 36),
            const SizedBox(height: 2),
            Text(
              flower.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppColors.brownDark,
              ),
            ),
            Text(
              '×$qty',
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: empty ? Colors.grey : const Color(0xFFEC407A),
              ),
            ),
          ],
        ),
      ),
    );

    if (empty) return body;

    return GestureDetector(
      onTap: onAdd,
      child: Draggable<String>(
        data: flower.id,
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: flower.color.withValues(alpha: 0.9),
              boxShadow: [
                BoxShadow(
                  color: flower.color.withValues(alpha: 0.6),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(child: FlowerImage(flower: flower, size: 40)),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.35, child: body),
        child: body,
      ),
    );
  }
}

// ── Submit bar ─────────────────────────────────────────────────────────────────

class _SubmitBar extends StatefulWidget {
  final BouquetOrder order;
  final int count;
  final VoidCallback onSubmit;

  const _SubmitBar({
    required this.order,
    required this.count,
    required this.onSubmit,
  });

  @override
  State<_SubmitBar> createState() => _SubmitBarState();
}

class _SubmitBarState extends State<_SubmitBar>
    with SingleTickerProviderStateMixin {
  // Always-on gentle breathing; only applied to scale when the button is ready,
  // so a completed bouquet quietly invites the tap.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = widget.count >= widget.order.minFlowers;
    final needed = widget.order.minFlowers - widget.count;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) => Transform.scale(
          scale: ready ? 1.0 + 0.025 * _pulse.value : 1.0,
          child: child,
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: ready ? widget.onSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC407A),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.6),
              disabledForegroundColor: AppColors.brownLight,
              elevation: ready ? 6 : 0,
              shadowColor: const Color(0xFFEC407A).withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              ready
                  ? 'Give Bouquet  🎀'
                  : 'Add $needed more flower${needed == 1 ? '' : 's'}…',
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Daily-challenge completion toast ─────────────────────────────────────────

class _ChallengeToast extends StatelessWidget {
  final DailyChallenge challenge;

  const _ChallengeToast({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, (1 - t) * 16), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF43A047).withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Challenge complete!',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    challenge.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '+\$${challenge.reward}',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Result overlay ─────────────────────────────────────────────────────────────

class _ResultOverlay extends StatelessWidget {
  final OrderResult result;
  final int earned;

  const _ResultOverlay({required this.result, required this.earned});

  @override
  Widget build(BuildContext context) {
    final (emoji, text, color) = switch (result) {
      OrderResult.great => ('🌟', 'Perfect!', const Color(0xFFFFB300)),
      OrderResult.good => ('💚', 'They loved it!', const Color(0xFF4CAF50)),
      OrderResult.poor => ('😔', 'Not quite right…', const Color(0xFFE57373)),
      _ => ('⏳', '', Colors.grey),
    };

    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1.0),
            duration: const Duration(milliseconds: 350),
            curve: Curves.elasticOut,
            builder: (_, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 30, vertical: 22),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: color, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 52)),
                  Text(
                    text,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.inkBrown,
                    ),
                  ),
                  if (earned > 0)
                    Text(
                      '+\$$earned',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
