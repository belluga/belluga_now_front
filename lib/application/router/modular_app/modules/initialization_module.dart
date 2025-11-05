import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/invites_repository.dart';
import 'package:belluga_now/presentation/landlord/screens/home/controllers/landlord_home_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/home/controller/invites_banner_builder_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/home/controller/tenant_home_controller.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class InitializationModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    
    registerLazySingleton<InvitesRepositoryContract>(
      () => InvitesRepository()..init(),
    );

    registerLazySingleton<TenantHomeController>(
      () => TenantHomeController(),
    );
    
    registerLazySingleton<LandlordHomeScreenController>(
      () => LandlordHomeScreenController(),
    );

    registerFactory(InvitesBannerBuilderController.new);
  }

  @override
  List<AutoRoute> get routes => const [];
}
