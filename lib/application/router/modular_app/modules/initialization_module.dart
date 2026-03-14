import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/tenant_route_guard.dart';
import 'package:belluga_now/domain/repositories/friends_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/friends_repository.dart';
import 'package:belluga_now/infrastructure/repositories/invites_repository.dart';
import 'package:belluga_now/infrastructure/repositories/user_events_repository.dart';
import 'package:belluga_now/presentation/shared/location_permission/controllers/location_permission_controller.dart';
import 'package:belluga_now/presentation/shared/init/screens/init_screen/controllers/init_screen_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class InitializationModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    if (!GetIt.I.isRegistered<FriendsRepositoryContract>()) {
      registerLazySingleton<FriendsRepositoryContract>(FriendsRepository.new);
    }

    if (!GetIt.I.isRegistered<InvitesRepositoryContract>()) {
      registerLazySingleton<InvitesRepositoryContract>(
        () => InvitesRepository(),
      );
    }

    if (!GetIt.I.isRegistered<UserEventsRepositoryContract>()) {
      registerLazySingleton<UserEventsRepositoryContract>(
        () => UserEventsRepository(),
      );
    }

    registerFactory<LocationPermissionController>(
      () => LocationPermissionController(),
    );

    registerLazySingleton<InitScreenController>(
      () => InitScreenController(),
    );
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/',
          page: InitRoute.page,
          guards: [TenantRouteGuard()],
        ),
        AutoRoute(
          path: '/location/permission',
          page: LocationPermissionRoute.page,
        ),
        AutoRoute(
          path: '/location/not-live',
          page: LocationNotLiveRoute.page,
        ),
      ];
}
