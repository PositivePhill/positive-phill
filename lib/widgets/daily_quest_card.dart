import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:positive_phill/models/daily_quests.dart';
import 'package:positive_phill/providers/quest_provider.dart';
import 'package:positive_phill/theme.dart';

class DailyQuestCard extends StatelessWidget {
  const DailyQuestCard({super.key});

  @override
  Widget build(BuildContext context) {
    final quests = context.select<QuestProvider, DailyQuests>((p) => p.quests);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📋', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Daily Quests',
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${quests.completed.length}/${QuestType.values.length}',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...QuestType.values.map((type) {
            final done = quests.isCompleted(type);
            return Padding(
              padding:
                  const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      done
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      key: ValueKey(done),
                      color: done
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    type.emoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      type.label,
                      style: textTheme.bodySmall?.copyWith(
                        color: done
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
                        decoration: done
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+5 XP',
                    style: textTheme.labelSmall?.copyWith(
                      color: done
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (quests.allComplete) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm, horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'All quests done! +15 XP bonus earned',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
