import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/controllers/event_detail_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/controllers/event_search_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/schedule_screen/controllers/schedule_screen_controller.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class ScheduleModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    registerLazySingleton(() => ScheduleScreenController());
    registerLazySingleton(() => EventSearchScreenController());

    registerFactory(() => EventDetailController());
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/agenda',
          page: ScheduleRoute.page,
        ),
        AutoRoute(
          path: '/agenda/evento/:slug',
          page: EventDetailRoute.page,
        ),
        AutoRoute(
          path: '/agenda/procurar',
          page: EventSearchRoute.page,
        ),
      ];
}
