import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:positive_phill/models/affirmation.dart';
import 'package:positive_phill/services/affirmation_share_export_service.dart';
import 'package:positive_phill/services/haptics_service.dart';
import 'package:positive_phill/theme.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;

Future<void> showAffirmationShareSheet({
  required BuildContext context,
  required Affirmation affirmation,
  String? categoryLabel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: AppSpacing.horizontalLg,
                child: Text(
                  'Share affirmation',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Share text'),
                subtitle: const Text('Messages, email, and more'),
                onTap: () async {
                  HapticsService.feedback(FeedbackType.selection);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                  try {
                    await SharePlus.instance.share(
                      ShareParams(
                        text: AffirmationShareExportService.shareTextBody(
                          affirmation,
                        ),
                        subject: 'Daily Affirmation',
                      ),
                    );
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Share failed. Try copying instead.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('Copy affirmation'),
                onTap: () async {
                  HapticsService.feedback(FeedbackType.selection);
                  await Clipboard.setData(
                    ClipboardData(text: affirmation.text),
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Export / share image'),
                subtitle: const Text('PNG card (best effort on web)'),
                onTap: () async {
                  HapticsService.feedback(FeedbackType.selection);
                  Navigator.pop(ctx);
                  final messenger = ScaffoldMessenger.of(context);
                  final ok =
                      await AffirmationShareExportService.sharePngBestEffort(
                    context: context,
                    affirmation: affirmation,
                    categoryLabel: categoryLabel,
                  );
                  if (!context.mounted) return;
                  if (ok) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          !kIsWeb
                              ? 'Image ready to share'
                              : 'Image download started',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Could not create image — try Share text or Copy',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      );
    },
  );
}
