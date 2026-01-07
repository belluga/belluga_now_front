import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

/// Implementation of UserEventsRepositoryContract
/// Tracks user-event relationships in memory (mock implementation)
class UserEventsRepository implements UserEventsRepositoryContract {
  UserEventsRepository({
    ScheduleRepositoryContract? scheduleRepository,
    TelemetryRepositoryContract? telemetryRepository,
  }) : _scheduleRepository =
            scheduleRepository ?? GetIt.I.get<ScheduleRepositoryContract>(),
        _telemetryRepository =
            telemetryRepository ?? GetIt.I.get<TelemetryRepositoryContract>();

  final ScheduleRepositoryContract _scheduleRepository;
  final TelemetryRepositoryContract _telemetryRepository;

  /// Stream of confirmed event IDs
  @override
  final StreamValue<Set<String>> confirmedEventIdsStream =
      StreamValue<Set<String>>(defaultValue: const {});

  /// In-memory storage for confirmed event IDs
  /// We use the stream value as the source of truth
  Set<String> get _confirmedEventIds => confirmedEventIdsStream.value;

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async {
    // Fetch all upcoming events and filter by confirmed IDs
    final allEvents = await _scheduleRepository.fetchUpcomingEvents();
    return allEvents
        .where((event) => _confirmedEventIds.contains(event.id))
        .toList();
  }

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async {
    // For now, return empty list
    // TODO: Implement featured events logic (recommendations, etc.)
    return [];
  }

  @override
  Future<void> confirmEventAttendance(String eventId) async {
    final newSet = Set<String>.from(_confirmedEventIds)..add(eventId);
    confirmedEventIdsStream.addValue(newSet);
    await _telemetryRepository.logEvent(
      EventTrackerEvents.eventConfirmedPresence,
      eventName: 'event_confirmed_presence',
      properties: {
        'event_id': eventId,
      },
    );
    // TODO: Call backend API when available
  }

  @override
  Future<void> unconfirmEventAttendance(String eventId) async {
    final newSet = Set<String>.from(_confirmedEventIds)..remove(eventId);
    confirmedEventIdsStream.addValue(newSet);
    // TODO: Call backend API when available
  }

  @override
  bool isEventConfirmed(String eventId) {
    return _confirmedEventIds.contains(eventId);
  }
}
