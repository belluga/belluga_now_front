import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/home_agenda_cache_snapshot.dart';
import 'package:belluga_now/domain/schedule/paged_events_result.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:stream_value/core/stream_value.dart';

export 'package:belluga_now/domain/schedule/home_agenda_cache_snapshot.dart';

abstract class ScheduleRepositoryContract {
  static const int _defaultPagedEventsPageSize = 25;
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

  StreamValue<bool> get hasMorePagedEventsStreamValue =>
      _pagedEventsState.hasMoreStreamValue;

  StreamValue<bool> get isPagedEventsPageLoadingStreamValue =>
      _pagedEventsState.isPageLoadingStreamValue;

  StreamValue<String?> get pagedEventsErrorStreamValue =>
      _pagedEventsState.errorStreamValue;

  int get currentPagedEventsPage => _pagedEventsState.currentPage;

  HomeAgendaCacheSnapshot? readHomeAgendaCache({
    required bool showPastOnly,
    required String searchQuery,
    required bool confirmedOnly,
  });

  void writeHomeAgendaCache(HomeAgendaCacheSnapshot snapshot);
  void clearHomeAgendaCache();

  Future<ScheduleSummaryModel> getScheduleSummary();
  Future<List<EventModel>> getEventsByDate(
    DateTime date, {
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  });
  Future<void> refreshEventsByDate(
    DateTime date, {
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
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
  Future<EventModel?> getEventBySlug(String slug);
  Future<PagedEventsResult> getEventsPage({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    String searchQuery = '',
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  });

  Future<void> loadEventsPage({
    int pageSize = _defaultPagedEventsPageSize,
    required bool showPastOnly,
    String searchQuery = '',
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async {
    await _waitForPagedEventsFetch();
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
    int pageSize = _defaultPagedEventsPageSize,
    required bool showPastOnly,
    String searchQuery = '',
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
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
    required int page,
    required int pageSize,
    required bool showPastOnly,
    String searchQuery = '',
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
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

  Future<void> _waitForPagedEventsFetch() async {
    while (_pagedEventsState.isFetching) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchPagedEvents({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    String searchQuery = '',
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
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
            const PagedEventsResult(events: <EventModel>[], hasMore: false));
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
  Future<List<VenueEventResume>> getEventResumesByDate(DateTime date);

  Future<List<VenueEventResume>> fetchUpcomingEvents();

  Stream<EventDeltaModel> watchEventsStream({
    String searchQuery = '',
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
    String? lastEventId,
    bool showPastOnly = false,
  });

  Stream<void> watchEventsSignal({
    required void Function(EventDeltaModel delta) onDelta,
    String searchQuery = '',
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
    String? lastEventId,
    bool showPastOnly = false,
  });
}

class _SchedulePagedEventsState {
  final StreamValue<bool> hasMoreStreamValue =
      StreamValue<bool>(defaultValue: true);
  final StreamValue<bool> isPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> errorStreamValue = StreamValue<String?>();
  int currentPage = 0;
  bool hasMore = true;
  bool isFetching = false;
}
