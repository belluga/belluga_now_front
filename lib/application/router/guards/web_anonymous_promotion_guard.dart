import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/route_redirect_path.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

class WebAnonymousPromotionGuard extends AutoRouteGuard {
  WebAnonymousPromotionGuard({
    bool? isWebRuntime,
    AuthRepositoryContract? authRepository,
  })  : _isWebRuntime = isWebRuntime ?? kIsWeb,
        _authRepository =
            authRepository ?? GetIt.I.get<AuthRepositoryContract>();

  final bool _isWebRuntime;
  final AuthRepositoryContract _authRepository;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (!_isWebRuntime || _authRepository.isAuthorized) {
      resolver.next(true);
      return;
    }

    final redirectPath = buildRedirectPathFromRouteMatch(resolver.route);
    resolver.redirectUntil(
      AppPromotionRoute(
        redirectPath: redirectPath,
      ),
    );
    resolver.next(false);
  }
}
