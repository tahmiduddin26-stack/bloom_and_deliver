import 'package:flutter/material.dart';

import '../config/feature_flags.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../data/flower_data.dart';
import '../data/seasonal_events_data.dart';
import '../data/shop_decor_data.dart';
import '../models/bouquet_order.dart';
import '../models/bouquet_preset.dart';
import '../models/flower.dart';
import '../models/shop_decoration.dart';
import '../models/florist_rank.dart';
import '../models/seasonal_event.dart';
import '../providers/game_provider.dart';
import '../services/ad_service.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bouquet_share_card.dart';
import '../widgets/achievement_popup.dart';
import '../widgets/bouquet_workspace.dart';
import '../widgets/customer_phone.dart';
import '../widgets/daily_challenges_strip.dart';
import '../widgets/end_of_day_dialog.dart';
import '../widgets/inventory_shelf.dart';
import '../widgets/memory_popup.dart';
import '../widgets/reputation_board.dart';
import '../widgets/seasonal_banner.dart';
import '../widgets/sparkle_overlay.dart';
import '../widgets/story_arc_dialog.dart';
import '../widgets/tip_character.dart';
import '../widgets/windowsill_plots.dart';
import '../widgets/xp_rank_bar.dart';
import 'achievements_screen.dart';
import 'big_order_screen.dart';
import 'delivery_screen.dart';
import 'leaderboard_screen.dart';
import 'level_map_screen.dart';
import 'market_screen.dart';
import 'shop_decor_screen.dart';
import 'shop_interior_screen.dart';
import 'shop_stats_screen.dart';
import 'town_map_screen.dart';
import 'upgrades_screen.dart';
import 'vibe_notebook_screen.dart';
import 'wholesale_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  OrderResult? _lastResult;
  bool _showResultBanner = false;
  bool _showConfetti = false;

  // Share card data (populated after a great order)
  BouquetOrder? _lastGreatOrder;
  List<Flower> _lastGreatBouquet = [];
  int _lastEarned = 0;

  // Mute toggle state (mirrors AudioService)
  bool _isMuted = false;


  // Tip system
  bool _showTip = false;
  String _tipText = '';
  TipCharacterType _tipChar = TipCharacterType.florist;
  bool _welcomeShown = false;
  int _ordersSubmitted = 0;

  // Achievement popup queue
  String? _activeAchievementId;

  // Tier 2 — memory popup queue
  String? _activeMemoryKey;

  // Tier 4 — seasonal event banner
  bool _showSeasonalBanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _welcomeShown) return;
      _welcomeShown = true;
      // Check login streak on each app open
      ref.read(gameProvider.notifier).checkLoginStreak();
      final state = ref.read(gameProvider);
      final (tip, char) = _startupTip(state.day);
      _showTipMessage(tip, char);
    });
  }

  static (String, TipCharacterType) _startupTip(int day) {
    if (day == 1) {
      return (
        'Welcome to Bloom & Deliver! 🌸 Drag flowers from the shelves into your workspace, then submit a bouquet that matches the customer\'s vibe!',
        TipCharacterType.florist,
      );
    }
    if (day < 4) {
      return (
        'Day $day — keep an eye on the order hints! The customer\'s mood tells you what vibes they\'re after. 💐',
        TipCharacterType.helper,
      );
    }
    if (day < 7) {
      return (
        'You\'re on a roll! Day $day unlocks some beautiful new flowers at the market. Try mixing premium blooms for bigger tips! ✨',
        TipCharacterType.florist,
      );
    }
    return (
      'Day $day — regulars give loyalty bonuses. Keep them happy and the coins add up fast! ⭐',
      TipCharacterType.helper,
    );
  }

  void _showTipMessage(String text, TipCharacterType char) {
    setState(() {
      _tipText = text;
      _tipChar = char;
      _showTip = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);

    // ── Day-ended listener ──────────────────────────────────────────────────
    ref.listen(gameProvider.select((s) => s.dayEnded), (prev, next) {
      if (next && prev == false) {
        // Fire day-end notifications (wilt warnings + first-day permission req)
        _onDayEnded();
        Future.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          showEndOfDayDialog( // ignore: use_build_context_synchronously
            context,
            onGoToMarket: _openMarket,
            onGoToDeliveries: Features.deliveries ? _openDeliveries : null,
            onGoToBigOrder: Features.bigOrders ? _openBigOrder : null,
          );
        });
      }
    });

    // ── Low-inventory tip (only when crossing the threshold) ────────────────
    ref.listen(gameProvider.select((s) => s.inventory), (prev, next) {
      final prevTotal =
          prev?.values.fold(0, (a, b) => a + b) ?? 999;
      final total = next.values.fold(0, (a, b) => a + b);
      if (total < 8 && total > 0 && prevTotal >= 8 && !state.dayEnded) {
        _showTipMessage(
          'Running low on flowers! 🪴 Finish the day and head to the market to restock.',
          TipCharacterType.helper,
        );
      }
    });

    // ── Rank-up listener ────────────────────────────────────────────────────
    ref.listen(gameProvider.select((s) => s.pendingRankUp), (prev, next) {
      if (next != null && next != prev) {
        _showRankUpDialog(next);
      }
    });

    // ── Achievement popup listener ──────────────────────────────────────────
    ref.listen(
      gameProvider.select((s) => s.pendingAchievements),
      (prev, next) {
        if (next.isNotEmpty && _activeAchievementId == null) {
          setState(() => _activeAchievementId = next.first);
        }
      },
    );

    // ── Memory popup listener ───────────────────────────────────────────────
    ref.listen(
      gameProvider.select((s) => s.pendingMemories),
      (prev, next) {
        if (next.isNotEmpty && _activeMemoryKey == null) {
          setState(() => _activeMemoryKey = next.first);
        }
      },
    );

    // ── Story arc listener ──────────────────────────────────────────────────
    ref.listen(
      gameProvider.select((s) => s.pendingStoryChapterDay),
      (prev, next) {
        if (next != null && next != prev) {
          _showStoryChapter(next);
        }
      },
    );

    // ── Reputation board listener ───────────────────────────────────────────
    ref.listen(
      gameProvider.select((s) => s.pendingReputationBoard),
      (prev, next) {
        if (next && prev != true) {
          _showRepBoard();
        }
      },
    );

    // ── Seasonal event banner listener (Tier 4) ─────────────────────────────
    ref.listen(
      gameProvider.select((s) => s.pendingSeasonalBanner),
      (prev, next) {
        if (next && prev != true) {
          setState(() => _showSeasonalBanner = true);
        }
      },
    );

    // ── Active event for dynamic background ─────────────────────────────────
    final activeEvent = eventForDay(state.day);

    // ── Active decor visuals ─────────────────────────────────────────────────
    final wallpaperId = state.activeDecorId(
        ShopDecorCategory.wallpaper.name, 'wall_garden');
    final wallpaperDecor = decorById[wallpaperId] ?? wallpaperDefault;
    final wallpaperGradient =
        wallpaperDecor.gradientColors ?? wallpaperDefault.gradientColors!;

    final plantId = state.activeDecorId(
        ShopDecorCategory.windowPlant.name, 'plant_none');
    final plantEmoji = decorById[plantId]?.decorEmoji ?? '';

    final lightsId = state.activeDecorId(
        ShopDecorCategory.fairyLights.name, 'lights_none');
    final lightsEmoji = decorById[lightsId]?.decorEmoji ?? '';

    final counterId = state.activeDecorId(
        ShopDecorCategory.counter.name, 'counter_oak');
    final counterColor =
        decorById[counterId]?.accentColor ?? const Color(0xFF5C3A1E);

    final displayId = state.activeDecorId(
        ShopDecorCategory.windowDisplay.name, 'display_none');
    final displayEmoji = decorById[displayId]?.decorEmoji ?? '';

    // Event overrides wallpaper when active
    final bgColors =
        activeEvent?.backgroundGradient ?? wallpaperGradient;

    return Scaffold(
      body: SparkleOverlay(
        active: _showConfetti,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: bgColors,
              stops: const [0.0, 0.35, 0.70, 1.0],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // ── Main layout ─────────────────────────────────────────────
                Column(
                  children: [
                    // ── AdMob banner ────────────────────────────────────────
                    const _AdBanner(),
                    _TopBar(
                      day: state.day,
                      money: state.money,
                      loginStreak: state.loginStreak,
                      activeEvent: activeEvent,
                      isMuted: _isMuted,
                      onUpgrades: () => openUpgradesScreen(context),
                      onAchievements: () => openAchievementsScreen(context),
                      onNotebook: () => openVibeNotebook(context),
                      onDecor: () => openShopDecorScreen(context),
                      onStats: () => openShopStatsScreen(context),
                      onMute: _handleMuteToggle,
                      onLevelMap: () => openLevelMapAsRoot(context),
                      onTownMap: () => openTownMapScreen(
                        context,
                        onGoToShop: () => openShopInteriorScreen(context),
                        onGoToMarket: _openMarket,
                        onGoToWholesale: () => openWholesaleScreen(context),
                      ),
                      onLeaderboard: () => openLeaderboardScreen(context),
                    ),
                    // XP / Rank bar
                    const XpRankBar(),
                    // Result banner
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      transitionBuilder: (child, anim) => SizeTransition(
                        sizeFactor: anim,
                        axisAlignment: -1,
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: (_showResultBanner && _lastResult != null)
                          ? _ResultBanner(
                              key: ValueKey(_lastResult),
                              result: _lastResult!,
                              onDismiss: () =>
                                  setState(() => _showResultBanner = false),
                              onShare: _lastResult == OrderResult.great &&
                                      _lastGreatOrder != null
                                  ? _handleShare
                                  : null,
                            )
                          : const SizedBox.shrink(key: ValueKey('empty')),
                    ),
                    // Daily challenges strip
                    const SizedBox(height: 6),
                    // Right padding keeps these clear of the phone handle
                    const Padding(
                      padding: EdgeInsets.only(right: 46),
                      child: DailyChallengesStrip(),
                    ),
                    const SizedBox(height: 6),
                    // Fairy lights strip (Tier 5 decor)
                    if (lightsEmoji.isNotEmpty)
                      _FairyLightsStrip(emoji: lightsEmoji),
                    // Windowsill growing pots
                    const Padding(
                      padding: EdgeInsets.only(right: 46),
                      child: WindowsillPlots(),
                    ),
                    const SizedBox(height: 4),
                    // Flower inventory shelves — flexible so small screens
                    // shrink the shelf instead of overflowing
                    Flexible(
                      flex: 0,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                            maxHeight: 164, minHeight: 96),
                        child: InventoryShelf(),
                      ),
                    ),
                    // Wooden edge (tinted by counter decor)
                    _WoodenEdge(tint: counterColor),
                    // Workspace + submit bar
                    Expanded(
                      child: _WorkspaceSection(
                        onSubmit: _handleSubmit,
                        counterColor: counterColor,
                      ),
                    ),
                  ],
                ),
                // ── Window plant overlay (Tier 5 decor) ────────────────────
                if (plantEmoji.isNotEmpty)
                  Positioned(
                    left: 8,
                    top: 160,
                    child: _DecorEmoji(emoji: plantEmoji, size: 28),
                  ),
                // ── Window display badge (Tier 5 decor) ────────────────────
                if (displayEmoji.isNotEmpty)
                  Positioned(
                    left: 8,
                    top: 130,
                    child: _DecorEmoji(emoji: displayEmoji, size: 22),
                  ),
                // ── Phone overlay ───────────────────────────────────────────
                const Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.center,
                    child: CustomerPhone(),
                  ),
                ),
                // ── Tip character ───────────────────────────────────────────
                if (_showTip)
                  Positioned(
                    left: 0,
                    bottom: 68,
                    child: TipCharacter(
                      character: _tipChar,
                      tip: _tipText,
                      autoDismissAfter: const Duration(seconds: 8),
                      onDismiss: () => setState(() => _showTip = false),
                    ),
                  ),
                // ── Achievement popup ───────────────────────────────────────
                if (_activeAchievementId != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: AchievementPopup(
                      achievementId: _activeAchievementId!,
                      onDismiss: _onAchievementDismissed,
                    ),
                  ),
                // ── Memory popup ────────────────────────────────────────────
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
                // ── Seasonal event banner (Tier 4) ──────────────────────────
                if (_showSeasonalBanner && activeEvent != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SeasonalBanner(
                      event: activeEvent,
                      onDismissed: () =>
                          setState(() => _showSeasonalBanner = false),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Event handlers ──────────────────────────────────────────────────────────

  void _handleSubmit() {
    HapticFeedback.mediumImpact();
    AudioService.instance.play(GameSound.submit);

    // Capture order + bouquet BEFORE submitting (cleared by provider after).
    final stateSnap = ref.read(gameProvider);
    final capturedOrder = stateSnap.currentOrder;
    // bouquetWorkspace is List<Flower> in the game state model.
    final capturedBouquet = List<Flower>.from(stateSnap.bouquetWorkspace);
    final moneyBefore = stateSnap.money;

    final result = ref.read(gameProvider.notifier).submitBouquet();
    final moneyAfter = ref.read(gameProvider).money;
    final earned = (moneyAfter - moneyBefore).clamp(0, 99999);

    if (result == OrderResult.great) {
      Future.delayed(
          const Duration(milliseconds: 150), HapticFeedback.heavyImpact);
      AudioService.instance.play(GameSound.greatOrder);
      AudioService.instance.play(GameSound.coin);
      if (capturedOrder != null) {
        _lastGreatOrder = capturedOrder;
        _lastGreatBouquet = capturedBouquet;
        _lastEarned = earned;
      }
    } else if (result == OrderResult.poor) {
      AudioService.instance.play(GameSound.poorOrder);
    } else {
      AudioService.instance.play(GameSound.coin);
    }

    setState(() {
      _lastResult = result;
      _showResultBanner = true;
      _showConfetti = result == OrderResult.great;
      _ordersSubmitted++;
    });

    if (_showConfetti) {
      Future.delayed(const Duration(milliseconds: 2400), () {
        if (mounted) setState(() => _showConfetti = false);
      });
    }

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showResultBanner = false);
    });

    if (result == OrderResult.great && _ordersSubmitted == 1) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _showTipMessage(
            'Amazing! 🌟 Regular customers give you a loyalty bonus — keep them happy for extra cash!',
            TipCharacterType.florist,
          );
        }
      });
    }
    if (result == OrderResult.poor && _ordersSubmitted <= 3) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _showTipMessage(
            'Not quite right… 😔 Read the customer\'s message carefully — it hints at the vibes they want!',
            TipCharacterType.helper,
          );
        }
      });
    }
  }

  void _handleMuteToggle() async {
    await AudioService.instance.toggleMute();
    setState(() => _isMuted = AudioService.instance.isMuted);
  }

  void _handleShare() {
    if (_lastGreatOrder == null) return;
    showShareSheet(
      context: context,
      order: _lastGreatOrder!,
      bouquet: _lastGreatBouquet,
      earned: _lastEarned,
    );
  }

  /// Called once per day when all orders are served.
  /// Requests notification permission on Day 1, then fires wilt warnings
  /// for any flowers that are close to expiring.
  void _onDayEnded() async {
    final state = ref.read(gameProvider);

    // Day 1 completion → ask for notification permission and schedule daily reminder
    if (state.day == 1) {
      final granted =
          await NotificationService.instance.requestPermissions();
      if (granted) {
        await NotificationService.instance.scheduleDailyReminder(
          hour: 10,
          minute: 0,
        );
      }
    }

    // Fire a wilt warning for the first nearly-wilted flower found
    final notifier = ref.read(gameProvider.notifier);
    for (final flowerId in state.inventory.keys) {
      if (notifier.isNearlyWilted(flowerId)) {
        final flower = allFlowers.firstWhere(
          (f) => f.id == flowerId,
          orElse: () => allFlowers.first,
        );
        await NotificationService.instance.showWiltWarning(flower.name);
        break; // one warning per day is enough
      }
    }
  }

  void _openMarket() {
    openMarketScreen(
      context,
      onStartNextDay: () {
        ref.read(gameProvider.notifier).startNextDay();
        // Back to the level map — the next level node is now unlocked.
        if (mounted) openLevelMapAsRoot(context);
      },
    );
  }

  void _openDeliveries() {
    openDeliveryScreen(
      context,
      onDone: _openMarket,
    );
  }

  void _openBigOrder() {
    openBigOrderScreen(
      context,
      onDone: _openMarket,
    );
  }

  void _onAchievementDismissed() {
    ref.read(gameProvider.notifier).popPendingAchievement();
    setState(() => _activeAchievementId = null);

    // Show next achievement in queue (if any)
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

    // Chain next memory if queued
    final next = ref.read(gameProvider).pendingMemories;
    if (next.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _activeMemoryKey = next.first);
      });
    }
  }

  void _showStoryChapter(int day) {
    ref.read(gameProvider.notifier).clearPendingStoryChapter();
    showStoryArcDialog(context, day, () {});
  }

  void _showRepBoard() {
    ref.read(gameProvider.notifier).clearPendingReputationBoard();
    final state = ref.read(gameProvider);
    // Week number = how many full 7-day cycles have completed
    final week = ((state.day - 1) / 7).ceil();
    showReputationBoard(
      context,
      week: week,
      playerScore: state.reputationScore,
      onClose: () {},
    );
  }

  void _showRankUpDialog(FloristRank newRank) {
    ref.read(gameProvider.notifier).clearPendingRankUp();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _RankUpDialog(rank: newRank),
    );
  }
}

// ── Workspace section ──────────────────────────────────────────────────────────

class _WorkspaceSection extends ConsumerWidget {
  final VoidCallback onSubmit;
  final Color counterColor;

  const _WorkspaceSection({
    required this.onSubmit,
    required this.counterColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final workspaceCount =
        ref.watch(gameProvider.select((s) => s.bouquetWorkspace.length));
    final order = ref.watch(gameProvider.select((s) => s.currentOrder));
    final dayEnded = ref.watch(gameProvider.select((s) => s.dayEnded));
    final presets =
        ref.watch(gameProvider.select((s) => s.bouquetPresets));

    final canSubmit =
        !dayEnded && order != null && workspaceCount >= order.minFlowers;

    return Container(
      color: counterColor.withValues(alpha: 0.18),
      child: Column(
        children: [
          // Preset strip (shown only when presets exist or workspace non-empty)
          if (presets.isNotEmpty || workspaceCount > 0)
            _PresetStrip(
              presets: presets,
              workspaceCount: workspaceCount,
              notifier: notifier,
            ),
          // Fills whatever space remains instead of a fixed 240px block —
          // no more overlap with the submit bar on short screens.
          const Expanded(child: BouquetWorkspace()),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 60, 6),
            child: _SubmitBar(
              canSubmit: canSubmit,
              onSubmit: onSubmit,
              onClear: notifier.clearWorkspace,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Wooden edge ────────────────────────────────────────────────────────────────

class _WoodenEdge extends StatelessWidget {
  final Color tint;

  const _WoodenEdge({this.tint = const Color(0xFF5C3A1E)});

  @override
  Widget build(BuildContext context) {
    // Blend the tint with the standard wood colours
    final light = Color.lerp(AppColors.shelfWoodLight, tint, 0.25)!;
    final mid = Color.lerp(AppColors.shelfWoodMid, tint, 0.25)!;
    final dark = Color.lerp(AppColors.shelfWoodDark, tint, 0.25)!;

    return Container(
      height: 18,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [light, mid, dark],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(
          14,
          (_) => Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              height: 1,
              color: AppColors.shelfWoodDark.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────────
// Two-row layout:
//   Row 1 — logo, title, day chip, money chip, streak chip, mute
//   Row 2 — scrollable nav icons (upgrades, achievements, notebook…)

class _TopBar extends StatelessWidget {
  final int day;
  final int money;
  final int loginStreak;
  final SeasonalEvent? activeEvent;
  final bool isMuted;
  final VoidCallback onUpgrades;
  final VoidCallback onAchievements;
  final VoidCallback onNotebook;
  final VoidCallback onDecor;
  final VoidCallback onStats;
  final VoidCallback onMute;
  final VoidCallback onLevelMap;
  final VoidCallback onTownMap;
  final VoidCallback onLeaderboard;

  const _TopBar({
    required this.day,
    required this.money,
    required this.loginStreak,
    required this.onUpgrades,
    required this.onAchievements,
    required this.onNotebook,
    required this.onDecor,
    required this.onStats,
    required this.onMute,
    required this.onLevelMap,
    required this.onTownMap,
    required this.onLeaderboard,
    this.activeEvent,
    this.isMuted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3D2010), Color(0xFF6B3A1E), Color(0xFF4A2814)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Row 1: title + chips ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                // Logo
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  child: const Center(
                    child: Text('🌸', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 7),
                // Title
                Expanded(
                  child: Text(
                    'Bloom & Deliver',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warmWhite,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                // Day chip
                _TopBarChip(
                  label: 'Day $day',
                  gradient: const [Color(0xFFE8956A), Color(0xFFC4694A)],
                  emoji: '☀️',
                ),
                const SizedBox(width: 5),
                // Money chip
                _TopBarChip(
                  label: '\$$money',
                  gradient: const [Color(0xFF5DBB8A), Color(0xFF3A9068)],
                  emoji: '🪙',
                ),
                // Optional streak chip
                if (loginStreak > 1) ...[
                  const SizedBox(width: 5),
                  _TopBarChip(
                    label: '${loginStreak}d',
                    gradient: const [Color(0xFFFF8C00), Color(0xFFE65C00)],
                    emoji: '🔥',
                  ),
                ],
                // Optional event chip
                if (activeEvent != null) ...[
                  const SizedBox(width: 5),
                  _TopBarChip(
                    emoji: activeEvent!.emoji,
                    label: '',
                    gradient: [
                      activeEvent!.backgroundGradient[1],
                      activeEvent!.backgroundGradient[0],
                    ],
                  ),
                ],
                // Mute button
                const SizedBox(width: 6),
                _NavIconButton(
                  emoji: isMuted ? '🔇' : '🔊',
                  tooltip: isMuted ? 'Unmute' : 'Mute',
                  onTap: onMute,
                  size: 28,
                ),
              ],
            ),
          ),
          // ── Row 2: scrollable nav icons ───────────────────────────────────
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              children: [
                _NavIconButton(
                  emoji: '🌸',
                  tooltip: 'Level Map',
                  onTap: onLevelMap,
                ),
                if (Features.upgrades) ...[
                  const SizedBox(width: 6),
                  _NavIconButton(
                    emoji: '🔨',
                    tooltip: 'Upgrades',
                    onTap: onUpgrades,
                  ),
                ],
                if (Features.achievements) ...[
                  const SizedBox(width: 6),
                  _NavIconButton(
                    emoji: '🏆',
                    tooltip: 'Achievements',
                    onTap: onAchievements,
                  ),
                ],
                if (Features.vibeNotebook) ...[
                  const SizedBox(width: 6),
                  _NavIconButton(
                    emoji: '📓',
                    tooltip: 'Vibe Notebook',
                    onTap: onNotebook,
                  ),
                ],
                if (Features.shopDecor) ...[
                  const SizedBox(width: 6),
                  _NavIconButton(
                    emoji: '🎨',
                    tooltip: 'Shop Decor',
                    onTap: onDecor,
                  ),
                ],
                if (Features.shopStats) ...[
                  const SizedBox(width: 6),
                  _NavIconButton(
                    emoji: '📊',
                    tooltip: 'Stats',
                    onTap: onStats,
                  ),
                ],
                if (Features.townMap) ...[
                  const SizedBox(width: 6),
                  _NavIconButton(
                    emoji: '🗺️',
                    tooltip: 'Town Map',
                    onTap: onTownMap,
                  ),
                ],
                if (Features.leaderboard) ...[
                  const SizedBox(width: 6),
                  _NavIconButton(
                    emoji: '🏅',
                    tooltip: 'Leaderboard',
                    onTap: onLeaderboard,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  final String emoji;
  final String tooltip;
  final VoidCallback onTap;
  final double size;

  const _NavIconButton({
    required this.emoji,
    required this.tooltip,
    required this.onTap,
    this.size = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
          ),
        ),
      ),
    );
  }
}

class _TopBarChip extends StatelessWidget {
  final String label;
  final List<Color> gradient;
  final String emoji;

  const _TopBarChip({
    required this.label,
    required this.gradient,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withValues(alpha: 0.45),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
}

// ── Submit bar ─────────────────────────────────────────────────────────────────

class _SubmitBar extends StatelessWidget {
  final bool canSubmit;
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  const _SubmitBar({
    required this.canSubmit,
    required this.onSubmit,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: canSubmit
                    ? const LinearGradient(
                        colors: [Color(0xFF5DBB8A), Color(0xFF3A9068)],
                      )
                    : null,
                boxShadow: canSubmit
                    ? [
                        BoxShadow(
                          color:
                              const Color(0xFF3A9068).withValues(alpha: 0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: ElevatedButton.icon(
                onPressed: canSubmit ? onSubmit : null,
                icon: const Text('🎀', style: TextStyle(fontSize: 20)),
                label: Text(
                  'Submit Bouquet',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(0, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  disabledBackgroundColor:
                      Colors.white.withValues(alpha: 0.10),
                  disabledForegroundColor:
                      Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onClear,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Text('🔄', style: TextStyle(fontSize: 22)),
                ),
              ),
            ),
          ),
        ],
      );
}

// ── Result banner ──────────────────────────────────────────────────────────────

class _ResultBanner extends StatelessWidget {
  final OrderResult result;
  final VoidCallback onDismiss;
  final VoidCallback? onShare;

  const _ResultBanner({
    super.key,
    required this.result,
    required this.onDismiss,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final (emoji, message, color) = switch (result) {
      OrderResult.great => (
          '🌟',
          'Perfect bouquet! The customer is over the moon!',
          AppColors.sunflowerGold,
        ),
      OrderResult.good => (
          '✅',
          'Nice bouquet! The customer was happy.',
          AppColors.mint,
        ),
      OrderResult.poor => (
          '😔',
          'Not quite right… the customer was disappointed.',
          AppColors.carnationCoral,
        ),
      _ => ('⏳', '', AppColors.brownLight),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: AppColors.inkBrown,
                fontSize: 13,
              ),
            ),
          ),
          // Share button (great orders only)
          if (onShare != null) ...[
            GestureDetector(
              onTap: onShare,
              child: Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: AppColors.gardenGreenMid.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('📤', style: TextStyle(fontSize: 14)),
                ),
              ),
            ),
          ],
          GestureDetector(
            onTap: onDismiss,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.brownLight.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '✕',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.brownLight.withValues(alpha: 0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Preset strip ───────────────────────────────────────────────────────────────

class _PresetStrip extends StatelessWidget {
  final List<BouquetPreset> presets;
  final int workspaceCount;
  final GameNotifier notifier;

  const _PresetStrip({
    required this.presets,
    required this.workspaceCount,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        children: [
          // Save button (shown when workspace has flowers and < 5 presets)
          if (workspaceCount > 0 && presets.length < 5)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => _showSaveDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.gardenGreenMid.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.gardenGreenMid.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Text('💾', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        'Save',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Preset chips
          ...presets.map(
            (p) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => notifier.loadPreset(p.id),
                onLongPress: () => _showDeleteDialog(context, p),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.20)),
                  ),
                  child: Row(
                    children: [
                      const Text('🎀', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        p.name,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSaveDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.parchment,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Save Preset',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: AppColors.inkBrown,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: InputDecoration(
            hintText: 'Preset name…',
            hintStyle: GoogleFonts.nunito(color: AppColors.brownLight),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          style: GoogleFonts.nunito(color: AppColors.inkBrown),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.nunito(color: AppColors.brownLight)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              notifier.savePreset(controller.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gardenGreenMid,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child:
                Text('Save', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, BouquetPreset preset) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.parchment,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete "${preset.name}"?',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: AppColors.inkBrown,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.nunito(color: AppColors.brownLight)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              notifier.deletePreset(preset.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.carnationCoral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Delete',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

// ── Fairy lights strip ─────────────────────────────────────────────────────────

class _FairyLightsStrip extends StatelessWidget {
  final String emoji;

  const _FairyLightsStrip({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          12,
          (_) => Text(emoji, style: const TextStyle(fontSize: 13)),
        ),
      ),
    );
  }
}

// ── Decor emoji overlay ────────────────────────────────────────────────────────

class _DecorEmoji extends StatelessWidget {
  final String emoji;
  final double size;

  const _DecorEmoji({required this.emoji, required this.size});

  @override
  Widget build(BuildContext context) => Text(
        emoji,
        style: TextStyle(fontSize: size),
      );
}

// ── Rank-up dialog ─────────────────────────────────────────────────────────────

class _RankUpDialog extends StatefulWidget {
  final FloristRank rank;

  const _RankUpDialog({required this.rank});

  @override
  State<_RankUpDialog> createState() => _RankUpDialogState();
}

class _RankUpDialogState extends State<_RankUpDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.4)),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2A3D2A), Color(0xFF1A2C20)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFF5DBB8A).withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5DBB8A).withValues(alpha: 0.35),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Big emoji
                Text(
                  widget.rank.emoji,
                  style: const TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 12),
                Text(
                  'Rank Up!',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sunflowerGold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.rank.title,
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'ve levelled up to ${widget.rank.title}!\nKeep crafting beautiful bouquets. 🌸',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.75),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5DBB8A), Color(0xFF3A9068)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3A9068).withValues(alpha: 0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      'Keep Blooming! 🌺',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
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

// ── AdMob banner widget ────────────────────────────────────────────────────────
//
// Renders the loaded banner ad at its natural size (320×50).
// Collapses to zero height while the ad is loading so the layout
// doesn't jump when the ad appears.

class _AdBanner extends StatefulWidget {
  const _AdBanner();

  @override
  State<_AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<_AdBanner> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loaded = AdService.instance.isLoaded;
    AdService.instance.onAdStateChanged = () {
      if (mounted) setState(() => _loaded = AdService.instance.isLoaded);
    };
  }

  @override
  void dispose() {
    // Only clear the callback if this widget still owns it
    if (AdService.instance.onAdStateChanged != null) {
      AdService.instance.onAdStateChanged = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = AdService.instance.bannerAd;
    if (!_loaded || ad == null) return const SizedBox.shrink();

    return Container(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      alignment: Alignment.center,
      color: Colors.black,
      child: AdWidget(ad: ad),
    );
  }
}
