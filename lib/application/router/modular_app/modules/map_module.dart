import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/any_location_route_guard.dart';
import 'package:belluga_now/domain/repositories/city_map_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/city_map_repository.dart';
import 'package:belluga_now/infrastructure/dal/datasources/mock_poi_database.dart';
import 'package:belluga_now/infrastructure/services/http/mock_http_service.dart';
import 'package:belluga_now/infrastructure/services/http/laravel_map_poi_http_service.dart';
import 'package:belluga_now/infrastructure/services/networking/mock_web_socket_service.dart';
import 'package:belluga_now/infrastructure/repositories/schedule_repository.dart';
import 'package:belluga_now/infrastructure/repositories/poi_repository.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/controllers/fab_menu_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class MapModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    final mockDatabase = MockPoiDatabase();
    registerLazySingleton<MockPoiDatabase>(() => mockDatabase);
    registerLazySingleton<MockHttpService>(
      () => MockHttpService(database: mockDatabase),
    );
    registerLazySingleton<LaravelMapPoiHttpService>(
      () => LaravelMapPoiHttpService(),
    );
    registerLazySingleton<MockWebSocketService>(
      () => MockWebSocketService(),
    );

    registerLazySingleton<ScheduleRepositoryContract>(
      () => ScheduleRepository(),
    );

    registerLazySingleton<CityMapRepositoryContract>(
      () => CityMapRepository(
        database: mockDatabase,
        httpService: GetIt.I<MockHttpService>(),
        laravelHttpService: GetIt.I<LaravelMapPoiHttpService>(),
        webSocketService: GetIt.I<MockWebSocketService>(),
      ),
    );

    registerLazySingleton<PoiRepository>(() => PoiRepository());
    registerLazySingleton<MapScreenController>(() => MapScreenController());
    registerLazySingleton<FabMenuController>(() => FabMenuController());
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/mapa',
          page: CityMapRoute.page,
          guards: [AnyLocationRouteGuard()],
        ),
        AutoRoute(
          path: '/mapa/poi',
          page: PoiDetailsRoute.page,
          guards: [AnyLocationRouteGuard()],
        ),
      ];
}
