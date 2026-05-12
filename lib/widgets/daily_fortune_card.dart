import 'package:flutter/material.dart';
import 'package:positive_phill/services/fortune_service.dart';
import 'package:positive_phill/theme.dart';

class DailyFortuneCard extends StatelessWidget {
  const DailyFortuneCard({super.key});

  @override
  Widget build(BuildContext context) {
    final fortune = FortuneService.getToday();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Brightness-aware premium gradient using existing theme tokens.
    // Light: warm sunrise (peach → soft peach).
    // Dark:  cosmic violet → warm peach accent.
    final gradientColors = isDark
        ? [
            colorScheme.primaryContainer,
            colorScheme.tertiary.withValues(alpha: 0.85),
          ]
        : [
            colorScheme.tertiary,
            colorScheme.tertiaryContainer,
          ];

    // High-contrast text color paired with the dominant background.
    final onCard =
        isDark ? colorScheme.onPrimaryContainer : colorScheme.onTertiary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: (isDark ? colorScheme.primary : colorScheme.tertiary)
              .withValues(alpha: 0.35),
          width: 1.25,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Eyebrow row — centered
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('✨', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                "TODAY'S ENERGY",
                style: textTheme.labelSmall?.copyWith(
                  color: onCard.withValues(alpha: 0.75),
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Energy title
          Text(
            fortune.energy,
            style: textTheme.headlineSmall?.copyWith(
              color: onCard,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          // Lucky focus — centered single line
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: textTheme.bodyMedium?.copyWith(
                color: onCard.withValues(alpha: 0.85),
              ),
              children: [
                const TextSpan(text: 'Lucky Focus: '),
                TextSpan(
                  text: fortune.luckyFocus,
                  style: TextStyle(
                    color: onCard,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Italic message
          Text(
            fortune.message,
            style: textTheme.bodyMedium?.copyWith(
              color: onCard,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
