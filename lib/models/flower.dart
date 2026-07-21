import 'package:flutter/material.dart';

enum VibeTag {
  // original
  romantic,
  cheerful,
  sympathy,
  elegant,
  wild,
  fresh,
  cozy,
  vibrant,
  mystical,
  delicate,
  // new
  luxurious,
  bold,
  exotic,
  festive,
  natural,
  traditional,
  soft,
  rustic,
}

extension VibeTagLabel on VibeTag {
  String get label => switch (this) {
        VibeTag.romantic => 'Romantic',
        VibeTag.cheerful => 'Cheerful',
        VibeTag.sympathy => 'Sympathy',
        VibeTag.elegant => 'Elegant',
        VibeTag.wild => 'Wild',
        VibeTag.fresh => 'Fresh',
        VibeTag.cozy => 'Cozy',
        VibeTag.vibrant => 'Vibrant',
        VibeTag.mystical => 'Mystical',
        VibeTag.delicate => 'Delicate',
        VibeTag.luxurious => 'Luxurious',
        VibeTag.bold => 'Bold',
        VibeTag.exotic => 'Exotic',
        VibeTag.festive => 'Festive',
        VibeTag.natural => 'Natural',
        VibeTag.traditional => 'Traditional',
        VibeTag.soft => 'Soft',
        VibeTag.rustic => 'Rustic',
      };

  Color get color => switch (this) {
        VibeTag.romantic => const Color(0xFFE8576A),
        VibeTag.cheerful => const Color(0xFFF5CE5A),
        VibeTag.sympathy => const Color(0xFFB0BEC5),
        VibeTag.elegant => const Color(0xFF9B5E8A),
        VibeTag.wild => const Color(0xFF7A9E7E),
        VibeTag.fresh => const Color(0xFF7EB8D4),
        VibeTag.cozy => const Color(0xFFE8A87C),
        VibeTag.vibrant => const Color(0xFFFFB830),
        VibeTag.mystical => const Color(0xFF6A5ACD),
        VibeTag.delicate => const Color(0xFFD4A0C0),
        VibeTag.luxurious => const Color(0xFFD4AF37),
        VibeTag.bold => const Color(0xFFE74C3C),
        VibeTag.exotic => const Color(0xFF16A085),
        VibeTag.festive => const Color(0xFFE67E22),
        VibeTag.natural => const Color(0xFF27AE60),
        VibeTag.traditional => const Color(0xFF8E44AD),
        VibeTag.soft => const Color(0xFFF4A7C0),
        VibeTag.rustic => const Color(0xFF8D6E63),
      };
}

class Flower {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final List<VibeTag> vibes;
  final int cost;
  final int wiltsAfterDays;
  /// Day number on which this flower becomes available in the shop.
  final int unlockDay;
  /// Price of a seed packet at the market. null = not growable.
  final int? seedPrice;
  /// How many real-time minutes to grow from seed to bloom.
  final int? growthMinutes;
  /// If non-null, this flower is exclusive to the named seasonal event
  /// and only appears in the market when that event is active.
  final String? eventId;

  /// True for structural greens and fillers (eucalyptus, fern, baby's breath,
  /// statice). Fillers are visually distinguished in the inventory and give a
  /// small scoring bonus when included in a bouquet.
  final bool isFiller;

  const Flower({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.vibes,
    required this.cost,
    this.wiltsAfterDays = 3,
    this.unlockDay = 1,
    this.seedPrice,
    this.growthMinutes,
    this.eventId,
    this.isFiller = false,
  });

  bool get isGrowable => seedPrice != null && growthMinutes != null;

  /// True for structural greens — same as [isFiller] but named for readability.
  bool get isGreens => isFiller;

  /// Asset path for the 3D flower image.
  /// Drop a PNG named `{id}.png` into `assets/flowers/` and it will
  /// automatically replace the emoji placeholder everywhere in the app.
  String get imagePath => 'assets/flowers/$id.png';

  /// True when this flower belongs to a seasonal event.
  bool get isEventExclusive => eventId != null;

  Flower copyWith({
    String? id,
    String? name,
    String? emoji,
    Color? color,
    List<VibeTag>? vibes,
    int? cost,
    int? wiltsAfterDays,
    int? unlockDay,
    int? seedPrice,
    int? growthMinutes,
    String? eventId,
    bool? isFiller,
  }) =>
      Flower(
        id: id ?? this.id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        color: color ?? this.color,
        vibes: vibes ?? this.vibes,
        cost: cost ?? this.cost,
        wiltsAfterDays: wiltsAfterDays ?? this.wiltsAfterDays,
        unlockDay: unlockDay ?? this.unlockDay,
        seedPrice: seedPrice ?? this.seedPrice,
        growthMinutes: growthMinutes ?? this.growthMinutes,
        eventId: eventId ?? this.eventId,
        isFiller: isFiller ?? this.isFiller,
      );
}
