import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/any_location_route_guard.dart';
import 'package:belluga_now/application/router/guards/tenant_route_guard.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class MapModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    registerLazySingleton<MapScreenController>(() => MapScreenController());
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/mapa',
          page: CityMapRoute.page,
          guards: [TenantRouteGuard(), AnyLocationRouteGuard()],
          meta: canonicalRouteMeta(family: CanonicalRouteFamily.cityMap),
        ),
        AutoRoute(
          path: '/mapa/poi',
          page: PoiDetailsRoute.page,
          guards: [TenantRouteGuard(), AnyLocationRouteGuard()],
          meta: canonicalRouteMeta(family: CanonicalRouteFamily.poiDetail),
        ),
      ];
}
