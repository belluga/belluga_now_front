export 'init_screen_ui_state.dart';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/startup/app_startup_navigation_plan.dart';
import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:belluga_now/domain/controllers/belluga_init_screen_controller_contract.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
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
import 'package:flutter/foundation.dart';

final class InitScreenController extends BellugaInitScreenControllerContract {
  InitScreenController({
    InvitesRepositoryContract? invitesRepository,
    AppDataRepositoryContract? appDataRepository,
    AuthRepositoryContract? authRepository,
    DeferredLinkRepositoryContract? deferredLinkRepository,
    TelemetryRepositoryContract? telemetryRepository,
    List<Duration>? startupRetryDelays,
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
        _startupRetryDelays = List<Duration>.unmodifiable(
          startupRetryDelays ?? _defaultStartupRetryDelays,
        );

  final InvitesRepositoryContract _invitesRepository;
  final AppDataRepositoryContract _appDataRepository;
  final AuthRepositoryContract? _authRepository;
  final DeferredLinkRepositoryContract? _deferredLinkRepository;
  final TelemetryRepositoryContract? _telemetryRepository;
  final List<Duration> _startupRetryDelays;
  static const List<Duration> _defaultStartupRetryDelays = <Duration>[
    Duration(milliseconds: 250),
    Duration(milliseconds: 500),
    Duration(milliseconds: 750),
    Duration(milliseconds: 1000),
    Duration(milliseconds: 1250),
    Duration(milliseconds: 1500),
    Duration(milliseconds: 1750),
    Duration(milliseconds: 2000),
    Duration(milliseconds: 2500),
  ];

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

  AppStartupNavigationPlan get startupNavigationPlan {
    final path = initialRoutePath;
    if (path != null && path.isNotEmpty) {
      return AppStartupNavigationPlan.path(path);
    }
    final stack = initialRouteStack;
    if (stack.length > 1) {
      return AppStartupNavigationPlan.routes(stack);
    }
    return const AppStartupNavigationPlan.none();
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

  @override
  Future<void> initialize() async {
    await _runStartupSequenceWithRetry();
  }

  Future<void> _runStartupSequenceWithRetry() async {
    Object? lastError;
    StackTrace? lastStackTrace;
    final attempts = 1 + _startupRetryDelays.length;

    for (var attempt = 0; attempt < attempts; attempt += 1) {
      try {
        await _runStartupSequence();
        return;
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
        if (attempt >= _startupRetryDelays.length) {
          Error.throwWithStackTrace(error, stackTrace);
        }
        final delay = _startupRetryDelays[attempt];
        if (delay > Duration.zero) {
          await Future<void>.delayed(delay);
        }
      }
    }

    final error = lastError ?? StateError('Init startup bootstrap failed.');
    final stackTrace = lastStackTrace ?? StackTrace.current;
    Error.throwWithStackTrace(error, stackTrace);
  }

  Future<void> _runStartupSequence() async {
    _determinedRoute = null;
    _initialRoutePath = null;
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

    DeferredLinkCaptureResult result;
    try {
      result = await deferred.captureFirstOpenInviteCode();
    } catch (error, stackTrace) {
      debugPrint(
        'InitScreenController deferred invite capture failed; '
        'continuing without deferred override: $error\n$stackTrace',
      );
      return;
    }
    if (result.isCaptured) {
      final storeChannel = result.storeChannel ?? 'unknown';
      _initialRoutePath = result.targetPath;
      await _logStartupTelemetryBestEffort(
        EventTrackerEvents.buttonClick,
        eventName: telemetryRepoString('app_deferred_deep_link_captured'),
        properties: telemetryRepoMap(<String, dynamic>{
          if (result.code != null) 'code': result.code,
          'target_path': result.targetPath,
          'platform': 'android',
          'store_channel': storeChannel,
        }),
      );
      return;
    }

    if (!result.shouldTrackFailure) {
      return;
    }

    final storeChannel = result.storeChannel ?? 'unknown';
    await _logStartupTelemetryBestEffort(
      EventTrackerEvents.buttonClick,
      eventName: telemetryRepoString('app_deferred_deep_link_capture_failed'),
      properties: telemetryRepoMap(<String, dynamic>{
        'platform': 'android',
        'failure_reason': result.failureReason,
        'store_channel': storeChannel,
      }),
    );
  }

  Future<void> _logStartupTelemetryBestEffort(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async {
    try {
      await _telemetryRepository?.logEvent(
        event,
        eventName: eventName,
        properties: properties,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'InitScreenController startup telemetry failed; '
        'continuing bootstrap: $error\n$stackTrace',
      );
    }
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
