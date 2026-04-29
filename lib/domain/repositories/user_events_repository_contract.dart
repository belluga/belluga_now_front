import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:stream_value/core/stream_value.dart';

typedef UserEventsRepositoryContractPrimString
    = UserEventsRepositoryContractTextValue;
typedef UserEventsRepositoryContractPrimBool
    = UserEventsRepositoryContractBoolValue;

/// Repository contract for user-specific event relationships.
/// Attendance confirmation identity is occurrence-scoped; event IDs are route
/// context only.
abstract class UserEventsRepositoryContract {
  /// Stream of confirmed occurrence IDs to notify listeners of changes.
  StreamValue<Set<UserEventsRepositoryContractPrimString>>
      get confirmedOccurrenceIdsStream;

  /// Refresh confirmed occurrence IDs from backend authoritative source.
  Future<void> refreshConfirmedOccurrenceIds();

  /// Fetch occurrences that the user has confirmed attendance for.
  Future<List<VenueEventResume>> fetchMyEvents();

  /// Fetch featured/recommended events for the user
  Future<List<VenueEventResume>> fetchFeaturedEvents();

  /// Mark an occurrence as confirmed for the user.
  Future<void> confirmEventAttendance(
    UserEventsRepositoryContractPrimString eventId, {
    required UserEventsRepositoryContractPrimString occurrenceId,
  });

  /// Remove confirmation for an occurrence.
  Future<void> unconfirmEventAttendance(
    UserEventsRepositoryContractPrimString eventId, {
    required UserEventsRepositoryContractPrimString occurrenceId,
  });

  /// Check if user has confirmed attendance for an occurrence.
  UserEventsRepositoryContractPrimBool isOccurrenceConfirmed(
      UserEventsRepositoryContractPrimString occurrenceId);
}
