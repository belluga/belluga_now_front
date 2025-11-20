import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/controllers/belluga_init_screen_controller_contract.dart';
import 'package:stream_value/core/stream_value.dart';

import 'package:get_it/get_it.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';

final class InitScreenController extends BellugaInitScreenControllerContract {
  InitScreenController({
    InvitesRepositoryContract? invitesRepository,
  }) : _invitesRepository =
            invitesRepository ?? GetIt.I.get<InvitesRepositoryContract>();

  final InvitesRepositoryContract _invitesRepository;

  @override
  final loadingStatusStreamValue = StreamValue<String>(
    defaultValue: "Carregando",
  );

  @override
  PageRouteInfo get initialRoute => _getInitialRoute();

  @override
  Future<void> initialize() async {
    // loadingStatusStreamValue.addValue("É bom te ver por aqui!");
    // loadingStatusStreamValue.addValue("Ajustando últimos detalhes!");
    await _invitesRepository.init();
    // await _initializeBehavior();
  }

  // _initializeBehavior() async {
  //   await _behaviorController.init();
  // }

  // openAPPEvent() {
  //   _behaviorController.saveEvent(type: EventTrackingTypes.openApp);
  // }

  PageRouteInfo _getInitialRoute() {
    if (_invitesRepository.hasPendingInvites) {
      return const InviteFlowRoute();
    }
    return const TenantHomeRoute();
  }
}
