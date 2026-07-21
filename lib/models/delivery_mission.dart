import 'flower.dart';

enum DeliveryResult { pending, great, good, poor }

class DeliveryMission {
  final String id;
  final String location;     // "St. Mary's Hospital"
  final String emoji;        // "🏥"
  final String description;  // "A bouquet for a patient recovering from surgery"
  final String hint;         // Customer DM-style message
  final List<VibeTag> requiredVibes;
  final int minFlowers;
  final int maxFlowers;
  final int reward;          // Bonus coins on completion
  final String storySnippet; // Short lore line shown after delivery
  final DeliveryResult result;
  final int? earned;

  const DeliveryMission({
    required this.id,
    required this.location,
    required this.emoji,
    required this.description,
    required this.hint,
    required this.requiredVibes,
    required this.minFlowers,
    required this.maxFlowers,
    required this.reward,
    required this.storySnippet,
    this.result = DeliveryResult.pending,
    this.earned,
  });

  bool get isCompleted => result != DeliveryResult.pending;

  DeliveryMission copyWith({
    DeliveryResult? result,
    int? earned,
  }) =>
      DeliveryMission(
        id: id,
        location: location,
        emoji: emoji,
        description: description,
        hint: hint,
        requiredVibes: requiredVibes,
        minFlowers: minFlowers,
        maxFlowers: maxFlowers,
        reward: reward,
        storySnippet: storySnippet,
        result: result ?? this.result,
        earned: earned ?? this.earned,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'location': location,
        'emoji': emoji,
        'description': description,
        'hint': hint,
        'requiredVibes': requiredVibes.map((v) => v.name).toList(),
        'minFlowers': minFlowers,
        'maxFlowers': maxFlowers,
        'reward': reward,
        'storySnippet': storySnippet,
        'result': result.name,
        'earned': earned,
      };

  factory DeliveryMission.fromJson(Map<String, dynamic> json) =>
      DeliveryMission(
        id: json['id'] as String,
        location: json['location'] as String,
        emoji: json['emoji'] as String,
        description: json['description'] as String,
        hint: json['hint'] as String,
        requiredVibes: (json['requiredVibes'] as List)
            .map((v) => VibeTag.values.firstWhere((t) => t.name == v))
            .toList(),
        minFlowers: (json['minFlowers'] as num).toInt(),
        maxFlowers: (json['maxFlowers'] as num).toInt(),
        reward: (json['reward'] as num).toInt(),
        storySnippet: json['storySnippet'] as String,
        result: DeliveryResult.values.firstWhere(
          (r) => r.name == json['result'],
          orElse: () => DeliveryResult.pending,
        ),
        earned: json['earned'] as int?,
      );
}
