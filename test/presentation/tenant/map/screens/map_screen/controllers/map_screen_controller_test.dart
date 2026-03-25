import 'dart:async';

import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/events/poi_update_event.dart';
import 'package:belluga_now/domain/map/filters/main_filter_option.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_mode.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/map_region_definition.dart';
import 'package:belluga_now/domain/map/queries/poi_query.dart';
import 'package:belluga_now/domain/map/ride_share_provider.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_address_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_description_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_name_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_priority_value.dart';
import 'package:belluga_now/domain/repositories/city_map_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/poi_repository.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
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
  Future<bool> logEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async {
    events.add(
      _LoggedEvent(
        event: event,
        eventName: eventName,
        properties: properties,
      ),
    );
    return true;
  }

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async {
    final handle = EventTrackerTimedEventHandle('handle-${_handleSeed++}');
    activeTimedEvents.add(
      _TimedEvent(
        handle: handle,
        event: event,
        eventName: eventName,
        properties: properties,
      ),
    );
    return handle;
  }

  @override
  Future<bool> finishTimedEvent(EventTrackerTimedEventHandle handle) async {
    final index = activeTimedEvents.indexWhere(
      (entry) => entry.handle.id == handle.id,
    );
    if (index == -1) {
      return true;
    }
    final entry = activeTimedEvents.removeAt(index);
    events.add(
      _LoggedEvent(
        event: entry.event,
        eventName: entry.eventName,
        properties: entry.properties,
      ),
    );
    return true;
  }

  @override
  Future<bool> flushTimedEvents() async {
    return true;
  }

  @override
  Future<bool> mergeIdentity({required String previousUserId}) async => true;

  @override
  void setScreenContext(Map<String, dynamic>? screenContext) {}

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
  @override
  final StreamValue<LocationResolutionPhase>
      locationResolutionPhaseStreamValue = StreamValue<LocationResolutionPhase>(
    defaultValue: LocationResolutionPhase.unknown,
  );

  @override
  Future<void> ensureLoaded() async {}

  @override
  Future<void> setLastKnownAddress(String? address) async {}

  @override
  Future<bool> warmUpIfPermitted() async => false;

  @override
  Future<bool> refreshIfPermitted(
      {Duration minInterval = const Duration(seconds: 30)}) async {
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
    required String stackKey,
  }) async {
    lastStackQuery = query;
    lastStackKey = stackKey;
    if (throwOnFetchStackItems) {
      throw Exception('forced stack fetch failure');
    }
    return nextStackItems;
  }

  @override
  Future<CityPoiModel?> fetchPoiByReference({
    required String refType,
    required String refId,
  }) async {
    lastLookupRefType = refType;
    lastLookupRefId = refId;
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
  Future<String> fetchFallbackEventImage() async => '';

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
  final StreamController<MapEvent> _events =
      StreamController<MapEvent>.broadcast();

  @override
  Stream<MapEvent> get mapEventStream => _events.stream;

  @override
  bool move(
    LatLng center,
    double zoom, {
    Offset offset = Offset.zero,
    String? id,
  }) {
    throw StateError('map not ready');
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
  MapCamera get camera => throw StateError('map not ready');

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
    refType: refType,
    refId: refId,
    stackKey: stackKey,
    stackCount: stackCount,
    stackItems: stackItems,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapScreenController telemetry', () {
    late _FakeTelemetryRepository telemetry;
    late _FakeCityMapRepository mapRepository;
    late _FakeUserLocationRepository userLocationRepository;
    late MapScreenController controller;

    setUp(() {
      telemetry = _FakeTelemetryRepository();
      mapRepository = _FakeCityMapRepository();
      userLocationRepository = _FakeUserLocationRepository();
      final poiRepository = PoiRepository(
        dataSource: mapRepository,
      );
      controller = MapScreenController(
        poiRepository: poiRepository,
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
      );
    });

    tearDown(() {
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
        PoiFilterCategory(
          key: 'nature',
          label: 'Natureza',
          tags: const {},
        ),
      );
      await _flushMicrotasks();

      expect(mapRepository.lastQuery, isNotNull);
      expect(mapRepository.lastQuery?.categoryKeys, equals({'nature'}));
      expect(controller.filterModeStreamValue.value, PoiFilterMode.server);
    });

    test('applies catalog filter query metadata when available', () async {
      controller.toggleCatalogCategoryFilter(
        PoiFilterCategory(
          key: 'event',
          label: 'Eventos agora',
          tags: const {},
          serverQuery: PoiFilterServerQuery(
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
      expect(mapRepository.lastQuery?.source, equals('event'));
      expect(mapRepository.lastQuery?.types, equals({'show'}));
      expect(mapRepository.lastQuery?.categoryKeys, equals({'culture'}));
      expect(mapRepository.lastQuery?.tags, equals({'live'}));
      expect(
        mapRepository.lastQuery?.taxonomy,
        equals({'music_genre:rock'}),
      );
      expect(controller.filterModeStreamValue.value, PoiFilterMode.server);
    });

    test(
      'supports source/types query metadata without category key fallback',
      () async {
        controller.toggleCatalogCategoryFilter(
          PoiFilterCategory(
            key: 'artists',
            label: 'Artistas',
            tags: const {},
            serverQuery: PoiFilterServerQuery(
              source: 'account_profile',
              types: {'artist'},
              taxonomy: {'music_genre:jazz'},
              tags: {'live'},
            ),
          ),
        );
        await _flushMicrotasks();

        expect(mapRepository.lastQuery, isNotNull);
        expect(mapRepository.lastQuery?.categoryKeys, isNull);
        expect(mapRepository.lastQuery?.source, equals('account_profile'));
        expect(mapRepository.lastQuery?.types, equals({'artist'}));
        expect(mapRepository.lastQuery?.tags, equals({'live'}));
        expect(mapRepository.lastQuery?.taxonomy, equals({'music_genre:jazz'}));
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
        PoiQuery(categoryKeys: {'event'}),
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
        PoiFilterTaxonomyTerm(
          type: 'cuisine',
          value: 'italian',
          label: 'Italiana',
          count: 4,
        ),
      );
      await _flushMicrotasks();

      expect(mapRepository.lastQuery, isNotNull);
      expect(
        mapRepository.lastQuery?.taxonomy,
        equals({'cuisine:italian'}),
      );
      expect(controller.filterModeStreamValue.value, PoiFilterMode.server);
    });

    test('locks filter interactions while a filter reload is in flight',
        () async {
      final firstRequest = Completer<List<CityPoiModel>>();
      mapRepository.queuedFetchCompleters.add(firstRequest);

      controller.toggleCatalogCategoryFilter(
        PoiFilterCategory(
          key: 'events',
          label: 'Eventos',
          tags: const {},
          serverQuery: PoiFilterServerQuery(
            source: 'event',
          ),
        ),
      );
      await _flushMicrotasks();

      controller.toggleCatalogCategoryFilter(
        PoiFilterCategory(
          key: 'beach',
          label: 'Praias',
          tags: const {},
          serverQuery: PoiFilterServerQuery(
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
        PoiFilterCategory(
          key: 'beach',
          label: 'Praias',
          tags: const {},
          serverQuery: PoiFilterServerQuery(
            source: 'static_asset',
            types: {'beach_spot'},
          ),
        ),
      );
      await _flushMicrotasks();

      expect(mapRepository.fetchPointsCallCount, 2);
    });

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
        PoiQuery(categoryKeys: {'event'}),
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
      expect(mapRepository.lastQuery?.searchTerm, 'pizza');
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

    test('keeps auto-centering on user when no initial poi query is provided',
        () async {
      await controller.init();
      await _flushMicrotasks();

      expect(userLocationRepository.refreshIfPermittedCallCount, 1);
      expect(userLocationRepository.resolveUserLocationCallCount, 1);
    });

    test('init does not throw when map readiness times out before centering',
        () async {
      final notReadyMapController = _NotReadyMapController();
      final localController = MapScreenController(
        poiRepository: PoiRepository(dataSource: mapRepository),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapController: notReadyMapController,
      );
      addTearDown(() async {
        await localController.onDispose();
        notReadyMapController.dispose();
      });

      userLocationRepository.userLocationStreamValue
          .addValue(_buildCoordinate('-20.1000', '-40.1000'));

      await expectLater(localController.init(), completes);
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

      final localController = MapScreenController(
        poiRepository: PoiRepository(dataSource: mapRepository),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapController: fakeMapController,
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
