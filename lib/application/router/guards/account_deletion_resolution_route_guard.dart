import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:get_it/get_it.dart';

class AccountDeletionResolutionRouteGuard extends AutoRouteGuard {
  AccountDeletionResolutionRouteGuard({AuthRepositoryContract? authRepository})
    : _authRepository = authRepository ?? GetIt.I.get<AuthRepositoryContract>();

  final AuthRepositoryContract _authRepository;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (_authRepository
        .accountDeletionJourneyState
        .mayRenderResolutionBoundary) {
      resolver.next(true);
      return;
    }

    resolver.redirectUntil(const TenantHomeRoute());
    resolver.next(false);
  }
}
