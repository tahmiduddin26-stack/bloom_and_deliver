import 'package:flutter/material.dart';

/// Small, consistent customer portraits drawn in the game's inked cartoon style.
/// A name always maps to the same colours and features on every screen.
class CustomerAvatar extends StatelessWidget {
  final String name;
  final double size;

  const CustomerAvatar({super.key, required this.name, this.size = 46});

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$name portrait',
    image: true,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF244B3B), width: 2.5),
      ),
      child: ClipOval(child: CustomPaint(painter: _CustomerPainter(name))),
    ),
  );
}

class _CustomerPainter extends CustomPainter {
  final String name;
  const _CustomerPainter(this.name);

  static const _backdrops = [
    Color(0xFFFFD8C7),
    Color(0xFFD5E9B3),
    Color(0xFFF9DEA0),
    Color(0xFFD9D1EF),
    Color(0xFFBCE4E5),
  ];
  static const _skin = [
    Color(0xFFF5C59B),
    Color(0xFFDC9F71),
    Color(0xFFAD704E),
    Color(0xFF8D563E),
    Color(0xFFF6D6B9),
  ];
  static const _hair = [
    Color(0xFF56372E),
    Color(0xFF302A31),
    Color(0xFF8A5138),
    Color(0xFFC17440),
    Color(0xFFE8C77E),
  ];
  static const _clothes = [
    Color(0xFFEF7690),
    Color(0xFF81B779),
    Color(0xFF768DBD),
    Color(0xFFE9A556),
    Color(0xFFA186BE),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    var seed = 0;
    for (final unit in name.codeUnits) {
      seed = (seed * 31 + unit) & 0x7fffffff;
    }
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final ink = Paint()
      ..color = const Color(0xFF3C493E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    void oval(Rect rect, Color fill) {
      canvas.drawOval(rect, Paint()..color = fill);
      canvas.drawOval(rect, ink);
    }

    canvas.drawColor(_backdrops[seed % _backdrops.length], BlendMode.src);
    final shirt = _clothes[(seed ~/ 7) % _clothes.length];
    final skin = _skin[(seed ~/ 3) % _skin.length];
    final hair = _hair[(seed ~/ 11) % _hair.length];
    oval(const Rect.fromLTWH(12, 72, 76, 64), shirt);
    oval(const Rect.fromLTWH(24, 15, 52, 65), hair);
    oval(const Rect.fromLTWH(28, 27, 44, 51), skin);
    if (seed.isEven) {
      final fringe = Path()
        ..moveTo(26, 45)
        ..quadraticBezierTo(30, 10, 65, 21)
        ..quadraticBezierTo(80, 31, 70, 42)
        ..quadraticBezierTo(55, 37, 49, 27)
        ..quadraticBezierTo(40, 40, 26, 45);
      canvas.drawPath(fringe, Paint()..color = hair);
      canvas.drawPath(fringe, ink);
    } else {
      oval(const Rect.fromLTWH(22, 16, 58, 26), hair);
    }
    final features = Paint()..color = const Color(0xFF3C493E);
    canvas.drawCircle(const Offset(40, 52), 2.4, features);
    canvas.drawCircle(const Offset(60, 52), 2.4, features);
    canvas.drawArc(const Rect.fromLTWH(42, 55, 16, 11), 0.1, 2.8, false, ink);
    if (seed % 5 == 0) {
      canvas.drawCircle(const Offset(40, 51), 8, ink);
      canvas.drawCircle(const Offset(60, 51), 8, ink);
      canvas.drawLine(const Offset(48, 50), const Offset(52, 50), ink);
    }
    if (seed % 3 == 0) {
      canvas.drawCircle(
        const Offset(27, 46),
        4,
        Paint()..color = const Color(0xFFFFCC55),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CustomerPainter oldDelegate) =>
      oldDelegate.name != name;
}
