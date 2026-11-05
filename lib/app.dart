import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/cache/cache_manager.dart';
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
  String? _purchaseSession;
  StreamSubscription<String>? _cacheUpdates;
  Timer? _cacheDebounce;
  final Set<String> _changedPaths = {};
  void _scheduleCacheUpdate(String path) {
    if (path.startsWith('revoke:')) {
      final endpoint = Uri.decodeComponent(path.substring(7));
      final d = widget.dependencies;
      if (endpoint.contains('/Supplier Point Of Purchase')) {
        d.pointOfPurchase.revokeSavedData();
      }
      if (endpoint == '/api/resource/Supplier' ||
          endpoint.startsWith('/api/resource/Supplier/')) {
        d.supplier.revokeSavedData();
      }
      if (endpoint.contains('/User') || endpoint.contains('/Has Role')) {
        d.profile.revokeSavedData();
      }
      return;
    }
    _changedPaths.add(Uri.decodeComponent(path));
    _cacheDebounce?.cancel();
    _cacheDebounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted || !widget.dependencies.auth.isAuthenticated) return;
      final paths = Set<String>.of(_changedPaths);
      _changedPaths.clear();
      final d = widget.dependencies;
      // Purchase mutations already update the selected document and reset its
      // advance balance. Reload form options only when their sources change;
      // unrelated option failures must not follow a successful purchase save.
      if (paths.any(
        (p) => const {
          '/api/resource/Supplier',
          '/api/resource/Item',
          '/api/resource/Journal Entry',
          '/api/resource/Warehouse',
          '/api/resource/Island',
          '/api/resource/Company',
          '/api/resource/Account',
          '/api/resource/Mode of Payment',
          '/api/resource/UOM',
        }.any((source) => p == source || p.startsWith('$source/')),
      )) {
        unawaited(d.pointOfPurchase.refreshReferenceData());
      }
      if (paths.any(
            (p) =>
                p == '/api/resource/Supplier' ||
                p.startsWith('/api/resource/Supplier/'),
          ) &&
          d.supplier.hasLoaded) {
        unawaited(d.supplier.loadSuppliers(force: false));
      }
      final supplierId = d.supplier.selectedSupplierId;
      if (supplierId != null &&
          paths.any(
            (p) =>
                p == '/api/resource/Supplier' ||
                p == '/api/resource/Supplier/$supplierId',
          )) {
        unawaited(d.supplier.loadSupplier(supplierId, force: false));
      }
      if (paths.any((p) => p.contains('Supplier Point Of Purchase'))) {
        if (d.pointOfPurchase.hasLoaded ||
            d.pointOfPurchase.errorMessage != null) {
          unawaited(d.pointOfPurchase.loadPointOfPurchases(force: false));
        }
        final name = d.pointOfPurchase.selectedName;
        if (name != null) {
          unawaited(d.pointOfPurchase.loadPointOfPurchase(name, force: false));
        }
      }
      if (paths.any((p) => p.contains('/User') || p.contains('/Has Role'))) {
        final email = d.auth.user?.id;
        if (email != null &&
            (d.profile.profile != null || d.profile.errorMessage != null)) {
          unawaited(d.profile.loadProfile(email, force: true, refresh: false));
        }
      }
    });
  }

  bool _reconnecting = false;
  void _reconnect() {
    if (_reconnecting ||
        !widget.dependencies.auth.isAuthenticated ||
        widget.dependencies.connectivity?.hasNetwork == false) {
      return;
    }
    _reconnecting = true;
    final d = widget.dependencies;
    unawaited(
      CacheManager.force(() async {
        if (!await d.auth.revalidateSession() ||
            d.connectivity?.offline == true) {
          return;
        }
        await d.pointOfPurchase.refreshReferenceData();
        if (d.supplier.hasLoaded || d.supplier.errorMessage != null) {
          await d.supplier.loadSuppliers();
        }
        if (d.pointOfPurchase.hasLoaded ||
            d.pointOfPurchase.errorMessage != null) {
          await d.pointOfPurchase.loadPointOfPurchases();
        }
        final supplierId = d.supplier.selectedSupplierId;
        if (supplierId != null) await d.supplier.loadSupplier(supplierId);
        final name = d.pointOfPurchase.selectedName;
        if (name != null) {
          await d.pointOfPurchase.loadPointOfPurchase(name);
        }
        final email = d.auth.user?.id;
        if (email != null &&
            (d.profile.profile != null || d.profile.errorMessage != null)) {
          await d.profile.loadProfile(email, force: true);
        }
      }).whenComplete(() {
        _reconnecting = false;
      }),
    );
  }

  void _onSessionChanged() {
    final auth = widget.dependencies.auth;
    final session = auth.isAuthenticated ? auth.user?.id : null;
    if (session == _purchaseSession) return;
    _purchaseSession = session;
    widget.dependencies.pointOfPurchase.resetSession();
    widget.dependencies.supplier.resetSession();
    widget.dependencies.profile.clearProfile();
  }

  @override
  void initState() {
    super.initState();
    _cacheUpdates = widget.dependencies.cache?.updates.listen(
      _scheduleCacheUpdate,
    );
    widget.dependencies.connectivity?.onReconnect = _reconnect;
    widget.dependencies.auth.addListener(_onSessionChanged);
    if (!AppConstants.bypassLoginForModulePreview) {
      widget.dependencies.auth.restoreSession();
    }
  }

  @override
  void dispose() {
    widget.dependencies.auth.removeListener(_onSessionChanged);
    _cacheUpdates?.cancel();
    _cacheDebounce?.cancel();
    widget.dependencies.connectivity?.onReconnect = null;
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
          // Keep a themed surface behind root authentication fades.
          builder: (context, child) => ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: widget.dependencies.connectivity == null
                ? child!
                : ListenableBuilder(
                    listenable: Listenable.merge([
                      widget.dependencies.connectivity!,
                      if (widget.dependencies.cache != null)
                        widget.dependencies.cache!.store,
                    ]),
                    builder: (context, _) {
                      final network = widget.dependencies.connectivity!;
                      final message = network.offline
                          ? "You're offline - Showing saved data where available"
                          : widget.dependencies.cache?.store.storageError ??
                                (network.refreshFailed
                                    ? 'Refresh failed - Showing saved data'
                                    : null);
                      return Column(
                        children: [
                          if (message != null)
                            Material(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              child: SafeArea(
                                bottom: false,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    message,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ),
                              ),
                            ),
                          Expanded(child: child!),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
    ),
  );
}
