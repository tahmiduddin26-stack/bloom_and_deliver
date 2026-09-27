import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/feature_flags.dart';
import '../data/flower_data.dart';
import '../data/wholesale_data.dart';
import '../models/flower.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/flower_image.dart';

/// Prepaid bundles arrive when the next level starts.
class WholesaleScreen extends ConsumerStatefulWidget {
  const WholesaleScreen({super.key});

  @override
  ConsumerState<WholesaleScreen> createState() => _WholesaleScreenState();
}

class _WholesaleScreenState extends ConsumerState<WholesaleScreen> {
  // The local cart stores bundles; game state stores individual stems.
  final Map<String, int> _cart = {};

  int get _selectedPacks => _cart.values.fold(0, (sum, packs) => sum + packs);

  int get _cartTotal => _cart.entries.fold(
    0,
    (sum, entry) =>
        sum + wholesalePackPrice(flowerById[entry.key]!) * entry.value,
  );

  void _changePacks(String id, int delta, int pendingStems) {
    final next = (_cart[id] ?? 0) + delta;
    if (next < 0 ||
        (delta > 0 &&
            pendingStems + (_selectedPacks + 1) * wholesalePackSize >
                wholesaleMaxPacksPerDay * wholesalePackSize)) {
      return;
    }
    setState(() {
      if (next == 0) {
        _cart.remove(id);
      } else {
        _cart[id] = next;
      }
    });
  }

  void _placeOrder() {
    if (_cart.isEmpty) return;
    final quantities = _cart.map(
      (id, packs) => MapEntry(id, packs * wholesalePackSize),
    );
    final placed = ref
        .read(gameProvider.notifier)
        .placeWholesaleCart(quantities);
    if (!mounted) return;
    if (placed) {
      AudioService.instance.play(GameSound.coin);
      setState(_cart.clear);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          placed
              ? 'Bundle booked! Fresh flowers arrive at the next level.'
              : 'That order could not be placed. Check your coins and bundle limit.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final pendingStems = wholesalePendingStems(state.wholesalePending);
    final packsLeft =
        ((wholesaleMaxPacksPerDay * wholesalePackSize - pendingStems) /
                wholesalePackSize)
            .floor()
            .clamp(0, wholesaleMaxPacksPerDay) -
        _selectedPacks;
    final flowers = unlockedFlowers(
      state.day,
    ).where((flower) => !flower.isEventExclusive).toList();
    final canPlace = _cart.isNotEmpty && _cartTotal <= state.money;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.gardenGreenDark,
        foregroundColor: Colors.white,
        title: Text(
          'Wholesale Depot',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              children: [
                Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE2AE),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cartoonInk, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plan tomorrow’s blooms',
                        style: GoogleFonts.nunito(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: AppColors.gardenGreenDark,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Bundles cost less and arrive fresh at the next level. Need flowers now? Visit the market.',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          color: AppColors.brownDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$wholesalePackSize stems per bundle  •  $wholesaleMaxPacksPerDay bundles a day',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w900,
                          color: AppColors.gardenGreenDark,
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.wholesalePending.isNotEmpty) ...[
                  const SizedBox(height: 13),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCEBC6),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.cartoonInk,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'On the way for next level',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w900,
                            color: AppColors.gardenGreenDark,
                          ),
                        ),
                        Text(
                          state.wholesalePending.entries
                              .map(
                                (entry) =>
                                    '${entry.value} ${flowerById[entry.key]?.name ?? entry.key}',
                              )
                              .join('  •  '),
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w700,
                            color: AppColors.brownDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 17),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Choose bundles',
                        style: GoogleFonts.nunito(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: AppColors.gardenGreenDark,
                        ),
                      ),
                    ),
                    Text(
                      '$packsLeft left',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        color: AppColors.gardenGreenDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                for (final flower in flowers)
                  _BundleCard(
                    flower: flower,
                    packs: _cart[flower.id] ?? 0,
                    stock: state.inventory[flower.id] ?? 0,
                    canAdd: packsLeft > 0,
                    onAdd: () => _changePacks(flower.id, 1, pendingStems),
                    onRemove: () => _changePacks(flower.id, -1, pendingStems),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.warmWhite,
                border: Border(
                  top: BorderSide(color: AppColors.cartoonInk, width: 2),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$_selectedPacks / $wholesaleMaxPacksPerDay bundles',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w900,
                            color: AppColors.gardenGreenDark,
                          ),
                        ),
                      ),
                      Text(
                        '\$$_cartTotal / \$${state.money}',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w900,
                          color: AppColors.gardenGreenDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: canPlace ? _placeOrder : null,
                      icon: Icon(
                        Icons.local_shipping_rounded,
                        color: canPlace ? Colors.white : AppColors.brownLight,
                      ),
                      label: Text(
                        _cart.isEmpty
                            ? 'Choose a bundle'
                            : canPlace
                            ? 'Place order for \$$_cartTotal'
                            : 'Need more coins',
                        style: TextStyle(
                          color: canPlace ? Colors.white : AppColors.brownLight,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(49),
                        backgroundColor: AppColors.gardenGreenDark,
                        foregroundColor: Colors.white,
                        textStyle: GoogleFonts.nunito(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BundleCard extends StatelessWidget {
  final Flower flower;
  final int packs;
  final int stock;
  final bool canAdd;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _BundleCard({
    required this.flower,
    required this.packs,
    required this.stock,
    required this.canAdd,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: packs > 0 ? const Color(0xFFFFDDE1) : AppColors.warmWhite,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.cartoonInk, width: 1.5),
    ),
    child: Column(
      children: [
        Row(
          children: [
            FlowerImage(flower: flower, size: 43),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    flower.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.gardenGreenDark,
                    ),
                  ),
                  Text(
                    '\$${wholesalePackPrice(flower)} for $wholesalePackSize stems  ·  market \$${flower.cost * wholesalePackSize}',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brownDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                '$stock in shop now',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brownDark,
                ),
              ),
            ),
            IconButton(
              onPressed: packs > 0 ? onRemove : null,
              tooltip: 'Remove ${flower.name} bundle',
              icon: const Icon(Icons.remove_circle_rounded),
              color: AppColors.gardenGreenDark,
            ),
            Text(
              '$packs',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.gardenGreenDark,
              ),
            ),
            IconButton(
              onPressed: canAdd ? onAdd : null,
              tooltip: 'Add ${flower.name} bundle',
              icon: const Icon(Icons.add_circle_rounded),
              color: AppColors.gardenGreenDark,
            ),
          ],
        ),
      ],
    ),
  );
}

Future<void> openWholesaleScreen(BuildContext context) {
  if (!Features.wholesale ||
      ProviderScope.containerOf(context).read(gameProvider).day <
          wholesaleUnlockDay) {
    return Future<void>.value();
  }
  return Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const WholesaleScreen()));
}
