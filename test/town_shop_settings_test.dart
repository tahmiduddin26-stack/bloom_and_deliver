import 'package:bloom_and_deliver/config/feature_flags.dart';
import 'package:bloom_and_deliver/data/flower_data.dart';
import 'package:bloom_and_deliver/data/order_data.dart';
import 'package:bloom_and_deliver/models/game_state.dart';
import 'package:bloom_and_deliver/providers/saved_state_provider.dart';
import 'package:bloom_and_deliver/screens/level_map_screen.dart';
import 'package:bloom_and_deliver/screens/settings_screen.dart';
import 'package:bloom_and_deliver/screens/shop_interior_screen.dart';
import 'package:bloom_and_deliver/screens/shop_stats_screen.dart';
import 'package:bloom_and_deliver/screens/town_map_screen.dart';
import 'package:bloom_and_deliver/services/audio_service.dart';
import 'package:bloom_and_deliver/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  GameState savedGame() => GameState(
    day: 1,
    money: 500,
    inventory: defaultInventory,
    inventoryDayAdded: defaultInventoryDayAdded,
    dayOrders: generateDayOrders(1),
    currentOrderIndex: 0,
    bouquetWorkspace: const [],
    completedToday: const [],
  );

  for (final size in [const Size(390, 844), const Size(320, 640)]) {
    testWidgets('town, shop, records and settings fit ${size.width} px', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Future<void> show(Widget screen) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [savedGameStateProvider.overrideWithValue(savedGame())],
            child: MaterialApp(
              theme: AppTheme.theme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(size.width == 320 ? 1.3 : 1),
                ),
                child: child!,
              ),
              home: screen,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
      }

      await show(TownMapScreen(onGoToShop: () {}, onGoToMarket: () {}));
      expect(find.text('Where to, florist?'), findsOneWidget);
      expect(find.text('Wholesale Depot'), findsNothing);
      await show(const ShopInteriorScreen());
      expect(find.text('Make it yours'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Achievements'),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Achievements'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      await show(const ShopStatsScreen());
      expect(find.text('Your shop in numbers'), findsOneWidget);
      await show(const SettingsScreen());
      expect(find.text('Sound & music'), findsOneWidget);
      await show(const LevelMapScreen());
      expect(find.text('Town'), findsOneWidget);
      expect(find.text('Shop'), findsOneWidget);
      expect(find.text('Market'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  }

  testWidgets('journey opens town, shop and settings with live actions', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AudioService.instance.loadPreferences();
    expect(Features.townMap && Features.shopInterior, isTrue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [savedGameStateProvider.overrideWithValue(savedGame())],
        child: MaterialApp(theme: AppTheme.theme, home: const LevelMapScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byTooltip('Explore Bloomfield'));
    await tester.pumpAndSettle();
    expect(find.text('Where to, florist?'), findsOneWidget);

    await tester.tap(find.text('Your Flower Shop'));
    await tester.pumpAndSettle();
    expect(find.byType(ShopInteriorScreen), findsOneWidget);
    expect(find.text('Windowsill Garden'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Shop Records'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('Shop Records'));
    await tester.tap(find.text('Shop Records'));
    await tester.pumpAndSettle();
    expect(find.byType(ShopStatsScreen), findsOneWidget);
    expect(find.text('Your shop in numbers'), findsOneWidget);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ShopInteriorScreen), findsOneWidget);
    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ShopInteriorScreen), findsNothing);
    expect(find.byType(LevelMapScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Sound & music'), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await tester.pump(const Duration(milliseconds: 200));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('sound_muted'), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
