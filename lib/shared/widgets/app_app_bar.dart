import 'package:flutter/material.dart';

import 'app_svg_icon.dart';

/// Common branded header, with route-aware back navigation and screen actions.
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle,
    this.bottom,
  });

  final Widget title;
  final List<Widget>? actions;
  final bool? centerTitle;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(56 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return AppBar(
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leadingWidth: canPop ? 30 : 0,
      leading: canPop
          ? IconButton(
              padding: const EdgeInsets.only(
                left: 8,
                right: 0,
                top: 0,
                bottom: 0,
              ),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const AppSvgIcon(icon: AppIconName.arrowBack),
            )
          : null,
      title: Row(
        // mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 32,
              height: 32,
              child: Image.asset(
                'assets/images/CAML Logo.png',
                fit: BoxFit.cover,
                semanticLabel: 'CAML logo',
              ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(child: title),
        ],
      ),
      actions: actions
          ?.map(
            (action) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Material(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  clipBehavior: Clip.antiAlias,
                  child: action,
                ),
              ),
            ),
          )
          .toList(),
      bottom: bottom,
    );
  }
}
