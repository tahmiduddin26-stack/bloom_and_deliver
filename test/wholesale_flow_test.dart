import 'dart:io';
import 'dart:ui' as ui;

import 'package:bloom_and_deliver/data/flower_data.dart';
import 'package:bloom_and_deliver/data/order_data.dart';
import 'package:bloom_and_deliver/models/game_state.dart';
import 'package:bloom_and_deliver/providers/game_provider.dart';
import 'package:bloom_and_deliver/providers/saved_state_provider.dart';
import 'package:bloom_and_deliver/screens/town_map_screen.dart';
import 'package:bloom_and_deliver/screens/market_screen.dart';
import 'package:bloom_and_deliver/screens/wholesale_screen.dart';
import 'package:bloom_and_deliver/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  GameState dayThree() => GameState(
    day: 3,
    money: 100,
    inventory: defaultInventory,
    inventoryDayAdded: defaultInventoryDayAdded,
    dayOrders: generateDayOrders(3),
    currentOrderIndex: 0,
    bouquetWorkspace: const [],
    completedToday: const [],
    levelStars: const {1: 1, 2: 1},
  );

  for (final size in [const Size(390, 844), const Size(320, 640)]) {
    testWidgets('wholesale cart fits and places an order at ${size.width}px', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(
        overrides: [savedGameStateProvider.overrideWithValue(dayThree())],
      );
      addTearDown(container.dispose);
      final previewKey = GlobalKey();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.theme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(size.width == 320 ? 1.3 : 1),
              ),
              child: child!,
            ),
            home: RepaintBoundary(
              key: previewKey,
              child: const WholesaleScreen(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Plan tomorrow’s blooms'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (size.width == 320 &&
          Platform.environment['SAVE_GAME_PREVIEWS'] == '1') {
        await tester.runAsync(() async {
          final boundary =
              previewKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final preview = await boundary.toImage(pixelRatio: 2);
          final bytes = await preview.toByteData(
            format: ui.ImageByteFormat.png,
          );
          await Directory('build/previews').create(recursive: true);
          await File(
            'build/previews/wholesale-320.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          preview.dispose();
        });
      }

      await tester.scrollUntilVisible(
        find.byTooltip('Add Daisy bundle'),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      await Scrollable.ensureVisible(
        tester.element(find.byTooltip('Add Daisy bundle')),
        alignment: 0.2,
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Add Daisy bundle'));
      await tester.pump();
      expect(find.text('Place order for \$10'), findsOneWidget);
      await tester.tap(find.text('Place order for \$10'));
      await tester.pump();
      expect(container.read(gameProvider).wholesalePending['daisy'], 5);
      expect(container.read(gameProvider).money, 90);
      await tester.scrollUntilVisible(
        find.text('On the way for next level'),
        -120,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('On the way for next level'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Day 3 market shows depot at ${size.width}px', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [savedGameStateProvider.overrideWithValue(dayThree())],
          child: MaterialApp(
            theme: AppTheme.theme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(size.width == 320 ? 1.3 : 1),
              ),
              child: child!,
            ),
            home: const MarketScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Wholesale'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  }

  testWidgets('Day 3 town opens the depot', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [savedGameStateProvider.overrideWithValue(dayThree())],
        child: MaterialApp(
          theme: AppTheme.theme,
          home: Builder(
            builder: (context) => TownMapScreen(
              onGoToWholesale: () => openWholesaleScreen(context),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.ensureVisible(find.text('Wholesale Depot'));
    await tester.tap(find.text('Wholesale Depot'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(WholesaleScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
