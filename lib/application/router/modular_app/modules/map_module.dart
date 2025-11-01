import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/repositories/city_map_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/city_map_repository.dart';
import 'package:belluga_now/presentation/tenant/screens/map/controller/city_map_controller.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class MapModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    registerLazySingleton<CityMapRepositoryContract>(
      () => CityMapRepository(),
    );
    registerFactory<CityMapController>(
      () => CityMapController(),
    );
  }

  @override
  List<AutoRoute> get routes => const [];
}
