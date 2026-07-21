import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../models/bouquet_order.dart';
import '../models/flower.dart';
import '../theme/app_theme.dart';
import 'flower_image.dart';

/// Shows a share sheet after a great order.
/// Renders an in-memory card widget, captures it as PNG, shares via system sheet.
Future<void> shareBouquetCard({
  required BuildContext context,
  required BouquetOrder order,
  required List<Flower> bouquet,
  required int earned,
}) async {
  try {
    // Render the card off-screen
    final bytes = await _renderCard(order: order, bouquet: bouquet, earned: earned);
    if (bytes == null) return;

    // Write to temp file
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/bouquet_share.png');
    await file.writeAsBytes(bytes);

    // Share
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      text: '🌸 Just crafted a perfect bouquet at Bloom & Deliver! '
          'Got a ⭐ Great rating from ${order.customer.name}. '
          'Download Bloom & Deliver to grow your own flower shop!',
    );
  } catch (e) {
    debugPrint('shareBouquetCard failed: $e');
  }
}

Future<Uint8List?> _renderCard({
  required BouquetOrder order,
  required List<Flower> bouquet,
  required int earned,
}) async {
  try {
    // Render via overlay-backed RepaintBoundary
    final completer = _OffscreenRenderer(
      order: order,
      bouquet: bouquet,
      earned: earned,
    );
    return await completer.capture();
  } catch (e) {
    debugPrint('_renderCard error: $e');
    return null;
  }
}

class _OffscreenRenderer {
  final BouquetOrder order;
  final List<Flower> bouquet;
  final int earned;

  _OffscreenRenderer({
    required this.order,
    required this.bouquet,
    required this.earned,
  });

  Future<Uint8List?> capture() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = const Size(400, 560);

      _paintCard(canvas, size);

      final picture = recorder.endRecording();
      final img = await picture.toImage(
        (size.width * 3).toInt(),
        (size.height * 3).toInt(),
      );
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('capture failed: $e');
      return null;
    }
  }

  void _paintCard(Canvas canvas, Size size) {
    final scale = 3.0;
    canvas.scale(scale);

    // Background gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E3A26), Color(0xFF2D5438)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(24)),
      bgPaint,
    );

    // Decorative flowers in background
    const flowerEmojis = ['🌸', '🌿', '💐', '🌺', '✨'];
    final decorPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < flowerEmojis.length; i++) {
      decorPainter.text = TextSpan(
        text: flowerEmojis[i],
        style: TextStyle(fontSize: 28 + (i * 4).toDouble()),
      );
      decorPainter.layout();
      canvas.save();
      canvas.translate(20.0 + i * 80, 20.0 + (i % 2) * 30);
      canvas.rotate((i - 2) * 0.15);
      decorPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }

    // Shop name
    final titlePainter = TextPainter(textDirection: TextDirection.ltr);
    titlePainter.text = const TextSpan(
      text: '🌸 Bloom & Deliver',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
    titlePainter.layout(maxWidth: size.width - 40);
    titlePainter.paint(canvas, const Offset(20, 100));

    // Rating banner
    final ratingPaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.15);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(20, 132, 380, 180), const Radius.circular(12)),
      ratingPaint,
    );
    final ratingPainter = TextPainter(textDirection: TextDirection.ltr);
    ratingPainter.text = const TextSpan(
      text: '⭐ GREAT ORDER',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: Color(0xFFFFD700),
        letterSpacing: 1.5,
      ),
    );
    ratingPainter.layout();
    ratingPainter.paint(canvas, const Offset(28, 144));

    // Customer name
    final custPainter = TextPainter(textDirection: TextDirection.ltr);
    custPainter.text = TextSpan(
      text: 'For ${order.customer.name}',
      style: TextStyle(
        fontSize: 14,
        color: Colors.white.withOpacity(0.7),
        fontStyle: FontStyle.italic,
      ),
    );
    custPainter.layout();
    custPainter.paint(canvas, const Offset(20, 192));

    // Bouquet flowers (emoji row)
    final uniqueFlowers = bouquet.toSet().toList();
    final flowerPainter = TextPainter(textDirection: TextDirection.ltr);
    double fx = 20;
    for (final f in uniqueFlowers.take(8)) {
      flowerPainter.text = TextSpan(
        text: f.emoji,
        style: const TextStyle(fontSize: 36),
      );
      flowerPainter.layout();
      flowerPainter.paint(canvas, Offset(fx, 220));
      fx += 44;
    }

    // Earnings
    final earnPainter = TextPainter(textDirection: TextDirection.ltr);
    earnPainter.text = TextSpan(
      text: '+\$$earned earned',
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: Color(0xFF7CFC88),
      ),
    );
    earnPainter.layout();
    earnPainter.paint(canvas, const Offset(20, 300));

    // Hint snippet
    final hintPainter = TextPainter(textDirection: TextDirection.ltr);
    hintPainter.text = TextSpan(
      text: '"${order.hint}"',
      style: TextStyle(
        fontSize: 12,
        color: Colors.white.withOpacity(0.55),
        fontStyle: FontStyle.italic,
      ),
    );
    hintPainter.layout(maxWidth: size.width - 40);
    hintPainter.paint(canvas, const Offset(20, 348));

    // Footer
    final footerPaint = Paint()
      ..color = Colors.white.withOpacity(0.06);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(0, 500, 400, 560), const Radius.circular(0)),
      footerPaint,
    );
    final footerPainter = TextPainter(textDirection: TextDirection.ltr);
    footerPainter.text = TextSpan(
      text: '🌷 Download Bloom & Deliver and open your own flower shop!',
      style: TextStyle(
        fontSize: 11,
        color: Colors.white.withOpacity(0.5),
      ),
    );
    footerPainter.layout(maxWidth: size.width - 40);
    footerPainter.paint(canvas, const Offset(20, 516));
  }
}

// ── In-app preview card (reserved for future dialog preview) ─────────────────
// ignore: unused_element
class _BouquetCardWidget extends StatelessWidget {
  final GlobalKey repaintKey;
  final BouquetOrder order;
  final List<Flower> bouquet;
  final int earned;

  const _BouquetCardWidget({
    required this.repaintKey,
    required this.order,
    required this.bouquet,
    required this.earned,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A26), Color(0xFF2D5438)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🌸 Bloom & Deliver',
                style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.4)),
              ),
              child: Text('⭐ GREAT ORDER',
                  style: GoogleFonts.nunito(
                    color: const Color(0xFFFFD700),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  )),
            ),
            const SizedBox(height: 8),
            Text('For ${order.customer.name}',
                style: GoogleFonts.nunito(
                    color: Colors.white54,
                    fontSize: 12,
                    fontStyle: FontStyle.italic)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: bouquet
                  .toSet()
                  .map((f) => FlowerImage(flower: f, size: 36))
                  .toList(),
            ),
            const SizedBox(height: 14),
            Text('+\$$earned earned',
                style: GoogleFonts.nunito(
                  color: const Color(0xFF7CFC88),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                )),
          ],
        ),
      ),
    );
  }
}

/// Shows a bottom sheet preview of the share card with a Share button.
Future<void> showShareSheet({
  required BuildContext context,
  required BouquetOrder order,
  required List<Flower> bouquet,
  required int earned,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _ShareSheetBody(
      order: order,
      bouquet: bouquet,
      earned: earned,
    ),
  );
}

class _ShareSheetBody extends StatefulWidget {
  final BouquetOrder order;
  final List<Flower> bouquet;
  final int earned;

  const _ShareSheetBody({
    required this.order,
    required this.bouquet,
    required this.earned,
  });

  @override
  State<_ShareSheetBody> createState() => _ShareSheetBodyState();
}

class _ShareSheetBodyState extends State<_ShareSheetBody> {
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '🌸 Share your bouquet!',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Show off your great work to friends',
            style: GoogleFonts.nunito(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          // Mini preview
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D5438), Color(0xFF1E3A26)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      'GREAT ORDER',
                      style: GoogleFonts.nunito(
                        color: const Color(0xFFFFD700),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'For ${widget.order.customer.name}',
                  style: GoogleFonts.nunito(
                      color: Colors.white54,
                      fontSize: 11,
                      fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 2,
                  children: widget.bouquet
                      .toSet()
                      .take(8)
                      .map((f) => FlowerImage(flower: f, size: 32))
                      .toList(),
                ),
                const SizedBox(height: 8),
                Text(
                  '+\$${widget.earned}',
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF7CFC88),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _sharing
                  ? null
                  : () async {
                      setState(() => _sharing = true);
                      HapticFeedback.mediumImpact();
                      await shareBouquetCard(
                        context: context,
                        order: widget.order,
                        bouquet: widget.bouquet,
                        earned: widget.earned,
                      );
                      if (mounted) setState(() => _sharing = false);
                    },
              icon: _sharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('📤', style: TextStyle(fontSize: 18)),
              label: Text(
                _sharing ? 'Preparing...' : 'Share Bouquet',
                style: GoogleFonts.nunito(
                    fontSize: 16, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gardenGreenMid,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
