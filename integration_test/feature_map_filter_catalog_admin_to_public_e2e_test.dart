import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_mode.dart';
import 'package:belluga_now/domain/map/queries/poi_query.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/user/user_belluga.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/auth_backend/auth_backend.dart';
import 'package:belluga_now/infrastructure/repositories/city_map_repository.dart';
import 'package:belluga_now/infrastructure/repositories/landlord_auth_repository.dart';
import 'package:belluga_now/infrastructure/repositories/landlord_tenants_repository.dart';
import 'package:belluga_now/infrastructure/repositories/poi_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_selected_tenant_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_settings_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_static_assets_repository.dart';
import 'package:belluga_now/infrastructure/services/http/laravel_map_poi_http_service.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/tenant_admin_settings_keys.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_settings_local_preferences_section.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/fab_menu_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/fab_menu.dart';
import 'package:dio/dio.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:get_it/get_it.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stream_value/core/stream_value.dart';

import 'support/integration_test_bootstrap.dart';

void main() {
  developer.postEvent(
    'seed_vm_golden_stream',
    const <String, Object>{},
    stream: 'integration_test.VmServiceProxyGoldenFileComparator',
  );
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

  const adminEmailDefine = String.fromEnvironment(
    'LANDLORD_ADMIN_EMAIL',
    defaultValue: 'admin@bellugasolutions.com.br',
  );
  const adminPasswordDefine = String.fromEnvironment(
    'LANDLORD_ADMIN_PASSWORD',
    defaultValue: '765432e1',
  );
  const tenantDomainDefine = String.fromEnvironment(
    'TENANT_ADMIN_TEST_DOMAIN',
    defaultValue: 'guarappari.belluga.space',
  );

  final originalGeolocator = GeolocatorPlatform.instance;

  setUpAll(() {
    GeolocatorPlatform.instance = _TestGeolocatorPlatform();
  });

  tearDownAll(() {
    GeolocatorPlatform.instance = originalGeolocator;
  });

  testWidgets(
    'admin-configured asset filter image propagates to settings preview and public map',
    (tester) async {
      await GetIt.I.reset(dispose: true);

      final adminEmail =
          requireDefine('LANDLORD_ADMIN_EMAIL', adminEmailDefine);
      final adminPassword = requireDefine(
        'LANDLORD_ADMIN_PASSWORD',
        adminPasswordDefine,
      );
      final expectedTenantHost = normalizeHost(tenantDomainDefine);
      final tenantOrigin = requireOriginUri(tenantDomainDefine);
      final landlordOrigin = deriveLandlordOriginFromTenantHost(
        expectedTenantHost,
      );

      final uniqueSeed = DateTime.now().microsecondsSinceEpoch.toString();
      final assetType = 'it_asset_$uniqueSeed';
      final assetFilterKey = 'asset_filter_$uniqueSeed';
      final assetFilterLabel = 'Praia automatizada';
      final eventFilterKey = 'event_filter_$uniqueSeed';
      final eventFilterLabel = 'Eventos em destaque';
      final assetDisplayName = 'Praia Automatizada $uniqueSeed';

      final adminAuthRepository = LandlordAuthRepository(
        dio: Dio(
          BaseOptions(
            baseUrl: '$landlordOrigin/admin/api',
          ),
        ),
      );
      GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(
        adminAuthRepository,
      );

      final tenantScopeRepository = TenantAdminSelectedTenantRepository();
      final settingsRepository = TenantAdminSettingsRepository(
        tenantScope: tenantScopeRepository,
      );
      final staticAssetsRepository = TenantAdminStaticAssetsRepository(
        tenantScope: tenantScopeRepository,
      );
      final appDataRepository = _FakeAppDataRepository(
        _buildAppData(mainDomain: tenantOrigin.toString()),
      );
      final settingsController = TenantAdminSettingsController(
        appDataRepository: appDataRepository,
        settingsRepository: settingsRepository,
        tenantScope: tenantScopeRepository,
        locationSelectionService: TenantAdminLocationSelectionService(),
        imageIngestionService: TenantAdminImageIngestionService(),
      );

      TenantAdminMapUiSettings? originalMapUiSettings;
      String? createdStaticAssetId;
      var createdStaticProfileType = false;
      MapScreenController? mapController;
      FabMenuController? fabMenuController;
      PoiRepository? poiRepository;

      try {
        await adminAuthRepository.init();
        await adminAuthRepository.loginWithEmailPassword(
            adminEmail, adminPassword);
        expect(adminAuthRepository.hasValidSession, isTrue);

        final tenantsRepository = LandlordTenantsRepository(
          landlordAuthRepository: adminAuthRepository,
          landlordOriginOverride: landlordOrigin,
        );
        final tenants = await tenantsRepository.fetchTenants();
        expect(tenants, isNotEmpty);

        final tenantOption = resolveTenantByDomain(tenants, expectedTenantHost);
        tenantScopeRepository.setAvailableTenants(tenants);
        tenantScopeRepository.selectTenant(tenantOption);

        originalMapUiSettings = await settingsRepository.fetchMapUiSettings();

        await staticAssetsRepository.createStaticProfileType(
          type: assetType,
          label: 'IT Asset Type $uniqueSeed',
          capabilities: const TenantAdminStaticProfileTypeCapabilities(
            isPoiEnabled: true,
            hasBio: false,
            hasTaxonomies: false,
            hasAvatar: true,
            hasCover: true,
            hasContent: false,
          ),
        );
        createdStaticProfileType = true;

        final createdAsset = await staticAssetsRepository.createStaticAsset(
          profileType: assetType,
          displayName: assetDisplayName,
          location: const TenantAdminLocation(
            latitude: -20.611121,
            longitude: -40.498617,
          ),
        );
        createdStaticAssetId = createdAsset.id;

        await settingsController.loadMapUiSettings();
        settingsController.addMapFilterItem();
        settingsController.updateMapFilterItemKey(0, assetFilterKey);
        settingsController.updateMapFilterItemLabel(0, assetFilterLabel);
        settingsController.updateMapFilterItemRule(
          0,
          TenantAdminMapFilterQuery(
            source: TenantAdminMapFilterSource.staticAsset,
            types: [assetType],
          ),
        );
        settingsController.addMapFilterItem();
        settingsController.updateMapFilterItemKey(1, eventFilterKey);
        settingsController.updateMapFilterItemLabel(1, eventFilterLabel);
        settingsController.updateMapFilterItemRule(
          1,
          TenantAdminMapFilterQuery(
            source: TenantAdminMapFilterSource.event,
          ),
        );
        await settingsController.saveMapFilters();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TenantAdminSettingsLocalPreferencesSection(
                  controller: settingsController,
                  onOpenDefaultOriginPicker: () async {},
                  onAddMapFilter: settingsController.addMapFilterItem,
                  onEditMapFilterKey: (_) async {},
                  onEditMapFilterLabel: (_) async {},
                  onEditMapFilterRule: (_) async {},
                  onEditMapFilterImage: (_) async {},
                  onRemoveMapFilter: settingsController.removeMapFilterItem,
                  onMoveMapFilterUp: settingsController.moveMapFilterItemUp,
                  onMoveMapFilterDown: settingsController.moveMapFilterItemDown,
                  onClearMapFilterImage:
                      settingsController.clearMapFilterItemImage,
                  isMapFilterImageBusy: (_) => false,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(TenantAdminSettingsKeys.localPreferencesMapFilterRow(0)),
          findsOneWidget,
        );
        expect(
          find.byKey(TenantAdminSettingsKeys.localPreferencesMapFilterRow(1)),
          findsOneWidget,
        );
        expect(find.text(assetFilterLabel), findsOneWidget);
        expect(find.text(eventFilterLabel), findsOneWidget);

        final firstUpload = _buildImageFile(
          name: 'map_filter_first.png',
          color: img.ColorRgb8(120, 45, 180),
        );
        await settingsController.uploadMapFilterItemImage(
          index: 0,
          file: firstUpload,
        );
        await tester.pumpAndSettle();

        final firstImageUri = settingsController
            .mapUiSettingsStreamValue.value.filters.first.imageUri;
        expect(firstImageUri, isNotNull);
        expect(
          firstImageUri,
          contains('/api/v1/media/map-filters/$assetFilterKey'),
        );
        final firstImageBytes = await fetchImageBytes(firstImageUri!);

        final previewFinder = find.descendant(
          of: find
              .byKey(TenantAdminSettingsKeys.localPreferencesMapFilterRow(0)),
          matching: find.byType(Image),
        );
        expect(previewFinder, findsOneWidget);
        final firstPreviewImage = tester.widget<Image>(previewFinder.first);
        expect((firstPreviewImage.image as NetworkImage).url, firstImageUri);

        final secondUpload = _buildImageFile(
          name: 'map_filter_second.png',
          color: img.ColorRgb8(20, 140, 220),
        );
        await settingsController.uploadMapFilterItemImage(
          index: 0,
          file: secondUpload,
        );
        await tester.pumpAndSettle();

        final secondImageUri = settingsController
            .mapUiSettingsStreamValue.value.filters.first.imageUri;
        expect(secondImageUri, isNotNull);
        expect(secondImageUri, isNot(equals(firstImageUri)));
        final secondImageBytes = await fetchImageBytes(secondImageUri!);
        expect(secondImageBytes, isNot(equals(firstImageBytes)));

        final secondPreviewImage = tester.widget<Image>(previewFinder.first);
        expect((secondPreviewImage.image as NetworkImage).url, secondImageUri);

        await settingsController.saveMapFilters();
        final persistedSettings = await waitForMapUiSettings(
          repository: settingsRepository,
          predicate: (settings) {
            if (settings.filters.length < 2) {
              return false;
            }
            final assetFilter = settings.filters.firstWhere(
              (item) => item.key == assetFilterKey,
              orElse: () => TenantAdminMapFilterCatalogItem(
                key: '',
                label: '',
              ),
            );
            final eventFilter = settings.filters.firstWhere(
              (item) => item.key == eventFilterKey,
              orElse: () => TenantAdminMapFilterCatalogItem(
                key: '',
                label: '',
              ),
            );
            return assetFilter.imageUri == secondImageUri &&
                assetFilter.label == assetFilterLabel &&
                eventFilter.label == eventFilterLabel;
          },
          expectationLabel: 'persisted map filter catalog',
        );
        expect(
          persistedSettings.filters
              .firstWhere((item) => item.key == assetFilterKey)
              .imageUri,
          secondImageUri,
        );

        final publicToken = await registerPublicUser(
          tenantOrigin: tenantOrigin,
          seed: uniqueSeed,
        );
        GetIt.I.registerSingleton<AuthRepositoryContract>(
          _StubAuthRepository(publicToken),
        );

        final backendContext = BackendContext(
          baseUrl: tenantOrigin.resolve('/api').toString(),
          adminUrl: tenantOrigin.resolve('/admin/api').toString(),
        );
        poiRepository = PoiRepository(
          dataSource: CityMapRepository(
            laravelHttpService: LaravelMapPoiHttpService(
              context: backendContext,
            ),
          ),
        );
        mapController = MapScreenController(
          poiRepository: poiRepository,
          userLocationRepository: _StaticUserLocationRepository(
            latitude: -20.611121,
            longitude: -40.498617,
          ),
          telemetryRepository: _NoopTelemetryRepository(),
        );
        fabMenuController = FabMenuController(poiRepository: poiRepository)
          ..setExpanded(true)
          ..setCondensed(false);

        final boundsQuery = _buildBoundsQuery(
          northEastLat: -20.601121,
          northEastLng: -40.488617,
          southWestLat: -20.621121,
          southWestLng: -40.508617,
        );

        await waitForCatalogAndPois(
          mapController: mapController,
          query: boundsQuery,
          assetFilterLabel: assetFilterLabel,
          eventFilterLabel: eventFilterLabel,
          assetDisplayName: assetDisplayName,
        );
        final publicAssetFilter = mapController
            .filterOptionsStreamValue.value!.sortedCategories
            .firstWhere((category) => category.label == assetFilterLabel);
        expect(publicAssetFilter.imageUri, secondImageUri);
        final publicImageBytes =
            await fetchImageBytes(publicAssetFilter.imageUri!);
        expect(publicImageBytes, equals(secondImageBytes));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FabMenu(
                onNavigateToUser: () {},
                mapController: mapController,
                controller: fabMenuController,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text(assetFilterLabel), findsOneWidget);
        expect(find.text(eventFilterLabel), findsOneWidget);
        expect(find.text(assetFilterKey), findsNothing);

        Finder findAssetFab() {
          return find.byWidgetPredicate(
            (widget) {
              if (widget is! FloatingActionButton) {
                return false;
              }
              final heroTag = widget.heroTag;
              return heroTag is String &&
                  heroTag.endsWith('category-filter-$assetFilterKey');
            },
            description:
                'FloatingActionButton for category-filter-$assetFilterKey',
          );
        }

        final assetFabFinder = findAssetFab();
        expect(assetFabFinder, findsOneWidget);

        final initialAssetFab =
            tester.widget<FloatingActionButton>(assetFabFinder.first);
        final initialBackground = initialAssetFab.backgroundColor;

        final assetImageFinder = find.descendant(
          of: assetFabFinder.first,
          matching: find.byType(Image),
        );
        expect(assetImageFinder, findsOneWidget);
        final fabImageWidget = tester.widget<Image>(assetImageFinder.first);
        expect((fabImageWidget.image as NetworkImage).url, secondImageUri);

        await tester.tap(assetFabFinder.first);
        await tester.pump();
        await waitForFilterApplication(
          tester,
          mapController: mapController,
          assetFilterLabel: assetFilterLabel,
          assetDisplayName: assetDisplayName,
        );

        final selectedAssetFabFinder = findAssetFab();
        expect(selectedAssetFabFinder, findsOneWidget);
        final selectedAssetFab =
            tester.widget<FloatingActionButton>(selectedAssetFabFinder.first);
        expect(
          selectedAssetFab.backgroundColor,
          isNot(equals(initialBackground)),
        );
        expect(mapController.filterModeStreamValue.value, PoiFilterMode.server);
        expect(
          (mapController.filteredPoisStreamValue.value ?? const <CityPoiModel>[])
              .map((poi) => poi.name)
              .toList(growable: false),
          equals(<String>[assetDisplayName]),
        );
      } finally {
        fabMenuController?.dispose();
        if (mapController != null) {
          await mapController.onDispose();
        }
        settingsController.onDispose();

        if (originalMapUiSettings != null) {
          try {
            await settingsRepository.updateMapUiSettings(
              settings: originalMapUiSettings,
            );
          } catch (_) {}
        }

        if (createdStaticAssetId != null) {
          try {
            await staticAssetsRepository
                .deleteStaticAsset(createdStaticAssetId);
          } catch (_) {}
          try {
            await staticAssetsRepository.forceDeleteStaticAsset(
              createdStaticAssetId,
            );
          } catch (_) {}
        }

        if (createdStaticProfileType) {
          try {
            await staticAssetsRepository.deleteStaticProfileType(assetType);
          } catch (_) {}
        }

        try {
          await adminAuthRepository.logout();
        } catch (_) {}
        await GetIt.I.reset(dispose: true);
      }
    },
  );
}

String requireDefine(String key, String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    fail('Missing --dart-define=$key for integration test execution.');
  }
  return normalized;
}

Uri requireOriginUri(String raw) {
  final trimmed = raw.trim();
  final uri =
      Uri.tryParse(trimmed.contains('://') ? trimmed : 'https://$trimmed');
  if (uri == null || uri.host.trim().isEmpty) {
    fail('Invalid origin/domain value: "$raw"');
  }
  return Uri(
    scheme: uri.scheme.isEmpty ? 'https' : uri.scheme,
    host: uri.host.trim().toLowerCase(),
    port: uri.hasPort ? uri.port : null,
  );
}

String normalizeHost(String raw) => requireOriginUri(raw).host;

String deriveLandlordOriginFromTenantHost(String tenantHost) {
  final labels = tenantHost.trim().toLowerCase().split('.');
  if (labels.length < 2) {
    fail('Invalid tenant host for landlord derivation: "$tenantHost"');
  }
  final landlordHost =
      labels.length >= 3 ? labels.sublist(1).join('.') : labels.join('.');
  return 'https://$landlordHost';
}

LandlordTenantOption resolveTenantByDomain(
  List<LandlordTenantOption> tenants,
  String expectedHost,
) {
  for (final tenant in tenants) {
    if (normalizeHost(tenant.mainDomain) == expectedHost) {
      return tenant;
    }
  }
  fail(
    'Tenant "$expectedHost" not found in landlord listing. '
    'Available: ${tenants.map((tenant) => tenant.mainDomain).join(', ')}',
  );
}

Future<TenantAdminMapUiSettings> waitForMapUiSettings({
  required TenantAdminSettingsRepository repository,
  required bool Function(TenantAdminMapUiSettings value) predicate,
  required String expectationLabel,
  Duration timeout = const Duration(seconds: 40),
  Duration step = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  TenantAdminMapUiSettings? lastRead;

  while (DateTime.now().isBefore(deadline)) {
    final current = await repository.fetchMapUiSettings();
    lastRead = current;
    if (predicate(current)) {
      return current;
    }
    await Future<void>.delayed(step);
  }

  throw TestFailure(
    'Timed out waiting for $expectationLabel. '
    'Last read: ${lastRead?.rawMapUi}',
  );
}

Future<List<int>> fetchImageBytes(String imageUri) async {
  final response = await Dio().get<List<int>>(
    imageUri,
    options: Options(
      responseType: ResponseType.bytes,
      headers: const {
        'Accept': 'image/*,*/*;q=0.8',
      },
    ),
  );

  expect(response.statusCode, 200);
  final contentType =
      response.headers.value(Headers.contentTypeHeader)?.trim() ?? '';
  expect(
    contentType.startsWith('image/'),
    isTrue,
    reason: 'Expected image content for $imageUri, got "$contentType".',
  );

  final bytes = response.data;
  expect(bytes, isNotNull);
  expect(bytes, isNotEmpty);
  final decoded = img.decodeImage(Uint8List.fromList(bytes!));
  expect(decoded, isNotNull, reason: 'Image bytes for $imageUri are invalid.');

  return bytes;
}

Future<String> registerPublicUser({
  required Uri tenantOrigin,
  required String seed,
}) async {
  final authBackend = LaravelAuthBackend(
    context: BackendContext(
      baseUrl: tenantOrigin.resolve('/api').toString(),
      adminUrl: tenantOrigin.resolve('/admin/api').toString(),
    ),
  );
  final email = 'map-filter-$seed@belluga.test';
  const password = 'SecurePass!123';

  final registration = await authBackend.registerWithEmailPassword(
    name: 'Map Filter Integration',
    email: email,
    password: password,
  );
  if (registration.token.trim().isNotEmpty) {
    return registration.token.trim();
  }

  final loginResult = await authBackend.loginWithEmailPassword(
    email,
    password,
  );
  return loginResult.$2.trim();
}

PoiQuery _buildBoundsQuery({
  required double northEastLat,
  required double northEastLng,
  required double southWestLat,
  required double southWestLng,
}) {
  return PoiQuery(
    northEast: _buildCoordinate(northEastLat, northEastLng),
    southWest: _buildCoordinate(southWestLat, southWestLng),
  );
}

CityCoordinate _buildCoordinate(double latitude, double longitude) {
  final latitudeValue = LatitudeValue()..parse(latitude.toStringAsFixed(6));
  final longitudeValue = LongitudeValue()..parse(longitude.toStringAsFixed(6));
  return CityCoordinate(
    latitudeValue: latitudeValue,
    longitudeValue: longitudeValue,
  );
}

Future<void> waitForCatalogAndPois({
  required MapScreenController mapController,
  required PoiQuery query,
  required String assetFilterLabel,
  required String eventFilterLabel,
  required String assetDisplayName,
  Duration timeout = const Duration(seconds: 50),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await mapController.loadFilters(force: true);
    await mapController.loadPois(query);

    final options = mapController.filterOptionsStreamValue.value;
    final hasAssetFilter = options?.categories.any(
          (category) => category.label == assetFilterLabel,
        ) ??
        false;
    final hasEventFilter = options?.categories.any(
          (category) => category.label == eventFilterLabel,
        ) ??
        false;
    final hasAssetPoi =
        (mapController.filteredPoisStreamValue.value ?? const <CityPoiModel>[])
            .any(
      (poi) => poi.name == assetDisplayName,
    );

    if (hasAssetFilter && hasEventFilter && hasAssetPoi) {
      return;
    }

    await Future<void>.delayed(const Duration(seconds: 2));
  }

  throw TestFailure(
    'Timed out waiting for public map catalog/poi propagation.',
  );
}

Future<void> waitForFilterApplication(
  WidgetTester tester, {
  required MapScreenController mapController,
  required String assetFilterLabel,
  required String assetDisplayName,
  Duration timeout = const Duration(seconds: 40),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
    final options = mapController.filterOptionsStreamValue.value;
    final assetFilter = options?.categories.firstWhere(
      (category) => category.label == assetFilterLabel,
      orElse: () => throw StateError('Asset filter not found.'),
    );
    if (assetFilter == null) {
      continue;
    }
    final isApplied = mapController.isCategoryFilterActive(assetFilter);
    final pois =
        mapController.filteredPoisStreamValue.value ?? const <CityPoiModel>[];
    if (!mapController.filterInteractionLockedStreamValue.value &&
        isApplied &&
        pois.length == 1 &&
        pois.first.name == assetDisplayName) {
      return;
    }
  }

  throw TestFailure('Timed out waiting for asset filter application.');
}

XFile _buildImageFile({
  required String name,
  required img.ColorRgb8 color,
}) {
  final image = img.Image(width: 256, height: 256);
  img.fill(image, color: color);
  final bytes = img.encodePng(image);
  return XFile.fromData(
    bytes,
    name: name,
    mimeType: 'image/png',
  );
}

AppData _buildAppData({
  required String mainDomain,
}) {
  final origin = requireOriginUri(mainDomain);
  final remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'profile_types': const [],
    'domains': [mainDomain],
    'app_domains': const ['com.guarappari.app'],
    'theme_data_settings': const {
      'brightness_default': 'light',
      'primary_seed_color': '#009688',
      'secondary_seed_color': '#3F51B5',
    },
    'main_color': '#009688',
    'main_domain': mainDomain,
    'tenant_id': 'tenant-1',
    'telemetry': const {
      'trackers': [],
    },
    'telemetry_context': const {'location_freshness_minutes': 5},
    'firebase': const {
      'apiKey': 'apikey',
      'appId': 'appid',
      'projectId': 'project-test',
      'messagingSenderId': 'sender',
      'storageBucket': 'bucket',
    },
    'push': const {
      'enabled': true,
      'types': ['event'],
      'throttles': {'max_per_hour': 20},
    },
  };

  final localInfo = {
    'platformType': PlatformTypeValue()..parse('mobile'),
    'hostname': origin.host,
    'href': origin.toString(),
    'port': origin.hasPort ? origin.port.toString() : null,
    'device': 'integration-test-device',
  };

  return AppData.fromInitialization(
    remoteData: remoteData,
    localInfo: localInfo,
  );
}

class _FakeAppDataRepository implements AppDataRepositoryContract {
  _FakeAppDataRepository(this._appData);

  final AppData _appData;
  final StreamValue<ThemeMode?> _themeModeStreamValue =
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.light);
  final StreamValue<double> _maxRadiusMetersStreamValue =
      StreamValue<double>(defaultValue: 1000);

  @override
  AppData get appData => _appData;

  @override
  Future<void> init() async {}

  @override
  StreamValue<ThemeMode?> get themeModeStreamValue => _themeModeStreamValue;

  @override
  ThemeMode get themeMode => _themeModeStreamValue.value ?? ThemeMode.system;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeModeStreamValue.addValue(mode);
  }

  @override
  StreamValue<double> get maxRadiusMetersStreamValue =>
      _maxRadiusMetersStreamValue;

  @override
  double get maxRadiusMeters => _maxRadiusMetersStreamValue.value;

  @override
  Future<void> setMaxRadiusMeters(double meters) async {
    _maxRadiusMetersStreamValue.addValue(meters);
  }
}

class _StubAuthRepository extends AuthRepositoryContract<UserBelluga> {
  _StubAuthRepository(this._token);

  final String _token;

  @override
  Object get backend => Object();

  @override
  String get userToken => _token;

  @override
  void setUserToken(String? token) {}

  @override
  Future<String> getDeviceId() async => 'integration-device';

  @override
  Future<String?> getUserId() async => 'integration-user';

  @override
  bool get isUserLoggedIn => true;

  @override
  bool get isAuthorized => true;

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

class _StaticUserLocationRepository implements UserLocationRepositoryContract {
  _StaticUserLocationRepository({
    required double latitude,
    required double longitude,
  }) {
    final coordinate = _buildCoordinate(latitude, longitude);
    userLocationStreamValue.addValue(coordinate);
    lastKnownLocationStreamValue.addValue(coordinate);
  }

  @override
  final StreamValue<CityCoordinate?> userLocationStreamValue =
      StreamValue<CityCoordinate?>();

  @override
  final StreamValue<CityCoordinate?> lastKnownLocationStreamValue =
      StreamValue<CityCoordinate?>();

  @override
  final StreamValue<DateTime?> lastKnownCapturedAtStreamValue =
      StreamValue<DateTime?>();

  @override
  final StreamValue<double?> lastKnownAccuracyStreamValue =
      StreamValue<double?>();

  @override
  final StreamValue<String?> lastKnownAddressStreamValue =
      StreamValue<String?>();

  @override
  @override
  final StreamValue<LocationResolutionPhase>
      locationResolutionPhaseStreamValue = StreamValue<LocationResolutionPhase>(
    defaultValue: LocationResolutionPhase.unknown,
  );

  @override
  Future<void> ensureLoaded() async {}

  @override
  Future<bool> refreshIfPermitted({
    Duration minInterval = const Duration(seconds: 30),
  }) async =>
      false;

  @override
  Future<String?> resolveUserLocation() async => null;

  @override
  Future<void> setLastKnownAddress(String? address) async {}

  @override
  Future<bool> startTracking({
    LocationTrackingMode mode = LocationTrackingMode.mapForeground,
  }) async =>
      true;

  @override
  Future<void> stopTracking() async {}

  @override
  Future<bool> warmUpIfPermitted() async => false;
}

class _NoopTelemetryRepository implements TelemetryRepositoryContract {
  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<bool> finishTimedEvent(EventTrackerTimedEventHandle handle) async =>
      true;

  @override
  Future<bool> flushTimedEvents() async => true;

  @override
  Future<bool> logEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async =>
      true;

  @override
  Future<bool> mergeIdentity({required String previousUserId}) async => true;

  @override
  void setScreenContext(Map<String, dynamic>? screenContext) {}

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async =>
      null;
}

class _TestGeolocatorPlatform extends GeolocatorPlatform {
  static final Position _position = Position(
    latitude: -20.611121,
    longitude: -40.498617,
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
    accuracy: 5.0,
    altitude: 1.0,
    altitudeAccuracy: 1.0,
    heading: 0.0,
    headingAccuracy: 1.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async =>
      _position;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async =>
      _position;

  @override
  Stream<ServiceStatus> getServiceStatusStream() =>
      Stream.value(ServiceStatus.enabled);

  @override
  Stream<Position> getPositionStream({
    LocationSettings? locationSettings,
  }) {
    return Stream<Position>.value(_position);
  }

  @override
  Future<LocationAccuracyStatus> requestTemporaryFullAccuracy({
    required String purposeKey,
  }) async =>
      LocationAccuracyStatus.precise;

  @override
  Future<LocationAccuracyStatus> getLocationAccuracy() async =>
      LocationAccuracyStatus.precise;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;
}
