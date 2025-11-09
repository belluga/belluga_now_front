import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/city_map_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/city_map_repository.dart';
import 'package:belluga_now/infrastructure/repositories/schedule_repository.dart';
import 'package:belluga_now/infrastructure/services/dal/datasources/mock_poi_database.dart';
import 'package:belluga_now/infrastructure/services/http/mock_http_service.dart';
import 'package:belluga_now/infrastructure/services/networking/mock_web_socket_service.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/city_map_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class MapPrototypeModule extends ModuleContract {
  static const instanceName = 'map_prototype_scope';

  @override
  FutureOr<void> registerDependencies() async {
    _registerMapServices();
    _registerController();
  }

  void _registerMapServices() {
    GetIt.I.registerLazySingleton<MockPoiDatabase>(
      () => MockPoiDatabase(),
      instanceName: instanceName,
    );
    GetIt.I.registerLazySingleton<MockHttpService>(
      () => MockHttpService(
        database: GetIt.I.get<MockPoiDatabase>(instanceName: instanceName),
      ),
      instanceName: instanceName,
    );
    GetIt.I.registerLazySingleton<MockWebSocketService>(
      () => MockWebSocketService(),
      instanceName: instanceName,
    );
    GetIt.I.registerLazySingleton<ScheduleRepositoryContract>(
      () => ScheduleRepository(),
      instanceName: instanceName,
    );

    registerLazySingleton<CityMapRepositoryContract>(() => CityMapRepository());
  }

  void _registerController() {
    registerLazySingleton<CityMapController>(() => CityMapController());
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/prototype/map-experience',
          page: MapExperiencePrototypeRoute.page,
        ),
      ];
}
