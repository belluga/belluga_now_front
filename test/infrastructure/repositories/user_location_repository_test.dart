import 'dart:async';

import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/user_location_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GeolocatorPlatform originalPlatform;

  setUp(() {
    originalPlatform = GeolocatorPlatform.instance;
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  tearDown(() {
    GeolocatorPlatform.instance = originalPlatform;
  });

  test(
      'falls back to current position when last known position is unsupported',
      () async {
    final platform = _FakeGeolocatorPlatform()
      ..serviceEnabledResult = true
      ..checkPermissionResult = LocationPermission.whileInUse
      ..throwUnsupportedOnLastKnownPosition = true
      ..currentPositionResult = _buildPosition(
        latitude: -20.6772,
        longitude: -40.5093,
      );
    GeolocatorPlatform.instance = platform;

    final repository = UserLocationRepository();

    final result = await repository.refreshIfPermitted();

    expect(result, isTrue);
    expect(platform.getLastKnownPositionCalls, 1);
    expect(platform.getCurrentPositionCalls, 1);
    expect(repository.userLocationStreamValue.value, isNotNull);
    expect(
      repository.locationResolutionPhaseStreamValue.value,
      LocationResolutionPhase.resolved,
    );
  });

  test(
      'returns unavailable without throwing when last known position is unsupported and current position fails',
      () async {
    final platform = _FakeGeolocatorPlatform()
      ..serviceEnabledResult = true
      ..checkPermissionResult = LocationPermission.whileInUse
      ..throwUnsupportedOnLastKnownPosition = true
      ..throwOnCurrentPosition = true;
    GeolocatorPlatform.instance = platform;

    final repository = UserLocationRepository();

    final result = await repository.refreshIfPermitted();

    expect(result, isFalse);
    expect(platform.getLastKnownPositionCalls, 1);
    expect(platform.getCurrentPositionCalls, 1);
    expect(repository.userLocationStreamValue.value, isNull);
    expect(
      repository.locationResolutionPhaseStreamValue.value,
      LocationResolutionPhase.unavailable,
    );
  });

  test('keeps the supported last known position fast path unchanged', () async {
    final platform = _FakeGeolocatorPlatform()
      ..serviceEnabledResult = true
      ..checkPermissionResult = LocationPermission.whileInUse
      ..lastKnownPositionResult = _buildPosition(
        latitude: -20.6772,
        longitude: -40.5093,
      );
    GeolocatorPlatform.instance = platform;

    final repository = UserLocationRepository();

    final result = await repository.refreshIfPermitted();

    expect(result, isTrue);
    expect(platform.getLastKnownPositionCalls, 1);
    expect(platform.getCurrentPositionCalls, 0);
    final coordinate = repository.userLocationStreamValue.value;
    expect(coordinate, isA<CityCoordinate>());
    expect(coordinate?.latitude, closeTo(-20.6772, 0.000001));
    expect(coordinate?.longitude, closeTo(-40.5093, 0.000001));
    expect(
      repository.locationResolutionPhaseStreamValue.value,
      LocationResolutionPhase.resolved,
    );
  });
}

class _FakeGeolocatorPlatform extends GeolocatorPlatform {
  bool serviceEnabledResult = true;
  LocationPermission checkPermissionResult = LocationPermission.denied;
  bool throwUnsupportedOnLastKnownPosition = false;
  bool throwOnCurrentPosition = false;
  Position? lastKnownPositionResult;
  Position? currentPositionResult;
  int getLastKnownPositionCalls = 0;
  int getCurrentPositionCalls = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabledResult;

  @override
  Future<LocationPermission> checkPermission() async => checkPermissionResult;

  @override
  Future<LocationPermission> requestPermission() async => checkPermissionResult;

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async {
    getLastKnownPositionCalls += 1;
    if (throwUnsupportedOnLastKnownPosition) {
      throw UnsupportedError(
        'getLastKnownPosition is not supported on the web platform.',
      );
    }
    return lastKnownPositionResult;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    getCurrentPositionCalls += 1;
    if (throwOnCurrentPosition) {
      throw Exception('forced current position failure');
    }
    final position = currentPositionResult;
    if (position == null) {
      throw StateError('currentPositionResult must be configured for this test');
    }
    return position;
  }

  @override
  Stream<Position> getPositionStream({
    LocationSettings? locationSettings,
  }) {
    return const Stream<Position>.empty();
  }

  @override
  Stream<ServiceStatus> getServiceStatusStream() {
    return Stream<ServiceStatus>.value(ServiceStatus.enabled);
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

Position _buildPosition({
  required double latitude,
  required double longitude,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.now(),
    accuracy: 5.0,
    altitude: 1.0,
    altitudeAccuracy: 1.0,
    heading: 0.0,
    headingAccuracy: 1.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );
}
