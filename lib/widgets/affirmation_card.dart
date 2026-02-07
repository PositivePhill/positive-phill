import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:positive_phill/models/affirmation.dart';
import 'package:positive_phill/providers/user_provider.dart';
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

class _AffirmationCardState extends State<AffirmationCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('en-US');
    _tts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _tts.setErrorHandler((msg) {
      if (mounted) setState(() => _isSpeaking = false);
    });
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
    _tts.stop();
    _controller.dispose();
    super.dispose();
  }

  void _onFavorite() {
    final userProvider = context.read<UserProvider>();
    final isFavorite = userProvider.isFavorite(widget.affirmation.id);
    
    if (!isFavorite) {
      _controller.forward().then((_) => _controller.reverse());
      HapticsService.feedback(FeedbackType.light);
    }
    
    userProvider.toggleFavorite(widget.affirmation.id);
  }

  void _onShare() {
    HapticsService.feedback(FeedbackType.selection);
    Share.share(
      '${widget.affirmation.text}\n\n— Positive Phill by Possum Mattern Studios',
      subject: 'Daily Affirmation',
    );
  }

  Future<void> _onSpeak() async {
    final text = widget.affirmation.text.trim();
    if (text.isEmpty) return;
    if (_isSpeaking) {
      await _tts.stop();
      if (mounted) setState(() => _isSpeaking = false);
      return;
    }
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isFavorite = userProvider.isFavorite(widget.affirmation.id);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.affirmation.text,
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                height: 1.5,
                shadows: widget.textBacklightEnabled
                    ? [
                        Shadow(
                          color: Colors.black.withOpacity(0.6),
                          offset: const Offset(1, 1),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.showActions) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: IconButton(
                      onPressed: _onFavorite,
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : colorScheme.secondary,
                        size: 32,
                      ),
                      tooltip: 'Favorite (+10 XP)',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  IconButton(
                    onPressed: _onShare,
                    icon: Icon(
                      Icons.share,
                      color: colorScheme.secondary,
                      size: 28,
                    ),
                    tooltip: 'Share',
                  ),
                  const SizedBox(width: AppSpacing.md),
                  IconButton(
                    onPressed: _onSpeak,
                    icon: Icon(
                      _isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                      color: colorScheme.secondary,
                      size: 28,
                    ),
                    tooltip: _isSpeaking ? 'Stop' : 'Speak',
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
