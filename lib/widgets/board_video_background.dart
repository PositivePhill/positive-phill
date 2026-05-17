import 'dart:async';

import 'package:flutter/foundation.dart';
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

  /// Clear persisted preset — always invoked from a post-frame callback.
  final VoidCallback? onFatalError;

  /// Surface visibility — callbacks are deferred to the next frame (never sync
  /// during init/build/dispose).
  final ValueChanged<bool>? onPresentationChanged;

  @override
  State<BoardVideoBackground> createState() => _BoardVideoBackgroundState();
}

class _BoardVideoBackgroundState extends State<BoardVideoBackground> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _fatalClearScheduled = false;
  bool _errorCleanedUp = false;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[BoardVideo ${widget.preset.name}] $message');
    }
  }

  void _deferToNextFrame(void Function() fn) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      fn();
    });
  }

  void _scheduleFatalClear() {
    if (_fatalClearScheduled) return;
    _fatalClearScheduled = true;
    final onFatal = widget.onFatalError;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      onFatal?.call();
    });
  }

  void _notifyPresentation(bool visible) {
    final cb = widget.onPresentationChanged;
    if (cb == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      cb(visible);
    });
  }

  @override
  void initState() {
    super.initState();
    print(
      '[board-video] init asset=${widget.preset.bundledAssetPath()}',
    );
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    final asset = widget.preset.bundledAssetPath();
    if (asset == null) {
      _log('no bundled asset — scheduling preset clear');
      _scheduleFatalClear();
      return;
    }

    _log('initializing asset: $asset');
    final controller = VideoPlayerController.asset(asset);
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) return;
      await controller.setLooping(true);
      await controller.setVolume(0);
      controller.addListener(_onVideoTick);

      await controller.play();

      if (!mounted) return;
      _deferToNextFrame(() {
        setState(() => _ready = true);
        _notifyPresentation(true);
        _log('ready (playing)');
      });
    } catch (e, st) {
      _log('init failed: $e\n$st');
      try {
        await controller.dispose();
      } catch (_) {}
      _controller = null;
      if (!mounted) return;
      _deferToNextFrame(() {
        setState(() => _ready = false);
        _scheduleFatalClear();
      });
    }
  }

  void _onVideoTick() {
    final c = _controller;
    if (c == null || !mounted || _fatalClearScheduled || _errorCleanedUp) {
      return;
    }
    if (c.value.hasError) {
      _log(
        'player error: ${c.value.errorDescription ?? "unknown"}',
      );
      _errorCleanedUp = true;
      unawaited(_failCleanupAfterError());
    }
  }

  Future<void> _failCleanupAfterError() async {
    final c = _controller;
    _controller = null;
    if (c == null) return;
    c.removeListener(_onVideoTick);
    try {
      await c.pause();
      await c.dispose();
    } catch (_) {}

    if (!mounted) return;
    _deferToNextFrame(() {
      setState(() => _ready = false);
      _notifyPresentation(false);
      _scheduleFatalClear();
    });
  }

  @override
  void dispose() {
    final c = _controller;
    _controller = null;
    final onPres = widget.onPresentationChanged;
    if (c != null) {
      c.removeListener(_onVideoTick);
      unawaited(() async {
        try {
          await c.dispose();
        } catch (_) {}
      }());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onPres?.call(false);
    });
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
