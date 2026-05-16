import 'dart:async' show Timer, unawaited;
import 'dart:math' show max;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:positive_phill/models/affirmation.dart';
import 'package:positive_phill/models/rescue_intent.dart';
import 'package:positive_phill/providers/ritual_provider.dart';
import 'package:positive_phill/providers/tts_provider.dart';
import 'package:positive_phill/services/affirmations_service.dart';
import 'package:positive_phill/services/haptics_service.dart';
import 'package:positive_phill/services/storage_service.dart';
import 'package:positive_phill/theme.dart';
import 'package:positive_phill/widgets/affirmation_card.dart';
import 'package:positive_phill/widgets/ritual_timer_bar.dart';
import 'package:positive_phill/widgets/sanctuary_sounds_sheet.dart';

class RescueFlowScreen extends StatefulWidget {
  final RescueIntent intent;

  const RescueFlowScreen({
    super.key,
    required this.intent,
  });

  @override
  State<RescueFlowScreen> createState() => _RescueFlowScreenState();
}

class _RescueFlowScreenState extends State<RescueFlowScreen> {
  /// Minimum spacing between ritual-driven auto-advance steps (speech pacing).
  static const int _minRitualAdvanceSec = 10;

  final AffirmationsService _affirmationsService = AffirmationsService();
  final PageController _pageController = PageController();

  RitualProvider? _ritual;
  bool _ritualListenerAttached = false;

  List<Affirmation> _pack = [];
  int _currentPage = 0;
  bool _loading = true;
  String? _loadError;
  bool _readyForAutoRead = false;

  /// Mirrors [HomeScreen] debounce — coalesce swipes before [TtsProvider.speak].
  Timer? _autoReadDebounce;

  /// Periodic advance while ritual countdown is active.
  Timer? _ritualAdvanceTimer;

  bool _lastRitualRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RitualProvider>().reset();
    });
    _loadPack();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ritual ??= context.read<RitualProvider>();
    _attachRitualListenerIfNeeded();
  }

  void _attachRitualListenerIfNeeded() {
    if (_ritualListenerAttached || _ritual == null) return;
    _lastRitualRunning = _ritual!.isRunning;
    _ritual!.addListener(_onRitualRunningChanged);
    _ritualListenerAttached = true;
  }

  void _onRitualRunningChanged() {
    if (!mounted || _ritual == null) return;
    final running = _ritual!.isRunning;
    if (running == _lastRitualRunning) return;
    _lastRitualRunning = running;
    if (!running) {
      _cancelRitualAdvanceTimerOnly();
    }
  }

  Future<void> _loadPack() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final pack =
          await _affirmationsService.getSessionPack(widget.intent.category);
      if (!mounted) return;
      _autoReadDebounce?.cancel();
      _cancelRitualAdvanceTimerOnly();
      setState(() {
        _readyForAutoRead = false;
        _pack = pack;
        _loading = false;
      });
      // Arm after layout so [PageView] does not emit a phantom first-page callback.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _readyForAutoRead = true);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Could not load affirmations. Try again later.';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _autoReadDebounce?.cancel();
    _cancelRitualAdvanceTimerOnly();
    if (_ritualListenerAttached && _ritual != null) {
      _ritual!.removeListener(_onRitualRunningChanged);
    }
    _pageController.dispose();
    _ritual?.reset();
    super.dispose();
  }

  void _cancelRitualAdvanceTimerOnly() {
    _ritualAdvanceTimer?.cancel();
    _ritualAdvanceTimer = null;
  }

  /// Spacing derived from ritual length ÷ affirmation count (floor pacing ~10s min).
  int _advanceIntervalSeconds(RitualProvider ritual) {
    final n = _pack.length;
    if (n <= 0) return _minRitualAdvanceSec;
    final raw = (ritual.selectedLength.seconds / n).ceil();
    return max(_minRitualAdvanceSec, raw);
  }

  void _handleRitualStarted() {
    if (!mounted || _pack.isEmpty) return;
    _cancelRitualAdvanceTimerOnly();
    _autoReadDebounce?.cancel();
    final ritual = context.read<RitualProvider>();
    final tts = context.read<TtsProvider>();
    if (_readyForAutoRead && tts.autoRead && tts.voiceEnabled) {
      unawaited(tts.speak(_pack[_currentPage].text));
    }
    _scheduleRitualAdvanceTimer(ritual);
  }

  void _handleRitualPaused() {
    _cancelRitualAdvanceTimerOnly();
    _autoReadDebounce?.cancel();
  }

  void _handleRitualReset() {
    _cancelRitualAdvanceTimerOnly();
    _autoReadDebounce?.cancel();
  }

  void _scheduleRitualAdvanceTimer(RitualProvider ritual) {
    _cancelRitualAdvanceTimerOnly();
    if (!mounted || !_readyForAutoRead || _pack.isEmpty) return;
    if (!ritual.isRunning) return;
    final secs = _advanceIntervalSeconds(ritual);
    _ritualAdvanceTimer = Timer.periodic(Duration(seconds: secs), (_) {
      if (!mounted) return;
      if (!context.read<RitualProvider>().isRunning) {
        _cancelRitualAdvanceTimerOnly();
        return;
      }
      unawaited(_advanceRitualStep());
    });
  }

  Future<void> _advanceRitualStep() async {
    if (!mounted || !context.read<RitualProvider>().isRunning) return;
    if (!_readyForAutoRead || _pack.isEmpty) return;

    if (_pack.length == 1) {
      _debouncedSpeakForPage(0);
      return;
    }

    final next = (_currentPage + 1) % _pack.length;
    await _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOut,
    );
  }

  /// Shared debounced speech used by manual swipe and ritual auto-advance.
  void _debouncedSpeakForPage(int index) {
    _autoReadDebounce?.cancel();
    if (!_readyForAutoRead || _pack.isEmpty) return;
    final tts = context.read<TtsProvider>();
    if (!tts.autoRead || !tts.voiceEnabled) return;

    _autoReadDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      if (index < 0 || index >= _pack.length) return;
      unawaited(tts.speak(_pack[index].text));
    });
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _debouncedSpeakForPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final category = widget.intent.category;

    return AnimatedBuilder(
      animation: StorageService.textBacklightEnabled,
      builder: (context, _) {
        final textBacklight = StorageService.textBacklightEnabled.value;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.intent.displayTitle,
              style: TextStyle(color: colorScheme.onSurface),
            ),
            leading: IconButton(
              icon: Icon(Icons.close, color: colorScheme.onSurface),
              onPressed: () {
                context.read<RitualProvider>().pause();
                context.pop();
              },
            ),
          ),
          body: SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            _loadError!,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(
                              AppSpacing.lg,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  widget.intent.supportLine,
                                  textAlign: TextAlign.center,
                                  style: textTheme.titleSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(
                                  height: AppSpacing.md,
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    IconButton(
                                      tooltip: 'Sanctuary sounds',
                                      padding: EdgeInsets.zero,
                                      visualDensity:
                                          VisualDensity.compact,
                                      constraints: const BoxConstraints(
                                        minWidth: 40,
                                        minHeight: 40,
                                      ),
                                      icon:
                                          Icon(Icons.graphic_eq_rounded,
                                              color:
                                                  colorScheme.primary),
                                      onPressed: () {
                                        HapticsService.feedback(
                                            FeedbackType.selection);
                                        showSanctuarySoundsSheet(
                                            context);
                                      },
                                    ),
                                    Expanded(
                                      child: RitualTimerBar(
                                        onRitualStarted:
                                            _handleRitualStarted,
                                        onRitualPaused:
                                            _handleRitualPaused,
                                        onRitualReset:
                                            _handleRitualReset,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: AppSpacing.lg,
                                ),
                                if (_pack.isEmpty)
                                  Text(
                                    'No affirmations in this category yet.',
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  )
                                else ...[
                                  SizedBox(
                                    height: 300,
                                    child: ScrollConfiguration(
                                      behavior: const RescueScrollBehavior(),
                                      child: PageView.builder(
                                        controller: _pageController,
                                        itemCount: _pack.length,
                                        onPageChanged: _onPageChanged,
                                        itemBuilder: (context, index) {
                                          return AffirmationCard(
                                            affirmation: _pack[index],
                                            textBacklightEnabled: textBacklight,
                                            shareSubtitle: category.displayName,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: AppSpacing.sm,
                                  ),
                                  Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(
                                        _pack.length,
                                        (i) => Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _currentPage == i
                                                ? colorScheme.primary
                                                : colorScheme.outline
                                                    .withValues(
                                                    alpha: 0.3,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
          ),
        );
      },
    );
  }
}

/// Mouse/trackpad can drag [PageView] on desktop web; touch unchanged.
class RescueScrollBehavior extends MaterialScrollBehavior {
  const RescueScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        ...super.dragDevices,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
