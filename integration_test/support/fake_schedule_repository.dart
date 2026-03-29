import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/paged_events_result.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:stream_value/core/stream_value.dart';

class IntegrationTestScheduleRepositoryFake extends ScheduleRepositoryContract {
  @override
  final StreamValue<List<EventModel>?> homeAgendaEventsStreamValue =
      StreamValue<List<EventModel>?>();
  @override
  final StreamValue<HomeAgendaCacheSnapshot?> homeAgendaCacheStreamValue =
      StreamValue<HomeAgendaCacheSnapshot?>();

  @override
  HomeAgendaCacheSnapshot? readHomeAgendaCache({
    required bool showPastOnly,
    bool liveNowOnly = false,
    required String searchQuery,
    required bool confirmedOnly,
  }) {
    final snapshot = homeAgendaCacheStreamValue.value;
    if (snapshot == null) return null;
    if (snapshot.showPastOnly != showPastOnly) return null;
    if (snapshot.searchQuery != searchQuery) return null;
    if (snapshot.confirmedOnly != confirmedOnly) return null;
    return snapshot;
  }

  @override
  void writeHomeAgendaCache(HomeAgendaCacheSnapshot snapshot) {
    homeAgendaCacheStreamValue.addValue(snapshot);
    homeAgendaEventsStreamValue.addValue(snapshot.events);
  }

  @override
  void clearHomeAgendaCache() {
    homeAgendaCacheStreamValue.addValue(null);
    homeAgendaEventsStreamValue.addValue(null);
  }

  @override
  Future<List<EventModel>> getAllEvents() async => const <EventModel>[];

  @override
  Future<EventModel?> getEventBySlug(String slug) async => null;

  @override
  Future<List<EventModel>> getEventsByDate(
    DateTime date, {
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async =>
      const <EventModel>[];

  @override
  Future<PagedEventsResult> getEventsPage({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    bool liveNowOnly = false,
    String searchQuery = '',
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async =>
      const PagedEventsResult(events: <EventModel>[], hasMore: false);

  @override
  Future<ScheduleSummaryModel> getScheduleSummary() async =>
      ScheduleSummaryModel(items: const []);

  @override
  Future<List<VenueEventResume>> getEventResumesByDate(DateTime date) async =>
      const <VenueEventResume>[];

  @override
  Future<List<VenueEventResume>> fetchUpcomingEvents() async =>
      const <VenueEventResume>[];

  @override
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
  }) =>
      const Stream<EventDeltaModel>.empty();

  @override
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
