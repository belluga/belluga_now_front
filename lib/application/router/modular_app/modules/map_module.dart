import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/repositories/city_map_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/city_map_repository.dart';
import 'package:belluga_now/infrastructure/services/dal/datasources/mock_poi_database.dart';
import 'package:belluga_now/infrastructure/services/http/mock_http_service.dart';
import 'package:belluga_now/infrastructure/services/networking/mock_web_socket_service.dart';
import 'package:belluga_now/infrastructure/repositories/schedule_repository.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/city_map_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/cuisine_panel_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/events_panel_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/fab_menu_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/music_panel_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/region_panel_controller.dart';
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
        webSocketService: GetIt.I<MockWebSocketService>(),
      ),
    );

    registerLazySingleton<CityMapController>(
      () => CityMapController(),
    );

    registerLazySingleton<FabMenuController>(() => FabMenuController());
    registerLazySingleton<RegionPanelController>(() => RegionPanelController());
    registerLazySingleton<EventsPanelController>(() => EventsPanelController());
    registerLazySingleton<MusicPanelController>(() => MusicPanelController());
    registerLazySingleton<CuisinePanelController>(() => CuisinePanelController());
  }

  @override
  List<AutoRoute> get routes => const [];
}
