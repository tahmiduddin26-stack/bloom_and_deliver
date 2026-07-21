import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/flower_data.dart';
import '../models/flower.dart';
import '../models/growing_plant.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/flower_image.dart';

/// A row of 3 terracotta windowsill pots shown above the inventory shelf.
/// Empty slots can be tapped to plant a seed; ready plots glow and can be tapped
/// to harvest.
class WindowsillPlots extends ConsumerStatefulWidget {
  const WindowsillPlots({super.key});

  @override
  ConsumerState<WindowsillPlots> createState() => _WindowsillPlotsState();
}

class _WindowsillPlotsState extends ConsumerState<WindowsillPlots> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Refresh every 30 s so progress bars and countdowns update.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plots = ref.watch(gameProvider.select((s) => s.windowsillPlots));

    return SizedBox(
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (slot) {
          final plant = plots.cast<GrowingPlant?>().firstWhere(
                (p) => p?.slot == slot,
                orElse: () => null,
              );
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _PlotPot(slot: slot, plant: plant),
          );
        }),
      ),
    );
  }
}

// ── Single pot ────────────────────────────────────────────────────────────────

class _PlotPot extends ConsumerWidget {
  final int slot;
  final GrowingPlant? plant;

  const _PlotPot({required this.slot, required this.plant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReady = plant?.isReady ?? false;

    return GestureDetector(
      onTap: () {
        if (plant == null) {
          _showSeedPicker(context, ref, slot);
        } else if (isReady) {
          ref.read(gameProvider.notifier).harvestPlant(slot);
          AudioService.instance.play(GameSound.coin);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🌸 Harvested! Added to your shelf.',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: AppColors.gardenGreenMid,
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: 72,
        height: 76,
        decoration: BoxDecoration(
          color: isReady
              ? AppColors.sunflowerGold.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isReady
                ? AppColors.sunflowerGold.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.12),
            width: isReady ? 2 : 1,
          ),
          boxShadow: isReady
              ? [
                  BoxShadow(
                    color: AppColors.sunflowerGold.withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: plant == null ? _EmptySlot() : _PlantView(plant: plant!),
      ),
    );
  }

  void _showSeedPicker(BuildContext context, WidgetRef ref, int slot) {
    final state = ref.read(gameProvider);
    final money = state.money;
    final day = state.day;
    final growable = allFlowers
        .where((f) => f.isGrowable && f.unlockDay <= day)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SeedPickerSheet(
        growable: growable,
        money: money,
        slot: slot,
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🪴', style: TextStyle(fontSize: 22)),
          const SizedBox(height: 2),
          Text(
            'Plant seed',
            style: GoogleFonts.nunito(
              fontSize: 9,
              color: Colors.white.withValues(alpha: 0.40),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
}

class _PlantView extends StatelessWidget {
  final GrowingPlant plant;

  const _PlantView({required this.plant});

  @override
  Widget build(BuildContext context) {
    final flower = flowerById[plant.flowerId];
    final progress = plant.progress;
    final isReady = plant.isReady;

    // Growth stage emoji
    final stageEmoji = isReady
        ? (flower?.emoji ?? '🌸')
        : progress < 0.4
            ? '🌱'
            : '🌿';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(stageEmoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 3),
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(
                isReady ? AppColors.sunflowerGold : AppColors.sage,
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          isReady ? 'Tap! 🌸' : plant.timeRemaining,
          style: GoogleFonts.nunito(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            color: isReady
                ? AppColors.sunflowerGold
                : Colors.white.withValues(alpha: 0.55),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Seed picker sheet ─────────────────────────────────────────────────────────

class _SeedPickerSheet extends ConsumerWidget {
  final List<Flower> growable;
  final int money;
  final int slot;

  const _SeedPickerSheet({
    required this.growable,
    required this.money,
    required this.slot,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C2A1C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text('🌱', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Choose a Seed',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gardenGreenMid.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
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
            ],
          ),
          const SizedBox(height: 14),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: growable.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final flower = growable[i];
                final canAfford = money >= (flower.seedPrice ?? 0);
                return _SeedRow(
                  flower: flower,
                  canAfford: canAfford,
                  onTap: () {
                    Navigator.pop(context);
                    final ok = ref
                        .read(gameProvider.notifier)
                        .plantSeed(flower.id, slot);
                    if (ok) {
                      AudioService.instance.play(GameSound.flowerDrop);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '🌱 ${flower.name} seed planted! '
                            'Ready in ${flower.growthMinutes} min.',
                            style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w700),
                          ),
                          duration: const Duration(seconds: 3),
                          backgroundColor: AppColors.gardenGreenMid,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SeedRow extends StatelessWidget {
  final Flower flower;
  final bool canAfford;
  final VoidCallback onTap;

  const _SeedRow({
    required this.flower,
    required this.canAfford,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canAfford ? onTap : null,
      child: AnimatedOpacity(
        opacity: canAfford ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            children: [
              FlowerImage(flower: flower, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flower.name,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '⏱ ${flower.growthMinutes} min  •  free flower when ready',
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.50),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: canAfford
                      ? const LinearGradient(
                          colors: [Color(0xFF5DBB8A), Color(0xFF3A9068)],
                        )
                      : null,
                  color: canAfford ? null : Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '\$${flower.seedPrice}',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
