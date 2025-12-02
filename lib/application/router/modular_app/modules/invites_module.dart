import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/contacts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/friends_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/contacts_repository.dart';
import 'package:belluga_now/infrastructure/repositories/friends_repository.dart';
import 'package:belluga_now/infrastructure/repositories/invites_repository.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_flow_screen/controllers/invite_flow_controller.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_share_screen/controllers/invite_share_screen_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class InvitesModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    if (!GetIt.I.isRegistered<FriendsRepositoryContract>()) {
      registerLazySingleton<FriendsRepositoryContract>(
        () => FriendsRepository(),
      );
    }

    if (!GetIt.I.isRegistered<ContactsRepositoryContract>()) {
      registerLazySingleton<ContactsRepositoryContract>(
        () => ContactsRepository(),
      );
    }

    if (!GetIt.I.isRegistered<InvitesRepositoryContract>()) {
      registerLazySingleton<InvitesRepositoryContract>(
        () => InvitesRepository(),
      );
    }

    registerLazySingleton<InviteFlowScreenController>(
      () => InviteFlowScreenController(),
    );
    registerLazySingleton<InviteShareScreenController>(
      () => InviteShareScreenController(),
    );
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/convites',
          page: InviteFlowRoute.page,
        ),
        AutoRoute(
          path: '/convites/compartilhar',
          page: InviteShareRoute.page,
        ),
      ];
}
