enum FloristRank { apprentice, florist, seniorFlorist, masterFlorist, bloomLegend }

extension FloristRankInfo on FloristRank {
  String get title => switch (this) {
        FloristRank.apprentice => 'Apprentice',
        FloristRank.florist => 'Florist',
        FloristRank.seniorFlorist => 'Senior Florist',
        FloristRank.masterFlorist => 'Master Florist',
        FloristRank.bloomLegend => 'Bloom Legend',
      };

  String get emoji => switch (this) {
        FloristRank.apprentice => '🌱',
        FloristRank.florist => '🌷',
        FloristRank.seniorFlorist => '💐',
        FloristRank.masterFlorist => '🌺',
        FloristRank.bloomLegend => '👑',
      };

  /// XP needed to reach this rank (cumulative from 0).
  int get xpThreshold => switch (this) {
        FloristRank.apprentice => 0,
        FloristRank.florist => 100,
        FloristRank.seniorFlorist => 300,
        FloristRank.masterFlorist => 600,
        FloristRank.bloomLegend => 1000,
      };

  /// XP needed to advance from this rank to the next.
  int get xpToNext => switch (this) {
        FloristRank.apprentice => 100,
        FloristRank.florist => 200,
        FloristRank.seniorFlorist => 300,
        FloristRank.masterFlorist => 400,
        FloristRank.bloomLegend => 0,
      };

  FloristRank? get next => switch (this) {
        FloristRank.apprentice => FloristRank.florist,
        FloristRank.florist => FloristRank.seniorFlorist,
        FloristRank.seniorFlorist => FloristRank.masterFlorist,
        FloristRank.masterFlorist => FloristRank.bloomLegend,
        FloristRank.bloomLegend => null,
      };

  bool get isMax => this == FloristRank.bloomLegend;

  /// XP progress within the current rank band (0..xpToNext).
  int xpInBand(int totalXp) => totalXp - xpThreshold;

  static FloristRank fromXp(int xp) {
    if (xp >= 1000) return FloristRank.bloomLegend;
    if (xp >= 600) return FloristRank.masterFlorist;
    if (xp >= 300) return FloristRank.seniorFlorist;
    if (xp >= 100) return FloristRank.florist;
    return FloristRank.apprentice;
  }
}
