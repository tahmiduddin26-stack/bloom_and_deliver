import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/order_data.dart';
import '../theme/app_theme.dart';

/// A warm sepia-toned banner that slides in from the top when a customer
/// backstory memory snippet is unlocked.  Format of [memoryKey]: "customerId:snippetIndex".
class MemoryPopup extends StatefulWidget {
  final String memoryKey;
  final VoidCallback onDismiss;

  const MemoryPopup({
    super.key,
    required this.memoryKey,
    required this.onDismiss,
  });

  @override
  State<MemoryPopup> createState() => _MemoryPopupState();
}

class _MemoryPopupState extends State<MemoryPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.3)),
    );
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 5000), _dismiss);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (!mounted) return;
    _ctrl.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  ({String name, String portrait, String snippet})? get _data {
    final parts = widget.memoryKey.split(':');
    if (parts.length != 2) return null;
    final customerId = parts[0];
    final snippetIdx = int.tryParse(parts[1]);
    if (snippetIdx == null) return null;

    try {
      final customer =
          customerPool.firstWhere((c) => c.id == customerId);
      if (snippetIdx >= customer.backstorySnippets.length) return null;
      return (
        name: customer.name,
        portrait: customer.portrait,
        snippet: customer.backstorySnippets[snippetIdx],
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) return const SizedBox.shrink();

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: GestureDetector(
          onTap: _dismiss,
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5E3C), Color(0xFF6B3A1E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5E3C).withValues(alpha: 0.50),
                  blurRadius: 22,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: AppColors.shelfWoodLight.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      data.portrait,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text('📖', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 5),
                          Text(
                            'Memory — ${data.name}',
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.shelfWoodLight
                                  .withValues(alpha: 0.90),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.snippet,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.90),
                          height: 1.45,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '✕',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
