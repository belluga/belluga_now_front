import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_public_instances_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/landlord_auth_repository_contract_values.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/presentation/landlord_area/home/screens/landlord_home_screen/controllers/landlord_home_screen_controller.dart';
import 'package:belluga_now/presentation/landlord_area/home/screens/landlord_home_screen/landlord_home_screen.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('shows landing + tenants + login CTA when not authenticated',
      (tester) async {
    GetIt.I.registerSingleton<AdminModeRepositoryContract>(
      _FakeAdminModeRepository(isLandlordMode: false),
    );
    GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(
      _FakeLandlordAuthRepository(hasValidSession: false),
    );
    final appDataRepository = _FakeAppDataRepository(
      appData: _buildAppData(
        environmentType: EnvironmentType.landlord,
        name: 'Bóora!',
        domain: 'belluga.space',
      ),
    );
    final publicInstancesRepository = _FakeLandlordPublicInstancesRepository([
      _buildAppData(
        environmentType: EnvironmentType.tenant,
        name: 'Tenant One',
        domain: 'tenant-one.example.com',
      ),
      _buildAppData(
        environmentType: EnvironmentType.tenant,
        name: 'Tenant Two',
        domain: 'tenant-two.example.com',
      ),
    ]);
    GetIt.I.registerSingleton<AppDataRepositoryContract>(appDataRepository);
    final controller = LandlordHomeScreenController(
      adminModeRepository: GetIt.I.get<AdminModeRepositoryContract>(),
      landlordAuthRepository: GetIt.I.get<LandlordAuthRepositoryContract>(),
      appDataRepository: appDataRepository,
      publicInstancesRepository: publicInstancesRepository,
    );
    GetIt.I.registerSingleton<LandlordHomeScreenController>(controller);
    final router = _RecordingStackRouter();

    await tester.pumpWidget(
      _buildRoutedLandlordHomeApp(router),
    );
    await tester.pumpAndSettle();

    expect(find.text('O que tem para fazer hoje?'), findsOneWidget);
    expect(find.text('Tenant One'), findsOneWidget);
    expect(find.text('tenant-one.example.com'), findsOneWidget);
    expect(find.text('Tenant Two'), findsOneWidget);
    expect(find.text('tenant-two.example.com'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Foco Hiperlocal'), findsOneWidget);
    expect(find.text('A Cidade na Palma da Mão'), findsOneWidget);
    expect(find.text('Descubra!'), findsOneWidget);
    expect(find.text('Motor Viral'), findsOneWidget);
    expect(find.text('Não Basta ter Clientes'), findsOneWidget);
    expect(
      find.text(
        'Agenda centralizada por geolocalização. Saiba exatamente o que está acontecendo perto de você agora ou amanhã, sem depender de algoritmos.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'O usuário tem papel ativo convidando amigos e promovendo os eventos, artistas e locais que prefere. Planos pagos (SaaS) permitem que o Trade também envie convites a quem os segue na plataforma.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows admin CTA when landlord session and mode are active',
      (tester) async {
    GetIt.I.registerSingleton<AdminModeRepositoryContract>(
      _FakeAdminModeRepository(isLandlordMode: true),
    );
    GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(
      _FakeLandlordAuthRepository(hasValidSession: true),
    );
    final appDataRepository = _FakeAppDataRepository(
      appData: _buildAppData(
        environmentType: EnvironmentType.landlord,
        name: 'Bóora!',
        domain: 'belluga.space',
      ),
    );
    final publicInstancesRepository = _FakeLandlordPublicInstancesRepository([
      _buildAppData(
        environmentType: EnvironmentType.tenant,
        name: 'Tenant One',
        domain: 'tenant-one.example.com',
      ),
    ]);
    GetIt.I.registerSingleton<AppDataRepositoryContract>(appDataRepository);
    final controller = LandlordHomeScreenController(
      adminModeRepository: GetIt.I.get<AdminModeRepositoryContract>(),
      landlordAuthRepository: GetIt.I.get<LandlordAuthRepositoryContract>(),
      appDataRepository: appDataRepository,
      publicInstancesRepository: publicInstancesRepository,
    );
    GetIt.I.registerSingleton<LandlordHomeScreenController>(controller);
    final router = _RecordingStackRouter();

    await tester.pumpWidget(
      _buildRoutedLandlordHomeApp(router),
    );
    await tester.pumpAndSettle();

    expect(controller.canAccessAdminArea, isTrue);
    expect(find.text('Tenant One'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('landlord home system back delegates to SystemNavigator.pop',
      (tester) async {
    GetIt.I.registerSingleton<AdminModeRepositoryContract>(
      _FakeAdminModeRepository(isLandlordMode: false),
    );
    GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(
      _FakeLandlordAuthRepository(hasValidSession: false),
    );
    final appDataRepository = _FakeAppDataRepository(
      appData: _buildAppData(
        environmentType: EnvironmentType.landlord,
        name: 'Bóora!',
        domain: 'belluga.space',
      ),
    );
    final publicInstancesRepository = _FakeLandlordPublicInstancesRepository([
      _buildAppData(
        environmentType: EnvironmentType.tenant,
        name: 'Tenant One',
        domain: 'tenant-one.example.com',
      ),
    ]);
    GetIt.I.registerSingleton<AppDataRepositoryContract>(appDataRepository);
    final controller = LandlordHomeScreenController(
      adminModeRepository: GetIt.I.get<AdminModeRepositoryContract>(),
      landlordAuthRepository: GetIt.I.get<LandlordAuthRepositoryContract>(),
      appDataRepository: appDataRepository,
      publicInstancesRepository: publicInstancesRepository,
    );
    GetIt.I.registerSingleton<LandlordHomeScreenController>(controller);
    final router = _RecordingStackRouter();
    var systemPopCallCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') {
          systemPopCallCount += 1;
        }
        return null;
      },
    );
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
      return Future<void>.value();
    });

    await tester.pumpWidget(
      _buildRoutedLandlordHomeApp(router),
    );
    await tester.pumpAndSettle();

    final popScope = tester.widget<PopScope<dynamic>>(
      find.byWidgetPredicate((widget) => widget is PopScope),
    );
    popScope.onPopInvokedWithResult?.call(false, null);
    await tester.pumpAndSettle();

    expect(router.canPopCallCount, 1);
    expect(systemPopCallCount, 1);
  });
}

Widget _buildRoutedLandlordHomeApp(_RecordingStackRouter router) {
  final routeData = RouteData(
    route: RouteMatch(
      config: AutoRoute(
        page: LandlordHomeRoute.page,
        path: '/',
        meta: canonicalRouteMeta(
          family: CanonicalRouteFamily.landlordHome,
        ),
      ),
      segments: const <String>[],
      stringMatch: '/',
      key: const ValueKey<String>('landlord-home'),
    ),
    router: router,
    stackKey: const ValueKey<String>('stack'),
    pendingChildren: const <RouteMatch>[],
    type: const RouteType.material(),
  );

  return StackRouterScope(
    controller: router,
    stateHash: 0,
    child: MaterialApp(
      home: RouteDataScope(
        routeData: routeData,
        child: const LandlordHomeScreen(),
      ),
    ),
  );
}

class _RecordingStackRouter extends Fake implements StackRouter {
  int canPopCallCount = 0;

  @override
  RootStackRouter get root => _FakeRootStackRouter('/');

  @override
  bool canPop({
    bool ignoreChildRoutes = false,
    bool ignoreParentRoutes = false,
    bool ignorePagelessRoutes = false,
  }) {
    canPopCallCount += 1;
    return false;
  }

  @override
  Future<void> replaceAll(
    List<PageRouteInfo<dynamic>> routes, {
    OnNavigationFailure? onFailure,
    bool updateExistingRoutes = true,
  }) async {}
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

class _FakeAdminModeRepository implements AdminModeRepositoryContract {
  _FakeAdminModeRepository({required this.isLandlordMode});

  @override
  final bool isLandlordMode;

  @override
  StreamValue<AdminMode> get modeStreamValue =>
      StreamValue<AdminMode>(defaultValue: mode);

  @override
  AdminMode get mode => isLandlordMode ? AdminMode.landlord : AdminMode.user;

  @override
  Future<void> init() async {}

  @override
  Future<void> setLandlordMode() async {}

  @override
  Future<void> setUserMode() async {}
}

class _FakeLandlordAuthRepository implements LandlordAuthRepositoryContract {
  _FakeLandlordAuthRepository({required this.hasValidSession});

  @override
  final bool hasValidSession;

  @override
  String get token => '';

  @override
  Future<void> init() async {}

  @override
  Future<void> loginWithEmailPassword(
    LandlordAuthRepositoryContractTextValue email,
    LandlordAuthRepositoryContractTextValue password,
  ) async {}

  @override
  Future<void> logout() async {}
}

class _FakeAppDataRepository extends AppDataRepositoryContract {
  _FakeAppDataRepository({required AppData appData}) : _appData = appData;

  final AppData _appData;

  @override
  AppData get appData => _appData;

  @override
  StreamValue<ThemeMode?> get themeModeStreamValue =>
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.light);

  @override
  ThemeMode get themeMode => ThemeMode.light;

  @override
  Future<void> init() async {}

  @override
  Future<void> setThemeMode(AppThemeModeValue mode) async {}

  @override
  StreamValue<DistanceInMetersValue> get maxRadiusMetersStreamValue =>
      StreamValue<DistanceInMetersValue>(
        defaultValue: DistanceInMetersValue.fromRaw(1000, defaultValue: 1000),
      );

  @override
  DistanceInMetersValue get maxRadiusMeters =>
      DistanceInMetersValue.fromRaw(1000, defaultValue: 1000);

  @override
  bool get hasPersistedMaxRadiusPreference => false;

  @override
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {}
}

class _FakeLandlordPublicInstancesRepository
    implements LandlordPublicInstancesRepositoryContract {
  const _FakeLandlordPublicInstancesRepository(this.instances);

  final List<AppData> instances;

  @override
  Future<List<AppData>> fetchFeaturedInstances() async => instances;
}

AppData _buildAppData({
  required EnvironmentType environmentType,
  required String name,
  required String domain,
  String mainColor = '#10B981',
}) {
  final platformType = PlatformTypeValue()..parse(AppType.web.name);
  final normalizedDomain = domain.contains('://') ? domain : 'https://$domain';
  final uri = Uri.parse(normalizedDomain);
  final host = uri.host.trim().isEmpty ? domain : uri.host.trim();

  return buildAppDataFromInitialization(
    remoteData: {
      'name': name,
      'type': environmentType.name,
      'main_domain': normalizedDomain,
      'domains': [normalizedDomain],
      'app_domains': const [],
      'theme_data_settings': {
        'primary_seed_color': mainColor,
        'secondary_seed_color': '#F97316',
        'brightness_default': 'light',
      },
      'main_color': mainColor,
      'tenant_id': '${environmentType.name}-$host',
      'telemetry': {'trackers': []},
    },
    localInfo: {
      'platformType': platformType,
      'hostname': host,
      'href': normalizedDomain,
      'port': null,
      'device': 'test-device',
    },
  );
}
