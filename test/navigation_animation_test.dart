import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:cml_si_buying/config/theme/app_theme.dart';
import 'package:cml_si_buying/core/navigation/app_navigation.dart';
import 'package:cml_si_buying/core/navigation/app_page_transitions.dart';
import 'package:cml_si_buying/core/navigation/app_transition_config.dart';
import 'package:cml_si_buying/shared/navigation/animated_branch_container.dart';
import 'package:cml_si_buying/shared/widgets/app_dialog.dart';

GoRouter testRouter({AppTransition transition = AppTransition.adaptive}) =>
    GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => AppPageTransitions.page(
            context,
            state,
            const Scaffold(body: Text('Home')),
            transition: AppTransition.none,
          ),
          routes: [
            GoRoute(
              path: 'detail',
              name: 'detail',
              pageBuilder: (context, state) => AppPageTransitions.page(
                context,
                state,
                const Scaffold(body: Text('Destination')),
                transition: transition,
                duration: AppTransitionConfig.detail,
              ),
            ),
          ],
        ),
      ],
    );

Widget host(GoRouter router, {bool reduced = false}) => MaterialApp.router(
  theme: AppTheme.light,
  routerConfig: router,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
    child: child!,
  ),
);

Future<void> backMessage(
  WidgetTester tester,
  String method, [
  double? progress,
]) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/backgesture',
    const StandardMethodCodec().encodeMethodCall(
      MethodCall(
        method,
        progress == null
            ? null
            : <String, dynamic>{
                'touchOffset': <double>[5, 300],
                'progress': progress,
                'swipeEdge': 0,
              },
      ),
    ),
    (_) {},
  );
}

void main() {
  testWidgets('push guard resets when sign-out replaces the route stack', (
    tester,
  ) async {
    final signedIn = ValueNotifier(true);
    final router = GoRouter(
      initialLocation: '/profile',
      refreshListenable: signedIn,
      redirect: (_, state) {
        if (!signedIn.value)
          return state.uri.path == '/login' ? null : '/login';
        return state.uri.path == '/login' ? '/profile' : null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('Login')),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.pushNamedOnce('settings'),
              child: const Text('Open settings'),
            ),
          ),
          routes: [
            GoRoute(
              path: 'settings',
              name: 'settings',
              builder: (_, _) => const Scaffold(body: Text('Settings page')),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(host(router));
    await tester.pumpAndSettle();
    for (var session = 0; session < 3; session++) {
      await tester.tap(find.text('Open settings'));
      await tester.pumpAndSettle();
      expect(find.text('Settings page'), findsOneWidget);
      signedIn.value = false;
      await tester.pumpAndSettle();
      expect(find.text('Login'), findsOneWidget);
      signedIn.value = true;
      await tester.pumpAndSettle();
      expect(find.text('Open settings'), findsOneWidget);
    }
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    signedIn.dispose();
  });

  for (final platform in [
    TargetPlatform.windows,
    TargetPlatform.android,
    TargetPlatform.iOS,
  ]) {
    for (final reduced in [false, true]) {
      testWidgets('page push and system back: $platform reduced=$reduced', (
        tester,
      ) async {
        debugDefaultTargetPlatformOverride = platform;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        final router = testRouter();
        await tester.pumpWidget(host(router, reduced: reduced));
        await tester.pumpAndSettle();
        unawaited(router.pushNamed('detail'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        expect(find.text('Destination'), findsOneWidget);
        final route = ModalRoute.of(tester.element(find.text('Destination')))!;
        expect(
          route.transitionDuration,
          reduced ? Duration.zero : AppTransitionConfig.detail,
        );
        expect(
          route.reverseTransitionDuration,
          reduced ? Duration.zero : AppTransitionConfig.back,
        );
        if (platform != TargetPlatform.windows) {
          expect(route, isA<MaterialRouteTransitionMixin>());
        }
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Home'), findsOneWidget);
        expect(router.canPop(), isFalse);
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        debugDefaultTargetPlatformOverride = null;
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('iOS edge swipe cancels, then commits a native pop', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final router = testRouter();
    await tester.pumpWidget(host(router));
    await tester.pumpAndSettle();
    unawaited(router.pushNamed('detail'));
    await tester.pumpAndSettle();
    final route = ModalRoute.of(tester.element(find.text('Destination')))!;
    expect(route.popGestureEnabled, isTrue);
    var gesture = await tester.startGesture(const Offset(1, 250));
    await gesture.moveBy(
      const Offset(50, 0),
      timeStamp: const Duration(milliseconds: 200),
    );
    await tester.pump();
    expect(route.popGestureInProgress, isTrue);
    await gesture.moveBy(
      const Offset(-45, 0),
      timeStamp: const Duration(milliseconds: 400),
    );
    await gesture.up(timeStamp: const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Destination'), findsOneWidget);
    gesture = await tester.startGesture(const Offset(1, 250));
    await gesture.moveBy(
      Offset(tester.view.physicalSize.width * 0.8, 0),
      timeStamp: const Duration(milliseconds: 250),
    );
    await gesture.up(timeStamp: const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
    'Android predictive back cancels and commits through Flutter channel',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final router = testRouter();
      await tester.pumpWidget(host(router));
      await tester.pumpAndSettle();
      unawaited(router.pushNamed('detail'));
      await tester.pumpAndSettle();
      final route = ModalRoute.of(tester.element(find.text('Destination')))!;
      await backMessage(tester, 'startBackGesture', 0);
      await tester.pump();
      expect(route.popGestureInProgress, isTrue);
      await backMessage(tester, 'updateBackGestureProgress', 0.4);
      await tester.pump();
      await backMessage(tester, 'cancelBackGesture');
      await tester.pumpAndSettle();
      expect(find.text('Destination'), findsOneWidget);
      await backMessage(tester, 'startBackGesture', 0);
      await tester.pump();
      await backMessage(tester, 'updateBackGestureProgress', 0.8);
      await tester.pump();
      await backMessage(tester, 'commitBackGesture');
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets(
    'repeated pushes create one page, preserve results, and unlock after pop',
    (tester) async {
      final router = testRouter(transition: AppTransition.slideFade);
      await tester.pumpWidget(host(router));
      await tester.pumpAndSettle();
      final context = tester.element(find.text('Home'));
      final first = context.pushNamedOnce<bool>('detail');
      final duplicate = context.pushNamedOnce<bool>('detail');
      expect(await duplicate, isNull);
      await tester.pumpAndSettle();
      router.pop(true);
      expect(await first, isTrue);
      await tester.pumpAndSettle();
      final next = context.pushNamedOnce<bool>('detail');
      await tester.pumpAndSettle();
      router.pop(false);
      expect(await next, isFalse);
      await tester.pumpAndSettle();
      expect(router.canPop(), isFalse);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets(
    'rapid branch switches retain scroll, never overlap, and stop for reduced motion',
    (tester) async {
      final selected = ValueNotifier(0);
      final reduced = ValueNotifier(false);
      final scroll = ScrollController();
      final branches = [
        ListView.builder(
          controller: scroll,
          itemCount: 100,
          itemBuilder: (_, i) => SizedBox(height: 50, child: Text('Row $i')),
        ),
        const Text('Second'),
        const Text('Third'),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: reduced,
            builder: (context, value, _) => MediaQuery(
              data: MediaQueryData(disableAnimations: value),
              child: Scaffold(
                body: ValueListenableBuilder<int>(
                  valueListenable: selected,
                  builder: (_, index, _) => AnimatedBranchContainer(
                    currentIndex: index,
                    children: branches,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      scroll.jumpTo(500);
      await tester.pump();
      for (final index in [1, 2, 1, 0, 2, 0]) {
        selected.value = index;
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          find
              .descendant(
                of: find.byType(AnimatedBranchContainer),
                matching: find.byType(Offstage),
                skipOffstage: false,
              )
              .evaluate()
              .where((e) => !(e.widget as Offstage).offstage)
              .length,
          1,
        );
        if (index != 1) expect(find.text('Second'), findsNothing);
        if (index != 2) expect(find.text('Third'), findsNothing);
      }
      expect(scroll.offset, 500);
      reduced.value = true;
      await tester.pump();
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
      selected.value = 1;
      await tester.pump();
      expect(
        tester
            .widget<FadeTransition>(
              find
                  .ancestor(
                    of: find.text('Second'),
                    matching: find.byType(FadeTransition),
                  )
                  .first,
            )
            .opacity
            .value,
        1,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      scroll.dispose();
      selected.dispose();
      reduced.dispose();
    },
  );

  testWidgets('dialog scale/fade preserves result and reduced motion', (
    tester,
  ) async {
    for (final reduced in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: const Scaffold(body: Text('Open')),
          ),
        ),
      );
      final context = tester.element(find.text('Open'));
      final result = AppDialog.show<bool>(
        context,
        title: 'Confirm',
        description: 'Continue?',
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(true),
            child: const Text('Continue'),
          ),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text('Confirm'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(await result, isTrue);
      expect(tester.takeException(), isNull);
    }
  });
}
