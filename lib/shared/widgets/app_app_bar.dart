import 'package:flutter/material.dart';

import 'app_svg_icon.dart';

/// App bar that uses the app's themed SVG back icon on poppable routes.
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle,
  });

  final Widget title;
  final List<Widget>? actions;
  final bool? centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return AppBar(
      // leadingWidth: 40,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: canPop
          ? IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const AppSvgIcon(icon: AppIconName.arrowBack),
            )
          : null,
      title: title,
      actions: actions,
    );
  }
}
