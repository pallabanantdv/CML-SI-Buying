import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../../features/auth/viewmodels/auth_viewmodel.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/splash_screen.dart';
import '../../features/dashboard/views/dashboard_screen.dart';
import '../../features/design_system/views/design_system_screen.dart';
import '../../features/point_of_purchase/views/point_of_purchase_screen.dart';
import '../../features/point_of_purchase/views/point_of_purchase_detail_screen.dart';
import '../../features/profile/views/profile_screen.dart';
import '../../features/supplier/views/add_supplier_screen.dart';
import '../../features/supplier/views/create_supplier_screen.dart';
import '../../shared/navigation/animated_branch_container.dart';
import '../../shared/navigation/main_shell.dart';
import 'route_names.dart';

GoRouter createAppRouter(AuthViewModel auth) => GoRouter(
  initialLocation: RoutePaths.splash,
  refreshListenable: auth,
  redirect: (context, state) {
    final path = state.matchedLocation;
    if (AppConstants.bypassLoginForModulePreview) {
      return path == RoutePaths.login ? RoutePaths.dashboard : null;
    }
    // Let the splash animation finish before it chooses the authenticated
    // destination. Protect all other routes while session state is restoring.
    if (path == RoutePaths.splash) return null;
    if (!auth.initialized) {
      return RoutePaths.splash;
    }
    if (!auth.isAuthenticated) {
      return path == RoutePaths.login ? null : RoutePaths.login;
    }
    if (path == RoutePaths.login) {
      return RoutePaths.dashboard;
    }
    return null;
  },
  routes: [
    GoRoute(
      path: RoutePaths.splash,
      name: RouteNames.splash,
      pageBuilder: (_, state) => _animatedPage(state, const SplashScreen()),
    ),
    GoRoute(
      path: RoutePaths.login,
      name: RouteNames.login,
      pageBuilder: (_, state) => _animatedPage(state, const LoginScreen()),
    ),
    StatefulShellRoute(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      navigatorContainerBuilder: (context, navigationShell, children) =>
          AnimatedBranchContainer(
            currentIndex: navigationShell.currentIndex,
            children: children,
          ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.dashboard,
              name: RouteNames.dashboard,
              pageBuilder: (_, state) =>
                  _animatedPage(state, const DashboardScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.pointOfPurchase,
              name: RouteNames.pointOfPurchase,
              pageBuilder: (_, state) =>
                  _animatedPage(state, const PointOfPurchaseScreen()),
              routes: [
                GoRoute(
                  path: ':documentName',
                  name: RouteNames.pointOfPurchaseDetail,
                  pageBuilder: (_, state) => _animatedPage(
                    state,
                    PointOfPurchaseDetailScreen(
                      documentName: state.pathParameters['documentName']!,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.addSupplier,
              name: RouteNames.addSupplier,
              pageBuilder: (_, state) =>
                  _animatedPage(state, const AddSupplierScreen()),
              routes: [
                GoRoute(
                  path: 'create',
                  name: RouteNames.createSupplier,
                  pageBuilder: (_, state) =>
                      _animatedPage(state, const CreateSupplierScreen()),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.profile,
              name: RouteNames.profile,
              pageBuilder: (_, state) =>
                  _animatedPage(state, const ProfileScreen()),
            ),
          ],
        ),
      ],
    ),
    if (kDebugMode)
      GoRoute(
        path: RoutePaths.designSystem,
        name: RouteNames.designSystem,
        pageBuilder: (_, state) =>
            _animatedPage(state, const DesignSystemScreen()),
      ),
  ],
);

CustomTransitionPage<void> _animatedPage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.of(context).disableAnimations) return child;
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final slide = Tween<Offset>(
          begin: const Offset(0.025, 0),
          end: Offset.zero,
        ).animate(curved);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
