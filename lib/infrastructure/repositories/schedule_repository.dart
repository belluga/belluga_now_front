import 'package:belluga_now/domain/map/geo_distance.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/schedule_repository_contract_values.dart';
import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/paged_events_result.dart';
import 'package:belluga_now/domain/schedule/value_objects/home_agenda_boolean_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/home_agenda_captured_at_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/home_agenda_page_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/home_agenda_search_query_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_page_dto.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class ScheduleRepository extends ScheduleRepositoryContract {
  static const double _homeAgendaCacheReuseMaxOriginJumpMeters = 1000.0;

  ScheduleRepository({
    ScheduleBackendContract? backend,
    BackendContract? backendContract,
  })  : _backend = backend ??
            (backendContract ?? GetIt.I.get<BackendContract>()).schedule;

  final ScheduleBackendContract _backend;
  @override
  final StreamValue<HomeAgendaCacheSnapshot?> homeAgendaStreamValue =
      StreamValue<HomeAgendaCacheSnapshot?>();

  @override
  HomeAgendaCacheSnapshot? readHomeAgenda({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) {
    final snapshot = homeAgendaStreamValue.value;
    if (snapshot == null) {
      return null;
    }
    if (snapshot.showPastOnly != showPastOnly.value) {
      return null;
    }
    if (snapshot.searchQuery != searchQuery.value) {
      return null;
    }
    if (snapshot.confirmedOnly != confirmedOnly.value) {
      return null;
    }
    if (!_matchesHomeAgendaOrigin(
      snapshot: snapshot,
      requestedOriginLat: originLat?.value,
      requestedOriginLng: originLng?.value,
    )) {
      return null;
    }
    if (!_matchesHomeAgendaMaxDistance(
      snapshot: snapshot,
      requestedMaxDistanceMeters: maxDistanceMeters?.value,
    )) {
      return null;
    }
    return snapshot;
  }

  bool _matchesHomeAgendaOrigin({
    required HomeAgendaCacheSnapshot snapshot,
    required double? requestedOriginLat,
    required double? requestedOriginLng,
  }) {
    final snapshotOriginLat = snapshot.originLat;
    final snapshotOriginLng = snapshot.originLng;

    if (requestedOriginLat == null || requestedOriginLng == null) {
      return snapshotOriginLat == null && snapshotOriginLng == null;
    }

    if (snapshotOriginLat == null || snapshotOriginLng == null) {
      return false;
    }

    final jumpMeters = haversineDistanceMeters(
      coordinateA: CityCoordinate(
        latitudeValue: LatitudeValue()..parse(snapshotOriginLat.toString()),
        longitudeValue: LongitudeValue()..parse(snapshotOriginLng.toString()),
      ),
      coordinateB: CityCoordinate(
        latitudeValue: LatitudeValue()..parse(requestedOriginLat.toString()),
        longitudeValue: LongitudeValue()..parse(requestedOriginLng.toString()),
      ),
    );

    return jumpMeters.value < _homeAgendaCacheReuseMaxOriginJumpMeters;
  }

  bool _matchesHomeAgendaMaxDistance({
    required HomeAgendaCacheSnapshot snapshot,
    required double? requestedMaxDistanceMeters,
  }) {
    final snapshotMaxDistanceMeters = snapshot.maxDistanceMeters;

    if (requestedMaxDistanceMeters == null) {
      return snapshotMaxDistanceMeters == null;
    }

    if (snapshotMaxDistanceMeters == null) {
      return false;
    }

    return (snapshotMaxDistanceMeters - requestedMaxDistanceMeters).abs() <
        0.001;
  }

  HomeAgendaCacheSnapshot _buildHomeAgendaSnapshot({
    required List<EventModel> events,
    required int page,
    required bool hasMore,
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) {
    return HomeAgendaCacheSnapshot(
      events: List<EventModel>.unmodifiable(events),
      hasMoreValue: HomeAgendaBooleanValue(defaultValue: hasMore)
        ..parse(hasMore.toString()),
      pageValue: HomeAgendaPageValue(defaultValue: page)..parse(page.toString()),
      showPastOnlyValue: HomeAgendaBooleanValue(defaultValue: showPastOnly.value)
        ..parse(showPastOnly.value.toString()),
      searchQueryValue: HomeAgendaSearchQueryValue(
        defaultValue: searchQuery.value,
      )..parse(searchQuery.value),
      confirmedOnlyValue:
          HomeAgendaBooleanValue(defaultValue: confirmedOnly.value)
            ..parse(confirmedOnly.value.toString()),
      capturedAtValue: HomeAgendaCapturedAtValue(defaultValue: DateTime.now())
        ..parse(DateTime.now().toIso8601String()),
      originLatValue: originLat == null
          ? null
          : (LatitudeValue()..parse(originLat.value.toString())),
      originLngValue: originLng == null
          ? null
          : (LongitudeValue()..parse(originLng.value.toString())),
      maxDistanceMetersValue: maxDistanceMeters == null
          ? null
          : (DistanceInMetersValue(defaultValue: maxDistanceMeters.value)
            ..parse(maxDistanceMeters.value.toString())),
    );
  }

  void _publishHomeAgendaSnapshot(HomeAgendaCacheSnapshot snapshot) {
    homeAgendaStreamValue.addValue(snapshot);
  }

  @override
  Future<HomeAgendaCacheSnapshot> loadHomeAgenda({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    final pageResult = await getEventsPage(
      page: ScheduleRepoInt.fromRaw(1, defaultValue: 1),
      pageSize: ScheduleRepoInt.fromRaw(25, defaultValue: 25),
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );

    final snapshot = _buildHomeAgendaSnapshot(
      events: pageResult.events,
      page: 1,
      hasMore: pageResult.hasMore,
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    _publishHomeAgendaSnapshot(snapshot);
    return snapshot;
  }

  @override
  Future<HomeAgendaCacheSnapshot?> loadNextHomeAgendaPage({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    final current = readHomeAgenda(
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    if (current == null || !current.hasMore) {
      return current;
    }

    final nextPage = current.page + 1;
    final pageResult = await getEventsPage(
      page: ScheduleRepoInt.fromRaw(nextPage, defaultValue: nextPage),
      pageSize: ScheduleRepoInt.fromRaw(25, defaultValue: 25),
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );

    final snapshot = _buildHomeAgendaSnapshot(
      events: <EventModel>[
        ...current.events,
        ...pageResult.events,
      ],
      page: nextPage,
      hasMore: pageResult.hasMore,
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    _publishHomeAgendaSnapshot(snapshot);
    return snapshot;
  }

  Future<void> initializeHomeAgendaStreams() async {
    homeAgendaStreamValue.addValue(homeAgendaStreamValue.value);
  }

  Future<void> refreshHomeAgendaStreams() async {
    homeAgendaStreamValue.addValue(homeAgendaStreamValue.value);
  }

  @override
  Future<EventModel?> getEventBySlug(ScheduleRepoString slug) async {
    final slugValue = slug.value;
    final dto = await _backend.fetchEventDetail(eventIdOrSlug: slugValue);
    return dto?.toDomain();
  }

  Map<String, String> _encodeTaxonomyEntry(ScheduleRepoTaxonomyEntry entry) {
    return <String, String>{
      'type': entry.type.value,
      'term': entry.term.value,
    };
  }

  @override
  Future<PagedEventsResult> getEventsPage({
    required ScheduleRepoInt page,
    required ScheduleRepoInt pageSize,
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoBool? liveNowOnly,
    ScheduleRepoString? searchQuery,
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    ScheduleRepoTaxonomyEntries? taxonomy,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    final EventPageDTO pageDto = await _backend.fetchEventsPage(
      page: page.value,
      pageSize: pageSize.value,
      showPastOnly: showPastOnly.value,
      liveNowOnly: liveNowOnly?.value ?? false,
      searchQuery: searchQuery?.value,
      categories: categories?.map((entry) => entry.value).toList(
            growable: false,
          ),
      tags: tags?.map((entry) => entry.value).toList(
            growable: false,
          ),
      taxonomy: taxonomy?.map(_encodeTaxonomyEntry).toList(
            growable: false,
          ),
      confirmedOnly: confirmedOnly?.value ?? false,
      originLat: originLat?.value,
      originLng: originLng?.value,
      maxDistanceMeters: maxDistanceMeters?.value,
    );

    final events =
        pageDto.events.map((event) => event.toDomain()).toList(growable: false);

    return pagedEventsResultFromRaw(
      events: events,
      hasMore: pageDto.hasMore,
    );
  }

  @override
  Stream<EventDeltaModel> watchEventsStream({
    ScheduleRepoString? searchQuery,
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    ScheduleRepoTaxonomyEntries? taxonomy,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
    ScheduleRepoString? lastEventId,
    ScheduleRepoBool? showPastOnly,
  }) {
    return _backend
        .watchEventsStream(
          searchQuery: searchQuery?.value,
          categories: categories?.map((entry) => entry.value).toList(
                growable: false,
              ),
          tags: tags?.map((entry) => entry.value).toList(
                growable: false,
              ),
          taxonomy: taxonomy?.map(_encodeTaxonomyEntry).toList(
                growable: false,
              ),
          confirmedOnly: confirmedOnly?.value ?? false,
          originLat: originLat?.value,
          originLng: originLng?.value,
          maxDistanceMeters: maxDistanceMeters?.value,
          lastEventId: lastEventId?.value,
          showPastOnly: showPastOnly?.value ?? false,
        )
        .map((deltaDto) => deltaDto.toDomain());
  }

  @override
  Stream<void> watchEventsSignal({
    required ScheduleRepositoryContractDeltaHandler onDelta,
    ScheduleRepoString? searchQuery,
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    ScheduleRepoTaxonomyEntries? taxonomy,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
    ScheduleRepoString? lastEventId,
    ScheduleRepoBool? showPastOnly,
  }) {
    return watchEventsStream(
      searchQuery: searchQuery,
      categories: categories,
      tags: tags,
      taxonomy: taxonomy,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
      lastEventId: lastEventId,
      showPastOnly: showPastOnly,
    ).map((delta) {
      onDelta(delta);
    });
  }

}
