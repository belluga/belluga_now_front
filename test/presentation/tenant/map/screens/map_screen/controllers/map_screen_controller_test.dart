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
  Future<void> ensureLoaded() async {}

  @override
  Future<void> setLastKnownAddress(String? address) async {}

  @override
  Future<bool> warmUpIfPermitted() async => false;

  @override
  Future<bool> refreshIfPermitted(
      {Duration minInterval = const Duration(seconds: 30)}) async {
    return false;
  }

  @override
  Future<String?> resolveUserLocation() async => null;

  @override
  Future<bool> startTracking(
      {LocationTrackingMode mode = LocationTrackingMode.mapForeground}) async {
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
  List<CityPoiModel> nextPois = const <CityPoiModel>[];
  bool throwOnFetchPoints = false;
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
  }) async =>
      const [];

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

CityPoiModel _buildPoi({String id = 'poi-1'}) {
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
      expect(controller.filteredPoisStreamValue.value, hasLength(1));

      controller.selectPoi(_buildPoi(id: 'poi-a'));
      expect(controller.selectedPoiStreamValue.value, isNotNull);

      mapRepository.throwOnFetchPoints = true;
      await controller.loadPois(
        PoiQuery(categoryKeys: {'event'}),
        loadingMessage: 'Aplicando filtros...',
      );

      expect(controller.filteredPoisStreamValue.value, isEmpty);
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
        controller.filteredPoisStreamValue.value.map((poi) => poi.id),
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
  });
}
