import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/flower.dart';
import 'flower_image.dart';

/// Builds a finished-looking bouquet from the exact flowers the player chose.
/// The stable layout means every combination has a distinct, repeatable image.
class BouquetPreview extends StatelessWidget {
  final List<Flower> flowers;
  final double size;

  const BouquetPreview({super.key, required this.flowers, this.size = 190});

  @override
  Widget build(BuildContext context) {
    if (flowers.isEmpty) return SizedBox.square(dimension: size);

    final shown = flowers.toList(growable: false);
    final bloomSize = size * (shown.length <= 3 ? 0.48 : 0.4);
    final spread = math.min(
      size * 0.14,
      size * 0.62 / math.max(1, shown.length - 1),
    );

    return Semantics(
      label: 'Bouquet of ${flowers.map((f) => f.name).join(', ')}',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _StemPainter(shown.length)),
            ),
            Positioned(
              left: size * 0.25,
              right: size * 0.25,
              bottom: size * 0.08,
              height: size * 0.48,
              child: CustomPaint(painter: _BackWrapPainter()),
            ),
            for (var i = 0; i < shown.length; i++)
              _positionedFlower(
                flower: shown[i],
                index: i,
                count: shown.length,
                size: size,
                bloomSize: bloomSize,
                spread: spread,
              ),
            Positioned(
              left: size * 0.24,
              right: size * 0.24,
              bottom: size * 0.035,
              height: size * 0.49,
              child: CustomPaint(painter: _FrontWrapPainter()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _positionedFlower({
    required Flower flower,
    required int index,
    required int count,
    required double size,
    required double bloomSize,
    required double spread,
  }) {
    final centeredIndex = index - (count - 1) / 2;
    final distance = centeredIndex.abs();
    final top =
        size * 0.025 +
        distance * size * 0.025 +
        (index.isOdd ? size * 0.045 : 0);
    final rotation = centeredIndex * 0.105;

    return Positioned(
      top: top,
      left: size / 2 - bloomSize / 2 + centeredIndex * spread,
      width: bloomSize,
      height: size * 0.72,
      child: Transform.rotate(
        angle: rotation,
        alignment: Alignment.bottomCenter,
        child: Align(
          alignment: Alignment.topCenter,
          child: FlowerImage(flower: flower, size: bloomSize),
        ),
      ),
    );
  }
}

class _StemPainter extends CustomPainter {
  final int count;
  _StemPainter(this.count);
  @override
  void paint(Canvas canvas, Size size) {
    final spread = math.min(
      size.width * .14,
      size.width * .62 / math.max(1, count - 1),
    );
    final paint = Paint()
      ..color = const Color(0xFF354C3E)
      ..strokeWidth = size.width * .016
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < count; i++) {
      final x = size.width / 2 + (i - (count - 1) / 2) * spread;
      canvas.drawPath(
        Path()
          ..moveTo(x, size.height * .28)
          ..quadraticBezierTo(
            x,
            size.height * .5,
            size.width * .5,
            size.height * .78,
          ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StemPainter oldDelegate) => oldDelegate.count != count;
}

class _BackWrapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paper = Paint()..color = const Color(0xFFF1D9B5);
    final path = Path()
      ..moveTo(0, size.height * 0.12)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.65, size.height)
      ..lineTo(size.width * 0.35, size.height)
      ..close();
    canvas.drawPath(path, paper);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FrontWrapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paper = Paint()..color = const Color(0xFFE7CBA3);
    final left = Path()
      ..moveTo(0, size.height * 0.12)
      ..lineTo(size.width * 0.51, size.height * 0.42)
      ..lineTo(size.width * 0.64, size.height)
      ..lineTo(size.width * 0.35, size.height)
      ..close();
    final right = Path()
      ..moveTo(size.width, size.height * 0.06)
      ..lineTo(size.width * 0.49, size.height * 0.42)
      ..lineTo(size.width * 0.64, size.height)
      ..close();
    canvas.drawPath(left, paper);
    canvas.drawPath(right, Paint()..color = const Color(0xFFF6E4C8));

    final ribbonY = size.height * 0.55;
    final ribbon = Paint()
      ..color = const Color(0xFFC95D75)
      ..strokeWidth = size.height * 0.075
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.24, ribbonY),
      Offset(size.width * 0.76, ribbonY),
      ribbon,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, ribbonY),
      size.height * 0.06,
      Paint()..color = const Color(0xFFB84C66),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
