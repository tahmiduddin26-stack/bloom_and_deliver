import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/bouquet_order.dart';
import '../models/customer_profile.dart';
import '../models/flower.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

/// A phone widget that lives on the right edge of the screen.
/// Collapsed: shows a small notification bubble.
/// Expanded: slides out as a chat/DM screen showing the current order.
class CustomerPhone extends ConsumerStatefulWidget {
  const CustomerPhone({super.key});

  @override
  ConsumerState<CustomerPhone> createState() => _CustomerPhoneState();
}

class _CustomerPhoneState extends ConsumerState<CustomerPhone>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  late final AnimationController _animCtrl;
  late final Animation<double> _slideAnim;
  int _lastOrderIndex = 0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _expand() {
    setState(() => _isExpanded = true);
    _animCtrl.forward(from: 0);
  }

  void _collapse() {
    setState(() => _isExpanded = false);
    _animCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);

    // Auto-expand when a new order comes in
    ref.listen(
      gameProvider.select((s) => s.currentOrderIndex),
      (prev, next) {
        if (next != _lastOrderIndex && !state.dayEnded) {
          _lastOrderIndex = next;
          if (mounted) {
            setState(() => _isExpanded = true);
            _animCtrl.forward(from: 0);
          }
        }
      },
    );

    if (state.dayEnded || state.currentOrder == null) {
      return const SizedBox.shrink();
    }

    final order = state.currentOrder!;

    return AnimatedBuilder(
      animation: _slideAnim,
      builder: (context, child) {
        return Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Collapsed handle tab (always visible)
              _CollapseHandle(
                customer: order.customer,
                remaining: state.ordersRemaining,
                isExpanded: _isExpanded,
                onTap: _isExpanded ? _collapse : _expand,
              ),
              // Expanded phone card
              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: _slideAnim.value,
                  child: _PhoneCard(
                    order: order,
                    onDismiss: _collapse,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Collapsed handle ─────────────────────────────────────────────────────────

class _CollapseHandle extends StatelessWidget {
  final CustomerProfile customer;
  final int remaining;
  final bool isExpanded;
  final VoidCallback onTap;

  const _CollapseHandle({
    required this.customer,
    required this.remaining,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.phoneScreen,
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(-3, 0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Customer portrait
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.messageBubble.withValues(alpha: 0.4),
                border: Border.all(
                  color: AppColors.messageBubble,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  customer.portrait,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Queue count badge
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.notifRed,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$remaining',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Arrow indicator
            Icon(
              isExpanded ? Icons.chevron_right : Icons.chevron_left,
              color: Colors.white.withValues(alpha: 0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Expanded phone card ───────────────────────────────────────────────────────

class _PhoneCard extends ConsumerWidget {
  final BouquetOrder order;
  final VoidCallback onDismiss;

  const _PhoneCard({required this.order, required this.onDismiss});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendship = ref.watch(
      gameProvider.select((s) => s.friendshipFor(order.customer.id)),
    );
    final day = ref.watch(gameProvider.select((s) => s.day));

    return Container(
      width: 240,
      constraints: const BoxConstraints(maxHeight: 520),
      decoration: BoxDecoration(
        color: AppColors.phoneScreen,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PhoneStatusBar(
            customer: order.customer,
            friendship: friendship,
            onDismiss: onDismiss,
          ),
          Flexible(child: _ChatBody(order: order, showDay: day)),
        ],
      ),
    );
  }
}

class _PhoneStatusBar extends StatelessWidget {
  final CustomerProfile customer;
  final int friendship;
  final VoidCallback onDismiss;

  const _PhoneStatusBar({
    required this.customer,
    required this.friendship,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: const BoxDecoration(
          color: AppColors.phoneScreenLight,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.messageBubble.withValues(alpha: 0.3),
                border: Border.all(
                  color: AppColors.messageBubble.withValues(alpha: 0.7),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  customer.portrait,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        customer.name,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      if (customer.isRegular) ...[
                        const SizedBox(width: 4),
                        const Text('⭐', style: TextStyle(fontSize: 10)),
                      ],
                    ],
                  ),
                  // Friendship hearts (only for regulars)
                  if (customer.isRegular)
                    _FriendshipHearts(
                      level: friendship,
                      max: customer.maxFriendship,
                    )
                  else
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'BloomChat',
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.keyboard_arrow_right_rounded,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      );
}

class _FriendshipHearts extends StatelessWidget {
  final int level;
  final int max;

  const _FriendshipHearts({required this.level, required this.max});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(max, (i) {
        final filled = i < level;
        return Padding(
          padding: const EdgeInsets.only(right: 1),
          child: AnimatedOpacity(
            opacity: filled ? 1.0 : 0.25,
            duration: const Duration(milliseconds: 300),
            child: Text(
              '❤️',
              style: TextStyle(fontSize: filled ? 9 : 8),
            ),
          ),
        );
      }),
    );
  }
}

class _ChatBody extends StatelessWidget {
  final BouquetOrder order;
  final int showDay;

  const _ChatBody({required this.order, required this.showDay});

  @override
  Widget build(BuildContext context) {
    final rival = order.customer.rivalMention;
    final showRival = showDay >= 8 && rival != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                order.description,
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Mood emoji
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 4),
            child: Text(
              order.customer.mood.emoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          // Order chat bubble
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar
              Text(
                order.customer.portrait,
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 6),
              // Message bubble
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.messageBubble,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                      bottomLeft: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.messageBubble.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    order.hint,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: Colors.white,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Rival mention bubble (shown after Day 8 for casual customers)
          if (showRival) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  order.customer.portrait,
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                        bottomLeft: Radius.circular(4),
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🏪',
                          style: const TextStyle(fontSize: 11),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            rival,
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.65),
                              height: 1.4,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          // Divider
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 10),
          if (order.isMystery) ...[
            // Mystery order — hide vibes, show creativity prompt
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF4A2060).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF9B59B6).withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎭 Premium Mystery',
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFD7B3F0),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No vibe hints — scored on creativity.\nUse 4+ different flower types for the best result.',
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.65),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoChip(
                  icon: '🌸',
                  label: '${order.minFlowers}–${order.maxFlowers}',
                ),
                const SizedBox(width: 6),
                _InfoChip(
                  icon: '💰',
                  label: 'up to \$${(order.basePayment * 2.5).round()}',
                ),
              ],
            ),
          ] else ...[
            // Normal order — show vibes
            Text(
              '✨ Looking for...',
              style: GoogleFonts.nunito(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: order.requiredVibes.map(_VibeChip.new).toList(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoChip(
                  icon: '🌸',
                  label: '${order.minFlowers}–${order.maxFlowers}',
                ),
                const SizedBox(width: 6),
                _InfoChip(
                  icon: '💰',
                  label: 'up to \$${(order.basePayment * 1.3).round()}',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _VibeChip extends StatelessWidget {
  final VibeTag vibe;

  const _VibeChip(this.vibe);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: vibe.color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: vibe.color.withValues(alpha: 0.5)),
        ),
        child: Text(
          vibe.label,
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
}

class _InfoChip extends StatelessWidget {
  final String icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      );
}
