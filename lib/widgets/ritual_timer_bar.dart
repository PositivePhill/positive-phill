// ignore: unnecessary_import -- Explicit dart:ui for FontFeature (tooling/Copilot parity).
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:positive_phill/models/ritual_length.dart';
import 'package:positive_phill/providers/ritual_provider.dart';
import 'package:positive_phill/services/haptics_service.dart';
import 'package:positive_phill/theme.dart';

/// Countdown controls for Rescue Flow (no gamification hooks).
class RitualTimerBar extends StatelessWidget {
  const RitualTimerBar({super.key});

  static String _formatMmSs(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ritual = context.watch<RitualProvider>();

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ritual timer',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: RitualLength.values.map((len) {
                final selected = ritual.selectedLength == len;
                return ChoiceChip(
                  label: Text(len.label),
                  selected: selected,
                  onSelected: ritual.isRunning
                      ? null
                      : (_) {
                          HapticsService.feedback(FeedbackType.selection);
                          context.read<RitualProvider>().setLength(len);
                        },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _formatMmSs(ritual.remainingSeconds),
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      HapticsService.feedback(FeedbackType.selection);
                      if (ritual.isRunning) {
                        context.read<RitualProvider>().pause();
                      } else {
                        context.read<RitualProvider>().start();
                      }
                    },
                    icon: Icon(
                      ritual.isRunning ? Icons.pause : Icons.play_arrow,
                    ),
                    label: Text(ritual.isRunning ? 'Pause' : 'Start'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticsService.feedback(FeedbackType.selection);
                      context.read<RitualProvider>().reset();
                    },
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reset'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
