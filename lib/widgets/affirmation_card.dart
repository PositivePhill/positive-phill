import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;
import 'package:positive_phill/models/affirmation.dart';
import 'package:positive_phill/models/daily_quests.dart';
import 'package:positive_phill/providers/tts_provider.dart';
import 'package:positive_phill/providers/user_provider.dart';
import 'package:positive_phill/quest_helper.dart';
import 'package:positive_phill/services/haptics_service.dart';
import 'package:positive_phill/theme.dart';

class AffirmationCard extends StatefulWidget {
  final Affirmation affirmation;
  final bool showActions;
  final bool textBacklightEnabled;

  const AffirmationCard({
    super.key,
    required this.affirmation,
    this.showActions = true,
    this.textBacklightEnabled = true,
  });

  @override
  State<AffirmationCard> createState() => _AffirmationCardState();
}

class _AffirmationCardState extends State<AffirmationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

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
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onFavorite() async {
    final userProvider = context.read<UserProvider>();
    final isFavorite = userProvider.isFavorite(widget.affirmation.id);
    if (!isFavorite) {
      _controller.forward().then((_) => _controller.reverse());
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
    SharePlus.instance.share(
      ShareParams(
        text: '${widget.affirmation.text}\n\n— Positive Phill by Possum Mattern Studios',
        subject: 'Daily Affirmation',
      ),
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

    final List<Shadow>? textShadows = widget.textBacklightEnabled
        ? [
            Shadow(
              color: Colors.black.withValues(alpha: 0.6),
              offset: const Offset(1, 1),
              blurRadius: 4,
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
            // Responsive text region — shrinks to fit within available height.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Text(
                    widget.affirmation.text,
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      height: 1.45,
                      shadows: textShadows,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ),
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
                  const SizedBox(width: AppSpacing.md),
                  IconButton(
                    onPressed: _onShare,
                    icon: Icon(
                      Icons.share_rounded,
                      color: colorScheme.primary,
                      size: 26,
                    ),
                    tooltip: 'Share',
                  ),
                  const SizedBox(width: AppSpacing.md),
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
