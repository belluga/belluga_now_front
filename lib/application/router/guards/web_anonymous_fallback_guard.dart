import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

typedef AnonymousWebRouteAllowance = bool Function(RouteMatch route);

class WebAnonymousFallbackGuard extends AutoRouteGuard {
  WebAnonymousFallbackGuard({
    bool? isWebRuntime,
    AuthRepositoryContract? authRepository,
    AnonymousWebRouteAllowance? allowAnonymousWeb,
  })  : _isWebRuntime = isWebRuntime ?? kIsWeb,
        _authRepository =
            authRepository ?? GetIt.I.get<AuthRepositoryContract>(),
        _allowAnonymousWeb = allowAnonymousWeb;

  final bool _isWebRuntime;
  final AuthRepositoryContract _authRepository;
  final AnonymousWebRouteAllowance? _allowAnonymousWeb;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (!_isWebRuntime || _authRepository.isAuthorized) {
      resolver.next(true);
      return;
    }

    if (_allowAnonymousWeb?.call(resolver.route) ?? false) {
      resolver.next(true);
      return;
    }

    resolver.next(false);
    router.replaceAll([const TenantHomeRoute()]);
  }
}
