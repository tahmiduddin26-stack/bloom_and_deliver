import 'package:flutter/material.dart';

import '../config/feature_flags.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/shop_upgrades.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

void openUpgradesScreen(BuildContext context) {
  if (!Features.upgrades) return;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _UpgradesSheet(),
  );
}

class _UpgradesSheet extends ConsumerWidget {
  const _UpgradesSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A3A2A), Color(0xFF1A2820)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          // Header row
          Row(
            children: [
              const Text('🔨', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                'Shop Upgrades',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warmWhite,
                ),
              ),
              const Spacer(),
              // Wallet chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A9068).withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF5DBB8A).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(
                      '\$${state.money}',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Upgrade cards
          ...UpgradeId.values.map(
            (id) => _UpgradeCard(
              upgradeId: id,
              owned: state.upgrades.has(id),
              canAfford: state.money >= id.cost,
              onBuy: () {
                final bought = notifier.purchaseUpgrade(id);
                if (bought) AudioService.instance.play(GameSound.coin);
                if (bought && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${id.title} purchased! 🎉',
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: const Color(0xFF3A9068),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Single upgrade card ────────────────────────────────────────────────────────

class _UpgradeCard extends StatelessWidget {
  final UpgradeId upgradeId;
  final bool owned;
  final bool canAfford;
  final VoidCallback onBuy;

  const _UpgradeCard({
    required this.upgradeId,
    required this.owned,
    required this.canAfford,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: owned
            ? const Color(0xFF3A9068).withValues(alpha: 0.20)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: owned
              ? const Color(0xFF5DBB8A).withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.11),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Text(upgradeId.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  upgradeId.title,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  upgradeId.description,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.60),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Owned badge / buy button
          if (owned)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF3A9068).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Owned ✓',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: canAfford ? onBuy : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  gradient: canAfford
                      ? const LinearGradient(
                          colors: [Color(0xFFFFB830), Color(0xFFE8956A)],
                        )
                      : null,
                  color: canAfford
                      ? null
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: canAfford
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFFB830)
                                .withValues(alpha: 0.40),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  '\$${upgradeId.cost}',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: canAfford
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
