import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/navigation/app_navigation.dart';

import 'package:provider/provider.dart';

import '../../../config/routes/route_names.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_spacing.dart';

import '../../../features/auth/viewmodels/auth_viewmodel.dart';
import '../../../shared/widgets/app_app_bar.dart';

import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_info_row.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/app_header_title.dart';
import '../../../shared/widgets/skeleton/skeleton.dart';
import '../widgets/profile_skeleton.dart';
import '../../../shared/widgets/app_expandable_section.dart';
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
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.profileContentMaxWidth,
            ),
            child: RefreshIndicator(
              onRefresh: () async {
                final email = context.read<AuthViewModel>().user?.id;
                if (email != null) {
                  await profile.loadProfile(email, force: true);
                }
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppDimensions.pageGutter),
                children: [
                  SkeletonReveal(
                    loading: _profileLoading(profile),
                    child: _profileCard(context, profile),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  AppCard(
                    title: 'Settings',
                    subtitle: 'Appearance, account and app information',
                    leading: AppSvgIcon(
                      icon: AppIconName.settings,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () => context.pushNamedOnce(RouteNames.settings),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  bool _profileLoading(ProfileViewModel state) =>
      state.profile == null &&
      (state.isLoading ||
          ((_requestedEmail?.isNotEmpty ?? false) &&
              state.errorMessage == null));

  Widget _profileCard(BuildContext context, ProfileViewModel state) {
    if (_profileLoading(state)) return const ProfileSkeleton();
    if (state.errorMessage != null && state.profile == null) {
      return AppCard(
        tone: AppCardTone.error,
        showAccentBar: false,
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
        showAccentBar: false,
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
    final imageUrl = context.read<ProfileViewModel>().repository.imageUrl(
      fields['user_image']?.toString(),
    );
    final initials = profile.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();
    const displayedFields = [
      ('username', 'Username'),
      ('user_type', 'Account type'),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    foregroundImage: imageUrl == null
                        ? null
                        : NetworkImage(imageUrl),
                    onForegroundImageError: imageUrl == null ? null : (_, _) {},
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Text(
                      initials.isEmpty ? '?' : initials,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        SelectableText(
                          profile.email,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (fields.containsKey('enabled')) ...[
                    const SizedBox(height: AppSpacing.relatedGap),
                    AppStatusBadge(
                      label: isEnabled ? 'Enabled' : 'Disabled',
                      color: isEnabled
                          ? context.appColors.success
                          : context.appColors.error,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (visibleFields.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.cardGap),
          AppExpandableSection(
            title: 'Account information',
            initiallyExpanded: true,
            child: Column(
              children: [
                for (final field in visibleFields)
                  _ProfileDetailRow(
                    label: field.$2,
                    value: _profileFieldValue(
                      context,
                      field.$1,
                      fields[field.$1],
                    ),
                    icon: _profileFieldIcon(field.$1),
                    accent: theme.colorScheme.primary,
                  ),
              ],
            ),
          ),
        ],
        if (profile.roles.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.cardGap),
          AppCard(child: _ProfileRoles(roles: profile.roles)),
        ],
      ],
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
          runSpacing: AppSpacing.relatedGap,
          children: [
            for (final role in roles)
              Chip(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                avatar: AppSvgIcon(
                  icon: AppIconName.badge,
                  size: 15,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text(role, maxLines: 2, overflow: TextOverflow.ellipsis),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSvgIcon(icon: icon, size: 18, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: AppInfoRow(label: label, value: value, selectable: true),
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

String _profileFieldValue(BuildContext context, String field, dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (!const {'creation', 'last_login', 'last_active'}.contains(field)) {
    return text;
  }
  final date = DateTime.tryParse(text);
  if (date == null) return text;
  final localizations = MaterialLocalizations.of(context);
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(date),
    alwaysUse24HourFormat: false,
  );
  return '${localizations.formatMediumDate(date)} • $time';
}
