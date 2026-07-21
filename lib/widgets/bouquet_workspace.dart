import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/bouquet_order.dart';
import '../models/flower.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import 'flower_image.dart';

class BouquetWorkspace extends ConsumerStatefulWidget {
  const BouquetWorkspace({super.key});

  @override
  ConsumerState<BouquetWorkspace> createState() => _BouquetWorkspaceState();
}

class _BouquetWorkspaceState extends ConsumerState<BouquetWorkspace>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startHover() {
    setState(() => _hovering = true);
    _pulseCtrl.repeat(reverse: true);
  }

  void _endHover() {
    setState(() => _hovering = false);
    _pulseCtrl.stop();
    _pulseCtrl.reset();
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(gameProvider.select((s) => s.bouquetWorkspace));
    final order = ref.watch(gameProvider.select((s) => s.currentOrder));
    final bonusSlots =
        ref.watch(gameProvider.select((s) => s.upgrades.workspaceBonusSlots));
    final minFlowers = order?.minFlowers ?? 3;
    // Include upgrade bonus slots so the UI agrees with the game logic.
    final maxFlowers = (order?.maxFlowers ?? 8) + bonusSlots;
    final atMax = workspace.length >= maxFlowers;
    final effectiveHovering = _hovering && !atMax;

    return DragTarget<String>(
      onWillAcceptWithDetails: (_) {
        if (!atMax) _startHover();
        return !atMax;
      },
      onLeave: (_) => _endHover(),
      onAcceptWithDetails: (details) {
        _endHover();
        ref.read(gameProvider.notifier).addFlowerToWorkspace(details.data);
      },
      builder: (context, _, __) {
        return AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) => Transform.scale(
            scale: effectiveHovering ? _pulse.value : 1.0,
            child: child,
          ),
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 60, 0),
            decoration: BoxDecoration(
              // Wooden table top
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: effectiveHovering
                    ? [
                        AppColors.floorWoodLight,
                        AppColors.floorWoodMid.withValues(alpha: 0.9),
                      ]
                    : [
                        AppColors.shelfWoodLight,
                        AppColors.shelfWoodMid,
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: effectiveHovering
                    ? AppColors.gardenGreenMid.withValues(alpha: 0.8)
                    : AppColors.shelfWoodDark.withValues(alpha: 0.5),
                width: effectiveHovering ? 3.0 : 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
                if (effectiveHovering)
                  BoxShadow(
                    color: AppColors.gardenGreenMid.withValues(alpha: 0.3),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
              ],
            ),
            child: Column(
              children: [
                _TableHeader(
                  count: workspace.length,
                  min: minFlowers,
                  max: maxFlowers,
                  atMax: atMax,
                ),
                // Live vibe-match checklist: which required vibes are covered
                if (order != null && !order.isMystery &&
                    order.requiredVibes.isNotEmpty)
                  _VibeChecklist(order: order, workspace: workspace),
                Expanded(
                  child: workspace.isEmpty
                      ? _EmptyTableHint(hovering: effectiveHovering)
                      : _FlowerArrangement(
                          flowers: workspace,
                          onRemove: (i) => ref
                              .read(gameProvider.notifier)
                              .removeFlowerFromWorkspace(i),
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

class _TableHeader extends ConsumerWidget {
  final int count;
  final int min;
  final int max;
  final bool atMax;

  const _TableHeader({
    required this.count,
    required this.min,
    required this.max,
    required this.atMax,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = count >= min;
    final hasFlowers = count > 0;
    final workspace = ref.watch(gameProvider.select((s) => s.bouquetWorkspace));
    final greensCount = workspace.where((f) => f.isFiller).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Text('✂️', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            'Your Bouquet',
            style: GoogleFonts.playfairDisplay(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.inkBrown,
            ),
          ),
          const Spacer(),
          // Greens badge — shown when at least one filler is in the workspace
          if (greensCount > 0) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4E8C5D).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF4E8C5D).withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 2),
                  Text(
                    '×$greensCount',
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF3A7248),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Undo button — only visible when workspace has flowers
          AnimatedOpacity(
            opacity: hasFlowers ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: hasFlowers
                  ? () => ref.read(gameProvider.notifier).undoLastFlower()
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: AppColors.brownLight.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.brownLight.withValues(alpha: 0.30),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('↩️', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 3),
                    Text(
                      'Undo',
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brownDark.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _CounterBadge(
            count: count,
            min: min,
            max: max,
            ready: ready,
            atMax: atMax,
          ),
        ],
      ),
    );
  }
}

/// Shows each required vibe as a chip; chips light up with a ✓ once a flower
/// carrying that vibe is in the workspace. Makes matching obvious at a glance.
class _VibeChecklist extends StatelessWidget {
  final BouquetOrder order;
  final List<Flower> workspace;

  const _VibeChecklist({required this.order, required this.workspace});

  @override
  Widget build(BuildContext context) {
    final coveredVibes = workspace.expand((f) => f.vibes).toSet();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      color: Colors.black.withValues(alpha: 0.06),
      child: Wrap(
        spacing: 5,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Match:',
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.brownDark.withValues(alpha: 0.65),
            ),
          ),
          ...order.requiredVibes.map((vibe) {
            final covered = coveredVibes.contains(vibe);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: covered
                    ? vibe.color.withValues(alpha: 0.85)
                    : vibe.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: vibe.color.withValues(alpha: covered ? 1.0 : 0.5),
                  width: 1.4,
                ),
                boxShadow: covered
                    ? [
                        BoxShadow(
                          color: vibe.color.withValues(alpha: 0.45),
                          blurRadius: 6,
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (covered) ...[
                    const Text('✓',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        )),
                    const SizedBox(width: 3),
                  ],
                  Text(
                    vibe.label,
                    style: GoogleFonts.nunito(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: covered
                          ? Colors.white
                          : AppColors.brownDark.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CounterBadge extends StatelessWidget {
  final int count, min, max;
  final bool ready, atMax;

  const _CounterBadge({
    required this.count,
    required this.min,
    required this.max,
    required this.ready,
    required this.atMax,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = atMax
        ? AppColors.terracottaDark.withValues(alpha: 0.25)
        : ready
            ? AppColors.gardenGreenMid.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.25);
    final textColor = atMax
        ? AppColors.potTerracottaDark
        : ready
            ? AppColors.gardenGreenDark
            : AppColors.brownDark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        atMax ? '🚫 $count/$max' : ready ? '✓ $count/$max' : '$count/$min min',
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}

class _EmptyTableHint extends StatefulWidget {
  final bool hovering;
  const _EmptyTableHint({required this.hovering});

  @override
  State<_EmptyTableHint> createState() => _EmptyTableHintState();
}

class _EmptyTableHintState extends State<_EmptyTableHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedOpacity(
        opacity: widget.hovering ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _float,
              builder: (_, child) =>
                  Transform.translate(offset: Offset(0, _float.value), child: child),
              child: Text(
                widget.hovering ? '🌸' : '💐',
                style: const TextStyle(fontSize: 44),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.hovering
                  ? 'Drop it here!'
                  : 'Drag flowers to craft\nyour bouquet',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.brownDark.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowerArrangement extends StatelessWidget {
  final List<Flower> flowers;
  final void Function(int) onRemove;

  const _FlowerArrangement({required this.flowers, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 72,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: flowers.length,
      itemBuilder: (context, i) => _WorkspaceFlower(
        flower: flowers[i],
        onRemove: () => onRemove(i),
      ),
    );
  }
}

class _WorkspaceFlower extends StatefulWidget {
  final Flower flower;
  final VoidCallback onRemove;

  const _WorkspaceFlower({required this.flower, required this.onRemove});

  @override
  State<_WorkspaceFlower> createState() => _WorkspaceFlowerState();
}

class _WorkspaceFlowerState extends State<_WorkspaceFlower>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: widget.onRemove,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.flower.color.withValues(alpha: 0.2),
            border: Border.all(
              color: widget.flower.color.withValues(alpha: 0.7),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.flower.color.withValues(alpha: 0.35),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: FlowerImage(flower: widget.flower, size: 34),
          ),
        ),
      ),
    );
  }
}
