import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/flower_data.dart';
import '../models/flower.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import 'flower_image.dart';

/// Scrollable area of wooden shelves holding flower pots.
class InventoryShelf extends ConsumerWidget {
  const InventoryShelf({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final visible = unlockedFlowers(state.day);

    // Vibes the current order asks for — matching pots get a golden halo.
    final order = state.currentOrder;
    final wantedVibes = (order != null && !order.isMystery)
        ? order.requiredVibes.toSet()
        : <VibeTag>{};

    // Split flowers into rows of 5 per shelf
    const perRow = 5;
    final rows = <List<Flower>>[];
    for (var i = 0; i < visible.length; i += perRow) {
      rows.add(visible.sublist(
          i, (i + perRow) > visible.length ? visible.length : i + perRow));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 12, 60, 8), // right pad for phone
      child: Column(
        children: rows.asMap().entries.map((entry) {
          return _ShelfRow(
            flowers: entry.value,
            inventory: state.inventory,
            notifier: notifier,
            wantedVibes: wantedVibes,
          );
        }).toList(),
      ),
    );
  }
}

class _ShelfRow extends StatelessWidget {
  final List<Flower> flowers;
  final Map<String, int> inventory;
  final GameNotifier notifier;
  final Set<VibeTag> wantedVibes;

  const _ShelfRow({
    required this.flowers,
    required this.inventory,
    required this.notifier,
    required this.wantedVibes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Pots row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: flowers.map((flower) {
            final qty = inventory[flower.id] ?? 0;
            final nearlyWilted = notifier.isNearlyWilted(flower.id);
            final freshness = notifier.freshnessRemaining(flower.id);
            final matchedVibes =
                flower.vibes.where(wantedVibes.contains).toList();
            return _FlowerPot(
              flower: flower,
              quantity: qty,
              nearlyWilted: nearlyWilted,
              freshnessDays: freshness,
              matchedVibes: matchedVibes,
            );
          }).toList(),
        ),
        // Wooden shelf plank
        _ShelfPlank(),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _ShelfPlank extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        height: 16,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.shelfWoodLight,
              AppColors.shelfWoodMid,
              AppColors.shelfWoodDark,
            ],
          ),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // Wood grain lines
        child: Row(
          children: List.generate(
            8,
            (_) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                height: 1,
                color: AppColors.shelfWoodDark.withValues(alpha: 0.25),
              ),
            ),
          ),
        ),
      );
}

class _FlowerPot extends ConsumerWidget {
  final Flower flower;
  final int quantity;
  final bool nearlyWilted;
  final int? freshnessDays;
  final List<VibeTag> matchedVibes;

  const _FlowerPot({
    required this.flower,
    required this.quantity,
    required this.nearlyWilted,
    this.freshnessDays,
    this.matchedVibes = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEmpty = quantity <= 0;

    return Draggable<String>(
      data: flower.id,
      onDragStarted: () {
        HapticFeedback.lightImpact();
        AudioService.instance.play(GameSound.flowerDrop);
      },
      feedback: _DragFeedback(flower: flower),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _PotBody(
          flower: flower,
          quantity: quantity,
          nearlyWilted: nearlyWilted,
          freshnessDays: freshnessDays,
          isEmpty: isEmpty,
          matchedVibes: matchedVibes,
        ),
      ),
      child: _PotBody(
        flower: flower,
        quantity: quantity,
        nearlyWilted: nearlyWilted,
        freshnessDays: freshnessDays,
        isEmpty: isEmpty,
        matchedVibes: matchedVibes,
      ),
    );
  }
}

class _PotBody extends StatelessWidget {
  final Flower flower;
  final int quantity;
  final bool nearlyWilted;
  final int? freshnessDays;
  final bool isEmpty;
  final List<VibeTag> matchedVibes;

  const _PotBody({
    required this.flower,
    required this.quantity,
    required this.nearlyWilted,
    required this.freshnessDays,
    required this.isEmpty,
    this.matchedVibes = const [],
  });

  // ── Filler / greens colour palette ───────────────────────────────────────────
  static const _fillerPotLight = Color(0xFF5A9B6A);
  static const _fillerPotDark = Color(0xFF3A7248);
  static const _fillerRimLight = Color(0xFF4E8C5D);
  static const _fillerRimDark = Color(0xFF2F6040);

  @override
  Widget build(BuildContext context) {
    final wiltColor = nearlyWilted ? Colors.orange[400]! : flower.color;
    final isFiller = flower.isFiller;

    // Pot rim colours
    final rimColors = isFiller
        ? [_fillerRimLight, _fillerRimDark]
        : [AppColors.potTerracottaLight, AppColors.potTerracottaDark];

    // Pot body colours
    final bodyColors = isEmpty
        ? (isFiller
            ? [_fillerPotLight.withValues(alpha: 0.35), _fillerPotDark.withValues(alpha: 0.25)]
            : [AppColors.potTerracotta.withValues(alpha: 0.4), AppColors.potTerracottaDark.withValues(alpha: 0.3)])
        : nearlyWilted
            ? [Colors.orange[300]!, Colors.orange[600]!]
            : isFiller
                ? [_fillerPotLight, _fillerPotDark]
                : [AppColors.potTerracotta, AppColors.potTerracottaDark];

    final shadowColor = isFiller
        ? _fillerPotDark.withValues(alpha: 0.5)
        : AppColors.potTerracottaDark.withValues(alpha: 0.5);

    return SizedBox(
      width: 62,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Match badge — this flower carries a vibe the customer wants
          if (matchedVibes.isNotEmpty && !isEmpty && !nearlyWilted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFE082), Color(0xFFFFD54F)],
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                '✓ MATCH',
                style: GoogleFonts.nunito(
                  fontSize: 6.5,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF6D4C00),
                ),
              ),
            )
          // Greens label badge (replaces wilt warning for fillers when in stock)
          else if (isFiller && !nearlyWilted && !isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: _fillerPotLight.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _fillerPotLight.withValues(alpha: 0.55),
                  width: 1,
                ),
              ),
              child: Text(
                '🌿 GREENS',
                style: GoogleFonts.nunito(
                  fontSize: 6.5,
                  fontWeight: FontWeight.w900,
                  color: _fillerPotDark,
                ),
              ),
            )
          else if (nearlyWilted)
            Text(
              freshnessDays == 0 ? '⚠️' : '⏳',
              style: const TextStyle(fontSize: 10),
            )
          else
            const SizedBox(height: 0),
          // Flower emoji with glow when in stock
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: isEmpty
                ? null
                : BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      // Golden halo when this flower matches the order
                      BoxShadow(
                        color: matchedVibes.isNotEmpty
                            ? const Color(0xFFFFD54F).withValues(alpha: 0.75)
                            : wiltColor.withValues(alpha: 0.4),
                        blurRadius: matchedVibes.isNotEmpty ? 16 : 12,
                        spreadRadius: matchedVibes.isNotEmpty ? 3 : 2,
                      ),
                    ],
                  ),
            child: AnimatedOpacity(
              opacity: isEmpty ? 0.35 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: FlowerImage(flower: flower, size: 42),
            ),
          ),
          const SizedBox(height: 2),
          // Pot rim
          Container(
            width: 58,
            height: 8,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: rimColors),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ),
          // Pot body with quantity number
          Container(
            width: 52,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: bodyColors,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
                topLeft: Radius.circular(2),
                topRight: Radius.circular(2),
              ),
              boxShadow: isEmpty
                  ? []
                  : [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Quantity number (big, game-style)
                Text(
                  '$quantity',
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isEmpty
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.white,
                    shadows: isEmpty
                        ? []
                        : [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                ),
                // Flower name (tiny)
                Text(
                  flower.name,
                  style: GoogleFonts.nunito(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: isEmpty ? 0.3 : 0.8),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DragFeedback extends StatefulWidget {
  final Flower flower;

  const _DragFeedback({required this.flower});

  @override
  State<_DragFeedback> createState() => _DragFeedbackState();
}

class _DragFeedbackState extends State<_DragFeedback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _wobble;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..repeat(reverse: true);
    _wobble = Tween<double>(begin: -0.12, end: 0.12).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _wobble,
      builder: (_, child) => Transform.rotate(
        angle: _wobble.value,
        child: child,
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.flower.color.withValues(alpha: 0.9),
            boxShadow: [
              BoxShadow(
                color: widget.flower.color.withValues(alpha: 0.6),
                blurRadius: 24,
                spreadRadius: 6,
              ),
            ],
          ),
          child: Center(
            child: FlowerImage(flower: widget.flower, size: 44),
          ),
        ),
      ),
    );
  }
}
