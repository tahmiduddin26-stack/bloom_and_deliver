enum CustomerMood { happy, neutral, anxious, sad, excited }

extension CustomerMoodEmoji on CustomerMood {
  String get emoji => switch (this) {
        CustomerMood.happy => '😊',
        CustomerMood.neutral => '😐',
        CustomerMood.anxious => '😟',
        CustomerMood.sad => '😢',
        CustomerMood.excited => '🤩',
      };
}

class CustomerProfile {
  final String id;
  final String name;
  final String portrait;
  final CustomerMood mood;
  final bool isRegular;
  final double loyaltyMultiplier;

  /// Backstory snippets revealed at friendship levels 1, 3, and 5.
  /// Regulars have 3 snippets; casual customers have 0–1.
  final List<String> backstorySnippets;

  /// Optional line shown as a second chat bubble after Day 8,
  /// referencing the rival shop "Petal & Co."
  final String? rivalMention;

  /// Shown in the phone as the life-event order hint when friendship hits 5.
  /// Only regulars have this.
  final String? lifeEventHint;

  const CustomerProfile({
    required this.id,
    required this.name,
    required this.portrait,
    required this.mood,
    this.isRegular = false,
    this.loyaltyMultiplier = 1.0,
    this.backstorySnippets = const [],
    this.rivalMention,
    this.lifeEventHint,
  });

  /// Returns the backstory snippet index for a given friendship level,
  /// or null if none exists.
  String? snippetForLevel(int level) {
    final idx = level == 1
        ? 0
        : level == 3
            ? 1
            : level == 5
                ? 2
                : null;
    if (idx == null || idx >= backstorySnippets.length) return null;
    return backstorySnippets[idx];
  }

  /// Highest friendship level this customer can reach.
  int get maxFriendship => isRegular ? 5 : 2;
}
