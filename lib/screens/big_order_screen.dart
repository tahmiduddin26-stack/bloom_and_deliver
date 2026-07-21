import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/flower_data.dart';
import '../models/big_order.dart';
import '../models/flower.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/flower_image.dart';

/// Full-screen workspace for submitting one day's contribution to a big order.
class BigOrderScreen extends ConsumerStatefulWidget {
  /// Called after the bouquet is submitted or the user cancels.
  final VoidCallback onDone;

  const BigOrderScreen({super.key, required this.onDone});

  @override
  ConsumerState<BigOrderScreen> createState() => _BigOrderScreenState();
}

class _BigOrderScreenState extends ConsumerState<BigOrderScreen> {
  /// Result shown after submission — null while still building.
  ContributionResult? _submittedResult;

  /// Uses the shared provider workspace so inventory deductions are consistent.
  void _addFlower(String flowerId) {
    final state = ref.read(gameProvider);
    final order = state.activeBigOrder;
    if (order == null) return;
    final wsLen = state.bouquetWorkspace.length;
    if (wsLen >= order.maxFlowers) return;
    ref.read(gameProvider.notifier).addFlowerToWorkspace(flowerId);
  }

  void _removeFlower(int idx) {
    ref.read(gameProvider.notifier).removeFlowerFromWorkspace(idx);
  }

  void _submit() {
    final workspace = ref.read(gameProvider).bouquetWorkspace;
    if (workspace.isEmpty) return;
    // contributeBigOrder scores the bouquet AND clears the workspace internally
    final result =
        ref.read(gameProvider.notifier).contributeBigOrder(workspace);
    if (result != null) {
      AudioService.instance.play(switch (result) {
        ContributionResult.great => GameSound.greatOrder,
        ContributionResult.poor => GameSound.poorOrder,
        _ => GameSound.coin,
      });
      setState(() => _submittedResult = result);
    }
  }

  @override
  void dispose() {
    // If the user leaves without submitting, return workspace flowers
    if (_submittedResult == null) {
      ref.read(gameProvider.notifier).clearWorkspace();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final order = state.activeBigOrder;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Commission')),
        body: const Center(child: Text('No active commission.')),
      );
    }

    final workspace = state.bouquetWorkspace;
    final dayIdx = order.nextDayIndex ?? 0;
    final minFlowers = order.minFlowers;
    final canSubmit = workspace.length >= minFlowers && _submittedResult == null;

    return Scaffold(
      backgroundColor: const Color(0xFF1A2C20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A3D2A),
        foregroundColor: Colors.white,
        title: Text(
          '${order.emoji}  ${order.name}',
          style: GoogleFonts.playfairDisplay(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          // clearWorkspace is called in dispose() if not submitted
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // ── Progress chips ─────────────────────────────────────────────────
          _CommissionProgress(order: order),

          // ── Story for today ────────────────────────────────────────────────
          if (_submittedResult == null)
            _DayStoryCard(story: order.dayStories[dayIdx]),

          // ── Result card ────────────────────────────────────────────────────
          if (_submittedResult != null)
            _ResultCard(result: _submittedResult!, onDone: widget.onDone),

          // ── Workspace ──────────────────────────────────────────────────────
          if (_submittedResult == null) ...[
            _WorkspaceStrip(
              flowers: workspace,
              maxFlowers: order.maxFlowers,
              onRemove: _removeFlower,
            ),
            // ── Flower picker ────────────────────────────────────────────────
            Expanded(
              child: _FlowerPicker(
                inventory: state.inventory,
                day: state.day,
                onAdd: _addFlower,
              ),
            ),
            // ── Submit bar ────────────────────────────────────────────────────
            _SubmitBar(
              canSubmit: canSubmit,
              minFlowers: minFlowers,
              current: workspace.length,
              onSubmit: _submit,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Commission progress bar ────────────────────────────────────────────────────

class _CommissionProgress extends StatelessWidget {
  final BigOrder order;

  const _CommissionProgress({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      color: const Color(0xFF2A3D2A),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final contrib = order.contributions[i];
          final isDone = contrib.isSubmitted;
          final isNext = !isDone && i == order.daysSubmitted;
          final col = switch (contrib.result) {
            ContributionResult.great => AppColors.sunflowerGold,
            ContributionResult.good => AppColors.sageDark,
            ContributionResult.poor => AppColors.carnationCoral,
            _ => Colors.white24,
          };
          return Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: isNext ? 40 : 32,
                height: isNext ? 40 : 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? col : Colors.white12,
                  border: isNext
                      ? Border.all(color: Colors.white60, width: 2)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  isDone ? '✓' : '${i + 1}',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              if (i < 2)
                Container(
                  width: 28,
                  height: 2,
                  color: i < order.daysSubmitted
                      ? AppColors.sageDark
                      : Colors.white24,
                ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Day story card ─────────────────────────────────────────────────────────────

class _DayStoryCard extends StatelessWidget {
  final String story;

  const _DayStoryCard({required this.story});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💌', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              story,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Workspace strip ────────────────────────────────────────────────────────────

class _WorkspaceStrip extends StatelessWidget {
  final List<Flower> flowers;
  final int maxFlowers;
  final void Function(int) onRemove;

  const _WorkspaceStrip({
    required this.flowers,
    required this.maxFlowers,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          // Slots
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: maxFlowers,
              itemBuilder: (_, i) {
                if (i < flowers.length) {
                  return GestureDetector(
                    onTap: () => onRemove(i),
                    child: Container(
                      width: 56,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FlowerImage(flower: flowers[i], size: 28),
                          const SizedBox(height: 2),
                          const Text('✕',
                              style: TextStyle(fontSize: 8, color: Colors.white54)),
                        ],
                      ),
                    ),
                  );
                }
                return Container(
                  width: 56,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10)),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Text(
              '${flowers.length}/$maxFlowers',
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: Colors.white54,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Flower picker ──────────────────────────────────────────────────────────────

class _FlowerPicker extends StatelessWidget {
  final Map<String, int> inventory;
  final int day;
  final void Function(String) onAdd;

  const _FlowerPicker({
    required this.inventory,
    required this.day,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final available = unlockedFlowers(day)
        .where((f) => (inventory[f.id] ?? 0) > 0)
        .toList();

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: available.length,
      itemBuilder: (_, i) {
        final flower = available[i];
        final qty = inventory[flower.id] ?? 0;
        return GestureDetector(
          onTap: () => onAdd(flower.id),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FlowerImage(flower: flower, size: 28),
                const SizedBox(height: 3),
                Text(
                  flower.name,
                  style: GoogleFonts.nunito(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '×$qty',
                  style: GoogleFonts.nunito(
                    fontSize: 9,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Submit bar ─────────────────────────────────────────────────────────────────

class _SubmitBar extends StatelessWidget {
  final bool canSubmit;
  final int minFlowers;
  final int current;
  final VoidCallback onSubmit;

  const _SubmitBar({
    required this.canSubmit,
    required this.minFlowers,
    required this.current,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3D2A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: canSubmit ? onSubmit : null,
        icon: const Text('🎀', style: TextStyle(fontSize: 18)),
        label: Text(
          canSubmit
              ? 'Submit Contribution'
              : 'Need $minFlowers+ flowers ($current added)',
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          backgroundColor: canSubmit
              ? AppColors.gardenGreenMid
              : Colors.white12,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white30,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

// ── Result card ────────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final ContributionResult result;
  final VoidCallback onDone;

  const _ResultCard({required this.result, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final (emoji, label, color) = switch (result) {
      ContributionResult.great => ('🌟', 'Outstanding!', AppColors.sunflowerGold),
      ContributionResult.good => ('✅', 'Well done!', AppColors.sageDark),
      ContributionResult.poor => ('😔', 'Not quite…', AppColors.carnationCoral),
      _ => ('⏳', 'Submitted', AppColors.brownLight),
    };

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result == ContributionResult.poor
                ? 'The vibes weren\'t quite right today.'
                : 'Day\'s contribution delivered!',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gardenGreenMid,
              foregroundColor: Colors.white,
              minimumSize: const Size(180, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Continue →',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Navigation helper ──────────────────────────────────────────────────────────

Future<void> openBigOrderScreen(
  BuildContext context, {
  required VoidCallback onDone,
}) =>
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => BigOrderScreen(onDone: () {
          Navigator.of(context).pop();
          onDone();
        }),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );
