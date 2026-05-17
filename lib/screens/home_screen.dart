import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:positive_phill/models/affirmation.dart';
import 'package:positive_phill/models/board_video_preset.dart';
import 'package:positive_phill/models/background_gradient_preset.dart';
import 'package:positive_phill/models/daily_quests.dart';
import 'package:positive_phill/nav.dart';
import 'package:positive_phill/providers/tts_provider.dart';
import 'package:positive_phill/providers/user_provider.dart';
import 'package:positive_phill/quest_helper.dart';
import 'package:positive_phill/services/affirmations_service.dart';
import 'package:positive_phill/platform/background_image.dart';
import 'package:positive_phill/services/storage_service.dart';
import 'package:positive_phill/services/ads_service.dart';
import 'package:positive_phill/services/haptics_service.dart';
import 'package:positive_phill/theme.dart';
import 'package:positive_phill/widgets/affirmation_card.dart';
import 'package:positive_phill/widgets/daily_fortune_card.dart';
import 'package:positive_phill/widgets/daily_quest_card.dart';
import 'package:positive_phill/widgets/level_up_toast.dart';
import 'package:positive_phill/widgets/mood_bar.dart';
import 'package:positive_phill/widgets/streak_display.dart';
import 'package:positive_phill/widgets/sos_entry_card.dart';
import 'package:positive_phill/widgets/streak_heatmap.dart';
import 'package:positive_phill/widgets/xp_progress_bar.dart';
import 'package:positive_phill/widgets/board_video_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AffirmationsService _affirmationsService = AffirmationsService();
  final AdsService _adsService = AdsService();
  final PageController _pageController = PageController();

  List<Affirmation> _currentPack = [];
  String _dailyTheme = '';
  AffirmationCategory? _selectedCategory;
  int _currentPage = 0;
  bool _zenMode = false;
  bool _readyForAutoRead = false;

  /// Drives readability scrim while a board video layer is actually presenting.
  final ValueNotifier<bool> _boardVideoPresenting = ValueNotifier<bool>(false);

  // Debounce timer for auto-read on PageView swipes. Coalesces fast swipes
  // and gives TtsProvider time to settle between page changes.
  Timer? _autoReadDebounce;

  // Mood state (local — persisted via StorageService)
  DailyMood? _selectedMood;

  ValueNotifier<int>? _levelUpNotifier;

  @override
  void initState() {
    super.initState();
    _adsService.initialize();
    _adsService.loadRewardedAd();
    _adsService.loadInterstitialAd();
    unawaited(_loadDailyContent());
    unawaited(_loadCustomBackground());
    unawaited(_loadZenMode());
    unawaited(_loadMood());
    unawaited(_loadBackgroundPreset());
    // Board video notifier is hydrated in main; re-read once post-frame so a
    // late prefs sync cannot leave Home stuck on none (no SharedPreferences reads in build).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadBoardVideoPreset());
    });
    _listenForLevelUp();
  }

  // ── Level-up toast ───────────────────────────────────────────────────────

  void _listenForLevelUp() {
    // Listen after the first frame so UserProvider is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final n = context.read<UserProvider>().levelUpNotifier;
      _levelUpNotifier = n;
      n.addListener(_onLevelUp);
    });
  }

  void _onLevelUp() {
    if (!mounted) return;
    final level = context.read<UserProvider>().levelUpNotifier.value;
    if (level > 0) {
      LevelUpToast.show(context, level);
    }
  }

  @override
  void dispose() {
    _levelUpNotifier?.removeListener(_onLevelUp);
    _autoReadDebounce?.cancel();
    _pageController.dispose();
    _adsService.dispose();
    _boardVideoPresenting.dispose();
    super.dispose();
  }

  // ── Background ───────────────────────────────────────────────────────────

  Future<void> _loadCustomBackground() async {
    final storage = StorageService();
    final path = await storage.getCustomBackgroundPath();
    final web = await storage.getCustomBackgroundWeb();
    await storage.getCustomBackgroundAlignment();
    await storage.getTextBacklightEnabled();
    if (mounted) {
      StorageService.customBackgroundPath.value = path;
      StorageService.customBackgroundWeb.value = web;
    }
  }

  Future<void> _loadBackgroundPreset() async {
    await StorageService().getBackgroundGradientPreset();
  }

  Future<void> _loadBoardVideoPreset() async {
    final preset = await StorageService().getBoardVideoPreset();
    StorageService.boardVideoPreset.value = preset;
  }

  /// Readable header actions on bright video/image/gradient backdrops.
  Widget _homeHeaderIconButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    Color? iconColor,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgAlpha = isDark ? 0.4 : 0.78;
    return Material(
      color: scheme.surface.withValues(alpha: bgAlpha),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      surfaceTintColor: Colors.transparent,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon),
        color: iconColor ?? scheme.onSurface,
      ),
    );
  }

  /// Text shadows for labels on photo/video/scrimmed backdrops (and optional user text backlight).
  List<Shadow>? _readabilityTextShadows({
    required bool needsReadabilityScrim,
    required bool textBacklight,
    required Brightness brightness,
  }) {
    if (!needsReadabilityScrim && !textBacklight) return null;
    if (needsReadabilityScrim) {
      if (brightness == Brightness.light) {
        return [
          Shadow(
            color: Colors.black.withValues(alpha: 0.58),
            offset: const Offset(0, 1),
            blurRadius: 6,
          ),
          Shadow(
            color: Colors.black.withValues(alpha: 0.22),
            offset: Offset.zero,
            blurRadius: 12,
          ),
        ];
      }
      return [
        Shadow(
          color: Colors.black.withValues(alpha: 0.72),
          offset: const Offset(0, 1),
          blurRadius: 3,
        ),
      ];
    }
    return [
      Shadow(
        color: Colors.black.withValues(alpha: 0.6),
        offset: const Offset(1, 1),
        blurRadius: 4,
      ),
    ];
  }

  // ── Zen mode ─────────────────────────────────────────────────────────────

  Future<void> _loadZenMode() async {
    final enabled = await StorageService().getZenModeEnabled();
    if (mounted) setState(() => _zenMode = enabled);
  }

  Future<void> _toggleZenMode() async {
    HapticsService.feedback(FeedbackType.selection);
    final next = !_zenMode;
    setState(() => _zenMode = next);
    await StorageService().setZenModeEnabled(next);
    // Quest: entering focus mode
    if (next && mounted) {
      await completeQuest(context, QuestType.enteredFocusMode);
    }
  }

  // ── Mood ─────────────────────────────────────────────────────────────────

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadMood() async {
    final storage = StorageService();
    final savedDate = await storage.getDailyMoodDate();
    final savedMood = await storage.getDailyMoodValue();
    if (!mounted) return;
    if (savedDate == _todayString() && savedMood != null) {
      final mood = DailyMood.values.firstWhere(
        (m) => m.name == savedMood,
        orElse: () => DailyMood.hopeful,
      );
      setState(() => _selectedMood = mood);
    }
  }

  Future<void> _onMoodSelected(DailyMood mood) async {
    HapticsService.feedback(FeedbackType.selection);
    setState(() => _selectedMood = mood);
    await StorageService().setDailyMood(mood.name, _todayString());
    // Change affirmation pack to match mood's suggested category
    await _onCategoryChanged(mood.suggestedCategory);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Showing ${mood.suggestedCategory.displayName} affirmations for your mood'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ── Affirmation content ───────────────────────────────────────────────────

  Future<void> _loadDailyContent() async {
    await AffirmationsService.preload();
    final seed = DateTime.now().millisecondsSinceEpoch;
    final pack =
        await _affirmationsService.getDailyPack(category: _selectedCategory);
    if (!mounted) return;
    setState(() {
      _dailyTheme = _affirmationsService.getRandomMessage(
          category: _selectedCategory, seed: seed);
      _currentPack = pack;
    });
    setState(() => _readyForAutoRead = true);
  }

  Future<void> _onCategoryChanged(AffirmationCategory? category) async {
    // Cancel any pending auto-read so the previous pack's text doesn't speak.
    _autoReadDebounce?.cancel();
    setState(() => _readyForAutoRead = false);
    final seed = DateTime.now().millisecondsSinceEpoch;
    final pack = await _affirmationsService.getRandomPack(
        category: category, count: 5, seed: seed);
    if (!mounted) return;
    setState(() {
      _selectedCategory = category;
      _dailyTheme =
          _affirmationsService.getRandomMessage(category: category, seed: seed);
      _currentPack = pack;
      _currentPage = 0;
    });
    _pageController.jumpToPage(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _readyForAutoRead = true);
    });
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);

    // Always cancel any pending auto-read; fast swipes coalesce to last page.
    _autoReadDebounce?.cancel();

    if (!_readyForAutoRead || _currentPack.isEmpty) return;
    final tts = context.read<TtsProvider>();
    if (!tts.autoRead || !tts.voiceEnabled) return;

    // Debounce so the previous TTS cancel callback has time to flush before
    // we issue a new speak() — fixes auto-read missing on rapid swipes.
    _autoReadDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      if (index < 0 || index >= _currentPack.length) return;
      unawaited(tts.speak(_currentPack[index].text));
    });
  }

  // ── Ads / extra packs ─────────────────────────────────────────────────────

  Future<void> _onGetMore() async {
    HapticsService.feedback(FeedbackType.selection);
    final userProvider = context.read<UserProvider>();
    if (_adsService.isRewardedAdReady) {
      final success = await _adsService.showRewardedAd((amount) {
        _loadExtraPack();
        _showSnackBar('🎉 Unlocked 5 more affirmations!');
      });
      if (!success) {
        _checkFreeExtraPack(userProvider);
      }
      _adsService.loadRewardedAd();
    } else {
      _checkFreeExtraPack(userProvider);
    }
  }

  void _checkFreeExtraPack(UserProvider userProvider) {
    if (userProvider.progress.extraPacksToday < 1) {
      _loadExtraPack();
      userProvider.incrementExtraPacks();
      _showSnackBar('✨ Free extra pack unlocked!');
    } else {
      _showSnackBar('Ad not available. Try again later!');
    }
  }

  Future<void> _loadExtraPack() async {
    final extraPack =
        await _affirmationsService.getExtraPack(category: _selectedCategory);
    if (!mounted) return;
    setState(() {
      _currentPack.addAll(extraPack);
      _pageController.animateToPage(
        _currentPack.length - 5,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onBoardVideoPresentationChanged(bool visible) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_boardVideoPresenting.value != visible) {
        _boardVideoPresenting.value = visible;
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final userProvider = context.watch<UserProvider>();
    final completedDates = userProvider.progress.completedDates;

    if (userProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: ValueListenableBuilder<BoardVideoPreset>(
        valueListenable: StorageService.boardVideoPreset,
        builder: (context, videoPreset, _) {
          if (kDebugMode && videoPreset != BoardVideoPreset.none) {
            debugPrint(
              'Home: board video preset selected = ${videoPreset.name}',
            );
          }

          if (videoPreset == BoardVideoPreset.none &&
              _boardVideoPresenting.value) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (_boardVideoPresenting.value) {
                _boardVideoPresenting.value = false;
              }
            });
          }

          return AnimatedBuilder(
            animation: Listenable.merge([
              StorageService.customBackgroundPath,
              StorageService.customBackgroundWeb,
              StorageService.customBackgroundAlignment,
              StorageService.textBacklightEnabled,
              StorageService.backgroundGradientPreset,
              _boardVideoPresenting,
            ]),
            builder: (context, _) {
              final bgPath = StorageService.customBackgroundPath.value;
              final bgWeb = StorageService.customBackgroundWeb.value;
              final align = StorageService.customBackgroundAlignment.value;
              final textBacklight = StorageService.textBacklightEnabled.value;
              final bgPreset = StorageService.backgroundGradientPreset.value;
              final videoChosen = videoPreset != BoardVideoPreset.none;

              Widget bgWidget =
                  ColoredBox(color: Theme.of(context).scaffoldBackgroundColor);
              bool hasCustomBg = false;
              if (kIsWeb) {
                if (bgWeb != null && bgWeb.isNotEmpty) {
                  try {
                    final bytes = base64Decode(bgWeb);
                    bgWidget = Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      alignment: align,
                    );
                    hasCustomBg = true;
                  } catch (_) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      unawaited(StorageService().setCustomBackgroundWeb(null));
                    });
                  }
                }
              } else {
                if (bgPath != null && bgPath.isNotEmpty) {
                  bgWidget =
                      BackgroundImageBuilder.build(bgPath, alignment: align);
                  hasCustomBg = true;
                }
              }

              if (!hasCustomBg) {
                final g =
                    bgPreset.linearGradientFor(Theme.of(context).brightness);
                if (g != null) {
                  bgWidget = Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(gradient: g),
                  );
                }
              }

              final needsReadabilityScrim =
                  hasCustomBg || (videoChosen && _boardVideoPresenting.value);
              final suppressPlainBackgroundTip = hasCustomBg || videoChosen;

              final readabilityShadows = _readabilityTextShadows(
                needsReadabilityScrim: needsReadabilityScrim,
                textBacklight: textBacklight,
                brightness: Theme.of(context).brightness,
              );
              final lightBusyHeadingColor = needsReadabilityScrim &&
                      Theme.of(context).brightness == Brightness.light
                  ? Colors.white.withValues(alpha: 0.98)
                  : null;

              return Stack(
                children: [
                  Positioned.fill(child: bgWidget),
                  if (videoChosen)
                    Positioned.fill(
                      child: BoardVideoBackground(
                        key: ValueKey('board-video-${videoPreset.name}'),
                        preset: videoPreset,
                        onFatalError: () {
                          unawaited(
                            StorageService()
                                .setBoardVideoPreset(BoardVideoPreset.none),
                          );
                        },
                        onPresentationChanged: _onBoardVideoPresentationChanged,
                      ),
                    ),
                  if (needsReadabilityScrim)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.5),
                              Colors.black.withValues(alpha: 0.72),
                            ],
                          ),
                        ),
                      ),
                    ),
                  SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final lane = w < 600
                            ? w
                            : w < 1024
                                ? 720.0
                                : w < 1440
                                    ? 840.0
                                    : 960.0;
                        return Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: lane),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // ── 1. Header ─────────────────────
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Center(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  'Positive Phill',
                                                  maxLines: 1,
                                                  softWrap: false,
                                                  overflow:
                                                      TextOverflow.visible,
                                                  style: textTheme
                                                      .headlineMedium
                                                      ?.copyWith(
                                                    color: colorScheme.primary,
                                                    fontWeight: FontWeight.bold,
                                                    shadows:
                                                        readabilityShadows,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          _homeHeaderIconButton(
                                            context: context,
                                            icon: Icons.favorite_border,
                                            onPressed: () =>
                                                context.push('/favorites'),
                                            tooltip: 'Saved Affirmations',
                                          ),
                                          _homeHeaderIconButton(
                                            context: context,
                                            icon: _zenMode
                                                ? Icons.self_improvement
                                                : Icons.self_improvement_outlined,
                                            onPressed: _toggleZenMode,
                                            iconColor: _zenMode
                                                ? colorScheme.primary
                                                : null,
                                            tooltip: _zenMode
                                                ? 'Exit Focus Mode'
                                                : 'Enter Focus Mode',
                                          ),
                                          _homeHeaderIconButton(
                                            context: context,
                                            icon: Icons.settings,
                                            onPressed: () =>
                                                context.push('/settings'),
                                            tooltip: 'Settings',
                                          ),
                                        ],
                                      ),

                                      if (!_zenMode) ...[
                                        const SizedBox(height: AppSpacing.md),
                                        SosEntryCard(
                                          textShadows: readabilityShadows,
                                        ),
                                      ],

                                      if (!_zenMode &&
                                          !suppressPlainBackgroundTip &&
                                          bgPreset ==
                                              BackgroundGradientPreset
                                                  .none) ...[
                                        const SizedBox(height: AppSpacing.sm),
                                        Material(
                                          color: colorScheme
                                              .surfaceContainerHighest
                                              .withValues(alpha: 0.92),
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.md),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.md),
                                            onTap: () {
                                              HapticsService.feedback(
                                                  FeedbackType.selection);
                                              context.push(AppRoutes.settings);
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.wallpaper_outlined,
                                                    color: colorScheme.primary,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'Make this screen yours',
                                                          style: textTheme
                                                              .titleSmall
                                                              ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: colorScheme
                                                                .onSurface,
                                                            shadows:
                                                                readabilityShadows,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 2),
                                                        Text(
                                                          'Add a background image',
                                                          style: textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                            color: colorScheme
                                                                .onSurfaceVariant,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.chevron_right,
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],

                                      // ── 2. XP + Streak (hidden in zen) ─
                                      if (!_zenMode) ...[
                                        const SizedBox(height: AppSpacing.md),
                                        XpProgressBar(
                                            progress: userProvider.progress),
                                        const SizedBox(height: AppSpacing.md),
                                        Center(
                                          child: StreakDisplay(
                                            streak:
                                                userProvider.progress.streak,
                                            textShadows: readabilityShadows,
                                            stressedBackdrop:
                                                needsReadabilityScrim,
                                          ),
                                        ),
                                      ],

                                      // ── 3. Mood bar (hidden in zen) ─────
                                      if (!_zenMode) ...[
                                        const SizedBox(height: AppSpacing.lg),
                                        MoodBar(
                                          selectedMood: _selectedMood,
                                          onMoodSelected: _onMoodSelected,
                                          textShadows: readabilityShadows,
                                          sectionTitleColor: lightBusyHeadingColor,
                                          chipElevatedSurface:
                                              needsReadabilityScrim,
                                        ),
                                      ],

                                      // ── 4. Daily fortune (hidden in zen) ─
                                      if (!_zenMode) ...[
                                        const SizedBox(height: AppSpacing.md),
                                        const DailyFortuneCard(),
                                      ],

                                      // ── 5. Daily theme quote ─────────────
                                      const SizedBox(height: AppSpacing.md),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 24, horizontal: 16),
                                        decoration: BoxDecoration(
                                          color: colorScheme.secondaryContainer,
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.lg),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            const Text('💭',
                                                style: TextStyle(fontSize: 28)),
                                            const SizedBox(
                                                height: AppSpacing.sm),
                                            AnimatedSwitcher(
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              child: Text(
                                                key: ValueKey(_dailyTheme),
                                                _dailyTheme,
                                                textAlign: TextAlign.center,
                                                style: textTheme.titleMedium
                                                    ?.copyWith(
                                                  color: colorScheme
                                                      .onSecondaryContainer,
                                                  fontStyle: FontStyle.italic,
                                                  shadows: readabilityShadows,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // ── 6. Category chips (hidden in zen) ─
                                      if (!_zenMode) ...[
                                        const SizedBox(height: AppSpacing.lg),
                                        Center(
                                          child: Text(
                                            "Today's Affirmations",
                                            style:
                                                textTheme.titleLarge?.copyWith(
                                              color: lightBusyHeadingColor ??
                                                  colorScheme.onSurface,
                                              fontWeight: FontWeight.bold,
                                              shadows: readabilityShadows,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        CategorySelector(
                                          selectedCategory: _selectedCategory,
                                          onCategoryChanged: _onCategoryChanged,
                                          elevatedChipSurface:
                                              needsReadabilityScrim,
                                        ),
                                      ] else ...[
                                        const SizedBox(height: AppSpacing.lg),
                                      ],

                                      // ── 7. Affirmation deck ───────────────
                                      const SizedBox(height: AppSpacing.md),
                                      SizedBox(
                                        height: 300,
                                        child: _currentPack.isEmpty
                                            ? Center(
                                                child: Text(
                                                  'No affirmations available',
                                                  style: textTheme.bodyMedium,
                                                ),
                                              )
                                            : ScrollConfiguration(
                                                behavior:
                                                    const AppScrollBehavior(),
                                                child: PageView.builder(
                                                  controller: _pageController,
                                                  itemCount:
                                                      _currentPack.length,
                                                  onPageChanged: _onPageChanged,
                                                  itemBuilder:
                                                      (context, index) {
                                                    return AffirmationCard(
                                                      affirmation:
                                                          _currentPack[index],
                                                      textBacklightEnabled:
                                                          textBacklight,
                                                      shareSubtitle:
                                                          _selectedCategory
                                                              ?.displayName,
                                                    );
                                                  },
                                                ),
                                              ),
                                      ),

                                      // ── Page dots ────────────────────────
                                      const SizedBox(height: AppSpacing.sm),
                                      Center(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: List.generate(
                                            _currentPack.length > 10
                                                ? 10
                                                : _currentPack.length,
                                            (i) => Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4),
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: _currentPage == i
                                                    ? colorScheme.primary
                                                    : colorScheme.outline
                                                        .withValues(alpha: 0.3),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // ── 8. Daily quests (hidden in zen) ──
                                      if (!_zenMode) ...[
                                        const SizedBox(height: AppSpacing.xl),
                                        const DailyQuestCard(),
                                      ],

                                      // ── 9. Streak heatmap (hidden in zen) ─
                                      if (!_zenMode) ...[
                                        const SizedBox(height: AppSpacing.lg),
                                        StreakHeatmap(
                                            completedDates: completedDates),
                                      ],

                                      // ── 10. CTA buttons (hidden in zen) ──
                                      if (!_zenMode) ...[
                                        const SizedBox(height: AppSpacing.xl),
                                        // Primary CTA
                                        FilledButton.icon(
                                          onPressed: _onGetMore,
                                          icon: const Icon(
                                              Icons.add_circle_outline),
                                          label: const Text(
                                              'Get More Affirmations'),
                                          style: FilledButton.styleFrom(
                                            minimumSize:
                                                const Size.fromHeight(52),
                                            backgroundColor:
                                                colorScheme.primary,
                                            foregroundColor:
                                                colorScheme.onPrimary,
                                            textStyle: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppRadius.md),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        // Secondary CTA
                                        FilledButton.icon(
                                          onPressed: () =>
                                              context.push('/session'),
                                          icon: const Icon(Icons.spa),
                                          label:
                                              const Text('Start Daily Session'),
                                          style: FilledButton.styleFrom(
                                            minimumSize:
                                                const Size.fromHeight(52),
                                            backgroundColor:
                                                colorScheme.secondary,
                                            foregroundColor:
                                                colorScheme.onSecondary,
                                            textStyle: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppRadius.md),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        // Tertiary outlined CTA
                                        OutlinedButton.icon(
                                          onPressed: () =>
                                              context.push('/webview'),
                                          icon: const Icon(Icons.games),
                                          label:
                                              const Text('Play YouImageFlip'),
                                          style: OutlinedButton.styleFrom(
                                            minimumSize:
                                                const Size.fromHeight(52),
                                            foregroundColor:
                                                colorScheme.primary,
                                            textStyle: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            side: BorderSide(
                                              color: colorScheme.primary
                                                  .withValues(alpha: 0.6),
                                              width: 1.25,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppRadius.md),
                                            ),
                                          ),
                                        ),
                                      ] else ...[
                                        const SizedBox(height: AppSpacing.xl),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // ── Zen exit FAB ─────────────────────────────────────
                  if (_zenMode)
                    Positioned(
                      bottom: 32,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: SafeArea(
                          child: FloatingActionButton.extended(
                            onPressed: _toggleZenMode,
                            backgroundColor: colorScheme.primaryContainer,
                            foregroundColor: colorScheme.onPrimaryContainer,
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Exit Focus'),
                            elevation: 4,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Mouse/trackpad can drag [PageView] on desktop web; touch unchanged.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        ...super.dragDevices,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

// ── CategorySelector ──────────────────────────────────────────────────────────

class CategorySelector extends StatelessWidget {
  final AffirmationCategory? selectedCategory;
  final Future<void> Function(AffirmationCategory?) onCategoryChanged;
  final bool elevatedChipSurface;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    this.elevatedChipSurface = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              label: Text(
                'All',
                style: TextStyle(
                  color: selectedCategory == null
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurface,
                  fontWeight: selectedCategory == null
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
                softWrap: false,
                overflow: TextOverflow.visible,
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              selected: selectedCategory == null,
              onSelected: (_) => onCategoryChanged(null),
              backgroundColor: elevatedChipSurface
                  ? colorScheme.surfaceContainerHigh
                  : colorScheme.surface,
              selectedColor: colorScheme.secondaryContainer,
            ),
          ),
          ...AffirmationCategory.values.map((category) {
            final isSelected = selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(
                  '${category.emoji} ${category.displayName}',
                  style: TextStyle(
                    color: isSelected
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  softWrap: false,
                  overflow: TextOverflow.visible,
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                selected: isSelected,
                onSelected: (_) => onCategoryChanged(category),
                backgroundColor: elevatedChipSurface
                    ? colorScheme.surfaceContainerHigh
                    : colorScheme.surface,
                selectedColor: colorScheme.secondaryContainer,
              ),
            );
          }),
        ],
      ),
    );
  }
}
