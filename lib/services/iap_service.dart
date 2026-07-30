import 'package:flutter/foundation.dart';

import '../data/gem_data.dart';

/// Outcome of a purchase attempt.
enum PurchaseStatus {
  /// The store confirmed a completed, paid transaction.
  success,

  /// The player backed out. Not an error — say nothing accusatory.
  cancelled,

  /// No billing backend is wired, or the store is unreachable/disabled.
  unavailable,

  /// The store returned an error.
  error,
}

class PurchaseResult {
  final PurchaseStatus status;

  /// Gems to credit. Non-zero only on [PurchaseStatus.success].
  final int gems;
  final String? message;

  const PurchaseResult(this.status, {this.gems = 0, this.message});

  bool get isSuccess => status == PurchaseStatus.success;
}

/// In-app purchase seam for gem packs.
///
/// The game ships with [UnavailableIap], which refuses every purchase, because
/// **no real billing SDK is wired yet**. Selling gems for real money requires
/// store setup that lives outside this repo:
///
///   1. Create the products in Google Play Console / App Store Connect using the
///      `productId`s in `gem_data.dart`.
///   2. Add a billing plugin (e.g. `in_app_purchase`) and implement this
///      interface against it — including server-side receipt validation, which
///      is what actually stops clients from minting free gems.
///   3. Assign it once at startup: `IapService.instance = MyStoreIap();`
///
/// Until then the gem shop honestly reports that purchases are unavailable
/// rather than pretending money changed hands.
abstract class IapService {
  const IapService();

  static IapService instance = const UnavailableIap();

  /// Whether purchases can currently be made.
  Future<bool> isAvailable();

  /// Attempt to buy [pack]. Implementations must only report
  /// [PurchaseStatus.success] after the store confirms payment.
  Future<PurchaseResult> buy(GemPack pack);

  /// Re-grant non-consumable entitlements. Stores require a visible "restore"
  /// path; consumable gem packs are typically credited on purchase instead.
  Future<void> restorePurchases() async {}
}

/// Default: no billing backend. Every purchase is refused.
class UnavailableIap extends IapService {
  const UnavailableIap();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<PurchaseResult> buy(GemPack pack) async => const PurchaseResult(
        PurchaseStatus.unavailable,
        message: 'The gem shop isn\'t open yet — no store is connected.',
      );
}

/// Debug-only stub so the gem flows can be exercised without a store account.
///
/// It grants gems **without any payment** and therefore refuses to run outside
/// debug builds — assign it only behind a `kDebugMode` check.
class DebugIap extends IapService {
  const DebugIap();

  @override
  Future<bool> isAvailable() async => kDebugMode;

  @override
  Future<PurchaseResult> buy(GemPack pack) async {
    if (!kDebugMode) {
      return const PurchaseResult(
        PurchaseStatus.unavailable,
        message: 'Debug purchases are disabled in release builds.',
      );
    }
    // Simulate store latency so the UI's pending state is exercised.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return PurchaseResult(
      PurchaseStatus.success,
      gems: pack.totalGems,
      message: 'Debug purchase — no payment was taken.',
    );
  }
}
