import 'package:flutter/material.dart';

import '../models/flower.dart';
import 'cartoon_flower.dart';

/// Renders a flower as either:
///   • a botanical PNG image (from `assets/flowers/{flower.id}.png`) ← preferred
///   • the flower emoji as a text fallback                       ← until PNG added
///
/// To upgrade any flower from an emoji to botanical art, add a PNG named
/// `{flower.id}.png` into `assets/flowers/` — no code changes needed.
///
/// Character portraits follow the same pattern via [CharacterImage].
class FlowerImage extends StatelessWidget {
  final Flower flower;

  /// Visual diameter of the flower (width = height = [size]).
  final double size;

  final BoxFit fit;

  const FlowerImage({
    super.key,
    required this.flower,
    required this.size,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: flower.name,
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: CartoonFlowerPainter(flower)),
      ),
    );
  }
}

// ── Character portrait image ──────────────────────────────────────────────────

enum GameCharacter { lily, bud }

extension GameCharacterAsset on GameCharacter {
  /// Asset path for this character's portrait PNG.
  /// Drop the file at `assets/characters/lily.png` or `assets/characters/bud.png`.
  String get imagePath => switch (this) {
    GameCharacter.lily => 'assets/characters/lily.png',
    GameCharacter.bud => 'assets/characters/bud.png',
  };

  String get fallbackEmoji => switch (this) {
    GameCharacter.lily => '👩‍🌾',
    GameCharacter.bud => '👨‍🌾',
  };

  String get displayName => switch (this) {
    GameCharacter.lily => 'Lily',
    GameCharacter.bud => 'Bud',
  };
}

/// Character portrait that shows a PNG or an emoji fallback.
/// Drop `assets/characters/lily.png` / `assets/characters/bud.png` to activate.
class CharacterImage extends StatelessWidget {
  final GameCharacter character;
  final double size;

  const CharacterImage({
    super.key,
    required this.character,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      character.imagePath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            character.fallbackEmoji,
            style: TextStyle(fontSize: size * 0.72),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
