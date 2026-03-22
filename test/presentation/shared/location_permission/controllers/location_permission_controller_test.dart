import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:belluga_now/presentation/shared/location_permission/controllers/location_permission_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GeolocatorPlatform originalPlatform;

  setUp(() {
    originalPlatform = GeolocatorPlatform.instance;
  });

  tearDown(() {
    GeolocatorPlatform.instance = originalPlatform;
  });

  test('web flow requests permission and never opens native settings',
      () async {
    final platform = _FakeGeolocatorPlatform()
      ..serviceEnabledResult = true
      ..checkPermissionResult = LocationPermission.whileInUse;
    GeolocatorPlatform.instance = platform;
    final controller = LocationPermissionController(isWeb: true);

    await controller.requestPermission(
      initialState: LocationPermissionState.serviceDisabled,
    );

    expect(platform.requestPermissionCalls, 1);
    expect(platform.openLocationSettingsCalls, 0);
    expect(platform.openAppSettingsCalls, 0);
    expect(controller.resultStreamValue.value, isTrue);
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
    GeolocatorPlatform.instance = platform;
    final controller = LocationPermissionController(isWeb: true);

    await controller.requestPermission(
      initialState: LocationPermissionState.deniedForever,
    );

    expect(platform.requestPermissionCalls, 0);
    expect(controller.resultStreamValue.value, isTrue);
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

  test('returns false when service remains disabled after request', () async {
    final platform = _FakeGeolocatorPlatform()
      ..serviceEnabledResult = false
      ..checkPermissionResult = LocationPermission.whileInUse;
    GeolocatorPlatform.instance = platform;
    final controller = LocationPermissionController(isWeb: true);

    await controller.requestPermission(
      initialState: LocationPermissionState.denied,
    );

    expect(controller.resultStreamValue.value, isFalse);
    expect(platform.checkPermissionCalls, 0);
    controller.onDispose();
  });

  test('gracefully handles geolocator errors and reports false', () async {
    final platform = _FakeGeolocatorPlatform()
      ..throwOnRequestPermission = true
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
}

class _FakeGeolocatorPlatform extends GeolocatorPlatform {
  int requestPermissionCalls = 0;
  int openAppSettingsCalls = 0;
  int openLocationSettingsCalls = 0;
  int checkPermissionCalls = 0;
  bool serviceEnabledResult = true;
  bool throwOnRequestPermission = false;
  LocationPermission checkPermissionResult = LocationPermission.denied;

  @override
  Future<LocationPermission> requestPermission() async {
    requestPermissionCalls += 1;
    if (throwOnRequestPermission) {
      throw Exception('forced request permission failure');
    }
    return checkPermissionResult;
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
    return checkPermissionResult;
  }
}
