import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/paged_events_result.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:stream_value/core/stream_value.dart';

class HomeAgendaCacheSnapshot {
  const HomeAgendaCacheSnapshot({
    required this.events,
    required this.hasMore,
    required this.page,
    required this.showPastOnly,
    required this.searchQuery,
    required this.confirmedOnly,
    required this.capturedAt,
    this.originLat,
    this.originLng,
    this.maxDistanceMeters,
  });

  final List<EventModel> events;
  final bool hasMore;
  final int page;
  final bool showPastOnly;
  final String searchQuery;
  final bool confirmedOnly;
  final DateTime capturedAt;
  final double? originLat;
  final double? originLng;
  final double? maxDistanceMeters;
}

abstract class ScheduleRepositoryContract {
  StreamValue<List<EventModel>?> get homeAgendaEventsStreamValue;
  StreamValue<HomeAgendaCacheSnapshot?> get homeAgendaCacheStreamValue;

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
}
