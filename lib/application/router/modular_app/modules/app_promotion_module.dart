import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/route_redirect_path.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_screen_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class AppPromotionModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    registerLazySingleton<AppPromotionScreenController>(
      () => AppPromotionScreenController(
        appDataRepository: GetIt.I.get<AppDataRepositoryContract>(),
      ),
    );
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: webPromotionRoutePath,
          page: AppPromotionRoute.page,
        ),
      ];
}
