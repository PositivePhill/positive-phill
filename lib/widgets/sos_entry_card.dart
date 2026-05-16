import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:positive_phill/nav.dart';
import 'package:positive_phill/services/haptics_service.dart';
import 'package:positive_phill/theme.dart';

/// Home entry to Rescue mode. Hidden when Focus/Zen mode is on (caller responsibility).
class SosEntryCard extends StatelessWidget {
  final List<Shadow>? textShadows;

  const SosEntryCard({
    super.key,
    this.textShadows,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.primaryContainer.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () {
          HapticsService.feedback(FeedbackType.selection);
          context.push(AppRoutes.rescue);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                Icons.favorite_outline,
                color: colorScheme.onPrimaryContainer,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need a boost?',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimaryContainer,
                        shadows: textShadows,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose a reset moment',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
