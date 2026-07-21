import 'package:flutter/material.dart';

/// Categories of shop decoration the player can customise.
enum ShopDecorCategory {
  wallpaper,
  floorTile,
  counter,
  windowPlant,
  fairyLights,
  windowDisplay;

  String get label => switch (this) {
        ShopDecorCategory.wallpaper => 'Wallpaper',
        ShopDecorCategory.floorTile => 'Floor',
        ShopDecorCategory.counter => 'Counter',
        ShopDecorCategory.windowPlant => 'Plants',
        ShopDecorCategory.fairyLights => 'Lights',
        ShopDecorCategory.windowDisplay => 'Window',
      };

  String get emoji => switch (this) {
        ShopDecorCategory.wallpaper => '🖼️',
        ShopDecorCategory.floorTile => '🏠',
        ShopDecorCategory.counter => '🏪',
        ShopDecorCategory.windowPlant => '🪴',
        ShopDecorCategory.fairyLights => '✨',
        ShopDecorCategory.windowDisplay => '🪟',
      };
}

/// A single decorative item the player can buy and equip.
class ShopDecoration {
  final String id;
  final String name;
  final String description;
  final ShopDecorCategory category;

  /// Cost in coins. 0 = default (always owned/equipped at start).
  final int cost;

  /// If true this item is always owned and cannot be removed.
  final bool isDefault;

  // ── Visual payload — only the relevant field is non-null ─────────────────

  /// Used by [wallpaper] and [floorTile]: gradient stop colours for the
  /// background / floor panel.
  final List<Color>? gradientColors;

  /// Used by [windowPlant], [fairyLights], and [windowDisplay]: the emoji
  /// that gets shown in the corresponding overlay.
  final String? decorEmoji;

  /// Used by [counter]: the tint colour applied to the counter/workspace band.
  final Color? accentColor;

  const ShopDecoration({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.cost,
    this.isDefault = false,
    this.gradientColors,
    this.decorEmoji,
    this.accentColor,
  });
}
