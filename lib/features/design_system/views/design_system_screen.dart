import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/theme_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_checkbox.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/app_radio.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_switch.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_svg_icon.dart';

class DesignSystemScreen extends StatefulWidget {
  const DesignSystemScreen({super.key});

  @override
  State<DesignSystemScreen> createState() => _DesignSystemScreenState();
}

class _DesignSystemScreenState extends State<DesignSystemScreen> {
  final _defaultController = TextEditingController();
  final _focusController = TextEditingController();
  final _errorController = TextEditingController();
  final _passwordController = TextEditingController();
  final _disabledController = TextEditingController(text: 'Read only sample');
  final _focusNode = FocusNode();
  String? _department;
  String _radioValue = 'standard';
  bool _checked = true;
  bool _switched = true;

  @override
  void dispose() {
    _defaultController.dispose();
    _focusController.dispose();
    _errorController.dispose();
    _passwordController.dispose();
    _disabledController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Design system')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.contentMaxWidth,
        ),
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.pageGutter),
          children: [
            Text(
              'Component showcase',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xSmall),
            Text(
              'A development preview of shared styles and interaction states.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.large),
            _section(
              context,
              'Typography',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Page heading',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    'Section heading',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Card heading',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Body text with comfortable line spacing.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Helper text and secondary information',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            _section(
              context,
              'Text fields',
              Form(
                autovalidateMode: AutovalidateMode.always,
                child: Column(
                  children: [
                    AppTextField(
                      controller: _defaultController,
                      label: 'Default field',
                      hint: 'Enter a value',
                      required: true,
                    ),
                    const SizedBox(height: AppSpacing.standard),
                    AppTextField(
                      controller: _focusController,
                      focusNode: _focusNode,
                      label: 'Focused field',
                      prefixIcon: const AppSvgIcon(icon: AppIconName.search),
                      suffixIcon: IconButton(
                        tooltip: 'Focus this field',
                        onPressed: _focusNode.requestFocus,
                        icon: const AppSvgIcon(icon: AppIconName.focus),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.standard),
                    AppTextField(
                      controller: _errorController,
                      label: 'Error field',
                      validator: (_) => 'This value needs attention.',
                    ),
                    const SizedBox(height: AppSpacing.standard),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Password',
                      isPassword: true,
                      prefixIcon: const AppSvgIcon(icon: AppIconName.lock),
                    ),
                    const SizedBox(height: AppSpacing.standard),
                    AppTextField(
                      controller: _disabledController,
                      label: 'Disabled field',
                      enabled: false,
                    ),
                    const SizedBox(height: AppSpacing.standard),
                    const AppTextField(
                      label: 'Read-only field',
                      hint: 'Reference value',
                      readOnly: true,
                    ),
                    const SizedBox(height: AppSpacing.standard),
                    const AppTextField(
                      label: 'Multiline note',
                      hint: 'Add a short note',
                      maxLines: 3,
                      maxLength: 120,
                    ),
                  ],
                ),
              ),
            ),
            _section(
              context,
              'Buttons',
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  AppButton(label: 'Primary', onPressed: () {}, expand: false),
                  AppButton(
                    label: 'Secondary',
                    variant: AppButtonVariant.secondary,
                    onPressed: () {},
                    expand: false,
                  ),
                  AppButton(
                    label: 'Outlined',
                    variant: AppButtonVariant.outlined,
                    onPressed: () {},
                    expand: false,
                  ),
                  AppButton(
                    label: 'Text',
                    variant: AppButtonVariant.text,
                    onPressed: () {},
                    expand: false,
                  ),
                  AppButton(
                    label: 'Danger',
                    variant: AppButtonVariant.danger,
                    onPressed: () {},
                    expand: false,
                  ),
                  AppButton(
                    label: 'Success',
                    variant: AppButtonVariant.success,
                    onPressed: () {},
                    expand: false,
                  ),
                  const AppButton(
                    label: 'Loading',
                    onPressed: null,
                    isLoading: true,
                    expand: false,
                  ),
                ],
              ),
            ),
            _section(
              context,
              'Selection controls',
              Column(
                children: [
                  AppDropdown<String>(
                    value: _department,
                    label: 'Department',
                    hint: 'Choose a department',
                    items: const [
                      DropdownMenuItem(value: 'buying', child: Text('Buying')),
                      DropdownMenuItem(
                        value: 'finance',
                        child: Text('Finance'),
                      ),
                      DropdownMenuItem(
                        value: 'operations',
                        child: Text('Operations'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _department = value),
                    validator: (value) =>
                        value == null ? 'Select a department.' : null,
                  ),
                  AppCheckbox(
                    value: _checked,
                    onChanged: (value) =>
                        setState(() => _checked = value ?? false),
                    label: 'Remember this choice',
                  ),
                  AppRadioGroup<String>(
                    value: _radioValue,
                    onChanged: (value) =>
                        setState(() => _radioValue = value ?? 'standard'),
                    child: const Column(
                      children: [
                        AppRadio<String>(value: 'standard', label: 'Standard'),
                        AppRadio<String>(value: 'compact', label: 'Compact'),
                      ],
                    ),
                  ),
                  AppSwitch(
                    value: _switched,
                    onChanged: (value) => setState(() => _switched = value),
                    label: 'Enable notifications',
                  ),
                ],
              ),
            ),
            _section(
              context,
              'Card and feedback',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppCard(
                    title: 'Card title',
                    subtitle: 'A compact, bordered surface.',
                    leading: AppSvgIcon(icon: AppIconName.inventory),
                    child: Text(
                      'Use shared surfaces for related business information.',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.standard),
                  Wrap(
                    spacing: AppSpacing.small,
                    runSpacing: AppSpacing.small,
                    children: [
                      AppButton(
                        label: 'Show dialog',
                        variant: AppButtonVariant.outlined,
                        expand: false,
                        onPressed: () => unawaited(
                          AppDialog.show<void>(
                            context,
                            title: 'Confirm action',
                            description: 'Review this short description before continuing.',
                            actions: [
                              AppButton(
                                label: 'Cancel',
                                variant: AppButtonVariant.text,
                                expand: false,
                                onPressed: () => Navigator.pop(context),
                              ),
                              AppButton(
                                label: 'Continue',
                                expand: false,
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AppButton(
                        label: 'Success message',
                        variant: AppButtonVariant.text,
                        expand: false,
                        onPressed: () => AppSnackbar.show(
                          context,
                          'Changes saved.',
                          type: AppMessageType.success,
                        ),
                      ),
                      AppButton(
                        label: 'Error message',
                        variant: AppButtonVariant.text,
                        expand: false,
                        onPressed: () => AppSnackbar.show(
                          context,
                          'Unable to complete this action.',
                          type: AppMessageType.error,
                        ),
                      ),
                      AppButton(
                        label: 'Warning message',
                        variant: AppButtonVariant.text,
                        expand: false,
                        onPressed: () => AppSnackbar.show(
                          context,
                          'Check the entered information.',
                          type: AppMessageType.warning,
                        ),
                      ),
                      AppButton(
                        label: 'Information message',
                        variant: AppButtonVariant.text,
                        expand: false,
                        onPressed: () => AppSnackbar.show(
                          context,
                          'Your workspace is up to date.',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _section(
              context,
              'Theme',
              Consumer<ThemeProvider>(
                builder: (context, theme, _) => SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                    ),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                  ],
                  selected: {theme.themeMode},
                  onSelectionChanged: (selection) =>
                      unawaited(theme.setThemeMode(selection.first)),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _section(BuildContext context, String title, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.large),
    child: AppCard(
      title: title,
      padding: const EdgeInsets.all(AppSpacing.standard),
      child: child,
    ),
  );
}
