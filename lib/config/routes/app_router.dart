import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../../features/auth/viewmodels/auth_viewmodel.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/splash_screen.dart';
import '../../features/dashboard/views/dashboard_screen.dart';
import '../../features/design_system/views/design_system_screen.dart';
import '../../features/point_of_purchase/views/point_of_purchase_screen.dart';
import '../../features/point_of_purchase/views/point_of_purchase_detail_screen.dart';
import '../../features/point_of_purchase/views/create_point_of_purchase_screen.dart';
import '../../features/profile/views/profile_screen.dart';
import '../../features/settings/views/settings_screen.dart';
import '../../features/supplier/views/add_supplier_screen.dart';
import '../../features/supplier/views/create_supplier_screen.dart';
import '../../features/supplier/views/supplier_details_screen.dart';
import '../../shared/navigation/animated_branch_container.dart';
import '../../shared/navigation/main_shell.dart';
import 'route_names.dart';
import '../../core/navigation/app_page_transitions.dart';
import '../../core/navigation/app_transition_config.dart';

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
      pageBuilder: (context, state) => AppPageTransitions.page(
        context,
        state,
        const SplashScreen(),
        transition: AppTransition.none,
      ),
    ),
    GoRoute(
      path: RoutePaths.login,
      name: RouteNames.login,
      pageBuilder: (context, state) => AppPageTransitions.page(
        context,
        state,
        const LoginScreen(),
        transition: AppTransition.fade,
        duration: AppTransitionConfig.authentication,
      ),
    ),
    GoRoute(
      path: RoutePaths.createPointOfPurchase,
      name: RouteNames.createPointOfPurchase,
      pageBuilder: (context, state) => AppPageTransitions.page(
        context,
        state,
        const CreatePointOfPurchaseScreen(),
      ),
    ),
    StatefulShellRoute(
      pageBuilder: (context, state, navigationShell) => AppPageTransitions.page(
        context,
        state,
        MainShell(navigationShell: navigationShell),
        transition: AppTransition.fade,
        duration: AppTransitionConfig.splashToHome,
      ),
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
              pageBuilder: (context, state) => AppPageTransitions.page(
                context,
                state,
                const DashboardScreen(),
                transition: AppTransition.none,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.pointOfPurchase,
              name: RouteNames.pointOfPurchase,
              pageBuilder: (context, state) => AppPageTransitions.page(
                context,
                state,
                const PointOfPurchaseScreen(),
                transition: AppTransition.none,
              ),
              routes: [
                GoRoute(
                  path: ':documentName',
                  name: RouteNames.pointOfPurchaseDetail,
                  pageBuilder: (context, state) => AppPageTransitions.page(
                    context,
                    state,
                    PointOfPurchaseDetailScreen(
                      documentName: state.pathParameters['documentName']!,
                    ),
                    duration: AppTransitionConfig.detail,
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
              pageBuilder: (context, state) => AppPageTransitions.page(
                context,
                state,
                const AddSupplierScreen(),
                transition: AppTransition.none,
              ),
              routes: [
                GoRoute(
                  path: 'create',
                  name: RouteNames.createSupplier,
                  pageBuilder: (context, state) => AppPageTransitions.page(
                    context,
                    state,
                    const CreateSupplierScreen(),
                  ),
                ),
                GoRoute(
                  path: 'details/:supplierId',
                  name: RouteNames.supplierDetails,
                  pageBuilder: (context, state) => AppPageTransitions.page(
                    context,
                    state,
                    SupplierDetailsScreen(
                      supplierId: state.pathParameters['supplierId']!,
                    ),
                    duration: AppTransitionConfig.detail,
                  ),
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
              pageBuilder: (context, state) => AppPageTransitions.page(
                context,
                state,
                const ProfileScreen(),
                transition: AppTransition.none,
              ),
              routes: [
                GoRoute(
                  path: 'settings',
                  name: RouteNames.settings,
                  pageBuilder: (context, state) => AppPageTransitions.page(
                    context,
                    state,
                    const SettingsScreen(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    if (kDebugMode)
      GoRoute(
        path: RoutePaths.designSystem,
        name: RouteNames.designSystem,
        pageBuilder: (context, state) =>
            AppPageTransitions.page(context, state, const DesignSystemScreen()),
      ),
  ],
);
