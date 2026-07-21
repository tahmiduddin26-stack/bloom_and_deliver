import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/feature_flags.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

// ── Town map screen ───────────────────────────────────────────────────────────
//
// The town map is the game's world-navigation hub. It has two kinds of
// location:
//
//  • Hub locations  — always-accessible shops/facilities the player can visit.
//    These have warm golden pins and a "Visit →" button in their info card.
//    Navigation is handled via optional callbacks passed in by game_screen.
//
//  • Delivery zones — drop-off points that unlock as the player completes more
//    orders. Info-only; no navigation action.
//
// Open via [openTownMapScreen]. Pass navigation callbacks for hubs you want
// to be visitable. Any callback left null renders that hub as "coming soon".

void openTownMapScreen(
  BuildContext context, {
  VoidCallback? onGoToShop,
  VoidCallback? onGoToMarket,
  VoidCallback? onGoToWholesale,
}) {
  if (!Features.townMap) return;
  Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => TownMapScreen(
        onGoToShop: onGoToShop,
        onGoToMarket: onGoToMarket,
        onGoToWholesale: onGoToWholesale,
      ),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  );
}

// ── Location model ────────────────────────────────────────────────────────────

enum _LocationKind { hub, deliveryZone }

class _MapLocation {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final _LocationKind kind;

  // Hub: unlocks on this game day (0 = always).
  // Delivery zone: unlocks after this many total orders served.
  final int unlockThreshold;

  // Normalised map position, Alignment coords (−1..1 each axis).
  final Alignment position;

  const _MapLocation({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.kind,
    required this.unlockThreshold,
    required this.position,
  });

  bool get isHub => kind == _LocationKind.hub;
}

// ─── All locations ────────────────────────────────────────────────────────────

const _locations = <_MapLocation>[
  // ── Hub locations (navigable) ────────────────────────────────────────────
  _MapLocation(
    id: 'your_shop',
    name: 'Your Flower Shop',
    emoji: '🌷',
    description: 'Home sweet home. Your bouquet studio, your shelves, your story.',
    kind: _LocationKind.hub,
    unlockThreshold: 0,
    position: Alignment(0.00, 0.10), // centre of the map
  ),
  _MapLocation(
    id: 'market',
    name: 'Bloomfield Market',
    emoji: '🌸',
    description:
        'Fresh flowers arrive every morning. Restock here at the end of each day.',
    kind: _LocationKind.hub,
    unlockThreshold: 0,
    position: Alignment(-0.30, -0.68), // upper-left
  ),
  _MapLocation(
    id: 'wholesale',
    name: 'Petal Wholesale Depot',
    emoji: '🛒',
    description:
        'Bulk stock at lower prices. Opens after your first few days in business.',
    kind: _LocationKind.hub,
    unlockThreshold: 3, // unlocks on Day 3
    position: Alignment(0.62, -0.62), // upper-right
  ),

  // ── Delivery zones (info only) ────────────────────────────────────────────
  _MapLocation(
    id: 'hospital',
    name: 'General Hospital',
    emoji: '🏥',
    description:
        'Bright flowers cheer up patients and visiting families.',
    kind: _LocationKind.deliveryZone,
    unlockThreshold: 0, // always open
    position: Alignment(-0.68, -0.35),
  ),
  _MapLocation(
    id: 'wedding_venue',
    name: 'The Grand Venue',
    emoji: '💒',
    description:
        'Elegant arrangements for the most special of days.',
    kind: _LocationKind.deliveryZone,
    unlockThreshold: 3,
    position: Alignment(0.65, -0.22),
  ),
  _MapLocation(
    id: 'school',
    name: 'Elmwood School',
    emoji: '🏫',
    description:
        'Teachers and graduates love a colourful bouquet.',
    kind: _LocationKind.deliveryZone,
    unlockThreshold: 6,
    position: Alignment(-0.68, 0.18),
  ),
  _MapLocation(
    id: 'cafe',
    name: 'The Petal Café',
    emoji: '☕',
    description:
        'A cosy spot that displays fresh flowers every morning.',
    kind: _LocationKind.deliveryZone,
    unlockThreshold: 10,
    position: Alignment(0.65, 0.18),
  ),
  _MapLocation(
    id: 'gallery',
    name: 'Atelier Art Gallery',
    emoji: '🖼️',
    description:
        'Avant-garde arrangements to complement the exhibitions.',
    kind: _LocationKind.deliveryZone,
    unlockThreshold: 15,
    position: Alignment(-0.30, 0.62),
  ),
  _MapLocation(
    id: 'community_hall',
    name: 'Community Hall',
    emoji: '🏛️',
    description:
        'Seasonal displays for every town event and ceremony.',
    kind: _LocationKind.deliveryZone,
    unlockThreshold: 20,
    position: Alignment(0.20, 0.65),
  ),
  _MapLocation(
    id: 'library',
    name: 'Town Library',
    emoji: '📚',
    description:
        'Dried and pressed flowers adorn every reading nook.',
    kind: _LocationKind.deliveryZone,
    unlockThreshold: 30,
    position: Alignment(0.65, 0.62),
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class TownMapScreen extends ConsumerStatefulWidget {
  final VoidCallback? onGoToShop;
  final VoidCallback? onGoToMarket;
  final VoidCallback? onGoToWholesale;

  const TownMapScreen({
    super.key,
    this.onGoToShop,
    this.onGoToMarket,
    this.onGoToWholesale,
  });

  @override
  ConsumerState<TownMapScreen> createState() => _TownMapScreenState();
}

class _TownMapScreenState extends ConsumerState<TownMapScreen>
    with SingleTickerProviderStateMixin {
  _MapLocation? _selected;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.93, end: 1.07).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // Resolve the navigation callback for a given hub id.
  VoidCallback? _navCallback(String id) => switch (id) {
        'market' => widget.onGoToMarket,
        'wholesale' => widget.onGoToWholesale,
        // If a shop callback is provided, use it; otherwise fall back to just
        // popping the map (still works fine if opened outside of game_screen).
        'your_shop' => widget.onGoToShop ?? () => Navigator.of(context).pop(),
        _ => null,
      };

  void _handleVisit(_MapLocation loc) {
    HapticFeedback.mediumImpact();
    final cb = _navCallback(loc.id);
    if (cb == null) return;
    Navigator.of(context).pop();
    cb();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final day = state.day;
    final ordersServed = state.totalOrdersServed;

    bool isUnlocked(_MapLocation loc) => loc.isHub
        ? day >= loc.unlockThreshold
        : ordersServed >= loc.unlockThreshold;

    return Scaffold(
      backgroundColor: const Color(0xFF152A1E),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            _MapHeader(
              day: day,
              ordersServed: ordersServed,
              onBack: () => Navigator.pop(context),
            ),

            // ── Map canvas ─────────────────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  // Parchment background with roads
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: _MapCanvas(
                        locations: _locations,
                        isUnlocked: isUnlocked,
                        selected: _selected,
                        pulse: _pulse,
                        onTap: (loc) {
                          HapticFeedback.selectionClick();
                          setState(() =>
                              _selected = _selected?.id == loc.id ? null : loc);
                        },
                      ),
                    ),
                  ),

                  // ── Info / action card ─────────────────────────────────
                  if (_selected != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: _InfoCard(
                        location: _selected!,
                        isUnlocked: isUnlocked(_selected!),
                        day: day,
                        ordersServed: ordersServed,
                        navCallback: _navCallback(_selected!.id),
                        onVisit: () => _handleVisit(_selected!),
                        onDismiss: () => setState(() => _selected = null),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _MapHeader extends StatelessWidget {
  final int day;
  final int ordersServed;
  final VoidCallback onBack;

  const _MapHeader({
    required this.day,
    required this.ordersServed,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0E1F15),
            const Color(0xFF1B3A2A).withValues(alpha: 0.95),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white70, size: 20),
          ),
          const Text('🗺️', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Town of Bloomfield',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Tap a location to explore',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          // Stat chips
          _HeaderChip(emoji: '☀️', label: 'Day $day'),
          const SizedBox(width: 6),
          _HeaderChip(emoji: '🚚', label: '$ordersServed orders'),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String emoji;
  final String label;

  const _HeaderChip({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.gardenGreenMid.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.gardenGreenMid.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
}

// ── Map canvas ────────────────────────────────────────────────────────────────

class _MapCanvas extends StatelessWidget {
  final List<_MapLocation> locations;
  final bool Function(_MapLocation) isUnlocked;
  final _MapLocation? selected;
  final Animation<double> pulse;
  final void Function(_MapLocation) onTap;

  const _MapCanvas({
    required this.locations,
    required this.isUnlocked,
    required this.selected,
    required this.pulse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Hand-drawn parchment effect
        gradient: const RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [Color(0xFF1E3A28), Color(0xFF122018), Color(0xFF0C1812)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              // Road network
              Positioned.fill(
                child: CustomPaint(
                  painter: _RoadPainter(),
                ),
              ),
              // Compass rose (top-right)
              const Positioned(
                right: 14,
                top: 14,
                child: _CompassRose(),
              ),
              // "Town of Bloomfield" watermark
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: Center(
                  child: Text(
                    'BLOOMFIELD',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.06),
                      letterSpacing: 6,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Location pins
              for (final loc in locations)
                _LocationPin(
                  location: loc,
                  mapSize: constraints.biggest,
                  isUnlocked: isUnlocked(loc),
                  isSelected: selected?.id == loc.id,
                  pulse: pulse,
                  onTap: () => onTap(loc),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Compass rose ──────────────────────────────────────────────────────────────

class _CompassRose extends StatelessWidget {
  const _CompassRose();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(44, 44),
      painter: _CompassPainter(),
    );
  }
}

class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r, circlePaint);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(cx, cy), r - 1, borderPaint);

    // N arrow (white/gold), S arrow (white dimmer)
    final northPaint = Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.7);
    final southPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25);

    void arrow(Paint paint, double angle, double len) {
      final cosA = math.cos(angle);
      final sinA = math.sin(angle);
      final tip = Offset(cx + cosA * len, cy + sinA * len);
      final base1 = Offset(cx + math.cos(angle + math.pi / 2) * 3,
          cy + math.sin(angle + math.pi / 2) * 3);
      final base2 = Offset(cx + math.cos(angle - math.pi / 2) * 3,
          cy + math.sin(angle - math.pi / 2) * 3);
      final path = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(base1.dx, base1.dy)
        ..lineTo(base2.dx, base2.dy)
        ..close();
      canvas.drawPath(path, paint);
    }

    arrow(northPaint, -math.pi / 2, r * 0.7);
    arrow(southPaint, math.pi / 2, r * 0.5);

    // "N" text
    final tp = TextPainter(
      text: TextSpan(
        text: 'N',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - r + 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Location pin ──────────────────────────────────────────────────────────────

class _LocationPin extends StatelessWidget {
  final _MapLocation location;
  final Size mapSize;
  final bool isUnlocked;
  final bool isSelected;
  final Animation<double> pulse;
  final VoidCallback onTap;

  const _LocationPin({
    required this.location,
    required this.mapSize,
    required this.isUnlocked,
    required this.isSelected,
    required this.pulse,
    required this.onTap,
  });

  static const _hubGold = Color(0xFFFFD166);
  static const _zoneBlue = Color(0xFF7EC8E3);

  @override
  Widget build(BuildContext context) {
    // Actual canvas size from the enclosing LayoutBuilder — keeps pins
    // aligned with the painted roads on every screen size.
    final dx = (location.position.x + 1) / 2 * mapSize.width;
    final dy = (location.position.y + 1) / 2 * mapSize.height;

    final accentColor = location.isHub ? _hubGold : _zoneBlue;
    final pinSize = location.isHub ? 54.0 : 46.0;
    final emojiSize = location.isHub ? 26.0 : 22.0;

    Widget pin = GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circle icon
          Container(
            width: pinSize,
            height: pinSize,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? (location.isHub
                      ? const Color(0xFF2D1A00).withValues(alpha: 0.9)
                      : const Color(0xFF0A1F2E).withValues(alpha: 0.9))
                  : Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
              border: Border.all(
                color: isUnlocked
                    ? (isSelected
                        ? accentColor
                        : accentColor.withValues(alpha: 0.6))
                    : Colors.white.withValues(alpha: 0.12),
                width: isSelected ? 2.5 : 1.5,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(
                            alpha: isSelected ? 0.55 : 0.25),
                        blurRadius: isSelected ? 20 : 10,
                        spreadRadius: isSelected ? 3 : 1,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                isUnlocked ? location.emoji : '🔒',
                style: TextStyle(
                  fontSize: emojiSize,
                  color: isUnlocked ? null : Colors.white24,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          // Name label
          Container(
            constraints: const BoxConstraints(maxWidth: 76),
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? accentColor.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isUnlocked
                    ? accentColor.withValues(alpha: 0.35)
                    : Colors.transparent,
              ),
            ),
            child: Text(
              isUnlocked ? location.name : '???',
              style: GoogleFonts.nunito(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: isUnlocked
                    ? accentColor.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.3),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );

    // Pulse selected+unlocked pin
    if (isSelected && isUnlocked) {
      pin = AnimatedBuilder(
        animation: pulse,
        builder: (_, child) =>
            Transform.scale(scale: pulse.value, child: child),
        child: pin,
      );
    }

    return Positioned(
      left: dx - pinSize / 2,
      top: dy - pinSize / 2 - 16,
      child: pin,
    );
  }
}

// ── Info / action card ────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final _MapLocation location;
  final bool isUnlocked;
  final int day;
  final int ordersServed;
  final VoidCallback? navCallback;
  final VoidCallback onVisit;
  final VoidCallback onDismiss;

  const _InfoCard({
    required this.location,
    required this.isUnlocked,
    required this.day,
    required this.ordersServed,
    required this.navCallback,
    required this.onVisit,
    required this.onDismiss,
  });

  static const _hubGold = Color(0xFFFFD166);
  static const _zoneBlue = Color(0xFF7EC8E3);

  @override
  Widget build(BuildContext context) {
    final accent = location.isHub ? _hubGold : _zoneBlue;
    final int progress = location.isHub ? day : ordersServed;
    final int needed = location.unlockThreshold - progress;
    final String lockLabel = location.isHub
        ? 'Unlocks on Day ${location.unlockThreshold}'
        : needed == 1
            ? 'Complete 1 more order to unlock'
            : 'Complete $needed more orders to unlock';

    return AnimatedSlide(
      offset: Offset.zero,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F2218).withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isUnlocked
                ? accent.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.10),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? accent.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isUnlocked
                      ? accent.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.10),
                ),
              ),
              child: Center(
                child: Text(
                  isUnlocked ? location.emoji : '🔒',
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Text block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isUnlocked ? location.name : 'Locked Location',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          location.isHub ? '🏪 Venue' : '📦 Delivery zone',
                          style: GoogleFonts.nunito(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: accent.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isUnlocked ? location.description : lockLabel,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: Colors.white60,
                      height: 1.4,
                    ),
                  ),
                  if (isUnlocked) ...[
                    const SizedBox(height: 6),
                    _UnlockBadge(location: location, accent: accent),
                  ],
                  // Unlock progress bar (locked only)
                  if (!isUnlocked) ...[
                    const SizedBox(height: 8),
                    _ProgressBar(
                      current: progress,
                      total: location.unlockThreshold,
                      color: accent,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small helpers inside card ─────────────────────────────────────────────────

class _UnlockBadge extends StatelessWidget {
  final _MapLocation location;
  final Color accent;

  const _UnlockBadge({required this.location, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (location.isHub) {
      // Show "Visit →" or "Coming soon" depending on whether card callback exists
      final card =
          context.findAncestorWidgetOfExactType<_InfoCard>();
      final hasNav = card?.navCallback != null;
      return Row(
        children: [
          _StatusPill(
            label: '✅  Unlocked',
            color: const Color(0xFF7CFC88),
            bgAlpha: 0.12,
          ),
          const SizedBox(width: 8),
          if (hasNav)
            _VisitButton(accent: accent, onTap: card!.onVisit)
          else
            _StatusPill(
              label: '🔧  Coming soon',
              color: Colors.white38,
              bgAlpha: 0.06,
            ),
        ],
      );
    }
    // Delivery zone — just show unlocked badge
    return _StatusPill(label: '✅  Zone active', color: const Color(0xFF7CFC88), bgAlpha: 0.12);
  }
}

class _VisitButton extends StatelessWidget {
  final Color accent;
  final VoidCallback onTap;

  const _VisitButton({required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent, accent.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Visit',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1A0E00),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 11, color: Color(0xFF1A0E00)),
            ],
          ),
        ),
      );
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final double bgAlpha;

  const _StatusPill({
    required this.label,
    required this.color,
    required this.bgAlpha,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: bgAlpha),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      );
}

class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final Color color;

  const _ProgressBar({
    required this.current,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (current / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$current / $total',
          style: GoogleFonts.nunito(
            fontSize: 10,
            color: color.withValues(alpha: 0.7),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color.withValues(alpha: 0.7)),
          ),
        ),
      ],
    );
  }
}

// ── Road / path painter ───────────────────────────────────────────────────────

class _RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Roads radiate from the centre (Your Shop) to surrounding locations
    final cx = size.width * 0.50;
    final cy = size.height * 0.55; // centre of map

    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Endpoints roughly matching the pin positions
    final destinations = [
      Offset(size.width * 0.18, size.height * 0.16), // market (upper-left)
      Offset(size.width * 0.81, size.height * 0.19), // wholesale (upper-right)
      Offset(size.width * 0.16, size.height * 0.33), // hospital (left)
      Offset(size.width * 0.82, size.height * 0.38), // wedding venue (right)
      Offset(size.width * 0.16, size.height * 0.58), // school (left-mid)
      Offset(size.width * 0.82, size.height * 0.58), // café (right-mid)
      Offset(size.width * 0.35, size.height * 0.81), // gallery (lower-left)
      Offset(size.width * 0.60, size.height * 0.83), // community hall
      Offset(size.width * 0.82, size.height * 0.81), // library
    ];

    final centre = Offset(cx, cy);

    for (final dest in destinations) {
      // Slightly curved roads using quadratic bezier
      final ctrl = Offset(
        (cx + dest.dx) / 2 + (dest.dy - cy) * 0.12,
        (cy + dest.dy) / 2 - (dest.dx - cx) * 0.08,
      );
      final path = Path()
        ..moveTo(centre.dx, centre.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, dest.dx, dest.dy);
      canvas.drawPath(path, roadPaint);
    }

    // Dashed texture overlay (every other segment)
    for (double d = 0; d < size.width; d += 50) {
      for (double h = 0; h < size.height; h += 50) {
        canvas.drawCircle(
          Offset(d + 12, h + 12),
          1.2,
          dashPaint,
        );
      }
    }

    // Circular town boundary
    final boundaryPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      math.min(size.width, size.height) * 0.46,
      boundaryPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
