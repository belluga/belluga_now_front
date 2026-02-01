import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/controllers/belluga_init_screen_controller_contract.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/push/push_presentation_gate_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:stream_value/core/stream_value.dart';

import 'package:get_it/get_it.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';

final class InitScreenController extends BellugaInitScreenControllerContract {
  InitScreenController({
    InvitesRepositoryContract? invitesRepository,
    AppDataRepositoryContract? appDataRepository,
    PushPresentationGateContract? pushPresentationGate,
  })  : _invitesRepository =
            invitesRepository ?? GetIt.I.get<InvitesRepositoryContract>(),
        _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>(),
        _pushPresentationGate = pushPresentationGate ??
            (GetIt.I.isRegistered<PushPresentationGateContract>()
                ? GetIt.I.get<PushPresentationGateContract>()
                : null);

  final InvitesRepositoryContract _invitesRepository;
  final AppDataRepositoryContract _appDataRepository;
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

  @override
  PageRouteInfo get initialRoute => _determinedRoute ?? const TenantHomeRoute();

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
    // loadingStatusStreamValue.addValue("É bom te ver por aqui!");
    // loadingStatusStreamValue.addValue("Ajustando últimos detalhes!");
    await _invitesRepository.init();

    if (_invitesRepository.hasPendingInvites) {
      _determinedRoute = const InviteFlowRoute();
    } else {
      _determinedRoute = const TenantHomeRoute();
    }
    // await _initializeBehavior();
  }

  void _updateUiState(InitScreenUiState state) {
    uiStateStreamValue.addValue(state);
  }

  // _initializeBehavior() async {
  //   await _behaviorController.init();
  // }

  // openAPPEvent() {
  //   _behaviorController.saveEvent(type: EventTrackingTypes.openApp);
  // }
}

class InitScreenUiState {
  static const _unset = Object();

  const InitScreenUiState({
    required this.errorMessage,
    required this.isRetrying,
  });

  factory InitScreenUiState.initial() =>
      const InitScreenUiState(errorMessage: null, isRetrying: false);

  final String? errorMessage;
  final bool isRetrying;

  InitScreenUiState copyWith({
    Object? errorMessage = _unset,
    bool? isRetrying,
  }) {
    final nextErrorMessage =
        errorMessage == _unset ? this.errorMessage : errorMessage as String?;
    return InitScreenUiState(
      errorMessage: nextErrorMessage,
      isRetrying: isRetrying ?? this.isRetrying,
    );
  }
}
