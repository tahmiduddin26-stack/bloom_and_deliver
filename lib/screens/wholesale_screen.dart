import 'package:flutter/material.dart';

import '../config/feature_flags.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/flower_data.dart';
import '../models/flower.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/flower_image.dart';

class WholesaleScreen extends ConsumerStatefulWidget {
  const WholesaleScreen({super.key});

  @override
  ConsumerState<WholesaleScreen> createState() => _WholesaleScreenState();
}

class _WholesaleScreenState extends ConsumerState<WholesaleScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideIn;

  // Local cart: flowerId → quantity to order
  final Map<String, int> _cart = {};

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideIn = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  int _wholesalePrice(Flower f) => (f.cost * 0.7).round().clamp(1, f.cost - 1);

  int get _cartTotal => _cart.entries.fold(
      0, (sum, e) => sum + _wholesalePrice(flowerById[e.key]!) * e.value);

  void _increment(String id) {
    HapticFeedback.selectionClick();
    setState(() => _cart[id] = (_cart[id] ?? 0) + 1);
  }

  void _decrement(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      final cur = _cart[id] ?? 0;
      if (cur <= 1) {
        _cart.remove(id);
      } else {
        _cart[id] = cur - 1;
      }
    });
  }

  void _placeOrders() {
    if (_cart.isEmpty) return;
    final notifier = ref.read(gameProvider.notifier);
    final money = ref.read(gameProvider).money;

    if (_cartTotal > money) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Not enough coins! You need \$$_cartTotal but only have \$$money.",
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
          ),
          backgroundColor: AppColors.potTerracottaDark,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    AudioService.instance.play(GameSound.coin);
    for (final entry in _cart.entries) {
      final flower = flowerById[entry.key]!;
      final qty = entry.value;
      final cost = _wholesalePrice(flower) * qty;
      notifier.placeWholesaleOrder(entry.key, qty, cost);
    }
    setState(() => _cart.clear());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '📦 Order placed! Flowers arrive tomorrow morning.',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.gardenGreenMid,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final unlocked = unlockedFlowers(state.day)
        .where((f) => !f.isEventExclusive)
        .toList();
    final pending = state.wholesalePending;

    return Scaffold(
      body: SlideTransition(
        position: _slideIn,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2D4A35), Color(0xFF1A2E20)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _WholesaleHeader(money: state.money),
                // Pending orders banner
                if (pending.isNotEmpty)
                  _PendingBanner(pending: pending),
                // Info strip
                _InfoStrip(),
                // Flower list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 100),
                    itemCount: unlocked.length,
                    itemBuilder: (context, i) {
                      final flower = unlocked[i];
                      final qty = _cart[flower.id] ?? 0;
                      final price = _wholesalePrice(flower);
                      return _WholesaleRow(
                        flower: flower,
                        wholesalePrice: price,
                        qty: qty,
                        onIncrement: () => _increment(flower.id),
                        onDecrement: () => _decrement(flower.id),
                      );
                    },
                  ),
                ),
                // Footer
                _WholesaleFooter(
                  cartTotal: _cartTotal,
                  cartCount: _cart.values.fold(0, (a, b) => a + b),
                  money: state.money,
                  onPlace: _cart.isEmpty ? null : _placeOrders,
                  onClose: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _WholesaleHeader extends StatelessWidget {
  final int money;
  const _WholesaleHeader({required this.money});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3020), Color(0xFF2E5438)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 10),
          const Text('🏭', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wholesale Supplier',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warmWhite,
                  ),
                ),
                Text(
                  '30% off — arrives next morning',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: AppColors.mint.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.mint.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.mint.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💵', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(
                  '\$$money',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.warmWhite,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pending orders banner ─────────────────────────────────────────────────────

class _PendingBanner extends StatelessWidget {
  final Map<String, int> pending;
  const _PendingBanner({required this.pending});

  @override
  Widget build(BuildContext context) {
    final lines = pending.entries.map((e) {
      final name = flowerById[e.key]?.name ?? e.key;
      return '${e.value}× $name';
    }).join('  •  ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: AppColors.gardenGreenMid.withValues(alpha: 0.25),
      child: Row(
        children: [
          const Text('📦', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Arriving tomorrow: $lines',
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.mint,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info strip ────────────────────────────────────────────────────────────────

class _InfoStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          _InfoChip('🕐', 'Arrives next morning'),
          const SizedBox(width: 12),
          _InfoChip('💸', '30% cheaper than market'),
          const SizedBox(width: 12),
          _InfoChip('⚠️', 'No same-day access'),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String emoji;
  final String label;
  const _InfoChip(this.emoji, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 9.5,
            color: Colors.white.withValues(alpha: 0.55),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Flower row ────────────────────────────────────────────────────────────────

class _WholesaleRow extends StatelessWidget {
  final Flower flower;
  final int wholesalePrice;
  final int qty;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _WholesaleRow({
    required this.flower,
    required this.wholesalePrice,
    required this.qty,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final isInCart = qty > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isInCart
            ? AppColors.gardenGreenMid.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isInCart
              ? AppColors.gardenGreenMid.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          FlowerImage(flower: flower, size: 36),
          const SizedBox(width: 12),
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
                Row(
                  children: [
                    Text(
                      '\$${flower.cost}',
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        color: Colors.white38,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Colors.white38,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '\$$wholesalePrice ea',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mint,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.gardenGreenMid.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '30% off',
                        style: GoogleFonts.nunito(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mint,
                        ),
                      ),
                    ),
                  ],
                ),
                if (qty > 0)
                  Text(
                    'Subtotal: \$${wholesalePrice * qty}',
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      color: AppColors.gardenGreenMid,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          // Qty stepper
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepBtn(
                icon: Icons.remove,
                enabled: qty > 0,
                onTap: onDecrement,
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: qty > 0
                      ? AppColors.gardenGreenMid.withValues(alpha: 0.25)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$qty',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: qty > 0 ? Colors.white : Colors.white38,
                  ),
                ),
              ),
              _StepBtn(
                icon: Icons.add,
                enabled: true,
                onTap: onIncrement,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? Colors.white : Colors.white24,
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _WholesaleFooter extends StatelessWidget {
  final int cartTotal;
  final int cartCount;
  final int money;
  final VoidCallback? onPlace;
  final VoidCallback onClose;

  const _WholesaleFooter({
    required this.cartTotal,
    required this.cartCount,
    required this.money,
    required this.onPlace,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = money >= cartTotal;
    final hasItems = cartCount > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cart summary
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasItems ? '$cartCount stem${cartCount == 1 ? '' : 's'} ordered' : 'Nothing selected',
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  hasItems ? '-\$$cartTotal' : '\$0',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: hasItems && !canAfford
                        ? AppColors.potTerracottaDark
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Place order button
          ElevatedButton.icon(
            onPressed: onPlace,
            icon: const Text('📦', style: TextStyle(fontSize: 16)),
            label: Text(
              hasItems
                  ? canAfford
                      ? 'Place Order'
                      : 'Can\'t Afford'
                  : 'Select Flowers',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 50),
              backgroundColor: hasItems && canAfford
                  ? AppColors.gardenGreenMid
                  : Colors.white.withValues(alpha: 0.12),
              foregroundColor:
                  hasItems && canAfford ? Colors.white : Colors.white38,
              elevation: hasItems && canAfford ? 4 : 0,
              shadowColor: AppColors.gardenGreenDark.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Push the wholesale screen from the market.
Future<void> openWholesaleScreen(BuildContext context) {
  if (!Features.wholesale) return Future<void>.value();
  return Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => const WholesaleScreen(),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 380),
    ),
  );
}
