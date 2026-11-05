# Navigation animations

The existing GoRouter routes, redirect rules, route parameters, and stateful shell branches remain unchanged. No animation packages were added.

## Central utilities

- `lib/core/navigation/app_transition_config.dart`: durations, curves, slide offset, scale, and tab opacity.
- `lib/core/navigation/app_page_transitions.dart`: adaptive, slide/fade, fade, scale/fade, native, and no-transition page factories; accessible native theme and sheet timing.
- `lib/core/navigation/app_navigation.dart`: `context.pushNamedOnce<T>()` preserves return values and rejects duplicate pending destinations. Its guard is scoped to each router, lasts until the pushed page returns, and releases in `finally`.

## Route policy

| Navigation | Behavior |
| --- | --- |
| Initial splash | No additional route animation; retains the existing branded splash |
| Login | 350 ms fade |
| Enter application shell | 400 ms fade |
| Bottom navigation | 200 ms fade from 90% opacity; only the destination paints |
| Purchase details | 300 ms native mobile transition; slide/fade on desktop or web |
| New purchase, new supplier, settings, debug design system | 280 ms native mobile transition; slide/fade on desktop or web |
| Back | 240 ms; native gestures remain interactive |
| Dialog | 220 ms fade with scale from 0.97 |
| Dropdown sheet | 220 ms native sheet motion, preserving drag dismissal |

The custom horizontal slide travels 10% of screen width and follows text direction. Flutter's native mobile motion is used where iOS edge swipe or Android predictive back matters. Native pages use `MaterialRouteTransitionMixin` and the platform transition theme; their contents remain live during navigation so skeletons continue animating.

`AnimatedBranchContainer` retains each branch under stable ancestors, isolates repainting, disables tickers and focus in inactive branches, and never paints the outgoing branch over the incoming one. Animation frames update opacity without rebuilding branch navigators. Reselecting a tab retains the existing shell behavior of returning to its initial location.

Reduced motion bypasses custom transforms, uses zero-duration route/modal transitions, and immediately completes tab fades. Native gesture detectors remain available. The app paints its theme background behind root transitions to avoid an unpainted surface during authentication changes.

## Integration files

- `lib/config/routes/app_router.dart`: transition policy for every existing route and the shell entry.
- `lib/config/theme/app_theme.dart`: accessible platform transition builders.
- `lib/app.dart`: themed background beneath root transitions.
- `lib/shared/navigation/animated_branch_container.dart`: stable branch trees and paint-only tab fades.
- `lib/shared/navigation/app_floating_bottom_navigation.dart`: shared icon/selection timing.
- `lib/shared/navigation/app_bottom_navigation.dart`: guarded central purchase action.
- `lib/shared/widgets/app_dialog.dart`, `app_dropdown.dart`: dialog and sheet motion.
- Dashboard, purchase list, supplier directory, profile, and settings screen views: guarded named pushes; existing destination names, path parameters, and return values are preserved.

## Validation

Completed: `flutter analyze --no-pub` with no issues, the full Flutter suite with 58 passing tests, and Android APK builds in debug, profile, and release modes.

- `navigation_animation_test.dart`: platform page transitions and back, reduced motion, iOS edge-swipe cancellation/commit, Android predictive-back channel cancellation/commit, duplicate push results, rapid tabs and retained scroll, dialog results.
- `navigation_loading_test.dart`: real shell switching during a pending detail API request, fixed bottom-bar geometry, no duplicate request, late response after back, splash/login/authenticated redirect.
- Existing loading lifecycle and mobile UI tests cover the existing nested destinations, form navigation, authentication state and cached data.

Native gesture tests simulate Flutter input and platform-channel events. Physical-device frame rates, different display refresh rates, and native OS compositor behavior still require device profiling. Build checks do not establish a 60/120 FPS guarantee.

## Flutter references

- [Stateful shell navigation](https://pub.dev/documentation/go_router/latest/go_router/StatefulShellRoute-class.html)
- [Predictive back](https://docs.flutter.dev/platform-integration/android/predictive-back)
- [Page route gesture eligibility](https://api.flutter.dev/flutter/widgets/PageRoute/popGestureEnabled.html)
