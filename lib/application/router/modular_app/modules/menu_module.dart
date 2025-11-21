import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class MenuModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    // Menu screen doesn't have a controller currently
    // Add dependencies here if needed in the future
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/menu',
          page: TenantMenuRoute.page,
        ),
      ];
}
