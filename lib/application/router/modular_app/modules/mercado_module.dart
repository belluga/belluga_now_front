import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant/mercado/screens/mercado_screen/controllers/mercado_controller.dart';
import 'package:belluga_now/presentation/tenant/mercado/screens/producer_store_screen/controllers/producer_store_controller.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class MercadoModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    registerLazySingleton<MercadoController>(() => MercadoController());
    registerLazySingleton<ProducerStoreController>(
      () => ProducerStoreController(),
    );
  }

  @override
  List<AutoRoute> get routes => const [];
}
