import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_mode.dart';
import 'package:belluga_now/domain/map/queries/poi_query.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_static_assets_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/landlord_auth_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_discovery_filters_settings_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
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
import 'package:belluga_now/infrastructure/services/location_origin_service.dart';
import 'package:belluga_now/infrastructure/services/http/laravel_map_poi_http_service.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/controllers/tenant_admin_discovery_filters_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_query.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_surface_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/screens/tenant_admin_discovery_filter_surface_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/tenant_admin_discovery_filters_keys.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/map_adaptive_tray.dart';
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

import 'package:belluga_now/testing/app_data_test_factory.dart';

import 'support/integration_test_bootstrap.dart';

TenantAdminLowercaseTokenValue _tokenValue(String raw) {
  final value = TenantAdminLowercaseTokenValue();
  value.parse(raw);
  return value;
}

TenantAdminOptionalUrlValue _optionalUrlValue(String raw) {
  final value = TenantAdminOptionalUrlValue();
  value.parse(raw);
  return value;
}

void main() {
  developer.postEvent(
    'seed_vm_golden_stream',
    <String, Object>{},
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
      final discoveryFiltersController = TenantAdminDiscoveryFiltersController(
        settingsRepository: settingsRepository,
      );

      TenantAdminDiscoveryFiltersSettingsValue? originalDiscoveryFilters;
      String? createdStaticAssetId;
      var createdStaticProfileType = false;
      MapScreenController? mapController;
      PoiRepository? poiRepository;

      try {
        await adminAuthRepository.init();
        await adminAuthRepository.loginWithEmailPassword(
          landlordAuthRepoString(adminEmail),
          landlordAuthRepoString(adminPassword),
        );
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

        originalDiscoveryFilters =
            await settingsRepository.fetchDiscoveryFiltersSettings();

        await staticAssetsRepository.createStaticProfileType(
          type: TenantAdminStaticAssetsRepoString.fromRaw(assetType),
          label: TenantAdminStaticAssetsRepoString.fromRaw(
            'IT Asset Type $uniqueSeed',
          ),
          capabilities: TenantAdminStaticProfileTypeCapabilities(
            isPoiEnabled: TenantAdminFlagValue(true),
            hasBio: TenantAdminFlagValue(false),
            hasTaxonomies: TenantAdminFlagValue(false),
            hasAvatar: TenantAdminFlagValue(true),
            hasCover: TenantAdminFlagValue(true),
            hasContent: TenantAdminFlagValue(false),
          ),
        );
        createdStaticProfileType = true;

        final createdAsset = await staticAssetsRepository.createStaticAsset(
          profileType: TenantAdminStaticAssetsRepoString.fromRaw(assetType),
          displayName: TenantAdminStaticAssetsRepoString.fromRaw(
            assetDisplayName,
          ),
          location: tenantAdminLocationFromRaw(
            latitude: -20.611121,
            longitude: -40.498617,
          ),
        );
        createdStaticAssetId = createdAsset.id;

        const mapSurface = TenantAdminDiscoveryFilterSurfaceDefinition.map;
        await discoveryFiltersController.init();
        discoveryFiltersController.addFilterItem(mapSurface);
        discoveryFiltersController.updateFilterKey(
          mapSurface,
          0,
          assetFilterKey,
        );
        discoveryFiltersController.updateFilterLabel(
          mapSurface,
          0,
          assetFilterLabel,
        );
        discoveryFiltersController.updateFilterRule(
          mapSurface,
          0,
          discoveryFiltersController
              .filtersForSurface(mapSurface)
              .elementAt(0)
              .copyWith(
                query: TenantAdminDiscoveryFilterQuery(
                  entityValues: [_tokenValue('static_asset')],
                  typeValuesByEntity: {
                    'static_asset': [_tokenValue(assetType)],
                  },
                ),
              ),
        );
        discoveryFiltersController.addFilterItem(mapSurface);
        discoveryFiltersController.updateFilterKey(
          mapSurface,
          1,
          eventFilterKey,
        );
        discoveryFiltersController.updateFilterLabel(
          mapSurface,
          1,
          eventFilterLabel,
        );
        discoveryFiltersController.updateFilterRule(
          mapSurface,
          1,
          discoveryFiltersController
              .filtersForSurface(mapSurface)
              .elementAt(1)
              .copyWith(
                query: TenantAdminDiscoveryFilterQuery(
                  entityValues: [_tokenValue('event')],
                ),
              ),
        );

        final imageIngestionService = TenantAdminImageIngestionService();

        final firstUpload = await _buildMapFilterUpload(
          imageIngestionService: imageIngestionService,
          file: _buildImageFile(
            name: 'map_filter_first.png',
            color: img.ColorRgb8(120, 45, 180),
          ),
        );
        final firstImageUri = await settingsRepository.uploadMapFilterImage(
          key: _tokenValue(assetFilterKey),
          upload: firstUpload,
        );

        expect(
          firstImageUri,
          contains('/api/v1/media/map-filters/$assetFilterKey'),
        );
        final firstImageBytes = await fetchImageBytes(firstImageUri);

        discoveryFiltersController.updateFilterVisual(
          mapSurface,
          0,
          discoveryFiltersController
              .filtersForSurface(mapSurface)
              .elementAt(0)
              .copyWith(imageUriValue: _optionalUrlValue(firstImageUri)),
        );

        final secondUpload = await _buildMapFilterUpload(
          imageIngestionService: imageIngestionService,
          file: _buildImageFile(
            name: 'map_filter_second.png',
            color: img.ColorRgb8(20, 140, 220),
          ),
        );
        final secondImageUri = await settingsRepository.uploadMapFilterImage(
          key: _tokenValue(assetFilterKey),
          upload: secondUpload,
        );
        expect(secondImageUri, isNot(equals(firstImageUri)));
        final secondImageBytes = await fetchImageBytes(secondImageUri);
        expect(secondImageBytes, isNot(equals(firstImageBytes)));

        discoveryFiltersController.updateFilterVisual(
          mapSurface,
          0,
          discoveryFiltersController
              .filtersForSurface(mapSurface)
              .elementAt(0)
              .copyWith(imageUriValue: _optionalUrlValue(secondImageUri)),
        );
        await discoveryFiltersController.saveFilters(mapSurface);
        expect(discoveryFiltersController.remoteErrorStreamValue.value, '');
        expect(
          discoveryFiltersController
              .filtersForSurface(mapSurface)
              .elementAt(0)
              .imageUri,
          secondImageUri,
        );

        GetIt.I.registerSingleton<TenantAdminDiscoveryFiltersController>(
          discoveryFiltersController,
        );
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TenantAdminDiscoveryFilterSurfaceScreen(
                surface: mapSurface,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(
            TenantAdminDiscoveryFiltersKeys.filterRow(
              'public_map.primary',
              0,
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            TenantAdminDiscoveryFiltersKeys.filterRow(
              'public_map.primary',
              1,
            ),
          ),
          findsOneWidget,
        );
        expect(find.text(assetFilterLabel), findsOneWidget);
        expect(find.text(eventFilterLabel), findsOneWidget);
        final filterAfterPreviewPump =
            discoveryFiltersController.filtersForSurface(mapSurface).elementAt(
                  0,
                );
        expect(
          filterAfterPreviewPump.imageUri,
          secondImageUri,
          reason:
              'admin preview controller filter after pump: ${filterAfterPreviewPump.toJson(
                    surface: mapSurface.key,
                    target: mapSurface.target,
                    primarySelectionMode: mapSurface.primarySelectionMode,
                  ).value}',
        );

        final persistedSettings = await waitForDiscoveryFiltersSettings(
          repository: settingsRepository,
          predicate: (settings) {
            final filters = _readSurfaceFilters(settings);
            if (filters.length < 2) {
              return false;
            }
            final assetFilter = _findSurfaceFilter(filters, assetFilterKey);
            final eventFilter = _findSurfaceFilter(filters, eventFilterKey);
            return assetFilter?['image_uri'] == secondImageUri &&
                assetFilter?['label'] == assetFilterLabel &&
                eventFilter?['label'] == eventFilterLabel;
          },
          expectationLabel: 'persisted discovery filter catalog',
        );
        expect(
          _readSurfaceFilters(persistedSettings)
              .firstWhere((item) => item['key'] == assetFilterKey)['image_uri'],
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
        final userLocationRepository = _StaticUserLocationRepository(
          latitude: -20.611121,
          longitude: -40.498617,
        );
        final appData = _buildTenantAppData(tenantOrigin);
        final appDataRepository = _MapIntegrationAppDataRepository(appData);
        mapController = MapScreenController(
          poiRepository: poiRepository,
          userLocationRepository: userLocationRepository,
          telemetryRepository: _NoopTelemetryRepository(),
          appData: appData,
          appDataRepository: appDataRepository,
          locationOriginService: LocationOriginService(
            appDataRepository: appDataRepository,
            userLocationRepository: userLocationRepository,
          ),
        );

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

        mapController.showFiltersTray();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: MapAdaptiveTray(controller: mapController),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final assetChipFinder = find.byKey(
          ValueKey<String>('map-compact-filter-chip-$assetFilterKey'),
        );
        final eventChipFinder = find.byKey(
          ValueKey<String>('map-compact-filter-chip-$eventFilterKey'),
        );
        expect(assetChipFinder, findsOneWidget);
        expect(eventChipFinder, findsOneWidget);
        expect(find.text(assetFilterLabel), findsNothing);
        expect(find.text(eventFilterLabel), findsNothing);
        expect(find.text(assetFilterKey), findsNothing);

        final assetImageFinder = find.byKey(ValueKey<String>(secondImageUri));
        expect(assetImageFinder, findsOneWidget);
        final chipImageWidget = tester.widget<Image>(assetImageFinder.first);
        expect((chipImageWidget.image as NetworkImage).url, secondImageUri);

        await tester.tap(assetChipFinder.first);
        await tester.pump();
        await waitForFilterApplication(
          tester,
          mapController: mapController,
          assetFilterLabel: assetFilterLabel,
          assetDisplayName: assetDisplayName,
        );

        expect(find.text(assetFilterLabel), findsOneWidget);
        expect(mapController.filterModeStreamValue.value, PoiFilterMode.server);
        expect(
            mapController.activeFilterLabelStreamValue.value, assetFilterLabel);
        expect(
          (mapController.filteredPoisStreamValue.value ?? <CityPoiModel>[])
              .map((poi) => poi.name)
              .toList(growable: false),
          equals(<String>[assetDisplayName]),
        );
      } finally {
        if (mapController != null) {
          await mapController.onDispose();
        }
        await discoveryFiltersController.onDispose();

        if (originalDiscoveryFilters != null) {
          try {
            await settingsRepository.updateDiscoveryFiltersSettings(
              settings: originalDiscoveryFilters,
            );
          } catch (_) {}
        }

        if (createdStaticAssetId != null) {
          try {
            await staticAssetsRepository.deleteStaticAsset(
              TenantAdminStaticAssetsRepoString.fromRaw(createdStaticAssetId),
            );
          } catch (_) {}
          try {
            await staticAssetsRepository.forceDeleteStaticAsset(
              TenantAdminStaticAssetsRepoString.fromRaw(createdStaticAssetId),
            );
          } catch (_) {}
        }

        if (createdStaticProfileType) {
          try {
            await staticAssetsRepository.deleteStaticProfileType(
              TenantAdminStaticAssetsRepoString.fromRaw(assetType),
            );
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

Future<TenantAdminDiscoveryFiltersSettingsValue>
    waitForDiscoveryFiltersSettings({
  required TenantAdminSettingsRepository repository,
  required bool Function(TenantAdminDiscoveryFiltersSettingsValue value)
      predicate,
  required String expectationLabel,
  Duration timeout = const Duration(seconds: 40),
  Duration step = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  TenantAdminDiscoveryFiltersSettingsValue? lastRead;

  while (DateTime.now().isBefore(deadline)) {
    final current = await repository.fetchDiscoveryFiltersSettings();
    lastRead = current;
    if (predicate(current)) {
      return current;
    }
    await Future<void>.delayed(step);
  }

  throw TestFailure(
    'Timed out waiting for $expectationLabel. '
    'Last read: ${lastRead?.rawDiscoveryFilters.value}',
  );
}

List<Map<String, dynamic>> _readSurfaceFilters(
  TenantAdminDiscoveryFiltersSettingsValue settings,
) {
  final raw = settings.rawDiscoveryFilters.value;
  final surfaces = raw['surfaces'];
  if (surfaces is! Map) {
    return const <Map<String, dynamic>>[];
  }
  final surface = surfaces['public_map.primary'];
  if (surface is! Map) {
    return const <Map<String, dynamic>>[];
  }
  final filters = surface['filters'];
  if (filters is! Iterable) {
    return const <Map<String, dynamic>>[];
  }
  return filters
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

Map<String, dynamic>? _findSurfaceFilter(
  List<Map<String, dynamic>> filters,
  String key,
) {
  for (final filter in filters) {
    if (filter['key'] == key) {
      return filter;
    }
  }
  return null;
}

Future<TenantAdminMediaUpload> _buildMapFilterUpload({
  required TenantAdminImageIngestionService imageIngestionService,
  required XFile file,
}) async {
  final upload = await imageIngestionService.buildUpload(
    file,
    slot: TenantAdminImageSlot.mapFilter,
  );
  expect(upload, isNotNull);
  return upload!;
}

Future<List<int>> fetchImageBytes(String imageUri) async {
  final response = await Dio().get<List<int>>(
    imageUri,
    options: Options(
      responseType: ResponseType.bytes,
      headers: {
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

AppData _buildTenantAppData(Uri tenantOrigin) {
  final remoteData = {
    'name': 'Guarappari',
    'type': 'tenant',
    'profile_types': const [],
    'domains': [tenantOrigin.host],
    'app_domains': const ['com.guarappari.app'],
    'theme_data_settings': const {
      'brightness_default': 'light',
      'primary_seed_color': '#009688',
      'secondary_seed_color': '#3F51B5',
    },
    'main_color': '#009688',
    'main_domain': tenantOrigin.toString(),
    'tenant_id': 'tenant-integration',
    'telemetry': const {'trackers': []},
    'telemetry_context': const {'location_freshness_minutes': 5},
    'settings': const {
      'map_ui': {
        'distance_bounds': {
          'min_meters': 1000,
          'default_meters': 15000,
          'max_meters': 50000,
        },
        'default_origin': {
          'lat': -20.611121,
          'lng': -40.498617,
          'label': 'Guarappari',
        },
      },
    },
    'firebase': null,
    'push': null,
  };
  final localInfo = {
    'platformType': 'mobile',
    'hostname': tenantOrigin.host,
    'href': tenantOrigin.toString(),
    'port': tenantOrigin.hasPort ? tenantOrigin.port.toString() : null,
    'device': 'integration-test-device',
  };
  return buildAppDataFromInitialization(
    remoteData: remoteData,
    localInfo: localInfo,
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
        (mapController.filteredPoisStreamValue.value ?? <CityPoiModel>[]).any(
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
        mapController.filteredPoisStreamValue.value ?? <CityPoiModel>[];
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

class _StubAuthRepository extends AuthRepositoryContract<UserBelluga> {
  _StubAuthRepository(this._token);

  final String _token;

  @override
  Object get backend => Object();

  @override
  String get userToken => _token;

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

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
    Object? minInterval,
  }) async =>
      false;

  @override
  Future<String?> resolveUserLocation() async => null;

  @override
  Future<void> setLastKnownAddress(Object? address) async {}

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

class _MapIntegrationAppDataRepository extends AppDataRepositoryContract {
  _MapIntegrationAppDataRepository(this._appData);

  final AppData _appData;

  @override
  AppData get appData => _appData;

  @override
  Future<void> init() async {}

  @override
  final StreamValue<ThemeMode?> themeModeStreamValue =
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.light);

  @override
  ThemeMode get themeMode => themeModeStreamValue.value ?? ThemeMode.light;

  @override
  Future<void> setThemeMode(AppThemeModeValue mode) async {
    themeModeStreamValue.addValue(mode.value);
  }

  @override
  final StreamValue<DistanceInMetersValue> maxRadiusMetersStreamValue =
      StreamValue<DistanceInMetersValue>(
    defaultValue: DistanceInMetersValue.fromRaw(50000, defaultValue: 50000),
  );

  @override
  DistanceInMetersValue get maxRadiusMeters => maxRadiusMetersStreamValue.value;

  @override
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {
    maxRadiusMetersStreamValue.addValue(meters);
  }
}

class _NoopTelemetryRepository implements TelemetryRepositoryContract {
  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<TelemetryRepositoryContractPrimBool> finishTimedEvent(
          EventTrackerTimedEventHandle handle) async =>
      telemetryRepoBool(true);

  @override
  Future<TelemetryRepositoryContractPrimBool> flushTimedEvents() async =>
      telemetryRepoBool(true);

  @override
  Future<TelemetryRepositoryContractPrimBool> logEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async =>
      telemetryRepoBool(true);

  @override
  Future<TelemetryRepositoryContractPrimBool> mergeIdentity(
          {required TelemetryRepositoryContractPrimString
              previousUserId}) async =>
      telemetryRepoBool(true);

  @override
  void setScreenContext(TelemetryRepositoryContractPrimMap? screenContext) {}

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
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
