import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/invites_repository.dart';
import 'package:belluga_now/infrastructure/repositories/schedule_repository.dart';
import 'package:belluga_now/presentation/landlord/home/controllers/landlord_home_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/controllers/home_upcoming_events_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/controllers/invites_banner_builder_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/controllers/tenant_home_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class InitializationModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    
    registerLazySingleton<InvitesRepositoryContract>(
      () => InvitesRepository()..init(),
    );

    if (!GetIt.I.isRegistered<ScheduleRepositoryContract>()) {
      registerLazySingleton<ScheduleRepositoryContract>(
        () => ScheduleRepository(),
      );
    }

    registerLazySingleton<TenantHomeController>(
      () => TenantHomeController(),
    );

    registerLazySingleton<HomeUpcomingEventsController>(
      () => HomeUpcomingEventsController(),
    );
    
    registerLazySingleton<LandlordHomeScreenController>(
      () => LandlordHomeScreenController(),
    );

    registerFactory(InvitesBannerBuilderController.new);
  }

  @override
  List<AutoRoute> get routes => const [];
}
