import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/guards/landlord_route_guard.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('allows navigation when landlord session + mode active', () {
    _registerAppData(_buildAppData(
      hostname: 'tenant.test',
      envType: 'tenant',
    ));
    GetIt.I.registerSingleton<AdminModeRepositoryContract>(
      _FakeAdminModeRepository(AdminMode.landlord),
    );
    GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(
      _FakeLandlordAuthRepository(hasValidSession: true),
    );

    final guard = LandlordRouteGuard();
    final resolver = MockNavigationResolver();
    final router = RecordingStackRouter();

    guard.onNavigation(resolver, router);

    verify(resolver.next(true)).called(1);
    expect(router.replaceAllCalled, isFalse);
  });

  test('blocks navigation when landlord mode inactive', () {
    _registerAppData(_buildAppData(
      hostname: 'tenant.test',
      envType: 'tenant',
    ));
    GetIt.I.registerSingleton<AdminModeRepositoryContract>(
      _FakeAdminModeRepository(AdminMode.user),
    );
    GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(
      _FakeLandlordAuthRepository(hasValidSession: true),
    );

    final guard = LandlordRouteGuard();
    final resolver = MockNavigationResolver();
    final router = RecordingStackRouter();

    guard.onNavigation(resolver, router);

    verify(resolver.next(false)).called(1);
    verifyNever(resolver.next(true));
    expect(router.replaceAllCalled, isTrue);
  });

  test('allows navigation on landlord host without session', () {
    _registerAppData(_buildAppData(
      hostname: 'belluga.app',
      envType: 'tenant',
    ));
    GetIt.I.registerSingleton<AdminModeRepositoryContract>(
      _FakeAdminModeRepository(AdminMode.user),
    );
    GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(
      _FakeLandlordAuthRepository(hasValidSession: false),
    );

    final guard = LandlordRouteGuard();
    final resolver = MockNavigationResolver();
    final router = RecordingStackRouter();

    guard.onNavigation(resolver, router);

    verify(resolver.next(true)).called(1);
    expect(router.replaceAllCalled, isFalse);
  });
}

void _registerAppData(AppData appData) {
  if (GetIt.I.isRegistered<AppData>()) {
    GetIt.I.unregister<AppData>();
  }
  GetIt.I.registerSingleton<AppData>(appData);
}

AppData _buildAppData({
  required String hostname,
  required String envType,
}) {
  final platformType = PlatformTypeValue()..parse(AppType.mobile.name);
  return AppData.fromInitialization(
    remoteData: {
      'name': 'Test',
      'type': envType,
      'main_domain': 'https://$hostname',
      'domains': ['https://$hostname'],
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
      'hostname': hostname,
      'href': 'https://$hostname',
      'port': null,
      'device': 'test-device',
    },
  );
}

class MockNavigationResolver extends Mock implements NavigationResolver {}

class RecordingStackRouter extends Mock implements StackRouter {
  bool replaceAllCalled = false;
  List<PageRouteInfo>? lastRoutes;

  @override
  Future<void> replaceAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
    bool updateExistingRoutes = true,
  }) async {
    replaceAllCalled = true;
    lastRoutes = routes;
  }
}

class _FakeAdminModeRepository implements AdminModeRepositoryContract {
  _FakeAdminModeRepository(this._mode);

  final AdminMode _mode;

  @override
  StreamValue<AdminMode> get modeStreamValue =>
      StreamValue<AdminMode>(defaultValue: _mode);

  @override
  AdminMode get mode => _mode;

  @override
  bool get isLandlordMode => _mode == AdminMode.landlord;

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
  String get token => hasValidSession ? 'token' : '';

  @override
  Future<void> init() async {}

  @override
  Future<void> loginWithEmailPassword(String email, String password) async {}

  @override
  Future<void> logout() async {}
}
