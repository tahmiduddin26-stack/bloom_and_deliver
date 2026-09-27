import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/feature_flags.dart';
import '../data/flower_data.dart';
import '../data/delivery_data.dart';
import '../models/delivery_mission.dart';
import '../models/flower.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bouquet_preview.dart';
import '../widgets/flower_image.dart';

/// Optional bouquets after a finished day. Nothing is spent until hand-in.
class DeliveryScreen extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  const DeliveryScreen({super.key, required this.onDone});

  @override
  ConsumerState<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends ConsumerState<DeliveryScreen> {
  String? _activeId;
  bool _leaving = false;
  final List<Flower> _workspace = [];

  void _leave() {
    if (_leaving) return;
    _leaving = true;
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
  }

  void _start(DeliveryMission mission) {
    setState(() {
      _activeId = mission.id;
      _workspace.clear();
    });
  }

  void _add(Flower flower, int inStock, int maxFlowers) {
    if (_workspace.length >= maxFlowers ||
        _workspace.where((selected) => selected.id == flower.id).length >=
            inStock) {
      return;
    }
    setState(() => _workspace.add(flower));
    AudioService.instance.play(GameSound.flowerDrop);
  }

  void _submit(DeliveryMission mission) {
    final result = ref
        .read(gameProvider.notifier)
        .submitDelivery(mission.id, _workspace);
    if (!mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Those flowers are no longer in stock.')),
      );
      return;
    }
    AudioService.instance.play(
      result == DeliveryResult.great
          ? GameSound.greatOrder
          : result == DeliveryResult.poor
          ? GameSound.poorOrder
          : GameSound.coin,
    );
    final earned = ref
        .read(gameProvider)
        .pendingDeliveries
        .firstWhere((item) => item.id == mission.id)
        .earned;
    setState(() {
      _activeId = null;
      _workspace.clear();
    });
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: Text(
          switch (result) {
            DeliveryResult.great => 'Wonderful delivery!',
            DeliveryResult.good => 'Delivery complete!',
            DeliveryResult.poor => 'Delivery complete',
            _ => 'Delivery complete',
          },
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w900,
            color: AppColors.gardenGreenDark,
          ),
        ),
        content: Text(
          '${mission.storySnippet}\n\n+${earned ?? 0} coins',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            color: AppColors.brownDark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Lovely!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    DeliveryMission? active;
    for (final mission in state.pendingDeliveries) {
      if (mission.id == _activeId && !mission.isCompleted) active = mission;
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !_leaving) {
          _leaving = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.gardenGreenDark,
          foregroundColor: Colors.white,
          title: Text(
            'Deliveries',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w900),
          ),
          actions: [
            TextButton(
              onPressed: _leave,
              child: const Text('Skip', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: active == null
            ? _missionList(state.pendingDeliveries)
            : _buildBouquet(active, state.inventory, state.day),
      ),
    );
  }

  Widget _missionList(List<DeliveryMission> missions) => Column(
    children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _paperCard(
              color: const Color(0xFFDCEBC6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A little more joy around town',
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.gardenGreenDark,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'These are optional. Choose a stop, make a bouquet with flowers already in your shop, or head to the market.',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      color: AppColors.brownDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            for (final mission in missions)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: mission.isCompleted
                      ? const Color(0xFFDCEBC6)
                      : AppColors.warmWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(
                      color: AppColors.cartoonInk,
                      width: 1.5,
                    ),
                  ),
                  child: InkWell(
                    onTap: mission.isCompleted ? null : () => _start(mission),
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                mission.emoji,
                                style: const TextStyle(fontSize: 27),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  mission.location,
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.gardenGreenDark,
                                  ),
                                ),
                              ),
                              Icon(
                                mission.isCompleted
                                    ? Icons.check_circle_rounded
                                    : Icons.chevron_right_rounded,
                                color: AppColors.gardenGreenDark,
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            mission.description,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                              color: AppColors.brownDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mission.isCompleted
                                ? 'Delivered • +${mission.earned ?? 0} coins'
                                : '${mission.minFlowers}–${mission.maxFlowers} flowers • up to ${(mission.reward * 1.25).round()} coins',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w900,
                              color: AppColors.gardenGreenDark,
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
      ),
      _bottomAction(
        label: 'Continue to Market',
        icon: Icons.local_florist_rounded,
        onPressed: _leave,
      ),
    ],
  );

  Widget _buildBouquet(
    DeliveryMission mission,
    Map<String, int> inventory,
    int day,
  ) {
    final canSubmit =
        _workspace.length >= mission.minFlowers &&
        _workspace.length <= mission.maxFlowers;
    final available = unlockedFlowers(
      day,
    ).where((flower) => (inventory[flower.id] ?? 0) > 0).toList();
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
            children: [
              _paperCard(
                color: const Color(0xFFFFE2AE),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${mission.emoji}  ${mission.location}',
                      style: GoogleFonts.nunito(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: AppColors.gardenGreenDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      mission.hint,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        color: AppColors.brownDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final vibe in mission.requiredVibes)
                          Chip(
                            label: Text(vibe.label),
                            backgroundColor: AppColors.warmWhite,
                            side: const BorderSide(color: AppColors.cartoonInk),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your bouquet  ${_workspace.length}/${mission.minFlowers} minimum',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.gardenGreenDark,
                ),
              ),
              if (_workspace.isEmpty)
                SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'Choose flowers from your shop below',
                      style: GoogleFonts.nunito(color: AppColors.brownDark),
                    ),
                  ),
                )
              else
                Center(child: BouquetPreview(flowers: _workspace, size: 155)),
              if (_workspace.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(_workspace.removeLast),
                    icon: const Icon(Icons.undo_rounded),
                    label: const Text('Undo last flower'),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Flowers in your shop',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.gardenGreenDark,
                ),
              ),
              const SizedBox(height: 8),
              if (available.isEmpty)
                Text(
                  'No flowers left in stock. Continue to the market to restock.',
                  style: GoogleFonts.nunito(color: AppColors.brownDark),
                ),
              for (final flower in available)
                _flowerChoice(
                  flower,
                  inventory[flower.id] ?? 0,
                  mission.maxFlowers,
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: canSubmit ? () => _submit(mission) : null,
                    icon: Icon(
                      Icons.local_shipping_rounded,
                      color: canSubmit ? Colors.white : AppColors.brownDark,
                    ),
                    label: Text(
                      'Send bouquet',
                      style: TextStyle(
                        color: canSubmit ? Colors.white : AppColors.brownDark,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: AppColors.gardenGreenDark,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _activeId = null;
                    _workspace.clear();
                  }),
                  child: const Text('Choose another stop'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _flowerChoice(Flower flower, int stock, int maxFlowers) {
    final selected = _workspace.where((item) => item.id == flower.id).length;
    final canAdd = selected < stock && _workspace.length < maxFlowers;
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.cartoonInk, width: 1.3),
      ),
      child: Row(
        children: [
          FlowerImage(flower: flower, size: 35),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '${flower.name}  •  ${stock - selected} left',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w900,
                color: AppColors.gardenGreenDark,
              ),
            ),
          ),
          IconButton(
            onPressed: canAdd ? () => _add(flower, stock, maxFlowers) : null,
            tooltip: 'Add ${flower.name}',
            icon: const Icon(Icons.add_circle_rounded),
            color: AppColors.gardenGreenDark,
          ),
        ],
      ),
    );
  }

  Widget _paperCard({required Color color, required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: AppColors.cartoonInk, width: 1.7),
    ),
    child: child,
  );

  Widget _bottomAction({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white),
          label: Text(label, style: const TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: AppColors.gardenGreenDark,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    ),
  );
}

Future<void> openDeliveryScreen(
  BuildContext context, {
  required VoidCallback onDone,
}) {
  final state = ProviderScope.containerOf(context).read(gameProvider);
  if (!Features.deliveries ||
      state.day < deliveryUnlockDay ||
      !state.dayEnded) {
    return Future<void>.value();
  }
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => DeliveryScreen(onDone: onDone)),
  );
}
