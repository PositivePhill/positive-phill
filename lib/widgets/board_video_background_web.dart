import 'dart:async';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  late final String _viewType;

  final List<StreamSubscription<html.Event>> _subs = [];

  bool _factoryRegistered = false;
  bool _presenting = false;
  bool _fatalClearScheduled = false;
  bool _errorCleanedUp = false;
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

  void _registerFactory(String src) {
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final video = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..loop = true
        ..controls = false;

      video.setAttribute('playsinline', 'true');

      video.style
        ..objectFit = 'cover'
        ..width = '100%'
        ..height = '100%'
        ..pointerEvents = 'none'
        ..border = '0';

      video.src = src;
      _video = video;

      void markReady(html.Event? _) {
        if (!mounted || _presenting || _errorCleanedUp) return;
        _presenting = true;
        _deferToNextFrame(() {
          if (!mounted) return;
          setState(() {});
          _notifyPresentation(true);
          _log('ready (native <video>)');
        });
      }

      _subs.add(video.onLoadedData.listen(markReady));
      _subs.add(video.onCanPlay.listen(markReady));
      _subs.add(video.onCanPlayThrough.listen(markReady));
      _subs.add(video.onPlay.listen(markReady));

      Future<void> fail(Object? error) async {
        if (_errorCleanedUp) return;
        final message = error ??
            video.error?.message ??
            video.error?.code.toString() ??
            'unknown';
        _log('error: $message');
        await _failCleanupAfterError();
      }

      _subs.add(
        video.onError.listen((_) {
          unawaited(fail(video.error));
        }),
      );

      unawaited(
        video.play().catchError((Object e) => fail(e)),
      );

      return video;
    });
  }

  Future<void> _failCleanupAfterError() async {
    if (_errorCleanedUp) return;
    _errorCleanedUp = true;

    for (final s in _subs) {
      await s.cancel();
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

    if (!mounted) return;
    _deferToNextFrame(() {
      if (!mounted) return;
      setState(() {});
      _notifyPresentation(false);
      _scheduleFatalClear();
    });
  }

  @override
  void initState() {
    super.initState();
    _viewType = 'board-video-${identityHashCode(this)}';

    final asset = widget.preset.bundledAssetPath();
    _log('init asset=$asset');

    if (asset == null) {
      _log('no bundled asset — scheduling preset clear');
      _scheduleFatalClear();
      return;
    }

    try {
      final src =
          _resolvedDocumentBase().resolve('assets/$asset').toString();
      _log('resolved src=$src');
      _registerFactory(src);
      _factoryRegistered = true;
    } catch (e, st) {
      _log('init failed: $e\n$st');
      _scheduleFatalClear();
    }
  }

  @override
  void dispose() {
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

    final onPres = widget.onPresentationChanged;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onPres?.call(false);
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_factoryRegistered || _errorCleanedUp) {
      return const SizedBox.expand();
    }

    return IgnorePointer(
      child: ClipRect(
        child: Opacity(
          opacity: _presenting ? 1 : 0,
          child: SizedBox.expand(
            child: HtmlElementView(
              viewType: _viewType,
            ),
          ),
        ),
      ),
    );
  }
}
