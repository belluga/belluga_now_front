import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/city_map_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/city_map_repository.dart';
import 'package:belluga_now/infrastructure/repositories/schedule_repository.dart';
import 'package:belluga_now/infrastructure/dal/datasources/mock_poi_database.dart';
import 'package:belluga_now/infrastructure/services/http/mock_http_service.dart';
import 'package:belluga_now/infrastructure/services/networking/mock_web_socket_service.dart';
import 'package:belluga_now/presentation/prototypes/map_experience/controllers/fab_menu_controller.dart';
import 'package:belluga_now/presentation/prototypes/map_experience/controllers/map_screen_controller.dart';
import 'package:belluga_now/infrastructure/repositories/poi_repository.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class MapPrototypeModule extends ModuleContract {
  static const instanceName = 'map_prototype_scope';

  @override
  FutureOr<void> registerDependencies() async {
    _registerMapServices();
    _registerController();
  }

  void _registerMapServices() {
    registerLazySingleton<MockPoiDatabase>(() => MockPoiDatabase());

    registerLazySingleton<MockHttpService>(() => MockHttpService());

    registerLazySingleton<MockWebSocketService>(() => MockWebSocketService());

    registerLazySingleton<ScheduleRepositoryContract>(
        () => ScheduleRepository());

    registerLazySingleton<CityMapRepositoryContract>(() => CityMapRepository());

    registerLazySingleton<PoiRepository>(() => PoiRepository());
  }

  void _registerController() {
    registerLazySingleton<MapScreenController>(
      () => MapScreenController(),
    );

    registerLazySingleton<FabMenuController>(
      () => FabMenuController(),
    );
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/prototype/map-experience',
          page: MapExperiencePrototypeRoute.page,
        ),
      ];
}
