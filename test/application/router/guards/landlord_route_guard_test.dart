import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/guards/landlord_route_guard.dart';
import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('blocks navigation on tenant host even with landlord mode/session', () {
    _registerAppData(_buildAppData(
      hostname: 'tenant.test',
      envType: 'tenant',
    ));

    final guard = LandlordRouteGuard();
    final resolver = MockNavigationResolver();
    final router = RecordingStackRouter();

    guard.onNavigation(resolver, router);

    verify(resolver.next(false)).called(1);
    verifyNever(resolver.next(true));
    expect(router.replaceAllCalled, isTrue);
  });

  test('blocks navigation on tenant host', () {
    _registerAppData(_buildAppData(
      hostname: 'tenant.test',
      envType: 'tenant',
    ));

    final guard = LandlordRouteGuard();
    final resolver = MockNavigationResolver();
    final router = RecordingStackRouter();

    guard.onNavigation(resolver, router);

    verify(resolver.next(false)).called(1);
    verifyNever(resolver.next(true));
    expect(router.replaceAllCalled, isTrue);
  });

  test('host-based allow requires configured landlord domain', () {
    final landlordHost = _landlordHostForTest();
    _registerAppData(_buildAppData(
      hostname: landlordHost,
      envType: 'tenant',
    ));

    final guard = LandlordRouteGuard();
    final resolver = MockNavigationResolver();
    final router = RecordingStackRouter();

    guard.onNavigation(resolver, router);

    if (BellugaConstants.landlordDomain.trim().isEmpty) {
      verify(resolver.next(false)).called(1);
      verifyNever(resolver.next(true));
      expect(router.replaceAllCalled, isTrue);
      return;
    }

    verify(resolver.next(true)).called(1);
    verifyNever(resolver.next(false));
    expect(router.replaceAllCalled, isFalse);
  });

  test('allows navigation in landlord environment regardless of host', () {
    _registerAppData(_buildAppData(
      hostname: 'tenant.test',
      envType: 'landlord',
    ));

    final guard = LandlordRouteGuard();
    final resolver = MockNavigationResolver();
    final router = RecordingStackRouter();

    guard.onNavigation(resolver, router);

    verify(resolver.next(true)).called(1);
    verifyNever(resolver.next(false));
    expect(router.replaceAllCalled, isFalse);
  });

  test('allows tenant admin route on tenant host', () {
    _registerAppData(_buildAppData(
      hostname: 'tenant.test',
      envType: 'tenant',
    ));

    final guard = LandlordRouteGuard();
    final resolver = MockNavigationResolver();
    resolver.routeValue = _FakeRouteMatch(name: TenantAdminShellRoute.name);
    final router = RecordingStackRouter();

    guard.onNavigation(resolver, router);

    verify(resolver.next(true)).called(1);
    verifyNever(resolver.next(false));
    expect(router.replaceAllCalled, isFalse);
  });
}

String _landlordHostForTest() {
  final configured = BellugaConstants.landlordDomain.trim();
  final parsed = Uri.tryParse(configured);
  if (parsed != null && parsed.host.trim().isNotEmpty) {
    return parsed.host.trim();
  }
  if (configured.isNotEmpty && !configured.contains('://')) {
    return configured;
  }
  return 'belluga.app';
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

class MockNavigationResolver extends Mock implements NavigationResolver {
  RouteMatch _route = _FakeRouteMatch(name: '');

  set routeValue(RouteMatch value) {
    _route = value;
  }

  @override
  RouteMatch get route => _route;
}

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

class _FakeRouteMatch extends Fake implements RouteMatch {
  _FakeRouteMatch({required this.name});

  @override
  final String name;
}
