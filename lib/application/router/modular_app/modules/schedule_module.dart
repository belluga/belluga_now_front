import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/tenant_route_guard.dart';
import 'package:belluga_now/application/router/guards/web_anonymous_fallback_guard.dart';
import 'package:belluga_now/application/router/resolvers/immersive_event_detail_route_resolver.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/controllers/event_search_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/controllers/immersive_event_detail_controller.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class ScheduleModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    _registerControllers();
    _registerResolvers();
  }

  void _registerControllers() {
    registerFactory(() => EventSearchScreenController());
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
          guards: [TenantRouteGuard(), WebAnonymousFallbackGuard()],
          meta: canonicalRouteMeta(family: CanonicalRouteFamily.eventSearch),
        ),
        AutoRoute(
          path: '/agenda/evento/:slug',
          page: ImmersiveEventDetailRoute.page,
          guards: [TenantRouteGuard()],
          meta: canonicalRouteMeta(
            family: CanonicalRouteFamily.immersiveEventDetail,
          ),
        ),
      ];
}
