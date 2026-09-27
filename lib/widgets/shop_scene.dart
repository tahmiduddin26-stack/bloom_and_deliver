import 'package:flutter/material.dart';
import '../data/shop_decor_data.dart';
import '../models/shop_upgrades.dart';

/// A tiny illustrated shop whose equipment reflects the player's purchases.
class ShopScene extends StatelessWidget {
  final ShopUpgrades upgrades;
  final Map<String, String> activeDecor;
  const ShopScene({
    super.key,
    required this.upgrades,
    this.activeDecor = const {},
  });
  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Your flower shop. Installed: ${upgrades.purchased.map((id) => id.title).join(', ')}',
    image: true,
    child: CustomPaint(
      painter: _ShopPainter(upgrades, activeDecor),
      size: const Size(340, 120),
    ),
  );
}

class _ShopPainter extends CustomPainter {
  final ShopUpgrades upgrades;
  final Map<String, String> activeDecor;
  _ShopPainter(this.upgrades, this.activeDecor);
  static const ink = Color(0xFF354C3E);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final scale = (size.width / 340).clamp(0.0, size.height / 120);
    canvas.translate(
      (size.width - 340 * scale) / 2,
      (size.height - 120 * scale) / 2,
    );
    canvas.scale(scale);
    final line = Paint()
      ..color = ink
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    void box(
      double x,
      double y,
      double w,
      double h,
      Color color, [
      double radius = 4,
    ]) {
      final shape = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        Radius.circular(radius),
      );
      canvas.drawRRect(shape, Paint()..color = color);
      canvas.drawRRect(shape, line);
    }

    void circle(double x, double y, double r, Color color) {
      canvas.drawCircle(Offset(x, y), r, Paint()..color = color);
      canvas.drawCircle(Offset(x, y), r, line);
    }

    final wall =
        decorById[activeDecor['wallpaper'] ?? defaultActiveDecor['wallpaper']];
    final floor =
        decorById[activeDecor['floorTile'] ?? defaultActiveDecor['floorTile']];
    final counter =
        decorById[activeDecor['counter'] ?? defaultActiveDecor['counter']];
    final plant = activeDecor['windowPlant'] ?? 'plant_none';
    final lights = activeDecor['fairyLights'] ?? 'lights_none';
    final display = activeDecor['windowDisplay'] ?? 'display_none';
    final wallColor = Color.lerp(
      wall?.gradientColors?.first ?? const Color(0xFF1C5232),
      const Color(0xFFFFF1CF),
      .72,
    )!;
    final floorColor = Color.lerp(
      floor?.gradientColors?.first ?? const Color(0xFF5C3A1E),
      const Color(0xFFE9BE87),
      .38,
    )!;
    box(63, 19, 209, 89, wallColor);
    box(63, 101, 209, 8, floorColor);
    box(
      83,
      46,
      75,
      47,
      display == 'display_winter'
          ? const Color(0xFFDAF3F7)
          : const Color(0xFFB9E5EA),
    );
    box(184, 46, 54, 62, const Color(0xFF77B586));
    box(193, 53, 36, 30, const Color(0xFFD5F0E4));
    circle(229, 94, 2, const Color(0xFFFFCF57));
    box(52, 10, 231, 18, const Color(0xFFFFFCED));
    for (var i = 0; i < 10; i++) {
      box(
        53 + i * 23,
        11,
        23,
        24,
        i.isEven ? const Color(0xFFEF7C91) : const Color(0xFFFFFCED),
        5,
      );
    }
    box(74, 89, 94, 18, counter?.accentColor ?? const Color(0xFFC68B61));
    for (var i = 0; i < 4; i++) {
      final x = 87.0 + i * 20;
      canvas.drawLine(Offset(x, 90), Offset(x, 71), line);
      circle(
        x,
        70,
        7,
        i.isEven ? const Color(0xFFF3829B) : const Color(0xFFFFCF57),
      );
      circle(x, 70, 2, const Color(0xFFFFE8A5));
    }
    if (plant != 'plant_none') {
      box(132, 78, 14, 12, const Color(0xFFBE8460));
      canvas.drawLine(const Offset(139, 78), const Offset(139, 65), line);
      circle(
        135,
        66,
        5,
        plant == 'plant_sunflower'
            ? const Color(0xFFFFCE55)
            : const Color(0xFF76B567),
      );
      circle(143, 67, 5, const Color(0xFF76B567));
    }
    if (lights != 'lights_none') {
      for (var i = 0; i < 6; i++) {
        circle(
          90 + i * 27,
          38,
          3,
          lights == 'lights_rose'
              ? const Color(0xFFEF7690)
              : i.isEven
              ? const Color(0xFFFFCE55)
              : const Color(0xFFB397D0),
        );
      }
    }
    if (display != 'display_none') {
      for (var i = 0; i < 3; i++) {
        circle(
          97 + i * 20,
          72,
          6,
          display == 'display_harvest'
              ? const Color(0xFFEA9A52)
              : const Color(0xFFEF7690),
        );
      }
    }
    if (upgrades.hasDisplayWindow) {
      box(94, 39, 55, 12, const Color(0xFFFFD35B));
      for (var i = 0; i < 4; i++) {
        circle(104 + i * 12, 45, 2, const Color(0xFFFFFCED));
      }
    }
    if (upgrades.hasExtraShelf) {
      box(19, 70, 36, 7, const Color(0xFFC68B61));
      box(19, 93, 36, 7, const Color(0xFFC68B61));
      for (var i = 0; i < 2; i++) {
        box(23 + i * 17, 55, 12, 15, const Color(0xFF8EC777));
        box(23 + i * 17, 80, 12, 13, const Color(0xFFF5C967));
      }
    }
    if (upgrades.hasFlowerCooler) {
      box(279, 42, 39, 64, const Color(0xFFC1E1EE));
      box(285, 49, 27, 37, const Color(0xFFE9F8FD));
      canvas.drawLine(const Offset(285, 94), const Offset(293, 94), line);
    }
    if (upgrades.has(UpgradeId.teaCart)) {
      box(12, 94, 44, 11, const Color(0xFFF4B85C));
      box(18, 81, 15, 13, const Color(0xFFFFFCED));
      circle(37, 88, 5, const Color(0xFFFFFCED));
      circle(21, 112, 4, const Color(0xFF93714F));
      circle(47, 112, 4, const Color(0xFF93714F));
    }
    if (upgrades.hasWrappingStation || upgrades.hasWorkspaceXL) {
      box(166, 94, 61, 10, const Color(0xFFD4A879));
      box(169, 105, 5, 12, const Color(0xFF9C754C));
      box(218, 105, 5, 12, const Color(0xFF9C754C));
    }
    if (upgrades.has(UpgradeId.ribbonRack)) {
      for (var i = 0; i < 3; i++) {
        circle(
          251,
          52 + i * 15,
          5,
          [
            const Color(0xFFEF7C91),
            const Color(0xFFFFCF57),
            const Color(0xFFA993D4),
          ][i],
        );
      }
    }
    if (upgrades.has(UpgradeId.tipJar)) {
      box(176, 81, 12, 13, const Color(0xFFFFCF57));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShopPainter oldDelegate) =>
      oldDelegate.upgrades != upgrades ||
      oldDelegate.activeDecor != activeDecor;
}
