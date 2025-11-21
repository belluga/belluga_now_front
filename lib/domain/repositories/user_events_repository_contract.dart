import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:stream_value/core/stream_value.dart';

/// Repository contract for user-specific event relationships
/// Handles confirmed events, featured events, and user event actions
abstract class UserEventsRepositoryContract {
  /// Stream of confirmed event slugs to notify listeners of changes
  StreamValue<Set<String>> get confirmedEventSlugsStream;

  /// Fetch events that the user has confirmed attendance for
  Future<List<VenueEventResume>> fetchMyEvents();

  /// Fetch featured/recommended events for the user
  Future<List<VenueEventResume>> fetchFeaturedEvents();

  /// Mark an event as confirmed for the user
  Future<void> confirmEventAttendance(String eventId);

  /// Remove confirmation for an event
  Future<void> unconfirmEventAttendance(String eventId);

  /// Check if user has confirmed attendance for an event
  bool isEventConfirmed(String eventId);
}
