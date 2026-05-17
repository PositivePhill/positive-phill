/// Full-screen looping muted video preset for Home inspirational board.
///
/// On mobile/desktop uses [video_player]; on web uses a native
/// [HTMLVideoElement] ([HtmlElementView]) for reliable GitHub Pages playback.
library;

export 'board_video_background_io.dart'
    if (dart.library.html) 'board_video_background_web.dart';
