import 'dart:io';
import 'dart:ui' as ui;

import 'package:bloom_and_deliver/data/flower_data.dart';
import 'package:bloom_and_deliver/theme/app_theme.dart';
import 'package:bloom_and_deliver/widgets/cartoon_flower.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders the app's own sunflower drawing into Android launcher densities.
///
/// Run with: flutter test tool/generate_launcher_icon.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('render Bloom & Deliver launcher icon', () async {
    const sizes = {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    };
    final sunflower = flowerById['sunflower']!;
    for (final entry in sizes.entries) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..scale(entry.value / 432);
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 432, 432),
        Paint()..color = AppColors.gardenGreenDark,
      );
      canvas.drawCircle(
        const Offset(216, 211),
        165,
        Paint()..color = AppColors.cream,
      );
      canvas.drawCircle(
        const Offset(216, 211),
        165,
        Paint()
          ..color = AppColors.cartoonInk
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11,
      );
      canvas.save();
      canvas.translate(69, 55);
      CartoonFlowerPainter(sunflower).paint(canvas, const Size(294, 294));
      canvas.restore();

      final image = await recorder.endRecording().toImage(
        entry.value,
        entry.value,
      );
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File(
        'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
      );
      await file.writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
      expect(await file.length(), greaterThan(0));
    }
  });
}
