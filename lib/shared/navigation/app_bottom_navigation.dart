import 'package:flutter/material.dart';

import '../../core/navigation/app_navigation.dart';

import 'package:go_router/go_router.dart';

import '../../config/routes/route_names.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_svg_icon.dart';
import 'bottom_navigation_item.dart';
import 'app_floating_bottom_navigation.dart';

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
  Widget build(BuildContext context) => AppFloatingBottomNavigation(
    items: items,
    selectedIndex: navigationShell.currentIndex,
    onCreatePurchase: () async {
      final created = await context.pushNamedOnce<bool>(
        RouteNames.createPointOfPurchase,
      );
      if (created == true && context.mounted) {
        AppSnackbar.show(
          context,
          'Purchase saved',
          type: AppMessageType.success,
        );
      }
    },
    onDestinationSelected: (index) => navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    ),
  );
}
