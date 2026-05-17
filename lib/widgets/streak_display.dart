import 'package:flutter/material.dart';
import 'package:positive_phill/theme.dart';

class StreakDisplay extends StatelessWidget {
  final int streak;
  final List<Shadow>? textShadows;

  /// Stronger frost + text when Home uses image/video scrim.
  final bool stressedBackdrop;

  const StreakDisplay({
    super.key,
    required this.streak,
    this.textShadows,
    this.stressedBackdrop = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    final gradAlpha = stressedBackdrop ? (isLight ? 0.42 : 0.30) : 0.2;
    final borderAlpha = stressedBackdrop ? 0.38 : 0.2;

    final subtitleColor = stressedBackdrop
        ? (isLight
            ? colorScheme.onSurface.withValues(alpha: 0.88)
            : colorScheme.onSurfaceVariant)
        : colorScheme.onSurfaceVariant;

    final titleShadows = <Shadow>[
      ...?textShadows,
      if (stressedBackdrop && isLight)
        Shadow(
          color: Colors.white.withValues(alpha: 0.72),
          blurRadius: 3,
          offset: Offset.zero,
        ),
    ];

    final subtitleShadows = <Shadow>[
      ...?textShadows,
      if (stressedBackdrop && isLight)
        Shadow(
          color: Colors.white.withValues(alpha: 0.65),
          blurRadius: 3,
          offset: Offset.zero,
        ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.tertiary.withValues(alpha: gradAlpha),
            colorScheme.secondary.withValues(alpha: gradAlpha),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: borderAlpha),
          width: 1,
        ),
        boxShadow: stressedBackdrop
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isLight ? 0.14 : 0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🔥',
            style: TextStyle(fontSize: 32),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$streak Day Streak',
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  shadows: titleShadows.isEmpty ? null : titleShadows,
                ),
              ),
              Text(
                streak > 0 ? 'Keep it going!' : 'Start today!',
                style: textTheme.bodySmall?.copyWith(
                  color: subtitleColor,
                  fontWeight:
                      stressedBackdrop && isLight ? FontWeight.w600 : null,
                  shadows: subtitleShadows.isEmpty ? null : subtitleShadows,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
