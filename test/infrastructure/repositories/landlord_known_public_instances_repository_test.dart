import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/landlord_public_instances_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_dto.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:belluga_now/infrastructure/repositories/landlord_known_public_instances_repository.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('passes canonical landlord origin from appData to backend', () async {
    final backend = _FakeLandlordPublicInstancesBackend();
    final repository = LandlordKnownPublicInstancesRepository(
      backend: backend,
      appDataRepository: _FakeAppDataRepository(
        _buildAppData(mainDomain: 'https://belluga.app'),
      ),
      localInfoSource: _FakeAppDataLocalInfoSource(),
    );

    final results = await repository.fetchFeaturedInstances();

    expect(backend.capturedLandlordOrigin, 'https://belluga.app');
    expect(results.single.mainDomainValue.value.origin, 'https://guarappari.belluga.app');
  });

  test('resolves AppDataRepository lazily from GetIt at fetch time', () async {
    final backend = _FakeLandlordPublicInstancesBackend();
    final repository = LandlordKnownPublicInstancesRepository(
      backend: backend,
      localInfoSource: _FakeAppDataLocalInfoSource(),
    );

    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      _FakeAppDataRepository(
        _buildAppData(mainDomain: 'https://belluga.app'),
      ),
    );

    final results = await repository.fetchFeaturedInstances();

    expect(backend.capturedLandlordOrigin, 'https://belluga.app');
    expect(results.single.mainDomainValue.value.origin, 'https://guarappari.belluga.app');
  });
}

class _FakeLandlordPublicInstancesBackend
    implements LandlordPublicInstancesBackendContract {
  String? capturedLandlordOrigin;

  @override
  Future<List<AppDataDTO>> fetchFeaturedInstanceEnvironments({
    required String landlordOrigin,
  }) async {
    capturedLandlordOrigin = landlordOrigin;
    return <AppDataDTO>[
      AppDataDTO.fromJson(
        const <String, Object?>{
          'type': 'tenant',
          'tenant_id': 'tenant-id',
          'name': 'Guarappari',
          'subdomain': 'guarappari',
          'main_domain': 'https://guarappari.belluga.app',
          'landlord_domain': 'https://belluga.app',
          'domains': <String>['guarappari.belluga.app'],
          'app_domains': <String>['com.guarappari.app'],
          'theme_data_settings': <String, Object?>{
            'brightness_default': 'dark',
            'primary_seed_color': '#A36CE3',
          },
          'profile_types': <Object>[],
          'telemetry': <String, Object?>{
            'trackers': <Object>[],
          },
        },
      ),
    ];
  }
}

class _FakeAppDataLocalInfoSource extends AppDataLocalInfoSource {
  @override
  Future<AppDataLocalInfoDTO> getInfo() async {
    return AppDataLocalInfoDTO.fromLegacyMap(
      const <String, dynamic>{
        'platformType': null,
        'port': '',
        'hostname': 'belluga.app',
        'href': 'https://belluga.app',
        'device': 'web',
      },
    );
  }
}

class _FakeAppDataRepository extends AppDataRepositoryContract {
  _FakeAppDataRepository(this._appData);

  final AppData _appData;
  final StreamValue<ThemeMode?> _themeModeStreamValue =
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.dark);
  final StreamValue<DistanceInMetersValue> _maxRadiusMetersStreamValue =
      StreamValue<DistanceInMetersValue>(
    defaultValue: DistanceInMetersValue.fromRaw(50000, defaultValue: 50000),
  );

  @override
  AppData get appData => _appData;

  @override
  Future<void> init() async {}

  @override
  StreamValue<ThemeMode?> get themeModeStreamValue => _themeModeStreamValue;

  @override
  ThemeMode get themeMode => _themeModeStreamValue.value ?? ThemeMode.dark;

  @override
  Future<void> setThemeMode(AppThemeModeValue mode) async {}

  @override
  StreamValue<DistanceInMetersValue> get maxRadiusMetersStreamValue =>
      _maxRadiusMetersStreamValue;

  @override
  DistanceInMetersValue get maxRadiusMeters =>
      _maxRadiusMetersStreamValue.value;

  @override
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {
    _maxRadiusMetersStreamValue.addValue(meters);
  }
}

AppData _buildAppData({required String mainDomain}) {
  return buildAppDataFromInitialization(
    remoteData: <String, Object?>{
      'type': 'landlord',
      'tenant_id': null,
      'name': 'Bóora!',
      'subdomain': null,
      'main_domain': mainDomain,
      'landlord_domain': mainDomain,
      'domains': const <String>[],
      'app_domains': const <String>[],
      'theme_data_settings': const <String, Object?>{
        'brightness_default': 'dark',
        'primary_seed_color': '#A36CE3',
      },
      'profile_types': const <Object>[],
      'telemetry': const <String, Object?>{
        'trackers': <Object>[],
      },
    },
    localInfo: <String, dynamic>{
      'hostname': Uri.parse(mainDomain).host,
      'href': mainDomain,
      'device': 'web',
      'port': '',
    },
  );
}
