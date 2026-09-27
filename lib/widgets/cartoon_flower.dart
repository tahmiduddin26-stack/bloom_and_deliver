import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/flower.dart';

/// Crisp, resolution-independent flower art with a shared ink outline.
class CartoonFlowerPainter extends CustomPainter {
  final Flower flower;
  CartoonFlowerPainter(this.flower);
  static const ink = Color(0xFF354C3E);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final outline = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    void shape(Path path, Color color) {
      canvas.drawPath(path, Paint()..color = color);
      canvas.drawPath(path, outline);
    }

    void oval(Rect rect, Color color) {
      canvas.drawOval(rect, Paint()..color = color);
      canvas.drawOval(rect, outline);
    }

    canvas.drawPath(
      Path()
        ..moveTo(50, 91)
        ..quadraticBezierTo(57, 66, 49, 35),
      Paint()
        ..color = ink
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke,
    );
    for (final side in [-1, 1]) {
      shape(
        Path()
          ..moveTo(51, 78)
          ..quadraticBezierTo(51 + side * 28, 78, 51 + side * 28, 59)
          ..quadraticBezierTo(51 + side * 6, 59, 51, 78),
        const Color(0xFF79BC64),
      );
    }
    final id = flower.id;
    final spike = {'lavender', 'wisteria', 'hyacinth', 'snapdragon', 'statice'};
    final clusters = {
      'babys_breath',
      'wildflower',
      'berry_branch',
      'sweet_pea',
    };
    if (flower.isFiller && !clusters.contains(id) && !spike.contains(id)) {
      for (var i = 0; i < 5; i++) {
        for (final side in [-1, 1]) {
          oval(
            Rect.fromCenter(
              center: Offset(50 + side * (17 - i * 2), 52 - i * 9),
              width: 23 - i * 2,
              height: 13,
            ),
            flower.color,
          );
        }
      }
    } else if (spike.contains(id)) {
      for (var i = 0; i < 6; i++) {
        oval(
          Rect.fromCenter(
            center: Offset(50 + (i.isEven ? -5 : 5), 54 - i * 8),
            width: 22 - i * 1.5,
            height: 13,
          ),
          flower.color,
        );
      }
    } else if (clusters.contains(id)) {
      for (var i = 0; i < 7; i++) {
        final a = i * math.pi * 2 / 7;
        final center = Offset(50 + math.cos(a) * 23, 33 + math.sin(a) * 21);
        canvas.drawLine(const Offset(50, 65), center, outline);
        oval(Rect.fromCircle(center: center, radius: 8), flower.color);
        canvas.drawCircle(center, 2, Paint()..color = const Color(0xFFFFD35B));
      }
    } else if (id == 'tulip') {
      shape(
        Path()
          ..moveTo(27, 18)
          ..lineTo(41, 26)
          ..lineTo(50, 11)
          ..lineTo(60, 26)
          ..lineTo(74, 18)
          ..quadraticBezierTo(78, 59, 50, 58)
          ..quadraticBezierTo(24, 57, 27, 18),
        flower.color,
      );
    } else {
      final longPetals = {
        'daisy',
        'sunflower',
        'gerbera_daisy',
        'cosmos',
        'zinnia',
      };
      final pointed = {'lily', 'amaryllis', 'orchid', 'protea'};
      final petals = longPetals.contains(id)
          ? 10
          : pointed.contains(id)
          ? 6
          : 7;
      for (var i = 0; i < petals; i++) {
        canvas.save();
        canvas.translate(50, 34);
        canvas.rotate(i * math.pi * 2 / petals);
        if (pointed.contains(id)) {
          shape(
            Path()
              ..moveTo(0, 5)
              ..quadraticBezierTo(-19, -8, 0, -30)
              ..quadraticBezierTo(19, -8, 0, 5),
            flower.color,
          );
        } else {
          oval(
            Rect.fromCenter(
              center: const Offset(0, -17),
              width: longPetals.contains(id) ? 14 : 24,
              height: 31,
            ),
            flower.color,
          );
        }
        canvas.restore();
      }
      oval(
        Rect.fromCircle(
          center: const Offset(50, 34),
          radius: id == 'sunflower' ? 14 : 10,
        ),
        id == 'sunflower' || id == 'anemone'
            ? const Color(0xFF78523C)
            : const Color(0xFFFFD35B),
      );
      canvas.drawCircle(
        const Offset(47, 30),
        2.5,
        Paint()..color = const Color(0xFFFFF1BC),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CartoonFlowerPainter oldDelegate) =>
      oldDelegate.flower.id != flower.id;
}
