import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/constants/app_constants.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'config/theme/theme_provider.dart';
import 'core/di/dependency_injection.dart';

class CmlSiBuyingApp extends StatefulWidget {
  const CmlSiBuyingApp({super.key, required this.dependencies});
  final AppDependencies dependencies;
  @override
  State<CmlSiBuyingApp> createState() => _CmlSiBuyingAppState();
}

class _CmlSiBuyingAppState extends State<CmlSiBuyingApp> {
  late final GoRouter _router = createAppRouter(widget.dependencies.auth);
  @override
  void initState() {
    super.initState();
    if (!AppConstants.bypassLoginForModulePreview) {
      widget.dependencies.auth.restoreSession();
    }
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: widget.dependencies.auth),
      ChangeNotifierProvider.value(value: widget.dependencies.dashboard),
      ChangeNotifierProvider.value(value: widget.dependencies.pointOfPurchase),
      ChangeNotifierProvider.value(value: widget.dependencies.supplier),
      ChangeNotifierProvider.value(value: widget.dependencies.profile),
    ],
    child: ChangeNotifierProvider(
      create: (_) => ThemeProvider(widget.dependencies.preferences),
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: AppConstants.appName,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.themeMode,
          routerConfig: _router,
        ),
      ),
    ),
  );
}
