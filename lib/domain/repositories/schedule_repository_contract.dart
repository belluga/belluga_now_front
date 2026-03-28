import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/home_agenda_cache_snapshot.dart';
import 'package:belluga_now/domain/schedule/paged_events_result.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:stream_value/core/stream_value.dart';

export 'package:belluga_now/domain/schedule/home_agenda_cache_snapshot.dart';

typedef ScheduleRepoString = String;
typedef ScheduleRepoInt = int;
typedef ScheduleRepoBool = bool;
typedef ScheduleRepoDouble = double;
typedef ScheduleRepoDateTime = DateTime;
typedef ScheduleRepoDynamic = dynamic;

abstract class ScheduleRepositoryContract {
  static const ScheduleRepoInt _defaultPagedEventsPageSize = 25;
  static final Expando<_SchedulePagedEventsState>
      _pagedEventsStateByRepository = Expando<_SchedulePagedEventsState>();

  _SchedulePagedEventsState get _pagedEventsState =>
      _pagedEventsStateByRepository[this] ??= _SchedulePagedEventsState();

  StreamValue<List<EventModel>?> get homeAgendaEventsStreamValue;
  StreamValue<HomeAgendaCacheSnapshot?> get homeAgendaCacheStreamValue;
  final eventSearchDisplayedEventsStreamValue =
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
    ScheduleRepoString searchQuery = '',
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    List<Map<ScheduleRepoString, ScheduleRepoString>>? taxonomy,
    ScheduleRepoBool confirmedOnly = false,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  });

  Future<void> loadEventsPage({
    ScheduleRepoInt pageSize = _defaultPagedEventsPageSize,
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoString searchQuery = '',
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    List<Map<ScheduleRepoString, ScheduleRepoString>>? taxonomy,
    ScheduleRepoBool confirmedOnly = false,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    if (_pagedEventsState.isFetching) {
      return;
    }
    _resetPagedEventsState();
    pagedEventsStreamValue.addValue(null);
    await _fetchPagedEvents(
      page: 1,
      pageSize: pageSize,
      showPastOnly: showPastOnly,
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
    ScheduleRepoInt pageSize = _defaultPagedEventsPageSize,
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoString searchQuery = '',
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    List<Map<ScheduleRepoString, ScheduleRepoString>>? taxonomy,
    ScheduleRepoBool confirmedOnly = false,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    if (_pagedEventsState.isFetching || !_pagedEventsState.hasMore) {
      return;
    }
    await _fetchPagedEvents(
      page: _pagedEventsState.currentPage + 1,
      pageSize: pageSize,
      showPastOnly: showPastOnly,
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
    ScheduleRepoString searchQuery = '',
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    List<Map<ScheduleRepoString, ScheduleRepoString>>? taxonomy,
    ScheduleRepoBool confirmedOnly = false,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    final pageResult = await getEventsPage(
      page: page,
      pageSize: pageSize,
      showPastOnly: showPastOnly,
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

  Future<void> _fetchPagedEvents({
    required ScheduleRepoInt page,
    required ScheduleRepoInt pageSize,
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoString searchQuery = '',
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    List<Map<ScheduleRepoString, ScheduleRepoString>>? taxonomy,
    ScheduleRepoBool confirmedOnly = false,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    if (_pagedEventsState.isFetching) return;
    if (page > 1 && !_pagedEventsState.hasMore) return;

    _pagedEventsState.isFetching = true;
    if (page > 1) {
      isPagedEventsPageLoadingStreamValue.addValue(true);
    }
    try {
      final pageResult = await getEventsPage(
        page: page,
        pageSize: pageSize,
        showPastOnly: showPastOnly,
        searchQuery: searchQuery,
        categories: categories,
        tags: tags,
        taxonomy: taxonomy,
        confirmedOnly: confirmedOnly,
        originLat: originLat,
        originLng: originLng,
        maxDistanceMeters: maxDistanceMeters,
      );
      _pagedEventsState.currentPage = page;
      _pagedEventsState.hasMore = pageResult.hasMore;
      hasMorePagedEventsStreamValue.addValue(pageResult.hasMore);
      pagedEventsStreamValue.addValue(pageResult);
      pagedEventsErrorStreamValue.addValue(null);
    } catch (error) {
      pagedEventsErrorStreamValue.addValue(error.toString());
      if (page == 1) {
        pagedEventsStreamValue.addValue(
            PagedEventsResult(events: <EventModel>[], hasMore: false));
        hasMorePagedEventsStreamValue.addValue(false);
      }
    } finally {
      _pagedEventsState.isFetching = false;
      isPagedEventsPageLoadingStreamValue.addValue(false);
    }
  }

  void _resetPagedEventsState() {
    _pagedEventsState.currentPage = 0;
    _pagedEventsState.hasMore = true;
    _pagedEventsState.isFetching = false;
    hasMorePagedEventsStreamValue.addValue(true);
    isPagedEventsPageLoadingStreamValue.addValue(false);
  }

  /// Returns the events for [date] already projected for presentation flows
  /// that require [VenueEventResume] rather than the raw [EventModel].
  Future<List<VenueEventResume>> getEventResumesByDate(
      ScheduleRepoDateTime date);

  Future<List<VenueEventResume>> fetchUpcomingEvents();

  Stream<EventDeltaModel> watchEventsStream({
    ScheduleRepoString searchQuery = '',
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    List<Map<ScheduleRepoString, ScheduleRepoString>>? taxonomy,
    ScheduleRepoBool confirmedOnly = false,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
    ScheduleRepoString? lastEventId,
    ScheduleRepoBool showPastOnly = false,
  });

  Stream<void> watchEventsSignal({
    required void Function(EventDeltaModel delta) onDelta,
    ScheduleRepoString searchQuery = '',
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    List<Map<ScheduleRepoString, ScheduleRepoString>>? taxonomy,
    ScheduleRepoBool confirmedOnly = false,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
    ScheduleRepoString? lastEventId,
    ScheduleRepoBool showPastOnly = false,
  });
}

class _SchedulePagedEventsState {
  final StreamValue<ScheduleRepoBool> hasMoreStreamValue =
      StreamValue<ScheduleRepoBool>(defaultValue: true);
  final StreamValue<ScheduleRepoBool> isPageLoadingStreamValue =
      StreamValue<ScheduleRepoBool>(defaultValue: false);
  final StreamValue<ScheduleRepoString?> errorStreamValue =
      StreamValue<ScheduleRepoString?>();
  ScheduleRepoInt currentPage = 0;
  ScheduleRepoBool hasMore = true;
  ScheduleRepoBool isFetching = false;
}
