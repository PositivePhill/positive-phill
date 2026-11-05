import 'package:flutter/material.dart';
import 'package:positive_phill/services/storage_service.dart';

/// Single source of the app's effective Reduce Motion state:
/// platform `disableAnimations` OR platform `reduceMotion` (iOS) OR the
/// user's in-app preference ([StorageService.reduceMotion]).
///
/// Place above [MaterialApp] and pass [ReduceMotion.appBuilder] as its
/// `builder` so [MediaQueryData.disableAnimations] and route transitions follow
/// the same value. [AnimationController]s do not read [MediaQuery]; explicit
/// animations must check [ReduceMotion.of] themselves.
class ReduceMotion extends StatefulWidget {
  const ReduceMotion({super.key, required this.child});

  final Widget child;

  /// Effective value. Outside a [ReduceMotion] scope falls back to
  /// [MediaQueryData.disableAnimations].
  static bool of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_ReduceMotionScope>();
    return scope?.reduced ??
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
  }

  /// Whether the platform's accessibility settings request reduced motion,
  /// independent of the in-app preference.
  static bool systemRequestOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_ReduceMotionScope>();
    return scope?.system ??
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
  }

  /// `MaterialApp.builder`: keeps the tree shape stable whether or not motion
  /// is reduced, so toggling never remounts the navigator.
  static Widget appBuilder(BuildContext context, Widget? child) {
    final reduced = of(context);
    final theme = Theme.of(context);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
      child: Theme(
        data: reduced
            ? theme.copyWith(pageTransitionsTheme: _instantPageTransitions)
            : theme,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }

  @override
  State<ReduceMotion> createState() => _ReduceMotionState();
}

final PageTransitionsTheme _instantPageTransitions = PageTransitionsTheme(
  builders: {
    for (final platform in TargetPlatform.values)
      platform: _InstantPageTransitionsBuilder(),
  },
);

class _InstantPageTransitionsBuilder extends PageTransitionsBuilder {
  const _InstantPageTransitionsBuilder();

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}

class _ReduceMotionState extends State<ReduceMotion>
    with WidgetsBindingObserver {
  late bool _system = _readSystem();

  bool _readSystem() {
    final features =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
    return features.disableAnimations || features.reduceMotion;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAccessibilityFeatures() {
    final next = _readSystem();
    if (next != _system) setState(() => _system = next);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: StorageService.reduceMotion,
      builder: (context, user, child) => _ReduceMotionScope(
        system: _system,
        reduced: _system || user,
        child: child!,
      ),
      child: widget.child,
    );
  }
}

class _ReduceMotionScope extends InheritedWidget {
  const _ReduceMotionScope({
    required this.system,
    required this.reduced,
    required super.child,
  });

  final bool system;
  final bool reduced;

  @override
  bool updateShouldNotify(_ReduceMotionScope old) =>
      old.system != system || old.reduced != reduced;
}
