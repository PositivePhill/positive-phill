import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:positive_phill/models/affirmation.dart';
import 'package:positive_phill/providers/user_provider.dart';
import 'package:positive_phill/services/affirmations_service.dart';
import 'package:positive_phill/services/ads_service.dart';
import 'package:positive_phill/services/haptics_service.dart';
import 'package:positive_phill/theme.dart';
import 'package:positive_phill/widgets/affirmation_card.dart';
import 'package:positive_phill/widgets/celebration_animation.dart';

class SessionFlowScreen extends StatefulWidget {
  const SessionFlowScreen({super.key});

  @override
  State<SessionFlowScreen> createState() => _SessionFlowScreenState();
}

class _SessionFlowScreenState extends State<SessionFlowScreen> {
  final AffirmationsService _affirmationsService = AffirmationsService();
  final AdsService _adsService = AdsService();
  
  List<AffirmationCategory> _selectedCategories = [];
  List<Affirmation> _sessionPack = [];
  int _currentIndex = 0;
  bool _sessionStarted = false;
  bool _sessionCompleted = false;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _adsService.initialize();
    _adsService.loadInterstitialAd();
  }

  @override
  void dispose() {
    _adsService.dispose();
    super.dispose();
  }

  void _startSessionWithCategories(List<AffirmationCategory> categories) {
    setState(() {
      _selectedCategories = List.from(categories);
      _sessionPack = _affirmationsService.getSessionPackForCategories(categories);
      _sessionStarted = true;
      _currentIndex = 0;
    });
  }

  void _onNext() {
    HapticsService.feedback(FeedbackType.selection);
    
    if (_currentIndex < _sessionPack.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _completeSession();
    }
  }

  Future<void> _completeSession() async {
    final userProvider = context.read<UserProvider>();
    await userProvider.completeSession();
    
    setState(() {
      _sessionCompleted = true;
      _showCelebration = true;
    });

    if (_adsService.isInterstitialAdReady) {
      await Future.delayed(const Duration(seconds: 2));
      await _adsService.showInterstitialAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CelebrationAnimation(
      trigger: _showCelebration,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Daily Session', style: TextStyle(color: colorScheme.onSurface)),
          leading: IconButton(
            icon: Icon(Icons.close, color: colorScheme.onSurface),
            onPressed: () => context.pop(),
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
                    ),
        ),
      ),
    );
  }
}

class CategorySelection extends StatefulWidget {
  final Function(List<AffirmationCategory>) onConfirm;

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

    return Padding(
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
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              children: AffirmationCategory.values.map((category) {
                final isSelected = _selected.contains(category);
                return CategoryCard(
                  category: category,
                  isSelected: isSelected,
                  onTap: () => _toggle(category),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _selected.isEmpty ? null : () => widget.onConfirm(_selected.toList()),
              icon: Icon(Icons.play_arrow, color: colorScheme.onPrimary),
              label: Text('Start Session', style: TextStyle(color: colorScheme.onPrimary)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                backgroundColor: colorScheme.primary,
              ),
            ),
          ),
        ],
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
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(category.emoji, style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    category.displayName,
                    style: textTheme.titleMedium?.copyWith(color: textColor, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.check_circle, color: colorScheme.primary, size: 22),
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

  const SessionContent({
    super.key,
    required this.affirmation,
    required this.currentIndex,
    required this.totalCount,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (currentIndex + 1) / totalCount,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.secondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${currentIndex + 1} of $totalCount',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          AffirmationCard(
            affirmation: affirmation,
            showActions: true,
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
