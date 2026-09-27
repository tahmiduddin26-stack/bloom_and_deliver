import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/feature_flags.dart';
import '../data/flower_data.dart';
import '../models/big_order.dart';
import '../models/flower.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bouquet_preview.dart';
import '../widgets/flower_image.dart';

/// One optional end-of-day bouquet for a three-day commission.
class BigOrderScreen extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  const BigOrderScreen({super.key, required this.onDone});

  @override
  ConsumerState<BigOrderScreen> createState() => _BigOrderScreenState();
}

class _BigOrderScreenState extends ConsumerState<BigOrderScreen> {
  final List<Flower> _bouquet = [];
  ContributionResult? _result;
  int _earned = 0;
  bool _leaving = false;

  void _leave() {
    if (_leaving) return;
    _leaving = true;
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
  }

  void _submit() {
    final before = ref.read(gameProvider).money;
    final result = ref.read(gameProvider.notifier).contributeBigOrder(_bouquet);
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check your flower stock and try again.')),
      );
      return;
    }
    AudioService.instance.play(switch (result) {
      ContributionResult.great => GameSound.greatOrder,
      ContributionResult.poor => GameSound.poorOrder,
      _ => GameSound.coin,
    });
    setState(() {
      _result = result;
      _earned = ref.read(gameProvider).money - before;
      _bouquet.clear();
    });
  }

  void _add(Flower flower, int stock, int max) {
    if (_bouquet.length >= max ||
        _bouquet.where((item) => item.id == flower.id).length >= stock) {
      return;
    }
    setState(() => _bouquet.add(flower));
    AudioService.instance.play(GameSound.flowerDrop);
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
    final canSubmit =
        _result == null &&
        order.canContributeOn(state.day) &&
        _bouquet.length >= order.minFlowers &&
        _bouquet.length <= order.maxFlowers;
    final available = unlockedFlowers(
      state.day,
    ).where((flower) => (state.inventory[flower.id] ?? 0) > 0).toList();
    final storyIndex = _result == null
        ? order.nextDayIndex ?? 0
        : (order.daysSubmitted - 1).clamp(0, 2);

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
            'Commission',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w900),
          ),
          actions: [
            TextButton(
              onPressed: _leave,
              child: Text(
                _result == null ? 'Skip' : 'Done',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _card(
                    const Color(0xFFFFE2AE),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${order.emoji}  ${order.name}',
                          style: _heading(21),
                        ),
                        const SizedBox(height: 6),
                        Text(order.description, style: _body()),
                        const SizedBox(height: 12),
                        Text(
                          'Deadline: end of Day ${order.deadlineDay}',
                          style: _body(bold: true),
                        ),
                        Text(
                          'One bouquet per day • ${order.daysSubmitted}/3 delivered',
                          style: _body(bold: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _card(
                    AppColors.warmWhite,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('The three arrangements', style: _heading(17)),
                        const SizedBox(height: 8),
                        for (var i = 0; i < 3; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Icon(
                                  order.contributions[i].isSubmitted
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  color: AppColors.gardenGreenDark,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Arrangement ${i + 1}: ${order.contributions[i].isSubmitted
                                        ? 'Delivered on Day ${order.contributions[i].gameDay}'
                                        : i == order.nextDayIndex
                                        ? 'Ready today'
                                        : 'Waiting'}',
                                    style: _body(bold: true),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'Up to ${(order.dailyReward * 1.25).round()} coins each day • ${order.completionBonus} coin finish bonus',
                          style: _body(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_result != null)
                    _card(
                      const Color(0xFFDCEBC6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(switch (_result!) {
                            ContributionResult.great =>
                              'A gorgeous arrangement!',
                            ContributionResult.good => 'Beautifully delivered!',
                            ContributionResult.poor => 'Arrangement delivered',
                            _ => 'Delivered',
                          }, style: _heading(20)),
                          const SizedBox(height: 6),
                          Text(
                            '+$_earned coins${order.isComplete ? ' • Commission complete!' : ''}',
                            style: _body(bold: true),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    _card(
                      const Color(0xFFDCEBC6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Today’s note', style: _heading(17)),
                          const SizedBox(height: 5),
                          Text(order.dayStories[storyIndex], style: _body()),
                          const SizedBox(height: 9),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final vibe in order.requiredVibes)
                                Chip(
                                  label: Text(vibe.label),
                                  backgroundColor: AppColors.warmWhite,
                                  side: const BorderSide(
                                    color: AppColors.cartoonInk,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your bouquet  ${_bouquet.length}/${order.minFlowers} minimum',
                      style: _heading(18),
                    ),
                    if (_bouquet.isEmpty)
                      SizedBox(
                        height: 110,
                        child: Center(
                          child: Text(
                            'Choose flowers from your shop below',
                            style: _body(),
                          ),
                        ),
                      )
                    else
                      Center(
                        child: BouquetPreview(flowers: _bouquet, size: 155),
                      ),
                    if (_bouquet.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => setState(_bouquet.removeLast),
                          icon: const Icon(Icons.undo_rounded),
                          label: const Text('Undo last flower'),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text('Flowers in your shop', style: _heading(18)),
                    const SizedBox(height: 8),
                    if (available.isEmpty)
                      Text(
                        'No flowers in stock. Continue to the market to restock.',
                        style: _body(),
                      ),
                    for (final flower in available)
                      _flowerChoice(
                        flower,
                        state.inventory[flower.id] ?? 0,
                        order.maxFlowers,
                      ),
                  ],
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _result != null
                        ? _leave
                        : canSubmit
                        ? _submit
                        : null,
                    icon: Icon(
                      _result != null
                          ? Icons.arrow_forward_rounded
                          : Icons.local_florist_rounded,
                      color: _result != null || canSubmit
                          ? Colors.white
                          : AppColors.brownDark,
                    ),
                    label: Text(
                      _result != null ? 'Continue' : 'Send arrangement',
                      style: TextStyle(
                        color: _result != null || canSubmit
                            ? Colors.white
                            : AppColors.brownDark,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: AppColors.gardenGreenDark,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _flowerChoice(Flower flower, int stock, int max) {
    final selected = _bouquet.where((item) => item.id == flower.id).length;
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
              style: _body(bold: true),
            ),
          ),
          IconButton(
            onPressed: selected < stock && _bouquet.length < max
                ? () => _add(flower, stock, max)
                : null,
            tooltip: 'Add ${flower.name}',
            icon: const Icon(Icons.add_circle_rounded),
            color: AppColors.gardenGreenDark,
          ),
        ],
      ),
    );
  }

  Widget _card(Color color, Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: AppColors.cartoonInk, width: 1.7),
    ),
    child: child,
  );

  TextStyle _heading(double size) => GoogleFonts.nunito(
    fontSize: size,
    fontWeight: FontWeight.w900,
    color: AppColors.gardenGreenDark,
  );
  TextStyle _body({bool bold = false}) => GoogleFonts.nunito(
    fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
    color: AppColors.brownDark,
  );
}

Future<void> openBigOrderScreen(
  BuildContext context, {
  required VoidCallback onDone,
}) {
  final state = ProviderScope.containerOf(context).read(gameProvider);
  if (!Features.bigOrders ||
      !state.dayEnded ||
      !(state.activeBigOrder?.canContributeOn(state.day) ?? false)) {
    onDone();
    return Future<void>.value();
  }
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => BigOrderScreen(onDone: onDone)),
  );
}
