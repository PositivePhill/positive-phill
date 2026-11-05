import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:positive_phill/models/board_video_preset.dart';

/// Full-screen looping muted video preset for Home inspirational board.
/// Does not capture pointer events (`IgnorePointer` wraps the player).
///
/// Stays transparent (so the poster beneath shows) until playback position
/// advances, then fades in.
class BoardVideoBackground extends StatefulWidget {
  const BoardVideoBackground({
    super.key,
    required this.preset,
    this.onPlaybackUnavailable,
    this.onPresentationChanged,
  });

  /// Must not be [BoardVideoPreset.none].
  final BoardVideoPreset preset;

  /// Playback cannot continue this session (missing asset, platform or decode
  /// error). Session-only: callers must not persist a preset change for this.
  /// Always invoked from a post-frame callback.
  final VoidCallback? onPlaybackUnavailable;

  /// Surface visibility — callbacks are deferred to the next frame (never sync
  /// during init/build/dispose).
  final ValueChanged<bool>? onPresentationChanged;

  @override
  State<BoardVideoBackground> createState() => _BoardVideoBackgroundState();
}

class _BoardVideoBackgroundState extends State<BoardVideoBackground>
    with SingleTickerProviderStateMixin {
  static const Duration _fade = Duration(milliseconds: 400);

  late final AnimationController _fadeController =
      AnimationController(vsync: this, duration: _fade);
  late final CurvedAnimation _fadeOpacity =
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

  VideoPlayerController? _controller;
  bool _ready = false;
  bool _unavailable = false;
  bool _disposed = false;

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

  void _notifyPresentation(bool visible) {
    final cb = widget.onPresentationChanged;
    if (cb == null) return;
    _deferToNextFrame(() => cb(visible));
  }

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    final asset = widget.preset.bundledAssetPath();
    if (asset == null) {
      _log('no bundled asset');
      _fail();
      return;
    }

    _log('initializing asset: $asset');
    final controller = VideoPlayerController.asset(asset);
    _controller = controller;

    try {
      await controller.initialize();
      if (_disposed || !identical(controller, _controller)) return;
      await controller.setLooping(true);
      if (_disposed || !identical(controller, _controller)) return;
      await controller.setVolume(0);
      if (_disposed || !identical(controller, _controller)) return;
      controller.addListener(_onVideoTick);
      // Mount the (still transparent) player so the fade starts from zero.
      _deferToNextFrame(() => setState(() {}));
      await controller.play();
    } catch (e, st) {
      if (_disposed || !identical(controller, _controller)) return;
      _log('init failed: $e\n$st');
      _fail();
    }
  }

  void _onVideoTick() {
    final c = _controller;
    if (c == null || _disposed || _unavailable) return;
    final value = c.value;
    if (value.hasError) {
      _log('player error: ${value.errorDescription ?? "unknown"}');
      _fail();
      return;
    }
    if (!_ready &&
        value.isInitialized &&
        value.isPlaying &&
        value.position > Duration.zero) {
      _ready = true;
      _deferToNextFrame(() {
        final reduceMotion =
            MediaQuery.maybeDisableAnimationsOf(context) ?? false;
        if (reduceMotion) {
          _fadeController.value = 1;
        } else {
          unawaited(_fadeController.forward());
        }
        _notifyPresentation(true);
        _log('ready (playing)');
      });
    }
  }

  Future<void> _disposeController(VideoPlayerController c) async {
    c.removeListener(_onVideoTick);
    try {
      await c.pause();
    } catch (_) {}
    try {
      await c.dispose();
    } catch (_) {}
  }

  void _fail() {
    if (_unavailable || _disposed) return;
    _unavailable = true;
    final wasReady = _ready;
    _ready = false;
    final c = _controller;
    _controller = null;
    if (c != null) unawaited(_disposeController(c));
    final onUnavailable = widget.onPlaybackUnavailable;
    _deferToNextFrame(() {
      setState(() {});
      if (wasReady) _notifyPresentation(false);
      onUnavailable?.call();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    final c = _controller;
    _controller = null;
    if (c != null) unawaited(_disposeController(c));
    final onPres = widget.onPresentationChanged;
    if (_ready && onPres != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onPres(false));
    }
    _fadeOpacity.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (_unavailable || c == null || !c.value.isInitialized) {
      return const SizedBox.expand();
    }
    final sz = c.value.size;
    if (sz.width == 0 || sz.height == 0) {
      return const SizedBox.expand();
    }

    return IgnorePointer(
      child: FadeTransition(
        opacity: _fadeOpacity,
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
      ),
    );
  }
}
