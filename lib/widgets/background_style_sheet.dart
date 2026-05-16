import 'package:flutter/material.dart';
import 'package:positive_phill/models/background_gradient_preset.dart';
import 'package:positive_phill/models/board_video_preset.dart';
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
        builder: (modalCtx, setModalState) {
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
                    'Video shows first when picked, then your photo, then a gradient. All muted loops on Home.',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AnimatedBuilder(
                    animation: StorageService.boardVideoPreset,
                    builder: (context, _) {
                      final videoSelected = StorageService.boardVideoPreset.value;
                      final maxH = MediaQuery.sizeOf(context).height * 0.68;
                      return ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: maxH),
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            Text(
                              'Video background',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            for (final v in BoardVideoPreset.values)
                              if (v != BoardVideoPreset.none)
                                ListTile(
                                  selected: videoSelected == v,
                                  leading: Icon(
                                    Icons.movie_filter_outlined,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                  title: Text(v.displayName),
                                  subtitle: const Text(
                                    'Muted looping video on Home',
                                  ),
                                  trailing: videoSelected == v
                                      ? Icon(
                                          Icons.check,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        )
                                      : null,
                                  onTap: () async {
                                    HapticsService.feedback(
                                        FeedbackType.selection);
                                    await storage.setBoardVideoPreset(v);
                                  },
                                ),
                            ListTile(
                              leading: Icon(
                                Icons.videocam_off_outlined,
                                color:
                                    Theme.of(context).colorScheme.primary,
                              ),
                              title: const Text('Clear video background'),
                              onTap: () async {
                                HapticsService.feedback(
                                    FeedbackType.selection);
                                await storage.setBoardVideoPreset(
                                    BoardVideoPreset.none,
                                );
                              },
                            ),
                            const Divider(height: AppSpacing.xl),
                            Text(
                              'Gradient',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            for (final preset in BackgroundGradientPreset.values)
                              ListTile(
                                selected: selected == preset,
                                title: Text(preset.displayName),
                                trailing: selected == preset
                                    ? Icon(
                                        Icons.check,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      )
                                    : null,
                                onTap: () async {
                                  HapticsService.feedback(
                                      FeedbackType.selection);
                                  await storage
                                      .setBackgroundGradientPreset(preset);
                                  if (!modalCtx.mounted) return;
                                  setModalState(() => selected = preset);
                                },
                              ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(
                                  Icons.add_photo_alternate_outlined),
                              title: const Text('Use my photo'),
                              subtitle:
                                  const Text('Choose from your gallery'),
                              onTap: () async {
                                HapticsService.feedback(
                                    FeedbackType.selection);
                                Navigator.pop(ctx);
                                await onPickImage();
                              },
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
    },
  );
}
