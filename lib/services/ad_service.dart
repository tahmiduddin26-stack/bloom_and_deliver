import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Manages the AdMob banner ad lifecycle.
///
/// Usage:
///   1. Call `AdService.instance.init()` in main() before runApp.
///   2. Use `AdService.instance.bannerAd` to get the loaded ad.
///   3. Listen to `AdService.instance.isLoaded` to know when it's ready.
///   4. Call `dispose()` when the host widget is torn down.
///
/// ⚠️  Replace the test IDs below with your real AdMob unit IDs before
///     releasing to production. Test IDs are safe to use during development
///     — using real IDs during testing violates AdMob policy.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // ── Ad unit IDs ────────────────────────────────────────────────────────────

  /// Switch these out for your real IDs from the AdMob console.
  static String get _bannerAdUnitId {
    if (kDebugMode) {
      // Google's official test banner IDs — safe to use in development.
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    // ── Production IDs ──────────────────────────────────────────────────────
    // Replace these with your real unit IDs from admob.google.com
    return Platform.isAndroid
        ? 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX' // ← your Android banner ID
        : 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX'; // ← your iOS banner ID
  }

  // ── State ──────────────────────────────────────────────────────────────────

  BannerAd? _bannerAd;
  bool _isLoaded = false;

  BannerAd? get bannerAd => _bannerAd;
  bool get isLoaded => _isLoaded;

  /// Callback fired when the ad loads or fails — wire this to setState() in
  /// the widget that shows the banner.
  VoidCallback? onAdStateChanged;

  // ── Init ───────────────────────────────────────────────────────────────────

  /// Call once in main() before runApp. Initialises the Mobile Ads SDK and
  /// loads the first banner.
  Future<void> init() async {
    try {
      await MobileAds.instance.initialize();
      _loadBanner();
    } catch (e) {
      debugPrint('AdService init failed: $e');
    }
  }

  // ── Banner loading ──────────────────────────────────────────────────────────

  void _loadBanner() {
    _bannerAd?.dispose();
    _isLoaded = false;

    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner, // 320×50 — standard banner
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _isLoaded = true;
          debugPrint('AdService: banner loaded');
          onAdStateChanged?.call();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdService: banner failed — ${error.message}');
          ad.dispose();
          _bannerAd = null;
          _isLoaded = false;
          onAdStateChanged?.call();
          // Retry after 60 s
          Future.delayed(const Duration(seconds: 60), _loadBanner);
        },
        onAdOpened: (_) => debugPrint('AdService: banner opened'),
        onAdClosed: (_) => _loadBanner(), // reload after user closes the ad
      ),
    )..load();
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────

  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;
  }
}
