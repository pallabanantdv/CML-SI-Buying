import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../config/constants/app_constants.dart';
import '../../../config/routes/route_names.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/theme_provider.dart';
import '../../../features/auth/viewmodels/auth_viewmodel.dart';
import '../../../shared/widgets/app_app_bar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/app_header_title.dart';
import '../../../shared/widgets/app_loader.dart';
import '../../../shared/widgets/app_page_banner.dart';
import '../../../shared/widgets/app_status_badge.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../models/profile_model.dart';
import '../viewmodels/profile_viewmodel.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _requestedEmail;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final email = context.watch<AuthViewModel>().user?.id.trim() ?? '';
    if (_requestedEmail == email) return;
    _requestedEmail = email;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final profile = context.read<ProfileViewModel>();
      if (email.isEmpty) {
        profile.clearProfile();
      } else {
        unawaited(profile.loadProfile(email));
      }
    });
  }

  @override
  Widget build(BuildContext context) => Consumer<ProfileViewModel>(
    builder: (context, profile, _) => Scaffold(
      appBar: const AppAppBar(title: AppHeaderTitle(title: 'Profile')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimensions.profileContentMaxWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.pageGutter),
            children: [
              const AppPageBanner(
                eyebrow: 'Account settings',
                title: 'Your profile',
                description: 'Review your account details and app preferences.',
                icon: AppIconName.profile,
              ),
              const SizedBox(height: AppSpacing.large),
              _profileCard(context, profile),
              const SizedBox(height: AppSpacing.large),
              AppCard(
                tone: AppCardTone.info,
                showAccentBar: true,
                title: 'Appearance',
                subtitle: 'Choose how CML SI Buying looks on this device.',
                leading: AppSvgIcon(
                  icon: AppIconName.contrast,
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: const _ThemeModeChips(),
              ),
              const SizedBox(height: AppSpacing.large),
              if (!AppConstants.bypassLoginForModulePreview)
                AppCard(
                  tone: AppCardTone.warning,
                  showAccentBar: true,
                  title: 'Session',
                  subtitle: 'Sign out of your current account on this device.',
                  leading: AppSvgIcon(
                    icon: AppIconName.lock,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: AppButton(
                    label: 'Sign out',
                    icon: AppIconName.logout,
                    variant: AppButtonVariant.danger,
                    onPressed: () => context.read<AuthViewModel>().logout(),
                  ),
                ),
              if (kDebugMode)
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppButton(
                    label: 'Open component showcase',
                    variant: AppButtonVariant.text,
                    icon: AppIconName.tune,
                    expand: false,
                    onPressed: () => context.goNamed(RouteNames.designSystem),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _profileCard(BuildContext context, ProfileViewModel state) {
    if (state.isLoading) {
      return const AppCard(
        tone: AppCardTone.info,
        showAccentBar: true,
        title: 'Account information',
        child: SizedBox(
          height: 120,
          child: AppLoader(label: 'Loading profile...'),
        ),
      );
    }
    if (state.errorMessage != null) {
      return AppCard(
        tone: AppCardTone.error,
        showAccentBar: true,
        title: 'Account information',
        child: AppErrorWidget(
          message: state.errorMessage!,
          onRetry: () {
            final email = context.read<AuthViewModel>().user?.id;
            if (email != null) unawaited(state.loadProfile(email));
          },
        ),
      );
    }
    final profile = state.profile;
    if (profile == null) {
      return const AppCard(
        tone: AppCardTone.warning,
        showAccentBar: true,
        title: 'Account information',
        child: AppEmptyState(
          icon: AppIconName.person,
          title: 'No signed-in user',
          description: 'Sign in to load your user profile.',
        ),
      );
    }
    return _UserProfileCard(profile: profile);
  }
}

class _UserProfileCard extends StatelessWidget {
  const _UserProfileCard({required this.profile});

  final ProfileModel profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fields = profile.fields;
    final initials = profile.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();
    const displayedFields = [
      ('email', 'Email'),
      ('username', 'Username'),
      ('user_type', 'Account type'),
      ('enabled', 'Account status'),
      ('language', 'Language'),
      ('time_zone', 'Time zone'),
      ('creation', 'Created'),
      ('last_login', 'Last login'),
      ('last_active', 'Last active'),
    ];
    final visibleFields = displayedFields
        .where(
          (field) =>
              fields[field.$1] != null &&
              '${fields[field.$1]}'.trim().isNotEmpty,
        )
        .toList(growable: false);
    final enabledValue = '${fields['enabled']}'.toLowerCase();
    final isEnabled =
        enabledValue == '1' ||
        enabledValue == 'true' ||
        enabledValue == 'enabled';

    return AppCard(
      tone: AppCardTone.primary,
      showAccentBar: true,
      title: 'Account information',
      leading: AppSvgIcon(
        icon: AppIconName.person,
        color: theme.colorScheme.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.28),
                    width: 2,
                  ),
                ),
                child: Text(
                  initials.isEmpty ? '?' : initials,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.standard),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(
                      profile.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (fields.containsKey('enabled')) ...[
                const SizedBox(width: AppSpacing.small),
                AppStatusBadge(
                  label: isEnabled ? 'Enabled' : 'Disabled',
                  color: isEnabled
                      ? context.appColors.success
                      : context.appColors.error,
                ),
              ],
            ],
          ),
          if (visibleFields.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.large),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = AppSpacing.small;
                final columns = constraints.maxWidth >= 560 ? 2 : 1;
                final itemWidth = columns == 2
                    ? (constraints.maxWidth - spacing) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (var index = 0; index < visibleFields.length; index++)
                      SizedBox(
                        width: itemWidth,
                        child: _ProfileDetailRow(
                          label: visibleFields[index].$2,
                          value: visibleFields[index].$1 == 'enabled'
                              ? (isEnabled ? 'Enabled' : 'Disabled')
                              : '${fields[visibleFields[index].$1]}',
                          icon: _profileFieldIcon(visibleFields[index].$1),
                          accent: visibleFields[index].$1 == 'enabled'
                              ? (isEnabled
                                    ? context.appColors.success
                                    : context.appColors.error)
                              : index.isEven
                              ? theme.colorScheme.primary
                              : context.appColors.info,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
          if (profile.roles.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.standard),
            _ProfileRoles(roles: profile.roles),
          ],
        ],
      ),
    );
  }
}

class _ProfileRoles extends StatefulWidget {
  const _ProfileRoles({required this.roles});

  final List<String> roles;

  @override
  State<_ProfileRoles> createState() => _ProfileRolesState();
}

class _ProfileRolesState extends State<_ProfileRoles> {
  static const _initialRoleCount = 4;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final roles = _expanded
        ? widget.roles
        : widget.roles.take(_initialRoleCount).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Roles', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.small),
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            for (final role in roles)
              Chip(
                avatar: AppSvgIcon(
                  icon: AppIconName.badge,
                  size: 15,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text(role),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer
                    .withValues(alpha: 0.55),
                labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        if (widget.roles.length > _initialRoleCount)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded
                  ? 'Show fewer roles'
                  : 'Show all ${widget.roles.length} roles',
            ),
          ),
      ],
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  const _ProfileDetailRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final AppIconName icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppDimensions.badgeRadius),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(AppDimensions.badgeRadius),
            ),
            child: AppSvgIcon(icon: icon, size: 17, color: accent),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelSmall),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

AppIconName _profileFieldIcon(String field) => switch (field) {
  'email' => AppIconName.email,
  'username' => AppIconName.person,
  'user_type' => AppIconName.badge,
  'enabled' => AppIconName.success,
  'language' || 'time_zone' => AppIconName.settings,
  _ => AppIconName.info,
};

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
