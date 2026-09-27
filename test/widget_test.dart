import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bloom_and_deliver/main.dart';
import 'package:bloom_and_deliver/data/flower_data.dart';
import 'package:bloom_and_deliver/screens/play_screen.dart';
import 'package:bloom_and_deliver/screens/upgrades_screen.dart';
import 'package:bloom_and_deliver/theme/app_theme.dart';
import 'package:bloom_and_deliver/widgets/bouquet_preview.dart';
import 'package:bloom_and_deliver/widgets/flower_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('every selected stem is drawn in a mixed bouquet', (
    tester,
  ) async {
    final bouquet = allFlowers.take(9).toList();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: BouquetPreview(flowers: bouquet, size: 190)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FlowerImage), findsNWidgets(bouquet.length));
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(390, 844), const Size(320, 640)]) {
    testWidgets('journey and shop fit ${size.width} wide screens offline', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const ProviderScope(child: BloomAndDeliverApp(isNewPlayer: false)),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Your flowering journey'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final context = tester.element(find.text('Your flowering journey'));
      openUpgradesScreen(context);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Flower Cooler'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('bouquet workspace fits ${size.width} wide screens', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(theme: AppTheme.theme, home: const PlayScreen()),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Restock flowers'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    });
  }
}
