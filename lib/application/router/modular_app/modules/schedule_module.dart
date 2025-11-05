import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/schedule_repository.dart';
import 'package:belluga_now/presentation/tenant/screens/schedule/controller/event_detail_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/schedule/controller/event_search_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/schedule/controller/schedule_screen_controller.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class ScheduleModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    registerLazySingleton<ScheduleRepositoryContract>(
      () => ScheduleRepository(),
    );

    registerLazySingleton(() => ScheduleScreenController());
    registerLazySingleton(() => EventSearchScreenController());
    registerFactory(() => EventDetailController());
  }

  @override
  List<AutoRoute> get routes => const [];
}
