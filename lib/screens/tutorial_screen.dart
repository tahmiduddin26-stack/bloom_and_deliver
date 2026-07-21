import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/flower_data.dart';
import '../models/flower.dart';
import '../providers/game_provider.dart';
import '../services/analytics_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/flower_image.dart';
import 'level_map_screen.dart';

// ── Interactive tutorial ──────────────────────────────────────────────────────
//
// Five steps. By step 3 the player is building — and then submitting — a real
// bouquet for a real customer, not just reading dialog. Each step logs an
// analytics event so the FTUE funnel is measurable (SHIP_PLAN Phase 1).
//
//   0  Welcome (Lily)
//   1  Meet the customer (Bud) — the order card appears
//   2  Build the bouquet (interactive) — tap flowers to match the vibe
//   3  Nailed it (Bud) — the submit result + how tips work
//   4  Ready (Lily) — restock at the market, then off you go

class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  int _step = 0;

  /// The tutorial customer's single required vibe.
  static const _wantedVibe = VibeTag.romantic;

  /// Flowers offered in the tutorial tray (two carry the wanted vibe).
  static const _trayIds = ['rose', 'tulip', 'daisy', 'lavender'];

  /// The player's in-progress tutorial bouquet (local — never touches the real
  /// game state, so the campaign starts clean).
  final List<Flower> _bouquet = [];

  static const _stepNames = [
    'welcome',
    'meet_customer',
    'build_bouquet',
    'result',
    'ready',
  ];

  static const _gradients = [
    [Color(0xFFFFF0F5), Color(0xFFFCE4EC)],
    [Color(0xFFF1FFF5), Color(0xFFE8F5E9)],
    [Color(0xFFFFFDE7), Color(0xFFFFF8E1)],
    [Color(0xFFFDEFF4), Color(0xFFFCE4EC)],
    [Color(0xFFF5F0FF), Color(0xFFF3E5F5)],
  ];

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.tutorialStep(0, _stepNames[0]);
  }

  // ── Bouquet state ───────────────────────────────────────────────────────────

  bool get _hasWantedVibe => _bouquet.any((f) => f.vibes.contains(_wantedVibe));
  bool get _bouquetReady => _bouquet.length >= 2 && _hasWantedVibe;

  void _addFlower(Flower f) {
    if (_bouquet.length >= 5) return;
    HapticFeedback.selectionClick();
    AudioService.instance.play(GameSound.flowerDrop);
    setState(() => _bouquet.add(f));
  }

  void _removeFlower(int index) {
    HapticFeedback.selectionClick();
    setState(() => _bouquet.removeAt(index));
  }

  // ── Navigation ──────────────────────────────────────────────────────────────

  void _goToStep(int next) {
    setState(() => _step = next);
    AnalyticsService.instance.tutorialStep(next, _stepNames[next]);
  }

  String get _primaryLabel => switch (_step) {
        2 => 'Submit  🎀',
        4 => "Let's Bloom!  🌸",
        _ => 'Next  →',
      };

  bool get _primaryEnabled => _step != 2 || _bouquetReady;

  void _onPrimary() {
    if (_step == 2) {
      // Submit the first real bouquet.
      AudioService.instance.play(GameSound.greatOrder);
      HapticFeedback.mediumImpact();
      AnalyticsService.instance.tutorialFirstBouquetSubmitted();
      _goToStep(3);
    } else if (_step == 4) {
      _finish();
    } else {
      _goToStep(_step + 1);
    }
  }

  void _skip() {
    AnalyticsService.instance.tutorialSkipped(_step);
    _leaveToGame();
  }

  void _finish() {
    AnalyticsService.instance.tutorialCompleted();
    _leaveToGame();
  }

  void _leaveToGame() {
    // Grant the one-time tutorial starter reward (unchanged).
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _gradients[_step],
          ),
        ),
        child: Stack(
          children: [
            const _FloatingDecorations(),
            SafeArea(
              child: Column(
                children: [
                  _TutHeader(onSkip: _skip),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      child: KeyedSubtree(
                        key: ValueKey(_step),
                        child: _buildStep(),
                      ),
                    ),
                  ),
                  _TutFooter(
                    page: _step,
                    total: _stepNames.length,
                    label: _primaryLabel,
                    enabled: _primaryEnabled,
                    highlight: _step == 4,
                    onNext: _onPrimary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return const _DialogStep(
          character: GameCharacter.lily,
          message:
              'Welcome to Bloom & Deliver! 🌸\n\nI\'m Lily, your head florist. '
              'Let\'s make your very first bouquet together — it only takes a minute!',
        );
      case 1:
        return _MeetCustomerStep(
          customerName: _customerName,
          customerPortrait: _customerPortrait,
          note: _customerNote,
          wantedVibe: _wantedVibe,
        );
      case 2:
        return _BuildStep(
          customerName: _customerName,
          customerPortrait: _customerPortrait,
          note: _customerNote,
          wantedVibe: _wantedVibe,
          covered: _hasWantedVibe,
          bouquet: _bouquet,
          tray: _trayFlowers,
          onAdd: _addFlower,
          onRemove: _removeFlower,
        );
      case 3:
        return _DialogStep(
          character: GameCharacter.bud,
          message:
              'Perfect — $_customerName loves it! 💕\n\nThe closer your bouquet '
              'matches the vibe, the bigger the tip. Regular customers who keep '
              'coming back tip even more!',
        );
      default:
        return const _DialogStep(
          character: GameCharacter.lily,
          message:
              'After each day, restock at the market. 🌺\n\nRarer blooms unlock '
              'as you grow and pay the biggest tips. I\'ve popped a few premium '
              'flowers and some coins in your shop to start you off. Ready?',
        );
    }
  }

  // ── Tutorial customer + flowers ─────────────────────────────────────────────

  static const _customerName = 'Mira';
  static const _customerPortrait = '👩';
  static const _customerNote =
      '"It\'s our anniversary tonight. Something romantic would be perfect. 💕"';

  List<Flower> get _trayFlowers =>
      [for (final id in _trayIds) flowerById[id]!];
}

// ── Dialog step (character + speech card) ─────────────────────────────────────

class _DialogStep extends StatelessWidget {
  final GameCharacter character;
  final String message;

  const _DialogStep({required this.character, required this.message});

  @override
  Widget build(BuildContext context) {
    final isLily = character == GameCharacter.lily;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FloatWrap(child: _CharacterCircle(character: character, isLily: isLily)),
          const SizedBox(height: 28),
          _SpeechCard(isLily: isLily, message: message),
        ],
      ),
    );
  }
}

// ── Meet-the-customer step ────────────────────────────────────────────────────

class _MeetCustomerStep extends StatelessWidget {
  final String customerName;
  final String customerPortrait;
  final String note;
  final VibeTag wantedVibe;

  const _MeetCustomerStep({
    required this.customerName,
    required this.customerPortrait,
    required this.note,
    required this.wantedVibe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FloatWrap(
            child: _CharacterCircle(
              character: GameCharacter.bud,
              isLily: false,
              size: 130,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your first customer is here! Read her note and the vibe she\'s after.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.inkBrown,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          _CustomerCard(
            name: customerName,
            portrait: customerPortrait,
            note: note,
            wantedVibe: wantedVibe,
            covered: false,
          ),
        ],
      ),
    );
  }
}

// ── Build step (interactive) ──────────────────────────────────────────────────

class _BuildStep extends StatelessWidget {
  final String customerName;
  final String customerPortrait;
  final String note;
  final VibeTag wantedVibe;
  final bool covered;
  final List<Flower> bouquet;
  final List<Flower> tray;
  final void Function(Flower) onAdd;
  final void Function(int) onRemove;

  const _BuildStep({
    required this.customerName,
    required this.customerPortrait,
    required this.note,
    required this.wantedVibe,
    required this.covered,
    required this.bouquet,
    required this.tray,
    required this.onAdd,
    required this.onRemove,
  });

  String get _coach {
    if (bouquet.isEmpty) {
      return 'Tap a flower with the 💕 ${wantedVibe.label} vibe to add it.';
    }
    if (!covered) {
      return 'Add a 💕 ${wantedVibe.label} bloom — try the Rose or Tulip!';
    }
    if (bouquet.length < 2) {
      return 'Lovely! Add one more flower, then hit Submit.';
    }
    return 'That\'s a beautiful match — hit Submit when you\'re ready! 🎀';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Column(
        children: [
          _CustomerCard(
            name: customerName,
            portrait: customerPortrait,
            note: note,
            wantedVibe: wantedVibe,
            covered: covered,
            compact: true,
          ),
          const SizedBox(height: 10),
          // Workspace
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.gardenGreenMid.withValues(alpha: 0.35),
                  width: 2,
                ),
              ),
              child: bouquet.isEmpty
                  ? Center(
                      child: Text(
                        '🪴  Your bouquet\nTap flowers below to add them',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brownLight,
                          height: 1.5,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (var i = 0; i < bouquet.length; i++)
                            GestureDetector(
                              onTap: () => onRemove(i),
                              child: _FlowerChip(flower: bouquet[i], inBouquet: true),
                            ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          // Coaching line
          Text(
            _coach,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: covered ? AppColors.gardenGreenDark : AppColors.inkBrown,
            ),
          ),
          const SizedBox(height: 10),
          // Flower tray
          SizedBox(
            height: 96,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final f in tray)
                  GestureDetector(
                    onTap: () => onAdd(f),
                    child: _FlowerChip(
                      flower: f,
                      wanted: f.vibes.contains(wantedVibe),
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

// ── A single flower pot (tray or bouquet) ─────────────────────────────────────

class _FlowerChip extends StatelessWidget {
  final Flower flower;
  final bool wanted;
  final bool inBouquet;

  const _FlowerChip({
    required this.flower,
    this.wanted = false,
    this.inBouquet = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(
              color: wanted
                  ? AppColors.roseRed.withValues(alpha: 0.7)
                  : AppColors.gardenGreenMid.withValues(alpha: 0.3),
              width: wanted ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(child: FlowerImage(flower: flower, size: 40)),
        ),
        const SizedBox(height: 3),
        Text(
          inBouquet ? '${flower.name}  ✕' : flower.name,
          style: GoogleFonts.nunito(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: inBouquet ? AppColors.brownLight : AppColors.inkBrown,
          ),
        ),
        if (wanted && !inBouquet)
          Text(
            '💕 ${flower.vibes.contains(VibeTag.romantic) ? "Romantic" : ""}',
            style: const TextStyle(fontSize: 9),
          ),
      ],
    );
  }
}

// ── Customer order card ───────────────────────────────────────────────────────

class _CustomerCard extends StatelessWidget {
  final String name;
  final String portrait;
  final String note;
  final VibeTag wantedVibe;
  final bool covered;
  final bool compact;

  const _CustomerCard({
    required this.name,
    required this.portrait,
    required this.note,
    required this.wantedVibe,
    required this.covered,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(portrait, style: TextStyle(fontSize: compact ? 26 : 32)),
              const SizedBox(width: 10),
              Text(
                name,
                style: GoogleFonts.playfairDisplay(
                  fontSize: compact ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.inkBrown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note,
            style: GoogleFonts.nunito(
              fontSize: compact ? 12.5 : 13.5,
              fontStyle: FontStyle.italic,
              color: AppColors.brownLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Wants: ',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brownLight,
                ),
              ),
              _VibeChip(vibe: wantedVibe, covered: covered),
            ],
          ),
        ],
      ),
    );
  }
}

class _VibeChip extends StatelessWidget {
  final VibeTag vibe;
  final bool covered;

  const _VibeChip({required this.vibe, required this.covered});

  @override
  Widget build(BuildContext context) {
    final color = covered ? AppColors.gardenGreenDark : AppColors.roseRed;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        covered ? '✓ ${vibe.label}' : '💕 ${vibe.label}',
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

// ── Shared speech card ────────────────────────────────────────────────────────

class _SpeechCard extends StatelessWidget {
  final bool isLily;
  final String message;

  const _SpeechCard({required this.isLily, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            color: (isLily ? AppColors.gardenGreenMid : AppColors.shelfWoodMid)
                .withValues(alpha: 0.12),
            blurRadius: 40,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NameBadge(isLily: isLily),
          const SizedBox(height: 14),
          Text(
            message,
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: AppColors.inkBrown,
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Floating wrapper (gentle bob) ─────────────────────────────────────────────

class _FloatWrap extends StatefulWidget {
  final Widget child;
  const _FloatWrap({required this.child});

  @override
  State<_FloatWrap> createState() => _FloatWrapState();
}

class _FloatWrapState extends State<_FloatWrap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _y;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _y = Tween<double>(begin: -10, end: 10)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _y,
        builder: (_, child) =>
            Transform.translate(offset: Offset(0, _y.value), child: child),
        child: widget.child,
      );
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

// ── Character circle ──────────────────────────────────────────────────────────

class _CharacterCircle extends StatelessWidget {
  final GameCharacter character;
  final bool isLily;
  final double size;

  const _CharacterCircle({
    required this.character,
    required this.isLily,
    this.size = 180,
  });

  @override
  Widget build(BuildContext context) {
    final circleColor = isLily ? AppColors.gardenGreenMid : AppColors.shelfWoodMid;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: circleColor.withValues(alpha: 0.12),
        border: Border.all(color: circleColor.withValues(alpha: 0.25), width: 3),
        boxShadow: [
          BoxShadow(
            color: circleColor.withValues(alpha: 0.20),
            blurRadius: 50,
            spreadRadius: 12,
          ),
        ],
      ),
      child: Center(
        child: CharacterImage(character: character, size: size * 0.82),
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

// ── Footer (dots + primary button) ────────────────────────────────────────────

class _TutFooter extends StatelessWidget {
  final int page;
  final int total;
  final String label;
  final bool enabled;
  final bool highlight;
  final VoidCallback onNext;

  const _TutFooter({
    required this.page,
    required this.total,
    required this.label,
    required this.enabled,
    required this.highlight,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 28),
      child: Column(
        children: [
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: LinearGradient(
                  colors: !enabled
                      ? [const Color(0xFFBFC7C0), const Color(0xFFAAB2AB)]
                      : highlight
                          ? [const Color(0xFFFF6B9E), const Color(0xFFE8456A)]
                          : [AppColors.gardenGreenMid, AppColors.gardenGreenDark],
                ),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: (highlight
                                  ? AppColors.roseRed
                                  : AppColors.gardenGreenMid)
                              .withValues(alpha: 0.40),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: ElevatedButton(
                onPressed: enabled ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(0, 58),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: Text(
                  label,
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
    _y = Tween<double>(begin: 0, end: 8)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
            bottom: 340 + _y.value * 0.6,
            left: 20,
            child: Opacity(
              opacity: 0.45,
              child: const Text('🌼', style: TextStyle(fontSize: 18)),
            ),
          ),
          Positioned(
            top: 70 + _y.value * 0.3,
            right: 70,
            child: Opacity(
              opacity: 0.4,
              child: const Text('🌿', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
