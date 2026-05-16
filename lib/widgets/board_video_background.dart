import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:positive_phill/models/board_video_preset.dart';

/// Full-screen looping muted video preset for Home inspirational board.
/// Does not capture pointer events (`IgnorePointer` wraps the player).
class BoardVideoBackground extends StatefulWidget {
  const BoardVideoBackground({
    super.key,
    required this.preset,
    this.onFatalError,
    this.onPresentationChanged,
  });

  /// Must not be [BoardVideoPreset.none].
  final BoardVideoPreset preset;

  /// Called after init/play failure or decode error — clear persisted preset.
  final VoidCallback? onFatalError;

  /// Called when the surface becomes visible (`true`) or on dispose (`false`).
  final ValueChanged<bool>? onPresentationChanged;

  @override
  State<BoardVideoBackground> createState() => _BoardVideoBackgroundState();
}

class _BoardVideoBackgroundState extends State<BoardVideoBackground> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _fatalReported = false;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    final asset = widget.preset.bundledAssetPath();
    if (asset == null) {
      widget.onFatalError?.call();
      return;
    }
    final controller = VideoPlayerController.asset(asset);
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      await controller.setLooping(true);
      await controller.setVolume(0);
      controller.addListener(_onVideoTick);

      widget.onPresentationChanged?.call(false);
      await controller.play();

      if (!mounted) return;
      setState(() => _ready = true);
      widget.onPresentationChanged?.call(true);
    } catch (e, st) {
      debugPrint('BoardVideoBackground init failed: $e\n$st');
      await controller.dispose();
      _controller = null;
      if (mounted) {
        setState(() => _ready = false);
      }
      widget.onFatalError?.call();
    }
  }

  void _onVideoTick() {
    final c = _controller;
    if (c == null || !mounted || _fatalReported) return;
    if (c.value.hasError) {
      debugPrint(
          'BoardVideoBackground error: ${c.value.errorDescription ?? "unknown"}');
      _fatalReported = true;
      unawaited(_failCleanup());
      widget.onFatalError?.call();
    }
  }

  Future<void> _failCleanup() async {
    final c = _controller;
    _controller = null;
    if (c == null) return;
    c.removeListener(_onVideoTick);
    try {
      await c.pause();
      await c.dispose();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _ready = false);
    widget.onPresentationChanged?.call(false);
  }

  @override
  void dispose() {
    final c = _controller;
    _controller = null;
    if (c != null) {
      c.removeListener(_onVideoTick);
      unawaited(() async {
        try {
          await c.dispose();
        } catch (_) {}
      }());
    }
    widget.onPresentationChanged?.call(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _controller == null) {
      return const SizedBox.expand();
    }
    final c = _controller!;
    final sz = c.value.size;
    if (sz.width == 0 || sz.height == 0) {
      return const SizedBox.expand();
    }

    return IgnorePointer(
      child: ClipRect(
        child: OverflowBox(
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: sz.width,
              height: sz.height,
              child: VideoPlayer(c),
            ),
          ),
        ),
      ),
    );
  }
}
