import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

/// Implementation of UserEventsRepositoryContract
/// Tracks user-event relationships in memory (mock implementation)
class UserEventsRepository implements UserEventsRepositoryContract {
  UserEventsRepository({
    ScheduleRepositoryContract? scheduleRepository,
  }) : _scheduleRepository =
            scheduleRepository ?? GetIt.I.get<ScheduleRepositoryContract>();

  final ScheduleRepositoryContract _scheduleRepository;

  /// Stream of confirmed event slugs
  @override
  final StreamValue<Set<String>> confirmedEventSlugsStream =
      StreamValue<Set<String>>(defaultValue: const {});

  /// In-memory storage for confirmed event slugs
  /// We use the stream value as the source of truth
  Set<String> get _confirmedEventSlugs => confirmedEventSlugsStream.value;

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async {
    // Fetch all upcoming events and filter by confirmed slugs
    final allEvents = await _scheduleRepository.fetchUpcomingEvents();
    return allEvents
        .where((event) => _confirmedEventSlugs.contains(event.slug))
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
    final newSet = Set<String>.from(_confirmedEventSlugs)..add(eventId);
    confirmedEventSlugsStream.addValue(newSet);
    // TODO: Call backend API when available
  }

  @override
  Future<void> unconfirmEventAttendance(String eventId) async {
    final newSet = Set<String>.from(_confirmedEventSlugs)..remove(eventId);
    confirmedEventSlugsStream.addValue(newSet);
    // TODO: Call backend API when available
  }

  @override
  bool isEventConfirmed(String eventId) {
    return _confirmedEventSlugs.contains(eventId);
  }
}
