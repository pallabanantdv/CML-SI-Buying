import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../config/constants/app_constants.dart';
import '../../../config/routes/route_names.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/theme_provider.dart';
import '../../../features/auth/viewmodels/auth_viewmodel.dart';
import '../../../shared/widgets/app_app_bar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header_title.dart';
import '../../../shared/widgets/app_info_row.dart';
import '../../../shared/widgets/app_svg_icon.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: const AppAppBar(title: AppHeaderTitle(title: 'Settings')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.profileContentMaxWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.pageGutter),
              children: [
                AppCard(
                  title: 'Appearance',
                  subtitle: 'Choose a theme for this device.',
                  leading: AppSvgIcon(
                    icon: AppIconName.contrast,
                    color: primary,
                  ),
                  child: const _ThemeModeChips(),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                if (!AppConstants.bypassLoginForModulePreview) ...[
                  AppCard(
                    title: 'Account',
                    leading: AppSvgIcon(icon: AppIconName.lock, color: primary),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (auth.user != null) ...[
                          AppInfoRow(
                            label: 'Signed in as',
                            value: auth.user!.id,
                            selectable: true,
                          ),
                          const SizedBox(height: AppSpacing.small),
                        ],
                        AppButton(
                          label: 'Sign out',
                          icon: AppIconName.logout,
                          variant: AppButtonVariant.outlined,
                          isLoading: auth.isLoading,
                          onPressed: auth.logout,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                ],
                AppCard(
                  title: 'About',
                  leading: AppSvgIcon(icon: AppIconName.info, color: primary),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'CAML SI Buying',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.relatedGap),
                      const Text('Your workspace for purchases and suppliers.'),
                      const SizedBox(height: AppSpacing.small),
                      AppButton(
                        label: 'Open-source licenses',
                        icon: AppIconName.info,
                        variant: AppButtonVariant.outlined,
                        onPressed: () => showLicensePage(
                          context: context,
                          applicationName: 'CAML SI Buying',
                        ),
                      ),
                    ],
                  ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: AppSpacing.sectionGap),
                  AppCard(
                    title: 'Developer tools',
                    child: AppButton(
                      label: 'Open component showcase',
                      variant: AppButtonVariant.outlined,
                      icon: AppIconName.tune,
                      onPressed: () =>
                          context.pushNamed(RouteNames.designSystem),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeModeChips extends StatelessWidget {
  const _ThemeModeChips();

  @override
  Widget build(BuildContext context) => Consumer<ThemeProvider>(
    builder: (context, theme, _) => Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      children: [
        _ThemeModeChip(
          label: 'System',
          icon: AppIconName.settings,
          mode: ThemeMode.system,
          selected: theme.themeMode,
          onSelected: theme.setThemeMode,
        ),
        _ThemeModeChip(
          label: 'Light',
          icon: AppIconName.lightMode,
          mode: ThemeMode.light,
          selected: theme.themeMode,
          onSelected: theme.setThemeMode,
        ),
        _ThemeModeChip(
          label: 'Dark',
          icon: AppIconName.darkMode,
          mode: ThemeMode.dark,
          selected: theme.themeMode,
          onSelected: theme.setThemeMode,
        ),
      ],
    ),
  );
}

class _ThemeModeChip extends StatelessWidget {
  const _ThemeModeChip({
    required this.label,
    required this.icon,
    required this.mode,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final AppIconName icon;
  final ThemeMode mode;
  final ThemeMode selected;
  final Future<void> Function(ThemeMode) onSelected;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    avatar: AppSvgIcon(
      icon: icon,
      size: 16,
      color: mode == selected
          ? Theme.of(context).colorScheme.onSecondaryContainer
          : Theme.of(context).colorScheme.onSurfaceVariant,
    ),
    label: Text(label),
    selected: mode == selected,
    selectedColor: Theme.of(context).colorScheme.secondaryContainer
        .withValues(alpha: 0.7),
    side: BorderSide(
      color: mode == selected
          ? Theme.of(context).colorScheme.secondary
          : Theme.of(context).colorScheme.outlineVariant,
    ),
    onSelected: (value) {
      if (value) unawaited(onSelected(mode));
    },
  );
}
