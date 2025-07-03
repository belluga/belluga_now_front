import 'package:auto_route/auto_route.dart';
import 'package:flutter_laravel_backend_boilerplate/application/router/app_router.gr.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/repositories/auth_repository_contract.dart';
import 'package:get_it/get_it.dart';

class AuthGuard extends AutoRouteGuard {
  final _authRepository = GetIt.I.get<AuthRepositoryContract>();

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (_authRepository.isAuthorized) {
      resolver.next(true);
    } else {
      router.push(const AuthLoginRoute());
    }
  }
}
