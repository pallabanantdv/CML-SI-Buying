import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:cml_si_buying/config/theme/app_theme.dart';
import 'package:cml_si_buying/shared/navigation/app_floating_bottom_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cml_si_buying/shared/navigation/app_bottom_navigation.dart';

void main() {
  testWidgets(
    'floating destinations fit phones, scale, safe areas and both themes',
    (tester) async {
      // Render the actual elevation instead of Flutter tests' shadow outline.
      final previousDisableShadows = debugDisableShadows;
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = previousDisableShadows);
      for (final entry in {
        'Alike Angular': 'assets/fonts/AlikeAngular-Regular.ttf',
        'Poppins': 'assets/fonts/Poppins-SemiBold.ttf',
      }.entries) {
        await (FontLoader(
          entry.key,
        )..addFont(rootBundle.load(entry.value))).load();
      }
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final width in [320.0, 360.0, 390.0, 430.0]) {
        tester.view.physicalSize = Size(width, 844);
        for (final scale in [1.0, 1.5, 2.0]) {
          for (final safeBottom in [0.0, 34.0]) {
            for (final theme in [AppTheme.light, AppTheme.dark]) {
              final selected = ValueNotifier(0);
              var creations = 0;
              final boundary = GlobalKey();
              await tester.pumpWidget(
                MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: theme,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(scale),
                      padding: EdgeInsets.only(bottom: safeBottom),
                      viewPadding: EdgeInsets.only(bottom: safeBottom),
                      disableAnimations: scale == 2,
                    ),
                    child: child!,
                  ),
                  home: Scaffold(
                    body: const Align(
                      alignment: Alignment.bottomCenter,
                      child: Text('Last content row'),
                    ),
                    bottomNavigationBar: RepaintBoundary(
                      key: boundary,
                      child: ColoredBox(
                        color: theme.scaffoldBackgroundColor,
                        child: ValueListenableBuilder<int>(
                          valueListenable: selected,
                          builder: (context, value, _) =>
                              AppFloatingBottomNavigation(
                                items: AppBottomNavigation.items,
                                selectedIndex: value,
                                onCreatePurchase: () => creations++,
                                onDestinationSelected: (index) =>
                                    selected.value = index,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              final action = find.bySemanticsLabel('New purchase');
              expect(tester.getSize(action), const Size(56, 56));
              await tester.tap(action);
              await tester.pumpAndSettle();
              expect(creations, 1);
              for (
                var index = 0;
                index < AppBottomNavigation.items.length;
                index++
              ) {
                final label = AppBottomNavigation.items[index].label;
                final tab = find.bySemanticsLabel(label);
                expect(
                  tester.getRect(tab).overlaps(tester.getRect(action)),
                  isFalse,
                );
                expect(tester.getSize(tab).height, greaterThanOrEqualTo(48));
                expect(tester.getSize(tab).width, greaterThanOrEqualTo(48));
                await tester.tap(tab);
                await tester.pumpAndSettle();
                expect(selected.value, index);
                expect(
                  tester
                      .widget<Semantics>(
                        find.byWidgetPredicate(
                          (w) => w is Semantics && w.properties.label == label,
                        ),
                      )
                      .properties
                      .selected,
                  true,
                );
                expect(
                  tester.takeException(),
                  isNull,
                  reason:
                      'width=$width scale=$scale safe=$safeBottom theme=${theme.brightness}',
                );
                expect(
                  tester.getRect(tab).bottom,
                  lessThanOrEqualTo(844 - safeBottom - 9),
                );
              }
              final navTop = tester
                  .getTopLeft(find.byType(AppFloatingBottomNavigation))
                  .dy;
              expect(
                tester.getRect(find.text('Last content row')).bottom,
                lessThanOrEqualTo(navTop),
              );
              if (width == 390 && scale == 1 && safeBottom == 34) {
                selected.value = 0;
                await tester.pumpAndSettle();
                await tester.runAsync(() async {
                  final pixels =
                      await (boundary.currentContext!.findRenderObject()
                              as RenderRepaintBoundary)
                          .toImage(pixelRatio: 2);
                  final bytes = await pixels.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  final file = File(
                    'build/mobile-previews/floating-nav-${theme.brightness.name}.png',
                  );
                  await file.parent.create(recursive: true);
                  await file.writeAsBytes(bytes!.buffer.asUint8List());
                  pixels.dispose();
                });
              }
              await tester.pumpWidget(const SizedBox());
              selected.dispose();
            }
          }
        }
      }
      debugDisableShadows = previousDisableShadows;
    },
  );

  test('main navigation exposes exactly the four requested modules', () {
    expect(AppBottomNavigation.items.map((item) => item.label).toList(), [
      'Dashboard',
      'Purchase',
      'Supplier',
      'Profile',
    ]);
  });
}
