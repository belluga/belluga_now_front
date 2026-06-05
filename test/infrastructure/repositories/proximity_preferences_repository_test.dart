import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/location_origin_settings.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/proximity_preferences/proximity_preference.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/proximity_preferences_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/proximity_preference_dto.dart';
import 'package:belluga_now/infrastructure/repositories/proximity_preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  test(
    'does not consume disabled entity references as active local origins',
    () async {
      final appDataRepository = _FakeAppDataRepository();
      final repository = ProximityPreferencesRepository(
        appDataRepository: appDataRepository,
        backend: _FakeProximityPreferencesBackend(
          remote: ProximityPreferenceDTO.fromJson({
            'max_distance_meters': 25000,
            'location_preference': {
              'mode': 'fixed_reference',
              'fixed_reference': {
                'source_kind': 'entity_reference',
                'coordinate': {'lat': -20.6736, 'lng': -40.4976},
                'label': 'Hotel Base',
                'entity_namespace': 'account_profile',
                'entity_type': 'hotel',
                'entity_id': 'profile-1',
                'reference_status': 'disabled',
                'reference_status_reason': 'source_capability_disabled',
                'blocked_capability_key': 'is_poi_enabled',
              },
            },
          }),
        ),
      );

      await repository.syncAfterIdentityReady();

      final fixedReference =
          repository.proximityPreference?.locationPreference.fixedReference;
      expect(fixedReference?.isDisabled, isTrue);
      expect(
        repository.proximityPreference?.locationPreference.usesFixedReference,
        isFalse,
      );
      expect(
        appDataRepository.locationOriginSettings?.usesUserLiveLocation,
        isTrue,
      );
      expect(
        appDataRepository.locationOriginSettings?.fixedLocationReference,
        isNull,
      );
    },
  );

  test(
    'setFixedReference resets route reference point policy to prompt',
    () async {
      final backend = _FakeProximityPreferencesBackend(
        remote: ProximityPreferenceDTO.fromJson({
          'max_distance_meters': 25000,
          'use_reference_point_for_routes': true,
          'location_preference': {
            'mode': 'fixed_reference',
            'fixed_reference': {
              'source_kind': 'manual_coordinate',
              'coordinate': {'lat': -20.1, 'lng': -40.1},
            },
          },
        }),
      );
      final repository = ProximityPreferencesRepository(
        appDataRepository: _FakeAppDataRepository(),
        backend: backend,
      );
      await repository.syncAfterIdentityReady();

      await repository.setFixedReference(
        fixedReference: FixedLocationReference(
          sourceKind: FixedLocationReferenceSourceKind.entityReference,
          coordinate: CityCoordinate(
            latitudeValue: LatitudeValue()..parse('-20.6736'),
            longitudeValue: LongitudeValue()..parse('-40.4976'),
          ),
          labelValue: ProximityPreferenceOptionalTextValue.fromRaw(
            'Hotel Base',
          ),
          entityNamespaceValue: ProximityPreferenceOptionalTextValue.fromRaw(
            'account_profile',
          ),
          entityTypeValue: ProximityPreferenceOptionalTextValue.fromRaw(
            'hotel',
          ),
          entityIdValue: ProximityPreferenceOptionalTextValue.fromRaw(
            'profile-1',
          ),
          entitySlugValue: ProximityPreferenceOptionalTextValue.fromRaw(
            'hotel-base',
          ),
        ),
      );

      expect(
        repository.proximityPreference?.useReferencePointForRoutes,
        isNull,
      );
      expect(backend.lastUpsert?.useReferencePointForRoutes, isNull);
      expect(backend.lastUpsert?.fixedReference?['entity_id'], 'profile-1');
      expect(backend.lastUpsert?.fixedReference?['entity_slug'], 'hotel-base');
    },
  );

  test(
    'clearFixedReference removes fixed reference and restores live location',
    () async {
      final backend = _FakeProximityPreferencesBackend(
        remote: ProximityPreferenceDTO.fromJson({
          'max_distance_meters': 25000,
          'location_preference': {
            'mode': 'fixed_reference',
            'fixed_reference': {
              'source_kind': 'entity_reference',
              'coordinate': {'lat': -20.6736, 'lng': -40.4976},
              'label': 'Hotel Base',
              'entity_namespace': 'account_profile',
              'entity_type': 'hotel',
              'entity_id': 'profile-1',
              'entity_slug': 'hotel-base',
            },
          },
        }),
      );
      final appDataRepository = _FakeAppDataRepository();
      final repository = ProximityPreferencesRepository(
        appDataRepository: appDataRepository,
        backend: backend,
      );
      await repository.syncAfterIdentityReady();

      await repository.clearFixedReference();

      expect(
        repository
            .proximityPreference?.locationPreference.usesLiveDeviceLocation,
        isTrue,
      );
      expect(backend.lastUpsert?.mode, 'live_device_location');
      expect(backend.lastUpsert?.fixedReference, isNull);
      expect(
        appDataRepository.locationOriginSettings?.usesUserLiveLocation,
        isTrue,
      );
      expect(
        appDataRepository.locationOriginSettings?.fixedLocationReference,
        isNull,
      );
    },
  );
}

class _FakeProximityPreferencesBackend
    implements ProximityPreferencesBackendContract {
  _FakeProximityPreferencesBackend({required this.remote});

  final ProximityPreferenceDTO? remote;
  ProximityPreferenceDTO? lastUpsert;

  @override
  Future<ProximityPreferenceDTO?> fetch() async => remote;

  @override
  Future<ProximityPreferenceDTO> upsert(
    ProximityPreferenceDTO preference,
  ) async {
    lastUpsert = preference;
    return preference;
  }
}

class _FakeAppDataRepository extends AppDataRepositoryContract {
  final StreamValue<ThemeMode?> _themeModeStreamValue = StreamValue<ThemeMode?>(
    defaultValue: ThemeMode.light,
  );
  final StreamValue<DistanceInMetersValue> _maxRadiusMetersStreamValue =
      StreamValue<DistanceInMetersValue>(
    defaultValue: DistanceInMetersValue.fromRaw(5000),
  );

  @override
  AppData get appData => throw UnimplementedError();

  @override
  StreamValue<ThemeMode?> get themeModeStreamValue => _themeModeStreamValue;

  @override
  ThemeMode get themeMode => ThemeMode.light;

  @override
  StreamValue<DistanceInMetersValue> get maxRadiusMetersStreamValue =>
      _maxRadiusMetersStreamValue;

  @override
  DistanceInMetersValue get maxRadiusMeters =>
      _maxRadiusMetersStreamValue.value;

  @override
  Future<void> init() async {}

  @override
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {
    _maxRadiusMetersStreamValue.addValue(meters);
  }

  @override
  Future<void> setThemeMode(AppThemeModeValue mode) async {}

  @override
  Future<void> setLocationOriginSettings(
    LocationOriginSettings settings,
  ) async {
    locationOriginSettingsStreamValue.addValue(settings);
  }
}
