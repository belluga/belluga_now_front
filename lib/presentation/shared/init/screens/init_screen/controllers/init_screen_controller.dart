export 'init_screen_ui_state.dart';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:belluga_now/domain/controllers/belluga_init_screen_controller_contract.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/push/push_presentation_gate_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/deferred_link_repository_contract.dart';
import 'package:belluga_now/presentation/shared/init/screens/init_screen/controllers/init_screen_ui_state.dart';
import 'package:stream_value/core/stream_value.dart';

import 'package:get_it/get_it.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';

final class InitScreenController extends BellugaInitScreenControllerContract {
  InitScreenController({
    InvitesRepositoryContract? invitesRepository,
    AppDataRepositoryContract? appDataRepository,
    AuthRepositoryContract? authRepository,
    DeferredLinkRepositoryContract? deferredLinkRepository,
    TelemetryRepositoryContract? telemetryRepository,
    PushPresentationGateContract? pushPresentationGate,
  })  : _invitesRepository =
            invitesRepository ?? GetIt.I.get<InvitesRepositoryContract>(),
        _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>(),
        _authRepository = authRepository ??
            (GetIt.I.isRegistered<AuthRepositoryContract>()
                ? GetIt.I.get<AuthRepositoryContract>()
                : null),
        _deferredLinkRepository = deferredLinkRepository ??
            (GetIt.I.isRegistered<DeferredLinkRepositoryContract>()
                ? GetIt.I.get<DeferredLinkRepositoryContract>()
                : null),
        _telemetryRepository = telemetryRepository ??
            (GetIt.I.isRegistered<TelemetryRepositoryContract>()
                ? GetIt.I.get<TelemetryRepositoryContract>()
                : null),
        _pushPresentationGate = pushPresentationGate ??
            (GetIt.I.isRegistered<PushPresentationGateContract>()
                ? GetIt.I.get<PushPresentationGateContract>()
                : null);

  final InvitesRepositoryContract _invitesRepository;
  final AppDataRepositoryContract _appDataRepository;
  final AuthRepositoryContract? _authRepository;
  final DeferredLinkRepositoryContract? _deferredLinkRepository;
  final TelemetryRepositoryContract? _telemetryRepository;
  final PushPresentationGateContract? _pushPresentationGate;

  @override
  final loadingStatusStreamValue = StreamValue<String>(
    defaultValue: "Carregando",
  );
  final StreamValue<InitScreenUiState> uiStateStreamValue =
      StreamValue<InitScreenUiState>(
    defaultValue: InitScreenUiState.initial(),
  );

  PageRouteInfo? _determinedRoute;
  String? _initialRoutePath;

  @override
  PageRouteInfo get initialRoute =>
      _determinedRoute ?? _homeRouteForEnvironment();

  String? get initialRoutePath => _initialRoutePath;

  List<PageRouteInfo> get initialRouteStack {
    final route = initialRoute;
    if (route is InviteFlowRoute) {
      return [
        _homeRouteForEnvironment(),
        route,
      ];
    }
    return [route];
  }

  AppData get appData => _appDataRepository.appData;

  void resetUiState() {
    _updateUiState(InitScreenUiState.initial());
  }

  void setRetrying(bool isRetrying) {
    _updateUiState(
      uiStateStreamValue.value.copyWith(isRetrying: isRetrying),
    );
  }

  void setErrorMessage(String? message) {
    _updateUiState(
      uiStateStreamValue.value.copyWith(errorMessage: message),
    );
  }

  void markPushReady() {
    _pushPresentationGate?.markReady();
  }

  @override
  Future<void> initialize() async {
    final authRepository = _authRepository;
    if (authRepository != null) {
      await authRepository.init();
    }
    // loadingStatusStreamValue.addValue("É bom te ver por aqui!");
    // loadingStatusStreamValue.addValue("Ajustando últimos detalhes!");
    await _invitesRepository.init();
    await _resolveDeferredInviteFirstOpenPath();
    _determinedRoute = _resolveInitialRoute();
    // await _initializeBehavior();
  }

  Future<void> _resolveDeferredInviteFirstOpenPath() async {
    _initialRoutePath = null;

    if (appData.typeValue.value == EnvironmentType.landlord) {
      return;
    }

    final deferred = _deferredLinkRepository;
    if (deferred == null) {
      return;
    }

    final result = await deferred.captureFirstOpenInviteCode();
    if (result.isCaptured) {
      _initialRoutePath = Uri(
        path: '/invite',
        queryParameters: <String, String>{
          'code': result.code!,
        },
      ).toString();
      await _telemetryRepository?.logEvent(
        EventTrackerEvents.buttonClick,
        eventName: telemetryRepoString('app_deferred_deep_link_captured'),
        properties: telemetryRepoMap(<String, dynamic>{
          'code': result.code,
          'platform': 'android',
          if (result.storeChannel != null) 'store_channel': result.storeChannel,
        }),
      );
      return;
    }

    if (!result.shouldTrackFailure) {
      return;
    }

    await _telemetryRepository?.logEvent(
      EventTrackerEvents.buttonClick,
      eventName: telemetryRepoString('app_deferred_deep_link_capture_failed'),
      properties: telemetryRepoMap(<String, dynamic>{
        'platform': 'android',
        'failure_reason': result.failureReason,
        if (result.storeChannel != null) 'store_channel': result.storeChannel,
      }),
    );
  }

  PageRouteInfo _resolveInitialRoute() {
    if (appData.typeValue.value == EnvironmentType.landlord) {
      return const LandlordHomeRoute();
    }

    if (_invitesRepository.hasPendingInvites.value) {
      return const InviteFlowRoute();
    }

    return const TenantHomeRoute();
  }

  PageRouteInfo _homeRouteForEnvironment() {
    if (appData.typeValue.value == EnvironmentType.landlord) {
      return const LandlordHomeRoute();
    }
    return const TenantHomeRoute();
  }

  void _updateUiState(InitScreenUiState state) {
    uiStateStreamValue.addValue(state);
  }

  @override
  void onDispose() {
    loadingStatusStreamValue.dispose();
    uiStateStreamValue.dispose();
  }

  // _initializeBehavior() async {
  //   await _behaviorController.init();
  // }

  // openAPPEvent() {
  //   _behaviorController.saveEvent(type: EventTrackingTypes.openApp);
  // }
}
