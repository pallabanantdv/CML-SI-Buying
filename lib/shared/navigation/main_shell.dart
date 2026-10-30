import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_bottom_navigation.dart';
import '../widgets/app_svg_icon.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final isDashboard = navigationShell.currentIndex == 0;

    return PopScope<Object?>(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !isDashboard) {
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(top: false, bottom: false, child: navigationShell),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: SizedBox.square(
          dimension: 64,
          child: FloatingActionButton(
            heroTag: 'main-shell-create-action',
            tooltip: 'Create',
            onPressed: () {},
            elevation: 8,
            shape: const CircleBorder(),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: const AppSvgIcon(icon: AppIconName.add, size: 28),
          ),
        ),
        bottomNavigationBar: AppBottomNavigation(
          navigationShell: navigationShell,
        ),
      ),
    );
  }
}
