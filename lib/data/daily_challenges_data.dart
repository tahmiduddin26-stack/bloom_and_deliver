import '../models/daily_challenge.dart';

// ── Challenge template ────────────────────────────────────────────────────────

class _T {
  final ChallengeType type;
  final String desc;
  final int target;
  final int reward;
  final String? filter;

  const _T(this.type, this.desc, this.target, this.reward, {this.filter});

  DailyChallenge build(int index) => DailyChallenge(
        id: 'challenge_$index',
        description: desc,
        type: type,
        target: target,
        reward: reward,
        filter: filter,
      );
}

// ── Pool of challenge templates ───────────────────────────────────────────────

const _pool = [
  // Serve count
  _T(ChallengeType.serveCount, 'Serve 3 customers today', 3, 20),
  _T(ChallengeType.serveCount, 'Serve 4 customers today', 4, 30),
  _T(ChallengeType.serveCount, 'Serve 5 customers today', 5, 45),

  // Perfect ratings
  _T(ChallengeType.qualityGreat, 'Get 2 Perfect ratings', 2, 25),
  _T(ChallengeType.qualityGreat, 'Get 3 Perfect ratings', 3, 40),

  // Earn money
  _T(ChallengeType.earnMoney, 'Earn \$80 today', 80, 15),
  _T(ChallengeType.earnMoney, 'Earn \$120 today', 120, 25),
  _T(ChallengeType.earnMoney, 'Earn \$160 today', 160, 35),

  // Vibe challenges
  _T(ChallengeType.vibeCount, 'Make 2 Romantic bouquets', 2, 20,
      filter: 'romantic'),
  _T(ChallengeType.vibeCount, 'Make 2 Cheerful bouquets', 2, 20,
      filter: 'cheerful'),
  _T(ChallengeType.vibeCount, 'Make 2 Elegant bouquets', 2, 20,
      filter: 'elegant'),
  _T(ChallengeType.vibeCount, 'Make 2 Fresh bouquets', 2, 20, filter: 'fresh'),
  _T(ChallengeType.vibeCount, 'Make 2 Cozy bouquets', 2, 20, filter: 'cozy'),
  _T(ChallengeType.vibeCount, 'Make 1 Mystical bouquet', 1, 15,
      filter: 'mystical'),
  _T(ChallengeType.vibeCount, 'Make 2 Vibrant bouquets', 2, 20,
      filter: 'vibrant'),

  // Flower use
  _T(ChallengeType.flowerUse, 'Use 4 Roses today', 4, 15, filter: 'rose'),
  _T(ChallengeType.flowerUse, 'Use 4 Tulips today', 4, 15, filter: 'tulip'),
  _T(ChallengeType.flowerUse, 'Use 5 Daisies today', 5, 15, filter: 'daisy'),
  _T(ChallengeType.flowerUse, 'Use 3 Sunflowers today', 3, 20,
      filter: 'sunflower'),
  _T(ChallengeType.flowerUse, 'Use 3 Lavender today', 3, 20,
      filter: 'lavender'),
  _T(ChallengeType.flowerUse, 'Use 3 Peonies today', 3, 20, filter: 'peony'),
];

// ── Generator ─────────────────────────────────────────────────────────────────

/// Returns 3 distinct challenges seeded by [gameDay].
/// Uses prime multipliers to spread picks across the pool.
List<DailyChallenge> generateDailyChallenges(int gameDay) {
  final n = _pool.length;
  final picked = <int>{};
  final primes = [3, 7, 13, 17, 23, 29];

  for (var p = 0; picked.length < 3 && p < primes.length * 3; p++) {
    final idx = ((gameDay * primes[p % primes.length]) + p * 11) % n;
    picked.add(idx);
  }

  // Fallback: add sequential indices if we somehow didn't get 3
  for (var i = 0; picked.length < 3; i++) {
    picked.add(i % n);
  }

  return picked.take(3).map((idx) => _pool[idx].build(idx)).toList();
}
