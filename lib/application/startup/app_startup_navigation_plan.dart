import 'package:auto_route/auto_route.dart';

final class AppStartupNavigationPlan {
  const AppStartupNavigationPlan._({
    this.path,
    this.routes = const <PageRouteInfo<dynamic>>[],
  });

  const AppStartupNavigationPlan.none() : this._();

  const AppStartupNavigationPlan.path(String path) : this._(path: path);

  AppStartupNavigationPlan.routes(List<PageRouteInfo<dynamic>> routes)
      : this._(routes: List<PageRouteInfo<dynamic>>.unmodifiable(routes));

  final String? path;
  final List<PageRouteInfo<dynamic>> routes;

  bool get hasOverride => path != null || routes.isNotEmpty;

  DeepLink? toDeepLink() {
    final resolvedPath = path;
    if (resolvedPath != null && resolvedPath.isNotEmpty) {
      return DeepLink.path(resolvedPath);
    }
    if (routes.isNotEmpty) {
      return DeepLink(routes);
    }
    return null;
  }
}
