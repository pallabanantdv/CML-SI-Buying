import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cml_si_buying/config/theme/app_colors.dart';
import 'package:cml_si_buying/config/theme/app_theme.dart';
import 'package:cml_si_buying/shared/widgets/app_button.dart';
import 'package:cml_si_buying/shared/widgets/app_text_field.dart';

void main() {
  test('light and dark themes use the centralized semantic palette', () {
    expect(AppTheme.light.colorScheme.primary, AppColors.primary);
    expect(AppTheme.dark.colorScheme.primary, AppColors.primary);
    expect(AppTheme.light.colorScheme.surface, AppColors.surface);
    expect(AppTheme.dark.colorScheme.surface, AppColors.darkSurface);
    expect(
      AppTheme.light.extension<AppSemanticColors>()!.success,
      AppColors.success,
    );
    expect(
      AppTheme.dark.extension<AppSemanticColors>()!.warning,
      AppColors.warning,
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
