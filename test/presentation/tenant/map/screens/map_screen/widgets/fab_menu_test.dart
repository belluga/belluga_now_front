import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/filters/main_filter_option.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_mode.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/queries/poi_query.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/poi_boolean_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_count_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_image_uri_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_key_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_label_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_source_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_taxonomy_token_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_hex_color_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_icon_symbol_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_stack_key_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_tag_value.dart';
import 'package:belluga_now/domain/repositories/poi_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/fab_menu_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/fab_menu.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
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
    required PoiStackKeyValue stackKey,
    required PoiQuery query,
  }) async =>
      const <CityPoiModel>[];

  @override
  Future<CityPoiModel?> fetchPoiByReference({
    required PoiReferenceTypeValue refType,
    required PoiReferenceIdValue refId,
  }) async =>
      null;

  @override
  Future<void> loadStackItems({
    required PoiStackKeyValue stackKey,
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

PoiFilterCategory _buildCategory({
  required String key,
  required String label,
  Set<String> tags = const <String>{},
  String? imageUri,
  bool overrideMarker = false,
  PoiFilterMarkerOverride? markerOverride,
  PoiFilterServerQuery? serverQuery,
}) {
  return PoiFilterCategory(
    keyValue: _buildFilterKeyValue(key),
    labelValue: _buildFilterLabelValue(label),
    countValue: _buildFilterCountValue(tags.length),
    tagValues: _buildTagValues(tags),
    imageUriValue: _buildFilterImageUriValue(imageUri),
    overrideMarkerValue: _buildBooleanValue(overrideMarker),
    markerOverride: markerOverride,
    serverQuery: serverQuery,
  );
}

PoiFilterServerQuery _buildServerQuery({
  String? source,
  Set<String> types = const <String>{},
  Set<String> categoryKeys = const <String>{},
  Set<String> taxonomy = const <String>{},
  Set<String> tags = const <String>{},
}) {
  return PoiFilterServerQuery(
    sourceValue: _buildFilterSourceValue(source),
    typeValues: _buildFilterTypeValues(types),
    categoryKeyValues: _buildFilterKeyValues(categoryKeys),
    taxonomyTokenValues: _buildFilterTaxonomyValues(taxonomy),
    tagValues: _buildTagValues(tags),
  );
}

PoiFilterMarkerOverride _buildIconMarkerOverride({
  required String icon,
  required String colorHex,
  String? iconColorHex,
}) {
  return PoiFilterMarkerOverride.icon(
    iconValue: _buildIconSymbolValue(icon),
    colorHexValue: _buildHexColorValue(colorHex),
    iconColorHexValue:
        iconColorHex == null ? null : _buildHexColorValue(iconColorHex),
  );
}

PoiFilterKeyValue _buildFilterKeyValue(String raw) {
  final value = PoiFilterKeyValue();
  value.parse(raw.trim().toLowerCase());
  return value;
}

PoiFilterLabelValue _buildFilterLabelValue(String raw) {
  final value = PoiFilterLabelValue();
  value.parse(raw.trim());
  return value;
}

PoiFilterCountValue _buildFilterCountValue(int raw) {
  final value = PoiFilterCountValue();
  value.parse(raw.toString());
  return value;
}

PoiFilterImageUriValue? _buildFilterImageUriValue(String? raw) {
  final normalized = raw?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  final value = PoiFilterImageUriValue();
  value.parse(normalized);
  return value;
}

PoiBooleanValue _buildBooleanValue(bool raw) {
  final value = PoiBooleanValue();
  value.parse(raw.toString());
  return value;
}

PoiFilterSourceValue? _buildFilterSourceValue(String? raw) {
  final normalized = raw?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  final value = PoiFilterSourceValue();
  value.parse(normalized);
  return value;
}

Set<PoiFilterTypeValue> _buildFilterTypeValues(Iterable<String> rawValues) {
  final values = <PoiFilterTypeValue>{};
  for (final entry in rawValues) {
    final normalized = entry.trim().toLowerCase();
    if (normalized.isEmpty) {
      continue;
    }
    final value = PoiFilterTypeValue();
    value.parse(normalized);
    values.add(value);
  }
  return Set<PoiFilterTypeValue>.unmodifiable(values);
}

Set<PoiFilterKeyValue> _buildFilterKeyValues(Iterable<String> rawValues) {
  final values = <PoiFilterKeyValue>{};
  for (final entry in rawValues) {
    final normalized = entry.trim().toLowerCase();
    if (normalized.isEmpty) {
      continue;
    }
    final value = PoiFilterKeyValue();
    value.parse(normalized);
    values.add(value);
  }
  return Set<PoiFilterKeyValue>.unmodifiable(values);
}

Set<PoiFilterTaxonomyTokenValue> _buildFilterTaxonomyValues(
  Iterable<String> rawValues,
) {
  final values = <PoiFilterTaxonomyTokenValue>{};
  for (final entry in rawValues) {
    final normalized = entry.trim().toLowerCase();
    if (normalized.isEmpty) {
      continue;
    }
    final value = PoiFilterTaxonomyTokenValue();
    value.parse(normalized);
    values.add(value);
  }
  return Set<PoiFilterTaxonomyTokenValue>.unmodifiable(values);
}

Set<PoiTagValue> _buildTagValues(Iterable<String> rawValues) {
  final values = <PoiTagValue>{};
  for (final entry in rawValues) {
    final normalized = entry.trim().toLowerCase();
    if (normalized.isEmpty) {
      continue;
    }
    final value = PoiTagValue();
    value.parse(normalized);
    values.add(value);
  }
  return Set<PoiTagValue>.unmodifiable(values);
}

PoiIconSymbolValue _buildIconSymbolValue(String raw) {
  final value = PoiIconSymbolValue();
  value.parse(raw.trim());
  return value;
}

PoiHexColorValue _buildHexColorValue(String raw) {
  final value = PoiHexColorValue();
  value.parse(raw.trim());
  return value;
}

void main() {
  testWidgets(
    'category FAB prefers override icon+color over legacy image',
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
            _buildCategory(
              key: 'events',
              label: 'Eventos',
              tags: const <String>{},
              imageUri: 'https://tenant.test/legacy-events.png',
              overrideMarker: true,
              markerOverride: _buildIconMarkerOverride(
                icon: 'music',
                colorHex: '#C6141F',
                iconColorHex: '#00DD88',
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

      final filterFabFinder = find.ancestor(
        of: find.text('Eventos'),
        matching: find.byType(FloatingActionButton),
      );
      expect(filterFabFinder, findsOneWidget);

      final iconFinder = find.descendant(
        of: filterFabFinder,
        matching: find.byIcon(Icons.music_note),
      );
      expect(iconFinder, findsOneWidget);

      final imageFinder = find.descendant(
        of: filterFabFinder,
        matching: find.byType(Image),
      );
      expect(imageFinder, findsNothing);

      fabController.dispose();
      await mapController.onDispose();
      poiRepository.dispose();
      userLocationRepository.dispose();
    },
  );

  testWidgets(
    'selected category FAB uses marker override color as background',
    (tester) async {
      final poiRepository = _FakePoiRepository();
      final userLocationRepository = _FakeUserLocationRepository();
      final telemetryRepository = _FakeTelemetryRepository();
      final mapController = MapScreenController(
        poiRepository: poiRepository,
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetryRepository,
      );
      mapController.isLoading.addValue(false);
      final fabController = FabMenuController(poiRepository: poiRepository)
        ..setExpanded(true)
        ..setCondensed(false);

      poiRepository.filterOptionsStreamValue.addValue(
        PoiFilterOptions(
          categories: [
            _buildCategory(
              key: 'events',
              label: 'Eventos',
              tags: const <String>{},
              overrideMarker: true,
              markerOverride: _buildIconMarkerOverride(
                icon: 'music',
                colorHex: '#C6141F',
                iconColorHex: '#101010',
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

      await tester.tap(find.text('Eventos'));
      await tester.pump();
      await tester.pump();

      final selectedFab = tester.widget<FloatingActionButton>(
        find.ancestor(
          of: find.text('Eventos'),
          matching: find.byType(FloatingActionButton),
        ),
      );

      expect(selectedFab.backgroundColor, const Color(0xFFC6141F));
      final selectedIcon = tester.widget<Icon>(
        find.descendant(
          of: find.ancestor(
            of: find.text('Eventos'),
            matching: find.byType(FloatingActionButton),
          ),
          matching: find.byIcon(Icons.music_note),
        ),
      );
      expect(selectedIcon.color, const Color(0xFF101010));

      fabController.dispose();
      await mapController.onDispose();
      poiRepository.dispose();
      userLocationRepository.dispose();
    },
  );

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
          _buildCategory(
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
      mapController.isLoading.addValue(false);
      final fabController = FabMenuController(poiRepository: poiRepository)
        ..setExpanded(true)
        ..setCondensed(false);

      poiRepository.filterOptionsStreamValue.addValue(
        PoiFilterOptions(
          categories: [
            _buildCategory(
              key: 'praia_filtro',
              label: 'Praia',
              tags: const <String>{},
              serverQuery: _buildServerQuery(
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
          _buildCategory(
            key: 'praia_filtro',
            label: 'Praia',
            tags: const <String>{},
            serverQuery: _buildServerQuery(
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
    'navigate-to-user action stays disabled until user location is available',
    (tester) async {
      final poiRepository = _FakePoiRepository();
      final userLocationRepository = _FakeUserLocationRepository();
      final telemetryRepository = _FakeTelemetryRepository();
      final mapController = MapScreenController(
        poiRepository: poiRepository,
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetryRepository,
      );
      mapController.isLoading.addValue(false);
      final fabController = FabMenuController(poiRepository: poiRepository)
        ..setExpanded(true)
        ..setCondensed(false);

      var navigateTapCount = 0;
      Widget buildUnderTest() {
        return MaterialApp(
          home: Scaffold(
            body: FabMenu(
              onNavigateToUser: () {
                navigateTapCount += 1;
              },
              mapController: mapController,
              controller: fabController,
            ),
          ),
        );
      }

      await tester.pumpWidget(buildUnderTest());
      await tester.pump();

      Finder navigateFabFinder() {
        return find.ancestor(
          of: find.text('Ir para você'),
          matching: find.byType(FloatingActionButton),
        );
      }

      final disabledFab =
          tester.widget<FloatingActionButton>(navigateFabFinder());
      final disabledColor = disabledFab.backgroundColor!;
      expect(disabledFab.onPressed, isNull);

      userLocationRepository.userLocationStreamValue.addValue(
        CityCoordinate.fromLatLng(const LatLng(-20.0, -40.0)),
      );
      await tester.pumpWidget(buildUnderTest());
      await tester.pump();

      final enabledFab =
          tester.widget<FloatingActionButton>(navigateFabFinder());
      final enabledColor = enabledFab.backgroundColor!;
      expect(enabledFab.onPressed, isNotNull);
      expect(disabledColor.a, lessThan(enabledColor.a));

      await tester.tap(find.text('Ir para você'));
      await tester.pump();
      expect(navigateTapCount, 1);

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
            _buildCategory(
              key: 'praia-a',
              label: 'Praia',
              tags: const <String>{},
            ),
            _buildCategory(
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
