import 'dart:developer' as developer;

import 'package:belluga_now/application/application.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:geolocator/geolocator.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/app_data_backend_stub.dart';
import 'package:belluga_now/infrastructure/dal/dao/local/app_data_local_info_source/app_data_local_info_source_stub.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/map_screen.dart';
import 'package:belluga_now/presentation/tenant/profile/screens/profile_screen/profile_screen.dart';
import 'package:belluga_now/presentation/common/auth/screens/auth_login_screen/auth_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'support/integration_test_bootstrap.dart';

void main() {
  developer.postEvent(
    'integration_test.VmServiceProxyGoldenFileComparator',
    const {},
  );
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();
  final originalGeolocator = GeolocatorPlatform.instance;

  setUpAll(() {
    GeolocatorPlatform.instance = _TestGeolocatorPlatform();
  });

  tearDownAll(() {
    GeolocatorPlatform.instance = originalGeolocator;
  });

  Future<void> _waitForFinder(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 30),
    Duration step = const Duration(milliseconds: 300),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(step);
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }
    throw TestFailure(
      'Timed out waiting for ${finder.describeMatch(Plurality.one)}.',
    );
  }

  Future<bool> _waitForMaybeFinder(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
    Duration step = const Duration(milliseconds: 300),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(step);
      if (finder.evaluate().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Future<void> _pumpFor(
    WidgetTester tester,
    Duration duration,
  ) async {
    final end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> _dismissInviteOverlayIfNeeded(WidgetTester tester) async {
    final closeButton = find.byTooltip('Fechar');
    if (await _waitForMaybeFinder(tester, closeButton)) {
      await tester.tap(closeButton.first);
      await _pumpFor(tester, const Duration(seconds: 1));
    }
  }

  Future<void> _dismissLocationGateIfNeeded(WidgetTester tester) async {
    final allowButton = find.text('Permitir localização');
    if (await _waitForMaybeFinder(tester, allowButton)) {
      await tester.tap(allowButton.first);
      await _pumpFor(tester, const Duration(seconds: 2));
    }

    final continueButton = find.text('Continuar sem localização ao vivo');
    if (await _waitForMaybeFinder(tester, continueButton)) {
      await tester.tap(continueButton.first);
      await _pumpFor(tester, const Duration(seconds: 1));
    }

    final notNowButton = find.text('Agora não');
    if (await _waitForMaybeFinder(tester, notNowButton)) {
      await tester.tap(notNowButton.first);
      await _pumpFor(tester, const Duration(seconds: 1));
    }
  }

  testWidgets(
    'Home to Map to Home to Profile navigation',
    (tester) async {
      debugPrint('Shell nav test: start');
      if (GetIt.I.isRegistered<ApplicationContract>()) {
        GetIt.I.unregister<ApplicationContract>();
      }
      if (GetIt.I.isRegistered<AppDataRepository>()) {
        GetIt.I.unregister<AppDataRepository>();
      }
      GetIt.I.registerSingleton<AppDataRepository>(
        AppDataRepository(
          backend: AppDataBackend(),
          localInfoSource: AppDataLocalInfoSource(),
        ),
      );
      debugPrint('Shell nav test: repositories registered');
      final app = Application();
      GetIt.I.registerSingleton<ApplicationContract>(app);
      debugPrint('Shell nav test: init app');
      await app.init();
      debugPrint('Shell nav test: app init done');

      await tester.pumpWidget(app);
      debugPrint('Shell nav test: widget pumped');

      await _pumpFor(tester, const Duration(seconds: 2));
      await _dismissLocationGateIfNeeded(tester);
      await _dismissInviteOverlayIfNeeded(tester);
      await _waitForFinder(
        tester,
        find.text('Seus Favoritos', skipOffstage: false),
      );

      await tester.tap(find.widgetWithText(NavigationDestination, 'Mapa'));
      await _pumpFor(tester, const Duration(seconds: 1));
      await _dismissLocationGateIfNeeded(tester);
      await _waitForFinder(tester, find.byType(MapScreen));

      await tester.tap(find.byIcon(Icons.arrow_back));
      await _pumpFor(tester, const Duration(seconds: 1));
      await _dismissLocationGateIfNeeded(tester);
      await _dismissInviteOverlayIfNeeded(tester);
      await _waitForFinder(
        tester,
        find.text('Seus Favoritos', skipOffstage: false),
      );

      final profileDestination = find.byWidgetPredicate(
        (widget) =>
            widget is NavigationDestination && widget.label == 'Perfil',
        skipOffstage: false,
      );
      await tester.tap(profileDestination);
      await _pumpFor(tester, const Duration(seconds: 1));
      final foundProfile = await _waitForMaybeFinder(
        tester,
        find.byType(ProfileScreen, skipOffstage: false),
      );
      final foundLogin = foundProfile
          ? true
          : await _waitForMaybeFinder(
              tester,
              find.byType(AuthLoginScreen, skipOffstage: false),
            );
      if (!foundProfile && !foundLogin) {
        throw TestFailure(
          'Profile destination did not resolve to ProfileScreen or AuthLoginScreen.',
        );
      }

      if (foundProfile || foundLogin) {
        await tester.tap(find.byIcon(Icons.arrow_back));
        await _pumpFor(tester, const Duration(seconds: 1));
      }
      await _waitForFinder(
        tester,
        find.text('Seus Favoritos', skipOffstage: false),
      );
    },
  );
}

class _TestGeolocatorPlatform extends GeolocatorPlatform {
  static final Position _position = Position(
    latitude: -20.6772,
    longitude: -40.5093,
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
