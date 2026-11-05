import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_transition_config.dart';

enum AppTransition { adaptive, slideFade, fade, scaleFade, native, none }

/// Route-owned animation clocks; no per-screen controllers or API dependencies.
abstract final class AppPageTransitions {
  static Page<T> page<T>(
    BuildContext context,
    GoRouterState state,
    Widget child, {
    AppTransition transition = AppTransition.adaptive,
    Duration duration = AppTransitionConfig.forward,
  }) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final platform = Theme.of(context).platform;
    final native =
        transition == AppTransition.native ||
        (transition == AppTransition.adaptive &&
            !kIsWeb &&
            (platform == TargetPlatform.android ||
                platform == TargetPlatform.iOS ||
                platform == TargetPlatform.macOS));
    if (native) {
      return _AppNativePage<T>(
        key: state.pageKey,
        name: state.name,
        child: child,
        duration: duration,
        reducedMotion: reduced,
      );
    }
    if (transition == AppTransition.none || reduced) {
      return NoTransitionPage<T>(
        key: state.pageKey,
        name: state.name,
        child: child,
      );
    }
    return CustomTransitionPage<T>(
      key: state.pageKey,
      name: state.name,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: AppTransitionConfig.back,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          build(context, animation, child, transition: transition),
    );
  }

  static Widget build(
    BuildContext context,
    Animation<double> animation,
    Widget child, {
    AppTransition transition = AppTransition.slideFade,
  }) {
    if (MediaQuery.disableAnimationsOf(context) ||
        transition == AppTransition.none) {
      return child;
    }
    // CurveTween creates no status listeners that need disposing in a route builder.
    final progress = animation.drive(
      CurveTween(
        curve: animation.status == AnimationStatus.reverse
            ? AppTransitionConfig.reverseCurve
            : AppTransitionConfig.curve,
      ),
    );
    final fade = FadeTransition(opacity: progress, child: child);
    return switch (transition) {
      AppTransition.fade => fade,
      AppTransition.scaleFade => ScaleTransition(
        scale: progress.drive(
          Tween(begin: AppTransitionConfig.initialScale, end: 1.0),
        ),
        child: fade,
      ),
      _ => SlideTransition(
        position: progress.drive(
          Tween(begin: AppTransitionConfig.slideOffset, end: Offset.zero),
        ),
        textDirection: Directionality.of(context),
        child: fade,
      ),
    };
  }

  /// Keep Flutter's native gesture detectors and delegated transitions intact.
  static const nativeTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: _AccessibleNativeTransitions(
        PredictiveBackPageTransitionsBuilder(),
      ),
      TargetPlatform.iOS: _AccessibleNativeTransitions(
        CupertinoPageTransitionsBuilder(),
      ),
      TargetPlatform.macOS: _AccessibleNativeTransitions(
        CupertinoPageTransitionsBuilder(),
      ),
      TargetPlatform.windows: _AccessibleNativeTransitions(
        ZoomPageTransitionsBuilder(),
      ),
      TargetPlatform.linux: _AccessibleNativeTransitions(
        ZoomPageTransitionsBuilder(),
      ),
      TargetPlatform.fuchsia: _AccessibleNativeTransitions(
        ZoomPageTransitionsBuilder(),
      ),
    },
  );

  static AnimationStyle modalStyle(BuildContext context) => AnimationStyle(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppTransitionConfig.modal,
    reverseDuration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppTransitionConfig.modal,
    curve: AppTransitionConfig.curve,
    reverseCurve: AppTransitionConfig.reverseCurve,
  );
}

class _AppNativePage<T> extends MaterialPage<T> {
  const _AppNativePage({
    required super.key,
    required super.name,
    required super.child,
    required this.duration,
    required this.reducedMotion,
  });
  final Duration duration;
  final bool reducedMotion;
  @override
  Route<T> createRoute(BuildContext context) => _AppNativeRoute<T>(this);
}

class _AppNativeRoute<T> extends PageRoute<T>
    with MaterialRouteTransitionMixin<T> {
  _AppNativeRoute(_AppNativePage<T> page)
    : super(settings: page, allowSnapshotting: false);
  _AppNativePage<T> get _page => settings as _AppNativePage<T>;
  @override
  Duration get transitionDuration =>
      _page.reducedMotion ? Duration.zero : _page.duration;
  @override
  Duration get reverseTransitionDuration =>
      _page.reducedMotion ? Duration.zero : AppTransitionConfig.back;
  @override
  bool get maintainState => true;
  @override
  Widget buildContent(BuildContext context) => _page.child;
}

class _AccessibleNativeTransitions extends PageTransitionsBuilder {
  const _AccessibleNativeTransitions(this.delegate);
  final PageTransitionsBuilder delegate;
  @override
  DelegatedTransitionBuilder? get delegatedTransition {
    final builder = delegate.delegatedTransition;
    if (builder == null) return null;
    return (context, animation, secondaryAnimation, allowSnapshotting, child) =>
        MediaQuery.disableAnimationsOf(context)
        ? child
        : builder(
            context,
            animation,
            secondaryAnimation,
            allowSnapshotting,
            child,
          );
  }

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final reduced =
        MediaQuery.disableAnimationsOf(context) && !route.popGestureInProgress;
    return delegate.buildTransitions(
      route,
      context,
      reduced ? kAlwaysCompleteAnimation : animation,
      reduced ? kAlwaysDismissedAnimation : secondaryAnimation,
      child,
    );
  }
}
