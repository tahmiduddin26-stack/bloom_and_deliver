import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/story_arc_data.dart';
import '../theme/app_theme.dart';

/// Shows the Lily & Bud chapter dialogue for a given day milestone.
void showStoryArcDialog(BuildContext context, int day, VoidCallback onClose) {
  final chapter = chapterForDay(day);
  if (chapter == null) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _StoryArcDialog(chapter: chapter, onClose: onClose),
  );
}

class _StoryArcDialog extends StatefulWidget {
  final StoryChapter chapter;
  final VoidCallback onClose;

  const _StoryArcDialog({required this.chapter, required this.onClose});

  @override
  State<_StoryArcDialog> createState() => _StoryArcDialogState();
}

class _StoryArcDialogState extends State<_StoryArcDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  bool _budVisible = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5)),
    );
    _ctrl.forward();

    // Reveal Bud's line after a beat
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _budVisible = true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2A3D2A), Color(0xFF1A2A1A)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.sage.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header strip ──────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Row(
                    children: [
                      const Text('📖', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        'Day ${widget.chapter.day}',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.sage.withValues(alpha: 0.8),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Dialogue ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Column(
                    children: [
                      // Lily
                      _DialogueLine(
                        portrait: '🌸',
                        name: 'Lily',
                        nameColor: AppColors.carnationCoral,
                        text: widget.chapter.lilyLine,
                        visible: true,
                      ),
                      const SizedBox(height: 14),
                      // Bud (delayed reveal)
                      AnimatedOpacity(
                        opacity: _budVisible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeIn,
                        child: AnimatedSlide(
                          offset: _budVisible
                              ? Offset.zero
                              : const Offset(0, 0.12),
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOut,
                          child: _DialogueLine(
                            portrait: '🌿',
                            name: 'Bud',
                            nameColor: AppColors.sage,
                            text: widget.chapter.budLine,
                            visible: true,
                            alignRight: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Close button ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
                            color:
                                const Color(0xFF3A9068).withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Text(
                        'Back to the shop 🌷',
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
}

// ── Single dialogue line ───────────────────────────────────────────────────────

class _DialogueLine extends StatelessWidget {
  final String portrait;
  final String name;
  final Color nameColor;
  final String text;
  final bool visible;
  final bool alignRight;

  const _DialogueLine({
    required this.portrait,
    required this.name,
    required this.nameColor,
    required this.text,
    required this.visible,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: alignRight
              ? [
                  Text(
                    name,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: nameColor,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(portrait, style: const TextStyle(fontSize: 16)),
                ]
              : [
                  Text(portrait, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 5),
                  Text(
                    name,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: nameColor,
                    ),
                  ),
                ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: alignRight
                  ? const Radius.circular(16)
                  : const Radius.circular(4),
              bottomRight: alignRight
                  ? const Radius.circular(4)
                  : const Radius.circular(16),
            ),
            border: Border.all(
              color: nameColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Text(
            text,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.90),
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );

    return alignRight
        ? Align(alignment: Alignment.centerRight, child: bubble)
        : bubble;
  }
}
