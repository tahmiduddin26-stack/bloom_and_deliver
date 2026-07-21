import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'flower_image.dart';

enum TipCharacterType { florist, helper }

/// Animated tip character that slides in from the left.
/// Lily (florist) uses green; Bud (helper) uses warm brown.
/// Character images come from assets/characters/lily.png and bud.png.
class TipCharacter extends StatefulWidget {
  final TipCharacterType character;
  final String tip;
  final VoidCallback? onDismiss;
  final Duration autoDismissAfter;

  const TipCharacter({
    super.key,
    required this.character,
    required this.tip,
    this.onDismiss,
    this.autoDismissAfter = const Duration(seconds: 7),
  });

  @override
  State<TipCharacter> createState() => _TipCharacterState();
}

class _TipCharacterState extends State<TipCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _slide = Tween<Offset>(
      begin: const Offset(-1.6, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();

    Future.delayed(widget.autoDismissAfter, () {
      if (mounted && !_dismissing) _dismiss();
    });
  }

  void _dismiss() {
    if (_dismissing) return;
    setState(() => _dismissing = true);
    _ctrl.reverse().then((_) {
      if (mounted) widget.onDismiss?.call();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFlorist = widget.character == TipCharacterType.florist;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: GestureDetector(
          onTap: _dismiss,
          child: Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Character avatar (big, uses real PNG)
                _CharacterAvatar(isFlorist: isFlorist),
                const SizedBox(width: 8),
                // Speech bubble
                _SpeechBubble(
                  name: isFlorist ? 'Lily 🌸' : 'Bud 🌿',
                  accentColor: isFlorist
                      ? AppColors.gardenGreenMid
                      : AppColors.shelfWoodMid,
                  nameDarkColor: isFlorist
                      ? AppColors.gardenGreenDark
                      : AppColors.shelfWoodDark,
                  tip: widget.tip,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Character avatar ──────────────────────────────────────────────────────────

class _CharacterAvatar extends StatefulWidget {
  final bool isFlorist;
  const _CharacterAvatar({required this.isFlorist});

  @override
  State<_CharacterAvatar> createState() => _CharacterAvatarState();
}

class _CharacterAvatarState extends State<_CharacterAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;
  late final Animation<double> _y;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _y = Tween<double>(begin: 0, end: -7).animate(
      CurvedAnimation(parent: _bounce, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isFlorist
        ? AppColors.gardenGreenMid
        : AppColors.shelfWoodMid;

    return AnimatedBuilder(
      animation: _y,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _y.value),
        child: child,
      ),
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withValues(alpha: 0.18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.9),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 10,
              offset: const Offset(2, 6),
            ),
          ],
        ),
        child: ClipOval(
          child: CharacterImage(
            character:
                widget.isFlorist ? GameCharacter.lily : GameCharacter.bud,
            size: 80,
          ),
        ),
      ),
    );
  }
}

// ── Speech bubble ─────────────────────────────────────────────────────────────

class _SpeechBubble extends StatelessWidget {
  final String name;
  final Color accentColor;
  final Color nameDarkColor;
  final String tip;

  const _SpeechBubble({
    required this.name,
    required this.accentColor,
    required this.nameDarkColor,
    required this.tip,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 230),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.97),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 14,
              offset: const Offset(2, 5),
            ),
            BoxShadow(
              color: accentColor.withValues(alpha: 0.12),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
          border: Border.all(
            color: accentColor.withValues(alpha: 0.20),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                name,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: nameDarkColor,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Tip text
            Text(
              tip,
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                color: AppColors.inkBrown,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            // Dismiss hint
            Text(
              'tap to dismiss',
              style: GoogleFonts.nunito(
                fontSize: 9,
                color: AppColors.brownLight.withValues(alpha: 0.50),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
