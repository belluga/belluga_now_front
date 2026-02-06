import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/auth_redirect_store.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:get_it/get_it.dart';

class AuthRouteGuard extends AutoRouteGuard {
  final _authRepository = GetIt.I.get<AuthRepositoryContract>();
  final _redirectStore = GetIt.I.get<AuthRedirectStore>();

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (_authRepository.isAuthorized) {
      resolver.next(true);
    } else {
      _redirectStore.setPendingPath(_buildPendingPath(resolver.route));
      router.push(const AuthLoginRoute());
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
