import 'package:go_router/go_router.dart';

import '../../features/auth/viewmodels/auth_viewmodel.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/splash_screen.dart';
import '../../features/dashboard/views/dashboard_screen.dart';
import '../../features/profile/views/profile_screen.dart';
import 'route_names.dart';

GoRouter createAppRouter(AuthViewModel auth) => GoRouter(
  initialLocation: '/splash',
  refreshListenable: auth,
  redirect: (context, state) {
    final path = state.matchedLocation;
    if (!auth.initialized) return path == '/splash' ? null : '/splash';
    if (!auth.isAuthenticated) return path == '/login' ? null : '/login';
    if (path == '/splash' || path == '/login') return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      name: RouteNames.splash,
      builder: (_, _) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: RouteNames.login,
      builder: (_, _) => const LoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      name: RouteNames.dashboard,
      builder: (_, _) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: RouteNames.profile,
      builder: (_, _) => const ProfileScreen(),
    ),
  ],
);
