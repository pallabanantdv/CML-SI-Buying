import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../config/routes/route_names.dart';
import '../../../features/auth/viewmodels/auth_viewmodel.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/app_loader.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../widgets/dashboard_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DashboardViewModel>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Overview'),
      actions: [
        IconButton(
          tooltip: 'Profile',
          onPressed: () => context.goNamed(RouteNames.profile),
          icon: const Icon(Icons.account_circle_outlined),
        ),
        IconButton(
          tooltip: 'Sign out',
          onPressed: () => context.read<AuthViewModel>().logout(),
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: Consumer<DashboardViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading && vm.dashboard == null) {
          return const AppLoader(label: 'Loading your workspace…');
        }
        if (vm.errorMessage != null && vm.dashboard == null) {
          return AppErrorWidget(
            message: vm.errorMessage!,
            onRetry: vm.loadDashboard,
          );
        }
        final model = vm.dashboard;
        if (model == null) return const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 760 ? 3 : 1;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good to see you',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        model.userName,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your buying workspace at a glance.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 28),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: columns,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: columns == 1 ? 2.6 : 1.4,
                        children: [
                          DashboardCard(
                            icon: Icons.people_outline,
                            title: 'Customers',
                            value: model.customerCount?.toString() ?? '-',
                            caption: model.customerError == null
                                ? 'Records visible to your account'
                                : 'Unavailable for this account',
                          ),
                          const DashboardCard(
                            icon: Icons.shopping_bag_outlined,
                            title: 'Purchase requests',
                            value: '-',
                            caption: 'Coming soon',
                          ),
                          const DashboardCard(
                            icon: Icons.receipt_long_outlined,
                            title: 'Purchase orders',
                            value: '-',
                            caption: 'Coming soon',
                          ),
                        ],
                      ),
                      if (model.customerError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'Customer summary unavailable: ${model.customerError}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}
