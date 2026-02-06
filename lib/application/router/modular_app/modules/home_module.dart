import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/tenant_route_guard.dart';
import 'package:belluga_now/domain/repositories/favorite_repository_contract.dart';
import 'package:belluga_now/domain/repositories/friends_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/favorite_repository.dart';
import 'package:belluga_now/infrastructure/repositories/friends_repository.dart';
import 'package:belluga_now/infrastructure/repositories/invites_repository.dart';
import 'package:belluga_now/infrastructure/repositories/schedule_repository.dart';
import 'package:belluga_now/infrastructure/repositories/user_events_repository.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/controllers/tenant_home_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/agenda_section/controllers/tenant_home_agenda_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/favorite_section/controllers/favorites_section_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/invites_banner/controllers/invites_banner_builder_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class HomeModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    registerLazySingleton<InvitesRepositoryContract>(
      () => InvitesRepository()..init(),
    );

    registerLazySingleton<FriendsRepositoryContract>(
      () => FriendsRepository(),
    );

    registerLazySingleton<FavoriteRepositoryContract>(
      FavoriteRepository.new,
    );

    if (!GetIt.I.isRegistered<ScheduleRepositoryContract>()) {
      registerLazySingleton<ScheduleRepositoryContract>(
        () => ScheduleRepository(),
      );
    }

    registerLazySingleton<UserEventsRepositoryContract>(
      () => UserEventsRepository(),
    );

    registerLazySingleton<TenantHomeAgendaController>(
      () => TenantHomeAgendaController(),
    );

    registerLazySingleton<TenantHomeController>(
      () => TenantHomeController(),
    );

    registerLazySingleton(FavoritesSectionController.new);
    registerLazySingleton(InvitesBannerBuilderController.new);
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/home',
          page: TenantHomeRoute.page,
          guards: [TenantRouteGuard()],
        ),
      ];
}
