// ApplicationContract intentionally owns mutable application-lifecycle fields.
// ignore_for_file: must_be_immutable

import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/modular_app/module_settings.dart';
import 'package:belluga_now/application/router/modular_app/modules/initialization_module.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_governance.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_cooldowns_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_rate_limits_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/presentation/shared/widgets/route_back_scope.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/controllers/invite_flow_controller.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/invite_flow_screen.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/testing/invite_model_factory.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides? previousHttpOverrides;
  setUpAll(() {
    previousHttpOverrides = HttpOverrides.current;
    HttpOverrides.global = _TestHttpOverrides();
  });
  setUp(() async => GetIt.I.reset());
  tearDown(() async => GetIt.I.reset());
  tearDownAll(() => HttpOverrides.global = previousHttpOverrides);

  testWidgets(
    'Application.init startup terminal empty leaves one Home and framework back opens the exit dialog',
    (tester) async {
      final repository = _PendingInvitesRepository(<InviteModel>[_invite()]);
      final app = _RegressionApplication(repository);
      // The injected repository is registered by the test ModuleSettings before
      // init, so the production AppStartupPlanResolver—not a literal test plan—
      // creates the startup [Home, Invite] hierarchy.
      await tester.runAsync(app.init);
      await tester.pumpWidget(app);
      await _flush(tester);
      expect(_hierarchy(app.appRouter), <String>[
        TenantHomeRoute.name,
        InviteFlowRoute.name,
      ]);
      expect(repository.refreshCalls, greaterThanOrEqualTo(2));

      repository.setPending(const <InviteModel>[]);
      await GetIt.I.get<InviteFlowScreenController>().fetchPendingInvites();
      await _flush(tester);
      expect(_hierarchy(app.appRouter), <String>[TenantHomeRoute.name]);
      expect(find.byTooltip('Back'), findsNothing);
      expect(find.text('canonical-home'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await _flush(tester);
      expect(find.text('Sair do app?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await _flush(tester);
      expect(_hierarchy(app.appRouter), <String>[TenantHomeRoute.name]);
      expect(find.text('canonical-home'), findsOneWidget);
    },
  );

  testWidgets('actual-router terminal branch pops a non-Home predecessor', (
    tester,
  ) async {
    final h = await _harness(tester, const <PageRouteInfo<dynamic>>[
      _PredecessorRoute(),
      InviteFlowRoute(),
    ]);
    await h.emptyAuthoritatively(tester);
    expect(h.names, <String>[_PredecessorRoute.name]);
    expect(find.text('predecessor'), findsOneWidget);
  });

  testWidgets('actual-router root Invite terminal branch falls back to Home', (
    tester,
  ) async {
    final h = await _harness(tester, const <PageRouteInfo<dynamic>>[
      InviteFlowRoute(),
    ]);
    await h.emptyAuthoritatively(tester);
    expect(h.names, <String>[TenantHomeRoute.name]);
  });

  testWidgets(
    'actual-router continuation replaces Invite and back exposes exact prior Home',
    (tester) async {
      final h = await _harness(tester, const <PageRouteInfo<dynamic>>[
        TenantHomeRoute(),
        InviteFlowRoute(),
      ]);
      h.repository.setShareCodeSessionContext(
        code: invitesRepoString('code', defaultValue: '', isRequired: true),
        invite: _invite(),
      );
      await h.emptyAuthoritatively(tester);
      expect(h.names, <String>[TenantHomeRoute.name, _EventRoute.name]);
      await tester.binding.handlePopRoute();
      await _flush(tester);
      expect(h.names, <String>[TenantHomeRoute.name]);
    },
  );

  testWidgets('actual-router refresh failure retains Home and Invite', (
    tester,
  ) async {
    final h = await _harness(tester, const <PageRouteInfo<dynamic>>[
      TenantHomeRoute(),
      InviteFlowRoute(),
    ]);
    h.repository.failRefresh = true;
    await h.controller.fetchPendingInvites();
    await _flush(tester);
    expect(h.names, <String>[TenantHomeRoute.name, InviteFlowRoute.name]);
    expect(h.repository.inviteFlowDisplayInvitesStreamValue.value, isNotEmpty);
  });

  testWidgets(
    'pending toolbar and framework back retain pending data while revealing Home',
    (tester) async {
      final h = await _harness(tester, const <PageRouteInfo<dynamic>>[
        TenantHomeRoute(),
        InviteFlowRoute(),
      ]);
      await tester.tap(find.byTooltip('Fechar'));
      await _flush(tester);
      expect(h.names, <String>[TenantHomeRoute.name]);
      expect(h.repository.pendingInvitesStreamValue.value, hasLength(1));
      unawaited(h.router.push(const InviteFlowRoute()));
      await _flush(tester);
      await tester.binding.handlePopRoute();
      await _flush(tester);
      expect(h.names, <String>[TenantHomeRoute.name]);
      expect(h.repository.pendingInvitesStreamValue.value, hasLength(1));
    },
  );
}

List<String> _hierarchy(StackRouter router) =>
    router.currentHierarchy().map((route) => route.name).toList();

Future<void> _flush(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump();
}

Future<_Harness> _harness(
  WidgetTester tester,
  List<PageRouteInfo<dynamic>> routes,
) async {
  final repository = _PendingInvitesRepository(<InviteModel>[_invite()]);
  final controller = InviteFlowScreenController(
    appData: _appData(),
    repository: repository,
    telemetryRepository: _TelemetryRepository(),
    authRepository: _AuthRepository(),
  );
  GetIt.I.registerSingleton<InviteFlowScreenController>(controller);
  final router = RootStackRouter.build(routes: _RegressionRoutes.allRoutes);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router.config()));
  router.replaceAll(routes);
  await _flush(tester);
  await controller.init();
  await _flush(tester);
  return _Harness(router, repository, controller);
}

class _Harness {
  const _Harness(this.router, this.repository, this.controller);
  final RootStackRouter router;
  final _PendingInvitesRepository repository;
  final InviteFlowScreenController controller;
  List<String> get names => _hierarchy(router);
  Future<void> emptyAuthoritatively(WidgetTester tester) async {
    repository.setPending(const <InviteModel>[]);
    await controller.fetchPendingInvites();
    await _flush(tester);
  }
}

class _RegressionApplication extends ApplicationContract {
  _RegressionApplication(_PendingInvitesRepository repository)
    : _settings = _RegressionSettings(repository);
  final _RegressionSettings _settings;
  @override
  ModuleSettings get moduleSettings => _settings;
  @override
  Future<void> initialSettingsPlatform() async {}
}

class _RegressionSettings extends ModuleSettings {
  _RegressionSettings(this.repository);
  final _PendingInvitesRepository repository;
  @override
  Future<void> registerGlobalDependencies() async {
    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      _AppDataRepository(_appData()),
    );
    final auth = _AuthRepository();
    GetIt.I.registerSingleton<AuthRepositoryContract>(auth);
    GetIt.I.registerSingleton<InvitesRepositoryContract>(repository);
    GetIt.I.registerSingleton<TelemetryRepositoryContract>(
      _TelemetryRepository(),
    );
    GetIt.I.registerSingleton<InviteFlowScreenController>(
      InviteFlowScreenController(
        appData: _appData(),
        repository: repository,
        telemetryRepository: GetIt.I.get<TelemetryRepositoryContract>(),
        authRepository: auth,
      ),
    );
    registerStartupDependencies();
  }

  @override
  Future<void> initializeSubmodules() async {
    await registerSubModuleIfAbsent(InitializationModule());
    await registerSubModuleIfAbsent(_RegressionRoutes());
  }
}

class _RegressionRoutes extends ModuleContract {
  static final List<AutoRoute> allRoutes = <AutoRoute>[
    AutoRoute(
      path: '/',
      page: PageInfo.builder(
        TenantHomeRoute.name,
        builder: (_, _) => const _CanonicalHome(),
      ),
      meta: canonicalRouteMeta(family: CanonicalRouteFamily.tenantHome),
    ),
    AutoRoute(
      path: '/convites',
      page: PageInfo.builder(
        InviteFlowRoute.name,
        builder: (_, _) => const InviteFlowScreen(),
      ),
      meta: canonicalRouteMeta(family: CanonicalRouteFamily.inviteFlow),
    ),
    AutoRoute(
      path: '/agenda/evento/:slug',
      page: PageInfo.builder(
        _EventRoute.name,
        builder: (_, _) => const _Event(),
      ),
      meta: canonicalRouteMeta(
        family: CanonicalRouteFamily.immersiveEventDetail,
      ),
    ),
    AutoRoute(
      path: '/predecessor',
      page: PageInfo.builder(
        _PredecessorRoute.name,
        builder: (_, _) => const _Predecessor(),
      ),
      meta: canonicalRouteMeta(family: CanonicalRouteFamily.discoveryRoot),
    ),
  ];
  @override
  Future<void> registerDependencies() async {
    if (!GetIt.I.isRegistered<InviteFlowScreenController>()) {
      GetIt.I.registerSingleton<InviteFlowScreenController>(
        InviteFlowScreenController(),
      );
    }
  }

  @override
  List<AutoRoute> get routes => allRoutes;
}

class _CanonicalHome extends StatelessWidget {
  const _CanonicalHome();
  @override
  Widget build(BuildContext context) => RouteBackScope(
    backPolicy: buildCanonicalCurrentRouteBackPolicy(
      context,
      requestExit: () async {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sair do app?'),
            content: const Text('Deseja fechar o aplicativo agora?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => context.router.pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        );
      },
    ),
    child: Scaffold(
      appBar: AppBar(title: Text('canonical-home')),
      body: SizedBox.expand(),
    ),
  );
}

class _Event extends StatelessWidget {
  const _Event();
  @override
  Widget build(BuildContext context) => RouteBackScope(
    backPolicy: buildCanonicalCurrentRouteBackPolicy(context),
    child: const Scaffold(body: Center(child: Text('event'))),
  );
}

class _Predecessor extends StatelessWidget {
  const _Predecessor();
  @override
  Widget build(BuildContext context) => RouteBackScope(
    backPolicy: buildCanonicalCurrentRouteBackPolicy(context),
    child: const Scaffold(body: Center(child: Text('predecessor'))),
  );
}

class _EventRoute extends PageRouteInfo<void> {
  const _EventRoute() : super(name);
  static const String name = 'ImmersiveEventDetailRoute';
}

class _PredecessorRoute extends PageRouteInfo<void> {
  const _PredecessorRoute() : super(name);
  static const String name = 'PredecessorRoute';
}

class _PendingInvitesRepository extends InvitesRepositoryContract {
  _PendingInvitesRepository(this._pending);
  List<InviteModel> _pending;
  int refreshCalls = 0;
  bool failRefresh = false;
  void setPending(List<InviteModel> value) => _pending = value;
  @override
  Future<void> refreshPendingInvites({
    InvitesRepositoryContractPrimInt? page,
    InvitesRepositoryContractPrimInt? pageSize,
  }) async {
    refreshCalls++;
    if (failRefresh) throw StateError('refresh failed');
    pendingInvitesStreamValue.addValue(
      List<InviteModel>.unmodifiable(_pending),
    );
  }

  @override
  Future<List<InviteModel>> fetchInvites({
    InvitesRepositoryContractPrimInt? page,
    InvitesRepositoryContractPrimInt? pageSize,
  }) async => List<InviteModel>.unmodifiable(_pending);
  @override
  Future<InviteRuntimeSettings> fetchSettings() async => InviteRuntimeSettings(
    limitValues: InviteRateLimitsValue(),
    cooldownValues: InviteCooldownsValue(),
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AuthRepository extends AuthRepositoryContract<UserContract> {
  @override
  Object get backend => Object();
  @override
  String get userToken => '';
  @override
  bool get isAuthorized => true;
  @override
  bool get isUserLoggedIn => true;
  @override
  Future<void> init() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AppDataRepository extends AppDataRepositoryContract {
  _AppDataRepository(this._data);
  final AppData _data;
  final _theme = StreamValue<ThemeMode?>(defaultValue: ThemeMode.light);
  final _radius = StreamValue<DistanceInMetersValue>(
    defaultValue: DistanceInMetersValue()..set(50000),
  );
  @override
  AppData get appData => _data;
  @override
  ThemeMode get themeMode => _theme.value ?? ThemeMode.light;
  @override
  StreamValue<ThemeMode?> get themeModeStreamValue => _theme;
  @override
  DistanceInMetersValue get maxRadiusMeters => _radius.value;
  @override
  StreamValue<DistanceInMetersValue> get maxRadiusMetersStreamValue => _radius;
  @override
  Future<void> init() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TelemetryRepository extends TelemetryRepositoryContract {
  @override
  Future<TelemetryRepositoryContractPrimBool> logEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async => telemetryRepoBool(true, defaultValue: true, isRequired: true);
  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async => null;
  @override
  Future<TelemetryRepositoryContractPrimBool> finishTimedEvent(
    EventTrackerTimedEventHandle handle,
  ) async => telemetryRepoBool(true, defaultValue: true, isRequired: true);
  @override
  Future<TelemetryRepositoryContractPrimBool> flushTimedEvents() async =>
      telemetryRepoBool(true, defaultValue: true, isRequired: true);
  @override
  void setScreenContext(TelemetryRepositoryContractPrimMap? screenContext) {}
  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;
  @override
  Future<TelemetryRepositoryContractPrimBool> mergeIdentity({
    required TelemetryRepositoryContractPrimString previousUserId,
  }) async => telemetryRepoBool(true, defaultValue: true, isRequired: true);
}

AppData _appData() {
  final platform = PlatformTypeValue(defaultValue: AppType.mobile)
    ..parse(AppType.mobile.name);
  return buildAppDataFromInitialization(
    remoteData: <String, dynamic>{
      'name': 'Tenant',
      'type': 'tenant',
      'main_domain': 'https://tenant.test',
      'profile_types': const <Map<String, dynamic>>[],
      'domains': const <String>['https://tenant.test'],
      'app_domains': const <String>[],
      'theme_data_settings': <String, dynamic>{
        'primary_seed_color': '#000000',
        'secondary_seed_color': '#FFFFFF',
        'brightness_default': 'light',
      },
    },
    localInfo: <String, dynamic>{
      'platformType': platform,
      'port': '1.0.0',
      'hostname': 'tenant.test',
      'href': 'https://tenant.test',
      'device': 'test-device',
    },
  );
}

InviteModel _invite() => buildInviteModelFromPrimitives(
  id: 'invite-1',
  eventId: 'event-1',
  eventSlug: 'show-rock',
  eventName: 'Show Rock',
  eventDateTime: DateTime.utc(2026, 7, 12, 20),
  eventImageUrl: 'https://example.com/event.png',
  location: 'Guarapari',
  hostName: 'Belluga',
  message: 'Você foi convidado.',
  tags: const <String>['music'],
  occurrenceId: 'occ-1',
);

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _TestHttpClient();
}

class _TestHttpClient implements HttpClient {
  static const List<int> _image = <int>[
    137,
    80,
    78,
    71,
    13,
    10,
    26,
    10,
    0,
    0,
    0,
    13,
    73,
    72,
    68,
    82,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    1,
    8,
    6,
    0,
    0,
    0,
    31,
    21,
    196,
    137,
    0,
    0,
    0,
    10,
    73,
    68,
    65,
    84,
    120,
    156,
    99,
    0,
    1,
    0,
    0,
    5,
    0,
    1,
    13,
    10,
    45,
    180,
    0,
    0,
    0,
    0,
    73,
    69,
    78,
    68,
    174,
    66,
    96,
    130,
  ];
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _TestHttpRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _TestHttpRequest();
  bool _autoUncompress = true;
  @override
  bool get autoUncompress => _autoUncompress;
  @override
  set autoUncompress(bool value) => _autoUncompress = value;
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestHttpRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _TestHttpResponse();
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestHttpResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.ok;
  @override
  int get contentLength => _TestHttpClient._image.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(_TestHttpClient._image).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
