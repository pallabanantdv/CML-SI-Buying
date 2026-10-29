import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../config/routes/route_names.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/app_loader.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/profile_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProfileViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Profile'),
      leading: IconButton(
        onPressed: () => context.goNamed(RouteNames.dashboard),
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    body: Consumer<ProfileViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading && vm.profile == null) return const AppLoader();
        if (vm.errorMessage != null && vm.profile == null) {
          return AppErrorWidget(message: vm.errorMessage!, onRetry: vm.load);
        }
        final profile = vm.profile;
        if (profile == null) return const SizedBox.shrink();
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Account details',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ProfileHeader(
              name: profile.fullName ?? profile.email,
              email: profile.email,
            ),
          ],
        );
      },
    ),
  );
}
