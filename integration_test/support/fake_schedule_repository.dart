import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/schedule_repository_contract_values.dart';
import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:stream_value/core/stream_value.dart';

typedef IntegrationTestScheduleQueryResolver = List<EventModel> Function({
  required List<EventModel> seededEvents,
  required bool showPastOnly,
  required bool liveNowOnly,
  String? searchQuery,
  required bool confirmedOnly,
  double? originLat,
  double? originLng,
  double? maxDistanceMeters,
});

typedef IntegrationTestScheduleSlugResolver = EventModel? Function({
  required List<EventModel> seededEvents,
  required String slug,
});

class IntegrationTestScheduleRepositoryFake extends ScheduleRepositoryContract {
  IntegrationTestScheduleRepositoryFake({
    List<EventModel> seededEvents = const <EventModel>[],
    IntegrationTestScheduleQueryResolver? queryResolver,
    IntegrationTestScheduleSlugResolver? slugResolver,
  })  : _seededEvents = List<EventModel>.unmodifiable(seededEvents),
        _queryResolver = queryResolver,
        _slugResolver = slugResolver;

  @override
  final StreamValue<List<EventModel>?> homeAgendaStreamValue =
      StreamValue<List<EventModel>?>();
  @override
  final StreamValue<List<EventModel>?> discoveryLiveNowEventsStreamValue =
      StreamValue<List<EventModel>?>(defaultValue: null);
  final List<EventModel> _seededEvents;
  final IntegrationTestScheduleQueryResolver? _queryResolver;
  final IntegrationTestScheduleSlugResolver? _slugResolver;
  _IntegrationFakeHomeAgendaState? _homeAgendaState;
  final Map<String, _IntegrationFakeQueryState> _eventSearchStateByQueryKey =
      <String, _IntegrationFakeQueryState>{};

  @override
  List<EventModel>? readHomeAgenda({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) {
    final state = _resolveHomeAgendaState(
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    return state?.events;
  }

  _IntegrationFakeHomeAgendaState? _resolveHomeAgendaState({
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
    if (state.originLat != originLat?.value) {
      return null;
    }
    if (state.originLng != originLng?.value) {
      return null;
    }
    if (state.maxDistanceMeters != maxDistanceMeters?.value) {
      return null;
    }
    return state;
  }

  List<EventModel> _resolveQueryEvents({
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoString? searchQuery,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoBool? liveNowOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) {
    final resolver = _queryResolver;
    if (resolver != null) {
      return List<EventModel>.unmodifiable(
        resolver(
          seededEvents: _seededEvents,
          showPastOnly: showPastOnly.value,
          liveNowOnly: liveNowOnly?.value ?? false,
          searchQuery: searchQuery?.value,
          confirmedOnly: confirmedOnly?.value ?? false,
          originLat: originLat?.value,
          originLng: originLng?.value,
          maxDistanceMeters: maxDistanceMeters?.value,
        ),
      );
    }

    return _seededEvents;
  }

  List<EventModel> _sliceQueryEvents({
    required int page,
    required int pageSize,
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoString? searchQuery,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoBool? liveNowOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) {
    final resolved = _resolveQueryEvents(
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      liveNowOnly: liveNowOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    final safePage = page <= 0 ? 1 : page;
    final safePageSize = pageSize <= 0 ? 1 : pageSize;
    final startIndex = (safePage - 1) * safePageSize;
    if (startIndex >= resolved.length) {
      return const <EventModel>[];
    }
    final endIndex = startIndex + safePageSize;
    return List<EventModel>.unmodifiable(
      resolved.sublist(
        startIndex,
        endIndex < resolved.length ? endIndex : resolved.length,
      ),
    );
  }

  String _eventSearchQueryKey({
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

  @override
  Future<List<EventModel>> loadHomeAgenda({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    final pageEvents = _sliceQueryEvents(
      page: 1,
      pageSize: 25,
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    _homeAgendaState = _IntegrationFakeHomeAgendaState(
      events: pageEvents,
      nextPage: 2,
      hasMore: pageEvents.length >= 25,
      showPastOnly: showPastOnly.value,
      searchQuery: searchQuery.value,
      confirmedOnly: confirmedOnly.value,
      originLat: originLat?.value,
      originLng: originLng?.value,
      maxDistanceMeters: maxDistanceMeters?.value,
    );
    homeAgendaStreamValue.addValue(pageEvents);
    return pageEvents;
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

    final pageEvents = _sliceQueryEvents(
      page: current.nextPage,
      pageSize: 25,
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    final nextEvents = <EventModel>[
      ...current.events,
      ...pageEvents,
    ];
    _homeAgendaState = _IntegrationFakeHomeAgendaState(
      events: nextEvents,
      nextPage: current.nextPage + 1,
      hasMore: pageEvents.length >= 25,
      showPastOnly: showPastOnly.value,
      searchQuery: searchQuery.value,
      confirmedOnly: confirmedOnly.value,
      originLat: originLat?.value,
      originLng: originLng?.value,
      maxDistanceMeters: maxDistanceMeters?.value,
    );
    homeAgendaStreamValue.addValue(nextEvents);
    return nextEvents;
  }

  @override
  Future<EventModel?> getEventBySlug(ScheduleRepoString slug) async {
    final resolver = _slugResolver;
    if (resolver != null) {
      return resolver(seededEvents: _seededEvents, slug: slug.value);
    }

    for (final event in _seededEvents) {
      if (event.slug == slug.value) {
        return event;
      }
    }
    return null;
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
    final queryKey = _eventSearchQueryKey(
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    final pageEvents = _sliceQueryEvents(
      page: 1,
      pageSize: 25,
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    _eventSearchStateByQueryKey[queryKey] = _IntegrationFakeQueryState(
      nextPage: 2,
      hasMore: pageEvents.length >= 25,
    );
    return pageEvents;
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
    final queryKey = _eventSearchQueryKey(
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

    final pageEvents = _sliceQueryEvents(
      page: state.nextPage,
      pageSize: 25,
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    _eventSearchStateByQueryKey[queryKey] = _IntegrationFakeQueryState(
      nextPage: state.nextPage + 1,
      hasMore: pageEvents.length >= 25,
    );
    return pageEvents;
  }

  @override
  Future<List<EventModel>> loadConfirmedEvents({
    required ScheduleRepoBool showPastOnly,
  }) async {
    final collected = <EventModel>[];
    var currentPage = 1;
    while (true) {
      final pageEvents = _sliceQueryEvents(
        page: currentPage,
        pageSize: 10,
        showPastOnly: showPastOnly,
        confirmedOnly: ScheduleRepoBool.fromRaw(true, defaultValue: true),
      );
      collected.addAll(pageEvents);
      if (pageEvents.length < 10) {
        break;
      }
      currentPage += 1;
    }
    return List<EventModel>.unmodifiable(collected);
  }

  @override
  Future<void> refreshDiscoveryLiveNowEvents({
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    final events = _sliceQueryEvents(
      page: 1,
      pageSize: 10,
      showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
      liveNowOnly: ScheduleRepoBool.fromRaw(true, defaultValue: true),
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    discoveryLiveNowEventsStreamValue.addValue(events);
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
  }) =>
      const Stream<EventDeltaModel>.empty();

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

class _IntegrationFakeQueryState {
  const _IntegrationFakeQueryState({
    required this.nextPage,
    required this.hasMore,
  });

  final int nextPage;
  final bool hasMore;
}

class _IntegrationFakeHomeAgendaState {
  const _IntegrationFakeHomeAgendaState({
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
