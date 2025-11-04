import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/invites_repository.dart';
import 'package:belluga_now/presentation/tenant/screens/invites/controller/invite_flow_controller.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class InvitesModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    registerLazySingleton<InvitesRepositoryContract>(
      () => InvitesRepository(),
    );

    registerFactory<InviteFlowController>(() => InviteFlowController());
  }

  @override
  List<AutoRoute> get routes => const [];
}
