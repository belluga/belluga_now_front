import 'package:belluga_now/domain/map/geo_distance.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/schedule_repository_contract_values.dart';
import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_page_dto.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class ScheduleRepository extends ScheduleRepositoryContract {
  static const double _homeAgendaCacheReuseMaxOriginJumpMeters = 1000.0;
  static const int _homeAgendaPageSize = 25;
  static const int _eventSearchPageSize = 25;
  static const int _discoveryLiveNowPageSize = 10;
  static const int _confirmedEventsPageSize = 10;
  static const int _maxConfirmedEventsPages = 30;

  ScheduleRepository({
    ScheduleBackendContract? backend,
    BackendContract? backendContract,
  }) : _backend = backend ??
            (backendContract ?? GetIt.I.get<BackendContract>()).schedule;

  final ScheduleBackendContract _backend;
  @override
  final StreamValue<List<EventModel>?> homeAgendaStreamValue =
      StreamValue<List<EventModel>?>();
  @override
  final StreamValue<List<EventModel>?> discoveryLiveNowEventsStreamValue =
      StreamValue<List<EventModel>?>(defaultValue: null);
  _HomeAgendaState? _homeAgendaState;
  final Map<String, _RepositoryQueryState> _eventSearchStateByQueryKey =
      <String, _RepositoryQueryState>{};

  @override
  List<EventModel>? readHomeAgenda({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) {
    final state = _homeAgendaState;
    if (state == null) {
      return null;
    }
    if (state.showPastOnly != showPastOnly.value) {
      return null;
    }
    if (state.searchQuery != searchQuery.value) {
      return null;
    }
    if (state.confirmedOnly != confirmedOnly.value) {
      return null;
    }
    if (!_matchesHomeAgendaOrigin(
      state: state,
      requestedOriginLat: originLat?.value,
      requestedOriginLng: originLng?.value,
    )) {
      return null;
    }
    if (!_matchesHomeAgendaMaxDistance(
      state: state,
      requestedMaxDistanceMeters: maxDistanceMeters?.value,
    )) {
      return null;
    }
    return state.events;
  }

  bool _matchesHomeAgendaOrigin({
    required _HomeAgendaState state,
    required double? requestedOriginLat,
    required double? requestedOriginLng,
  }) {
    final snapshotOriginLat = state.originLat;
    final snapshotOriginLng = state.originLng;

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
    required _HomeAgendaState state,
    required double? requestedMaxDistanceMeters,
  }) {
    final snapshotMaxDistanceMeters = state.maxDistanceMeters;

    if (requestedMaxDistanceMeters == null) {
      return snapshotMaxDistanceMeters == null;
    }

    if (snapshotMaxDistanceMeters == null) {
      return false;
    }

    return (snapshotMaxDistanceMeters - requestedMaxDistanceMeters).abs() <
        0.001;
  }

  _HomeAgendaState? _resolveHomeAgendaState({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) {
    final state = _homeAgendaState;
    if (state == null) {
      return null;
    }
    if (state.showPastOnly != showPastOnly.value) {
      return null;
    }
    if (state.searchQuery != searchQuery.value) {
      return null;
    }
    if (state.confirmedOnly != confirmedOnly.value) {
      return null;
    }
    if (!_matchesHomeAgendaOrigin(
      state: state,
      requestedOriginLat: originLat?.value,
      requestedOriginLng: originLng?.value,
    )) {
      return null;
    }
    if (!_matchesHomeAgendaMaxDistance(
      state: state,
      requestedMaxDistanceMeters: maxDistanceMeters?.value,
    )) {
      return null;
    }
    return state;
  }

  void _publishHomeAgendaState(_HomeAgendaState state) {
    _homeAgendaState = state;
    homeAgendaStreamValue.addValue(state.events);
  }

  String _buildEventSearchQueryKey({
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoString? searchQuery,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) {
    return <String>[
      showPastOnly.value.toString(),
      searchQuery?.value ?? '',
      (confirmedOnly?.value ?? false).toString(),
      originLat?.value.toString() ?? '',
      originLng?.value.toString() ?? '',
      maxDistanceMeters?.value.toString() ?? '',
    ].join('::');
  }

  Future<_SchedulePageSlice> _fetchEventsPageSlice({
    required int page,
    required int pageSize,
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
      page: page,
      pageSize: pageSize,
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

    return _SchedulePageSlice(
      events: List<EventModel>.unmodifiable(
        pageDto.events.map((event) => event.toDomain()),
      ),
      hasMore: pageDto.hasMore,
    );
  }

  @override
  Future<List<EventModel>> loadHomeAgenda({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    final firstSlice = await _fetchEventsPageSlice(
      page: 1,
      pageSize: _homeAgendaPageSize,
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );

    final state = _HomeAgendaState(
      events: firstSlice.events,
      nextPage: 2,
      hasMore: firstSlice.hasMore,
      showPastOnly: showPastOnly.value,
      searchQuery: searchQuery.value,
      confirmedOnly: confirmedOnly.value,
      originLat: originLat?.value,
      originLng: originLng?.value,
      maxDistanceMeters: maxDistanceMeters?.value,
    );
    _publishHomeAgendaState(state);
    return state.events;
  }

  @override
  Future<List<EventModel>> loadMoreHomeAgenda({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    final current = _resolveHomeAgendaState(
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    if (current == null || !current.hasMore) {
      return current?.events ?? const <EventModel>[];
    }

    final nextSlice = await _fetchEventsPageSlice(
      page: current.nextPage,
      pageSize: _homeAgendaPageSize,
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );

    final state = _HomeAgendaState(
      events: <EventModel>[
        ...current.events,
        ...nextSlice.events,
      ],
      nextPage: current.nextPage + 1,
      hasMore: nextSlice.hasMore,
      showPastOnly: showPastOnly.value,
      searchQuery: searchQuery.value,
      confirmedOnly: confirmedOnly.value,
      originLat: originLat?.value,
      originLng: originLng?.value,
      maxDistanceMeters: maxDistanceMeters?.value,
    );
    _publishHomeAgendaState(state);
    return state.events;
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
  Future<List<EventModel>> loadEventSearch({
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoString? searchQuery,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    final queryKey = _buildEventSearchQueryKey(
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    final firstSlice = await _fetchEventsPageSlice(
      page: 1,
      pageSize: _eventSearchPageSize,
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    _eventSearchStateByQueryKey[queryKey] = _RepositoryQueryState(
      nextPage: 2,
      hasMore: firstSlice.hasMore,
    );
    return firstSlice.events;
  }

  @override
  Future<List<EventModel>> loadMoreEventSearch({
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoString? searchQuery,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    final queryKey = _buildEventSearchQueryKey(
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    final state = _eventSearchStateByQueryKey[queryKey];
    if (state == null || !state.hasMore) {
      return const <EventModel>[];
    }

    final nextSlice = await _fetchEventsPageSlice(
      page: state.nextPage,
      pageSize: _eventSearchPageSize,
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    _eventSearchStateByQueryKey[queryKey] = _RepositoryQueryState(
      nextPage: state.nextPage + 1,
      hasMore: nextSlice.hasMore,
    );
    return nextSlice.events;
  }

  @override
  Future<List<EventModel>> loadConfirmedEvents({
    required ScheduleRepoBool showPastOnly,
  }) async {
    final events = <EventModel>[];
    var currentPage = 1;
    var hasMore = true;

    while (hasMore && currentPage <= _maxConfirmedEventsPages) {
      final pageSlice = await _fetchEventsPageSlice(
        page: currentPage,
        pageSize: _confirmedEventsPageSize,
        showPastOnly: showPastOnly,
        confirmedOnly: ScheduleRepoBool.fromRaw(true, defaultValue: true),
      );
      events.addAll(pageSlice.events);
      hasMore = pageSlice.hasMore;
      currentPage += 1;
    }

    return List<EventModel>.unmodifiable(events);
  }

  @override
  Future<void> refreshDiscoveryLiveNowEvents({
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    final liveNowSlice = await _fetchEventsPageSlice(
      page: 1,
      pageSize: _discoveryLiveNowPageSize,
      showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
      liveNowOnly: ScheduleRepoBool.fromRaw(true, defaultValue: true),
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    discoveryLiveNowEventsStreamValue.addValue(liveNowSlice.events);
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

class _SchedulePageSlice {
  const _SchedulePageSlice({
    required this.events,
    required this.hasMore,
  });

  final List<EventModel> events;
  final bool hasMore;
}

class _HomeAgendaState {
  const _HomeAgendaState({
    required this.events,
    required this.nextPage,
    required this.hasMore,
    required this.showPastOnly,
    required this.searchQuery,
    required this.confirmedOnly,
    required this.originLat,
    required this.originLng,
    required this.maxDistanceMeters,
  });

  final List<EventModel> events;
  final int nextPage;
  final bool hasMore;
  final bool showPastOnly;
  final String searchQuery;
  final bool confirmedOnly;
  final double? originLat;
  final double? originLng;
  final double? maxDistanceMeters;
}

class _RepositoryQueryState {
  const _RepositoryQueryState({
    required this.nextPage,
    required this.hasMore,
  });

  final int nextPage;
  final bool hasMore;
}
