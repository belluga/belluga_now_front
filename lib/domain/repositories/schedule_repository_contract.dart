import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/paged_events_result.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';

abstract class ScheduleRepositoryContract {
  Future<ScheduleSummaryModel> getScheduleSummary();
  Future<List<EventModel>> getEventsByDate(DateTime date);
  Future<List<EventModel>> getAllEvents();
  Future<EventModel?> getEventBySlug(String slug);
  Future<PagedEventsResult> getEventsPage({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    String searchQuery = '',
  });

  /// Returns the events for [date] already projected for presentation flows
  /// that require [VenueEventResume] rather than the raw [EventModel].
  Future<List<VenueEventResume>> getEventResumesByDate(DateTime date);

  Future<List<VenueEventResume>> fetchUpcomingEvents();
}
