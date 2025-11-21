import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';

abstract class ScheduleRepositoryContract {
  Future<ScheduleSummaryModel> getScheduleSummary();
  Future<List<EventModel>> getEventsByDate(DateTime date);
  Future<List<EventModel>> getAllEvents();
  Future<EventModel?> getEventBySlug(String slug);

  /// Returns the events for [date] already projected for presentation flows
  /// that require [VenueEventResume] rather than the raw [EventModel].
  Future<List<VenueEventResume>> getEventResumesByDate(DateTime date);

  Future<List<VenueEventResume>> fetchUpcomingEvents();
}
