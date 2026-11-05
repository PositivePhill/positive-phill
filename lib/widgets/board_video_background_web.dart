import 'dart:async';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:positive_phill/models/board_video_preset.dart';

/// Full-screen looping muted video preset for Home inspirational board.
/// Does not capture pointer events (`IgnorePointer` wraps the player).
///
/// The `<video>` stays fully transparent (so the poster beneath shows) until
/// playback has advanced past its first frame, then fades in via CSS.
class BoardVideoBackground extends StatefulWidget {
  const BoardVideoBackground({
    super.key,
    required this.preset,
    this.onPlaybackUnavailable,
    this.onPresentationChanged,
  });

  /// Must not be [BoardVideoPreset.none].
  final BoardVideoPreset preset;

  /// Playback cannot continue this session (missing asset, network or decode
  /// error). Session-only: callers must not persist a preset change for this.
  /// Always invoked from a post-frame callback.
  final VoidCallback? onPlaybackUnavailable;

  /// Surface visibility — callbacks are deferred to the next frame (never sync
  /// during init/build/dispose).
  final ValueChanged<bool>? onPresentationChanged;

  @override
  State<BoardVideoBackground> createState() => _BoardVideoBackgroundState();
}

class _BoardVideoBackgroundState extends State<BoardVideoBackground> {
  static const int _fadeMs = 400;

  /// `HTMLMediaElement.HAVE_CURRENT_DATA`.
  static const int _haveCurrentData = 2;

  late final String _viewType;

  final List<StreamSubscription<html.Event>> _subs = [];

  bool _factoryRegistered = false;
  bool _presenting = false;
  bool _unavailable = false;
  bool _disposed = false;
  html.VideoElement? _video;

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
    // Media events can arrive while the app is idle; without a frame the
    // callback (and the session fallback it reports) would never run.
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _notifyPresentation(bool visible) {
    final cb = widget.onPresentationChanged;
    if (cb == null) return;
    _deferToNextFrame(() => cb(visible));
  }

  Uri _resolvedDocumentBase() {
    final raw = html.document.baseUri;
    if (raw == null) {
      throw StateError('document.baseUri is null');
    }
    var base = Uri.parse(raw);
    final path = base.path;
    if (path.isNotEmpty && !path.endsWith('/')) {
      base = base.replace(path: '$path/');
    }
    return base;
  }

  bool get _prefersReducedMotion {
    try {
      return html.window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    } catch (_) {
      return false;
    }
  }

  void _registerFactory(String src) {
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      // Muted + inline must be set before `src` for iOS/Safari autoplay.
      final video = html.VideoElement()
        ..muted = true
        ..loop = true
        ..autoplay = true
        ..controls = false
        ..preload = 'auto';
      video
        ..setAttribute('muted', '')
        ..setAttribute('playsinline', '')
        ..setAttribute('webkit-playsinline', '')
        ..setAttribute('disablepictureinpicture', '')
        ..setAttribute('disableremoteplayback', '')
        ..setAttribute('aria-hidden', 'true');

      video.style
        ..objectFit = 'cover'
        ..width = '100%'
        ..height = '100%'
        ..pointerEvents = 'none'
        ..border = '0'
        ..opacity = '0'
        ..transition =
            _prefersReducedMotion ? 'none' : 'opacity ${_fadeMs}ms ease';

      if (_disposed || _unavailable) return video;
      _video = video;

      _subs.add(video.onPlaying.listen((_) => _maybePresent(video)));
      _subs.add(video.onTimeUpdate.listen((_) => _maybePresent(video)));
      _subs.add(
        video.onError.listen((_) {
          final err = video.error;
          _log('media error code=${err?.code} ${err?.message ?? ''}');
          _fail();
        }),
      );

      video.src = src;
      _startPlayback(video);
      return video;
    });
  }

  void _startPlayback(html.VideoElement video) {
    video.play().then<void>(
      (_) {},
      onError: (Object e) {
        if (_disposed || _unavailable || !identical(video, _video)) return;
        final name = e is html.DomException ? e.name : '';
        if (name == 'NotAllowedError') {
          // Autoplay policy refusal: keep the poster, keep the preference.
          _log('autoplay not allowed — poster stays');
          return;
        }
        if (name == 'AbortError') return;
        _log('play() rejected: $e');
        _fail();
      },
    );
  }

  /// Fade in only once playback has advanced, which proves a frame is decoded.
  void _maybePresent(html.VideoElement video) {
    if (_disposed || _unavailable || _presenting) return;
    if (!identical(video, _video)) return;
    if (video.paused ||
        video.readyState < _haveCurrentData ||
        video.currentTime <= 0) {
      return;
    }
    _presenting = true;
    video.style.opacity = '1';
    _log('presenting');
    _notifyPresentation(true);
  }

  void _teardownVideo() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();

    final v = _video;
    _video = null;
    if (v != null) {
      try {
        v.pause();
        v.removeAttribute('src');
        v.load();
      } catch (_) {}
    }
  }

  void _fail() {
    if (_unavailable || _disposed) return;
    _unavailable = true;
    final wasPresenting = _presenting;
    _presenting = false;
    _teardownVideo();
    final onUnavailable = widget.onPlaybackUnavailable;
    _deferToNextFrame(() {
      setState(() {});
      if (wasPresenting) _notifyPresentation(false);
      onUnavailable?.call();
    });
  }

  @override
  void initState() {
    super.initState();
    _viewType = 'board-video-${identityHashCode(this)}';

    final asset = widget.preset.bundledAssetPath();
    _log('init asset=$asset');

    if (asset == null) {
      _fail();
      return;
    }

    try {
      final src = _resolvedDocumentBase().resolve('assets/$asset').toString();
      _log('resolved src=$src');
      _registerFactory(src);
      _factoryRegistered = true;
    } catch (e, st) {
      _log('init failed: $e\n$st');
      _fail();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _teardownVideo();

    final onPres = widget.onPresentationChanged;
    if (_presenting && onPres != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onPres(false));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_factoryRegistered || _unavailable) {
      return const SizedBox.expand();
    }

    return IgnorePointer(
      child: ClipRect(
        child: SizedBox.expand(
          child: HtmlElementView(viewType: _viewType),
        ),
      ),
    );
  }
}
