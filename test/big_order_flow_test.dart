import 'dart:io';
import 'dart:ui' as ui;

import 'package:bloom_and_deliver/data/big_orders_data.dart';
import 'package:bloom_and_deliver/data/delivery_data.dart';
import 'package:bloom_and_deliver/data/flower_data.dart';
import 'package:bloom_and_deliver/data/order_data.dart';
import 'package:bloom_and_deliver/models/game_state.dart';
import 'package:bloom_and_deliver/providers/game_provider.dart';
import 'package:bloom_and_deliver/providers/saved_state_provider.dart';
import 'package:bloom_and_deliver/screens/big_order_screen.dart';
import 'package:bloom_and_deliver/services/persistence_service.dart';
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

  GameState ready() {
    final orders = generateDayOrders(7);
    return GameState(
      day: 7,
      money: 100,
      inventory: const {'rose': 20, 'lily': 20, 'babys_breath': 20},
      inventoryDayAdded: const {'rose': 7, 'lily': 7, 'babys_breath': 7},
      dayOrders: orders,
      currentOrderIndex: orders.length,
      bouquetWorkspace: const [],
      completedToday: [for (final order in orders) (order, 20)],
      dayEnded: true,
      activeBigOrder: bigOrderForDay(7),
      levelStars: {for (var day = 1; day <= 7; day++) day: 1},
    );
  }

  final bouquet = [
    flowerById['rose']!,
    flowerById['lily']!,
    flowerById['babys_breath']!,
    flowerById['rose']!,
    flowerById['lily']!,
  ];

  test('every commission window asks for obtainable moods', () {
    for (var day = 7; day <= 77; day += 14) {
      final order = bigOrderForDay(day)!;
      final availableVibes = unlockedFlowers(
        day,
      ).expand((flower) => flower.vibes).toSet();
      expect(
        order.requiredVibes.every(availableVibes.contains),
        isTrue,
        reason: 'Day $day commission asks for a locked mood',
      );
      expect(order.deadlineDay, day + 2);
    }
  });

  test('three distinct days pay once, survive save, then clear', () async {
    SharedPreferences.setMockInitialValues({});
    var container = ProviderContainer(
      overrides: [savedGameStateProvider.overrideWithValue(ready())],
    );
    var game = container.read(gameProvider.notifier);
    var state = container.read(gameProvider);
    expect(game.contributeBigOrder(bouquet), isNotNull);
    state = container.read(gameProvider);
    expect(state.activeBigOrder!.daysSubmitted, 1);
    expect(state.activeBigOrder!.contributions.first.gameDay, 7);
    expect(state.inventory['rose'], 18);
    final firstMoney = state.money;
    expect(game.contributeBigOrder(bouquet), isNull);
    expect(container.read(gameProvider).money, firstMoney);

    await PersistenceService.saveState(state);
    final restored = (await PersistenceService.loadState())!;
    container.dispose();
    container = ProviderContainer(
      overrides: [savedGameStateProvider.overrideWithValue(restored)],
    );
    game = container.read(gameProvider.notifier);
    expect(game.contributeBigOrder(bouquet), isNull);

    game.startNextDay();
    state = container.read(gameProvider);
    expect(state.day, 8);
    expect(state.activeBigOrder!.daysSubmitted, 1);
    expect(game.contributeBigOrder(bouquet), isNull);
    container.dispose();
    container = ProviderContainer(
      overrides: [
        savedGameStateProvider.overrideWithValue(
          state.copyWith(
            dayEnded: true,
            levelStars: {for (var day = 1; day <= 8; day++) day: 1},
          ),
        ),
      ],
    );
    game = container.read(gameProvider.notifier);
    expect(game.contributeBigOrder(bouquet), isNotNull);
    state = container.read(gameProvider);
    expect(state.activeBigOrder!.contributions[1].gameDay, 8);
    game.startNextDay();
    state = container.read(gameProvider);
    expect(state.day, 9);
    container.dispose();
    container = ProviderContainer(
      overrides: [
        savedGameStateProvider.overrideWithValue(
          state.copyWith(
            dayEnded: true,
            levelStars: {for (var day = 1; day <= 9; day++) day: 1},
          ),
        ),
      ],
    );
    game = container.read(gameProvider.notifier);
    final beforeFinish = container.read(gameProvider).money;
    expect(game.contributeBigOrder(bouquet), isNotNull);
    state = container.read(gameProvider);
    expect(state.activeBigOrder!.isComplete, isTrue);
    expect(state.activeBigOrder!.contributions[2].gameDay, 9);
    expect(
      state.money - beforeFinish,
      greaterThan(state.activeBigOrder!.dailyReward),
    );
    expect(game.contributeBigOrder(bouquet), isNull);
    game.startNextDay();
    expect(container.read(gameProvider).activeBigOrder, isNull);
    container.dispose();
  });

  test('missed deadline expires and later windows use their offer day', () {
    SharedPreferences.setMockInitialValues({});
    var container = ProviderContainer(
      overrides: [savedGameStateProvider.overrideWithValue(ready())],
    );
    var game = container.read(gameProvider.notifier);
    game.startNextDay();
    var state = container.read(gameProvider);
    container.dispose();
    container = ProviderContainer(
      overrides: [
        savedGameStateProvider.overrideWithValue(
          state.copyWith(
            dayEnded: true,
            levelStars: {for (var day = 1; day <= 8; day++) day: 1},
          ),
        ),
      ],
    );
    game = container.read(gameProvider.notifier);
    expect(game.contributeBigOrder(bouquet), isNotNull);
    game.startNextDay();
    state = container.read(gameProvider);
    container.dispose();
    container = ProviderContainer(
      overrides: [
        savedGameStateProvider.overrideWithValue(
          state.copyWith(
            dayEnded: true,
            levelStars: {for (var day = 1; day <= 9; day++) day: 1},
          ),
        ),
      ],
    );
    game = container.read(gameProvider.notifier);
    expect(game.contributeBigOrder(bouquet), isNotNull);
    expect(container.read(gameProvider).activeBigOrder!.isComplete, isFalse);
    game.startNextDay();
    expect(container.read(gameProvider).activeBigOrder, isNull);
    expect(bigOrderForDay(21)!.commissionDay, 21);
    expect(bigOrderForDay(21)!.deadlineDay, 23);
    expect(bigOrderForDay(21)!.canContributeOn(21), isTrue);
    container.dispose();
  });

  test('invalid stock and replay cannot award commission coins', () {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [savedGameStateProvider.overrideWithValue(ready())],
    );
    final game = container.read(gameProvider.notifier);
    expect(
      game.contributeBigOrder(List.filled(5, flowerById['peony']!)),
      isNull,
    );
    expect(
      game.contributeBigOrder(List.filled(10, flowerById['rose']!)),
      isNull,
    );
    final before = container.read(gameProvider);
    expect(game.startLevel(1), isTrue);
    expect(game.contributeBigOrder(bouquet), isNull);
    expect(container.read(gameProvider).money, before.money);
    container.dispose();
  });

  for (final size in [const Size(390, 844), const Size(320, 640)]) {
    testWidgets('commission fits and submits at ${size.width}px', (
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
              child: BigOrderScreen(onDone: () {}),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Deadline: end of Day 9'), findsOneWidget);
      expect(tester.takeException(), isNull);
      for (var i = 0; i < 5; i++) {
        await tester.scrollUntilVisible(
          find.byTooltip('Add Rose'),
          150,
          scrollable: find.byType(Scrollable).last,
        );
        await Scrollable.ensureVisible(
          tester.element(find.byTooltip('Add Rose')),
          alignment: 0.2,
        );
        await tester.pump();
        await tester.tap(find.byTooltip('Add Rose'));
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
            'build/previews/commission-320.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          preview.dispose();
        });
      }
      await tester.tap(find.text('Send arrangement'));
      await tester.pump();
      expect(container.read(gameProvider).activeBigOrder!.daysSubmitted, 1);
      expect(find.textContaining('coins'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Day 7 summary offers commission at ${size.width}px', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final orders = generateDayOrders(7);
      final finished = ready().copyWith(
        dayOrders: orders,
        currentOrderIndex: orders.length,
        completedToday: [for (final order in orders) (order, 20)],
        pendingDeliveries: generateDeliveries(7),
      );
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
            home: EndOfDayDialog(
              onGoToMarket: () {},
              onGoToBigOrder: () {},
              onGoToDeliveries: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Harrington Wedding'), findsOneWidget);
      expect(find.textContaining('Evening Deliveries'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
