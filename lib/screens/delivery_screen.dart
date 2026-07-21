import 'package:flutter/material.dart';

import '../config/feature_flags.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/flower_data.dart';
import '../models/delivery_mission.dart';
import '../models/flower.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/flower_image.dart';

/// Full delivery screen shown after the day ends but before the market.
/// Player can complete 0–3 optional missions, each requiring a fresh bouquet.
class DeliveryScreen extends ConsumerStatefulWidget {
  final VoidCallback onDone; // called when player taps "Go to Market"

  const DeliveryScreen({super.key, required this.onDone});

  @override
  ConsumerState<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends ConsumerState<DeliveryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideIn;

  String? _activeMissionId; // which mission is being built
  final List<Flower> _workspace = [];

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _slideIn = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final missions = ref.watch(
      gameProvider.select((s) => s.pendingDeliveries),
    );
    final money = ref.watch(gameProvider.select((s) => s.money));
    final day = ref.watch(gameProvider.select((s) => s.day));
    final unlocked = unlockedFlowers(day);

    return Scaffold(
      body: SlideTransition(
        position: _slideIn,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1C3022), Color(0xFF0F1F14)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _DeliveryHeader(money: money, onSkip: widget.onDone),
                Expanded(
                  child: _activeMissionId == null
                      ? _MissionList(
                          missions: missions,
                          onSelect: (id) =>
                              setState(() { _activeMissionId = id; _workspace.clear(); }),
                          onDone: widget.onDone,
                        )
                      : _BuildView(
                          mission: missions.firstWhere(
                              (m) => m.id == _activeMissionId),
                          workspace: _workspace,
                          unlocked: unlocked,
                          onAddFlower: (f) => setState(() => _workspace.add(f)),
                          onRemoveLast: () {
                            if (_workspace.isNotEmpty) {
                              setState(() => _workspace.removeLast());
                            }
                          },
                          onSubmit: () {
                            final result = ref
                                .read(gameProvider.notifier)
                                .submitDelivery(_activeMissionId!, _workspace);
                            setState(() => _activeMissionId = null);
                            _showResultSnack(result);
                          },
                          onCancel: () =>
                              setState(() => _activeMissionId = null),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showResultSnack(DeliveryResult result) {
    AudioService.instance.play(switch (result) {
      DeliveryResult.great => GameSound.greatOrder,
      DeliveryResult.poor => GameSound.poorOrder,
      _ => GameSound.coin,
    });
    final (msg, color) = switch (result) {
      DeliveryResult.great => ('🌟 Perfect delivery! Bonus earned!', AppColors.sunflowerGold),
      DeliveryResult.good  => ('✅ Good delivery! Payment received.', AppColors.sage),
      DeliveryResult.poor  => ('😔 They were a little disappointed…', AppColors.carnationCoral),
      _                    => ('', AppColors.brownLight),
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _DeliveryHeader extends StatelessWidget {
  final int money;
  final VoidCallback onSkip;

  const _DeliveryHeader({required this.money, required this.onSkip});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2A5C3A), Color(0xFF1A3A25)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.40),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('🚲', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Evening Deliveries',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warmWhite,
                    ),
                  ),
                  Text(
                    'Optional — skip anytime',
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      color: AppColors.cream.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            // Wallet chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.gardenGreenMid.withValues(alpha: 0.30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '🪙 \$$money',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.sage,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onSkip,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Market →',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.70),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

// ── Mission list ──────────────────────────────────────────────────────────────

class _MissionList extends StatelessWidget {
  final List<DeliveryMission> missions;
  final ValueChanged<String> onSelect;
  final VoidCallback onDone;

  const _MissionList({
    required this.missions,
    required this.onSelect,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = missions.where((m) => !m.isCompleted).length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Text(
                '$remaining mission${remaining == 1 ? '' : 's'} available',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: missions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _MissionCard(
              mission: missions[i],
              onTap: missions[i].isCompleted
                  ? null
                  : () => onSelect(missions[i].id),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ElevatedButton.icon(
            onPressed: onDone,
            icon: const Text('🌷', style: TextStyle(fontSize: 18)),
            label: Text(
              'Visit the Market →',
              style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppColors.gardenGreenMid,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MissionCard extends StatelessWidget {
  final DeliveryMission mission;
  final VoidCallback? onTap;

  const _MissionCard({required this.mission, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = mission.isCompleted;
    final resultColor = switch (mission.result) {
      DeliveryResult.great => AppColors.sunflowerGold,
      DeliveryResult.good  => AppColors.sage,
      DeliveryResult.poor  => AppColors.carnationCoral,
      _                    => Colors.white,
    };

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: done ? 0.65 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: done
                  ? resultColor.withValues(alpha: 0.50)
                  : Colors.white.withValues(alpha: 0.10),
              width: done ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(mission.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission.location,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          mission.description,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!done)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5DBB8A), Color(0xFF3A9068)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '+\$${mission.reward}',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    Text(
                      mission.result == DeliveryResult.great
                          ? '🌟 +\$${mission.earned}'
                          : mission.result == DeliveryResult.good
                              ? '✅ +\$${mission.earned}'
                              : '😔 +\$${mission.earned}',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: resultColor,
                      ),
                    ),
                ],
              ),
              if (done && mission.storySnippet.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '"${mission.storySnippet}"',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withValues(alpha: 0.65),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
              if (!done) ...[
                const SizedBox(height: 8),
                // Vibe chips
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: mission.requiredVibes.map((v) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: v.color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: v.color.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        v.label,
                        style: GoogleFonts.nunito(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                Text(
                  '${mission.minFlowers}–${mission.maxFlowers} flowers',
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.38),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Build view ────────────────────────────────────────────────────────────────

class _BuildView extends StatelessWidget {
  final DeliveryMission mission;
  final List<Flower> workspace;
  final List<Flower> unlocked;
  final ValueChanged<Flower> onAddFlower;
  final VoidCallback onRemoveLast;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const _BuildView({
    required this.mission,
    required this.workspace,
    required this.unlocked,
    required this.onAddFlower,
    required this.onRemoveLast,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        workspace.length >= mission.minFlowers &&
        workspace.length <= mission.maxFlowers;

    return Column(
      children: [
        // Mission hint card
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mission.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.location,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        mission.hint,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withValues(alpha: 0.70),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: mission.requiredVibes.map((v) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: v.color.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            v.label,
                            style: GoogleFonts.nunito(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Workspace: flowers added so far
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              Text(
                'Your bouquet (${workspace.length}/${mission.maxFlowers})',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              const Spacer(),
              if (workspace.isNotEmpty)
                GestureDetector(
                  onTap: onRemoveLast,
                  child: Text(
                    '↩ Undo',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.carnationCoral.withValues(alpha: 0.80),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 52,
          child: workspace.isEmpty
              ? Center(
                  child: Text(
                    'Tap flowers below to add them',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: workspace.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) => Column(
                    children: [
                      FlowerImage(flower: workspace[i], size: 34),
                      Text(
                        workspace[i].emoji,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
        ),
        const Divider(color: Colors.white12, height: 1),
        // Flower picker grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: unlocked.length,
            itemBuilder: (_, i) {
              final f = unlocked[i];
              final disabled = workspace.length >= mission.maxFlowers;
              return GestureDetector(
                onTap: disabled ? null : () => onAddFlower(f),
                child: AnimatedOpacity(
                  opacity: disabled ? 0.4 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FlowerImage(flower: f, size: 36),
                        const SizedBox(height: 3),
                        Text(
                          f.name,
                          style: GoogleFonts.nunito(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.80),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Bottom bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: onCancel,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('✕', style: TextStyle(color: Colors.white54, fontSize: 16)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canSubmit ? onSubmit : null,
                  icon: const Text('🚲', style: TextStyle(fontSize: 18)),
                  label: Text(
                    'Deliver (${mission.minFlowers}–${mission.maxFlowers} flowers)',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    backgroundColor: AppColors.gardenGreenMid,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white12,
                    disabledForegroundColor: Colors.white38,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Push the delivery screen on top of the current route.
Future<void> openDeliveryScreen(
  BuildContext context, {
  required VoidCallback onDone,
}) {
  if (!Features.deliveries) return Future<void>.value();
  return Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => DeliveryScreen(onDone: () {
        Navigator.of(context).pop();
        onDone();
      }),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 420),
    ),
  );
}
