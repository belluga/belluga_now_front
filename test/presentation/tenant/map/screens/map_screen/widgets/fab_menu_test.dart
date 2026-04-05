import 'dart:async';

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
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/location_origin_settings.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/poi_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/infrastructure/services/location_origin_service.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/fab_menu_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_location_feedback_state.dart';
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
  Completer<bool>? refreshIfPermittedCompleter;

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
  final StreamValue<LocationResolutionPhase>
      locationResolutionPhaseStreamValue = StreamValue<LocationResolutionPhase>(
    defaultValue: LocationResolutionPhase.unknown,
  );

  @override
  Future<void> ensureLoaded() async {}

  @override
  Future<bool> refreshIfPermitted({
    Object? minInterval,
  }) async {
    locationResolutionPhaseStreamValue.addValue(
      LocationResolutionPhase.resolving,
    );
    final completer = refreshIfPermittedCompleter;
    if (completer != null) {
      return completer.future;
    }
    return false;
  }

  @override
  Future<String?> resolveUserLocation() async {
    locationResolutionPhaseStreamValue.addValue(
      LocationResolutionPhase.resolving,
    );
    return null;
  }

  @override
  Future<void> setLastKnownAddress(Object? address) async {}

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
    locationResolutionPhaseStreamValue.dispose();
  }
}

class _FakeTelemetryRepository implements TelemetryRepositoryContract {
  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<TelemetryRepositoryContractPrimBool> finishTimedEvent(
          EventTrackerTimedEventHandle handle) async =>
      telemetryRepoBool(true);

  @override
  Future<TelemetryRepositoryContractPrimBool> flushTimedEvents() async =>
      telemetryRepoBool(true);

  @override
  Future<TelemetryRepositoryContractPrimBool> logEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async =>
      telemetryRepoBool(true);

  @override
  Future<TelemetryRepositoryContractPrimBool> mergeIdentity(
          {required TelemetryRepositoryContractPrimString
              previousUserId}) async =>
      telemetryRepoBool(true);

  @override
  void setScreenContext(TelemetryRepositoryContractPrimMap? screenContext) {}

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
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

List<PoiFilterTypeValue> _buildFilterTypeValues(Iterable<String> rawValues) {
  final values = <PoiFilterTypeValue>[];
  for (final entry in rawValues) {
    final normalized = entry.trim().toLowerCase();
    if (normalized.isEmpty) {
      continue;
    }
    final value = PoiFilterTypeValue();
    value.parse(normalized);
    values.add(value);
  }
  return List<PoiFilterTypeValue>.unmodifiable(values.toSet().toList());
}

List<PoiFilterKeyValue> _buildFilterKeyValues(Iterable<String> rawValues) {
  final values = <PoiFilterKeyValue>[];
  for (final entry in rawValues) {
    final normalized = entry.trim().toLowerCase();
    if (normalized.isEmpty) {
      continue;
    }
    final value = PoiFilterKeyValue();
    value.parse(normalized);
    values.add(value);
  }
  return List<PoiFilterKeyValue>.unmodifiable(values.toSet().toList());
}

List<PoiFilterTaxonomyTokenValue> _buildFilterTaxonomyValues(
  Iterable<String> rawValues,
) {
  final values = <PoiFilterTaxonomyTokenValue>[];
  for (final entry in rawValues) {
    final normalized = entry.trim().toLowerCase();
    if (normalized.isEmpty) {
      continue;
    }
    final value = PoiFilterTaxonomyTokenValue();
    value.parse(normalized);
    values.add(value);
  }
  return List<PoiFilterTaxonomyTokenValue>.unmodifiable(
    values.toSet().toList(),
  );
}

List<PoiTagValue> _buildTagValues(Iterable<String> rawValues) {
  final values = <PoiTagValue>[];
  for (final entry in rawValues) {
    final normalized = entry.trim().toLowerCase();
    if (normalized.isEmpty) {
      continue;
    }
    final value = PoiTagValue();
    value.parse(normalized);
    values.add(value);
  }
  return List<PoiTagValue>.unmodifiable(values.toSet().toList());
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

MapScreenController _buildMapScreenController({
  required PoiRepositoryContract poiRepository,
  required UserLocationRepositoryContract userLocationRepository,
  required TelemetryRepositoryContract telemetryRepository,
  AppDataRepositoryContract? appDataRepository,
}) {
  final resolvedAppDataRepository =
      appDataRepository ?? _FakeMapAppDataRepository(_buildTestAppData());
  return MapScreenController(
    poiRepository: poiRepository,
    userLocationRepository: userLocationRepository,
    telemetryRepository: telemetryRepository,
    appData: resolvedAppDataRepository.appData,
    appDataRepository: resolvedAppDataRepository,
    locationOriginService: LocationOriginService(
      appDataRepository: resolvedAppDataRepository,
      userLocationRepository: userLocationRepository,
    ),
  );
}

class _FakeMapAppDataRepository extends AppDataRepositoryContract {
  _FakeMapAppDataRepository(this._appData);

  final AppData _appData;

  @override
  AppData get appData => _appData;

  @override
  Future<void> init() async {}

  @override
  final StreamValue<ThemeMode?> themeModeStreamValue =
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.light);

  @override
  ThemeMode get themeMode => themeModeStreamValue.value ?? ThemeMode.light;

  @override
  Future<void> setThemeMode(AppThemeModeValue mode) async {
    themeModeStreamValue.addValue(mode.value);
  }

  @override
  final StreamValue<DistanceInMetersValue> maxRadiusMetersStreamValue =
      StreamValue<DistanceInMetersValue>(
    defaultValue: DistanceInMetersValue.fromRaw(50000, defaultValue: 50000),
  );

  @override
  DistanceInMetersValue get maxRadiusMeters => maxRadiusMetersStreamValue.value;

  @override
  bool get hasPersistedMaxRadiusPreference => false;

  @override
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {
    maxRadiusMetersStreamValue.addValue(meters);
  }
}

AppData _buildTestAppData() {
  return buildAppDataFromInitialization(
    remoteData: const {
      'name': 'Tenant Test',
      'type': 'tenant',
      'main_domain': 'https://tenant.test',
      'profile_types': [],
      'domains': ['https://tenant.test'],
      'app_domains': [],
      'theme_data_settings': {
        'brightness_default': 'light',
        'primary_seed_color': '#FFFFFF',
        'secondary_seed_color': '#000000',
      },
      'main_color': '#FFFFFF',
      'tenant_id': 'tenant-1',
      'telemetry': {'trackers': []},
      'telemetry_context': {'location_freshness_minutes': 5},
      'settings': {
        'map_ui': {
          'distance_bounds': {
            'min_meters': 1000,
            'default_meters': 15000,
            'max_meters': 50000,
          },
          'default_origin': {
            'lat': -20.0,
            'lng': -40.0,
            'label': 'Centro',
          },
        },
      },
      'firebase': null,
      'push': null,
    },
    localInfo: const {
      'platformType': 'mobile',
      'hostname': 'tenant.test',
      'href': 'https://tenant.test',
      'port': null,
      'device': 'test-device',
    },
  );
}

void main() {
  testWidgets(
    'category FAB prefers override icon+color over legacy image',
    (tester) async {
      final poiRepository = _FakePoiRepository();
      final userLocationRepository = _FakeUserLocationRepository();
      final telemetryRepository = _FakeTelemetryRepository();
      final mapController = _buildMapScreenController(
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
      final mapController = _buildMapScreenController(
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
    final mapController = _buildMapScreenController(
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
      final mapController = _buildMapScreenController(
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
    'navigate-to-user action stays disabled while location origin is still unresolved',
    (tester) async {
      final poiRepository = _FakePoiRepository();
      final userLocationRepository = _FakeUserLocationRepository();
      final telemetryRepository = _FakeTelemetryRepository();
      final mapController = _buildMapScreenController(
        poiRepository: poiRepository,
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetryRepository,
      );
      mapController.locationFeedbackStateStreamValue.addValue(
        const MapLocationFeedbackState.loading(
          resolutionPhase: LocationResolutionPhase.resolving,
        ),
      );
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

      final resolvedCoordinate = CityCoordinate.fromLatLng(
        const LatLng(-20.0, -40.0),
      );
      mapController.locationFeedbackStateStreamValue.addValue(
        MapLocationFeedbackState(
          kind: MapLocationFeedbackKind.live,
          resolutionPhase: LocationResolutionPhase.resolved,
          settings: LocationOriginSettings.userLiveLocation(),
          targetCoordinate: resolvedCoordinate,
        ),
      );
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
    'navigate-to-user action stays enabled with home badge for fixed manual location',
    (tester) async {
      final poiRepository = _FakePoiRepository();
      final userLocationRepository = _FakeUserLocationRepository();
      final telemetryRepository = _FakeTelemetryRepository();
      final fixedCoordinate = CityCoordinate.fromLatLng(
        const LatLng(-20.011, -40.022),
      );
      final mapController = _buildMapScreenController(
        poiRepository: poiRepository,
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetryRepository,
      );
      mapController.locationFeedbackStateStreamValue.addValue(
        MapLocationFeedbackState(
          kind: MapLocationFeedbackKind.fixedManual,
          resolutionPhase: LocationResolutionPhase.resolved,
          settings: LocationOriginSettings.userFixedLocation(
            fixedLocationReference: fixedCoordinate,
          ),
          targetCoordinate: fixedCoordinate,
        ),
      );
      final fabController = FabMenuController(poiRepository: poiRepository)
        ..setExpanded(true)
        ..setCondensed(false);

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

      final navigateFab = tester.widget<FloatingActionButton>(
        find.ancestor(
          of: find.text('Ir para você'),
          matching: find.byType(FloatingActionButton),
        ),
      );
      expect(navigateFab.onPressed, isNotNull);
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);

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
      final mapController = _buildMapScreenController(
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
