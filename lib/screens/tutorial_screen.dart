import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/flower_image.dart';
import 'level_map_screen.dart';

// ── Tutorial entry point ──────────────────────────────────────────────────────

class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen>
    with SingleTickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _page = 0;

  // ── Step definitions ────────────────────────────────────────────────────────

  static const _steps = [
    _TutStep(
      character: GameCharacter.lily,
      message:
          'Welcome to Bloom & Deliver! 🌸\n\nI\'m Lily, your head florist. '
          'We craft the most beautiful bouquets in town — let me show you the ropes!',
      bgGradient: [Color(0xFFFFF0F5), Color(0xFFFCE4EC)],
    ),
    _TutStep(
      character: GameCharacter.bud,
      message:
          'Hey! I\'m Bud! 🌿\n\nCustomers send orders through the phone on the '
          'right. Tap it to see what kind of bouquet they\'re after — each '
          'message hints at the vibe they want!',
      bgGradient: [Color(0xFFF1FFF5), Color(0xFFE8F5E9)],
    ),
    _TutStep(
      character: GameCharacter.lily,
      message:
          'See those flowers on the shelves? ✨\n\nDrag them down into the '
          'workspace to start building your bouquet. Mix and match colours '
          'and vibes to nail what the customer asked for!',
      bgGradient: [Color(0xFFFFFDE7), Color(0xFFFFF8E1)],
    ),
    _TutStep(
      character: GameCharacter.bud,
      message:
          'Hit Submit when you\'ve got enough flowers! 🎀\n\nA perfect match '
          'earns a big tip. The closer your bouquet matches their vibe, the '
          'more coins you pocket. Regular customers give loyalty bonuses too!',
      bgGradient: [Color(0xFFE8F4FD), Color(0xFFE3F2FD)],
    ),
    _TutStep(
      character: GameCharacter.lily,
      message:
          'After each day, head to the market to restock! 🌺\n\nNew flowers '
          'unlock as you grow — some rare blooms give massive tips. Keep '
          'those regulars happy and the coins add up fast. Ready to bloom?',
      bgGradient: [Color(0xFFF5F0FF), Color(0xFFF3E5F5)],
    ),
  ];

  // ── Navigation ──────────────────────────────────────────────────────────────

  void _next() {
    if (_page < _steps.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _startGame();
    }
  }

  void _startGame() {
    // Grant the one-time tutorial starter reward.
    ref.read(gameProvider.notifier).claimTutorialReward();
    AudioService.instance.play(GameSound.greatOrder);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const LevelMapScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeIn),
          child: child,
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_page];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: step.bgGradient,
          ),
        ),
        child: Stack(
          children: [
            // ── Decorative floating emojis ─────────────────────────────────
            const _FloatingDecorations(),

            // ── Main content ───────────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // Header row
                  _TutHeader(onSkip: _startGame),

                  // Page content
                  Expanded(
                    child: PageView.builder(
                      controller: _pageCtrl,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemCount: _steps.length,
                      itemBuilder: (_, i) => _TutPage(step: _steps[i]),
                    ),
                  ),

                  // Dots + action button
                  _TutFooter(
                    page: _page,
                    total: _steps.length,
                    isLast: _page == _steps.length - 1,
                    onNext: _next,
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

class _TutHeader extends StatelessWidget {
  final VoidCallback onSkip;
  const _TutHeader({required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 16, 0),
      child: Row(
        children: [
          const Text('🌸', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Bloom & Deliver',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.gardenGreenDark,
              ),
            ),
          ),
          TextButton(
            onPressed: onSkip,
            child: Text(
              'Skip',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.brownLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single tutorial page ──────────────────────────────────────────────────────

class _TutPage extends StatefulWidget {
  final _TutStep step;
  const _TutPage({required this.step});

  @override
  State<_TutPage> createState() => _TutPageState();
}

class _TutPageState extends State<_TutPage> with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final Animation<double> _floatY;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _floatY = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLily = widget.step.character == GameCharacter.lily;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Character with floating animation ────────────────────────────
          AnimatedBuilder(
            animation: _floatY,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _floatY.value),
              child: child,
            ),
            child: _CharacterCircle(
              character: widget.step.character,
              isLily: isLily,
            ),
          ),

          const SizedBox(height: 28),

          // ── Speech card ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.09),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: (isLily
                          ? AppColors.gardenGreenMid
                          : AppColors.shelfWoodMid)
                      .withValues(alpha: 0.12),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name badge
                _NameBadge(isLily: isLily),
                const SizedBox(height: 14),
                // Message
                Text(
                  widget.step.message,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    color: AppColors.inkBrown,
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Character circle ──────────────────────────────────────────────────────────

class _CharacterCircle extends StatelessWidget {
  final GameCharacter character;
  final bool isLily;

  const _CharacterCircle({required this.character, required this.isLily});

  @override
  Widget build(BuildContext context) {
    final circleColor = isLily ? AppColors.gardenGreenMid : AppColors.shelfWoodMid;

    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: circleColor.withValues(alpha: 0.12),
        border: Border.all(
          color: circleColor.withValues(alpha: 0.25),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: circleColor.withValues(alpha: 0.20),
            blurRadius: 50,
            spreadRadius: 12,
          ),
        ],
      ),
      child: Center(
        child: CharacterImage(character: character, size: 148),
      ),
    );
  }
}

// ── Name badge ────────────────────────────────────────────────────────────────

class _NameBadge extends StatelessWidget {
  final bool isLily;
  const _NameBadge({required this.isLily});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLily
              ? [AppColors.gardenGreenMid, AppColors.gardenGreenDark]
              : [AppColors.shelfWoodMid, AppColors.shelfWoodDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isLily ? AppColors.gardenGreenDark : AppColors.shelfWoodDark)
                .withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        isLily ? 'Lily 🌸' : 'Bud 🌿',
        style: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Footer (dots + button) ────────────────────────────────────────────────────

class _TutFooter extends StatelessWidget {
  final int page;
  final int total;
  final bool isLast;
  final VoidCallback onNext;

  const _TutFooter({
    required this.page,
    required this.total,
    required this.isLast,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 36),
      child: Column(
        children: [
          // Progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              total,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == page ? 28.0 : 8.0,
                height: 8,
                decoration: BoxDecoration(
                  color: i == page
                      ? AppColors.gardenGreenMid
                      : AppColors.gardenGreenMid.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Next / Start button
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: LinearGradient(
                  colors: isLast
                      ? [const Color(0xFFFF6B9E), const Color(0xFFE8456A)]
                      : [AppColors.gardenGreenMid, AppColors.gardenGreenDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isLast
                            ? AppColors.roseRed
                            : AppColors.gardenGreenMid)
                        .withValues(alpha: 0.40),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(0, 58),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: Text(
                  isLast ? "Let's Bloom! 🌸" : 'Next  →',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Floating decorative emojis ────────────────────────────────────────────────

class _FloatingDecorations extends StatefulWidget {
  const _FloatingDecorations();

  @override
  State<_FloatingDecorations> createState() => _FloatingDecorationsState();
}

class _FloatingDecorationsState extends State<_FloatingDecorations>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _y;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _y = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _y,
      builder: (_, __) => Stack(
        children: [
          Positioned(
            top: 50 + _y.value * 0.5,
            left: 16,
            child: const Text('🌸', style: TextStyle(fontSize: 30)),
          ),
          Positioned(
            top: 110 - _y.value,
            right: 24,
            child: Opacity(
              opacity: 0.6,
              child: const Text('✨', style: TextStyle(fontSize: 22)),
            ),
          ),
          Positioned(
            top: 200 + _y.value * 0.7,
            left: 8,
            child: Opacity(
              opacity: 0.5,
              child: const Text('🌿', style: TextStyle(fontSize: 24)),
            ),
          ),
          Positioned(
            bottom: 240 - _y.value,
            right: 14,
            child: Opacity(
              opacity: 0.55,
              child: const Text('💐', style: TextStyle(fontSize: 28)),
            ),
          ),
          Positioned(
            bottom: 340 + _y.value * 0.6,
            left: 20,
            child: Opacity(
              opacity: 0.45,
              child: const Text('🌺', style: TextStyle(fontSize: 22)),
            ),
          ),
          Positioned(
            top: 70 + _y.value * 0.3,
            right: 70,
            child: Opacity(
              opacity: 0.4,
              child: const Text('🌼', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _TutStep {
  final GameCharacter character;
  final String message;
  final List<Color> bgGradient;

  const _TutStep({
    required this.character,
    required this.message,
    required this.bgGradient,
  });
}
