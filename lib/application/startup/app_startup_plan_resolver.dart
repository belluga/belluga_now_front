import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/startup/app_startup_navigation_plan.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/deferred_link_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:get_it/get_it.dart';

final class AppStartupPlanResolver {
  AppStartupPlanResolver({
    InvitesRepositoryContract? invitesRepository,
    AppDataRepositoryContract? appDataRepository,
    AuthRepositoryContract? authRepository,
    DeferredLinkRepositoryContract? deferredLinkRepository,
    TelemetryRepositoryContract? telemetryRepository,
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
                : null);

  final InvitesRepositoryContract _invitesRepository;
  final AppDataRepositoryContract _appDataRepository;
  final AuthRepositoryContract? _authRepository;
  final DeferredLinkRepositoryContract? _deferredLinkRepository;
  final TelemetryRepositoryContract? _telemetryRepository;

  AppData get appData => _appDataRepository.appData;

  Future<AppStartupNavigationPlan> resolvePlan() async {
    final authRepository = _authRepository;
    if (authRepository != null) {
      await authRepository.init();
    }

    await _invitesRepository.init();

    final deferredInvitePath = await _resolveDeferredInviteFirstOpenPath();
    if (deferredInvitePath != null && deferredInvitePath.isNotEmpty) {
      return AppStartupNavigationPlan.path(deferredInvitePath);
    }

    if (appData.typeValue.value == EnvironmentType.landlord) {
      return const AppStartupNavigationPlan.none();
    }

    if (_invitesRepository.hasPendingInvites.value) {
      return AppStartupNavigationPlan.routes(
        const <PageRouteInfo<dynamic>>[
          TenantHomeRoute(),
          InviteFlowRoute(),
        ],
      );
    }

    return const AppStartupNavigationPlan.none();
  }

  Future<String?> _resolveDeferredInviteFirstOpenPath() async {
    if (appData.typeValue.value == EnvironmentType.landlord) {
      return null;
    }

    final deferred = _deferredLinkRepository;
    if (deferred == null) {
      return null;
    }

    final result = await deferred.captureFirstOpenInviteCode();
    if (result.isCaptured) {
      final path = Uri(
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
      return path;
    }

    if (!result.shouldTrackFailure) {
      return null;
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
    return null;
  }
}
