import 'package:flutter/material.dart';
import 'package:positive_phill/models/board_video_preset.dart';

/// Full-bleed still frame for a [BoardVideoPreset], painted beneath the video
/// so Home never shows an empty backdrop while media initializes or fails.
class BoardVideoPoster extends StatelessWidget {
  const BoardVideoPoster({super.key, required this.preset});

  final BoardVideoPreset preset;

  static const Duration _fadeIn = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    final path = preset.posterAssetPath();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return ColoredBox(
      color: preset.posterPlaceholderColor,
      child: path == null
          ? const SizedBox.expand()
          : Image.asset(
              path,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              gaplessPlayback: true,
              excludeFromSemantics: true,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: reduceMotion ? Duration.zero : _fadeIn,
                  curve: Curves.easeOut,
                  child: child,
                );
              },
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.expand(),
            ),
    );
  }
}
