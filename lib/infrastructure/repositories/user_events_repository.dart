import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/user_events_backend/laravel_user_events_backend.dart';
import 'package:belluga_now/infrastructure/services/user_events_backend_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

/// Implementation of UserEventsRepositoryContract
/// Uses backend-authoritative attendance commitments for confirmation state.
class UserEventsRepository implements UserEventsRepositoryContract {
  static final Uri _defaultEventImage = Uri.parse(
    'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=800',
  );
  static const int _myEventsPageSize = 10;
  static const int _maxMyEventsPages = 30;

  UserEventsRepository({
    ScheduleRepositoryContract? scheduleRepository,
    UserEventsBackendContract? backend,
  })  : _scheduleRepository =
            scheduleRepository ?? GetIt.I.get<ScheduleRepositoryContract>(),
        _backend = backend ?? LaravelUserEventsBackend();

  final ScheduleRepositoryContract _scheduleRepository;
  final UserEventsBackendContract _backend;

  /// Stream of confirmed event IDs
  @override
  final StreamValue<Set<String>> confirmedEventIdsStream =
      StreamValue<Set<String>>(defaultValue: const {});

  /// In-memory storage for confirmed event IDs
  /// We use the stream value as the source of truth
  Set<String> get _confirmedEventIds => confirmedEventIdsStream.value;

  @override
  Future<void> refreshConfirmedEventIds() async {
    final response = await _backend.fetchConfirmedEventIds();
    final eventIdsRaw = response['confirmed_event_ids'];
    if (eventIdsRaw is! List) {
      confirmedEventIdsStream.addValue(const {});
      return;
    }

    final next = eventIdsRaw
        .map((item) => item?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet();
    confirmedEventIdsStream.addValue(next);
  }

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async {
    final events = <VenueEventResume>[];
    var currentPage = 1;
    var hasMore = true;

    while (hasMore && currentPage <= _maxMyEventsPages) {
      final page = await _scheduleRepository.getEventsPage(
        page: currentPage,
        pageSize: _myEventsPageSize,
        showPastOnly: false,
        confirmedOnly: true,
      );

      events.addAll(
        page.events.map(
          (event) => VenueEventResume.fromScheduleEvent(
            event,
            _defaultEventImage,
          ),
        ),
      );

      hasMore = page.hasMore;
      currentPage += 1;
    }

    return List<VenueEventResume>.unmodifiable(events);
  }

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async {
    return [];
  }

  @override
  Future<void> confirmEventAttendance(String eventId) async {
    await _backend.confirmAttendance(eventId: eventId);
    await refreshConfirmedEventIds();
  }

  @override
  Future<void> unconfirmEventAttendance(String eventId) async {
    await _backend.unconfirmAttendance(eventId: eventId);
    await refreshConfirmedEventIds();
  }

  @override
  bool isEventConfirmed(String eventId) {
    return _confirmedEventIds.contains(eventId);
  }
}
