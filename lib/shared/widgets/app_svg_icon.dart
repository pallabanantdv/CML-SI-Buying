import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Semantic icon names backed by the app's monochrome SVG icon set.
enum AppIconName {
  add,
  dashboard,
  purchase,
  supplier,
  profile,
  cloudOff,
  inbox,
  visibility,
  visibilityOff,
  expandMore,
  logout,
  success,
  error,
  warning,
  info,
  person,
  lock,
  search,
  focus,
  inventory,
  badge,
  contrast,
  settings,
  lightMode,
  darkMode,
  tune,
  phone,
  email,
  chevronRight,
}

class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon({
    super.key,
    required this.icon,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final AppIconName icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  String get _assetName => switch (icon) {
    AppIconName.cloudOff => 'cloud_off',
    AppIconName.visibilityOff => 'visibility_off',
    AppIconName.expandMore => 'expand_more',
    AppIconName.lightMode => 'light_mode',
    AppIconName.darkMode => 'dark_mode',
    AppIconName.chevronRight => 'chevron_right',
    _ => icon.name,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconTheme = IconTheme.of(context);
    return SvgPicture.asset(
      'assets/icons/$_assetName.svg',
      width: size ?? iconTheme.size ?? 24,
      height: size ?? iconTheme.size ?? 24,
      colorFilter: ColorFilter.mode(
        color ?? iconTheme.color ?? theme.colorScheme.onSurface,
        BlendMode.srcIn,
      ),
      excludeFromSemantics: semanticLabel == null,
      semanticsLabel: semanticLabel,
    );
  }
}
