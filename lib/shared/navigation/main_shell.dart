import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_bottom_navigation.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final isDashboard = navigationShell.currentIndex == 0;

    return PopScope<Object?>(
      canPop: isDashboard,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !isDashboard) {
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(top: false, bottom: false, child: navigationShell),
        bottomNavigationBar: AppBottomNavigation(
          navigationShell: navigationShell,
        ),
      ),
    );
  }
}
