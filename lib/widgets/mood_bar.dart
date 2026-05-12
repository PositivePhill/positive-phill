import 'package:flutter/material.dart';
import 'package:positive_phill/models/affirmation.dart';
import 'package:positive_phill/theme.dart';

enum DailyMood {
  hopeful,
  calm,
  focused,
  motivated,
  overwhelmed,
  tired;

  String get label {
    switch (this) {
      case DailyMood.hopeful:
        return 'Hopeful';
      case DailyMood.calm:
        return 'Calm';
      case DailyMood.focused:
        return 'Focused';
      case DailyMood.motivated:
        return 'Motivated';
      case DailyMood.overwhelmed:
        return 'Overwhelmed';
      case DailyMood.tired:
        return 'Tired';
    }
  }

  String get emoji {
    switch (this) {
      case DailyMood.hopeful:
        return '🌤';
      case DailyMood.calm:
        return '😌';
      case DailyMood.focused:
        return '🔥';
      case DailyMood.motivated:
        return '💪';
      case DailyMood.overwhelmed:
        return '😵';
      case DailyMood.tired:
        return '😴';
    }
  }

  /// The affirmation category most helpful for this mood
  AffirmationCategory get suggestedCategory {
    switch (this) {
      case DailyMood.hopeful:
        return AffirmationCategory.gratitude;
      case DailyMood.calm:
        return AffirmationCategory.calm;
      case DailyMood.focused:
        return AffirmationCategory.focus;
      case DailyMood.motivated:
        return AffirmationCategory.confidence;
      case DailyMood.overwhelmed:
        return AffirmationCategory.healing;
      case DailyMood.tired:
        return AffirmationCategory.calm;
    }
  }
}

class MoodBar extends StatelessWidget {
  final DailyMood? selectedMood;
  final Future<void> Function(DailyMood) onMoodSelected;
  final List<Shadow>? textShadows;

  const MoodBar({
    super.key,
    required this.selectedMood,
    required this.onMoodSelected,
    this.textShadows,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Centered, stronger label — survives custom backgrounds
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Center(
            child: Text(
              'How are you feeling today?',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                shadows: textShadows,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: DailyMood.values.map((mood) {
              final isSelected = selectedMood == mood;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ChoiceChip(
                  label: Text(
                    '${mood.emoji} ${mood.label}',
                    style: textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  selected: isSelected,
                  onSelected: (_) => onMoodSelected(mood),
                  selectedColor: colorScheme.secondaryContainer,
                  backgroundColor: colorScheme.surface,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
