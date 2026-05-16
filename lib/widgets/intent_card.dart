import 'package:flutter/material.dart';
import 'package:positive_phill/models/rescue_intent.dart';
import 'package:positive_phill/theme.dart';

class IntentCard extends StatelessWidget {
  final RescueIntent intent;
  final VoidCallback onTap;

  const IntentCard({
    super.key,
    required this.intent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Text(
                _emojiFor(intent),
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      intent.displayTitle,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      intent.supportLine,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _emojiFor(RescueIntent intent) {
    switch (intent) {
      case RescueIntent.calm:
        return '🌊';
      case RescueIntent.hype:
        return '⚡';
      case RescueIntent.focus:
        return '🎯';
      case RescueIntent.healing:
        return '💚';
      case RescueIntent.confidence:
        return '💪';
    }
  }
}
