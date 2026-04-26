import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/proximity_preferences/proximity_preference.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/proximity_preferences_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/proximity_preferences_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/proximity_preferences_backend/laravel_proximity_preferences_backend.dart';
import 'package:belluga_now/infrastructure/dal/dto/proximity_preference_dto.dart';
import 'package:get_it/get_it.dart';

class ProximityPreferencesRepository
    extends ProximityPreferencesRepositoryContract {
  ProximityPreferencesRepository({
    AppDataRepositoryContract? appDataRepository,
    ProximityPreferencesBackendContract? backend,
  })  : _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>(),
        _backend = backend ?? LaravelProximityPreferencesBackend() {
    seedFromLocalMirror();
  }

  final AppDataRepositoryContract _appDataRepository;
  final ProximityPreferencesBackendContract _backend;

  @override
  void seedFromLocalMirror() {
    setCurrentPreference(_buildFromLocalMirror());
  }

  @override
  Future<void> syncAfterIdentityReady() async {
    final remote = await _backend.fetch();
    if (remote != null) {
      await _apply(remote.toDomain());
      return;
    }

    final shouldSeed = _appDataRepository.hasPersistedMaxRadiusPreference ||
        _appDataRepository.hasPersistedLocationOriginPreference;
    if (!shouldSeed) {
      seedFromLocalMirror();
      return;
    }

    final seeded = await _backend.upsert(
      ProximityPreferenceDTO.fromDomain(_currentPreference),
    );
    await _apply(seeded.toDomain());
  }

  @override
  Future<void> updateMaxDistanceMeters(DistanceInMetersValue meters) async {
    final next = _currentPreference.copyWith(maxDistanceMetersValue: meters);
    final persisted = await _backend.upsert(
      ProximityPreferenceDTO.fromDomain(next),
    );
    await _apply(persisted.toDomain());
  }

  @override
  Future<void> setLiveDeviceLocation() async {
    final next = _currentPreference.copyWith(
      locationPreference:
          const ProximityLocationPreference.liveDeviceLocation(),
    );
    final persisted = await _backend.upsert(
      ProximityPreferenceDTO.fromDomain(next),
    );
    await _apply(persisted.toDomain());
  }

  @override
  Future<void> setFixedReference({
    required FixedLocationReference fixedReference,
  }) async {
    final next = _currentPreference.copyWith(
      locationPreference: ProximityLocationPreference.fixedReference(
        fixedReference: fixedReference,
      ),
    );
    final persisted = await _backend.upsert(
      ProximityPreferenceDTO.fromDomain(next),
    );
    await _apply(persisted.toDomain());
  }

  ProximityPreference get _currentPreference =>
      proximityPreference ?? _buildFromLocalMirror();

  Future<void> _apply(ProximityPreference preference) async {
    setCurrentPreference(preference);
    await _syncLocalMirror(preference);
  }

  Future<void> _syncLocalMirror(ProximityPreference preference) async {
    await _appDataRepository.setMaxRadiusMeters(
      preference.maxDistanceMetersValue,
    );

    if (preference.locationPreference.usesFixedReference) {
      final fixedReference = preference.locationPreference.fixedReference!;
      await _appDataRepository.useUserFixedLocationOrigin(
        fixedLocationReference: fixedReference.coordinate,
      );
      return;
    }

    await _appDataRepository.useUserLiveLocationOrigin();
  }

  ProximityPreference _buildFromLocalMirror() {
    final settings = _appDataRepository.locationOriginSettings;
    final fixedReference = settings?.usesUserFixedPreference == true &&
            settings?.fixedLocationReference != null
        ? FixedLocationReference(
            sourceKind: FixedLocationReferenceSourceKind.manualCoordinate,
            coordinate: settings!.fixedLocationReference!,
          )
        : null;

    return ProximityPreference(
      maxDistanceMetersValue: _appDataRepository.maxRadiusMeters,
      locationPreference: fixedReference == null
          ? const ProximityLocationPreference.liveDeviceLocation()
          : ProximityLocationPreference.fixedReference(
              fixedReference: fixedReference,
            ),
    );
  }
}
