import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:positive_phill/models/affirmation.dart';
import 'package:positive_phill/providers/user_provider.dart';
import 'package:positive_phill/services/affirmations_service.dart';
import 'package:positive_phill/platform/background_image.dart';
import 'package:positive_phill/services/storage_service.dart';
import 'package:positive_phill/services/ads_service.dart';
import 'package:positive_phill/services/haptics_service.dart';
import 'package:positive_phill/theme.dart';
import 'package:positive_phill/widgets/affirmation_card.dart';
import 'package:positive_phill/widgets/celebration_animation.dart';
import 'package:positive_phill/widgets/streak_display.dart';
import 'package:positive_phill/widgets/xp_progress_bar.dart';
import 'dart:convert';

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
  bool _showCelebration = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _adsService.initialize();
    _adsService.loadRewardedAd();
    _adsService.loadInterstitialAd();
    _loadDailyContent();
    _loadCustomBackground();
  }

  Future<void> _loadCustomBackground() async {
    final storage = StorageService();
    final path = await storage.getCustomBackgroundPath();
    final web = await storage.getCustomBackgroundWeb();
    await storage.getCustomBackgroundAlignment();
    if (mounted) {
      StorageService.customBackgroundPath.value = path;
      StorageService.customBackgroundWeb.value = web;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _adsService.dispose();
    super.dispose();
  }

  void _loadDailyContent() {
    final seed = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _dailyTheme = _affirmationsService.getRandomMessage(category: _selectedCategory, seed: seed);
      _currentPack = _affirmationsService.getDailyPack(category: _selectedCategory);
    });
  }

  void _onCategoryChanged(AffirmationCategory? category) {
    final seed = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _selectedCategory = category;
      _dailyTheme = _affirmationsService.getRandomMessage(category: category, seed: seed);
      _currentPack = _affirmationsService.getRandomPack(category: category, count: 5, seed: seed);
      _currentPage = 0;
    });
    _pageController.jumpToPage(0);
  }

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

  void _loadExtraPack() {
    setState(() {
      final extraPack = _affirmationsService.getExtraPack(category: _selectedCategory);
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final userProvider = context.watch<UserProvider>();

    if (userProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return CelebrationAnimation(
      trigger: _showCelebration,
      child: Scaffold(
        body: AnimatedBuilder(
          animation: Listenable.merge([
            StorageService.customBackgroundPath,
            StorageService.customBackgroundWeb,
            StorageService.customBackgroundAlignment,
          ]),
          builder: (context, _) {
            final bgPath = StorageService.customBackgroundPath.value;
            final bgWeb = StorageService.customBackgroundWeb.value;
            final align = StorageService.customBackgroundAlignment.value;
            Widget bgWidget = ColoredBox(color: Theme.of(context).scaffoldBackgroundColor);
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
                    StorageService().setCustomBackgroundWeb(null);
                  });
                }
              }
            } else {
              if (bgPath != null && bgPath.isNotEmpty) {
                bgWidget = BackgroundImageBuilder.build(bgPath, alignment: align);
                hasCustomBg = true;
              }
            }
            return Stack(
              children: [
                Positioned.fill(child: bgWidget),
                if (hasCustomBg)
                  Positioned.fill(
                    child: Container(color: Colors.black.withOpacity(0.6)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Positive Phill',
                          style: textTheme.headlineMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.push('/settings'),
                        icon: Icon(Icons.settings, color: colorScheme.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  XpProgressBar(progress: userProvider.progress),
                  const SizedBox(height: AppSpacing.md),
                  Center(child: StreakDisplay(streak: userProvider.progress.streak)),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('💭', style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: AppSpacing.sm),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            key: ValueKey(_dailyTheme),
                            _dailyTheme,
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: Text(
                      'Today\'s Affirmations',
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CategorySelector(
                    selectedCategory: _selectedCategory,
                    onCategoryChanged: _onCategoryChanged,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 280,
                    child: _currentPack.isEmpty
                        ? Center(
                            child: Text(
                              'No affirmations available',
                              style: textTheme.bodyMedium,
                            ),
                          )
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: _currentPack.length,
                            onPageChanged: (index) {
                              setState(() => _currentPage = index);
                            },
                            itemBuilder: (context, index) {
                              return AffirmationCard(
                                affirmation: _currentPack[index],
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _currentPack.length > 10 ? 10 : _currentPack.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index
                                ? colorScheme.primary
                                : colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _onGetMore,
                      icon: Icon(Icons.add_circle_outline, color: colorScheme.onPrimary),
                      label: Text('Get More Affirmations', style: TextStyle(color: colorScheme.onPrimary)),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        backgroundColor: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.push('/session'),
                      icon: Icon(Icons.spa, color: colorScheme.onSecondary),
                      label: Text('Start Daily Session', style: TextStyle(color: colorScheme.onSecondary)),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        backgroundColor: colorScheme.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/webview'),
                      icon: Icon(Icons.games, color: colorScheme.primary),
                      label: Text('Play YouImageFlip', style: TextStyle(color: colorScheme.primary)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        side: BorderSide(color: colorScheme.primary),
                      ),
                    ),
                  ),
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
              ],
            );
          },
        ),
      ),
    );
  }
}

class CategorySelector extends StatelessWidget {
  final AffirmationCategory? selectedCategory;
  final Function(AffirmationCategory?) onCategoryChanged;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
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
              label: Text('All', style: TextStyle(
                color: selectedCategory == null ? colorScheme.onSecondaryContainer : colorScheme.onSurface,
              )),
              selected: selectedCategory == null,
              onSelected: (_) => onCategoryChanged(null),
              backgroundColor: colorScheme.surface,
              selectedColor: colorScheme.secondaryContainer,
            ),
          ),
          ...AffirmationCategory.values.map((category) {
            final isSelected = selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${category.emoji} '),
                      TextSpan(text: category.displayName),
                    ],
                    style: TextStyle(
                      color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurface,
                    ),
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => onCategoryChanged(category),
                backgroundColor: colorScheme.surface,
                selectedColor: colorScheme.secondaryContainer,
              ),
            );
          }),
        ],
      ),
    );
  }
}
