import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/constants/app_constants.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../features/auth/viewmodels/auth_viewmodel.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../viewmodels/dashboard_viewmodel.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => Consumer<DashboardViewModel>(
    builder: (context, viewModel, _) => Scaffold(
      appBar: AppBar(
        title: Text(viewModel.title),
        actions: AppConstants.bypassLoginForModulePreview
            ? const []
            : [
                IconButton(
                  tooltip: 'Sign out',
                  onPressed: () => context.read<AuthViewModel>().logout(),
                  icon: const AppSvgIcon(icon: AppIconName.logout),
                ),
                const SizedBox(width: 8),
              ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimensions.contentMaxWidth,
          ),
          child: AppEmptyState(
            icon: AppIconName.dashboard,
            title: 'Dashboard module is ready',
            description: viewModel.placeholder,
          ),
        ),
      ),
    ),
  );
}
