import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/resolvers/immersive_event_detail_route_resolver.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/controllers/event_detail_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/controllers/event_search_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/controllers/immersive_event_detail_controller.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class ScheduleModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    _registerControllers();
    _registerResolvers();
  }

  void _registerControllers() {
    registerLazySingleton(() => EventSearchScreenController());

    registerFactory(() => EventDetailController());
    registerFactory(() => ImmersiveEventDetailController());
  }

  void _registerResolvers() {
    registerRouteResolver<EventModel>(ImmersiveEventDetailRouteResolver.new);
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/agenda',
          page: EventSearchRoute.page,
        ),
        AutoRoute(
          path: '/agenda/evento/:slug',
          page: EventDetailRoute.page,
        ),
        AutoRoute(
          path: '/agenda/evento-imersivo/:slug',
          page: ImmersiveEventDetailRoute.page,
        ),
      ];
}
