import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';

/// Holds the pre-loaded saved state (set at ProviderScope level in main.dart).
/// Returns null if no save exists — GameNotifier will start fresh in that case.
final savedGameStateProvider = Provider<GameState?>((_) => null);
