import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/filters/main_filter_option.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_mode.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/queries/poi_query.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/poi_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/fab_menu_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/fab_menu.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

class _FakePoiRepository implements PoiRepositoryContract {
  @override
  final StreamValue<List<CityPoiModel>?> filteredPoisStreamValue =
      StreamValue<List<CityPoiModel>?>(defaultValue: null);

  @override
  final StreamValue<PoiFilterMode> filterModeStreamValue =
      StreamValue<PoiFilterMode>(defaultValue: PoiFilterMode.none);

  @override
  final StreamValue<PoiFilterOptions?> filterOptionsStreamValue =
      StreamValue<PoiFilterOptions?>();

  @override
  final StreamValue<List<MainFilterOption>> mainFilterOptionsStreamValue =
      StreamValue<List<MainFilterOption>>(defaultValue: const []);

  @override
  final StreamValue<CityPoiModel?> selectedPoiStreamValue =
      StreamValue<CityPoiModel?>();
  @override
  final StreamValue<List<CityPoiModel>?> stackItemsStreamValue =
      StreamValue<List<CityPoiModel>?>(defaultValue: null);

  @override
  CityCoordinate get defaultCenter => throw UnimplementedError();

  @override
  void applyFilterMode(PoiFilterMode mode) {
    filterModeStreamValue.addValue(mode);
  }

  @override
  void clearFilters() {
    filterModeStreamValue.addValue(PoiFilterMode.none);
  }

  @override
  void clearLoadedPois() {
    filteredPoisStreamValue.addValue(const <CityPoiModel>[]);
  }

  @override
  void clearSelection() {
    selectedPoiStreamValue.addValue(null);
  }

  @override
  Future<List<MainFilterOption>> fetchMainFilters() async => const [];

  @override
  Future<PoiFilterOptions> fetchFilters() async =>
      PoiFilterOptions(categories: const []);

  @override
  Future<List<CityPoiModel>> fetchPoints(PoiQuery query) async =>
      const <CityPoiModel>[];

  @override
  Future<void> refreshPoints(PoiQuery query) async {
    final points = await fetchPoints(query);
    filteredPoisStreamValue.addValue(points);
  }

  @override
  Future<List<CityPoiModel>> fetchStackItems({
    required String stackKey,
    required PoiQuery query,
  }) async =>
      const <CityPoiModel>[];

  @override
  Future<void> loadStackItems({
    required String stackKey,
    required PoiQuery query,
  }) async {
    final stackItems = await fetchStackItems(
      stackKey: stackKey,
      query: query,
    );
    stackItemsStreamValue.addValue(stackItems);
  }

  @override
  void selectPoi(CityPoiModel? poi) {
    selectedPoiStreamValue.addValue(poi);
  }

  void dispose() {
    filteredPoisStreamValue.dispose();
    filterModeStreamValue.dispose();
    filterOptionsStreamValue.dispose();
    mainFilterOptionsStreamValue.dispose();
    selectedPoiStreamValue.dispose();
    stackItemsStreamValue.dispose();
  }
}

class _FakeUserLocationRepository implements UserLocationRepositoryContract {
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
    Duration minInterval = const Duration(seconds: 30),
  }) async =>
      false;

  @override
  Future<String?> resolveUserLocation() async => null;

  @override
  Future<void> setLastKnownAddress(String? address) async {}

  @override
  Future<bool> startTracking({
    LocationTrackingMode mode = LocationTrackingMode.mapForeground,
  }) async =>
      true;

  @override
  Future<void> stopTracking() async {}

  @override
  Future<bool> warmUpIfPermitted() async => false;

  void dispose() {
    userLocationStreamValue.dispose();
    lastKnownLocationStreamValue.dispose();
    lastKnownCapturedAtStreamValue.dispose();
    lastKnownAccuracyStreamValue.dispose();
    lastKnownAddressStreamValue.dispose();
  }
}

class _FakeTelemetryRepository implements TelemetryRepositoryContract {
  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<bool> finishTimedEvent(EventTrackerTimedEventHandle handle) async =>
      true;

  @override
  Future<bool> flushTimedEvents() async => true;

  @override
  Future<bool> logEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async =>
      true;

  @override
  Future<bool> mergeIdentity({required String previousUserId}) async => true;

  @override
  void setScreenContext(Map<String, dynamic>? screenContext) {}

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async =>
      null;
}

void main() {
  testWidgets('filter image uses icon-sized contain envelope in fab', (
    tester,
  ) async {
    final poiRepository = _FakePoiRepository();
    final userLocationRepository = _FakeUserLocationRepository();
    final telemetryRepository = _FakeTelemetryRepository();
    final mapController = MapScreenController(
      poiRepository: poiRepository,
      userLocationRepository: userLocationRepository,
      telemetryRepository: telemetryRepository,
    );
    final fabController = FabMenuController(poiRepository: poiRepository)
      ..setExpanded(true)
      ..setCondensed(false);

    poiRepository.filterOptionsStreamValue.addValue(
      PoiFilterOptions(
        categories: [
          PoiFilterCategory(
            key: 'events',
            label: 'Eventos',
            tags: const <String>{},
            imageUri:
                'https://tenant-a.test/api/v1/media/map-filters/events?v=1',
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FabMenu(
            onNavigateToUser: () {},
            mapController: mapController,
            controller: fabController,
          ),
        ),
      ),
    );

    final imageWidget = tester.widget<Image>(find.byType(Image).first);
    expect(imageWidget.fit, BoxFit.contain);

    final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
    expect(
      sizedBoxes.any((box) => box.width == 20 && box.height == 20),
      isTrue,
    );

    fabController.dispose();
    await mapController.onDispose();
    poiRepository.dispose();
    userLocationRepository.dispose();
  });

  testWidgets(
    'source-backed catalog filter uses active visual state after selection',
    (tester) async {
      final poiRepository = _FakePoiRepository();
      final userLocationRepository = _FakeUserLocationRepository();
      final telemetryRepository = _FakeTelemetryRepository();
      final mapController = MapScreenController(
        poiRepository: poiRepository,
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetryRepository,
      );
      final fabController = FabMenuController(poiRepository: poiRepository)
        ..setExpanded(true)
        ..setCondensed(false);

      poiRepository.filterOptionsStreamValue.addValue(
        PoiFilterOptions(
          categories: [
            PoiFilterCategory(
              key: 'praia_filtro',
              label: 'Praia',
              tags: const <String>{},
              serverQuery: PoiFilterServerQuery(
                source: 'static_asset',
                types: {'beach_spot'},
              ),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FabMenu(
              onNavigateToUser: () {},
              mapController: mapController,
              controller: fabController,
            ),
          ),
        ),
      );
      await tester.pump();

      Finder findFilterFab() {
        return find.ancestor(
          of: find.text('Praia'),
          matching: find.byType(FloatingActionButton),
        );
      }

      final initialFab = tester.widget<FloatingActionButton>(findFilterFab());
      final initialBackground = initialFab.backgroundColor;

      await tester.tap(find.text('Praia'));
      await tester.pump();
      await tester.pump();

      final selectedFab = tester.widget<FloatingActionButton>(findFilterFab());

      expect(
        mapController.isCategoryFilterActive(
          PoiFilterCategory(
            key: 'praia_filtro',
            label: 'Praia',
            tags: const <String>{},
            serverQuery: PoiFilterServerQuery(
              source: 'static_asset',
              types: {'beach_spot'},
            ),
          ),
        ),
        isTrue,
      );
      expect(selectedFab.backgroundColor, isNot(equals(initialBackground)));

      fabController.dispose();
      await mapController.onDispose();
      poiRepository.dispose();
      userLocationRepository.dispose();
    },
  );

  testWidgets(
    'category fabs keep unique hero tags when labels repeat',
    (tester) async {
      final poiRepository = _FakePoiRepository();
      final userLocationRepository = _FakeUserLocationRepository();
      final telemetryRepository = _FakeTelemetryRepository();
      final mapController = MapScreenController(
        poiRepository: poiRepository,
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetryRepository,
      );
      final fabController = FabMenuController(poiRepository: poiRepository)
        ..setExpanded(true)
        ..setCondensed(false);

      poiRepository.filterOptionsStreamValue.addValue(
        PoiFilterOptions(
          categories: [
            PoiFilterCategory(
              key: 'praia-a',
              label: 'Praia',
              tags: const <String>{},
            ),
            PoiFilterCategory(
              key: 'praia-b',
              label: 'Praia',
              tags: const <String>{},
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FabMenu(
              onNavigateToUser: () {},
              mapController: mapController,
              controller: fabController,
            ),
          ),
        ),
      );
      await tester.pump();

      final heroTags = tester
          .widgetList<FloatingActionButton>(find.byType(FloatingActionButton))
          .map((fab) => fab.heroTag)
          .toList(growable: false);

      expect(heroTags.length, heroTags.toSet().length);

      fabController.dispose();
      await mapController.onDispose();
      poiRepository.dispose();
      userLocationRepository.dispose();
    },
  );
}
