import 'package:auto_route/auto_route.dart';
import 'package:flutter_laravel_backend_boilerplate/application/router/app_router.gr.dart';
import 'package:flutter_laravel_backend_boilerplate/application/router/guards/route_guard_auth.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(path: "/init", page: InitRoute.page, initial: true),
    AutoRoute(path: "/", page: HomeRoute.page),
    AutoRoute(
      path: "/dashboard",
      page: DashboardRoute.page,
      guards: [AuthGuard()],
    ),
    AutoRoute(path: "/login", page: AuthLoginRoute.page),
    AutoRoute(path: "/recover_password", page: RecoveryPasswordRoute.page),
    // AutoRoute(page: AuthPasswordRecoverRoute.page),
    // AutoRoute(page: AuthPasswordRecoverConfirmationRoute.page),
    AutoRoute(path: "/profile", page: ProfileRoute.page),
    AutoRoute(page: LessonRoute.page),
  ];
}
