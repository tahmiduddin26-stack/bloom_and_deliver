import 'customer_profile.dart';
import 'flower.dart';

enum OrderResult { pending, great, good, poor }

class BouquetOrder {
  final String id;
  final CustomerProfile customer;
  final String description;
  final String hint;
  final List<VibeTag> requiredVibes;
  final int minFlowers;
  final int maxFlowers;
  final int basePayment;
  final OrderResult result;

  /// If true this is a mystery order — no vibe hints shown, scored by creativity.
  final bool isMystery;

  /// If true, the customer would appreciate greens or filler in the bouquet.
  /// A 10% bonus is applied (vs the standard 5%) when fillers are included.
  final bool prefersGreens;

  const BouquetOrder({
    required this.id,
    required this.customer,
    required this.description,
    required this.hint,
    required this.requiredVibes,
    this.minFlowers = 3,
    this.maxFlowers = 8,
    required this.basePayment,
    this.result = OrderResult.pending,
    this.isMystery = false,
    this.prefersGreens = false,
  });

  BouquetOrder copyWith({
    String? id,
    CustomerProfile? customer,
    String? description,
    String? hint,
    List<VibeTag>? requiredVibes,
    int? minFlowers,
    int? maxFlowers,
    int? basePayment,
    OrderResult? result,
    bool? isMystery,
    bool? prefersGreens,
  }) =>
      BouquetOrder(
        id: id ?? this.id,
        customer: customer ?? this.customer,
        description: description ?? this.description,
        hint: hint ?? this.hint,
        requiredVibes: requiredVibes ?? this.requiredVibes,
        minFlowers: minFlowers ?? this.minFlowers,
        maxFlowers: maxFlowers ?? this.maxFlowers,
        basePayment: basePayment ?? this.basePayment,
        result: result ?? this.result,
        isMystery: isMystery ?? this.isMystery,
        prefersGreens: prefersGreens ?? this.prefersGreens,
      );

  /// Score a submitted bouquet by comparing its vibes against required vibes.
  /// Applies [loyaltyMultiplier] from the customer profile.
  /// Returns (result, payment earned).
  (OrderResult, int) score(List<Flower> bouquet) {
    if (bouquet.length < minFlowers) return (OrderResult.poor, 0);

    if (isMystery) return _scoreMystery(bouquet);

    final bouquetVibes = bouquet.expand((f) => f.vibes).toSet();
    final matched = requiredVibes.where(bouquetVibes.contains).length;
    final ratio = matched / requiredVibes.length;

    final loyalty = customer.loyaltyMultiplier;

    if (ratio >= 0.8) {
      return (OrderResult.great, (basePayment * 1.3 * loyalty).round());
    }
    if (ratio >= 0.5) {
      return (OrderResult.good, (basePayment * loyalty).round());
    }
    // Poor result: loyalty multiplier does NOT apply — disappointed customers don't tip
    return (OrderResult.poor, (basePayment * 0.4).round());
  }

  /// Mystery orders are scored on *creativity* — how many distinct flower species
  /// the player used. More variety = better result. Pay is 2.5× base for great.
  (OrderResult, int) _scoreMystery(List<Flower> bouquet) {
    final uniqueTypes = bouquet.map((f) => f.id).toSet().length;
    if (uniqueTypes >= 4) {
      return (OrderResult.great, (basePayment * 2.5).round());
    }
    if (uniqueTypes == 3) {
      return (OrderResult.good, (basePayment * 1.8).round());
    }
    return (OrderResult.poor, (basePayment * 0.5).round());
  }
}
