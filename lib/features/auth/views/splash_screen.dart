import 'package:flutter/material.dart';

import '../../../config/constants/app_constants.dart';
import '../../../shared/widgets/app_loader.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48),
          SizedBox(height: 18),
          Text(AppConstants.appName),
          SizedBox(height: 24),
          AppLoader(label: 'Checking your session…'),
        ],
      ),
    ),
  );
}
