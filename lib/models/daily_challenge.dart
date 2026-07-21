enum ChallengeType {
  serveCount,   // Serve X customers today
  qualityGreat, // Get X Perfect ratings
  vibeCount,    // Make X bouquets matching a specific vibe
  flowerUse,    // Use X of a specific flower
  earnMoney,    // Earn X coins today
}

class DailyChallenge {
  final String id;
  final String description;
  final ChallengeType type;
  final int target;

  /// Bonus coins awarded on completion.
  final int reward;

  final int progress;
  final bool completed;

  /// For vibeCount: the VibeTag name.  For flowerUse: the flower id.
  final String? filter;

  const DailyChallenge({
    required this.id,
    required this.description,
    required this.type,
    required this.target,
    required this.reward,
    this.progress = 0,
    this.completed = false,
    this.filter,
  });

  DailyChallenge copyWith({int? progress, bool? completed}) => DailyChallenge(
        id: id,
        description: description,
        type: type,
        target: target,
        reward: reward,
        progress: progress ?? this.progress,
        completed: completed ?? this.completed,
        filter: filter,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'type': type.name,
        'target': target,
        'reward': reward,
        'progress': progress,
        'completed': completed,
        'filter': filter,
      };

  static DailyChallenge fromJson(Map<String, dynamic> j) => DailyChallenge(
        id: j['id'] as String,
        description: j['description'] as String,
        type: ChallengeType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => ChallengeType.serveCount,
        ),
        target: j['target'] as int,
        reward: j['reward'] as int,
        progress: j['progress'] as int? ?? 0,
        completed: j['completed'] as bool? ?? false,
        filter: j['filter'] as String?,
      );
}
