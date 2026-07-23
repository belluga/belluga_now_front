import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/discovery_filter_selection_snapshot.dart';
import 'package:belluga_now/domain/app_data/location_origin_reason.dart';
import 'package:belluga_now/domain/app_data/location_origin_settings.dart';
import 'package:belluga_now/domain/app_data/value_object/app_data_discovery_filter_token_value.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_dto.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test(
    'persists and restores fixed home location origin settings locally',
    () async {
      final backend = _FakeAppDataBackend();
      final localInfoSource = _FakeAppDataLocalInfoSource();
      final firstRepository = AppDataRepository(
        backend: backend,
        localInfoSource: localInfoSource,
      );

      await firstRepository.init();
      await firstRepository.setLocationOriginSettings(
        LocationOriginSettings.tenantDefaultLocation(
          fixedLocationReference: _buildCoordinate(
            latitude: -20.671339,
            longitude: -40.495395,
          ),
          reason: LocationOriginReason.outsideRange,
        ),
      );

      final reloadedRepository = AppDataRepository(
        backend: backend,
        localInfoSource: localInfoSource,
      );
      await reloadedRepository.init();

      expect(reloadedRepository.hasPersistedLocationOriginPreference, isTrue);
      expect(
        reloadedRepository.locationOriginSettings?.usesFixedReference,
        isTrue,
      );
      expect(
        reloadedRepository.locationOriginSettings?.reason,
        LocationOriginReason.outsideRange,
      );
      expect(
        reloadedRepository
            .locationOriginSettings
            ?.fixedLocationReference
            ?.latitude,
        closeTo(-20.671339, 0.000001),
      );
      expect(
        reloadedRepository
            .locationOriginSettings
            ?.fixedLocationReference
            ?.longitude,
        closeTo(-40.495395, 0.000001),
      );
    },
  );

  test(
    'persists and restores live home location origin mode locally',
    () async {
      final backend = _FakeAppDataBackend();
      final localInfoSource = _FakeAppDataLocalInfoSource();
      final firstRepository = AppDataRepository(
        backend: backend,
        localInfoSource: localInfoSource,
      );

      await firstRepository.init();
      await firstRepository.setLocationOriginSettings(
        LocationOriginSettings.userLiveLocation(),
      );

      final reloadedRepository = AppDataRepository(
        backend: backend,
        localInfoSource: localInfoSource,
      );
      await reloadedRepository.init();

      expect(reloadedRepository.hasPersistedLocationOriginPreference, isTrue);
      expect(
        reloadedRepository.locationOriginSettings?.usesUserLiveLocation,
        isTrue,
      );
      expect(
        reloadedRepository.locationOriginSettings?.fixedLocationReference,
        isNull,
      );
    },
  );

  test('scopes persisted home location origin settings by tenant', () async {
    final localInfoSource = _FakeAppDataLocalInfoSource();
    final firstRepository = AppDataRepository(
      backend: _FakeAppDataBackend(mainDomain: 'https://tenant-a.test'),
      localInfoSource: localInfoSource,
    );

    await firstRepository.init();
    await firstRepository.setLocationOriginSettings(
      LocationOriginSettings.tenantDefaultLocation(
        fixedLocationReference: _buildCoordinate(
          latitude: -20.671339,
          longitude: -40.495395,
        ),
        reason: LocationOriginReason.outsideRange,
      ),
    );

    final otherTenantRepository = AppDataRepository(
      backend: _FakeAppDataBackend(mainDomain: 'https://tenant-b.test'),
      localInfoSource: localInfoSource,
    );
    await otherTenantRepository.init();

    expect(otherTenantRepository.hasPersistedLocationOriginPreference, isFalse);
    expect(otherTenantRepository.locationOriginSettings, isNull);
  });

  test(
    'loads legacy unscoped home location origin settings as fallback',
    () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'home_use_live_location': 'false',
        'home_location_origin_reason': 'outsideRange',
        'home_fixed_location_reference_lat': '-20.671339',
        'home_fixed_location_reference_lng': '-40.495395',
      });
      final repository = AppDataRepository(
        backend: _FakeAppDataBackend(),
        localInfoSource: _FakeAppDataLocalInfoSource(),
      );

      await repository.init();

      expect(repository.hasPersistedLocationOriginPreference, isTrue);
      expect(repository.locationOriginSettings?.usesFixedReference, isTrue);
      expect(
        repository.locationOriginSettings?.fixedLocationReference?.latitude,
        closeTo(-20.671339, 0.000001),
      );
    },
  );

  test(
    'scopes persisted max radius by tenant and preserves legacy fallback',
    () async {
      final localInfoSource = _FakeAppDataLocalInfoSource();
      final firstRepository = AppDataRepository(
        backend: _FakeAppDataBackend(mainDomain: 'https://tenant-a.test'),
        localInfoSource: localInfoSource,
      );
      await firstRepository.init();
      await firstRepository.setMaxRadiusMeters(
        DistanceInMetersValue.fromRaw(9000, defaultValue: 9000),
      );

      final otherTenantRepository = AppDataRepository(
        backend: _FakeAppDataBackend(mainDomain: 'https://tenant-b.test'),
        localInfoSource: localInfoSource,
      );
      await otherTenantRepository.init();

      expect(otherTenantRepository.hasPersistedMaxRadiusPreference, isFalse);
      expect(otherTenantRepository.maxRadiusMeters.value, 50000);

      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'max_radius_meters': '7000',
      });
      final legacyRepository = AppDataRepository(
        backend: _FakeAppDataBackend(mainDomain: 'https://tenant-c.test'),
        localInfoSource: localInfoSource,
      );
      await legacyRepository.init();

      expect(legacyRepository.hasPersistedMaxRadiusPreference, isTrue);
      expect(legacyRepository.maxRadiusMeters.value, 7000);
    },
  );

  test('persists discovery filter selections by tenant and surface', () async {
    final backend = _FakeAppDataBackend();
    final localInfoSource = _FakeAppDataLocalInfoSource();
    final firstRepository = AppDataRepository(
      backend: backend,
      localInfoSource: localInfoSource,
    );

    await firstRepository.init();
    await firstRepository.setDiscoveryFilterSelection(
      AppDataDiscoveryFilterTokenValue.fromRaw('home.events'),
      AppDataDiscoveryFilterSelectionSnapshot(
        primaryKeys: [AppDataDiscoveryFilterTokenValue.fromRaw('shows')],
        taxonomySelections: [
          AppDataDiscoveryFilterTaxonomySelection(
            taxonomyKey: AppDataDiscoveryFilterTokenValue.fromRaw(
              'music_styles',
            ),
            termKeys: [AppDataDiscoveryFilterTokenValue.fromRaw('rock')],
          ),
        ],
        typeFiltersByEntity: <String, List<AppDataDiscoveryFilterTokenValue>>{
          'event': [AppDataDiscoveryFilterTokenValue.fromRaw('show')],
        },
      ),
    );

    final reloadedRepository = AppDataRepository(
      backend: backend,
      localInfoSource: localInfoSource,
    );
    await reloadedRepository.init();

    final restoredSelection = await reloadedRepository
        .getDiscoveryFilterSelection(
          AppDataDiscoveryFilterTokenValue.fromRaw('home.events'),
        );
    expect(
      restoredSelection?.primaryKeys
          .map((value) => value.value)
          .toList(growable: false),
      ['shows'],
    );
    expect(
      restoredSelection?.taxonomySelections.single.taxonomyKey.value,
      'music_styles',
    );
    expect(
      restoredSelection?.taxonomySelections.single.termKeys
          .map((value) => value.value)
          .toList(growable: false),
      ['rock'],
    );
    expect(
      restoredSelection?.typeFiltersByEntity['event']
          ?.map((value) => value.value)
          .toList(growable: false),
      ['show'],
    );
    expect(
      await reloadedRepository.getDiscoveryFilterSelection(
        AppDataDiscoveryFilterTokenValue.fromRaw('discovery.account_profiles'),
      ),
      isNull,
    );
  });

  test('ignores malformed persisted discovery filter selections', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'discovery_filter_selection_tenant.test_home.events': '{not-json',
    });
    final repository = AppDataRepository(
      backend: _FakeAppDataBackend(),
      localInfoSource: _FakeAppDataLocalInfoSource(),
    );

    await repository.init();

    expect(
      await repository.getDiscoveryFilterSelection(
        AppDataDiscoveryFilterTokenValue.fromRaw('home.events'),
      ),
      isNull,
    );
  });
}

class _FakeAppDataBackend implements AppDataBackendContract {
  _FakeAppDataBackend({this.mainDomain = 'https://tenant.test'});

  final String mainDomain;

  @override
  Future<AppDataDTO> fetch() async {
    return AppDataDTO.fromJson({
      'name': 'Tenant Test',
      'type': 'tenant',
      'main_domain': mainDomain,
      'profile_types': const [
        {
          'type': 'artist',
          'label': 'Artist',
          'allowed_taxonomies': [],
          'capabilities': {'is_favoritable': true, 'is_poi_enabled': true},
        },
      ],
      'domains': const ['https://tenant.test'],
      'app_domains': const [],
      'theme_data_settings': const {
        'brightness_default': 'dark',
        'primary_seed_color': '#112233',
        'secondary_seed_color': '#445566',
      },
      'main_color': '#112233',
      'tenant_id': 'tenant-1',
      'telemetry': const {'trackers': []},
      'telemetry_context': const {'location_freshness_minutes': 5},
      'firebase': null,
      'push': null,
      'settings': {
        'map_ui': {
          'radius': {'min_km': 1, 'default_km': 5, 'max_km': 50},
          'default_origin': {
            'lat': -20.671339,
            'lng': -40.495395,
            'label': 'Guarapari',
          },
        },
      },
    });
  }
}

class _FakeAppDataLocalInfoSource extends AppDataLocalInfoSource {
  @override
  Future<AppDataLocalInfoDTO> getInfo() async {
    final platformTypeValue = PlatformTypeValue(defaultValue: AppType.web)
      ..parse(AppType.web.name);
    return AppDataLocalInfoDTO(
      platformTypeValue: platformTypeValue,
      port: '',
      hostname: 'tenant.example.test',
      href: 'https://tenant.example.test',
      device: 'test',
    );
  }
}

CityCoordinate _buildCoordinate({
  required double latitude,
  required double longitude,
}) {
  return CityCoordinate(
    latitudeValue: LatitudeValue()..parse(latitude.toString()),
    longitudeValue: LongitudeValue()..parse(longitude.toString()),
  );
}
