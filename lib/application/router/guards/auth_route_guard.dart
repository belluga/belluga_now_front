import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:get_it/get_it.dart';

class AuthRouteGuard extends AutoRouteGuard {
  final _authRepository = GetIt.I.get<AuthRepositoryContract>();

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (_authRepository.isAuthorized) {
      resolver.next(true);
    } else {
      final pendingPath = _buildPendingPath(resolver.route);
      final encodedRedirect = Uri.encodeQueryComponent(pendingPath);
      router.pushPath('/auth/login?redirect=$encodedRedirect');
      resolver.next(false);
    }
  }

  String _buildPendingPath(RouteMatch route) {
    final rawPath = route.fullPath;
    final path = rawPath.isEmpty ? '/' : '/$rawPath';
    final queryParams = route.queryParams.rawMap;
    final normalizedParams = queryParams.isEmpty
        ? null
        : queryParams.map(
            (key, value) => MapEntry(key, value?.toString() ?? ''),
          );
    return Uri(path: path, queryParameters: normalizedParams).toString();
  }
}
