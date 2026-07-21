import 'dart:math';
import 'package:flutter/material.dart';

class SparkleOverlay extends StatefulWidget {
  final Widget child;
  final bool active;

  const SparkleOverlay({
    super.key,
    required this.child,
    required this.active,
  });

  @override
  State<SparkleOverlay> createState() => _SparkleOverlayState();
}

class _SparkleOverlayState extends State<SparkleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _rng = Random();
  List<_Particle> _particles = [];

  static const _emojis = [
    '✨', '🌸', '🌟', '💫', '🌺', '🌼', '🎊', '🌷',
    '🪷', '🌻', '🎉', '💐', '🌈', '⭐',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  @override
  void didUpdateWidget(SparkleOverlay old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _spawnParticles();
    }
  }

  void _spawnParticles() {
    _particles = List.generate(22, (i) {
      return _Particle(
        x: 0.05 + _rng.nextDouble() * 0.9,
        y: 0.15 + _rng.nextDouble() * 0.65,
        dx: (_rng.nextDouble() - 0.5) * 0.45,
        dy: -0.08 - _rng.nextDouble() * 0.38,
        emoji: _emojis[_rng.nextInt(_emojis.length)],
        delay: i * 0.028,
        size: 18.0 + _rng.nextDouble() * 20.0,
      );
    });
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                if (_ctrl.value == 0 ||
                    _ctrl.status == AnimationStatus.dismissed) {
                  return const SizedBox.shrink();
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    return Stack(
                      children: _particles
                          .map((p) => _buildParticle(p, w, h))
                          .toList(),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParticle(_Particle p, double w, double h) {
    final t = ((_ctrl.value - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);
    if (t == 0) return const SizedBox.shrink();

    final curve = Curves.easeOut.transform(t);
    final x = (p.x + p.dx * curve) * w - p.size / 2;
    final y = (p.y + p.dy * curve) * h - p.size / 2;
    final opacity =
        (t < 0.35 ? t / 0.35 : t < 0.65 ? 1.0 : (1.0 - t) / 0.35)
            .clamp(0.0, 1.0);

    return Positioned(
      left: x,
      top: y,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: curve * (p.x > 0.5 ? 1.2 : -1.2),
          child: Text(
            p.emoji,
            style: TextStyle(fontSize: p.size),
          ),
        ),
      ),
    );
  }
}

class _Particle {
  final double x, y, dx, dy, delay, size;
  final String emoji;

  const _Particle({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.delay,
    required this.size,
    required this.emoji,
  });
}
