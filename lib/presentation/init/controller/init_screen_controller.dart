import 'package:auto_route/auto_route.dart';
import 'package:unifast_portal/application/router/app_router.gr.dart';
import 'package:unifast_portal/domain/controllers/belluga_init_screen_controller_contract.dart';
import 'package:stream_value/core/stream_value.dart';

final class InitScreenController extends BellugaInitScreenControllerContract {
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
    // await _initializeBehavior();
  }

  // _initializeBehavior() async {
  //   await _behaviorController.init();
  // }

  // openAPPEvent() {
  //   _behaviorController.saveEvent(type: EventTrackingTypes.openApp);
  // }

  PageRouteInfo _getInitialRoute() => const HomeRoute();
}
