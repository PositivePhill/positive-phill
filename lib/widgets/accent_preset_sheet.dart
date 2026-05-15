import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:positive_phill/models/accent_preset.dart';
import 'package:positive_phill/providers/theme_provider.dart';
import 'package:positive_phill/services/haptics_service.dart';
import 'package:positive_phill/theme.dart';

Future<void> showAccentPresetSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final colorScheme = Theme.of(ctx).colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Accent color',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: AccentPreset.values.length,
                itemBuilder: (_, i) {
                  final preset = AccentPreset.values[i];
                  return InkWell(
                    onTap: () async {
                      HapticsService.feedback(FeedbackType.selection);
                      await context.read<ThemeProvider>().setAccentPreset(preset);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: preset.seedColor,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          preset.displayName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
