import 'dart:async' show Timer, unawaited;
import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:positive_phill/models/affirmation.dart';
import 'package:positive_phill/models/daily_quests.dart';
import 'package:positive_phill/providers/ritual_provider.dart';
import 'package:positive_phill/providers/tts_provider.dart';
import 'package:positive_phill/providers/user_provider.dart';
import 'package:positive_phill/quest_helper.dart';
import 'package:positive_phill/services/affirmations_service.dart';
import 'package:positive_phill/services/ads_service.dart';
import 'package:positive_phill/services/haptics_service.dart';
import 'package:positive_phill/theme.dart';
import 'package:positive_phill/widgets/affirmation_card.dart';
import 'package:positive_phill/widgets/celebration_animation.dart';
import 'package:positive_phill/widgets/ritual_timer_bar.dart';

class SessionFlowScreen extends StatefulWidget {
  const SessionFlowScreen({super.key});

  @override
  State<SessionFlowScreen> createState() => _SessionFlowScreenState();
}

class _SessionFlowScreenState extends State<SessionFlowScreen> {
  static const int _minGuidedAdvanceSec = 10;
  static const int _autoReadDebounceMs = 180;

  final AffirmationsService _affirmationsService = AffirmationsService();
  final AdsService _adsService = AdsService();

  List<Affirmation> _sessionPack = [];
  int _currentIndex = 0;
  bool _sessionStarted = false;
  bool _sessionCompleted = false;
  bool _showCelebration = false;
  bool _completionInFlight = false;

  RitualProvider? _ritual;
  bool _ritualListenerAttached = false;

  Timer? _autoReadDebounce;
  Timer? _guidedAdvanceTimer;

  bool _lastRitualRunning = false;

  @override
  void initState() {
    super.initState();
    _adsService.initialize();
    _adsService.loadInterstitialAd();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RitualProvider>().reset();
    });
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
      _cancelGuidedAdvanceTimerOnly();
    }
  }

  void _cancelGuidedAdvanceTimerOnly() {
    _guidedAdvanceTimer?.cancel();
    _guidedAdvanceTimer = null;
  }

  void _cancelLocalTimersOnly() {
    _autoReadDebounce?.cancel();
    _autoReadDebounce = null;
    _cancelGuidedAdvanceTimerOnly();
  }

  int _advanceIntervalSeconds(RitualProvider ritual) {
    final n = _sessionPack.length;
    if (n <= 0) return _minGuidedAdvanceSec;
    final raw = (ritual.selectedLength.seconds / n).ceil();
    return max(_minGuidedAdvanceSec, raw);
  }

  void _scheduleGuidedAdvanceTimer() {
    _cancelGuidedAdvanceTimerOnly();
    if (!mounted || _sessionPack.isEmpty || _sessionCompleted || _completionInFlight) return;
    if (_ritual == null || !_ritual!.isRunning) return;

    final secs = _advanceIntervalSeconds(_ritual!);
    _guidedAdvanceTimer = Timer.periodic(Duration(seconds: secs), (_) {
      if (!mounted) return;
      if (_sessionCompleted || _completionInFlight) {
        _cancelGuidedAdvanceTimerOnly();
        return;
      }
      if (!context.read<RitualProvider>().isRunning) {
        _cancelGuidedAdvanceTimerOnly();
        return;
      }
      _advanceGuidedStep();
    });
  }

  void _advanceGuidedStep() {
    if (!mounted ||
        !_sessionStarted ||
        _sessionPack.isEmpty ||
        _sessionCompleted ||
        _completionInFlight) {
      return;
    }
    if (_currentIndex >= _sessionPack.length - 1) {
      _cancelGuidedAdvanceTimerOnly();
      return;
    }

    setState(() => _currentIndex++);
    _debouncedSpeakForIndex(_currentIndex);
  }

  void _debouncedSpeakForIndex(int index) {
    _autoReadDebounce?.cancel();
    if (!_sessionStarted || _sessionPack.isEmpty) return;

    _autoReadDebounce = Timer(const Duration(milliseconds: _autoReadDebounceMs), () {
      if (!mounted) return;
      if (index < 0 || index >= _sessionPack.length) return;
      final tts = context.read<TtsProvider>();
      if (!tts.autoRead || !tts.voiceEnabled) return;
      unawaited(tts.speak(_sessionPack[index].text));
    });
  }

  void _handleRitualStarted() {
    if (!mounted || _sessionPack.isEmpty || _sessionCompleted || _completionInFlight) return;
    _cancelGuidedAdvanceTimerOnly();
    _autoReadDebounce?.cancel();

    final tts = context.read<TtsProvider>();
    if (tts.autoRead && tts.voiceEnabled) {
      unawaited(tts.speak(_sessionPack[_currentIndex].text));
    }
    _scheduleGuidedAdvanceTimer();
  }

  void _handleRitualPaused() {
    _cancelGuidedAdvanceTimerOnly();
    _autoReadDebounce?.cancel();
  }

  void _handleRitualReset() {
    _cancelGuidedAdvanceTimerOnly();
    _autoReadDebounce?.cancel();
  }

  @override
  void dispose() {
    _cancelLocalTimersOnly();
    if (_ritualListenerAttached && _ritual != null) {
      _ritual!.removeListener(_onRitualRunningChanged);
    }
    _ritual?.reset();
    _adsService.dispose();
    super.dispose();
  }

  Future<void> _startSessionWithCategories(List<AffirmationCategory> categories) async {
    final pack = await _affirmationsService.getSessionPackForCategories(categories);
    if (!mounted) return;
    context.read<RitualProvider>().reset();
    _cancelLocalTimersOnly();
    setState(() {
      _sessionPack = pack;
      _sessionStarted = true;
      _currentIndex = 0;
    });
  }

  void _onPopInvokedOrClose() {
    _cancelLocalTimersOnly();
    context.read<RitualProvider>().pause();
  }

  void _onNext() {
    if (_sessionCompleted || _completionInFlight) return;
    HapticsService.feedback(FeedbackType.selection);

    if (_currentIndex < _sessionPack.length - 1) {
      setState(() => _currentIndex++);
      _debouncedSpeakForIndex(_currentIndex);
    } else {
      unawaited(_completeSession());
    }
  }

  Future<void> _completeSession() async {
    if (_sessionCompleted || _completionInFlight) return;
    _completionInFlight = true;

    _cancelGuidedAdvanceTimerOnly();
    _autoReadDebounce?.cancel();
    context.read<RitualProvider>().pause();

    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.completeSession();
      if (!mounted) return;
      await completeQuest(context, QuestType.completeSession);
      if (!mounted) return;

      setState(() {
        _sessionCompleted = true;
        _showCelebration = true;
      });

      if (_adsService.isInterstitialAdReady) {
        await Future.delayed(const Duration(seconds: 2));
        await _adsService.showInterstitialAd();
      }
    } finally {
      _completionInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _cancelLocalTimersOnly();
          context.read<RitualProvider>().pause();
        }
      },
      child: CelebrationAnimation(
        trigger: _showCelebration,
        child: Scaffold(
        appBar: AppBar(
          title: Text('Daily Session', style: TextStyle(color: colorScheme.onSurface)),
          leading: IconButton(
            icon: Icon(Icons.close, color: colorScheme.onSurface),
            onPressed: () {
              context.pop();
            },
          ),
        ),
        body: SafeArea(
          child: !_sessionStarted
              ? CategorySelection(onConfirm: _startSessionWithCategories)
              : _sessionCompleted
                  ? CompletionScreen(onDone: () => context.pop())
                  : SessionContent(
                      affirmation: _sessionPack[_currentIndex],
                      currentIndex: _currentIndex,
                      totalCount: _sessionPack.length,
                      onNext: _onNext,
                      pacingBar: RitualTimerBar(
                        title: 'Session timer',
                        subtitle: 'Starts guided pacing — advance through each card.',
                        onRitualStarted: _handleRitualStarted,
                        onRitualPaused: _handleRitualPaused,
                        onRitualReset: _handleRitualReset,
                      ),
                    ),
        ),
      ),
      ),
    );
  }
}

class CategorySelection extends StatefulWidget {
  final Future<void> Function(List<AffirmationCategory>) onConfirm;

  const CategorySelection({super.key, required this.onConfirm});

  @override
  State<CategorySelection> createState() => _CategorySelectionState();
}

class _CategorySelectionState extends State<CategorySelection> {
  final Set<AffirmationCategory> _selected = {};

  void _toggle(AffirmationCategory c) {
    setState(() {
      if (_selected.contains(c)) {
        _selected.remove(c);
      } else {
        _selected.add(c);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Your Focus',
                style: textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Select one or more categories for your 2-3 minute session',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 280,
                    mainAxisExtent: 110,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                  ),
                  itemCount: AffirmationCategory.values.length,
                  itemBuilder: (context, index) {
                    final category = AffirmationCategory.values[index];
                    final isSelected = _selected.contains(category);
                    return CategoryCard(
                      category: category,
                      isSelected: isSelected,
                      onTap: () => _toggle(category),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _selected.isEmpty
                      ? null
                      : () async {
                          await widget.onConfirm(_selected.toList());
                        },
                  icon: Icon(Icons.play_arrow, color: colorScheme.onPrimary),
                  label: Text('Start Session',
                      style: TextStyle(color: colorScheme.onPrimary)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md),
                    backgroundColor: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final AffirmationCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
   final textTheme = Theme.of(context).textTheme;

    final borderColor = isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.2);
    final bg = isSelected ? colorScheme.secondaryContainer : colorScheme.primaryContainer;
    final textColor = isSelected ? colorScheme.onSecondaryContainer : colorScheme.onPrimaryContainer;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Stack(
          children: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(category.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      category.displayName,
                      style: textTheme.titleMedium?.copyWith(
                          color: textColor, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(Icons.check_circle,
                    color: colorScheme.primary, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

class SessionContent extends StatelessWidget {
  final Affirmation affirmation;
  final int currentIndex;
  final int totalCount;
  final VoidCallback onNext;
  final RitualTimerBar pacingBar;

  const SessionContent({
    super.key,
    required this.affirmation,
    required this.currentIndex,
    required this.totalCount,
    required this.onNext,
    required this.pacingBar,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
   final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          pacingBar,
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value: (currentIndex + 1) / totalCount,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.secondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${currentIndex + 1} of $totalCount',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          AffirmationCard(
            affirmation: affirmation,
            showActions: true,
            shareSubtitle: affirmation.categories.isNotEmpty
                ? affirmation.categories.first.displayName
                : null,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                backgroundColor: colorScheme.primary,
              ),
              child: Text(
                currentIndex < totalCount - 1 ? 'Next' : 'Complete',
                style: TextStyle(
                  fontSize: 18,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CompletionScreen extends StatelessWidget {
  final VoidCallback onDone;

  const CompletionScreen({super.key, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
   final textTheme = Theme.of(context).textTheme;
    final userProvider = context.watch<UserProvider>();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '🎉',
            style: const TextStyle(fontSize: 80),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Session Complete!',
            style: textTheme.headlineLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nice work! You earned:',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('⭐', style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '+20 XP',
                      style: textTheme.headlineMedium?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🔥', style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${userProvider.progress.streak} Day Streak',
                      style: textTheme.headlineMedium?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                backgroundColor: colorScheme.primary,
              ),
              child: Text('Done', style: TextStyle(fontSize: 18, color: colorScheme.onPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}
