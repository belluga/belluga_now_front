import 'dart:async';
import 'package:belluga_now/testing/domain_factories.dart';
import 'dart:io';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/testing/invite_accept_result_builder.dart';
import 'package:belluga_now/testing/invite_materialize_result_builder.dart';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/application/router/support/route_instance_scope.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_inviter.dart';
import 'package:belluga_now/domain/invites/invite_inviter_type.dart';
import 'package:belluga_now/domain/invites/invite_materialize_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_sender_display_name_candidate_value.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/event_profile_group.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_linked_account_profile_text_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_profile_group_order_value.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_type_value.dart';
import 'package:belluga_now/domain/upcoming_ocurrence/projections/upcoming_ocurrence_resume.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/controllers/invite_flow_controller.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/invite_flow_screen.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/widgets/invite_flow_coordinator.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:belluga_now/testing/invite_model_factory.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/infrastructure/dal/dto/invites/invite_dto.dart';

class _FakeInvitesRepository extends InvitesRepositoryContract {
  _FakeInvitesRepository({
    required List<InviteModel> initialInvites,
    this.materializedInviteId,
    this.materializeStatus,
  }) : _invites = List<InviteModel>.from(initialInvites);

  final List<InviteModel> _invites;
  final List<String> previewedShareCodes = <String>[];
  final String? materializedInviteId;
  final String? materializeStatus;
  bool failFetch = false;
  bool failMaterialization = false;
  final List<String> materializedShareCodes = <String>[];
  final List<String> acceptedInviteIds = <String>[];
  final List<String> acceptedShareCodes = <String>[];
  final List<String> declinedInviteIds = <String>[];

  @override
  Future<List<InviteModel>> fetchInvites({
    InvitesRepositoryContractPrimInt? page,
    InvitesRepositoryContractPrimInt? pageSize,
  }) async {
    if (failFetch) {
      throw StateError('invite refresh failed');
    }
    return List<InviteModel>.from(_invites);
  }

  void replaceInvites(List<InviteModel> invites) {
    _invites
      ..clear()
      ..addAll(invites);
  }

  @override
  Future<InviteRuntimeSettings> fetchSettings() async =>
      buildInviteRuntimeSettings(
        tenantId: null,
        limits: {},
        cooldowns: {},
        overQuotaMessage: null,
      );

  @override
  Future<InviteAcceptResult> acceptInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) async => (() {
    acceptedInviteIds.add(inviteId.value);
    _removeInvite(inviteId.value);
    pendingInvitesStreamValue.addValue(List<InviteModel>.from(_invites));
    return buildInviteAcceptResult(
      inviteId: inviteId.value,
      status: 'accepted',
      creditedAcceptance: true,
      attendancePolicy: 'free_confirmation_only',
      nextStep: InviteNextStep.freeConfirmationCreated,
      supersededInviteIds: const [],
    );
  })();

  @override
  Future<InviteAcceptResult> acceptInviteByCode(
    InvitesRepositoryContractPrimString code,
  ) async {
    acceptedShareCodes.add(code.value);
    return buildInviteAcceptResult(
      inviteId: 'mock-${code.value}',
      status: 'accepted',
      creditedAcceptance: true,
      attendancePolicy: 'free_confirmation_only',
      nextStep: InviteNextStep.freeConfirmationCreated,
      supersededInviteIds: const [],
    );
  }

  @override
  Future<InviteDeclineResult> declineInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) async => (() {
    declinedInviteIds.add(inviteId.value);
    _removeInvite(inviteId.value);
    pendingInvitesStreamValue.addValue(List<InviteModel>.from(_invites));
    return buildInviteDeclineResult(
      inviteId: inviteId.value,
      status: 'declined',
      groupHasOtherPending: false,
    );
  })();

  @override
  Future<InviteMaterializeResult> materializeShareCode(
    InvitesRepositoryContractPrimString code,
  ) async {
    materializedShareCodes.add(code.value);
    if (failMaterialization) {
      throw StateError('share-code materialization failed');
    }
    return buildInviteMaterializeResult(
      inviteId: materializedInviteId ?? '',
      status:
          materializeStatus ??
          (materializedInviteId == null ? 'expired' : 'pending'),
      creditedAcceptance: false,
      attendancePolicy: 'free_confirmation_only',
    );
  }

  @override
  Future<InviteModel?> previewShareCode(
    InvitesRepositoryContractPrimString code,
  ) async {
    previewedShareCodes.add(code.value);
    if (_invites.isEmpty) {
      return null;
    }
    return _invites.first;
  }

  void _removeInvite(String inviteId) {
    final inviteIdValue = InviteIdValue()..parse(inviteId);
    _invites.removeWhere(
      (invite) =>
          invite.id == inviteId || invite.containsInviteId(inviteIdValue),
    );
  }

  @override
  Future<List<InviteContactMatch>> importContacts(
    InviteContacts contacts,
  ) async => const [];

  @override
  Future<InviteShareCodeResult> createShareCode({
    required InvitesRepositoryContractPrimString eventId,
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? accountProfileId,
  }) async => buildInviteShareCodeResult(
    code: 'CODE123',
    eventId: eventId.value,
    occurrenceId: occurrenceId?.value ?? 'occurrence-1',
  );

  @override
  Future<void> sendInvites(
    InvitesRepositoryContractPrimString eventSlug,
    InviteRecipients recipients, {
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? message,
  }) async {}

  @override
  Future<List<SentInviteStatus>> getSentInvitesForOccurrence(
    InvitesRepositoryContractPrimString eventSlug,
  ) async => const [];
}

class _FakeTelemetryRepository implements TelemetryRepositoryContract {
  @override
  Future<TelemetryRepositoryContractPrimBool> logEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async => telemetryRepoBool(true);

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async => const EventTrackerTimedEventHandle('handle');

  @override
  Future<TelemetryRepositoryContractPrimBool> finishTimedEvent(
    EventTrackerTimedEventHandle handle,
  ) async => telemetryRepoBool(true);

  @override
  Future<TelemetryRepositoryContractPrimBool> flushTimedEvents() async =>
      telemetryRepoBool(true);

  @override
  void setScreenContext(TelemetryRepositoryContractPrimMap? screenContext) {}

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<TelemetryRepositoryContractPrimBool> mergeIdentity({
    required TelemetryRepositoryContractPrimString previousUserId,
  }) async => telemetryRepoBool(true);
}

class _FakeUserEventsRepository implements UserEventsRepositoryContract {
  @override
  void clearCurrentIdentityState() {}

  @override
  final StreamValue<Set<UserEventsRepositoryContractPrimString>>
  confirmedOccurrenceIdsStream =
      StreamValue<Set<UserEventsRepositoryContractPrimString>>(
        defaultValue: const {},
      );

  @override
  Future<List<UpcomingOcurrenceResume>> fetchMyEvents() async => const [];

  @override
  Future<List<UpcomingOcurrenceResume>> fetchFeaturedEvents() async => const [];

  @override
  Future<void> confirmEventAttendance(
    UserEventsRepositoryContractPrimString eventId, {
    required UserEventsRepositoryContractPrimString occurrenceId,
  }) async {}

  @override
  Future<void> unconfirmEventAttendance(
    UserEventsRepositoryContractPrimString eventId, {
    required UserEventsRepositoryContractPrimString occurrenceId,
  }) async {}

  @override
  Future<void> refreshConfirmedOccurrenceIds() async {}

  @override
  UserEventsRepositoryContractPrimBool isOccurrenceConfirmed(
    UserEventsRepositoryContractPrimString eventId,
  ) => userEventsRepoBool(false, defaultValue: false, isRequired: true);
}

class _RecordingStackRouter extends Mock implements StackRouter {
  _RecordingStackRouter({required this.canPopValue});

  final bool canPopValue;
  String? lastPushedPath;
  bool pushCalled = false;
  PageRouteInfo? lastPushed;
  bool replaceAllCalled = false;
  List<PageRouteInfo>? lastReplaced;
  String? lastReplacedPath;
  bool popCalled = false;
  RouteData? activeRoute;

  @override
  RootStackRouter get root => _FakeRootStackRouter('/convites');

  @override
  RouteData get topRoute => activeRoute!;

  @override
  bool get hasPagelessTopRoute => false;

  @override
  bool canPop({
    bool ignoreChildRoutes = false,
    bool ignoreParentRoutes = false,
    bool ignorePagelessRoutes = false,
  }) {
    return canPopValue;
  }

  @override
  Future<T?> push<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) async {
    pushCalled = true;
    lastPushed = route;
    return null;
  }

  @override
  Future<T?> pushPath<T extends Object?>(
    String path, {
    bool includePrefixMatches = false,
    OnNavigationFailure? onFailure,
  }) async {
    lastPushedPath = path;
    return null;
  }

  @override
  Future<void> replaceAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
    bool updateExistingRoutes = true,
  }) async {
    replaceAllCalled = true;
    lastReplaced = routes;
  }

  @override
  Future<T?> replacePath<T extends Object?>(
    String path, {
    bool includePrefixMatches = false,
    OnNavigationFailure? onFailure,
  }) async {
    lastReplacedPath = path;
    return null;
  }

  @override
  void pop<T extends Object?>([T? result]) {
    popCalled = true;
  }
}

class _FakeRootStackRouter extends Fake implements RootStackRouter {
  _FakeRootStackRouter(this.currentPath);

  @override
  final String currentPath;

  @override
  Object? get pathState => null;

  @override
  RootStackRouter get root => this;
}

void main() {
  HttpOverrides? previousHttpOverrides;

  setUpAll(() async {
    previousHttpOverrides = HttpOverrides.current;
    HttpOverrides.global = _TestHttpOverrides();
    await initializeDateFormatting('pt_BR');
  });

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AppData>(_buildAppData());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  tearDownAll(() {
    HttpOverrides.global = previousHttpOverrides;
  });

  testWidgets('FRC invite terminal navigation', (tester) async {
    const supportedScenarios = <String>{
      'repopulation_before_effect',
      'refresh_failure',
      'materialization_failure',
      'disposed_callback',
      'repeated_terminal_callback',
      'page_child_serialization',
      'owned_pageless_serialization',
      'external_cover_drop',
      'awaited_return',
    };
    final scenario =
        Platform.environment['DELPHI_RACE_SCENARIO'] ??
        'repeated_terminal_callback';
    final burst =
        int.tryParse(Platform.environment['DELPHI_RACE_BURST_LEVEL'] ?? '') ??
        1;

    expect(supportedScenarios, contains(scenario));
    expect(burst, greaterThan(0));
    // Probe metadata is optional so this focused test remains runnable through
    // the ordinary Flutter suite as well as the FRC wrapper.
    final repeatIndex = Platform.environment['DELPHI_RACE_REPEAT_INDEX'];
    final attemptDir = Platform.environment['DELPHI_RACE_ATTEMPT_DIR'];
    final outputDir = Platform.environment['DELPHI_RACE_OUTPUT_DIR'];
    if (repeatIndex != null || attemptDir != null || outputDir != null) {
      expect(repeatIndex, isNotNull);
      expect(attemptDir, isNotNull);
      expect(outputDir, isNotNull);
    }

    final invite = scenario == 'owned_pageless_serialization'
        ? _buildInviteWithSelectableCandidates('frc')
        : _buildInvite('frc');
    final harness = await _pumpSemanticFrcHarness(tester, invite: invite);
    expect(harness.names, <String>[TenantHomeRoute.name, InviteFlowRoute.name]);

    switch (scenario) {
      case 'repopulation_before_effect':
        for (var callback = 0; callback < burst; callback += 1) {
          harness.controller.removeInvite();
          await _materializeTerminalBuild(tester, harness);
          harness.controller.addInvite(invite);
          await _buildDirtyWidgetsWithoutPostFrame(tester);
          expect(_coordinatorInvites(tester), [invite]);
        }
        expect(harness.materializedTerminalBuilds, burst);
        expect(harness.navigationObserver.popCount, 0);
        await _flushFrc(tester);
        expect(harness.names, <String>[
          TenantHomeRoute.name,
          InviteFlowRoute.name,
        ]);
        expect(harness.controller.displayInvitesStreamValue.value, [invite]);
        expect(harness.navigationObserver.popCount, 0);
        break;
      case 'refresh_failure':
        harness.repository.failFetch = true;
        await Future.wait<bool>(
          List<Future<bool>>.generate(
            burst,
            (_) => harness.controller.fetchPendingInvites(),
          ),
        );
        await _flushFrc(tester);
        expect(harness.names, <String>[
          TenantHomeRoute.name,
          InviteFlowRoute.name,
        ]);
        expect(harness.controller.displayInvitesStreamValue.value, [invite]);
        break;
      case 'materialization_failure':
        harness.repository.failMaterialization = true;
        await Future.wait<void>(
          List<Future<void>>.generate(
            burst,
            (_) => harness.controller.init(shareCode: 'FRC-CODE'),
          ),
        );
        await _flushFrc(tester);
        expect(harness.names, <String>[
          TenantHomeRoute.name,
          InviteFlowRoute.name,
        ]);
        expect(harness.controller.initializedStreamValue.value, isFalse);
        break;
      case 'disposed_callback':
        for (var callback = 0; callback < burst; callback += 1) {
          harness.repository.setInviteFlowDisplayInvites(const <InviteModel>[]);
          await _materializeTerminalBuild(tester, harness);
          if (callback + 1 < burst) {
            harness.repository.setInviteFlowDisplayInvites(<InviteModel>[
              invite,
            ]);
            await _buildDirtyWidgetsWithoutPostFrame(tester);
            expect(_coordinatorInvites(tester), [invite]);
          }
        }
        expect(harness.materializedTerminalBuilds, burst);
        expect(harness.navigationObserver.popCount, 0);
        harness.router.replaceAll(const <PageRouteInfo<dynamic>>[
          TenantHomeRoute(),
        ]);
        await tester.pumpWidget(
          const SizedBox.shrink(),
          phase: EnginePhase.build,
        );
        expect(find.byType(InviteFlowScreen), findsNothing);
        await _flushFrc(tester);
        expect(harness.names, <String>[TenantHomeRoute.name]);
        expect(harness.navigationObserver.popCount, 0);
        break;
      case 'repeated_terminal_callback':
        for (var callback = 0; callback < burst; callback += 1) {
          harness.repository.setInviteFlowDisplayInvites(const <InviteModel>[]);
          await _materializeTerminalBuild(tester, harness);
          if (callback + 1 < burst) {
            harness.repository.setInviteFlowDisplayInvites(<InviteModel>[
              invite,
            ]);
            await _buildDirtyWidgetsWithoutPostFrame(tester);
            expect(_coordinatorInvites(tester), [invite]);
          }
        }
        expect(harness.materializedTerminalBuilds, burst);
        expect(harness.navigationObserver.popCount, 0);
        await _flushFrc(tester);
        expect(harness.names, <String>[TenantHomeRoute.name]);
        expect(harness.navigationObserver.popCount, 1);
        break;
      case 'page_child_serialization':
      case 'awaited_return':
        harness.controller.markImageLoaded(invite.eventImageUrl);
        await _flushFrc(tester);
        await tester.tap(find.text('Ver detalhes'));
        await _flushFrc(tester);
        expect(harness.names.last, ImmersiveEventDetailRoute.name);
        harness.repository.replaceInvites(const <InviteModel>[]);
        await Future.wait<bool>(
          List<Future<bool>>.generate(
            burst,
            (_) => harness.controller.fetchPendingInvites(),
          ),
        );
        await _flushFrc(tester);
        expect(harness.names, <String>[
          TenantHomeRoute.name,
          InviteFlowRoute.name,
          ImmersiveEventDetailRoute.name,
        ]);
        await tester.binding.handlePopRoute();
        await _flushFrc(tester);
        expect(harness.names, <String>[TenantHomeRoute.name]);
        break;
      case 'owned_pageless_serialization':
        harness.controller.markImageLoaded(invite.eventImageUrl);
        await _flushFrc(tester);
        await tester.tap(find.text('Aceitar'));
        await _flushFrc(tester);
        expect(find.text('Aceitar com quem te convidou'), findsOneWidget);
        harness.repository.replaceInvites(const <InviteModel>[]);
        await Future.wait<bool>(
          List<Future<bool>>.generate(
            burst,
            (_) => harness.controller.fetchPendingInvites(),
          ),
        );
        await _flushFrc(tester);
        expect(harness.names, <String>[
          TenantHomeRoute.name,
          InviteFlowRoute.name,
        ]);
        await tester.binding.handlePopRoute();
        await _flushFrc(tester);
        expect(harness.names, <String>[TenantHomeRoute.name]);
        break;
      case 'external_cover_drop':
        final inviteContext = tester.element(find.byType(InviteFlowScreen));
        final dialog = showDialog<void>(
          context: inviteContext,
          builder: (_) => const AlertDialog(title: Text('external-cover')),
        );
        await _flushFrc(tester);
        expect(find.text('external-cover'), findsOneWidget);
        harness.repository.replaceInvites(const <InviteModel>[]);
        await Future.wait<bool>(
          List<Future<bool>>.generate(
            burst,
            (_) => harness.controller.fetchPendingInvites(),
          ),
        );
        await _flushFrc(tester);
        expect(harness.names, <String>[
          TenantHomeRoute.name,
          InviteFlowRoute.name,
        ]);
        await tester.binding.handlePopRoute();
        await dialog;
        await _flushFrc(tester);
        expect(harness.names, <String>[
          TenantHomeRoute.name,
          InviteFlowRoute.name,
        ]);
        break;
    }
  });

  testWidgets('Decision result pushes InviteShareRoute', (tester) async {
    final invite = _buildInvite('1');
    final controller = InviteFlowScreenController(
      repository: _FakeInvitesRepository(initialInvites: [invite]),
      userEventsRepository: _FakeUserEventsRepository(),
      telemetryRepository: _FakeTelemetryRepository(),
    );
    GetIt.I.registerSingleton<InviteFlowScreenController>(controller);

    final router = _RecordingStackRouter(canPopValue: true);
    final routeData = _buildRouteData(router, queryParams: const {});

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: RouteDataScope(
            routeData: routeData,
            child: const InviteFlowScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    controller.decisionResultStreamValue.addValue(
      InviteDecisionResult(invite: invite, queued: false),
    );
    await tester.pump();

    expect(router.pushCalled, isTrue);
    expect(router.lastPushed, isA<InviteShareRoute>());
  });

  testWidgets('Authenticated invite shows decline/accept contract', (
    tester,
  ) async {
    final invite = _buildInvite('1');
    final controller = InviteFlowScreenController(
      repository: _FakeInvitesRepository(initialInvites: [invite]),
      userEventsRepository: _FakeUserEventsRepository(),
      telemetryRepository: _FakeTelemetryRepository(),
      authRepository: _FakeAuthRepository(authorized: true),
    );
    GetIt.I.registerSingleton<InviteFlowScreenController>(controller);

    final router = _RecordingStackRouter(canPopValue: true);
    final routeData = _buildRouteData(
      router,
      path: '/invite',
      queryParams: const {},
    );

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: RouteDataScope(
            routeData: routeData,
            child: const InviteFlowScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    controller.markImageLoaded(invite.eventImageUrl);
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 150));
      if (find.text('Recusar').evaluate().isNotEmpty &&
          find.text('Aceitar').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.text('Recusar'), findsOneWidget);
    expect(find.text('Aceitar'), findsOneWidget);
    expect(find.text('Ver detalhes'), findsOneWidget);
    expect(find.bySemanticsLabel(invite.eventName), findsWidgets);
    expect(find.byIcon(Icons.swipe), findsOneWidget);
    expect(find.text('Entre para Aceitar ou Recusar'), findsNothing);
  });

  testWidgets('Empty invites exit to home route', (tester) async {
    final controller = InviteFlowScreenController(
      repository: _FakeInvitesRepository(initialInvites: const []),
      userEventsRepository: _FakeUserEventsRepository(),
      telemetryRepository: _FakeTelemetryRepository(),
    );
    GetIt.I.registerSingleton<InviteFlowScreenController>(controller);

    final router = _RecordingStackRouter(canPopValue: false);
    final routeData = _buildRouteData(router, queryParams: const {});

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: RouteDataScope(
            routeData: routeData,
            child: const InviteFlowScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(router.lastReplacedPath, isNull);
  });

  testWidgets('Invite flow ignores legacy public fallback query input', (
    tester,
  ) async {
    final controller = InviteFlowScreenController(
      repository: _FakeInvitesRepository(initialInvites: const []),
      userEventsRepository: _FakeUserEventsRepository(),
      telemetryRepository: _FakeTelemetryRepository(),
    );
    GetIt.I.registerSingleton<InviteFlowScreenController>(controller);

    final router = _RecordingStackRouter(canPopValue: false);
    final routeData = _buildRouteData(
      router,
      path: '/invite',
      queryParams: const {
        'fallback': '/agenda/evento/event-1?occurrence=occ-1',
      },
    );

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: RouteDataScope(
            routeData: routeData,
            child: const InviteFlowScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(router.lastReplacedPath, isNull);
  });

  testWidgets('Ver detalhes opens public event route using invite slug', (
    tester,
  ) async {
    final invite = buildInviteModelFromPrimitives(
      id: 'invite-1',
      eventId: '665f0c8f8c9b7c0012ab34cd',
      eventSlug: 'pw-event-share-boundary-store-release-5',
      eventName: 'Invite Event',
      eventDateTime: DateTime(2026, 1, 1, 18),
      eventImageUrl: 'https://example.com/event.jpg',
      location: 'Guarapari',
      hostName: 'Belluga',
      message: 'Bora?',
      tags: const ['music'],
      occurrenceId: 'occ-1',
    );
    final controller = InviteFlowScreenController(
      repository: _FakeInvitesRepository(initialInvites: [invite]),
      userEventsRepository: _FakeUserEventsRepository(),
      telemetryRepository: _FakeTelemetryRepository(),
    );
    GetIt.I.registerSingleton<InviteFlowScreenController>(controller);

    final router = _RecordingStackRouter(canPopValue: true);
    final routeData = _buildRouteData(router, queryParams: const {});

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: RouteDataScope(
            routeData: routeData,
            child: const InviteFlowScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    controller.markImageLoaded(invite.eventImageUrl);
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 150));
      if (find.text('Ver detalhes').evaluate().isNotEmpty) {
        break;
      }
    }

    await tester.tap(find.text('Ver detalhes'));
    await tester.pumpAndSettle();

    expect(router.lastPushed, isA<ImmersiveEventDetailRoute>());
    final route = router.lastPushed! as ImmersiveEventDetailRoute;
    expect(route.args?.eventSlug, 'pw-event-share-boundary-store-release-5');
    expect(route.args?.occurrenceId, 'occ-1');
  });

  testWidgets(
    'Ver detalhes shows feedback instead of navigating when invite slug is absent',
    (tester) async {
      final invite = InviteDto(
        id: 'invite-1',
        eventId: '665f0c8f8c9b7c0012ab34cd',
        eventSlug: '',
        eventName: 'Invite Event',
        eventDate: '2026-01-01T18:00:00.000',
        eventImageUrl: 'https://example.com/event.jpg',
        location: 'Guarapari',
        hostName: 'Belluga',
        message: 'Bora?',
        tags: const ['music'],
        attendancePolicy: 'free_confirmation_only',
        additionalInviters: const [],
        inviterCandidates: const [],
        occurrenceId: 'occ-1',
      ).toDomain();
      final controller = InviteFlowScreenController(
        repository: _FakeInvitesRepository(initialInvites: [invite]),
        userEventsRepository: _FakeUserEventsRepository(),
        telemetryRepository: _FakeTelemetryRepository(),
      );
      GetIt.I.registerSingleton<InviteFlowScreenController>(controller);

      final router = _RecordingStackRouter(canPopValue: true);
      final routeData = _buildRouteData(router, queryParams: const {});

      await tester.pumpWidget(
        StackRouterScope(
          controller: router,
          stateHash: 0,
          child: MaterialApp(
            home: RouteDataScope(
              routeData: routeData,
              child: const InviteFlowScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.text('Ver detalhes'));
      await tester.pumpAndSettle();

      expect(router.lastPushed, isNull);
      expect(
        find.text('Os detalhes deste evento ainda não estão disponíveis.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Invite flow shows loading state before initialization', (
    tester,
  ) async {
    final controller = InviteFlowScreenController(
      repository: _FakeInvitesRepository(initialInvites: const []),
      userEventsRepository: _FakeUserEventsRepository(),
      telemetryRepository: _FakeTelemetryRepository(),
    );
    GetIt.I.registerSingleton<InviteFlowScreenController>(controller);

    final router = _RecordingStackRouter(canPopValue: false);
    final routeData = _buildRouteData(router, queryParams: const {});

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: RouteDataScope(
            routeData: routeData,
            child: const InviteFlowCoordinator(
              invites: [],
              decisionResult: null,
              requiresAuthentication: false,
              isInitialized: false,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
    'Invite flow renders grouped participants and avoids duplicate host metadata',
    (tester) async {
      final invite = _buildInviteWithParticipantGroups('grouped-1');
      final controller = InviteFlowScreenController(
        repository: _FakeInvitesRepository(initialInvites: [invite]),
        userEventsRepository: _FakeUserEventsRepository(),
        telemetryRepository: _FakeTelemetryRepository(),
      );
      GetIt.I.registerSingleton<InviteFlowScreenController>(controller);

      final router = _RecordingStackRouter(canPopValue: true);
      final routeData = _buildRouteData(
        router,
        path: '/invite',
        queryParams: const {},
      );

      await tester.pumpWidget(
        StackRouterScope(
          controller: router,
          stateHash: 0,
          child: MaterialApp(
            home: RouteDataScope(
              routeData: routeData,
              child: const InviteFlowScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      controller.markImageLoaded(invite.eventImageUrl);
      await tester.pump();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 150));
        if (find.text('Participantes').evaluate().isNotEmpty) {
          break;
        }
      }

      expect(find.text('Promotion Smoke Perfil Público'), findsOneWidget);
      expect(find.text('Participantes'), findsOneWidget);
      expect(find.textContaining('Bandas: Du Jorge'), findsOneWidget);
      expect(
        find.textContaining('Expositores: QA Discovery Tag Sem Tags'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          RegExp(
            'Promotion Smoke Perfil Público.*Bandas: Du Jorge.*Expositores: QA Discovery Tag Sem Tags',
          ),
        ),
        findsWidgets,
      );
      expect(find.byIcon(Icons.storefront_outlined), findsNothing);
    },
  );

  testWidgets('Invite flow web anonymous irrecoverable fallback routes home', (
    tester,
  ) async {
    final controller = InviteFlowScreenController(
      repository: _FakeInvitesRepository(initialInvites: const []),
      userEventsRepository: _FakeUserEventsRepository(),
      telemetryRepository: _FakeTelemetryRepository(),
      authRepository: _FakeAuthRepository(authorized: false),
    );
    GetIt.I.registerSingleton<InviteFlowScreenController>(controller);
    final router = _RecordingStackRouter(canPopValue: false);
    final routeData = _buildRouteData(router, queryParams: const {});

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: RouteDataScope(
            routeData: routeData,
            child: const InviteFlowCoordinator(
              invites: [],
              decisionResult: null,
              requiresAuthentication: false,
              isInitialized: true,
              isWebRuntime: true,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(router.replaceAllCalled, isTrue);
  });

  testWidgets(
    'Invite flow renders the invite immediately without waiting for image precache',
    (tester) async {
      final invite = _buildInviteWithPrimaryInviter('1');
      final controller = InviteFlowScreenController(
        repository: _FakeInvitesRepository(initialInvites: [invite]),
        userEventsRepository: _FakeUserEventsRepository(),
        telemetryRepository: _FakeTelemetryRepository(),
      );
      GetIt.I.registerSingleton<InviteFlowScreenController>(controller);

      final router = _RecordingStackRouter(canPopValue: true);
      final routeData = _buildRouteData(router, queryParams: const {});

      await tester.pumpWidget(
        StackRouterScope(
          controller: router,
          stateHash: 0,
          child: MaterialApp(
            home: RouteDataScope(
              routeData: routeData,
              child: InviteFlowCoordinator(
                invites: [invite],
                decisionResult: null,
                requiresAuthentication: false,
                isInitialized: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Event 1'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'Invite flow falls back home when invite is empty and no fallback path is available',
    (tester) async {
      final controller = InviteFlowScreenController(
        repository: _FakeInvitesRepository(initialInvites: const []),
        userEventsRepository: _FakeUserEventsRepository(),
        telemetryRepository: _FakeTelemetryRepository(),
      );
      GetIt.I.registerSingleton<InviteFlowScreenController>(controller);

      final router = _RecordingStackRouter(canPopValue: true);

      await tester.pumpWidget(
        StackRouterScope(
          controller: router,
          stateHash: 0,
          child: MaterialApp(
            home: RouteDataScope(
              routeData: _buildRouteData(router, queryParams: const {}),
              child: const InviteFlowCoordinator(
                invites: [],
                decisionResult: null,
                requiresAuthentication: false,
                isInitialized: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(router.popCalled, isTrue);
      expect(router.lastReplacedPath, isNull);
    },
  );

  testWidgets(
    'Invite flow falls back to event when invite is empty and session continuity still resolves',
    (tester) async {
      final repository = _FakeInvitesRepository(initialInvites: const []);
      repository.setShareCodeSessionContext(
        code: invitesRepoString(
          'SHARE-CODE-123',
          defaultValue: '',
          isRequired: true,
        ),
        invite: buildInviteModelFromPrimitives(
          id: 'invite-1',
          eventId: 'event-1',
          eventSlug: 'event-1',
          eventName: 'Invite Event',
          eventDateTime: DateTime(2026, 1, 1, 18),
          eventImageUrl: 'https://example.com/event.jpg',
          location: 'Guarapari',
          hostName: 'Belluga',
          message: 'Bora?',
          tags: const ['music'],
          occurrenceId: 'occ-1',
        ),
      );
      final controller = InviteFlowScreenController(
        repository: repository,
        userEventsRepository: _FakeUserEventsRepository(),
        telemetryRepository: _FakeTelemetryRepository(),
      );
      GetIt.I.registerSingleton<InviteFlowScreenController>(controller);

      final router = _RecordingStackRouter(canPopValue: false);

      await tester.pumpWidget(
        StackRouterScope(
          controller: router,
          stateHash: 0,
          child: MaterialApp(
            home: RouteDataScope(
              routeData: _buildRouteData(router, queryParams: const {}),
              child: InviteFlowCoordinator(
                invites: const [],
                decisionResult: null,
                requiresAuthentication: false,
                isInitialized: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(
        router.lastReplacedPath,
        '/agenda/evento/event-1?occurrence=occ-1',
      );
    },
  );

  testWidgets(
    'Invite flow preserves the synchronous event continuation without revalidation',
    (tester) async {
      final repository = _FakeInvitesRepository(initialInvites: const []);
      repository.setShareCodeSessionContext(
        code: invitesRepoString(
          'SHARE-CODE-123',
          defaultValue: '',
          isRequired: true,
        ),
        invite: buildInviteModelFromPrimitives(
          id: 'invite-ended',
          eventId: 'event-ended',
          eventSlug: 'event-ended',
          eventName: 'Ended Event',
          eventDateTime: DateTime(2026, 1, 1, 18),
          eventImageUrl: 'https://example.com/event-ended.jpg',
          location: 'Guarapari',
          hostName: 'Belluga',
          message: 'Bora?',
          tags: const ['music'],
          occurrenceId: 'occ-ended',
        ),
      );
      final controller = InviteFlowScreenController(
        repository: repository,
        userEventsRepository: _FakeUserEventsRepository(),
        telemetryRepository: _FakeTelemetryRepository(),
      );
      GetIt.I.registerSingleton<InviteFlowScreenController>(controller);

      final router = _RecordingStackRouter(canPopValue: false);

      await tester.pumpWidget(
        StackRouterScope(
          controller: router,
          stateHash: 0,
          child: MaterialApp(
            home: RouteDataScope(
              routeData: _buildRouteData(router, queryParams: const {}),
              child: InviteFlowCoordinator(
                invites: const [],
                decisionResult: null,
                requiresAuthentication: false,
                isInitialized: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(
        router.lastReplacedPath,
        '/agenda/evento/event-ended?occurrence=occ-ended',
      );
    },
  );

  testWidgets(
    'Unauthenticated app invite asks for authentication before accept',
    (tester) async {
      final invite = _buildInviteWithPrimaryInviter('1');
      final repository = _FakeInvitesRepository(initialInvites: [invite]);
      final controller = InviteFlowScreenController(
        repository: repository,
        userEventsRepository: _FakeUserEventsRepository(),
        telemetryRepository: _FakeTelemetryRepository(),
        authRepository: _FakeAuthRepository(authorized: false),
      );
      GetIt.I.registerSingleton<InviteFlowScreenController>(controller);

      final router = _RecordingStackRouter(canPopValue: true);
      final routeData = _buildRouteData(
        router,
        path: '/invite',
        queryParams: const {'code': '31F8RN5QJ9'},
      );

      await tester.pumpWidget(
        StackRouterScope(
          controller: router,
          stateHash: 0,
          child: MaterialApp(
            home: RouteDataScope(
              routeData: routeData,
              child: const InviteFlowScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      controller.markImageLoaded(invite.eventImageUrl);
      await tester.pump();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 150));
        if (find.text('Entre para Aceitar ou Recusar').evaluate().isNotEmpty) {
          break;
        }
      }

      expect(find.text('Aceitar'), findsNothing);
      expect(find.text('Recusar'), findsNothing);
      expect(find.text('Ver detalhes'), findsOneWidget);
      expect(find.text('Entre para Aceitar ou Recusar'), findsOneWidget);

      await tester.tap(find.text('Entre para Aceitar ou Recusar'));
      await tester.pump();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (router.lastPushed != null) {
          break;
        }
      }

      expect(
        router.lastPushedPath,
        '/auth/login?redirect=%2Finvite%3Fcode%3D31F8RN5QJ9',
      );
      expect(router.lastPushed, isNull);
      expect(repository.acceptedShareCodes, isEmpty);
      expect(repository.acceptedInviteIds, isEmpty);
    },
  );

  testWidgets(
    'Authenticated share invite accept uses canonical invite action',
    (tester) async {
      final invite = _buildInvite('1');
      final repository = _FakeInvitesRepository(
        initialInvites: [invite],
        materializedInviteId: '1',
      );
      final controller = InviteFlowScreenController(
        repository: repository,
        userEventsRepository: _FakeUserEventsRepository(),
        telemetryRepository: _FakeTelemetryRepository(),
        authRepository: _FakeAuthRepository(authorized: true),
      );
      GetIt.I.registerSingleton<InviteFlowScreenController>(controller);

      final router = _RecordingStackRouter(canPopValue: true);
      final routeData = _buildRouteData(
        router,
        path: '/invite',
        queryParams: const {'code': '31F8RN5QJ9'},
      );

      await tester.pumpWidget(
        StackRouterScope(
          controller: router,
          stateHash: 0,
          child: MaterialApp(
            home: RouteDataScope(
              routeData: routeData,
              child: const InviteFlowScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      controller.markImageLoaded(invite.eventImageUrl);
      await tester.pump();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 150));
        if (find.text('Aceitar').evaluate().isNotEmpty) {
          break;
        }
      }

      await tester.tap(find.text('Aceitar'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(repository.materializedShareCodes, ['31F8RN5QJ9']);
      expect(repository.acceptedInviteIds, ['1']);
    },
  );

  testWidgets(
    'Authenticated share invite with inviteId accepts through invite contract',
    (tester) async {
      final invite = _buildInviteWithPrimaryInviter('accept-1');
      final repository = _FakeInvitesRepository(
        initialInvites: [invite],
        materializedInviteId: 'accept-1',
      );
      final controller = InviteFlowScreenController(
        repository: repository,
        userEventsRepository: _FakeUserEventsRepository(),
        telemetryRepository: _FakeTelemetryRepository(),
        authRepository: _FakeAuthRepository(authorized: true),
      );
      GetIt.I.registerSingleton<InviteFlowScreenController>(controller);

      final router = _RecordingStackRouter(canPopValue: true);
      final routeData = _buildRouteData(
        router,
        path: '/invite',
        queryParams: const {'code': '31F8RN5QJ9'},
      );

      await tester.pumpWidget(
        StackRouterScope(
          controller: router,
          stateHash: 0,
          child: MaterialApp(
            home: RouteDataScope(
              routeData: routeData,
              child: const InviteFlowScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      controller.markImageLoaded(invite.eventImageUrl);
      await tester.pump();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 150));
        if (find.text('Aceitar').evaluate().isNotEmpty) {
          break;
        }
      }

      await tester.tap(find.text('Aceitar'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(repository.acceptedInviteIds, ['accept-1']);
      expect(repository.materializedShareCodes, ['31F8RN5QJ9']);
    },
  );

  testWidgets(
    'Authenticated share invite with inviteId declines through invite contract',
    (tester) async {
      final invite = _buildInviteWithPrimaryInviter('decline-1');
      final repository = _FakeInvitesRepository(
        initialInvites: [invite],
        materializedInviteId: 'decline-1',
      );
      final controller = InviteFlowScreenController(
        repository: repository,
        userEventsRepository: _FakeUserEventsRepository(),
        telemetryRepository: _FakeTelemetryRepository(),
        authRepository: _FakeAuthRepository(authorized: true),
      );
      GetIt.I.registerSingleton<InviteFlowScreenController>(controller);

      final router = _RecordingStackRouter(canPopValue: true);
      final routeData = _buildRouteData(
        router,
        path: '/invite',
        queryParams: const {'code': '31F8RN5QJ9'},
      );

      await tester.pumpWidget(
        StackRouterScope(
          controller: router,
          stateHash: 0,
          child: MaterialApp(
            home: RouteDataScope(
              routeData: routeData,
              child: const InviteFlowScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      controller.markImageLoaded(invite.eventImageUrl);
      await tester.pump();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 150));
        if (find.text('Recusar').evaluate().isNotEmpty) {
          break;
        }
      }

      await tester.tap(find.text('Recusar'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(repository.declinedInviteIds, ['decline-1']);
      expect(repository.materializedShareCodes, ['31F8RN5QJ9']);
    },
  );

  testWidgets(
    'Self issuer preview replaces recipient actions with preview alert and share action',
    (tester) async {
      final invite = _buildInviteWithPrimaryInviter('self-preview');
      final repository = _FakeInvitesRepository(
        initialInvites: [invite],
        materializeStatus: 'self_issuer_preview',
      );
      final controller = InviteFlowScreenController(
        repository: repository,
        userEventsRepository: _FakeUserEventsRepository(),
        telemetryRepository: _FakeTelemetryRepository(),
        authRepository: _FakeAuthRepository(authorized: true),
      );
      GetIt.I.registerSingleton<InviteFlowScreenController>(controller);

      final router = _RecordingStackRouter(canPopValue: true);
      final routeData = _buildRouteData(
        router,
        path: '/invite',
        queryParams: const {'code': '31F8RN5QJ9'},
      );

      await tester.pumpWidget(
        StackRouterScope(
          controller: router,
          stateHash: 0,
          child: MaterialApp(
            home: RouteDataScope(
              routeData: routeData,
              child: const InviteFlowScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      controller.markImageLoaded(invite.eventImageUrl);
      await tester.pump();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 150));
        if (find.text('Prévia do seu convite').evaluate().isNotEmpty) {
          break;
        }
      }

      expect(repository.materializedShareCodes, ['31F8RN5QJ9']);
      expect(repository.previewedShareCodes, ['31F8RN5QJ9']);
      expect(find.text('Prévia do seu convite'), findsOneWidget);
      expect(find.text('Compartilhar'), findsOneWidget);
      expect(find.text('Ver detalhes'), findsOneWidget);
      expect(find.text('Aceitar'), findsNothing);
      expect(find.text('Recusar'), findsNothing);
      expect(find.byIcon(Icons.swipe), findsNothing);
    },
  );

  testWidgets(
    'Closing invite flow without decision routes home and keeps invite pending',
    (tester) async {
      final invite = _buildInviteWithPrimaryInviter('pending-1');
      final repository = _FakeInvitesRepository(
        initialInvites: [invite],
        materializedInviteId: 'pending-1',
      );
      final controller = InviteFlowScreenController(
        repository: repository,
        userEventsRepository: _FakeUserEventsRepository(),
        telemetryRepository: _FakeTelemetryRepository(),
        authRepository: _FakeAuthRepository(authorized: true),
      );
      GetIt.I.registerSingleton<InviteFlowScreenController>(controller);

      final router = _RecordingStackRouter(canPopValue: false);
      final routeData = _buildRouteData(
        router,
        path: '/invite',
        queryParams: const {'code': '31F8RN5QJ9'},
      );

      await tester.pumpWidget(
        StackRouterScope(
          controller: router,
          stateHash: 0,
          child: MaterialApp(
            home: RouteDataScope(
              routeData: routeData,
              child: const InviteFlowScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      controller.markImageLoaded(invite.eventImageUrl);
      await tester.pump();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 150));
        if (find.byTooltip('Fechar').evaluate().isNotEmpty) {
          break;
        }
      }

      await tester.tap(find.byTooltip('Fechar'));
      await tester.pump();

      expect(router.replaceAllCalled, isTrue);
      expect(router.lastReplaced?.first, isA<TenantHomeRoute>());
      expect(controller.pendingInvitesStreamValue.value, hasLength(1));
      expect(controller.pendingInvitesStreamValue.value.first.id, 'pending-1');
      expect(
        controller.pendingInvitesStreamValue.value.first.eventId,
        'event-pending-1',
      );
    },
  );

  testWidgets(
    'Invite flow system back routes home and keeps invite pending when there is no stack',
    (tester) async {
      final invite = _buildInviteWithPrimaryInviter('pending-system-back');
      final repository = _FakeInvitesRepository(
        initialInvites: [invite],
        materializedInviteId: 'pending-system-back',
      );
      final controller = InviteFlowScreenController(
        repository: repository,
        userEventsRepository: _FakeUserEventsRepository(),
        telemetryRepository: _FakeTelemetryRepository(),
        authRepository: _FakeAuthRepository(authorized: true),
      );
      GetIt.I.registerSingleton<InviteFlowScreenController>(controller);

      final router = _RecordingStackRouter(canPopValue: false);
      final routeData = _buildRouteData(
        router,
        path: '/invite',
        queryParams: const {'code': '31F8RN5QJ9'},
      );

      await tester.pumpWidget(
        StackRouterScope(
          controller: router,
          stateHash: 0,
          child: MaterialApp(
            home: RouteDataScope(
              routeData: routeData,
              child: const InviteFlowScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      controller.markImageLoaded(invite.eventImageUrl);
      await tester.pump();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 150));
        if (find.byType(PopScope<dynamic>).evaluate().isNotEmpty) {
          break;
        }
      }

      final popScope = tester.widget<PopScope<dynamic>>(
        find.byWidgetPredicate((widget) => widget is PopScope),
      );
      popScope.onPopInvokedWithResult?.call(false, null);
      await tester.pump();

      expect(router.replaceAllCalled, isTrue);
      expect(router.lastReplaced?.first, isA<TenantHomeRoute>());
      expect(controller.pendingInvitesStreamValue.value, hasLength(1));
      expect(
        controller.pendingInvitesStreamValue.value.first.id,
        'pending-system-back',
      );
    },
  );

  testWidgets(
    'Authenticated multi-inviter share invite with empty picker id still uses canonical decision',
    (tester) async {
      final invite = _buildInviteWithEmptyCandidateIds('multi-1');
      final repository = _FakeInvitesRepository(
        initialInvites: [invite],
        materializedInviteId: 'multi-1',
      );
      final controller = InviteFlowScreenController(
        repository: repository,
        userEventsRepository: _FakeUserEventsRepository(),
        telemetryRepository: _FakeTelemetryRepository(),
        authRepository: _FakeAuthRepository(authorized: true),
      );
      GetIt.I.registerSingleton<InviteFlowScreenController>(controller);

      final router = _RecordingStackRouter(canPopValue: true);
      final routeData = _buildRouteData(
        router,
        path: '/invite',
        queryParams: const {'code': '31F8RN5QJ9'},
      );

      await tester.pumpWidget(
        StackRouterScope(
          controller: router,
          stateHash: 0,
          child: MaterialApp(
            home: RouteDataScope(
              routeData: routeData,
              child: const InviteFlowScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      controller.markImageLoaded(invite.eventImageUrl);
      await tester.pump();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 150));
        if (find.text('Aceitar').evaluate().isNotEmpty) {
          break;
        }
      }

      await tester.tap(find.text('Aceitar'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(repository.materializedShareCodes, ['31F8RN5QJ9']);
      expect(repository.acceptedInviteIds, ['multi-1']);
    },
  );
}

AppData _buildAppData() {
  final platformType = PlatformTypeValue()..parse(AppType.mobile.name);
  return buildAppDataFromInitialization(
    remoteData: {
      'name': 'Guarappari',
      'type': 'tenant',
      'main_domain': 'https://guarappari.com.br',
      'domains': ['https://guarappari.com.br'],
      'app_domains': [],
      'theme_data_settings': {
        'primary_seed_color': '#4FA0E3',
        'secondary_seed_color': '#E80D5D',
        'brightness_default': 'light',
      },
      'main_color': '#4FA0E3',
      'tenant_id': 'tenant-1',
      'telemetry': {'trackers': []},
    },
    localInfo: {
      'platformType': platformType,
      'hostname': 'guarappari.com.br',
      'href': 'https://guarappari.com.br',
      'port': null,
      'device': 'test-device',
    },
  );
}

class _SemanticFrcHarness {
  _SemanticFrcHarness({
    required this.router,
    required this.repository,
    required this.controller,
    required this.navigationObserver,
  });

  final RootStackRouter router;
  final _FakeInvitesRepository repository;
  final InviteFlowScreenController controller;
  final _CountingNavigatorObserver navigationObserver;
  int materializedTerminalBuilds = 0;

  List<String> get names =>
      router.currentHierarchy().map((route) => route.name).toList();
}

Future<_SemanticFrcHarness> _pumpSemanticFrcHarness(
  WidgetTester tester, {
  required InviteModel invite,
}) async {
  final repository = _FakeInvitesRepository(
    initialInvites: <InviteModel>[invite],
  );
  final controller = InviteFlowScreenController(
    appData: GetIt.I.get<AppData>(),
    repository: repository,
    userEventsRepository: _FakeUserEventsRepository(),
    telemetryRepository: _FakeTelemetryRepository(),
    authRepository: _FakeAuthRepository(authorized: true),
  );
  GetIt.I.registerSingleton<InviteFlowScreenController>(controller);
  final router = RootStackRouter.build(
    routes: <AutoRoute>[
      AutoRoute(
        path: '/',
        page: PageInfo.builder(
          TenantHomeRoute.name,
          builder: (_, _) => const Scaffold(body: Text('frc-home')),
        ),
        meta: canonicalRouteMeta(family: CanonicalRouteFamily.tenantHome),
      ),
      AutoRoute(
        path: '/convites',
        page: PageInfo.builder(
          InviteFlowRoute.name,
          builder: (_, _) =>
              const RouteInstanceScope(child: InviteFlowScreen()),
        ),
        meta: canonicalRouteMeta(family: CanonicalRouteFamily.inviteFlow),
      ),
      AutoRoute(
        path: '/agenda/evento/:slug',
        page: PageInfo.builder(
          ImmersiveEventDetailRoute.name,
          builder: (_, _) => const Scaffold(body: Text('frc-event-child')),
        ),
        meta: canonicalRouteMeta(
          family: CanonicalRouteFamily.immersiveEventDetail,
        ),
      ),
    ],
  );
  final navigationObserver = _CountingNavigatorObserver();
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router.config(
        navigatorObservers: () => <NavigatorObserver>[navigationObserver],
      ),
    ),
  );
  router.replaceAll(const <PageRouteInfo<dynamic>>[
    TenantHomeRoute(),
    InviteFlowRoute(),
  ]);
  await _flushFrc(tester);
  return _SemanticFrcHarness(
    router: router,
    repository: repository,
    controller: controller,
    navigationObserver: navigationObserver,
  );
}

class _CountingNavigatorObserver extends NavigatorObserver {
  int popCount = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popCount += 1;
    super.didPop(route, previousRoute);
  }
}

List<InviteModel> _coordinatorInvites(WidgetTester tester) {
  return tester
      .widget<InviteFlowCoordinator>(find.byType(InviteFlowCoordinator))
      .invites;
}

Future<void> _materializeTerminalBuild(
  WidgetTester tester,
  _SemanticFrcHarness harness,
) async {
  await _buildDirtyWidgetsWithoutPostFrame(tester);
  expect(_coordinatorInvites(tester), isEmpty);
  expect(harness.names, <String>[TenantHomeRoute.name, InviteFlowRoute.name]);
  harness.materializedTerminalBuilds += 1;
}

Future<void> _buildDirtyWidgetsWithoutPostFrame(WidgetTester tester) async {
  await tester.idle();
  final rootElement = tester.binding.rootElement;
  expect(rootElement, isNotNull);
  tester.binding.buildOwner!.buildScope(rootElement!);
  tester.binding.buildOwner!.finalizeTree();
}

Future<void> _flushFrc(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump();
}

InviteModel _buildInvite(String id) {
  return buildInviteModelFromPrimitives(
    id: id,
    eventId: 'event-$id',
    eventSlug: 'event-$id',
    eventName: 'Event $id',
    eventDateTime: DateTime(2026, 1, 1, 18),
    eventImageUrl: 'https://example.com/$id.jpg',
    location: 'Guarapari',
    hostName: 'Host $id',
    message: 'Invite $id',
    tags: const ['music'],
  );
}

InviteModel _buildInviteWithPrimaryInviter(String id) {
  return buildInviteModelFromPrimitives(
    id: id,
    eventId: 'event-$id',
    eventName: 'Event $id',
    eventDateTime: DateTime(2026, 1, 1, 18),
    eventImageUrl: 'https://example.com/$id.jpg',
    location: 'Guarapari',
    hostName: 'Host $id',
    message: 'Invite $id',
    tags: const ['music'],
    inviterName: 'Convidador principal',
  );
}

InviteModel _buildInviteWithParticipantGroups(String id) {
  const venueId = 'venue-1';
  const bandId = 'band-1';
  const exhibitorId = 'exhibitor-1';

  return buildInviteModelFromPrimitives(
    id: id,
    eventId: 'event-$id',
    eventName: 'Event $id',
    eventDateTime: DateTime(2026, 1, 1, 18),
    eventImageUrl: 'https://example.com/$id.jpg',
    location: 'Promotion Smoke Perfil Público',
    hostName: 'Promotion Smoke Perfil Público',
    message: 'Invite $id',
    tags: const ['music'],
    linkedAccountProfiles: [
      _linkedProfile(
        id: venueId,
        name: 'Promotion Smoke Perfil Público',
        profileType: 'venue',
      ),
      _linkedProfile(id: bandId, name: 'Du Jorge', profileType: 'artist'),
      _linkedProfile(
        id: exhibitorId,
        name: 'QA Discovery Tag Sem Tags',
        profileType: 'exhibitor',
      ),
    ],
    profileGroups: [
      EventProfileGroup(
        idValue: EventLinkedAccountProfileTextValue('bandas'),
        labelValue: EventLinkedAccountProfileTextValue('Bandas'),
        orderValue: EventProfileGroupOrderValue(0),
        accountProfileIdValues: [EventLinkedAccountProfileTextValue(bandId)],
      ),
      EventProfileGroup(
        idValue: EventLinkedAccountProfileTextValue('expositores'),
        labelValue: EventLinkedAccountProfileTextValue('Expositores'),
        orderValue: EventProfileGroupOrderValue(1),
        accountProfileIdValues: [
          EventLinkedAccountProfileTextValue(exhibitorId),
        ],
      ),
    ],
    venueAccountProfileId: venueId,
  );
}

InviteModel _buildInviteWithEmptyCandidateIds(String id) {
  return buildInviteModelFromPrimitives(
    id: id,
    eventId: 'event-$id',
    eventName: 'Event $id',
    eventDateTime: DateTime(2026, 1, 1, 18),
    eventImageUrl: 'https://example.com/$id.jpg',
    location: 'Guarapari',
    hostName: 'Host $id',
    message: 'Invite $id',
    tags: const ['music'],
    inviterName: 'Convidador A',
    inviters: [
      InviteInviter(
        inviteIdValue: InviteInviterIdValue(
          defaultValue: '',
          isRequired: false,
        ),
        type: InviteInviterType.user,
        nameValue: InviteSenderDisplayNameCandidateValue()
          ..parse('Convidador A'),
      ),
      InviteInviter(
        inviteIdValue: InviteInviterIdValue(
          defaultValue: '',
          isRequired: false,
        ),
        type: InviteInviterType.user,
        nameValue: InviteSenderDisplayNameCandidateValue()
          ..parse('Convidador B'),
      ),
    ],
  );
}

InviteModel _buildInviteWithSelectableCandidates(String id) {
  return buildInviteModelFromPrimitives(
    id: id,
    eventId: 'event-$id',
    eventName: 'Event $id',
    eventDateTime: DateTime(2026, 1, 1, 18),
    eventImageUrl: 'https://example.com/$id.jpg',
    location: 'Guarapari',
    hostName: 'Host $id',
    message: 'Invite $id',
    tags: const ['music'],
    inviters: [
      InviteInviter(
        inviteIdValue: InviteInviterIdValue()..parse('$id-a'),
        type: InviteInviterType.user,
        nameValue: InviteSenderDisplayNameCandidateValue()
          ..parse('Convidador A'),
      ),
      InviteInviter(
        inviteIdValue: InviteInviterIdValue()..parse('$id-b'),
        type: InviteInviterType.user,
        nameValue: InviteSenderDisplayNameCandidateValue()
          ..parse('Convidador B'),
      ),
    ],
  );
}

EventLinkedAccountProfile _linkedProfile({
  required String id,
  required String name,
  required String profileType,
}) {
  return EventLinkedAccountProfile(
    idValue: EventLinkedAccountProfileTextValue(id),
    displayNameValue: EventLinkedAccountProfileTextValue(name),
    profileTypeValue: AccountProfileTypeValue(profileType),
  );
}

RouteData _buildRouteData(
  StackRouter router, {
  required Map<String, dynamic> queryParams,
  String path = '/invite-flow',
}) {
  final normalizedSegments = path
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);
  final match = RouteMatch(
    config: AutoRoute(
      page: path == '/invite' ? InviteEntryRoute.page : InviteFlowRoute.page,
      path: path,
      meta: canonicalRouteMeta(
        family: path == '/invite'
            ? CanonicalRouteFamily.inviteEntry
            : CanonicalRouteFamily.inviteFlow,
      ),
    ),
    segments: normalizedSegments,
    stringMatch: path,
    key: ValueKey(path),
    queryParams: Parameters(queryParams),
  );
  final routeData = RouteData(
    route: match,
    router: router,
    stackKey: const ValueKey('stack'),
    pendingChildren: const [],
    type: const RouteType.material(),
  );
  if (router is _RecordingStackRouter) {
    router.activeRoute = routeData;
  }
  return routeData;
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _TestHttpClient();
  }
}

class _FakeAuthRepository extends AuthRepositoryContract {
  _FakeAuthRepository({required this.authorized});

  final bool authorized;

  @override
  Object get backend => Object();

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

  @override
  String get userToken => authorized ? 'token' : '';

  @override
  bool get isUserLoggedIn => authorized;

  @override
  bool get isAuthorized => authorized;

  @override
  Future<String> getDeviceId() async => 'device-id';

  @override
  Future<String?> getUserId() async => authorized ? 'user-id' : null;

  @override
  Future<void> init() async {}

  @override
  Future<void> autoLogin() async {}

  @override
  Future<void> loginWithEmailPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractParamString name,
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString codigoEnviado,
  ) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> createNewPassword(
    AuthRepositoryContractParamString newPassword,
    AuthRepositoryContractParamString confirmPassword,
  ) async {}

  @override
  Future<void> sendPasswordResetEmail(
    AuthRepositoryContractParamString email,
  ) async {}

  @override
  Future<void> updateUser(UserCustomData data) async {}
}

class _TestHttpClient implements HttpClient {
  bool _autoUncompress = true;

  static final List<int> _transparentImage = <int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ];

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _TestHttpClientRequest(_transparentImage);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _TestHttpClientRequest(_transparentImage);
  }

  @override
  bool get autoUncompress => _autoUncompress;

  @override
  set autoUncompress(bool value) {
    _autoUncompress = value;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestHttpClientRequest implements HttpClientRequest {
  _TestHttpClientRequest(this._imageBytes);

  final List<int> _imageBytes;

  @override
  Future<HttpClientResponse> close() async {
    return _TestHttpClientResponse(_imageBytes);
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _TestHttpClientResponse(this._imageBytes);

  final List<int> _imageBytes;

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _imageBytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  Stream<List<int>> get stream => Stream<List<int>>.value(_imageBytes);

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final controller = StreamController<List<int>>();
    controller.add(_imageBytes);
    controller.close();
    return controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
