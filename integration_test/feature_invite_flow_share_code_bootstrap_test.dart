import 'dart:async';
import 'package:belluga_now/testing/domain_factories.dart';
import 'dart:io';
import 'package:belluga_now/testing/invite_accept_result_builder.dart';
import 'package:belluga_now/testing/invite_materialize_result_builder.dart';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_materialize_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/controllers/invite_flow_controller.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/invite_flow_screen.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_value/core/stream_value.dart';

import 'support/integration_test_bootstrap.dart';
import 'package:belluga_now/testing/invite_model_factory.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

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

  testWidgets(
      'authenticated share code bootstrap materializes canonical invite',
      (tester) async {
    final repository = _RecordingInvitesRepository();
    final controller = InviteFlowScreenController(
      repository: repository,
      userEventsRepository: _FakeUserEventsRepository(),
      telemetryRepository: _FakeTelemetryRepository(),
    );
    GetIt.I.registerSingleton<InviteFlowScreenController>(controller);

    final router = _RecordingStackRouter(canPopValue: false);
    final routeData = _buildRouteData(
      router,
      queryParams: const {'code': 'SHARE-CODE-123'},
    );

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: RouteDataScope(
            routeData: routeData,
            child: const InviteFlowScreen(key: ValueKey('invite-anon-stage')),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(repository.previewedShareCodes, isEmpty);
    expect(repository.materializedShareCodes, ['SHARE-CODE-123']);
    expect(controller.authRequiredForDecisionStreamValue.value, isFalse);
    expect(controller.displayInvitesStreamValue.value, hasLength(1));
    expect(router.replaceAllCalled, isFalse);
  });

  testWidgets(
      'anonymous share code query param previews decision actions without materializing',
      (tester) async {
    final repository = _RecordingInvitesRepository();
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
      queryParams: const {'code': 'SHARE-CODE-123'},
    );

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: RouteDataScope(
            routeData: routeData,
            child: const InviteFlowScreen(key: ValueKey('invite-auth-stage')),
          ),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 150));
      if (controller.displayInvitesStreamValue.value.isNotEmpty) {
        break;
      }
    }

    expect(repository.previewedShareCodes, ['SHARE-CODE-123']);
    expect(repository.materializedShareCodes, isEmpty);
    expect(controller.authRequiredForDecisionStreamValue.value, isFalse);
    expect(controller.displayInvitesStreamValue.value, hasLength(1));
    controller.markImageLoaded(
      controller.displayInvitesStreamValue.value.first.eventImageUrl,
    );
    await tester.pump(const Duration(milliseconds: 200));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 150));
      if (find.text('Recusar').evaluate().isNotEmpty &&
          find.text('Aceitar').evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.text('Recusar'), findsOneWidget);
    expect(find.text('Aceitar'), findsOneWidget);
    expect(find.text('Entre para Aceitar ou Recusar'), findsNothing);
    expect(router.replaceAllCalled, isFalse);
  });

  testWidgets(
      'anonymous share preview keeps decision UI and authenticated continuation materializes invite',
      (tester) async {
    final repository = _RecordingInvitesRepository();
    final authRepository = _FakeAuthRepository(authorized: false);
    final anonymousController = InviteFlowScreenController(
      repository: repository,
      userEventsRepository: _FakeUserEventsRepository(),
      telemetryRepository: _FakeTelemetryRepository(),
      authRepository: authRepository,
    );
    GetIt.I.registerSingleton<InviteFlowScreenController>(anonymousController);

    final router = _RecordingStackRouter(canPopValue: true);
    final routeData = _buildRouteData(
      router,
      queryParams: const {'code': 'SHARE-CODE-123'},
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
      if (anonymousController.displayInvitesStreamValue.value.isNotEmpty) {
        break;
      }
    }

    expect(repository.previewedShareCodes, ['SHARE-CODE-123']);
    expect(repository.materializedShareCodes, isEmpty);
    expect(
      anonymousController.authRequiredForDecisionStreamValue.value,
      isFalse,
    );
    expect(anonymousController.displayInvitesStreamValue.value, hasLength(1));
    anonymousController.markImageLoaded(
      anonymousController.displayInvitesStreamValue.value.first.eventImageUrl,
    );
    await tester.pump(const Duration(milliseconds: 200));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 150));
      if (find.text('Recusar').evaluate().isNotEmpty &&
          find.text('Aceitar').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.text('Recusar'), findsOneWidget);
    expect(find.text('Aceitar'), findsOneWidget);
    expect(find.text('Entre para Aceitar ou Recusar'), findsNothing);
    expect(router.lastPushedPath, isNull);
    expect(router.replaceAllCalled, isFalse);

    authRepository.authorized = true;
    await anonymousController.init(
      shareCode: 'SHARE-CODE-123',
      redirectPath: '/invite?code=SHARE-CODE-123',
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 150));
      if (anonymousController.displayInvitesStreamValue.value.isNotEmpty) {
        break;
      }
    }
    expect(anonymousController.displayInvitesStreamValue.value, hasLength(1));
    expect(
      anonymousController.authRequiredForDecisionStreamValue.value,
      isFalse,
    );
    anonymousController.markImageLoaded(
      anonymousController.displayInvitesStreamValue.value.first.eventImageUrl,
    );
    await tester.pump(const Duration(milliseconds: 200));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 150));
      if (find.text('Recusar').evaluate().isNotEmpty &&
          find.text('Aceitar').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.text('Recusar'), findsOneWidget);
    expect(find.text('Aceitar'), findsOneWidget);
    expect(find.text('Entre para Aceitar ou Recusar'), findsNothing);
    expect(repository.materializedShareCodes, ['SHARE-CODE-123']);
    expect(router.replaceAllCalled, isFalse);
  });

  testWidgets('missing share code does not call materializeShareCode',
      (tester) async {
    final repository = _RecordingInvitesRepository();
    final controller = InviteFlowScreenController(
      repository: repository,
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

    expect(repository.materializedShareCodes, isEmpty);
  });

  testWidgets(
      'closing authenticated invite flow without decision routes home and keeps pending invite',
      (tester) async {
    final repository = _RecordingInvitesRepository();
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
      queryParams: const {'code': 'SHARE-CODE-123'},
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

    expect(controller.displayInvitesStreamValue.value, hasLength(1));
    controller.markImageLoaded(
      controller.displayInvitesStreamValue.value.first.eventImageUrl,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byTooltip('Fechar'), findsOneWidget);
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pump();

    expect(router.replaceAllCalled, isTrue);
    expect(router.lastReplaced?.first, isA<TenantHomeRoute>());
    expect(controller.pendingInvitesStreamValue.value, hasLength(1));
    expect(
      controller.pendingInvitesStreamValue.value.first.id,
      'preview-SHARE-CODE-123',
    );
    expect(
      controller.pendingInvitesStreamValue.value.first.eventId,
      'event-preview',
    );
  });
}

class _RecordingInvitesRepository extends InvitesRepositoryContract {
  _RecordingInvitesRepository() : _invites = <InviteModel>[_materializedInvite];

  final List<String> materializedShareCodes = <String>[];
  final List<String> previewedShareCodes = <String>[];
  final List<InviteModel> _invites;

  static final InviteModel _materializedInvite = buildInviteModelFromPrimitives(
    id: 'preview-SHARE-CODE-123',
    eventId: 'event-preview',
    eventName: 'Preview Event',
    eventDateTime: DateTime(2026, 3, 15, 18),
    eventImageUrl: 'https://example.com/preview.jpg',
    location: 'Guarapari',
    hostName: 'Host',
    message: 'Convite para evento',
    tags: const ['music'],
    inviterName: 'Um amigo',
  );

  @override
  Future<List<InviteModel>> fetchInvites(
          {InvitesRepositoryContractPrimInt? page,
          InvitesRepositoryContractPrimInt? pageSize}) async =>
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
  Future<InviteAcceptResult> acceptInvite(
          InvitesRepositoryContractPrimString inviteId) async =>
      buildInviteAcceptResult(
        inviteId: inviteId.value,
        status: 'accepted',
        creditedAcceptance: true,
        attendancePolicy: 'free_confirmation_only',
        nextStep: InviteNextStep.none,
        supersededInviteIds: const [],
      );

  @override
  Future<InviteAcceptResult> acceptInviteByCode(
          InvitesRepositoryContractPrimString code) async =>
      buildInviteAcceptResult(
        inviteId: 'mock-${code.value}',
        status: 'accepted',
        creditedAcceptance: true,
        attendancePolicy: 'free_confirmation_only',
        nextStep: InviteNextStep.none,
        supersededInviteIds: const [],
      );

  @override
  Future<InviteDeclineResult> declineInvite(
          InvitesRepositoryContractPrimString inviteId) async =>
      buildInviteDeclineResult(
        inviteId: inviteId.value,
        status: 'declined',
        groupHasOtherPending: false,
      );

  @override
  Future<InviteMaterializeResult> materializeShareCode(
      InvitesRepositoryContractPrimString code) async {
    materializedShareCodes.add(code.value);
    return buildInviteMaterializeResult(
      inviteId: 'preview-SHARE-CODE-123',
      status: 'pending',
      creditedAcceptance: false,
      attendancePolicy: 'free_confirmation_only',
    );
  }

  @override
  Future<InviteModel?> previewShareCode(
      InvitesRepositoryContractPrimString code) async {
    previewedShareCodes.add(code.value);
    return _materializedInvite;
  }

  @override
  Future<List<InviteContactMatch>> importContacts(
          InviteContacts contacts) async =>
      const [];

  @override
  Future<InviteShareCodeResult> createShareCode({
    required InvitesRepositoryContractPrimString eventId,
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? accountProfileId,
  }) async =>
      buildInviteShareCodeResult(
        code: 'SHARE123',
        eventId: eventId.value,
        occurrenceId: occurrenceId?.value,
      );

  @override
  Future<void> sendInvites(InvitesRepositoryContractPrimString eventSlug,
      InviteRecipients recipients,
      {InvitesRepositoryContractPrimString? occurrenceId,
      InvitesRepositoryContractPrimString? message}) async {}

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(
          InvitesRepositoryContractPrimString eventSlug) async =>
      const [];
}

class _FakeAuthRepository extends AuthRepositoryContract {
  _FakeAuthRepository({required this.authorized});

  bool authorized;

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
  Future<void> loginWithEmailPassword(AuthRepositoryContractParamString email,
      AuthRepositoryContractParamString password) async {}

  @override
  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractParamString name,
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
      AuthRepositoryContractParamString email,
      AuthRepositoryContractParamString codigoEnviado) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> createNewPassword(
    AuthRepositoryContractParamString newPassword,
    AuthRepositoryContractParamString confirmPassword,
  ) async {}

  @override
  Future<void> sendPasswordResetEmail(
      AuthRepositoryContractParamString email) async {}

  @override
  Future<void> updateUser(UserCustomData data) async {}
}

class _FakeTelemetryRepository implements TelemetryRepositoryContract {
  @override
  Future<TelemetryRepositoryContractPrimBool> logEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async =>
      telemetryRepoBool(true);

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async =>
      const EventTrackerTimedEventHandle('handle');

  @override
  Future<TelemetryRepositoryContractPrimBool> finishTimedEvent(
          EventTrackerTimedEventHandle handle) async =>
      telemetryRepoBool(true);

  @override
  Future<TelemetryRepositoryContractPrimBool> flushTimedEvents() async =>
      telemetryRepoBool(true);

  @override
  void setScreenContext(TelemetryRepositoryContractPrimMap? screenContext) {}

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<TelemetryRepositoryContractPrimBool> mergeIdentity(
          {required TelemetryRepositoryContractPrimString
              previousUserId}) async =>
      telemetryRepoBool(true);
}

class _FakeUserEventsRepository implements UserEventsRepositoryContract {
  @override
  final StreamValue<Set<UserEventsRepositoryContractPrimString>>
      confirmedEventIdsStream =
      StreamValue<Set<UserEventsRepositoryContractPrimString>>(
          defaultValue: const {});

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async => const [];

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async => const [];

  @override
  Future<void> confirmEventAttendance(
      UserEventsRepositoryContractPrimString eventId) async {}

  @override
  Future<void> unconfirmEventAttendance(
      UserEventsRepositoryContractPrimString eventId) async {}

  @override
  Future<void> refreshConfirmedEventIds() async {}

  @override
  UserEventsRepositoryContractPrimBool isEventConfirmed(
          UserEventsRepositoryContractPrimString eventId) =>
      userEventsRepoBool(false, defaultValue: false, isRequired: true);
}

class _RecordingStackRouter extends Mock implements StackRouter {
  _RecordingStackRouter({required this.canPopValue});

  final bool canPopValue;
  String? lastPushedPath;
  bool replaceAllCalled = false;
  List<PageRouteInfo>? lastReplaced;

  @override
  bool canPop({
    bool ignoreChildRoutes = false,
    bool ignoreParentRoutes = false,
    bool ignorePagelessRoutes = false,
  }) {
    return canPopValue;
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
}

RouteData _buildRouteData(
  StackRouter router, {
  required Map<String, dynamic> queryParams,
}) {
  final match = RouteMatch(
    config: AutoRoute(
      page: InviteEntryRoute.page,
      path: '/invite',
      meta: canonicalRouteMeta(family: CanonicalRouteFamily.inviteEntry),
    ),
    segments: const ['invite'],
    stringMatch: '/invite',
    key: const ValueKey('invite'),
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
