import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:positive_phill/models/affirmation.dart';
import 'package:positive_phill/models/rescue_intent.dart';
import 'package:positive_phill/providers/ritual_provider.dart';
import 'package:positive_phill/services/affirmations_service.dart';
import 'package:positive_phill/services/storage_service.dart';
import 'package:positive_phill/theme.dart';
import 'package:positive_phill/widgets/affirmation_card.dart';
import 'package:positive_phill/widgets/ritual_timer_bar.dart';

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
  final AffirmationsService _affirmationsService = AffirmationsService();
  final PageController _pageController = PageController();

  RitualProvider? _ritual;

  List<Affirmation> _pack = [];
  int _currentPage = 0;
  bool _loading = true;
  String? _loadError;

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
  }

  Future<void> _loadPack() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      await AffirmationsService.preload();
      final pack =
          await _affirmationsService.getSessionPack(widget.intent.category);
      if (!mounted) return;
      setState(() {
        _pack = pack;
        _loading = false;
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
    _pageController.dispose();
    _ritual?.reset();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
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
                    : LayoutBuilder(
                            builder: (context, constraints) {
                              return Center(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 720),
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.lg,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          widget.intent.supportLine,
                                          textAlign: TextAlign.center,
                                          style: textTheme.titleSmall
                                              ?.copyWith(
                                            color:
                                                colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppSpacing.md,
                                        ),
                                        const RitualTimerBar(),
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
                                              behavior:
                                                  const RescueScrollBehavior(),
                                              child: PageView.builder(
                                                controller: _pageController,
                                                itemCount: _pack.length,
                                                onPageChanged: _onPageChanged,
                                                itemBuilder: (context, index) {
                                                  return AffirmationCard(
                                                    affirmation: _pack[index],
                                                    textBacklightEnabled:
                                                        textBacklight,
                                                    shareSubtitle:
                                                        category.displayName,
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
                                                _pack.length > 10
                                                    ? 10
                                                    : _pack.length,
                                                (i) => Container(
                                                  margin: const EdgeInsets
                                                      .symmetric(
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
                              );
                            },
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
