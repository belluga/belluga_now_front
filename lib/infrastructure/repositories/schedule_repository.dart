import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/paged_events_result.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/domain/map/geo_distance.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_page_dto.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:get_it/get_it.dart';

class ScheduleRepository extends ScheduleRepositoryContract {
  static final Uri _defaultEventImage = Uri.parse(
    'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=800',
  );

  ScheduleRepository({ScheduleBackendContract? backend})
      : _backend = backend ?? GetIt.I.get<ScheduleBackendContract>();

  final ScheduleBackendContract _backend;
  List<EventDTO>? _cachedEvents;

  Future<List<EventDTO>> _loadEvents() async {
    if (_cachedEvents != null) {
      return _cachedEvents!;
    }
    final events = await _backend.fetchEvents();
    _cachedEvents = events;
    return events;
  }

  @override
  Future<List<EventModel>> getAllEvents() async {
    final events = await _loadEvents();
    return events.map((e) => EventModel.fromDto(e)).toList();
  }

  @override
  Future<List<EventModel>> getEventsByDate(DateTime date) async {
    final events = await getAllEvents();
    return events.where((event) {
      final eventDate = event.dateTimeStart.value;
      if (eventDate == null) {
        return false;
      }
      return eventDate.year == date.year &&
          eventDate.month == date.month &&
          eventDate.day == date.day;
    }).toList();
  }

  @override
  Future<EventModel?> getEventBySlug(String slug) async {
    final normalizedSlug = _normalizeSlug(slug);
    final events = await getAllEvents();
    for (final event in events) {
      final idValue = event.id.value;
      if (idValue == slug) {
        return event;
      }

      if (event.slug == slug) {
        return event;
      }

      final titleSlug = _normalizeSlug(event.title.value);
      if (titleSlug == normalizedSlug) {
        return event;
      }
    }
    return null;
  }

  String _normalizeSlug(String value) {
    final slug = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final cleaned = slug.replaceAll(RegExp(r'-{2,}'), '-');
    return cleaned.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  @override
  Future<ScheduleSummaryModel> getScheduleSummary() async {
    final summary = await _backend.fetchSummary();
    return ScheduleSummaryModel.fromDto(summary);
  }

  @override
  Future<PagedEventsResult> getEventsPage({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    String searchQuery = '',
  }) async {
    final EventPageDTO pageDto = await _backend.fetchEventsPage(
      page: page,
      pageSize: pageSize,
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
    );

    final events = pageDto.events
        .map((e) => EventModel.fromDto(e))
        .toList(growable: false);

    return PagedEventsResult(
      events: events,
      hasMore: pageDto.hasMore,
    );
  }

  @override
  Future<List<VenueEventResume>> getEventResumesByDate(DateTime date) async {
    final events = await getEventsByDate(date);
    return events
        .map(
          (event) => VenueEventResume.fromScheduleEvent(
            event,
            _defaultEventImage,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<VenueEventResume>> fetchUpcomingEvents() async {
    final events = await getAllEvents();
    final now = DateTime.now();
    const assumedDuration = Duration(hours: 3);
    const radiusMeters = 50000.0;

    bool isHappeningNow(EventModel e) {
      final start = e.dateTimeStart.value;
      if (start == null) return false;
      final end = e.dateTimeEnd?.value ?? start.add(assumedDuration);
      final started = !now.isBefore(start);
      final notEnded = now.isBefore(end);
      return started && notEnded;
    }

    final upcomingOrNow = events.where((e) {
      final start = e.dateTimeStart.value;
      if (start == null) return false;
      return start.isAfter(now) || isHappeningNow(e);
    }).toList();

    final listToMap = upcomingOrNow.isNotEmpty ? upcomingOrNow : events;

    final sorted =
        _filterWithinRadiusThenSortByTime(listToMap, radiusMeters: radiusMeters);

    return sorted
        .map(
          (event) => VenueEventResume.fromScheduleEvent(
            event,
            _defaultEventImage,
          ),
        )
        .toList(growable: false);
  }

  List<EventModel> _filterWithinRadiusThenSortByTime(
    List<EventModel> input, {
    required double radiusMeters,
  }) {
    if (!GetIt.I.isRegistered<UserLocationRepositoryContract>()) {
      return _sortByStartTime(input);
    }

    final userCoordinate =
        GetIt.I.get<UserLocationRepositoryContract>().userLocationStreamValue.value;
    if (userCoordinate == null) {
      return _sortByStartTime(input);
    }

    final withinRadius = <EventModel>[];
    for (final event in input) {
      final coordinate = event.coordinate;
      if (coordinate == null) {
        continue;
      }
      final distance = haversineDistanceMeters(
        lat1: userCoordinate.latitude,
        lon1: userCoordinate.longitude,
        lat2: coordinate.latitude,
        lon2: coordinate.longitude,
      );
      if (distance <= radiusMeters) {
        withinRadius.add(event);
      }
    }

    // Fallback: if nothing is inside the radius, keep the original list.
    final filtered = withinRadius.isNotEmpty ? withinRadius : input;
    return _sortByStartTime(filtered);
  }

  List<EventModel> _sortByStartTime(List<EventModel> input) {
    final sorted = [...input];
    sorted.sort((a, b) {
      final aStart = a.dateTimeStart.value;
      final bStart = b.dateTimeStart.value;
      if (aStart == null && bStart == null) return 0;
      if (aStart == null) return 1;
      if (bStart == null) return -1;
      return aStart.compareTo(bStart);
    });
    return sorted;
  }
}
