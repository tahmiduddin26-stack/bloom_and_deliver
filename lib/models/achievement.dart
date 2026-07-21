enum AchievementId {
  firstBouquet,
  firstGreat,
  day5,
  day10,
  earn500,
  earn2000,
  greatStreak3,
  serve50,
  serve100,
  allVibes,
  firstUpgrade,
  perfectDay,
  firstChallenge,
  rankMaster,
  rankLegend,
}

class Achievement {
  final AchievementId id;
  final String title;
  final String description;
  final String emoji;

  /// Progress-based achievements show a progress bar up to [target].
  /// Binary achievements (null target) are either locked or unlocked.
  final int? target;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    this.target,
  });
}
