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
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/app_loader.dart';
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
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimensions.profileContentMaxWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.pageGutter),
            children: [
              Text(
                'Your profile',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                'Manage your account and app preferences.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.medium),
              _profileCard(context, profile),
              const SizedBox(height: AppSpacing.large),
              AppCard(
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
        title: 'Account information',
        child: SizedBox(
          height: 120,
          child: AppLoader(label: 'Loading profile...'),
        ),
      );
    }
    if (state.errorMessage != null) {
      return AppCard(
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

    return AppCard(
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
              CircleAvatar(
                radius: 30,
                backgroundColor: theme.colorScheme.primaryContainer,
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
                    Text(profile.fullName, style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(profile.email, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          Divider(color: theme.colorScheme.outlineVariant, height: 1),
          const SizedBox(height: AppSpacing.small),
          for (var index = 0; index < visibleFields.length; index++) ...[
            if (index > 0)
              Divider(color: theme.colorScheme.outlineVariant, height: 1),
            const SizedBox(height: AppSpacing.small),
            _ProfileDetailRow(
              label: visibleFields[index].$2,
              value: visibleFields[index].$1 == 'enabled'
                  ? (fields[visibleFields[index].$1].toString() == '1'
                        ? 'Enabled'
                        : 'Disabled')
                  : '${fields[visibleFields[index].$1]}',
            ),
            const SizedBox(height: AppSpacing.small),
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
                label: Text(role),
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .secondaryContainer,
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
  const _ProfileDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      ),
      const SizedBox(width: AppSpacing.medium),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ],
  );
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
    onSelected: (value) {
      if (value) unawaited(onSelected(mode));
    },
  );
}
