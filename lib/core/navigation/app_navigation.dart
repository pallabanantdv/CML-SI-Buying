import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// A guard lasts until the pushed page returns, including its entrance animation.
/// Scope guards to the originating page: authentication redirects can discard
/// pushed pages without completing their push futures. A new page must not
/// inherit those stale guards. Contexts outside a route fall back to the router.
final _pendingPushes = Expando<Set<String>>('pending navigation');

extension AppNavigation on BuildContext {
  Future<T?> pushNamedOnce<T extends Object?>(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) async {
    final router = GoRouter.of(this);
    final location = router.namedLocation(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
    );
    final owner = ModalRoute.of(this) ?? router;
    final pending = _pendingPushes[owner] ??= <String>{};
    if (router.routeInformationProvider.value.uri.toString() == location ||
        !pending.add(location)) {
      return null;
    }
    try {
      return await router.pushNamed<T>(
        name,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
        extra: extra,
      );
    } finally {
      pending.remove(location);
    }
  }
}
