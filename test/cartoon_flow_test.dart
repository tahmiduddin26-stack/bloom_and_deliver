import 'package:bloom_and_deliver/data/flower_data.dart';
import 'package:bloom_and_deliver/data/order_data.dart';
import 'package:bloom_and_deliver/models/game_state.dart';
import 'package:bloom_and_deliver/providers/game_provider.dart';
import 'package:bloom_and_deliver/providers/saved_state_provider.dart';
import 'package:bloom_and_deliver/screens/market_screen.dart';
import 'package:bloom_and_deliver/screens/gem_shop_screen.dart';
import 'package:bloom_and_deliver/screens/level_map_screen.dart';
import 'package:bloom_and_deliver/screens/play_screen.dart';
import 'package:bloom_and_deliver/screens/shop_decor_screen.dart';
import 'package:bloom_and_deliver/screens/tutorial_screen.dart';
import 'package:bloom_and_deliver/screens/vibe_notebook_screen.dart';
import 'package:bloom_and_deliver/theme/app_theme.dart';
import 'package:bloom_and_deliver/services/iap_service.dart';
import 'package:bloom_and_deliver/widgets/customer_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  GameState savedState({bool failed = false, bool decorOwned = false}) =>
      GameState(
        day: 1,
        money: 500,
        inventory: defaultInventory,
        inventoryDayAdded: defaultInventoryDayAdded,
        dayOrders: generateDayOrders(1),
        currentOrderIndex: failed ? 3 : 0,
        bouquetWorkspace: const [],
        completedToday: const [],
        dayEnded: failed,
        purchasedDecor: decorOwned ? const {'wall_lavender'} : const {},
      );

  for (final size in [const Size(390, 844), const Size(320, 640)]) {
    testWidgets('market, decor and notebook fit ${size.width} px', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(
        overrides: [
          savedGameStateProvider.overrideWithValue(
            savedState(failed: true, decorOwned: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      Future<void> show(Widget screen) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(theme: AppTheme.theme, home: screen),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
      }

      await show(MarketScreen(onStartNextDay: () {}));
      expect(find.text('Retry Level 1 →'), findsOneWidget);
      await show(const ShopDecorScreen());
      expect(find.text('Dress the Shop'), findsOneWidget);
      await tester.tap(find.text('Lavender Fields'));
      await tester.pump();
      expect(
        container.read(gameProvider).activeDecor['wallpaper'],
        'wall_lavender',
      );
      expect(tester.takeException(), isNull);
      await show(const VibeNotebookScreen());
      expect(find.text('Flower Notebook'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  }

  testWidgets('the first customer uses a drawn portrait', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: TutorialScreen())),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    await tester.tap(find.textContaining('Next'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(CustomerAvatar), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('unconnected store offers earned gems without dead buy buttons', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    IapService.instance = const UnavailableIap();
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: GemShopSheet())),
      ),
    );
    await tester.pump();
    expect(find.text('Gem Garden'), findsOneWidget);
    expect(find.text('Handful of Gems'), findsNothing);
    expect(find.textContaining('Replay a level'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('journey and order fit narrow screen with larger text', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [savedGameStateProvider.overrideWithValue(savedState())],
    );
    addTearDown(container.dispose);

    Future<void> show(Widget screen) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.theme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: screen,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    }

    await show(const LevelMapScreen());
    await show(const PlayScreen());
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('bouquet result appears before a florist rank-up', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final order = generateDayOrders(1).first;
    final container = ProviderContainer(
      overrides: [
        savedGameStateProvider.overrideWithValue(
          savedState().copyWith(
            xp: 99,
            bouquetWorkspace: allFlowers.take(order.minFlowers).toList(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.theme, home: const PlayScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.textContaining('Give Bouquet'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Rank Up!'), findsNothing);
    expect(find.textContaining('+\$'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Rank Up!'), findsOneWidget);
    await tester.tap(find.textContaining('Keep Blooming'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('day summary waits for a rank-up reward', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final orders = generateDayOrders(1);
    final container = ProviderContainer(
      overrides: [
        savedGameStateProvider.overrideWithValue(
          savedState().copyWith(
            xp: 99,
            currentOrderIndex: orders.length - 1,
            bouquetWorkspace: allFlowers.take(orders.last.minFlowers).toList(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.theme, home: const PlayScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.textContaining('Give Bouquet'));
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Rank Up!'), findsOneWidget);
    expect(find.text('End of Day 1'), findsNothing);
    await tester.tap(find.textContaining('Keep Blooming'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('End of Day 1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
