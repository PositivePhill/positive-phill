import 'package:flutter/material.dart';
import 'package:positive_phill/theme.dart';

/// Shows a brief animated overlay toast when the user levels up.
/// Call [LevelUpToast.show] from anywhere with a mounted BuildContext.
class LevelUpToast {
  LevelUpToast._();

  static void show(BuildContext context, int newLevel) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _LevelUpToastWidget(
        level: newLevel,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _LevelUpToastWidget extends StatefulWidget {
  final int level;
  final VoidCallback onDone;

  const _LevelUpToastWidget({required this.level, required this.onDone});

  @override
  State<_LevelUpToastWidget> createState() => _LevelUpToastWidgetState();
}

class _LevelUpToastWidgetState extends State<_LevelUpToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 20),
      TweenSequenceItem(
          tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 20),
    ]).animate(_controller);
    _scale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.7, end: 1.05)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 1.05, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 72,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎖️',
                          style: TextStyle(fontSize: 32)),
                      const SizedBox(height: 4),
                      Text(
                        'Level Up!',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'You reached Level ${widget.level}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
