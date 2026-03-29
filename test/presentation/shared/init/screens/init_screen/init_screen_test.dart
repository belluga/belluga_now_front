import 'dart:async';
import 'package:belluga_now/testing/domain_factories.dart';
import 'dart:io';
import 'package:belluga_now/testing/invite_accept_result_builder.dart';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/push/push_presentation_gate_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/presentation/shared/init/screens/init_screen/controllers/init_screen_controller.dart';
import 'package:belluga_now/presentation/shared/init/screens/init_screen/init_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:belluga_now/testing/invite_model_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() async {
    await GetIt.I.reset(dispose: false);
  });

  tearDown(() async {
    await GetIt.I.reset(dispose: false);
  });

  testWidgets('tenant pending invite navigates to home plus invite flow',
      (tester) async {
    final gate = _FakePushPresentationGate();
    GetIt.I.registerSingleton<InitScreenController>(
      InitScreenController(
        invitesRepository: _FakeInvitesRepository(hasPendingInvites: true),
        appDataRepository: _FakeAppDataRepository(
          _buildAppData(environmentType: EnvironmentType.tenant),
        ),
        pushPresentationGate: gate,
      ),
    );

    final router = _RecordingStackRouter(canPopValue: false);

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: const MaterialApp(home: InitScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    final asyncExceptions = _takeAllExceptions(tester);

    expect(
      asyncExceptions,
      isEmpty,
      reason: _formatAsyncExceptions(asyncExceptions),
    );
    expect(
      router.lastReplaced?.map((route) => route.routeName).toList(),
      [
        TenantHomeRoute.name,
        InviteFlowRoute.name,
      ],
    );
  });

  testWidgets('landlord bootstrap navigates only to landlord home',
      (tester) async {
    final gate = _FakePushPresentationGate();
    GetIt.I.registerSingleton<InitScreenController>(
      InitScreenController(
        invitesRepository: _FakeInvitesRepository(hasPendingInvites: true),
        appDataRepository: _FakeAppDataRepository(
          _buildAppData(environmentType: EnvironmentType.landlord),
        ),
        pushPresentationGate: gate,
      ),
    );

    final router = _RecordingStackRouter(canPopValue: false);

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: const MaterialApp(home: InitScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    final asyncExceptions = _takeAllExceptions(tester);

    expect(
      asyncExceptions,
      isEmpty,
      reason: _formatAsyncExceptions(asyncExceptions),
    );
    expect(
      router.lastReplaced?.map((route) => route.routeName).toList(),
      [LandlordHomeRoute.name],
    );
  });
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  _FakeInvitesRepository({required this.hasPendingInvites});

  @override
  final bool hasPendingInvites;

  @override
  Future<void> init() async {
    pendingInvitesStreamValue.addValue(
      hasPendingInvites ? [_buildInvite()] : const [],
    );
  }

  @override
  Future<List<InviteModel>> fetchInvites(
      {int page = 1, int pageSize = 20}) async {
    return hasPendingInvites ? [_buildInvite()] : const [];
  }

  @override
  Future<InviteRuntimeSettings> fetchSettings() async {
    return buildInviteRuntimeSettings(
      tenantId: null,
      limits: {},
      cooldowns: {},
      overQuotaMessage: null,
    );
  }

  @override
  Future<InviteAcceptResult> acceptInvite(String inviteId) async {
    return buildInviteAcceptResult(
      inviteId: inviteId,
      status: 'accepted',
      creditedAcceptance: true,
      attendancePolicy: 'free_confirmation_only',
      nextStep: InviteNextStep.freeConfirmationCreated,
      supersededInviteIds: const [],
    );
  }

  @override
  Future<InviteDeclineResult> declineInvite(String inviteId) async {
    return buildInviteDeclineResult(
      inviteId: inviteId,
      status: 'declined',
      groupHasOtherPending: false,
    );
  }

  @override
  Future<InviteShareCodeResult> createShareCode({
    required String eventId,
    String? occurrenceId,
    String? accountProfileId,
  }) async {
    return buildInviteShareCodeResult(
      code: 'CODE123',
      eventId: eventId,
      occurrenceId: occurrenceId,
    );
  }

  @override
  Future<List<InviteContactMatch>> importContacts(
    List<ContactModel> contacts,
  ) async =>
      const [];

  @override
  Future<void> sendInvites(
    String eventId,
    List<EventFriendResume> recipients, {
    String? occurrenceId,
    String? message,
  }) async {}

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(
    String eventId,
  ) async =>
      const [];
}

class _FakeAppDataRepository implements AppDataRepositoryContract {
  _FakeAppDataRepository(this.appData);

  @override
  final AppData appData;

  @override
  StreamValue<double> get maxRadiusMetersStreamValue =>
      StreamValue<double>(defaultValue: 1000);

  @override
  double get maxRadiusMeters => 1000;

  @override
  bool get hasPersistedMaxRadiusPreference => false;

  @override
  ThemeMode get themeMode => ThemeMode.light;

  @override
  StreamValue<ThemeMode?> get themeModeStreamValue =>
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.light);

  @override
  Future<void> init() async {}

  @override
  Future<void> setMaxRadiusMeters(double meters) async {}

  @override
  Future<void> setThemeMode(ThemeMode mode) async {}
}

class _FakePushPresentationGate implements PushPresentationGateContract {
  int markReadyCalls = 0;

  @override
  bool get isReady => markReadyCalls > 0;

  @override
  void markReady() {
    markReadyCalls += 1;
  }

  @override
  Future<void> waitUntilReady() async {}
}

class _RecordingStackRouter extends Mock implements StackRouter {
  _RecordingStackRouter({required this.canPopValue});

  final bool canPopValue;
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
  Future<void> replaceAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
    bool updateExistingRoutes = true,
  }) async {
    lastReplaced = routes;
  }
}

List<Object> _takeAllExceptions(WidgetTester tester) {
  final exceptions = <Object>[];
  Object? error;
  while ((error = tester.takeException()) != null) {
    exceptions.add(error!);
  }
  return exceptions;
}

String _formatAsyncExceptions(List<Object> exceptions) {
  if (exceptions.isEmpty) {
    return 'No async exception captured.';
  }
  return exceptions.join('\n---\n');
}

InviteModel _buildInvite() {
  return buildInviteModelFromPrimitives(
    id: 'invite-1',
    eventId: 'event-1',
    eventName: 'Evento',
    eventDateTime: DateTime(2026, 3, 15, 20),
    eventImageUrl: 'https://example.com/event.png',
    location: 'Centro',
    hostName: 'Host',
    message: 'Bora sim',
    tags: const ['show'],
    inviterName: 'Ana',
  );
}

AppData _buildAppData({
  required EnvironmentType environmentType,
}) {
  final platformType = PlatformTypeValue()..parse(AppType.web.name);
  final hostname = environmentType == EnvironmentType.landlord
      ? 'landlord.belluga.space'
      : 'guarappari.belluga.space';
  return buildAppDataFromInitialization(
    remoteData: {
      'name': 'Test',
      'type': environmentType.name,
      'main_domain': 'https://$hostname',
      'domains': ['https://$hostname'],
      'app_domains': const [],
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
      'hostname': hostname,
      'href': 'https://$hostname',
      'port': null,
      'device': 'test-device',
    },
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
