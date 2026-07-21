import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/saved_state_provider.dart';
import 'screens/level_map_screen.dart';
import 'screens/tutorial_screen.dart';
import 'services/ad_service.dart';
import 'services/audio_service.dart';
import 'services/notification_service.dart';
import 'services/persistence_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Boot services (failures are silently swallowed inside each service).
  await NotificationService.instance.init();
  await AudioService.instance.startAmbient();
  await AdService.instance.init();

  // Load saved game state before the UI boots.
  final savedState = await PersistenceService.loadState();

  runApp(
    ProviderScope(
      overrides: [
        // If a save exists, seed the provider so GameNotifier starts from it.
        if (savedState != null)
          savedGameStateProvider.overrideWithValue(savedState),
      ],
      child: BloomAndDeliverApp(isNewPlayer: savedState == null),
    ),
  );
}

class BloomAndDeliverApp extends StatelessWidget {
  final bool isNewPlayer;
  const BloomAndDeliverApp({super.key, required this.isNewPlayer});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bloom & Deliver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      // New players see the tutorial; returning players land on the level map.
      home: isNewPlayer ? const TutorialScreen() : const LevelMapScreen(),
    );
  }
}
