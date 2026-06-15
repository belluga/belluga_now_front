import 'dart:async';

import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_bool_value.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_duration_value.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_text_value.dart';
import 'package:belluga_now/presentation/shared/location_permission/controllers/location_permission_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GeolocatorPlatform originalPlatform;

  setUp(() {
    originalPlatform = GeolocatorPlatform.instance;
  });

  tearDown(() async {
    GeolocatorPlatform.instance = originalPlatform;
    await GetIt.I.reset();
  });

  test(
      'web flow delegates prompt+location bootstrap to repository when browser permission is not yet granted',
      () async {
    final platform = _FakeGeolocatorPlatform()
      ..serviceEnabledResult = true
      ..checkPermissionResult = LocationPermission.denied;
    final repository = _FakeUserLocationRepository();
    GeolocatorPlatform.instance = platform;
    final controller = LocationPermissionController(
      isWeb: true,
      userLocationRepository: repository,
    );

    await controller.requestPermission(
      initialState: LocationPermissionState.serviceDisabled,
    );

    expect(platform.requestPermissionCalls, 0);
    expect(platform.openLocationSettingsCalls, 0);
    expect(platform.openAppSettingsCalls, 0);
    expect(repository.resolveUserLocationCallCount, 1);
    expect(repository.lastRequestPermissionIfNeededValue, isTrue);
    expect(controller.resultStreamValue.value, isTrue);
    expect(controller.loading.value, isFalse);
    controller.onDispose();
  });

  test(
      'web flow skips browser prompt when permission is already granted but still resolves canonical location',
      () async {
    final platform = _FakeGeolocatorPlatform()
      ..serviceEnabledResult = true
      ..checkPermissionResult = LocationPermission.whileInUse;
    final repository = _FakeUserLocationRepository();
    GeolocatorPlatform.instance = platform;
    final controller = LocationPermissionController(
      isWeb: true,
      userLocationRepository: repository,
    );

    await controller.requestPermission(
      initialState: LocationPermissionState.denied,
    );

    expect(platform.requestPermissionCalls, 0);
    expect(repository.resolveUserLocationCallCount, 1);
    expect(repository.lastRequestPermissionIfNeededValue, isFalse);
    expect(controller.resultStreamValue.value, isTrue);
    expect(controller.loading.value, isFalse);
    controller.onDispose();
  });

  test(
      'granted permission only completes after canonical location resolution succeeds',
      () async {
    final platform = _FakeGeolocatorPlatform()
      ..serviceEnabledResult = true
      ..checkPermissionResult = LocationPermission.denied;
    final repository = _FakeUserLocationRepository()
      ..resolveUserLocationCompleter = Completer<String?>();
    GeolocatorPlatform.instance = platform;
    final controller = LocationPermissionController(
      isWeb: true,
      userLocationRepository: repository,
    );

    final pending = controller.requestPermission(
      initialState: LocationPermissionState.denied,
    );
    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(controller.loading.value, isTrue);
    expect(controller.resultStreamValue.value, isNull);
    expect(repository.resolveUserLocationCallCount, 1);
    expect(repository.lastRequestPermissionIfNeededValue, isTrue);

    repository.resolveUserLocationCompleter!.complete(null);
    await pending;

    expect(controller.resultStreamValue.value, isTrue);
    expect(controller.loading.value, isFalse);
    controller.onDispose();
  });

  test(
      'web flow completes when permission becomes granted even if same-page canonical location bootstrap fails',
      () async {
    final platform = _FakeGeolocatorPlatform()
      ..serviceEnabledResult = true
      ..checkPermissionResults = <LocationPermission>[
        LocationPermission.denied,
        LocationPermission.whileInUse,
      ];
    final repository = _FakeUserLocationRepository()
      ..resolveUserLocationResult =
          'Permita o acesso a localizacao para localizar pontos proximos.';
    GeolocatorPlatform.instance = platform;
    final controller = LocationPermissionController(
      isWeb: true,
      userLocationRepository: repository,
    );

    await controller.requestPermission(
      initialState: LocationPermissionState.denied,
    );

    expect(repository.resolveUserLocationCallCount, 1);
    expect(controller.resultStreamValue.value, isTrue);
    expect(platform.checkPermissionCalls, 2);
    expect(controller.loading.value, isFalse);
    controller.onDispose();
  });

  test(
      'web flow still blocks when same-page canonical location bootstrap fails and permission remains denied',
      () async {
    final platform = _FakeGeolocatorPlatform()
      ..serviceEnabledResult = true
      ..checkPermissionResults = <LocationPermission>[
        LocationPermission.denied,
        LocationPermission.denied,
      ];
    final repository = _FakeUserLocationRepository()
      ..resolveUserLocationResult =
          'Permita o acesso a localizacao para localizar pontos proximos.';
    GeolocatorPlatform.instance = platform;
    final controller = LocationPermissionController(
      isWeb: true,
      userLocationRepository: repository,
    );

    await controller.requestPermission(
      initialState: LocationPermissionState.denied,
    );

    expect(repository.resolveUserLocationCallCount, 1);
    expect(controller.resultStreamValue.value, isFalse);
    expect(platform.checkPermissionCalls, 2);
    expect(controller.loading.value, isFalse);
    controller.onDispose();
  });

  test('web deniedForever does not re-request browser permission', () async {
    final platform = _FakeGeolocatorPlatform()
      ..serviceEnabledResult = true
      ..checkPermissionResult = LocationPermission.deniedForever;
    GeolocatorPlatform.instance = platform;
    final controller = LocationPermissionController(isWeb: true);

    await controller.requestPermission(
      initialState: LocationPermissionState.deniedForever,
    );

    expect(platform.requestPermissionCalls, 0);
    expect(platform.openLocationSettingsCalls, 0);
    expect(platform.openAppSettingsCalls, 0);
    expect(controller.resultStreamValue.value, isFalse);
    controller.onDispose();
  });

  test('web deniedForever returns true when permission was already restored',
      () async {
    final platform = _FakeGeolocatorPlatform()
      ..serviceEnabledResult = true
      ..checkPermissionResult = LocationPermission.whileInUse;
    final repository = _FakeUserLocationRepository();
    GeolocatorPlatform.instance = platform;
    final controller = LocationPermissionController(
      isWeb: true,
      userLocationRepository: repository,
    );

    await controller.requestPermission(
      initialState: LocationPermissionState.deniedForever,
    );

    expect(platform.requestPermissionCalls, 0);
    expect(repository.resolveUserLocationCallCount, 1);
    expect(controller.resultStreamValue.value, isTrue);
    controller.onDispose();
  });

  test('web flow fails closed when location repository is unavailable',
      () async {
    final platform = _FakeGeolocatorPlatform()
      ..serviceEnabledResult = true
      ..checkPermissionResult = LocationPermission.whileInUse;
    GeolocatorPlatform.instance = platform;
    final controller = LocationPermissionController(isWeb: true);

    await controller.requestPermission(
      initialState: LocationPermissionState.denied,
    );

    expect(controller.resultStreamValue.value, isFalse);
    expect(controller.loading.value, isFalse);
    controller.onDispose();
  });

  test('non-web deniedForever opens app settings path', () async {
    final platform = _FakeGeolocatorPlatform()
      ..serviceEnabledResult = true
      ..checkPermissionResult = LocationPermission.deniedForever;
    GeolocatorPlatform.instance = platform;
    final controller = LocationPermissionController(isWeb: false);

    await controller.requestPermission(
      initialState: LocationPermissionState.deniedForever,
    );

    expect(platform.openAppSettingsCalls, 1);
    expect(platform.requestPermissionCalls, 0);
    expect(controller.resultStreamValue.value, isFalse);
    controller.onDispose();
  });

  test('web flow reports false when repository bootstrap throws', () async {
    final platform = _FakeGeolocatorPlatform()
      ..serviceEnabledResult = true
      ..checkPermissionResult = LocationPermission.denied;
    final repository = _FakeUserLocationRepository()
      ..throwOnResolveUserLocation = true;
    GeolocatorPlatform.instance = platform;
    final controller = LocationPermissionController(
      isWeb: true,
      userLocationRepository: repository,
    );

    await controller.requestPermission(
      initialState: LocationPermissionState.denied,
    );

    expect(controller.resultStreamValue.value, isFalse);
    expect(controller.loading.value, isFalse);
    controller.onDispose();
  });

  test('ensureInitialState loads blocker when no state was injected', () async {
    final controller = LocationPermissionController(
      isWeb: true,
      initialStateLoader: () async => LocationPermissionState.deniedForever,
    );

    await controller.ensureInitialState();

    expect(
      controller.initialStateStreamValue.value,
      LocationPermissionState.deniedForever,
    );
    controller.onDispose();
  });

  test('ensureInitialState preserves injected state without calling loader',
      () async {
    var loaderCalls = 0;
    final controller = LocationPermissionController(
      isWeb: true,
      initialStateLoader: () async {
        loaderCalls += 1;
        return LocationPermissionState.denied;
      },
    );

    await controller.ensureInitialState(
      initialState: LocationPermissionState.serviceDisabled,
    );

    expect(
      controller.initialStateStreamValue.value,
      LocationPermissionState.serviceDisabled,
    );
    expect(loaderCalls, 0);
    controller.onDispose();
  });
}

class _FakeGeolocatorPlatform extends GeolocatorPlatform {
  int requestPermissionCalls = 0;
  int openAppSettingsCalls = 0;
  int openLocationSettingsCalls = 0;
  int checkPermissionCalls = 0;
  bool serviceEnabledResult = true;
  bool throwOnRequestPermission = false;
  LocationPermission checkPermissionResult = LocationPermission.denied;
  LocationPermission requestPermissionResult = LocationPermission.denied;
  List<LocationPermission>? checkPermissionResults;

  @override
  Future<LocationPermission> requestPermission() async {
    requestPermissionCalls += 1;
    if (throwOnRequestPermission) {
      throw Exception('forced request permission failure');
    }
    return requestPermissionResult;
  }

  @override
  Future<bool> openAppSettings() async {
    openAppSettingsCalls += 1;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    openLocationSettingsCalls += 1;
    return true;
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return serviceEnabledResult;
  }

  @override
  Future<LocationPermission> checkPermission() async {
    checkPermissionCalls += 1;
    if (checkPermissionResults case final List<LocationPermission> values
        when values.isNotEmpty) {
      return values.removeAt(0);
    }
    return checkPermissionResult;
  }
}

class _FakeUserLocationRepository implements UserLocationRepositoryContract {
  int ensureLoadedCallCount = 0;
  int refreshIfPermittedCallCount = 0;
  int resolveUserLocationCallCount = 0;
  Completer<String?>? resolveUserLocationCompleter;
  String? resolveUserLocationResult;
  bool throwOnResolveUserLocation = false;
  bool? lastRequestPermissionIfNeededValue;

  @override
  final userLocationStreamValue = StreamValue<CityCoordinate?>();

  @override
  final lastKnownLocationStreamValue = StreamValue<CityCoordinate?>();

  @override
  final lastKnownCapturedAtStreamValue = StreamValue<DateTime?>();

  @override
  final lastKnownAccuracyStreamValue = StreamValue<double?>();

  @override
  final lastKnownAddressStreamValue = StreamValue<String?>();

  @override
  final locationResolutionPhaseStreamValue =
      StreamValue<LocationResolutionPhase>(
    defaultValue: LocationResolutionPhase.unknown,
  );

  @override
  Future<void> ensureLoaded() async {
    ensureLoadedCallCount += 1;
  }

  @override
  Future<bool> refreshIfPermitted({
    UserLocationRepositoryContractDurationValue? minInterval,
  }) async {
    refreshIfPermittedCallCount += 1;
    return false;
  }

  @override
  Future<String?> resolveUserLocation({
    UserLocationRepositoryContractDurationValue? timeout,
    UserLocationRepositoryContractBoolValue? requestPermissionIfNeededValue,
  }) async {
    resolveUserLocationCallCount += 1;
    lastRequestPermissionIfNeededValue = requestPermissionIfNeededValue?.value;
    if (throwOnResolveUserLocation) {
      throw Exception('forced resolve location failure');
    }
    final completer = resolveUserLocationCompleter;
    if (completer != null) {
      return completer.future;
    }
    return resolveUserLocationResult;
  }

  @override
  Future<void> setLastKnownAddress(
    UserLocationRepositoryContractTextValue? address,
  ) async {}

  @override
  Future<bool> startTracking({
    LocationTrackingMode mode = LocationTrackingMode.mapForeground,
  }) async {
    return false;
  }

  @override
  Future<void> stopTracking() async {}

  @override
  Future<bool> warmUpIfPermitted() async {
    return false;
  }
}
