import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/manual_route_stubs.dart';
import 'package:belluga_now/application/router/guards/auth_route_guard.dart';
import 'package:belluga_now/application/router/guards/tenant_route_guard.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@AutoRouterConfig()
class AppRouter extends AppRouterContract {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/init',
          page: InitRoute.page,
          initial: true,
        ),
        AutoRoute(
          path: '/',
          page: TenantHomeRoute.page,
          guards: [TenantRouteGuard()],
        ),
        AutoRoute(
          path: '/landlord',
          page: LandlordHomeRoute.page,
        ),
        AutoRoute(
          path: '/login',
          page: AuthLoginRoute.page,
        ),
        AutoRoute(
          path: '/recover_password',
          page: RecoveryPasswordRoute.page,
        ),
        AutoRoute(
          path: '/auth/create-password',
          page: AuthCreateNewPasswordRoute.page,
          guards: [AuthRouteGuard()],
        ),
        AutoRoute(
          path: '/profile',
          page: ProfileRoute.page,
          guards: [
            AuthRouteGuard(),
            TenantRouteGuard(),
          ],
        ),
        AutoRoute(
          path: '/agenda',
          page: ScheduleRoute.page,
        ),
        AutoRoute(
          path: '/agenda/procurar',
          page: EventSearchRoute.page,
        ),
        AutoRoute(
          path: '/mapa',
          page: CityMapRoute.page,
        ),
        AutoRoute(
          path: '/mapa/poi',
          page: PoiDetailsRoute.page,
        ),
        AutoRoute(
          path: '/mercado',
          page: MercadoRoute.page,
        ),
        AutoRoute(
          path: '/mercado/produtor',
          page: ProducerStoreRoute.page,
        ),
        AutoRoute(
          path: '/experiencias',
          page: ExperiencesRoute.page,
        ),
        AutoRoute(
          path: '/experiencias/detalhe',
          page: ExperienceDetailRoute.page,
        ),
        ...childModules.expand((module) => module.routes),
      ];
}
