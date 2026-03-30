import 'package:belluga_now/domain/repositories/value_objects/schedule_repository_contract_values.dart';
import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/home_agenda_cache_snapshot.dart';
import 'package:belluga_now/domain/schedule/paged_events_result.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:stream_value/core/stream_value.dart';

export 'package:belluga_now/domain/schedule/home_agenda_cache_snapshot.dart';

typedef ScheduleRepoString = ScheduleRepositoryContractTextValue;
typedef ScheduleRepoInt = ScheduleRepositoryContractIntValue;
typedef ScheduleRepoBool = ScheduleRepositoryContractBoolValue;
typedef ScheduleRepoDouble = ScheduleRepositoryContractDoubleValue;
typedef ScheduleRepoDateTime = ScheduleRepositoryContractDateTimeValue;
typedef ScheduleRepoTaxonomyEntry = ScheduleRepositoryContractTaxonomyEntry;
typedef ScheduleRepoTaxonomyEntries = ScheduleTaxonomyEntries;

abstract class ScheduleRepositoryContract {
  static final ScheduleRepoInt _defaultPagedEventsPageSize =
      ScheduleRepoInt.fromRaw(
    25,
    defaultValue: 25,
  );
  static final Expando<_SchedulePagedEventsState>
      _pagedEventsStateByRepository = Expando<_SchedulePagedEventsState>();

  _SchedulePagedEventsState get _pagedEventsState =>
      _pagedEventsStateByRepository[this] ??= _SchedulePagedEventsState();

  StreamValue<List<EventModel>?> get homeAgendaEventsStreamValue;
  StreamValue<HomeAgendaCacheSnapshot?> get homeAgendaCacheStreamValue;
  final eventSearchDisplayedEventsStreamValue =
      StreamValue<List<EventModel>>(defaultValue: const <EventModel>[]);
  final discoveryLiveNowEventsStreamValue =
      StreamValue<List<EventModel>>(defaultValue: const <EventModel>[]);
  final eventsByDateStreamValue =
      StreamValue<List<EventModel>>(defaultValue: const <EventModel>[]);
  final pagedEventsStreamValue =
      StreamValue<PagedEventsResult?>(defaultValue: null);

  StreamValue<ScheduleRepoBool> get hasMorePagedEventsStreamValue =>
      _pagedEventsState.hasMoreStreamValue;

  StreamValue<ScheduleRepoBool> get isPagedEventsPageLoadingStreamValue =>
      _pagedEventsState.isPageLoadingStreamValue;

  StreamValue<ScheduleRepoString?> get pagedEventsErrorStreamValue =>
      _pagedEventsState.errorStreamValue;

  ScheduleRepoInt get currentPagedEventsPage => _pagedEventsState.currentPage;

  HomeAgendaCacheSnapshot? readHomeAgendaCache({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
  });

  void writeHomeAgendaCache(HomeAgendaCacheSnapshot snapshot);
  void clearHomeAgendaCache();

  Future<ScheduleSummaryModel> getScheduleSummary();
  Future<List<EventModel>> getEventsByDate(
    ScheduleRepoDateTime date, {
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  });
  Future<void> refreshEventsByDate(
    ScheduleRepoDateTime date, {
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    final events = await getEventsByDate(
      date,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    eventsByDateStreamValue.addValue(events);
  }

  Future<List<EventModel>> getAllEvents();
  Future<EventModel?> getEventBySlug(ScheduleRepoString slug);
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
  });

  Future<void> loadEventsPage({
    ScheduleRepoInt? pageSize,
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
    if (_pagedEventsState.isFetching.value) {
      return;
    }
    _resetPagedEventsState();
    pagedEventsStreamValue.addValue(null);
    await _fetchPagedEvents(
      page: ScheduleRepoInt.fromRaw(1, defaultValue: 1),
      pageSize: pageSize ?? _defaultPagedEventsPageSize,
      showPastOnly: showPastOnly,
      liveNowOnly: liveNowOnly,
      searchQuery: searchQuery,
      categories: categories,
      tags: tags,
      taxonomy: taxonomy,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
  }

  Future<void> loadNextEventsPage({
    ScheduleRepoInt? pageSize,
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
    if (_pagedEventsState.isFetching.value ||
        !_pagedEventsState.hasMore.value) {
      return;
    }
    await _fetchPagedEvents(
      page: ScheduleRepoInt.fromRaw(
        _pagedEventsState.currentPage.value + 1,
        defaultValue: 1,
      ),
      pageSize: pageSize ?? _defaultPagedEventsPageSize,
      showPastOnly: showPastOnly,
      liveNowOnly: liveNowOnly,
      searchQuery: searchQuery,
      categories: categories,
      tags: tags,
      taxonomy: taxonomy,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
  }

  void resetPagedEventsState() {
    _resetPagedEventsState();
    pagedEventsStreamValue.addValue(null);
    pagedEventsErrorStreamValue.addValue(null);
  }

  Future<void> refreshEventsPage({
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
    final pageResult = await getEventsPage(
      page: page,
      pageSize: pageSize,
      showPastOnly: showPastOnly,
      liveNowOnly: liveNowOnly,
      searchQuery: searchQuery,
      categories: categories,
      tags: tags,
      taxonomy: taxonomy,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    pagedEventsStreamValue.addValue(pageResult);
  }

  Future<void> refreshDiscoveryLiveNowEvents({
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    final page = await getEventsPage(
      page: ScheduleRepoInt.fromRaw(1, defaultValue: 1),
      pageSize: ScheduleRepoInt.fromRaw(10, defaultValue: 10),
      showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
      liveNowOnly: ScheduleRepoBool.fromRaw(true, defaultValue: true),
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    discoveryLiveNowEventsStreamValue.addValue(page.events);
  }

  Future<void> _fetchPagedEvents({
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
    if (_pagedEventsState.isFetching.value) return;
    if (page.value > 1 && !_pagedEventsState.hasMore.value) return;

    _pagedEventsState.isFetching = ScheduleRepoBool.fromRaw(
      true,
      defaultValue: true,
    );
    if (page.value > 1) {
      isPagedEventsPageLoadingStreamValue.addValue(
        ScheduleRepoBool.fromRaw(
          true,
          defaultValue: true,
        ),
      );
    }
    try {
      final pageResult = await getEventsPage(
        page: page,
        pageSize: pageSize,
        showPastOnly: showPastOnly,
        liveNowOnly: liveNowOnly ??
            ScheduleRepoBool.fromRaw(
              false,
              defaultValue: false,
            ),
        searchQuery: searchQuery ??
            ScheduleRepoString.fromRaw(
              '',
              defaultValue: '',
            ),
        categories: categories,
        tags: tags,
        taxonomy: taxonomy,
        confirmedOnly: confirmedOnly ??
            ScheduleRepoBool.fromRaw(
              false,
              defaultValue: false,
            ),
        originLat: originLat,
        originLng: originLng,
        maxDistanceMeters: maxDistanceMeters,
      );
      _pagedEventsState.currentPage = page;
      _pagedEventsState.hasMore = ScheduleRepoBool.fromRaw(
        pageResult.hasMore,
        defaultValue: true,
      );
      hasMorePagedEventsStreamValue.addValue(_pagedEventsState.hasMore);
      pagedEventsStreamValue.addValue(pageResult);
      pagedEventsErrorStreamValue.addValue(null);
    } catch (error) {
      pagedEventsErrorStreamValue.addValue(
        ScheduleRepoString.fromRaw(error.toString()),
      );
      if (page.value == 1) {
        pagedEventsStreamValue.addValue(
          pagedEventsResultFromRaw(events: <EventModel>[], hasMore: false),
        );
        hasMorePagedEventsStreamValue.addValue(
          ScheduleRepoBool.fromRaw(
            false,
            defaultValue: false,
          ),
        );
      }
    } finally {
      _pagedEventsState.isFetching = ScheduleRepoBool.fromRaw(
        false,
        defaultValue: false,
      );
      isPagedEventsPageLoadingStreamValue.addValue(
        ScheduleRepoBool.fromRaw(
          false,
          defaultValue: false,
        ),
      );
    }
  }

  void _resetPagedEventsState() {
    _pagedEventsState.currentPage = ScheduleRepoInt.fromRaw(
      0,
      defaultValue: 0,
    );
    _pagedEventsState.hasMore = ScheduleRepoBool.fromRaw(
      true,
      defaultValue: true,
    );
    _pagedEventsState.isFetching = ScheduleRepoBool.fromRaw(
      false,
      defaultValue: false,
    );
    hasMorePagedEventsStreamValue.addValue(
      ScheduleRepoBool.fromRaw(
        true,
        defaultValue: true,
      ),
    );
    isPagedEventsPageLoadingStreamValue.addValue(
      ScheduleRepoBool.fromRaw(
        false,
        defaultValue: false,
      ),
    );
  }

  Future<List<VenueEventResume>> getEventResumesByDate(
      ScheduleRepoDateTime date);

  Future<List<VenueEventResume>> fetchUpcomingEvents();

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
  });

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
  });
}

class _SchedulePagedEventsState {
  final StreamValue<ScheduleRepoBool> hasMoreStreamValue =
      StreamValue<ScheduleRepoBool>(
    defaultValue: ScheduleRepoBool.fromRaw(
      true,
      defaultValue: true,
    ),
  );
  final StreamValue<ScheduleRepoBool> isPageLoadingStreamValue =
      StreamValue<ScheduleRepoBool>(
    defaultValue: ScheduleRepoBool.fromRaw(
      false,
      defaultValue: false,
    ),
  );
  final StreamValue<ScheduleRepoString?> errorStreamValue =
      StreamValue<ScheduleRepoString?>();
  ScheduleRepoInt currentPage = ScheduleRepoInt.fromRaw(
    0,
    defaultValue: 0,
  );
  ScheduleRepoBool hasMore = ScheduleRepoBool.fromRaw(
    true,
    defaultValue: true,
  );
  ScheduleRepoBool isFetching = ScheduleRepoBool.fromRaw(
    false,
    defaultValue: false,
  );
}
