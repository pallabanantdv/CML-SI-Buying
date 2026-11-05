import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cml_si_buying/config/theme/app_theme.dart';
import 'package:cml_si_buying/shared/widgets/skeleton/skeleton.dart';
import 'package:cml_si_buying/features/dashboard/widgets/dashboard_skeleton.dart';
import 'package:cml_si_buying/features/point_of_purchase/widgets/purchase_list_skeleton.dart';
import 'package:cml_si_buying/features/point_of_purchase/widgets/purchase_detail_skeleton.dart';
import 'package:cml_si_buying/features/profile/widgets/profile_skeleton.dart';
import 'package:cml_si_buying/features/supplier/widgets/supplier_list_skeleton.dart';

void main() {
  testWidgets(
    'screen skeletons fit narrow and wide screens, themes and large text',
    (tester) async {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        for (final width in [240.0, 320.0, 680.0]) {
          for (final scale in [1.0, 2.0]) {
            tester.view.resetPhysicalSize();
            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1;
            for (final layout in const [
              DashboardSkeleton(),
              PurchaseListSkeleton(),
              SupplierListSkeleton(),
              ProfileSkeleton(),
              PurchaseDetailSkeleton(),
            ]) {
              await tester.pumpWidget(
                MaterialApp(
                  theme: theme,
                  home: MediaQuery(
                    data: MediaQueryData(
                      size: Size(width, 900),
                      textScaler: TextScaler.linear(scale),
                    ),
                    child: Scaffold(
                      body: layout is PurchaseDetailSkeleton
                          ? layout
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: layout,
                            ),
                    ),
                  ),
                ),
              );
              await tester.pump(const Duration(milliseconds: 700));
              expect(
                tester.takeException(),
                isNull,
                reason: '$layout width=$width scale=$scale',
              );
            }
          }
        }
      }
      await tester.pumpWidget(const SizedBox());
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets(
    'reduced motion is static; shimmer stops when disabled or removed',
    (tester) async {
      Widget host({bool reduced = false, bool enabled = true}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: SkeletonShimmer(
            enabled: enabled,
            label: 'Loading records',
            child: const SkeletonBox(width: 100, height: 24),
          ),
        ),
      );
      await tester.pumpWidget(host());
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.binding.hasScheduledFrame, isTrue);
      expect(find.bySemanticsLabel('Loading records'), findsOneWidget);
      await tester.pumpWidget(host(reduced: true));
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpWidget(host());
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pumpWidget(host(enabled: false));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Loading records'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}
