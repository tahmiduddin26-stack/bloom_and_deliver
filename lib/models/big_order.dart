import 'flower.dart';

/// Result of a single day's bouquet contribution to a big order.
enum ContributionResult { pending, great, good, poor }

/// One day's work toward a multi-day big order.
class DayContribution {
  /// Which flowers were submitted (may be empty while pending).
  final List<String> flowerIds;
  final ContributionResult result;
  final int earned;

  /// Campaign day when this bouquet was handed in.
  final int? gameDay;

  const DayContribution({
    this.flowerIds = const [],
    this.result = ContributionResult.pending,
    this.earned = 0,
    this.gameDay,
  });

  bool get isSubmitted => result != ContributionResult.pending;

  DayContribution copyWith({
    List<String>? flowerIds,
    ContributionResult? result,
    int? earned,
    int? gameDay,
  }) => DayContribution(
    flowerIds: flowerIds ?? this.flowerIds,
    result: result ?? this.result,
    earned: earned ?? this.earned,
    gameDay: gameDay ?? this.gameDay,
  );

  Map<String, dynamic> toJson() => {
    'flowerIds': flowerIds,
    'result': result.name,
    'earned': earned,
    'gameDay': gameDay,
  };

  factory DayContribution.fromJson(Map<String, dynamic> j) => DayContribution(
    flowerIds: List<String>.from(j['flowerIds'] as List? ?? []),
    result: ContributionResult.values.firstWhere(
      (r) => r.name == j['result'],
      orElse: () => ContributionResult.pending,
    ),
    earned: (j['earned'] as num?)?.toInt() ?? 0,
    gameDay: (j['gameDay'] as num?)?.toInt(),
  );
}

/// A 3-day multi-bouquet commission (wedding, gala, festival, etc.).
class BigOrder {
  final String id;
  final String name;
  final String emoji;

  /// One-line pitch shown on the commission card.
  final String description;

  /// Short flavour text revealed each day (exactly 3 entries).
  final List<String> dayStories;

  /// Vibes the customer cares about — used to score each bouquet.
  final List<VibeTag> requiredVibes;

  /// Minimum flowers per day bouquet.
  final int minFlowers;

  /// Maximum flowers per day bouquet.
  final int maxFlowers;

  /// Payout per day if completed with a "good" result or better.
  final int dailyReward;

  /// Bonus on top of daily rewards when all 3 days are submitted.
  final int completionBonus;

  /// Game day this commission becomes available.
  final int availableFromDay;

  /// Day this particular commission window started (may be later than unlock).
  final int? startDay;

  // ── Mutable progress ──────────────────────────────────────────────────────
  /// Contributions indexed 0–2 (one per required day).
  final List<DayContribution> contributions;

  const BigOrder({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.dayStories,
    required this.requiredVibes,
    required this.availableFromDay,
    this.startDay,
    this.minFlowers = 4,
    this.maxFlowers = 8,
    this.dailyReward = 30,
    this.completionBonus = 40,
    this.contributions = const [
      DayContribution(),
      DayContribution(),
      DayContribution(),
    ],
  });

  // ── Derived helpers ───────────────────────────────────────────────────────

  /// How many days have been submitted so far.
  int get daysSubmitted => contributions.where((c) => c.isSubmitted).length;

  bool get isComplete => daysSubmitted >= 3;

  int get commissionDay => startDay ?? availableFromDay;
  int get deadlineDay => commissionDay + 2;

  bool canContributeOn(int day) {
    if (isComplete || day < commissionDay || day > deadlineDay) {
      return false;
    }
    final previous = daysSubmitted == 0
        ? null
        : contributions[daysSubmitted - 1].gameDay;
    return previous == null || day > previous;
  }

  /// Next 0-based contribution index that still needs submitting, or null.
  int? get nextDayIndex {
    for (int i = 0; i < contributions.length; i++) {
      if (!contributions[i].isSubmitted) return i;
    }
    return null;
  }

  /// Total earnings accumulated so far.
  int get totalEarned =>
      contributions.fold(0, (sum, c) => sum + c.earned) +
      (isComplete ? completionBonus : 0);

  BigOrder copyWith({List<DayContribution>? contributions, int? startDay}) =>
      BigOrder(
        id: id,
        name: name,
        emoji: emoji,
        description: description,
        dayStories: dayStories,
        requiredVibes: requiredVibes,
        availableFromDay: availableFromDay,
        startDay: startDay ?? this.startDay,
        minFlowers: minFlowers,
        maxFlowers: maxFlowers,
        dailyReward: dailyReward,
        completionBonus: completionBonus,
        contributions: contributions ?? this.contributions,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'startDay': commissionDay,
    'contributions': contributions.map((c) => c.toJson()).toList(),
  };

  /// Reconstruct from persisted JSON + the static pool entry for metadata.
  factory BigOrder.fromJson(Map<String, dynamic> j, BigOrder template) =>
      template.copyWith(
        startDay: (j['startDay'] as num?)?.toInt() ?? template.availableFromDay,
        contributions: List.generate(3, (index) {
          final saved = j['contributions'] as List?;
          if (saved == null || index >= saved.length) {
            return const DayContribution();
          }
          final contribution = DayContribution.fromJson(
            saved[index] as Map<String, dynamic>,
          );
          // Older saves did not record the day. Preserve progress while
          // assigning each existing hand-in its earliest valid campaign day.
          return contribution.isSubmitted && contribution.gameDay == null
              ? contribution.copyWith(
                  gameDay:
                      ((j['startDay'] as num?)?.toInt() ??
                          template.availableFromDay) +
                      index,
                )
              : contribution;
        }),
      );
}
