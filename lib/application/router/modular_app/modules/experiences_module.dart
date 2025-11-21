import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/experiences_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/experiences_repository.dart';
import 'package:belluga_now/presentation/tenant/experiences/screens/experiences_screen/controllers/experiences_controller.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class ExperiencesModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    registerLazySingleton<ExperiencesRepositoryContract>(
      () => ExperiencesRepository(),
    );

    registerFactory<ExperiencesController>(() => ExperiencesController());
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/experiencias',
          page: ExperiencesRoute.page,
        ),
        AutoRoute(
          path: '/experiencias/detalhe',
          page: ExperienceDetailRoute.page,
        ),
      ];
}
