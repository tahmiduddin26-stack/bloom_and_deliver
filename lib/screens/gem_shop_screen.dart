import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/gem_data.dart';
import '../providers/game_provider.dart';
import '../services/analytics_service.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../theme/app_theme.dart';

/// The gem shop: spend gems on time-savers, or buy more with real money.
///
/// Purchases go through [IapService]. With no billing backend wired the shop
/// says so plainly instead of pretending a payment succeeded.
Future<void> openGemShop(BuildContext context, {String source = 'unknown'}) {
  AnalyticsService.instance.gemShopOpened(source);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const GemShopSheet(),
  );
}

class GemShopSheet extends ConsumerStatefulWidget {
  const GemShopSheet({super.key});

  @override
  ConsumerState<GemShopSheet> createState() => _GemShopSheetState();
}

class _GemShopSheetState extends ConsumerState<GemShopSheet> {
  String? _pendingProductId;
  late final Future<bool> _storeAvailable = IapService.instance.isAvailable();

  Future<void> _buy(GemPack pack) async {
    if (_pendingProductId != null) return;
    setState(() => _pendingProductId = pack.productId);

    final result = await IapService.instance.buy(pack);
    if (!mounted) return;
    setState(() => _pendingProductId = null);

    if (result.isSuccess && result.gems > 0) {
      ref.read(gameProvider.notifier).grantGems(result.gems);
      AnalyticsService.instance.gemsPurchased(pack.productId, result.gems);
      AudioService.instance.play(GameSound.coin);
      _toast('${result.gems} gems added. Thank you! 💎');
    } else if (result.status == PurchaseStatus.cancelled) {
      // Player backed out — stay quiet.
    } else {
      _toast(result.message ?? 'Purchase unavailable right now.');
    }
  }

  void _spend(bool Function() action, String okMessage) {
    if (action()) {
      AudioService.instance.play(GameSound.coin);
      _toast(okMessage);
    } else {
      _toast('Check your gems and whether this shortcut is needed.');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gems = ref.watch(gameProvider.select((s) => s.gems));
    final notifier = ref.read(gameProvider.notifier);

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.brownLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.diamond_outlined,
                    color: AppColors.gardenGreenDark,
                    size: 27,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Gem Garden',
                    style: GoogleFonts.nunito(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: AppColors.gardenGreenDark,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7556AD),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.cartoonInk,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '💎 $gems',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                children: [
                  _SectionLabel(
                    title: 'Spend gems',
                    subtitle: 'Little shortcuts — never a way to buy stars.',
                  ),
                  _SinkTile(
                    emoji: '🚚',
                    name: 'Instant Restock',
                    detail: 'Fill every shelf to 5, fresh today.',
                    cost: kGemCostInstantRestock,
                    affordable: gems >= kGemCostInstantRestock,
                    onTap: () => _spend(
                      notifier.gemInstantRestock,
                      'Shelves restocked! 🚚',
                    ),
                  ),
                  _SinkTile(
                    emoji: '💧',
                    name: 'Fresh Water',
                    detail: 'Reset freshness — nothing wilts tonight.',
                    cost: kGemCostFreshWater,
                    affordable: gems >= kGemCostFreshWater,
                    onTap: () => _spend(
                      notifier.gemFreshWater,
                      'Everything is fresh again 💧',
                    ),
                  ),
                  _SinkTile(
                    emoji: '🎲',
                    name: 'New Challenges',
                    detail:
                        'Swap challenges before serving the first customer.',
                    cost: kGemCostRerollChallenges,
                    affordable: gems >= kGemCostRerollChallenges,
                    onTap: () => _spend(
                      notifier.gemRerollChallenges,
                      'New challenges drawn 🎲',
                    ),
                  ),
                  const SizedBox(height: 18),
                  FutureBuilder<bool>(
                    future: _storeAvailable,
                    builder: (context, snapshot) {
                      final available = snapshot.data == true;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionLabel(
                            title: 'Grow your gems',
                            subtitle: available
                                ? 'Earn 5 gems for each new journey star, or choose an optional pack.'
                                : 'Earn 5 gems for each new journey star. Replay a level to collect its missing stars.',
                          ),
                          if (available) ...[
                            for (final pack in gemPacks)
                              _PackTile(
                                pack: pack,
                                pending: _pendingProductId == pack.productId,
                                onTap: () => _buy(pack),
                              ),
                            const SizedBox(height: 10),
                            Text(
                              'Your store confirms the final price before purchase.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.brownLight,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionLabel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: AppColors.inkBrown,
          ),
        ),
        Text(
          subtitle,
          style: GoogleFonts.nunito(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.brownLight,
          ),
        ),
      ],
    ),
  );
}

class _SinkTile extends StatelessWidget {
  final String emoji;
  final String name;
  final String detail;
  final int cost;
  final bool affordable;
  final VoidCallback onTap;

  const _SinkTile({
    required this.emoji,
    required this.name,
    required this.detail,
    required this.cost,
    required this.affordable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: affordable ? 1 : 0.55,
      child: GestureDetector(
        onTap: affordable ? onTap : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cartoonInk, width: 1.5),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.inkBrown,
                      ),
                    ),
                    Text(
                      detail,
                      style: GoogleFonts.nunito(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brownLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF7E57C2).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF7E57C2).withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  '💎 $cost',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF5E35B1),
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

class _PackTile extends StatelessWidget {
  final GemPack pack;
  final bool pending;
  final VoidCallback onTap;

  const _PackTile({
    required this.pack,
    required this.pending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: pending ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF7E57C2).withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Text(pack.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pack.name,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.inkBrown,
                    ),
                  ),
                  Text(
                    pack.bonusGems > 0
                        ? '💎 ${pack.gems} + ${pack.bonusGems} bonus'
                        : '💎 ${pack.gems}',
                    style: GoogleFonts.nunito(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: pack.bonusGems > 0
                          ? AppColors.gardenGreenDark
                          : AppColors.brownLight,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF7556AD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cartoonInk, width: 1.5),
              ),
              child: pending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      pack.fallbackPrice,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
