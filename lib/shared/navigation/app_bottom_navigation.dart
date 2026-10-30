import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/app_svg_icon.dart';
import 'bottom_navigation_item.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const items = [
    BottomNavigationItem(
      label: 'Dashboard',
      icon: AppIconName.dashboard,
      selectedIcon: AppIconName.dashboard,
    ),
    BottomNavigationItem(
      label: 'Purchase',
      icon: AppIconName.purchase,
      selectedIcon: AppIconName.purchase,
    ),
    BottomNavigationItem(
      label: 'Supplier',
      icon: AppIconName.supplier,
      selectedIcon: AppIconName.supplier,
    ),
    BottomNavigationItem(
      label: 'Profile',
      icon: AppIconName.profile,
      selectedIcon: AppIconName.profile,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: BottomAppBar(
        height: 76,
        color: scheme.surface,
        surfaceTintColor: scheme.surface,
        elevation: 8,
        notchMargin: 10,
        clipBehavior: Clip.antiAlias,
        shape: const AutomaticNotchedShape(StadiumBorder(), CircleBorder()),
        child: Row(
          children: [
            for (var index = 0; index < 2; index++)
              Expanded(child: _destination(context, index)),

            const SizedBox(width: 80),

            for (var index = 2; index < items.length; index++)
              Expanded(child: _destination(context, index)),
          ],
        ),
      ),
    );
  }

  Widget _destination(BuildContext context, int index) {
    final item = items[index];
    final selected = navigationShell.currentIndex == index;
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: () => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: item.label,
                child: AppSvgIcon(
                  icon: selected ? item.selectedIcon : item.icon,
                  size: 24,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
