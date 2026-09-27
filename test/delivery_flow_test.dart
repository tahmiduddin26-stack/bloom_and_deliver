import 'dart:io';
import 'dart:ui' as ui;

import 'package:bloom_and_deliver/data/delivery_data.dart';
import 'package:bloom_and_deliver/data/flower_data.dart';
import 'package:bloom_and_deliver/data/order_data.dart';
import 'package:bloom_and_deliver/models/game_state.dart';
import 'package:bloom_and_deliver/providers/game_provider.dart';
import 'package:bloom_and_deliver/providers/saved_state_provider.dart';
import 'package:bloom_and_deliver/screens/delivery_screen.dart';
import 'package:bloom_and_deliver/theme/app_theme.dart';
import 'package:bloom_and_deliver/widgets/end_of_day_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final mission = generateDeliveries(deliveryUnlockDay).first;

  test('every offered delivery asks for obtainable flower vibes', () {
    for (var day = deliveryUnlockDay; day <= 20; day++) {
      expect(generateDeliveries(day).length, inInclusiveRange(2, 3));
      final availableVibes = unlockedFlowers(
        day,
      ).expand((flower) => flower.vibes).toSet();
      for (final offered in generateDeliveries(day)) {
        expect(
          offered.requiredVibes.every(availableVibes.contains),
          isTrue,
          reason: 'Day $day delivery ${offered.id} asks for locked vibes',
        );
      }
    }
  });

  GameState ready() => GameState(
    day: deliveryUnlockDay,
    money: 100,
    inventory: const {'daisy': 20},
    inventoryDayAdded: const {'daisy': deliveryUnlockDay},
    dayOrders: generateDayOrders(deliveryUnlockDay),
    currentOrderIndex: 0,
    bouquetWorkspace: const [],
    completedToday: const [],
    dayEnded: true,
    pendingDeliveries: [mission],
    levelStars: const {1: 1, 2: 1, 3: 1, 4: 1},
  );

  for (final size in [const Size(390, 844), const Size(320, 640)]) {
    testWidgets('Day 4 summary offers deliveries at ${size.width}px', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final orders = generateDayOrders(deliveryUnlockDay);
      final finished = ready().copyWith(
        dayOrders: orders,
        currentOrderIndex: orders.length,
        completedToday: [for (final order in orders) (order, 20)],
      );
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [savedGameStateProvider.overrideWithValue(finished)],
          child: MaterialApp(
            theme: AppTheme.theme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(size.width == 320 ? 1.3 : 1),
              ),
              child: child!,
            ),
            home: EndOfDayDialog(onGoToMarket: () {}, onGoToDeliveries: () {}),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('Evening Deliveries'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('evening delivery fits and pays once at ${size.width}px', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(
        overrides: [savedGameStateProvider.overrideWithValue(ready())],
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
              child: DeliveryScreen(onDone: () {}),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('A little more joy around town'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(mission.location));
      await tester.pump();
      expect(find.text('Send bouquet'), findsOneWidget);
      for (var i = 0; i < mission.minFlowers; i++) {
        await tester.scrollUntilVisible(
          find.byTooltip('Add Daisy'),
          140,
          scrollable: find.byType(Scrollable).last,
        );
        await Scrollable.ensureVisible(
          tester.element(find.byTooltip('Add Daisy')),
          alignment: 0.2,
        );
        await tester.pump();
        await tester.tap(find.byTooltip('Add Daisy'));
        await tester.pump();
      }
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
            'build/previews/delivery-320.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          preview.dispose();
        });
      }
      await tester.tap(find.text('Send bouquet'));
      await tester.pump();
      final after = container.read(gameProvider);
      expect(after.pendingDeliveries.single.isCompleted, isTrue);
      expect(after.inventory['daisy'], 20 - mission.minFlowers);
      expect(after.money, greaterThan(100));
      expect(find.text('Lovely!'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Lovely!'));
      await tester.pump();
      expect(find.textContaining('Delivered •'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  }

  testWidgets('skip and Android back both return to the next-day flow once', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var continued = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [savedGameStateProvider.overrideWithValue(ready())],
        child: MaterialApp(
          theme: AppTheme.theme,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () =>
                    openDeliveryScreen(context, onDone: () => continued++),
                child: const Text('Open deliveries'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open deliveries'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(continued, 1);

    await tester.tap(find.text('Open deliveries'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(continued, 2);
    expect(find.byType(DeliveryScreen), findsNothing);
  });
}
