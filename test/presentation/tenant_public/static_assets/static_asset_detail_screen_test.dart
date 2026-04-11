import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/static_assets/public_static_asset_model.dart';
import 'package:belluga_now/domain/static_assets/value_objects/public_static_asset_fields.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/presentation/tenant_public/static_assets/controllers/static_asset_detail_controller.dart';
import 'package:belluga_now/presentation/tenant_public/static_assets/static_asset_detail_screen.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  testWidgets(
      'static asset detail is share-only and renders Sobre + Como Chegar',
      (tester) async {
    final asset = PublicStaticAssetModel(
      idValue: PublicStaticAssetIdValue(defaultValue: 'asset-1'),
      profileTypeValue: PublicStaticAssetTypeValue(defaultValue: 'beach'),
      displayNameValue:
          PublicStaticAssetNameValue(defaultValue: 'Praia das Virtudes'),
      slugValue: SlugValue()..parse('praia-das-virtudes'),
      contentValue: PublicStaticAssetDescriptionValue(
        defaultValue: '<p>Quiosques, píer e acesso fácil.</p>',
        isRequired: false,
      ),
      locationLatitudeValue: LatitudeValue(isRequired: false)
        ..parse('-20.6701'),
      locationLongitudeValue: LongitudeValue(isRequired: false)
        ..parse('-40.5001'),
    );
    final controller = StaticAssetDetailController(
      appData: _buildAppData(),
    );
    final router = _RecordingStackRouter();

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: router,
        child: StaticAssetDetailScreen(
          asset: asset,
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('immersiveShareAction')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('immersiveTabLabel_0'))).data,
      'Sobre',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('immersiveTabLabel_1'))).data,
      'Como Chegar',
    );
    expect(find.text('Quiosques, píer e acesso fácil.'), findsOneWidget);
  });

  testWidgets(
      'static asset detail visible back falls back to discovery when no history exists',
      (tester) async {
    final controller = StaticAssetDetailController(
      appData: _buildAppData(),
    );
    final router = _RecordingStackRouter()..canPopResult = false;

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: router,
        child: StaticAssetDetailScreen(
          asset: _buildStaticAsset(),
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back).first);
    await tester.pumpAndSettle();

    expect(router.canPopCallCount, 1);
    expect(router.popCallCount, 0);
    expect(router.replaceAllRoutes, hasLength(1));
    expect(
      router.replaceAllRoutes.single.single.routeName,
      DiscoveryRoute.name,
    );
  });

  testWidgets(
      'static asset detail system back falls back to discovery when no history exists',
      (tester) async {
    final controller = StaticAssetDetailController(
      appData: _buildAppData(),
    );
    final router = _RecordingStackRouter()..canPopResult = false;

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: router,
        child: StaticAssetDetailScreen(
          asset: _buildStaticAsset(),
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final popScope = tester.widget<PopScope<dynamic>>(
      find.byWidgetPredicate((widget) => widget is PopScope),
    );
    popScope.onPopInvokedWithResult?.call(false, null);
    await tester.pumpAndSettle();

    expect(router.canPopCallCount, 1);
    expect(router.popCallCount, 0);
    expect(router.replaceAllRoutes, hasLength(1));
    expect(
      router.replaceAllRoutes.single.single.routeName,
      DiscoveryRoute.name,
    );
  });

  testWidgets(
      'static asset detail visible back pops when previous history exists',
      (tester) async {
    final controller = StaticAssetDetailController(
      appData: _buildAppData(),
    );
    final router = _RecordingStackRouter()..canPopResult = true;

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: router,
        child: StaticAssetDetailScreen(
          asset: _buildStaticAsset(),
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back).first);
    await tester.pumpAndSettle();

    expect(router.canPopCallCount, 1);
    expect(router.popCallCount, 1);
    expect(router.replaceAllRoutes, isEmpty);
  });
}

AppData _buildAppData() {
  const remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'main_domain': 'https://tenant.test',
    'profile_types': [
      {
        'type': 'artist',
        'label': 'Artist',
        'allowed_taxonomies': [],
        'capabilities': {
          'is_favoritable': true,
          'is_poi_enabled': true,
        },
      },
    ],
    'domains': ['https://tenant.test'],
    'app_domains': [],
    'theme_data_settings': {
      'brightness_default': 'light',
      'primary_seed_color': '#FFFFFF',
      'secondary_seed_color': '#000000',
    },
    'main_color': '#FFFFFF',
    'tenant_id': 'tenant-1',
    'telemetry': {'trackers': []},
    'telemetry_context': {'location_freshness_minutes': 5},
    'settings': {
      'map_ui': {
        'distance_bounds': {
          'min_meters': 1000,
          'default_meters': 15000,
          'max_meters': 50000,
        },
        'default_origin': {
          'lat': -20.0,
          'lng': -40.0,
          'label': 'Centro',
        },
        'filters': <Map<String, dynamic>>[],
      },
    },
    'firebase': null,
    'push': null,
  };
  const localInfo = {
    'platformType': 'mobile',
    'hostname': 'tenant.test',
    'href': 'https://tenant.test',
    'port': null,
    'device': 'test-device',
  };

  return buildAppDataFromInitialization(
    remoteData: remoteData,
    localInfo: localInfo,
  );
}

PublicStaticAssetModel _buildStaticAsset() {
  return PublicStaticAssetModel(
    idValue: PublicStaticAssetIdValue(defaultValue: 'asset-1'),
    profileTypeValue: PublicStaticAssetTypeValue(defaultValue: 'beach'),
    displayNameValue:
        PublicStaticAssetNameValue(defaultValue: 'Praia das Virtudes'),
    slugValue: SlugValue()..parse('praia-das-virtudes'),
    contentValue: PublicStaticAssetDescriptionValue(
      defaultValue: '<p>Quiosques, píer e acesso fácil.</p>',
      isRequired: false,
    ),
    locationLatitudeValue: LatitudeValue(isRequired: false)..parse('-20.6701'),
    locationLongitudeValue: LongitudeValue(isRequired: false)
      ..parse('-40.5001'),
  );
}

Widget _buildRoutedTestApp({
  required _RecordingStackRouter router,
  required Widget child,
}) {
  final routeData = RouteData(
    route: _FakeRouteMatch(fullPath: '/static/asset-ref'),
    router: router,
    stackKey: const ValueKey<String>('stack'),
    pendingChildren: const [],
    type: const RouteType.material(),
  );

  return StackRouterScope(
    controller: router,
    stateHash: 0,
    child: MaterialApp(
      home: RouteDataScope(
        routeData: routeData,
        child: child,
      ),
    ),
  );
}

class _RecordingStackRouter extends Fake implements StackRouter {
  bool canPopResult = false;
  int canPopCallCount = 0;
  int popCallCount = 0;
  final List<List<PageRouteInfo<dynamic>>> replaceAllRoutes =
      <List<PageRouteInfo<dynamic>>>[];

  @override
  RootStackRouter get root => _FakeRootStackRouter('/static/praia-das-virtudes');

  @override
  bool canPop({
    bool ignoreChildRoutes = false,
    bool ignoreParentRoutes = false,
    bool ignorePagelessRoutes = false,
  }) {
    canPopCallCount += 1;
    return canPopResult;
  }

  @override
  void pop<T extends Object?>([T? result]) {
    popCallCount += 1;
  }

  @override
  Future<void> replaceAll(
    List<PageRouteInfo<dynamic>> routes, {
    OnNavigationFailure? onFailure,
    bool updateExistingRoutes = true,
  }) async {
    replaceAllRoutes.add(routes);
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

class _FakeRouteMatch extends Fake implements RouteMatch {
  _FakeRouteMatch({
    required this.fullPath,
    String? name,
    Map<String, dynamic>? meta,
    PageRouteInfo<dynamic>? pageRouteInfo,
  })  : name = name ?? StaticAssetDetailRoute.name,
        meta = meta ??
            canonicalRouteMeta(
              family: CanonicalRouteFamily.staticAssetDetail,
            ),
        pageRouteInfo = pageRouteInfo ?? const DiscoveryRoute();

  @override
  final String name;

  @override
  final String fullPath;

  @override
  final Map<String, dynamic> meta;

  final PageRouteInfo<dynamic> pageRouteInfo;

  @override
  PageRouteInfo<dynamic> toPageRouteInfo() => pageRouteInfo;
}
