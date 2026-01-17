import 'dart:developer' as developer;

import 'package:belluga_now/application/application.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/app_data_backend_stub.dart';
import 'package:belluga_now/infrastructure/dal/dao/local/app_data_local_info_source/app_data_local_info_source_stub.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/presentation/common/location_permission/screens/location_not_live_screen/location_not_live_screen.dart';
import 'package:belluga_now/presentation/common/location_permission/screens/location_permission_screen/location_permission_screen.dart';
import 'package:belluga_now/presentation/common/widgets/button_loading.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/map_screen.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/widgets/shared/marker_core.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/schedule_screen/widgets/event_bottom_sheet.dart';
import 'package:belluga_now/presentation/tenant/widgets/carousel_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  developer.postEvent(
    'integration_test.VmServiceProxyGoldenFileComparator',
    const {},
  );
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
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
    final permissionScreen = find.byType(LocationPermissionScreen);
    if (await _waitForMaybeFinder(tester, permissionScreen)) {
      final allowButton = find.byType(ButtonLoading);
      await tester.tap(allowButton.first);
      await _pumpFor(tester, const Duration(seconds: 1));
    }

    final notLiveScreen = find.byType(LocationNotLiveScreen);
    if (await _waitForMaybeFinder(tester, notLiveScreen)) {
      final continueButton = find.byType(TextButton);
      await tester.tap(continueButton.first);
      await _pumpFor(tester, const Duration(seconds: 1));
    }
  }

  Finder _mainFabFinder() {
    return find.byWidgetPredicate(
      (widget) =>
          widget is FloatingActionButton && widget.heroTag == 'map-fab-main',
    );
  }

  testWidgets(
    'Map event carousel, details sheet, filters, and marker border',
    (tester) async {
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
      final app = Application();
      GetIt.I.registerSingleton<ApplicationContract>(app);
      await app.init();

      await tester.pumpWidget(app);
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
      await _waitForFinder(tester, _mainFabFinder());

      final eventFilterIcon = find.byIcon(BooraIcons.audiotrack);
      await _waitForFinder(tester, eventFilterIcon);
      await tester.tap(eventFilterIcon.first);
      await _pumpFor(tester, const Duration(seconds: 1));
      await _waitForFinder(tester, find.text('Eventos em destaque'));

      expect(find.byType(CarouselCard), findsWidgets);

      final detailsButton = find.widgetWithText(FilledButton, 'Detalhes');
      await _waitForFinder(tester, detailsButton);
      await tester.tap(detailsButton.first);
      await _pumpFor(tester, const Duration(seconds: 1));
      expect(find.byType(EventBottomSheet), findsOneWidget);

      final barrier = find.byType(ModalBarrier);
      if (barrier.evaluate().isNotEmpty) {
        await tester.tap(barrier.first);
        await _pumpFor(tester, const Duration(seconds: 1));
      }

      final markerCore = find.byType(MarkerCore);
      await _waitForFinder(tester, markerCore);
      final markerContainer = find.descendant(
        of: markerCore.first,
        matching: find.byType(Container),
      );
      final containerWidget = tester.widget<Container>(markerContainer.first);
      final decoration = containerWidget.decoration as BoxDecoration;
      expect(decoration.border, isNull);

      await tester.tap(_mainFabFinder());
      await _pumpFor(tester, const Duration(seconds: 1));
      expect(find.text('Eventos em destaque'), findsNothing);
      expect(eventFilterIcon, findsWidgets);

      await tester.tap(_mainFabFinder());
      await _pumpFor(tester, const Duration(seconds: 1));
      expect(eventFilterIcon, findsNothing);
      expect(find.byIcon(Icons.tune), findsOneWidget);
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
