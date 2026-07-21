/// A chapter in the Lily & Bud story arc.
class StoryChapter {
  final int day;
  final String lilyLine;
  final String budLine;

  const StoryChapter({
    required this.day,
    required this.lilyLine,
    required this.budLine,
  });
}

/// Chapters trigger at Day 5, 10, 20, and 30.
const List<StoryChapter> storyChapters = [
  StoryChapter(
    day: 5,
    lilyLine:
        'You know, Bud and I almost didn\'t open this place. We had the keys for three weeks before I could walk through the door.',
    budLine:
        'She\'s being modest. She\'d had the arrangements planned in her head for years. I just carried boxes and tried to keep up.',
  ),
  StoryChapter(
    day: 10,
    lilyLine:
        'My grandmother had a shop just like this in her village. She said flowers remember things that people try to forget.',
    budLine:
        'Lily\'s been talking about her Gran a lot lately. I think she\'d love what you\'ve been building here. I really do.',
  ),
  StoryChapter(
    day: 20,
    lilyLine:
        'There was a week last winter we almost had to close. Bills, a broken cooler, three days without any orders. Bud sold his guitar. We never talked about it.',
    budLine: '[quietly] Still worth it.',
  ),
  StoryChapter(
    day: 30,
    lilyLine:
        'I think this is what Gran meant. Not just selling flowers — knowing whose hands they\'re going to. You\'ve got it. You really do.',
    budLine:
        'I\'m keeping the shop, by the way. Even if you leave someday. I\'ve gotten quite attached to the peonies.',
  ),
];

/// Returns the chapter for the given day, or null if none.
StoryChapter? chapterForDay(int day) {
  try {
    return storyChapters.firstWhere((c) => c.day == day);
  } catch (_) {
    return null;
  }
}

/// Petal & Co. scripted weekly town reputation scores.
/// Used to compare against the player's accumulated [reputationScore].
int petalCoScoreForWeek(int weekNumber) {
  // Ramps up over time — easy to beat week 1, competitive by week 4+
  return switch (weekNumber) {
    1 => 55,
    2 => 130,
    3 => 220,
    4 => 330,
    _ => 330 + (weekNumber - 4) * 90,
  };
}
