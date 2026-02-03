import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_flow_screen/controllers/invite_flow_controller.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_flow_screen/invite_flow_screen.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_value/core/stream_value.dart';

class _FakeInvitesRepository extends InvitesRepositoryContract {
  _FakeInvitesRepository({required List<InviteModel> initialInvites})
      : _initialInvites = initialInvites;

  final List<InviteModel> _initialInvites;

  @override
  Future<List<InviteModel>> fetchInvites() async => _initialInvites;

  @override
  Future<void> sendInvites(String eventSlug, List<String> friendIds) async {}

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
  bool isEventConfirmed(String eventId) => false;
}

class _RecordingStackRouter extends Mock implements StackRouter {
  _RecordingStackRouter({required this.canPopValue});

  final bool canPopValue;
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
}

InviteModel _buildInvite(String id) {
  return InviteModel.fromPrimitives(
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

RouteData _buildRouteData(
  StackRouter router, {
  required Map<String, dynamic> queryParams,
}) {
  final match = RouteMatch(
    config: AutoRoute(page: InviteFlowRoute.page, path: '/invite-flow'),
    segments: const ['invite-flow'],
    stringMatch: '/invite-flow',
    key: const ValueKey('invite-flow'),
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
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
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
