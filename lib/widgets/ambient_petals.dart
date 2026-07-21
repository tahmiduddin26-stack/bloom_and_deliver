import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Slow-drifting decorative petals and sparkles for the background of a screen.
///
/// Purely atmospheric: it ignores pointer events and never affects layout of the
/// content painted on top. Drop it in behind the main content — e.g. as the
/// first child of a `Stack`, wrapped in `Positioned.fill`. The gentle, always-on
/// motion is what makes an otherwise-still screen read as alive and cosy (Phase 3
/// atmosphere — no assets required).
class AmbientPetals extends StatefulWidget {
  /// Overall visibility multiplier (0–1). Lower it on busier screens.
  final double intensity;

  const AmbientPetals({super.key, this.intensity = 1.0});

  @override
  State<AmbientPetals> createState() => _AmbientPetalsState();
}

class _AmbientPetal {
  final String emoji;
  final double left; // fraction of width 0..1
  final double top; // fraction of height 0..1
  final double size;
  final double swayX; // horizontal drift, px
  final double bobY; // vertical drift, px
  final double phase; // 0..1 loop offset
  final double opacity;

  const _AmbientPetal(
    this.emoji,
    this.left,
    this.top,
    this.size,
    this.swayX,
    this.bobY,
    this.phase,
    this.opacity,
  );
}

class _AmbientPetalsState extends State<AmbientPetals>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  static const _petals = <_AmbientPetal>[
    _AmbientPetal('🌸', 0.08, 0.10, 22, 14, 20, 0.00, 0.16),
    _AmbientPetal('🌿', 0.86, 0.18, 20, -12, 24, 0.30, 0.14),
    _AmbientPetal('✨', 0.70, 0.07, 15, 9, 15, 0.60, 0.22),
    _AmbientPetal('🌼', 0.15, 0.60, 18, 11, 22, 0.15, 0.13),
    _AmbientPetal('🌸', 0.90, 0.72, 20, -13, 17, 0.45, 0.12),
    _AmbientPetal('🌿', 0.28, 0.86, 17, 10, 19, 0.75, 0.12),
    _AmbientPetal('✨', 0.54, 0.44, 13, 7, 13, 0.90, 0.18),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          if (!w.isFinite || !h.isFinite) return const SizedBox.shrink();
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Stack(
              children: [
                for (final p in _petals) _positioned(p, w, h, _ctrl.value),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _positioned(_AmbientPetal p, double w, double h, double t) {
    final angle = (t + p.phase) * 2 * math.pi;
    final dx = p.swayX * math.sin(angle);
    final dy = p.bobY * math.sin(angle * 0.8 + 1.0);
    return Positioned(
      left: p.left * w + dx,
      top: p.top * h + dy,
      child: Opacity(
        opacity: (p.opacity * widget.intensity).clamp(0.0, 1.0),
        child: Text(p.emoji, style: TextStyle(fontSize: p.size)),
      ),
    );
  }
}
