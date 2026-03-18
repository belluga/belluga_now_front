import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/support/route_redirect_path.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:get_it/get_it.dart';

class AuthRouteGuard extends AutoRouteGuard {
  final _authRepository = GetIt.I.get<AuthRepositoryContract>();

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (_authRepository.isAuthorized) {
      resolver.next(true);
    } else {
      final pendingPath = buildRedirectPathFromRouteMatch(resolver.route);
      final encodedRedirect = Uri.encodeQueryComponent(pendingPath);
      router.pushPath('/auth/login?redirect=$encodedRedirect');
      resolver.next(false);
    }
  }
}
