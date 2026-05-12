import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:positive_phill/models/affirmation.dart';
import 'package:positive_phill/models/daily_quests.dart';
import 'package:positive_phill/providers/user_provider.dart';
import 'package:positive_phill/quest_helper.dart';
import 'package:positive_phill/services/affirmations_service.dart';
import 'package:positive_phill/theme.dart';
import 'package:positive_phill/widgets/affirmation_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final AffirmationsService _service = AffirmationsService();
  List<Affirmation?> _resolved = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolve();
    // Quest: visit favorites screen — fire after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) completeQuest(context, QuestType.visitedFavorites);
    });
  }

  Future<void> _resolve() async {
    final ids = context.read<UserProvider>().progress.favorites;
    final results = await Future.wait(ids.map((id) => _service.getById(id)));
    if (mounted) {
      setState(() {
        _resolved = results;
        _loading = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-resolve when favorites list changes (e.g. unfavorite)
    if (!_loading) {
      _resolve();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Watch favorites so the list updates when user unfavorites
    final favorites = context.select<UserProvider, List<String>>(
      (p) => List.unmodifiable(p.progress.favorites),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Affirmations',
            style: TextStyle(color: colorScheme.onSurface)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : favorites.isEmpty
                  ? _EmptyState(colorScheme: colorScheme, textTheme: textTheme)
                  : _FavoritesList(
                      resolved: _resolved,
                      favorites: favorites,
                    ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _EmptyState(
      {required this.colorScheme, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Your saved affirmations will appear here.',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Tap the heart on any affirmation to save it.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesList extends StatelessWidget {
  final List<Affirmation?> resolved;
  final List<String> favorites;

  const _FavoritesList({
    required this.resolved,
    required this.favorites,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      itemCount: resolved.length,
      itemBuilder: (context, index) {
        final affirmation = resolved[index];
        if (affirmation == null) {
          // Placeholder for an ID that no longer resolves to a pack entry
          return Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(
                'Affirmation no longer available.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return AffirmationCard(
          key: ValueKey(affirmation.id),
          affirmation: affirmation,
          showActions: true,
          textBacklightEnabled: false,
        );
      },
    );
  }
}
