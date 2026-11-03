import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cml_si_buying/config/theme/app_colors.dart';
import 'package:cml_si_buying/config/theme/app_theme.dart';
import 'package:cml_si_buying/shared/widgets/app_button.dart';
import 'package:cml_si_buying/shared/widgets/app_text_field.dart';

void main() {
  test(
    'mobile text and status colors have readable contrast in both themes',
    () {
      double contrast(Color a, Color b) {
        final aa = a.computeLuminance();
        final bb = b.computeLuminance();
        return ((aa > bb ? aa : bb) + 0.05) / ((aa < bb ? aa : bb) + 0.05);
      }

      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final semantic = theme.extension<AppSemanticColors>()!;
        final surface = theme.colorScheme.surface;
        expect(
          contrast(theme.colorScheme.primary, surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(semantic.textSecondary, surface),
          greaterThanOrEqualTo(4.5),
        );
        for (final color in [
          semantic.success,
          semantic.warning,
          semantic.error,
          semantic.info,
        ]) {
          final badge = Color.alphaBlend(color.withValues(alpha: 0.1), surface);
          expect(contrast(color, badge), greaterThanOrEqualTo(4.5));
        }
      }
    },
  );

  test('light and dark themes use the centralized semantic palette', () {
    expect(AppTheme.light.colorScheme.primary, AppColors.primary);
    expect(AppTheme.dark.colorScheme.primary, AppColors.highlight);
    expect(AppTheme.light.colorScheme.surface, AppColors.surface);
    expect(AppTheme.dark.colorScheme.surface, AppColors.darkSurface);
    expect(
      AppTheme.light.extension<AppSemanticColors>()!.success,
      AppColors.success,
    );
    expect(
      AppTheme.dark.extension<AppSemanticColors>()!.warning,
      AppColors.darkWarning,
    );
  });

  testWidgets('app field displays validation and password visibility control', (
    tester,
  ) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.always,
            child: AppTextField(
              controller: controller,
              label: 'Password',
              isPassword: true,
              required: true,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Password required' : null,
            ),
          ),
        ),
      ),
    );
    formKey.currentState!.validate();
    await tester.pumpAndSettle();
    expect(find.text('Password required'), findsOneWidget);
    expect(find.byTooltip('Show password'), findsOneWidget);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Hide password'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('compact controls preserve 48 dp touch targets', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              AppButton(label: 'Save', onPressed: () {}),
              IconButton(
                tooltip: 'Action',
                onPressed: () {},
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(FilledButton)).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byType(IconButton)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('app button preserves disabled loading state', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppButton(
            label: 'Save',
            isLoading: true,
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    expect(pressed, isFalse);
  });
}
