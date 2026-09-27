import 'package:flutter/foundation.dart';

/// Compatibility surface for a future, deliberate ad integration.
///
/// The shipped game is ad-free, so this service intentionally has no SDK or
/// network dependency. Keeping the no-op entry point lets the feature flag
/// remain safe while avoiding stale mobile-ad build configuration.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  Future<void> init() async {
    debugPrint('AdService: ads are not part of this build.');
  }

  void dispose() {}
}
