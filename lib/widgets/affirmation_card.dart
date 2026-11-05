import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:positive_phill/models/affirmation.dart';
import 'package:positive_phill/models/daily_quests.dart';
import 'package:positive_phill/providers/tts_provider.dart';
import 'package:positive_phill/providers/user_provider.dart';
import 'package:positive_phill/quest_helper.dart';
import 'package:positive_phill/services/haptics_service.dart';
import 'package:positive_phill/theme.dart';
import 'package:positive_phill/widgets/affirmation_share_sheet.dart';
import 'package:positive_phill/widgets/reduce_motion.dart';

class AffirmationCard extends StatefulWidget {
  final Affirmation affirmation;
  final bool showActions;
  final bool textBacklightEnabled;
  /// Optional label on share card (e.g. category name).
  final String? shareSubtitle;

  const AffirmationCard({
    super.key,
    required this.affirmation,
    this.showActions = true,
    this.textBacklightEnabled = true,
    this.shareSubtitle,
  });

  @override
  State<AffirmationCard> createState() => _AffirmationCardState();
}

class _AffirmationCardState extends State<AffirmationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  final ScrollController _textScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _textScrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  static const double _maxTextWidth = 600;

  /// Smallest unscaled font size used when shrinking to fit; the user's
  /// text scale still applies on top of it.
  static const double _minFontSize = 16;

  TextStyle _fittedTextStyle(
    BuildContext context,
    TextStyle base, {
    required double maxWidth,
    required double maxHeight,
  }) {
    final maxFontSize = base.fontSize ?? 24;
    if (!maxHeight.isFinite || maxFontSize <= _minFontSize) return base;

    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);
    for (var size = maxFontSize; size > _minFontSize; size -= 1) {
      final candidate = base.copyWith(fontSize: size);
      final painter = TextPainter(
        text: TextSpan(text: widget.affirmation.text, style: candidate),
        textAlign: TextAlign.center,
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout(maxWidth: maxWidth);
      final fits = painter.height <= maxHeight;
      painter.dispose();
      if (fits) return candidate;
    }
    return base.copyWith(fontSize: _minFontSize);
  }

  Future<void> _onFavorite() async {
    final userProvider = context.read<UserProvider>();
    final isFavorite = userProvider.isFavorite(widget.affirmation.id);
    if (!isFavorite) {
      if (!ReduceMotion.of(context)) {
        _controller.forward().then((_) => _controller.reverse());
      }
      HapticsService.feedback(FeedbackType.light);
    }
    await userProvider.toggleFavorite(widget.affirmation.id);
    // Quest: favorite one affirmation (guarded inside completeQuest)
    if (!isFavorite && mounted) {
      await completeQuest(context, QuestType.favoriteOne);
    }
  }

  void _onShare() {
    HapticsService.feedback(FeedbackType.selection);
    showAffirmationShareSheet(
      context: context,
      affirmation: widget.affirmation,
      categoryLabel: widget.shareSubtitle,
    );
  }

  Future<void> _onSpeak() async {
    final tts = context.read<TtsProvider>();
    if (!tts.voiceEnabled) return;
    final isThisCardSpeaking =
        tts.isSpeaking && tts.currentText == widget.affirmation.text;
    if (isThisCardSpeaking) {
      await tts.stop();
    } else {
      await tts.speak(widget.affirmation.text);
      // Quest: listen with voice
      if (mounted) await completeQuest(context, QuestType.usedVoice);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.select<UserProvider, bool>(
      (p) => p.progress.favorites.contains(widget.affirmation.id),
    );
    final isThisCardSpeaking = context.select<TtsProvider, bool>(
      (p) => p.isSpeaking && p.currentText == widget.affirmation.text,
    );
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final textColor = colorScheme.onPrimaryContainer;
    // The card is opaque: a dark backlight only helps light text; on dark
    // text it renders as a smudge.
    final List<Shadow>? textShadows =
        widget.textBacklightEnabled && textColor.computeLuminance() > 0.5
            ? [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  offset: const Offset(0, 1),
                  blurRadius: 3,
                ),
              ]
            : null;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Wraps at the card's real width and steps the font size down
            // (never below the floor) to fit the height; scrolls as a last
            // resort so text is never clipped or truncated.
            Flexible(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth < _maxTextWidth
                      ? constraints.maxWidth
                      : _maxTextWidth;
                  final style = _fittedTextStyle(
                    context,
                    textTheme.headlineSmall?.copyWith(
                          color: textColor,
                          height: 1.45,
                          shadows: textShadows,
                        ) ??
                        TextStyle(
                          color: textColor,
                          height: 1.45,
                          shadows: textShadows,
                        ),
                    maxWidth: width,
                    maxHeight: constraints.maxHeight,
                  );
                  return Center(
                    child: SizedBox(
                      width: width,
                      // The thumb paints only when the text actually
                      // overflows, signalling that more text is below.
                      child: Scrollbar(
                        controller: _textScrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _textScrollController,
                          child: Text(
                            widget.affirmation.text,
                            key: const ValueKey('affirmation-card-text'),
                            style: style,
                            textAlign: TextAlign.center,
                            softWrap: true,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.showActions) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: IconButton(
                      onPressed: _onFavorite,
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : colorScheme.primary,
                        size: 30,
                      ),
                      tooltip: 'Favorite',
                    ),
                  ),
                  // Gaps shrink on narrow cards (320px) so the 48px tap
                  // targets never overflow.
                  const Flexible(child: SizedBox(width: AppSpacing.md)),
                  IconButton(
                    onPressed: _onShare,
                    icon: Icon(
                      Icons.share_rounded,
                      color: colorScheme.primary,
                      size: 26,
                    ),
                    tooltip: 'Share',
                  ),
                  const Flexible(child: SizedBox(width: AppSpacing.md)),
                  IconButton(
                    onPressed: _onSpeak,
                    icon: Icon(
                      isThisCardSpeaking
                          ? Icons.stop_rounded
                          : Icons.volume_up_rounded,
                      color: isThisCardSpeaking
                          ? colorScheme.tertiary
                          : colorScheme.primary,
                      size: 26,
                    ),
                    tooltip: isThisCardSpeaking ? 'Stop' : 'Speak',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
