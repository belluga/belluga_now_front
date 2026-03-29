import 'dart:async';
import 'package:belluga_now/testing/domain_factories.dart';
import 'dart:io';
import 'package:belluga_now/testing/invite_accept_result_builder.dart';
import 'package:belluga_now/testing/invite_materialize_result_builder.dart';

import 'package:belluga_now/application/router/app_router.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/modular_app/modules/home_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/initialization_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/invites_module.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:belluga_now/domain/app_data/value_object/environment_name_value.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_materialize_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/invites/projections/friend_resume.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/friends_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/tenant/value_objects/icon_url_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_color_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_logo_url_value.dart';
import 'package:belluga_now/domain/user/friend.dart';
import 'package:belluga_now/domain/value_objects/asset_path_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:belluga_now/presentation/shared/init/screens/init_screen/controllers/init_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/controllers/tenant_home_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/controllers/tenant_home_agenda_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/favorite_section/controllers/favorites_section_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/invites_banner/controllers/invites_banner_builder_controller.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_value/core/stream_value.dart';

import '../../presentation/tenant/home/screens/tenant_home_screen/tenant_home_screen_test.mocks.dart';
import 'package:belluga_now/testing/invite_model_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() async {
    resetMockitoState();
    await GetIt.I.reset(dispose: false);
  });

  tearDown(() async {
    await GetIt.I.reset(dispose: false);
  });

  testWidgets('tenant bootstrap reaches home without framework exceptions',
      (tester) async {
    _registerTenantBootstrapDependencies();

    final initializationModule = InitializationModule();
    final homeModule = HomeModule();
    GetIt.I.registerSingleton<InitializationModule>(initializationModule);
    GetIt.I.registerSingleton<HomeModule>(homeModule);
    final router = AppRouter()
      ..setChildModules([
        initializationModule,
        homeModule,
      ]);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router.config(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await _pumpFrames(tester);

    final asyncExceptions = _takeAllExceptions(tester);

    expect(
      asyncExceptions,
      isEmpty,
      reason: _formatAsyncExceptions(asyncExceptions),
    );
    expect(router.current.name, TenantHomeRoute.name);
    expect(find.text('Seus Favoritos'), findsOneWidget);
  });

  testWidgets(
      'tenant privacy policy route resolves without framework exceptions',
      (tester) async {
    _registerTenantBootstrapDependencies();

    final homeModule = HomeModule();
    GetIt.I.registerSingleton<HomeModule>(homeModule);
    final router = AppRouter()
      ..setChildModules([
        homeModule,
      ]);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router.config(),
      ),
    );
    await tester.pump();
    await _pumpFrames(tester);

    unawaited(router.pushPath('/privacy-policy'));
    await tester.pump();
    await _pumpFrames(tester);

    final asyncExceptions = _takeAllExceptions(tester);

    expect(
      asyncExceptions,
      isEmpty,
      reason: _formatAsyncExceptions(asyncExceptions),
    );
    expect(router.current.name, TenantPrivacyPolicyRoute.name);
    expect(find.text('Política de privacidade'), findsWidgets);
  });

  testWidgets('tenant privacy policy legacy path redirects to canonical route',
      (tester) async {
    _registerTenantBootstrapDependencies();

    final homeModule = HomeModule();
    GetIt.I.registerSingleton<HomeModule>(homeModule);
    final router = AppRouter()
      ..setChildModules([
        homeModule,
      ]);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router.config(),
      ),
    );
    await tester.pump();
    await _pumpFrames(tester);

    unawaited(router.pushPath('/politica-de-privacidade'));
    await tester.pump();
    await _pumpFrames(tester);

    final asyncExceptions = _takeAllExceptions(tester);

    expect(
      asyncExceptions,
      isEmpty,
      reason: _formatAsyncExceptions(asyncExceptions),
    );
    expect(router.current.name, TenantPrivacyPolicyRoute.name);
  });

  testWidgets(
      'invite fallback navigation reaches tenant home without framework exceptions',
      (tester) async {
    _registerTenantBootstrapDependencies(
      invitesRepository: _FakeInvitesRepository(
        hasPendingInvites: false,
        previewInvite: null,
      ),
      authRepository: _FakeAuthRepository(authorized: false),
    );

    final homeModule = HomeModule();
    final invitesModule = InvitesModule();
    GetIt.I.registerSingleton<HomeModule>(homeModule);
    GetIt.I.registerSingleton<InvitesModule>(invitesModule);
    final router = AppRouter()
      ..setChildModules([
        homeModule,
        invitesModule,
      ]);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router.config(),
      ),
    );
    await tester.pump();
    await _pumpFrames(tester);

    unawaited(router.pushPath('/invite?code=INVALID'));
    await tester.pump();
    await _pumpFrames(tester, count: 40);

    final asyncExceptions = _takeAllExceptions(tester);

    expect(
      asyncExceptions,
      isEmpty,
      reason: _formatAsyncExceptions(asyncExceptions),
    );
    expect(router.current.name, TenantHomeRoute.name);
    expect(find.text('Seus Favoritos'), findsOneWidget);
  });
}

Future<void> _pumpFrames(WidgetTester tester, {int count = 20}) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
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

void _registerTenantBootstrapDependencies({
  InvitesRepositoryContract? invitesRepository,
  AuthRepositoryContract? authRepository,
}) {
  final appData = _buildAppData(environmentType: EnvironmentType.tenant);
  final resolvedInvitesRepository =
      invitesRepository ?? _FakeInvitesRepository(hasPendingInvites: false);
  final friendsRepository = _FakeFriendsRepository();
  final userEventsRepository = _FakeUserEventsRepository();
  final telemetryRepository = _FakeTelemetryRepository();
  final appDataRepository = _FakeAppDataRepository(appData);

  final mockController = MockTenantHomeController();
  final mockAgendaController = MockTenantHomeAgendaController();
  final mockFavoritesController = MockFavoritesSectionController();
  final mockInvitesBannerController = MockInvitesBannerBuilderController();
  final mockAppData = MockAppData();
  final testScrollController = ScrollController();

  GetIt.I.registerSingleton<AppData>(appData);
  GetIt.I.registerSingleton<AppDataRepositoryContract>(appDataRepository);
  GetIt.I
      .registerSingleton<InvitesRepositoryContract>(resolvedInvitesRepository);
  GetIt.I.registerSingleton<FriendsRepositoryContract>(friendsRepository);
  GetIt.I.registerSingleton<UserEventsRepositoryContract>(userEventsRepository);
  GetIt.I.registerSingleton<TelemetryRepositoryContract>(telemetryRepository);
  if (authRepository != null) {
    GetIt.I.registerSingleton<AuthRepositoryContract>(authRepository);
  }
  GetIt.I.registerSingleton<InitScreenController>(
    InitScreenController(
      invitesRepository: resolvedInvitesRepository,
      appDataRepository: appDataRepository,
    ),
  );

  GetIt.I.registerSingleton<TenantHomeController>(mockController);
  GetIt.I.registerSingleton<TenantHomeAgendaController>(mockAgendaController);
  GetIt.I.registerSingleton<FavoritesSectionController>(
    mockFavoritesController,
  );
  GetIt.I.registerSingleton<InvitesBannerBuilderController>(
    mockInvitesBannerController,
  );
  GetIt.I.registerSingleton<MockAppData>(mockAppData);

  when(mockAppData.nameValue).thenReturn(
    EnvironmentNameValue()..parse('Test App'),
  );
  when(mockAppData.mainColor).thenReturn(
    MainColorValue()..parse('#000000'),
  );
  when(mockAppData.mainIconLightUrl).thenReturn(
    IconUrlValue()..parse('http://example.com/icon.png'),
  );
  when(mockAppData.mainLogoLightUrl).thenReturn(
    MainLogoUrlValue()..parse('http://example.com/logo-light.png'),
  );
  when(mockAppData.mainLogoDarkUrl).thenReturn(
    MainLogoUrlValue()..parse('http://example.com/logo-dark.png'),
  );

  when(mockFavoritesController.favoritesStreamValue).thenReturn(
    StreamValue<List<FavoriteResume>?>(defaultValue: const []),
  );
  when(mockFavoritesController.init()).thenAnswer((_) async {});
  when(mockFavoritesController.buildPinnedFavorite()).thenReturn(
    FavoriteResume(
      titleValue: TitleValue()..parse('Pinned'),
      assetPathValue: AssetPathValue()
        ..parse('assets/images/placeholder_avatar.png'),
      isPrimary: true,
    ),
  );
  when(mockInvitesBannerController.pendingInvitesStreamValue).thenReturn(
    StreamValue<List<InviteModel>>(defaultValue: const []),
  );

  when(mockController.appData).thenReturn(appData);
  when(mockController.init()).thenAnswer((_) async {});
  when(mockController.userAddressStreamValue).thenReturn(
    StreamValue<String?>(defaultValue: 'Rua Teste, 123'),
  );
  when(mockController.myEventsFilteredStreamValue).thenReturn(
    StreamValue<List<VenueEventResume>>(defaultValue: const []),
  );
  when(mockController.scrollController).thenReturn(testScrollController);

  when(mockAgendaController.isInitialLoadingStreamValue).thenReturn(
    StreamValue<bool>(defaultValue: false),
  );
  when(mockAgendaController.initialLoadingLabelStreamValue).thenReturn(
    StreamValue<String>(defaultValue: ''),
  );
  when(mockAgendaController.isPageLoadingStreamValue).thenReturn(
    StreamValue<bool>(defaultValue: false),
  );
  when(mockAgendaController.showHistoryStreamValue).thenReturn(
    StreamValue<bool>(defaultValue: false),
  );
  when(mockAgendaController.searchActiveStreamValue).thenReturn(
    StreamValue<bool>(defaultValue: false),
  );
  when(mockAgendaController.inviteFilterStreamValue).thenReturn(
    StreamValue<InviteFilter>(defaultValue: InviteFilter.none),
  );
  when(mockAgendaController.radiusMetersStreamValue).thenReturn(
    StreamValue<double>(defaultValue: 1000),
  );
  when(mockAgendaController.maxRadiusMetersStreamValue).thenReturn(
    StreamValue<double>(defaultValue: 5000),
  );
  when(mockAgendaController.hasMoreStreamValue).thenReturn(
    StreamValue<bool>(defaultValue: false),
  );
  when(mockAgendaController.displayedEventsStreamValue).thenReturn(
    StreamValue<List<EventModel>>(defaultValue: const []),
  );
  when(mockAgendaController.searchController).thenReturn(
    TextEditingController(),
  );
  when(mockAgendaController.focusNode).thenReturn(FocusNode());
  when(
    mockAgendaController.init(startWithHistory: false),
  ).thenAnswer((_) async {});
  when(
    mockAgendaController.setInviteFilter(InviteFilter.none),
  ).thenReturn(null);
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  _FakeInvitesRepository({
    required this.hasPendingInvites,
    this.previewInvite,
  });

  @override
  final bool hasPendingInvites;
  final InviteModel? previewInvite;

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
  Future<InviteMaterializeResult> materializeShareCode(String code) async {
    return buildInviteMaterializeResult(
      inviteId: hasPendingInvites ? _buildInvite().id : '',
      status: hasPendingInvites ? 'pending' : 'expired',
      creditedAcceptance: false,
      attendancePolicy: 'free_confirmation_only',
    );
  }

  @override
  Future<InviteModel?> previewShareCode(String code) async {
    return previewInvite;
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

class _FakeFriendsRepository implements FriendsRepositoryContract {
  @override
  StreamValue<List<InviteFriendResume>> get friendsStreamValue =>
      StreamValue<List<InviteFriendResume>>(defaultValue: const []);

  @override
  Future<void> fetchAndCacheFriends({bool forceRefresh = false}) async {}

  @override
  Future<List<Friend>> fetchFriends() async => const [];
}

class _FakeUserEventsRepository implements UserEventsRepositoryContract {
  @override
  final StreamValue<Set<String>> confirmedEventIdsStream =
      StreamValue<Set<String>>(defaultValue: const {});

  @override
  Future<void> confirmEventAttendance(String eventId) async {}

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async => const [];

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async => const [];

  @override
  bool isEventConfirmed(String eventId) => false;

  @override
  Future<void> refreshConfirmedEventIds() async {}

  @override
  Future<void> unconfirmEventAttendance(String eventId) async {}
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
