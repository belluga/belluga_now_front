import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/route_redirect_path.dart';
import 'package:belluga_now/application/telemetry/auth_wall_telemetry.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

class AuthRouteGuard extends AutoRouteGuard {
  AuthRouteGuard({
    bool? isWebRuntime,
    AuthRepositoryContract? authRepository,
  })  : _isWebRuntime = isWebRuntime ?? kIsWeb,
        _authRepository =
            authRepository ?? GetIt.I.get<AuthRepositoryContract>();

  final bool _isWebRuntime;
  final AuthRepositoryContract _authRepository;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (_authRepository.isAuthorized) {
      resolver.next(true);
    } else {
      final pendingPath = buildRedirectPathFromRouteMatch(resolver.route);
      final actionType =
          AuthWallTelemetry.resolveActionTypeForPath(pendingPath);
      if (actionType != null) {
        AuthWallTelemetry.trackTriggered(
          actionType: actionType,
          redirectPath: pendingPath,
        );
      }
      if (_isWebRuntime) {
        resolver.redirectUntil(
          AppPromotionRoute(
            redirectPath: pendingPath,
          ),
        );
      } else {
        resolver.redirectUntil(
          AuthLoginRoute(
            redirectPath: pendingPath,
          ),
        );
      }
      resolver.next(false);
    }
  }
}
