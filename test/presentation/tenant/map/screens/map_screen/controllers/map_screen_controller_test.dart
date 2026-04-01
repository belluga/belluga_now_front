import 'dart:async';

import 'package:belluga_now/application/router/guards/location_permission_gate_runtime.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/app_theme_mode_value.dart';
import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/events/poi_update_event.dart';
import 'package:belluga_now/domain/map/filters/main_filter_option.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_mode.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/map_region_definition.dart';
import 'package:belluga_now/domain/map/projections/city_poi_stack_items.dart';
import 'package:belluga_now/domain/map/queries/poi_query.dart';
import 'package:belluga_now/domain/map/ride_share_provider.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_address_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_description_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_name_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_boolean_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_count_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_image_uri_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_key_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_label_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_source_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_taxonomy_term_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_taxonomy_token_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_taxonomy_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_hex_color_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_icon_symbol_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_priority_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_stack_count_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_stack_key_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_tag_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/city_map_repository_contract.dart';
import 'package:belluga_now/domain/repositories/poi_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/infrastructure/services/telemetry/telemetry_properties_codec.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/infrastructure/repositories/poi_repository.dart';
import 'package:belluga_now/infrastructure/services/location_origin_service.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/misc/move_and_rotate_result.dart';
import 'package:latlong2/latlong.dart';
import 'package:stream_value/core/stream_value.dart';

class _LoggedEvent {
  _LoggedEvent({
    required this.event,
    required this.eventName,
    required this.properties,
  });

  final EventTrackerEvents event;
  final String? eventName;
  final Map<String, dynamic>? properties;
}

class _TimedEvent {
  _TimedEvent({
    required this.handle,
    required this.event,
    required this.eventName,
    required this.properties,
  });

  final EventTrackerTimedEventHandle handle;
  final EventTrackerEvents event;
  final String? eventName;
  final Map<String, dynamic>? properties;
}

class _FakeTelemetryRepository implements TelemetryRepositoryContract {
  final List<_LoggedEvent> events = [];
  final List<_TimedEvent> activeTimedEvents = [];
  int _handleSeed = 0;

  @override
  Future<TelemetryRepositoryContractPrimBool> logEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async {
    events.add(
      _LoggedEvent(
        event: event,
        eventName: eventName?.value,
        properties: properties == null
            ? null
            : TelemetryPropertiesCodec.toRawMap(properties),
      ),
    );
    return telemetryRepoBool(true);
  }

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async {
    final handle = EventTrackerTimedEventHandle('handle-${_handleSeed++}');
    activeTimedEvents.add(
      _TimedEvent(
        handle: handle,
        event: event,
        eventName: eventName?.value,
        properties: properties == null
            ? null
            : TelemetryPropertiesCodec.toRawMap(properties),
      ),
    );
    return handle;
  }

  @override
  Future<TelemetryRepositoryContractPrimBool> finishTimedEvent(
      EventTrackerTimedEventHandle handle) async {
    final index = activeTimedEvents.indexWhere(
      (entry) => entry.handle.id == handle.id,
    );
    if (index == -1) {
      return telemetryRepoBool(true);
    }
    final entry = activeTimedEvents.removeAt(index);
    events.add(
      _LoggedEvent(
        event: entry.event,
        eventName: entry.eventName,
        properties: entry.properties,
      ),
    );
    return telemetryRepoBool(true);
  }

  @override
  Future<TelemetryRepositoryContractPrimBool> flushTimedEvents() async {
    return telemetryRepoBool(true);
  }

  @override
  Future<TelemetryRepositoryContractPrimBool> mergeIdentity(
          {required TelemetryRepositoryContractPrimString
              previousUserId}) async =>
      telemetryRepoBool(true);

  @override
  void setScreenContext(TelemetryRepositoryContractPrimMap? screenContext) {}

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;
}

class _FakeUserLocationRepository implements UserLocationRepositoryContract {
  int refreshIfPermittedCallCount = 0;
  int resolveUserLocationCallCount = 0;
  int startTrackingCallCount = 0;
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
  Future<void> setLastKnownAddress(Object? address) async {}

  @override
  Future<bool> warmUpIfPermitted() async => false;

  @override
  Future<bool> refreshIfPermitted({Object? minInterval}) async {
    refreshIfPermittedCallCount += 1;
    final completer = refreshIfPermittedCompleter;
    if (completer != null) {
      return completer.future;
    }
    return false;
  }

  @override
  Future<String?> resolveUserLocation() async {
    resolveUserLocationCallCount += 1;
    return null;
  }

  @override
  Future<bool> startTracking(
      {LocationTrackingMode mode = LocationTrackingMode.mapForeground}) async {
    startTrackingCallCount += 1;
    return true;
  }

  @override
  Future<void> stopTracking() async {}

  void dispose() {
    userLocationStreamValue.dispose();
    lastKnownLocationStreamValue.dispose();
    lastKnownCapturedAtStreamValue.dispose();
    lastKnownAccuracyStreamValue.dispose();
    lastKnownAddressStreamValue.dispose();
  }
}

class _FakeCityMapRepository implements CityMapRepositoryContract {
  _FakeCityMapRepository() {
    final latitude = LatitudeValue()..parse('-20.0');
    final longitude = LongitudeValue()..parse('-40.0');
    _defaultCenter = CityCoordinate(
      latitudeValue: latitude,
      longitudeValue: longitude,
    );
  }

  late final CityCoordinate _defaultCenter;
  final StreamController<PoiUpdateEvent?> _poiEventsController =
      StreamController<PoiUpdateEvent?>.broadcast();
  PoiQuery? lastQuery;
  PoiQuery? lastStackQuery;
  String? lastStackKey;
  String? lastLookupRefType;
  String? lastLookupRefId;
  List<CityPoiModel> nextPois = const <CityPoiModel>[];
  List<CityPoiModel> nextStackItems = const <CityPoiModel>[];
  CityPoiModel? nextLookupPoi;
  bool throwOnFetchPoints = false;
  bool throwOnFetchStackItems = false;
  bool throwOnLookupPoi = false;
  int fetchPointsCallCount = 0;
  final List<Completer<List<CityPoiModel>>> queuedFetchCompleters =
      <Completer<List<CityPoiModel>>>[];

  @override
  Future<List<CityPoiModel>> fetchPoints(PoiQuery query) async {
    fetchPointsCallCount += 1;
    lastQuery = query;
    if (queuedFetchCompleters.isNotEmpty) {
      final completer = queuedFetchCompleters.removeAt(0);
      return completer.future;
    }
    if (throwOnFetchPoints) {
      throw Exception('forced fetch failure');
    }
    return nextPois;
  }

  @override
  Future<List<CityPoiModel>> fetchStackItems({
    required PoiQuery query,
    required PoiStackKeyValue stackKey,
  }) async {
    lastStackQuery = query;
    lastStackKey = stackKey.value;
    if (throwOnFetchStackItems) {
      throw Exception('forced stack fetch failure');
    }
    return nextStackItems;
  }

  @override
  Future<CityPoiModel?> fetchPoiByReference({
    required PoiReferenceTypeValue refType,
    required PoiReferenceIdValue refId,
  }) async {
    lastLookupRefType = refType.value;
    lastLookupRefId = refId.value;
    if (throwOnLookupPoi) {
      throw Exception('forced lookup failure');
    }
    return nextLookupPoi;
  }

  @override
  Future<PoiFilterOptions> fetchFilters() async =>
      PoiFilterOptions(categories: const []);

  @override
  Future<List<MainFilterOption>> fetchMainFilters() async => const [];

  @override
  Future<List<MapRegionDefinition>> fetchRegions() async => const [];

  @override
  Future<ThumbUriValue> fetchFallbackEventImage() async {
    final value = ThumbUriValue(
      defaultValue: Uri.parse('asset://event-placeholder'),
    );
    value.parse(value.defaultValue.toString());
    return value;
  }

  @override
  Stream<PoiUpdateEvent?> get poiEvents => _poiEventsController.stream;

  @override
  CityCoordinate defaultCenter() => _defaultCenter;

  @override
  void dispose() {
    _poiEventsController.close();
  }
}

class _FakeMapController implements MapController {
  _FakeMapController()
      : _camera = MapCamera.initialCamera(
          const MapOptions(
            initialCenter: LatLng(-20.0, -40.0),
            initialZoom: 16,
          ),
        );

  final StreamController<MapEvent> _events =
      StreamController<MapEvent>.broadcast();
  MapCamera _camera;
  int moveCallCount = 0;
  LatLng? lastMoveCenter;
  double? lastMoveZoom;

  @override
  Stream<MapEvent> get mapEventStream => _events.stream;

  @override
  bool move(
    LatLng center,
    double zoom, {
    Offset offset = Offset.zero,
    String? id,
  }) {
    moveCallCount += 1;
    lastMoveCenter = center;
    lastMoveZoom = zoom;
    _camera = _camera.withPosition(center: center, zoom: zoom);
    return true;
  }

  @override
  bool rotate(double degree, {String? id}) => false;

  @override
  MoveAndRotateResult rotateAroundPoint(
    double degree, {
    Offset? offset,
    String? id,
  }) {
    return const (moveSuccess: false, rotateSuccess: false);
  }

  @override
  MoveAndRotateResult moveAndRotate(
    LatLng center,
    double zoom,
    double degree, {
    String? id,
  }) {
    return const (moveSuccess: false, rotateSuccess: false);
  }

  @override
  bool fitCamera(CameraFit cameraFit) => false;

  @override
  MapCamera get camera => _camera;

  @override
  void dispose() {
    _events.close();
  }

  void emitMapEvent() {
    final current = _camera;
    _events.add(
      MapEventMove(
        source: MapEventSource.nonRotatedSizeChange,
        oldCamera: current,
        camera: current,
      ),
    );
  }
}

class _NotReadyMapController implements MapController {
  _NotReadyMapController()
      : _camera = MapCamera.initialCamera(
          const MapOptions(
            initialCenter: LatLng(-20.0, -40.0),
            initialZoom: 16,
          ),
        );

  final StreamController<MapEvent> _events =
      StreamController<MapEvent>.broadcast();
  MapCamera _camera;
  bool isReady = false;
  int moveCallCount = 0;
  LatLng? lastMoveCenter;
  double? lastMoveZoom;

  @override
  Stream<MapEvent> get mapEventStream => _events.stream;

  @override
  bool move(
    LatLng center,
    double zoom, {
    Offset offset = Offset.zero,
    String? id,
  }) {
    if (!isReady) {
      throw StateError('map not ready');
    }
    moveCallCount += 1;
    lastMoveCenter = center;
    lastMoveZoom = zoom;
    _camera = _camera.withPosition(center: center, zoom: zoom);
    return true;
  }

  @override
  bool rotate(double degree, {String? id}) => false;

  @override
  MoveAndRotateResult rotateAroundPoint(
    double degree, {
    Offset? offset,
    String? id,
  }) {
    return const (moveSuccess: false, rotateSuccess: false);
  }

  @override
  MoveAndRotateResult moveAndRotate(
    LatLng center,
    double zoom,
    double degree, {
    String? id,
  }) {
    return const (moveSuccess: false, rotateSuccess: false);
  }

  @override
  bool fitCamera(CameraFit cameraFit) => false;

  @override
  MapCamera get camera {
    if (!isReady) {
      throw StateError('map not ready');
    }
    return _camera;
  }

  @override
  void dispose() {
    _events.close();
  }
}

CityPoiModel _buildPoi({
  String id = 'poi-1',
  String refType = 'static',
  String refId = 'poi-1',
  String stackKey = '',
  int stackCount = 1,
  List<CityPoiModel>? stackItems,
}) {
  final idValue = CityPoiIdValue()..parse(id);
  final nameValue = CityPoiNameValue()..parse('Beach Bar');
  final descriptionValue = CityPoiDescriptionValue()..parse('Nice place');
  final addressValue = CityPoiAddressValue()..parse('Av. Brasil');
  final priorityValue = PoiPriorityValue()..parse('1');
  final refTypeValue = PoiReferenceTypeValue()..parse(refType);
  final refIdValue = PoiReferenceIdValue()..parse(refId);
  final stackKeyValue = PoiStackKeyValue()..parse(stackKey);
  final stackCountValue = PoiStackCountValue()..parse(stackCount.toString());
  final stackItemCollection = CityPoiStackItems();
  for (final item in stackItems ?? const <CityPoiModel>[]) {
    stackItemCollection.add(item);
  }
  final latitude = LatitudeValue()..parse('-20.0');
  final longitude = LongitudeValue()..parse('-40.0');
  final coordinate = CityCoordinate(
    latitudeValue: latitude,
    longitudeValue: longitude,
  );

  return CityPoiModel(
    idValue: idValue,
    nameValue: nameValue,
    descriptionValue: descriptionValue,
    addressValue: addressValue,
    category: CityPoiCategory.restaurant,
    coordinate: coordinate,
    priorityValue: priorityValue,
    refTypeValue: refTypeValue,
    refIdValue: refIdValue,
    stackKeyValue: stackKeyValue,
    stackCountValue: stackCountValue,
    stackItems: stackItemCollection,
  );
}

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
}

CityCoordinate _buildCoordinate(String latitudeRaw, String longitudeRaw) {
  final latitude = LatitudeValue()..parse(latitudeRaw);
  final longitude = LongitudeValue()..parse(longitudeRaw);
  return CityCoordinate(
    latitudeValue: latitude,
    longitudeValue: longitude,
  );
}

PoiQuery _buildQuery({
  Set<String>? categoryKeys,
}) {
  return PoiQuery(
    categoryKeyValues:
        categoryKeys == null ? null : _buildFilterKeyValues(categoryKeys),
  );
}

Set<String>? _queryCategoryKeys(PoiQuery? query) {
  return query?.categoryKeyValues
      ?.map((entry) => entry.value.trim().toLowerCase())
      .where((entry) => entry.isNotEmpty)
      .toSet();
}

String? _querySource(PoiQuery? query) {
  final raw = query?.sourceValue?.value.trim().toLowerCase();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return raw;
}

Set<String>? _queryTypes(PoiQuery? query) {
  return query?.typeValues
      ?.map((entry) => entry.value.trim().toLowerCase())
      .where((entry) => entry.isNotEmpty)
      .toSet();
}

Set<String>? _queryTags(PoiQuery? query) {
  return query?.tagValues
      ?.map((entry) => entry.value.trim().toLowerCase())
      .where((entry) => entry.isNotEmpty)
      .toSet();
}

Set<String>? _queryTaxonomy(PoiQuery? query) {
  return query?.taxonomyTokenValues
      ?.map((entry) => entry.value.trim().toLowerCase())
      .where((entry) => entry.isNotEmpty)
      .toSet();
}

String? _querySearchTerm(PoiQuery? query) {
  final raw = query?.searchTermValue?.value.trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return raw;
}

PoiFilterTaxonomyTerm _buildTaxonomyTerm({
  required String type,
  required String value,
  required String label,
  required int count,
}) {
  return PoiFilterTaxonomyTerm(
    typeValue: _buildTaxonomyTypeValue(type),
    valueValue: _buildTaxonomyTermValue(value),
    labelValue: _buildFilterLabelValue(label),
    countValue: _buildFilterCountValue(count),
  );
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

PoiFilterTaxonomyTypeValue _buildTaxonomyTypeValue(String raw) {
  final value = PoiFilterTaxonomyTypeValue();
  value.parse(raw.trim().toLowerCase());
  return value;
}

PoiFilterTaxonomyTermValue _buildTaxonomyTermValue(String raw) {
  final value = PoiFilterTaxonomyTermValue();
  value.parse(raw.trim().toLowerCase());
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapScreenController telemetry', () {
    late _FakeTelemetryRepository telemetry;
    late _FakeCityMapRepository mapRepository;
    late _FakeUserLocationRepository userLocationRepository;
    late MapScreenController controller;

    setUp(() {
      LocationPermissionGateRuntime.resetForTesting();
      telemetry = _FakeTelemetryRepository();
      mapRepository = _FakeCityMapRepository();
      userLocationRepository = _FakeUserLocationRepository();
      final poiRepository = PoiRepository(
        dataSource: mapRepository,
      );
      controller = _buildMapController(
        poiRepository: poiRepository,
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        appData: _buildAppData(),
      );
    });

    tearDown(() {
      LocationPermissionGateRuntime.resetForTesting();
      mapRepository.dispose();
      userLocationRepository.dispose();
      controller.onDispose();
    });

    test('logs poi_opened when selecting a poi', () async {
      final poi = _buildPoi(id: 'poi-123');

      controller.selectPoi(poi);
      await _flushMicrotasks();
      controller.clearSelectedPoi();
      await _flushMicrotasks();

      expect(telemetry.events, hasLength(1));
      final event = telemetry.events.first;
      expect(event.event, EventTrackerEvents.poiOpened);
      expect(event.eventName, 'poi_opened');
      expect(event.properties?['poi_id'], 'poi-123');
    });

    test('logs search submit and clear events', () async {
      await controller.searchPois('pizza');
      await _flushMicrotasks();

      await controller.clearSearch();
      await _flushMicrotasks();

      expect(telemetry.events, hasLength(2));
      expect(telemetry.events[0].eventName, 'map_search_submitted');
      expect(telemetry.events[0].event, EventTrackerEvents.search);
      expect(telemetry.events[0].properties?['query_len'], 5);
      expect(telemetry.events[1].eventName, 'map_search_cleared');
      expect(telemetry.events[1].event, EventTrackerEvents.buttonClick);
      expect(telemetry.events[1].properties?['previous_query_len'], 5);
    });

    test('logs filter apply and clear events', () async {
      controller.applyFilterMode(PoiFilterMode.events);
      await _flushMicrotasks();

      controller.clearFilters();
      await _flushMicrotasks();

      expect(telemetry.events, hasLength(2));
      expect(telemetry.events[0].eventName, 'map_main_filter_applied');
      expect(telemetry.events[0].event, EventTrackerEvents.selectItem);
      expect(telemetry.events[0].properties?['filter_mode'], 'events');
      expect(telemetry.events[1].eventName, 'map_main_filter_cleared');
      expect(telemetry.events[1].event, EventTrackerEvents.buttonClick);
    });

    test('applies dynamic category filters using category keys', () async {
      controller.toggleCatalogCategoryFilter(
        _buildCategory(
          key: 'nature',
          label: 'Natureza',
          tags: const {},
        ),
      );
      await _flushMicrotasks();

      expect(mapRepository.lastQuery, isNotNull);
      expect(_queryCategoryKeys(mapRepository.lastQuery), equals({'nature'}));
      expect(controller.filterModeStreamValue.value, PoiFilterMode.server);
    });

    test('applies catalog filter query metadata when available', () async {
      controller.toggleCatalogCategoryFilter(
        _buildCategory(
          key: 'event',
          label: 'Eventos agora',
          tags: const {},
          serverQuery: _buildServerQuery(
            source: 'event',
            types: {'show'},
            categoryKeys: {'culture'},
            taxonomy: {'music_genre:rock'},
            tags: {'live'},
          ),
        ),
      );
      await _flushMicrotasks();

      expect(mapRepository.lastQuery, isNotNull);
      expect(_querySource(mapRepository.lastQuery), equals('event'));
      expect(_queryTypes(mapRepository.lastQuery), equals({'show'}));
      expect(_queryCategoryKeys(mapRepository.lastQuery), equals({'culture'}));
      expect(_queryTags(mapRepository.lastQuery), equals({'live'}));
      expect(
        _queryTaxonomy(mapRepository.lastQuery),
        equals({'music_genre:rock'}),
      );
      expect(controller.filterModeStreamValue.value, PoiFilterMode.server);
    });

    test(
      'supports source/types query metadata without category key fallback',
      () async {
        controller.toggleCatalogCategoryFilter(
          _buildCategory(
            key: 'artists',
            label: 'Artistas',
            tags: const {},
            serverQuery: _buildServerQuery(
              source: 'account_profile',
              types: {'artist'},
              taxonomy: {'music_genre:jazz'},
              tags: {'live'},
            ),
          ),
        );
        await _flushMicrotasks();

        expect(mapRepository.lastQuery, isNotNull);
        expect(_queryCategoryKeys(mapRepository.lastQuery), isNull);
        expect(
            _querySource(mapRepository.lastQuery), equals('account_profile'));
        expect(_queryTypes(mapRepository.lastQuery), equals({'artist'}));
        expect(_queryTags(mapRepository.lastQuery), equals({'live'}));
        expect(_queryTaxonomy(mapRepository.lastQuery),
            equals({'music_genre:jazz'}));
      },
    );

    test('clears stale map data when loadPois fails', () async {
      mapRepository.nextPois = <CityPoiModel>[
        _buildPoi(id: 'poi-a'),
      ];
      await controller.loadPois(PoiQuery());
      expect(
        controller.filteredPoisStreamValue.value ?? const <CityPoiModel>[],
        hasLength(1),
      );

      controller.selectPoi(_buildPoi(id: 'poi-a'));
      expect(controller.selectedPoiStreamValue.value, isNotNull);

      mapRepository.throwOnFetchPoints = true;
      await controller.loadPois(
        _buildQuery(categoryKeys: {'event'}),
        loadingMessage: 'Aplicando filtros...',
      );

      expect(
        controller.filteredPoisStreamValue.value ?? const <CityPoiModel>[],
        isEmpty,
      );
      expect(controller.selectedPoiStreamValue.value, isNull);
    });

    test('applies taxonomy filter tokens to map query', () async {
      controller.toggleTaxonomyFilter(
        _buildTaxonomyTerm(
          type: 'cuisine',
          value: 'italian',
          label: 'Italiana',
          count: 4,
        ),
      );
      await _flushMicrotasks();

      expect(mapRepository.lastQuery, isNotNull);
      expect(
        _queryTaxonomy(mapRepository.lastQuery),
        equals({'cuisine:italian'}),
      );
      expect(controller.filterModeStreamValue.value, PoiFilterMode.server);
    });

    test(
      'taxonomy filter activation clears active catalog filter context',
      () async {
        controller.toggleCatalogCategoryFilter(
          _buildCategory(
            key: 'beach',
            label: 'Praias',
            tags: const {},
            serverQuery: _buildServerQuery(
              source: 'static_asset',
              types: {'beach_spot'},
            ),
          ),
        );
        await _flushMicrotasks();

        expect(controller.activeCatalogFilterKeyStreamValue.value, 'beach');

        controller.toggleTaxonomyFilter(
          _buildTaxonomyTerm(
            type: 'cuisine',
            value: 'italian',
            label: 'Italiana',
            count: 4,
          ),
        );
        await _flushMicrotasks();

        expect(controller.activeCatalogFilterKeyStreamValue.value, isNull);
        expect(controller.activeCategoryKeysStreamValue.value, isEmpty);
        expect(
          controller.activeTaxonomyTokensStreamValue.value,
          equals({'cuisine:italian'}),
        );
        expect(_querySource(mapRepository.lastQuery), isNull);
        expect(_queryTypes(mapRepository.lastQuery), isNull);
        expect(_queryTaxonomy(mapRepository.lastQuery),
            equals({'cuisine:italian'}));
      },
    );

    test('toggling same taxonomy token again clears filters', () async {
      final term = _buildTaxonomyTerm(
        type: 'cuisine',
        value: 'italian',
        label: 'Italiana',
        count: 4,
      );

      controller.toggleTaxonomyFilter(term);
      await _flushMicrotasks();
      expect(controller.filterModeStreamValue.value, PoiFilterMode.server);

      controller.toggleTaxonomyFilter(term);
      await _flushMicrotasks();

      expect(controller.filterModeStreamValue.value, PoiFilterMode.none);
      expect(controller.activeTaxonomyTokensStreamValue.value, isEmpty);
      expect(controller.activeCategoryKeysStreamValue.value, isEmpty);
      expect(controller.activeCatalogFilterKeyStreamValue.value, isNull);
    });

    test('locks filter interactions while a filter reload is in flight',
        () async {
      final firstRequest = Completer<List<CityPoiModel>>();
      mapRepository.queuedFetchCompleters.add(firstRequest);

      controller.toggleCatalogCategoryFilter(
        _buildCategory(
          key: 'events',
          label: 'Eventos',
          tags: const {},
          serverQuery: _buildServerQuery(
            source: 'event',
          ),
        ),
      );
      await _flushMicrotasks();

      controller.toggleCatalogCategoryFilter(
        _buildCategory(
          key: 'beach',
          label: 'Praias',
          tags: const {},
          serverQuery: _buildServerQuery(
            source: 'static_asset',
            types: {'beach_spot'},
          ),
        ),
      );
      await _flushMicrotasks();

      expect(mapRepository.fetchPointsCallCount, 1);
      expect(
        controller.filterInteractionLockedStreamValue.value,
        isTrue,
      );

      firstRequest.complete(<CityPoiModel>[]);
      await _flushMicrotasks();
      await _flushMicrotasks();

      expect(
        controller.filterInteractionLockedStreamValue.value,
        isFalse,
      );

      controller.toggleCatalogCategoryFilter(
        _buildCategory(
          key: 'beach',
          label: 'Praias',
          tags: const {},
          serverQuery: _buildServerQuery(
            source: 'static_asset',
            types: {'beach_spot'},
          ),
        ),
      );
      await _flushMicrotasks();

      expect(mapRepository.fetchPointsCallCount, 2);
    });

    test(
      'applies marker override key only after catalog reload completes',
      () async {
        final firstRequest = Completer<List<CityPoiModel>>();
        mapRepository.queuedFetchCompleters.add(firstRequest);
        final category = _buildCategory(
          key: 'beach',
          label: 'Praias',
          tags: const {},
          overrideMarker: true,
          markerOverride: _buildIconMarkerOverride(
            icon: 'beach',
            colorHex: '#FF3300',
          ),
          serverQuery: _buildServerQuery(
            source: 'static_asset',
            types: {'beach_spot'},
          ),
        );

        expect(controller.appliedCatalogFilterKeyStreamValue.value, isNull);

        controller.toggleCatalogCategoryFilter(category);
        await _flushMicrotasks();

        expect(controller.activeCatalogFilterKeyStreamValue.value, 'beach');
        expect(controller.appliedCatalogFilterKeyStreamValue.value, isNull);

        firstRequest.complete(<CityPoiModel>[]);
        await _flushMicrotasks();
        await _flushMicrotasks();

        expect(controller.appliedCatalogFilterKeyStreamValue.value, 'beach');
      },
    );

    test('keeps the latest loadPois result after overlapping requests',
        () async {
      final firstRequest = Completer<List<CityPoiModel>>();
      final secondRequest = Completer<List<CityPoiModel>>();
      mapRepository.queuedFetchCompleters
        ..add(firstRequest)
        ..add(secondRequest);

      final firstPoi = _buildPoi(id: 'poi-first');
      final secondPoi = _buildPoi(id: 'poi-second');

      final firstFuture = controller.loadPois(PoiQuery());
      await _flushMicrotasks();
      final secondFuture = controller.loadPois(
        _buildQuery(categoryKeys: {'event'}),
      );
      await _flushMicrotasks();

      firstRequest.complete(<CityPoiModel>[firstPoi]);
      await _flushMicrotasks();

      secondRequest.complete(<CityPoiModel>[secondPoi]);
      await Future.wait<void>([firstFuture, secondFuture]);
      await _flushMicrotasks();

      expect(
        (controller.filteredPoisStreamValue.value ?? const <CityPoiModel>[])
            .map((poi) => poi.id),
        equals(<String>['poi-second']),
      );
    });

    test('refreshes query origin from the latest tracked user location',
        () async {
      final firstOrigin = _buildCoordinate('-20.1000', '-40.1000');
      final latestOrigin = _buildCoordinate('-20.2000', '-40.2000');

      userLocationRepository.userLocationStreamValue.addValue(firstOrigin);
      await controller.loadPois(PoiQuery());
      expect(mapRepository.lastQuery?.origin, firstOrigin);

      userLocationRepository.userLocationStreamValue.addValue(latestOrigin);
      await controller.searchPois('pizza');

      expect(mapRepository.lastQuery?.origin, latestOrigin);
      expect(_querySearchTerm(mapRepository.lastQuery), 'pizza');
    });

    test('logs directions and ride share events', () async {
      final poi = _buildPoi();

      controller.logDirectionsOpened(poi);
      controller.logRideShareClicked(
        provider: RideShareProvider.uber,
        poiId: poi.id,
      );
      await _flushMicrotasks();

      expect(telemetry.events, hasLength(2));
      expect(telemetry.events[0].eventName, 'map_directions_opened');
      expect(telemetry.events[0].event, EventTrackerEvents.viewContent);
      expect(telemetry.events[0].properties?['poi_id'], poi.id);
      expect(telemetry.events[1].eventName, 'map_ride_share_clicked');
      expect(telemetry.events[1].event, EventTrackerEvents.buttonClick);
      expect(telemetry.events[1].properties?['provider'], 'uber');
    });

    test(
        'hydrates selected poi from initial query when top-level list has match',
        () async {
      final targetPoi = _buildPoi(
        id: 'poi-target',
        refType: 'event',
        refId: 'evt-001',
        stackKey: 'stack-target',
      );
      mapRepository.nextPois = <CityPoiModel>[targetPoi];

      await controller.init(initialPoiQuery: 'event:evt-001');
      await _flushMicrotasks();

      expect(controller.selectedPoiStreamValue.value?.id, 'poi-target');
      expect(
        controller.statusMessageStreamValue.value,
        isNot('POI do link não foi encontrado.'),
      );
    });

    test('skips auto-centering on user when initial poi query is provided',
        () async {
      final targetPoi = _buildPoi(
        id: 'poi-target',
        refType: 'event',
        refId: 'evt-001',
      );
      mapRepository.nextPois = <CityPoiModel>[targetPoi];

      await controller.init(initialPoiQuery: 'event:evt-001');
      await _flushMicrotasks();

      expect(userLocationRepository.refreshIfPermittedCallCount, 1);
      expect(userLocationRepository.resolveUserLocationCallCount, 0);
    });

    test(
        'does not auto-center on user but still triggers permission resolution on plain map load',
        () async {
      await controller.init();
      await _flushMicrotasks();

      expect(userLocationRepository.refreshIfPermittedCallCount, 1);
      expect(userLocationRepository.resolveUserLocationCallCount, 1);
    });

    test(
        'soft-gate map entry skips interactive resolution and exposes fixed-location notice',
        () async {
      LocationPermissionGateRuntime.armSoftLocationFallbackEntry();

      await controller.init();
      await _flushMicrotasks();

      expect(userLocationRepository.refreshIfPermittedCallCount, 1);
      expect(userLocationRepository.resolveUserLocationCallCount, 0);
      expect(
        controller.softLocationNoticeStreamValue.value,
        'Sua localização não está disponível, por isso, usamos uma localização de referência para mostrar eventos e locais relevantes.',
      );
      expect(
        mapRepository.lastQuery?.origin?.latitude,
        mapRepository.defaultCenter().latitude,
      );
      expect(
        mapRepository.lastQuery?.origin?.longitude,
        mapRepository.defaultCenter().longitude,
      );
    });

    test('centerOnUser shows status when map is not ready yet', () async {
      final notReadyMapController = _NotReadyMapController();
      final localController = _buildMapController(
        poiRepository: PoiRepository(dataSource: mapRepository),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapController: notReadyMapController,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await localController.onDispose();
        notReadyMapController.dispose();
      });

      userLocationRepository.userLocationStreamValue
          .addValue(_buildCoordinate('-20.1000', '-40.1000'));

      await localController.centerOnUser();
      expect(
        localController.statusMessageStreamValue.value,
        'Mapa ainda está inicializando. Tente novamente.',
      );
    });

    test(
      'hydrates selected poi from stack query when poi is not in top-level list',
      () async {
        final topPoi = _buildPoi(
          id: 'poi-top',
          refType: 'event',
          refId: 'evt-top',
          stackKey: 'stack-abc',
          stackCount: 2,
        );
        final stackedTarget = _buildPoi(
          id: 'poi-stacked',
          refType: 'event',
          refId: 'evt-stacked',
          stackKey: 'stack-abc',
          stackCount: 2,
        );
        mapRepository.nextPois = <CityPoiModel>[topPoi];
        mapRepository.nextStackItems = <CityPoiModel>[
          topPoi,
          stackedTarget,
        ];

        await controller.init(
          initialPoiQuery: 'event:evt-stacked',
          initialPoiStackQuery: 'stack-abc',
        );
        await _flushMicrotasks();

        expect(mapRepository.lastStackKey, 'stack-abc');
        expect(controller.selectedPoiStreamValue.value?.id, 'poi-stacked');
        expect(
          controller.statusMessageStreamValue.value,
          isNot('POI do link não foi encontrado.'),
        );
      },
    );

    test(
      'hydrates selected poi from backend lookup when typed query is outside loaded payload',
      () async {
        mapRepository.nextPois = <CityPoiModel>[
          _buildPoi(
            id: 'poi-other',
            refType: 'event',
            refId: 'evt-other',
          ),
        ];
        mapRepository.nextLookupPoi = _buildPoi(
          id: 'poi-lookup',
          refType: 'event',
          refId: 'evt-lookup',
          stackKey: 'stack-lookup',
          stackCount: 2,
        );

        await controller.init(initialPoiQuery: 'event:evt-lookup');
        await _flushMicrotasks();

        expect(mapRepository.lastLookupRefType, 'event');
        expect(mapRepository.lastLookupRefId, 'evt-lookup');
        expect(controller.selectedPoiStreamValue.value?.id, 'poi-lookup');
        expect(
          controller.statusMessageStreamValue.value,
          isNot('POI do link não foi encontrado.'),
        );
      },
    );

    test(
      'hydrates initial poi before refreshIfPermitted completes',
      () async {
        final refreshCompleter = Completer<bool>();
        userLocationRepository.refreshIfPermittedCompleter = refreshCompleter;
        mapRepository.nextLookupPoi = _buildPoi(
          id: 'poi-lookup',
          refType: 'event',
          refId: 'evt-lookup',
        );

        var initCompleted = false;
        final initFuture = controller.init(initialPoiQuery: 'event:evt-lookup')
          ..then((_) => initCompleted = true);

        await _flushMicrotasks();
        await _flushMicrotasks();

        expect(mapRepository.lastLookupRefType, 'event');
        expect(mapRepository.lastLookupRefId, 'evt-lookup');
        expect(controller.selectedPoiStreamValue.value?.id, 'poi-lookup');
        expect(
          initCompleted,
          isFalse,
          reason: 'location refresh can continue while poi hydration resolves',
        );

        refreshCompleter.complete(false);
        await initFuture;
      },
    );

    test('sets deterministic status when initial poi query cannot be resolved',
        () async {
      mapRepository.nextPois = <CityPoiModel>[
        _buildPoi(
          id: 'poi-other',
          refType: 'event',
          refId: 'evt-other',
          stackKey: 'stack-other',
        ),
      ];

      await controller.init(initialPoiQuery: 'event:evt-missing');
      await _flushMicrotasks();

      expect(controller.selectedPoiStreamValue.value, isNull);
      expect(
        controller.statusMessageStreamValue.value,
        'POI do link não foi encontrado.',
      );
    });

    test('buildPoiQueryKey normalizes ref_type:ref_id key', () {
      final canonicalPoi = _buildPoi(
        id: 'poi-canonical',
        refType: 'EVENT',
        refId: 'EVT-9000',
      );

      expect(controller.buildPoiQueryKey(canonicalPoi), 'event:evt-9000');
    });

    test(
        'applies initial poi focus after first map event when deep link query is present',
        () async {
      final fakeMapController = _FakeMapController();
      final targetPoi = _buildPoi(
        id: 'poi-target',
        refType: 'event',
        refId: 'evt-001',
      );
      mapRepository.nextPois = <CityPoiModel>[targetPoi];

      final localController = _buildMapController(
        poiRepository: PoiRepository(dataSource: mapRepository),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapController: fakeMapController,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await localController.onDispose();
        fakeMapController.dispose();
      });

      await localController.init(initialPoiQuery: 'event:evt-001');
      await _flushMicrotasks();

      expect(localController.selectedPoiStreamValue.value?.id, 'poi-target');
      expect(fakeMapController.moveCallCount, 0);

      fakeMapController.emitMapEvent();
      await _flushMicrotasks();
      await _flushMicrotasks();

      expect(fakeMapController.moveCallCount, 1);
      expect(fakeMapController.lastMoveCenter, isNotNull);
      expect(fakeMapController.lastMoveCenter!.latitude, closeTo(-20.0, 1e-9));
      expect(
        fakeMapController.lastMoveCenter!.longitude,
        closeTo(-40.0, 1e-9),
      );

      fakeMapController.emitMapEvent();
      await _flushMicrotasks();

      expect(
        fakeMapController.moveCallCount,
        1,
        reason: 'initial focus must be applied exactly once',
      );
    });
  });
}

MapScreenController _buildMapController({
  required PoiRepositoryContract poiRepository,
  required UserLocationRepositoryContract userLocationRepository,
  required TelemetryRepositoryContract telemetryRepository,
  MapController? mapController,
  AppData? appData,
}) {
  final resolvedAppData = appData ?? _buildAppData();
  final appDataRepository = _FakeMapAppDataRepository(resolvedAppData);
  return MapScreenController(
    poiRepository: poiRepository,
    userLocationRepository: userLocationRepository,
    telemetryRepository: telemetryRepository,
    mapController: mapController,
    appData: resolvedAppData,
    locationOriginService: LocationOriginService(
      appDataRepository: appDataRepository,
      userLocationRepository: userLocationRepository,
    ),
  );
}

AppData _buildAppData() {
  final remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'main_domain': 'https://tenant.test',
    'profile_types': const [
      {
        'type': 'artist',
        'label': 'Artist',
        'allowed_taxonomies': [],
        'capabilities': {
          'is_favoritable': true,
          'is_poi_enabled': true,
        },
      },
    ],
    'domains': ['https://tenant.test'],
    'app_domains': const [],
    'theme_data_settings': {
      'brightness_default': 'light',
      'primary_seed_color': '#FFFFFF',
      'secondary_seed_color': '#000000',
    },
    'main_color': '#FFFFFF',
    'tenant_id': 'tenant-1',
    'telemetry': const {'trackers': []},
    'telemetry_context': const {'location_freshness_minutes': 5},
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
  };
  const localInfo = {
    'platformType': 'mobile',
    'hostname': 'tenant.test',
    'href': 'https://tenant.test',
    'port': null,
    'device': 'test-device',
  };
  return buildAppDataFromInitialization(
    remoteData: remoteData,
    localInfo: localInfo,
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
