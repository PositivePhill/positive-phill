import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:positive_phill/models/sanctuary_soundscape.dart';
import 'package:positive_phill/providers/sanctuary_audio_provider.dart';
import 'package:positive_phill/services/haptics_service.dart';
import 'package:positive_phill/theme.dart';

Future<void> showSanctuarySoundsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final bottomInset = MediaQuery.paddingOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : AppSpacing.sm),
        child: const SanctuarySoundsSheet(),
      );
    },
  );
}

class SanctuarySoundsSheet extends StatelessWidget {
  const SanctuarySoundsSheet({super.key});

  static int _crossAxisCount(double width) {
    if (width >= 640) return 3;
    if (width >= 420) return 2;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final sanctuary = context.watch<SanctuaryAudioProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = _crossAxisCount(w);
        const spacing = 10.0;
        final usable = (w - AppSpacing.lg * 2 - spacing * (cols - 1)).clamp(120.0, double.infinity);
        final tileW = usable / cols;
        final childAspectRatio = (tileW / 88).clamp(0.95, 1.35);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sanctuary Sounds',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Ambient loops — tap to play.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: SanctuarySoundscape.values.length,
                itemBuilder: (context, index) {
                  final sound = SanctuarySoundscape.values[index];
                  final selected = sanctuary.selectedSoundscape == sound;
                  return Material(
                    color: selected
                        ? colorScheme.primaryContainer.withValues(alpha: 0.65)
                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () async {
                        await HapticsService.feedback(FeedbackType.selection);
                        if (!context.mounted) return;
                        await context.read<SanctuaryAudioProvider>().play(sound);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            Text(
                              sound.emoji,
                              style: const TextStyle(fontSize: 26),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                sound.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.labelLarge?.copyWith(
                                  color: selected
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurface,
                                  fontWeight:
                                      selected ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: sanctuary.isPlaying
                    ? () async {
                        await HapticsService.feedback(FeedbackType.selection);
                        if (!context.mounted) return;
                        await context.read<SanctuaryAudioProvider>().stop();
                      }
                    : null,
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Stop playback'),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(Icons.volume_down_rounded,
                      color: colorScheme.primary, size: 22),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: sanctuary.volume.clamp(0.0, 1.0),
                        min: 0,
                        max: 1,
                        divisions: 20,
                        label: '${(sanctuary.volume * 100).round()}%',
                        onChanged: (v) =>
                            context.read<SanctuaryAudioProvider>().setVolume(v),
                      ),
                    ),
                  ),
                  Icon(Icons.volume_up_rounded,
                      color: colorScheme.primary, size: 22),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
