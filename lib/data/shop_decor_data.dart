import 'package:flutter/material.dart';

import '../models/shop_decoration.dart';

// ── Wallpapers ─────────────────────────────────────────────────────────────────

const ShopDecoration wallpaperDefault = ShopDecoration(
  id: 'wall_garden',
  name: 'Garden Green',
  description: 'The classic forest-green walls your shop started with.',
  category: ShopDecorCategory.wallpaper,
  cost: 0,
  isDefault: true,
  gradientColors: [
    Color(0xFF1C5232),
    Color(0xFF2A7048),
    Color(0xFF1F5E3A),
    Color(0xFF163D26),
  ],
);

const ShopDecoration wallpaperLavender = ShopDecoration(
  id: 'wall_lavender',
  name: 'Lavender Fields',
  description: 'Soft purple hues that feel like a walk through a lavender farm.',
  category: ShopDecorCategory.wallpaper,
  cost: 55,
  gradientColors: [
    Color(0xFF3D2A5E),
    Color(0xFF5C4280),
    Color(0xFF4A3368),
    Color(0xFF2E1F4A),
  ],
);

const ShopDecoration wallpaperSunset = ShopDecoration(
  id: 'wall_sunset',
  name: 'Sunset Peach',
  description: 'Warm amber and coral tones, like a golden evening.',
  category: ShopDecorCategory.wallpaper,
  cost: 60,
  gradientColors: [
    Color(0xFF7A3A1E),
    Color(0xFFA05030),
    Color(0xFF8A4424),
    Color(0xFF5C2C14),
  ],
);

const ShopDecoration wallpaperOcean = ShopDecoration(
  id: 'wall_ocean',
  name: 'Ocean Mist',
  description: 'Cool teal and blue tones that bring the seaside indoors.',
  category: ShopDecorCategory.wallpaper,
  cost: 55,
  gradientColors: [
    Color(0xFF1A3D5C),
    Color(0xFF2A5878),
    Color(0xFF1F4A68),
    Color(0xFF12303F),
  ],
);

const ShopDecoration wallpaperRose = ShopDecoration(
  id: 'wall_rose',
  name: 'Rose Petal',
  description: 'Rich dusty-rose tones for a romantic, luxurious feel.',
  category: ShopDecorCategory.wallpaper,
  cost: 70,
  gradientColors: [
    Color(0xFF5C1E35),
    Color(0xFF7A2E4A),
    Color(0xFF682540),
    Color(0xFF3E1225),
  ],
);

// ── Floor tiles ────────────────────────────────────────────────────────────────

const ShopDecoration floorDefault = ShopDecoration(
  id: 'floor_wood',
  name: 'Oak Planks',
  description: 'Warm oak-wood flooring. Timeless.',
  category: ShopDecorCategory.floorTile,
  cost: 0,
  isDefault: true,
  gradientColors: [
    Color(0xFF5C3A1E),
    Color(0xFF7A5030),
    Color(0xFF6A4424),
  ],
);

const ShopDecoration floorTerracotta = ShopDecoration(
  id: 'floor_terra',
  name: 'Terracotta Tiles',
  description: 'Mediterranean-style terracotta, warm and earthy.',
  category: ShopDecorCategory.floorTile,
  cost: 40,
  gradientColors: [
    Color(0xFF8B4A2A),
    Color(0xFFA85C35),
    Color(0xFF9A5030),
  ],
);

const ShopDecoration floorMarble = ShopDecoration(
  id: 'floor_marble',
  name: 'White Marble',
  description: 'Elegant marble flooring that makes flowers pop.',
  category: ShopDecorCategory.floorTile,
  cost: 65,
  gradientColors: [
    Color(0xFF9A9A9A),
    Color(0xFFB8B8B8),
    Color(0xFFA8A8A8),
  ],
);

const ShopDecoration floorSlate = ShopDecoration(
  id: 'floor_slate',
  name: 'Slate Blue',
  description: 'Cool charcoal-blue slate for a modern feel.',
  category: ShopDecorCategory.floorTile,
  cost: 50,
  gradientColors: [
    Color(0xFF2A3A4A),
    Color(0xFF384D60),
    Color(0xFF304050),
  ],
);

// ── Counter styles ─────────────────────────────────────────────────────────────

const ShopDecoration counterDefault = ShopDecoration(
  id: 'counter_oak',
  name: 'Oak Counter',
  description: 'The sturdy oak counter you started with.',
  category: ShopDecorCategory.counter,
  cost: 0,
  isDefault: true,
  accentColor: Color(0xFF5C3A1E),
);

const ShopDecoration counterMarble = ShopDecoration(
  id: 'counter_marble',
  name: 'White Marble',
  description: 'A pristine marble counter — elegance in full bloom.',
  category: ShopDecorCategory.counter,
  cost: 55,
  accentColor: Color(0xFF8A8A8A),
);

const ShopDecoration counterWalnut = ShopDecoration(
  id: 'counter_walnut',
  name: 'Dark Walnut',
  description: 'Rich dark walnut with a luxurious finish.',
  category: ShopDecorCategory.counter,
  cost: 45,
  accentColor: Color(0xFF2A1A0E),
);

const ShopDecoration counterMint = ShopDecoration(
  id: 'counter_mint',
  name: 'Mint Green',
  description: 'A cheerful mint-painted counter, full of life.',
  category: ShopDecorCategory.counter,
  cost: 50,
  accentColor: Color(0xFF2A6644),
);

// ── Window plants ──────────────────────────────────────────────────────────────

const ShopDecoration plantNone = ShopDecoration(
  id: 'plant_none',
  name: 'No Plant',
  description: 'Keep the windowsill bare.',
  category: ShopDecorCategory.windowPlant,
  cost: 0,
  isDefault: true,
  decorEmoji: '',
);

const ShopDecoration plantFern = ShopDecoration(
  id: 'plant_fern',
  name: 'Trailing Fern',
  description: 'A lush fern cascading over the sill.',
  category: ShopDecorCategory.windowPlant,
  cost: 30,
  decorEmoji: '🌿',
);

const ShopDecoration plantCactus = ShopDecoration(
  id: 'plant_cactus',
  name: 'Desert Cactus',
  description: 'Low-maintenance and full of personality.',
  category: ShopDecorCategory.windowPlant,
  cost: 25,
  decorEmoji: '🌵',
);

const ShopDecoration plantBonsai = ShopDecoration(
  id: 'plant_bonsai',
  name: 'Mini Bonsai',
  description: 'A patient bonsai for a Zen corner.',
  category: ShopDecorCategory.windowPlant,
  cost: 45,
  decorEmoji: '🌳',
);

const ShopDecoration plantSunflower = ShopDecoration(
  id: 'plant_sunflower',
  name: 'Pot Sunflower',
  description: 'A cheerful potted sunflower that brightens the room.',
  category: ShopDecorCategory.windowPlant,
  cost: 35,
  decorEmoji: '🌻',
);

// ── Fairy lights ───────────────────────────────────────────────────────────────

const ShopDecoration lightsNone = ShopDecoration(
  id: 'lights_none',
  name: 'No Lights',
  description: 'No string lights — natural light only.',
  category: ShopDecorCategory.fairyLights,
  cost: 0,
  isDefault: true,
  decorEmoji: '',
);

const ShopDecoration lightsWarm = ShopDecoration(
  id: 'lights_warm',
  name: 'Warm White',
  description: 'Soft, warm-white fairy lights for a cosy glow.',
  category: ShopDecorCategory.fairyLights,
  cost: 35,
  decorEmoji: '💡',
);

const ShopDecoration lightsRainbow = ShopDecoration(
  id: 'lights_rainbow',
  name: 'Rainbow Lights',
  description: 'Every colour of the rainbow, dancing overhead.',
  category: ShopDecorCategory.fairyLights,
  cost: 40,
  decorEmoji: '🌈',
);

const ShopDecoration lightsRose = ShopDecoration(
  id: 'lights_rose',
  name: 'Rose Pink',
  description: "Delicate pink bulb lights, perfect for Valentine's.",
  category: ShopDecorCategory.fairyLights,
  cost: 35,
  decorEmoji: '🌸',
);

const ShopDecoration lightsLanterns = ShopDecoration(
  id: 'lights_lanterns',
  name: 'Paper Lanterns',
  description: 'Hanging lanterns casting a warm, festive glow.',
  category: ShopDecorCategory.fairyLights,
  cost: 50,
  decorEmoji: '🏮',
);

// ── Window displays ────────────────────────────────────────────────────────────

const ShopDecoration displayNone = ShopDecoration(
  id: 'display_none',
  name: 'Empty Window',
  description: 'No window display — keep it simple.',
  category: ShopDecorCategory.windowDisplay,
  cost: 0,
  isDefault: true,
  decorEmoji: '',
);

const ShopDecoration displaySpring = ShopDecoration(
  id: 'display_spring',
  name: 'Spring Blooms',
  description: 'A cheerful spring display of tulips and cherry blossoms.',
  category: ShopDecorCategory.windowDisplay,
  cost: 40,
  decorEmoji: '🌸',
);

const ShopDecoration displayHarvest = ShopDecoration(
  id: 'display_harvest',
  name: 'Harvest Charm',
  description: 'Wheat sheaves and autumn leaves for a cosy harvest look.',
  category: ShopDecorCategory.windowDisplay,
  cost: 40,
  decorEmoji: '🍂',
);

const ShopDecoration displayWinter = ShopDecoration(
  id: 'display_winter',
  name: 'Winter Scene',
  description: 'Frosted glass and a tiny snowflake wreath.',
  category: ShopDecorCategory.windowDisplay,
  cost: 45,
  decorEmoji: '❄️',
);

const ShopDecoration displayRainbow = ShopDecoration(
  id: 'display_rainbow',
  name: 'Rainbow Pride',
  description: 'Bright rainbow bunting to welcome everyone.',
  category: ShopDecorCategory.windowDisplay,
  cost: 35,
  decorEmoji: '🌈',
);

// ── Catalog ────────────────────────────────────────────────────────────────────

const List<ShopDecoration> allDecorations = [
  // Wallpapers
  wallpaperDefault,
  wallpaperLavender,
  wallpaperSunset,
  wallpaperOcean,
  wallpaperRose,
  // Floor
  floorDefault,
  floorTerracotta,
  floorMarble,
  floorSlate,
  // Counter
  counterDefault,
  counterMarble,
  counterWalnut,
  counterMint,
  // Window plants
  plantNone,
  plantFern,
  plantCactus,
  plantBonsai,
  plantSunflower,
  // Fairy lights
  lightsNone,
  lightsWarm,
  lightsRainbow,
  lightsRose,
  lightsLanterns,
  // Window displays
  displayNone,
  displaySpring,
  displayHarvest,
  displayWinter,
  displayRainbow,
];

final Map<String, ShopDecoration> decorById = {
  for (final d in allDecorations) d.id: d,
};

/// Returns all decorations in a given category, sorted with default first.
List<ShopDecoration> decorForCategory(ShopDecorCategory cat) =>
    allDecorations.where((d) => d.category == cat).toList()
      ..sort((a, b) => a.isDefault ? -1 : (b.isDefault ? 1 : a.cost.compareTo(b.cost)));

/// Default active decoration IDs, one per category.
const Map<String, String> defaultActiveDecor = {
  'wallpaper': 'wall_garden',
  'floorTile': 'floor_wood',
  'counter': 'counter_oak',
  'windowPlant': 'plant_none',
  'fairyLights': 'lights_none',
  'windowDisplay': 'display_none',
};
