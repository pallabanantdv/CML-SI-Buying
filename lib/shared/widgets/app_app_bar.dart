import 'package:flutter/material.dart';

import 'app_svg_icon.dart';

/// Common branded header, with route-aware back navigation and screen actions.
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
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return AppBar(
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: canPop
          ? IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const AppSvgIcon(icon: AppIconName.arrowBack),
            )
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/CAML Logo.jpg.jpeg',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
              semanticLabel: 'CAML logo',
            ),
          ),
          const SizedBox(width: 10),
          Flexible(child: title),
        ],
      ),
      actions: actions,
    );
  }
}
