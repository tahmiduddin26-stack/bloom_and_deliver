import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/seasonal_event.dart';
import '../providers/game_provider.dart';

/// Slide-down banner that appears on the first day of a seasonal event.
/// Dismisses automatically after [_autoDismissMs] ms, or on tap.
class SeasonalBanner extends ConsumerStatefulWidget {
  final SeasonalEvent event;
  final VoidCallback onDismissed;

  const SeasonalBanner({
    super.key,
    required this.event,
    required this.onDismissed,
  });

  @override
  ConsumerState<SeasonalBanner> createState() => _SeasonalBannerState();
}

class _SeasonalBannerState extends ConsumerState<SeasonalBanner>
    with SingleTickerProviderStateMixin {
  static const _slideDurationMs = 400;
  static const _autoDismissMs = 5000;

  late final AnimationController _controller;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _slideDurationMs),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Auto-dismiss after a few seconds
    Future.delayed(const Duration(milliseconds: _autoDismissMs), _dismiss);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) {
        ref.read(gameProvider.notifier).clearPendingSeasonalBanner();
        widget.onDismissed();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final gradient = event.backgroundGradient;

    return SlideTransition(
      position: _slide,
      child: GestureDetector(
        onTap: _dismiss,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  // Event emoji in a softly glowing circle
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      event.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          event.tagline,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tap-to-dismiss hint
                  Column(
                    children: [
                      Text(
                        'Tap to',
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        'dismiss',
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
