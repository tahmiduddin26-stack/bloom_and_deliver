import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/story_arc_data.dart';
import '../theme/app_theme.dart';

/// Weekly town reputation board comparing Lily's shop vs Petal & Co.
/// Shown at the end of each 7-day cycle (Day 8, 15, 22, 29…).
void showReputationBoard(
  BuildContext context, {
  required int week,
  required int playerScore,
  required VoidCallback onClose,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ReputationBoardDialog(
      week: week,
      playerScore: playerScore,
      onClose: onClose,
    ),
  );
}

class _ReputationBoardDialog extends StatefulWidget {
  final int week;
  final int playerScore;
  final VoidCallback onClose;

  const _ReputationBoardDialog({
    required this.week,
    required this.playerScore,
    required this.onClose,
  });

  @override
  State<_ReputationBoardDialog> createState() => _ReputationBoardDialogState();
}

class _ReputationBoardDialogState extends State<_ReputationBoardDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  bool _barsVisible = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5)),
    );
    _ctrl.forward();

    // Bars animate in after the dialog appears
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _barsVisible = true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rival = petalCoScoreForWeek(widget.week);
    final player = widget.playerScore;
    final playerWins = player >= rival;

    // Normalise bar widths: max bar = full width
    final maxScore = (player > rival ? player : rival).toDouble();
    final playerFrac = maxScore > 0 ? player / maxScore : 0.0;
    final rivalFrac = maxScore > 0 ? rival / maxScore : 0.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 370),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2D2A3E), Color(0xFF1A1726)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.60),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ────────────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Row(
                    children: [
                      const Text('📊', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Town Reputation',
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Week ${ widget.week } wrap-up',
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Score bars ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    children: [
                      _ScoreBar(
                        label: "Lily's Blooms",
                        emoji: '🌸',
                        score: player,
                        fraction: playerFrac,
                        color: AppColors.carnationCoral,
                        visible: _barsVisible,
                        delay: 0,
                      ),
                      const SizedBox(height: 14),
                      _ScoreBar(
                        label: 'Petal & Co.',
                        emoji: '🏪',
                        score: rival,
                        fraction: rivalFrac,
                        color: const Color(0xFF9E8AFF),
                        visible: _barsVisible,
                        delay: 150,
                      ),
                    ],
                  ),
                ),

                // ── Verdict ───────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: AnimatedOpacity(
                    opacity: _barsVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: playerWins
                            ? AppColors.carnationCoral.withValues(alpha: 0.12)
                            : const Color(0xFF9E8AFF).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: playerWins
                              ? AppColors.carnationCoral.withValues(alpha: 0.30)
                              : const Color(0xFF9E8AFF)
                                  .withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            playerWins ? '🏆' : '😤',
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              playerWins
                                  ? _winMessage(widget.week)
                                  : _loseMessage(widget.week),
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.88),
                                height: 1.45,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Close button ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onClose();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5DBB8A), Color(0xFF3A9068)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3A9068)
                                .withValues(alpha: 0.40),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Text(
                        'Keep blooming! 🌷',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _winMessage(int week) {
    const msgs = [
      "The whole town is buzzing about your bouquets! Petal & Co. is scrambling to keep up.",
      "Two weeks running — you're the talk of every street corner. Bud says he overheard them arguing.",
      "Three weeks of victory! A customer said they walked past Petal & Co. and it looked quiet…",
      "They hired a window dresser. Bud peeked inside. Still not as cozy as here. 🌿",
    ];
    return msgs[(week - 1).clamp(0, msgs.length - 1)];
  }

  String _loseMessage(int week) {
    const msgs = [
      "Petal & Co. edged you out this week. Their grand opening specials drew a crowd — keep pushing!",
      "Still behind, but your regulars are loyal. More great bouquets and the tide will turn.",
      "They've got momentum. But Bud reminded you: one perfect arrangement can change everything.",
      "Neck and neck across town. Your heart is in every bouquet — that matters more than a scoreboard.",
    ];
    return msgs[(week - 1).clamp(0, msgs.length - 1)];
  }
}

// ── Score bar ─────────────────────────────────────────────────────────────────

class _ScoreBar extends StatefulWidget {
  final String label;
  final String emoji;
  final int score;
  final double fraction;
  final Color color;
  final bool visible;
  final int delay; // extra ms delay before animating in

  const _ScoreBar({
    required this.label,
    required this.emoji,
    required this.score,
    required this.fraction,
    required this.color,
    required this.visible,
    required this.delay,
  });

  @override
  State<_ScoreBar> createState() => _ScoreBarState();
}

class _ScoreBarState extends State<_ScoreBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _barCtrl;
  late final Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _barAnim = CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(_ScoreBar old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible) {
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) _barCtrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(widget.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const Spacer(),
            Text(
              '${widget.score} pts',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: widget.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Track
                Container(
                  height: 10,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                // Fill
                AnimatedBuilder(
                  animation: _barAnim,
                  builder: (_, __) => Container(
                    height: 10,
                    width: constraints.maxWidth *
                        widget.fraction *
                        _barAnim.value,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.45),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
