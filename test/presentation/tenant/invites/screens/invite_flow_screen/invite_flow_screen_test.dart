import 'dart:async';
import 'package:belluga_now/testing/domain_factories.dart';
import 'dart:io';
import 'package:belluga_now/testing/invite_accept_result_builder.dart';
import 'package:belluga_now/testing/invite_materialize_result_builder.dart';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/contacts/contact_model.dart';
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
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_name_value.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/controllers/invite_flow_controller.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/invite_flow_screen.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:belluga_now/testing/invite_model_factory.dart';

class _FakeInvitesRepository extends InvitesRepositoryContract {
  _FakeInvitesRepository({
    required List<InviteModel> initialInvites,
    this.materializedInviteId,
  }) : _invites = List<InviteModel>.from(initialInvites);

  final List<InviteModel> _invites;
  final List<String> previewedShareCodes = <String>[];
  final String? materializedInviteId;
  final List<String> materializedShareCodes = <String>[];
  final List<String> acceptedInviteIds = <String>[];
  final List<String> declinedInviteIds = <String>[];

  @override
  Future<List<InviteModel>> fetchInvites(
          {int page = 1, int pageSize = 20}) async =>
      List<InviteModel>.from(_invites);

  @override
  Future<InviteRuntimeSettings> fetchSettings() async =>
      buildInviteRuntimeSettings(
        tenantId: null,
        limits: {},
        cooldowns: {},
        overQuotaMessage: null,
      );

  @override
  Future<InviteAcceptResult> acceptInvite(String inviteId) async => (() {
        acceptedInviteIds.add(inviteId);
        _removeInvite(inviteId);
        pendingInvitesStreamValue.addValue(List<InviteModel>.from(_invites));
        return buildInviteAcceptResult(
          inviteId: inviteId,
          status: 'accepted',
          creditedAcceptance: true,
          attendancePolicy: 'free_confirmation_only',
          nextStep: InviteNextStep.freeConfirmationCreated,
          supersededInviteIds: const [],
        );
      })();

  @override
  Future<InviteDeclineResult> declineInvite(String inviteId) async => (() {
        declinedInviteIds.add(inviteId);
        _removeInvite(inviteId);
        pendingInvitesStreamValue.addValue(List<InviteModel>.from(_invites));
        return buildInviteDeclineResult(
          inviteId: inviteId,
          status: 'declined',
          groupHasOtherPending: false,
        );
      })();

  @override
  Future<InviteMaterializeResult> materializeShareCode(String code) async {
    materializedShareCodes.add(code);
    return buildInviteMaterializeResult(
      inviteId: materializedInviteId ?? '',
      status: materializedInviteId == null ? 'expired' : 'pending',
      creditedAcceptance: false,
      attendancePolicy: 'free_confirmation_only',
    );
  }

  @override
  Future<InviteModel?> previewShareCode(String code) async {
    previewedShareCodes.add(code);
    if (_invites.isEmpty) {
      return null;
    }
    return _invites.first;
  }

  void _removeInvite(String inviteId) {
    _invites.removeWhere(
      (invite) => invite.id == inviteId || invite.containsInviteId(inviteId),
    );
  }

  @override
  Future<List<InviteContactMatch>> importContacts(
          List<ContactModel> contacts) async =>
      const [];

  @override
  Future<InviteShareCodeResult> createShareCode({
    required String eventId,
    String? occurrenceId,
    String? accountProfileId,
  }) async =>
      buildInviteShareCodeResult(
        code: 'CODE123',
        eventId: eventId,
        occurrenceId: occurrenceId,
      );

  @override
  Future<void> sendInvites(
    String eventSlug,
    List<EventFriendResume> recipients, {
    String? occurrenceId,
    String? message,
  }) async {}

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(
    String eventSlug,
  ) async =>
      const [];
}

class _FakeTelemetryRepository implements TelemetryRepositoryContract {
  @override
  Future<bool> logEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async =>
      true;

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async =>
      const EventTrackerTimedEventHandle('handle');

  @override
  Future<bool> finishTimedEvent(EventTrackerTimedEventHandle handle) async =>
      true;

  @override
  Future<bool> flushTimedEvents() async => true;

  @override
  void setScreenContext(Map<String, dynamic>? screenContext) {}

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<bool> mergeIdentity({required String previousUserId}) async => true;
}

class _FakeUserEventsRepository implements UserEventsRepositoryContract {
  @override
  final StreamValue<Set<String>> confirmedEventIdsStream =
      StreamValue<Set<String>>(defaultValue: const {});

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async => const [];

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async => const [];

  @override
  Future<void> confirmEventAttendance(String eventId) async {}

  @override
  Future<void> unconfirmEventAttendance(String eventId) async {}

  @override
  Future<void> refreshConfirmedEventIds() async {}

  @override
  bool isEventConfirmed(String eventId) => false;
}

class _RecordingStackRouter extends Mock implements StackRouter {
  _RecordingStackRouter({required this.canPopValue});

  final bool canPopValue;
  String? lastPushedPath;
  bool pushCalled = false;
  PageRouteInfo? lastPushed;
  bool replaceAllCalled = false;
  List<PageRouteInfo>? lastReplaced;
  bool popCalled = false;

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
  void pop<T extends Object?>([T? result]) {
    popCalled = true;
  }
}

void main() {
  setUpAll(() async {
    HttpOverrides.global = _TestHttpOverrides();
    await initializeDateFormatting('pt_BR');
  });

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
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

  testWidgets('Authenticated invite shows decline/accept contract',
      (tester) async {
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

    expect(router.replaceAllCalled, isTrue);
    expect(router.lastReplaced?.first, isA<TenantHomeRoute>());
  });

  testWidgets(
      'Unauthenticated invite shows auth CTA and preserves invite deep link',
      (tester) async {
    final invite = _buildInvite('1');
    final controller = InviteFlowScreenController(
      repository: _FakeInvitesRepository(initialInvites: [invite]),
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
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 150));
      if (find.text('Entre para Aceitar ou Recusar').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.text('Entre para Aceitar ou Recusar'), findsOneWidget);
    expect(find.text('Recusar'), findsNothing);

    await tester.tap(find.text('Entre para Aceitar ou Recusar'));
    await tester.pump();

    expect(
      router.lastPushedPath,
      '/auth/login?redirect=%2Finvite%3Fcode%3D31F8RN5QJ9',
    );
  });

  testWidgets('Authenticated share invite accept uses canonical invite action',
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
  });

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
  });

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
  });

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
    expect(controller.pendingInvitesStreamValue.value.first.eventId,
        'event-pending-1');
  });

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
  });
}

InviteModel _buildInvite(String id) {
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
        inviteIdValue:
            InviteInviterIdValue(defaultValue: '', isRequired: false),
        type: InviteInviterType.user,
        nameValue: InviteInviterNameValue()..parse('Convidador A'),
      ),
      InviteInviter(
        inviteIdValue:
            InviteInviterIdValue(defaultValue: '', isRequired: false),
        type: InviteInviterType.user,
        nameValue: InviteInviterNameValue()..parse('Convidador B'),
      ),
    ],
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
    ),
    segments: normalizedSegments,
    stringMatch: path,
    key: ValueKey(path),
    queryParams: Parameters(queryParams),
  );
  return RouteData(
    route: match,
    router: router,
    stackKey: const ValueKey('stack'),
    pendingChildren: const [],
    type: const RouteType.material(),
  );
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
  void setUserToken(String? token) {}

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
  Future<void> loginWithEmailPassword(String email, String password) async {}

  @override
  Future<void> signUpWithEmailPassword(
    String name,
    String email,
    String password,
  ) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
    String email,
    String codigoEnviado,
  ) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> createNewPassword(
    String newPassword,
    String confirmPassword,
  ) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> updateUser(Map<String, Object?> data) async {}
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
