import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:stream_value/core/stream_value.dart';

typedef UserEventsRepositoryContractPrimString
    = UserEventsRepositoryContractTextValue;
typedef UserEventsRepositoryContractPrimBool
    = UserEventsRepositoryContractBoolValue;

/// Repository contract for user-specific event relationships
/// Handles confirmed events, featured events, and user event actions
abstract class UserEventsRepositoryContract {
  /// Stream of confirmed event IDs to notify listeners of changes
  StreamValue<Set<UserEventsRepositoryContractPrimString>>
      get confirmedEventIdsStream;

  /// Refresh confirmed event IDs from backend authoritative source.
  Future<void> refreshConfirmedEventIds();

  /// Fetch events that the user has confirmed attendance for
  Future<List<VenueEventResume>> fetchMyEvents();

  /// Fetch featured/recommended events for the user
  Future<List<VenueEventResume>> fetchFeaturedEvents();

  /// Mark an event as confirmed for the user
  Future<void> confirmEventAttendance(
      UserEventsRepositoryContractPrimString eventId);

  /// Remove confirmation for an event
  Future<void> unconfirmEventAttendance(
      UserEventsRepositoryContractPrimString eventId);

  /// Check if user has confirmed attendance for an event
  UserEventsRepositoryContractPrimBool isEventConfirmed(
      UserEventsRepositoryContractPrimString eventId);
}
