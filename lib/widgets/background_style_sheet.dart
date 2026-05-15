import 'package:flutter/material.dart';
import 'package:positive_phill/models/background_gradient_preset.dart';
import 'package:positive_phill/services/haptics_service.dart';
import 'package:positive_phill/services/storage_service.dart';
import 'package:positive_phill/theme.dart';

typedef PickBackgroundImageCallback = Future<void> Function();

Future<void> showBackgroundStyleSheet(
  BuildContext context, {
  required BackgroundGradientPreset initial,
  required PickBackgroundImageCallback onPickImage,
}) {
  final storage = StorageService();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      BackgroundGradientPreset selected = initial;
      return StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Background style',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Home screen only. Custom photo always shows when set.',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final preset in BackgroundGradientPreset.values)
                          ListTile(
                            selected: selected == preset,
                            title: Text(preset.displayName),
                            trailing: selected == preset
                                ? Icon(
                                    Icons.check,
                                    color: Theme.of(ctx).colorScheme.primary,
                                  )
                                : null,
                            onTap: () async {
                              HapticsService.feedback(FeedbackType.selection);
                              await storage.setBackgroundGradientPreset(preset);
                              setModalState(() => selected = preset);
                            },
                          ),
                        const Divider(),
                        ListTile(
                          leading:
                              const Icon(Icons.add_photo_alternate_outlined),
                          title: const Text('Use my photo'),
                          subtitle: const Text('Choose from your gallery'),
                          onTap: () async {
                            HapticsService.feedback(FeedbackType.selection);
                            Navigator.pop(ctx);
                            await onPickImage();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
