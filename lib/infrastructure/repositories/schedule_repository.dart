import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/paged_events_result.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/domain/map/geo_distance.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_delta_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_page_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/artist_dto_mapper.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/invite_dto_mapper.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/invite_status_dto_mapper.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/partner_dto_mapper.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/schedule_dto_mapper.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/thumb_dto_mapper.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:get_it/get_it.dart';

class ScheduleRepository extends ScheduleRepositoryContract
    with
        InviteDtoMapper,
        ThumbDtoMapper,
        ArtistDtoMapper,
        PartnerDtoMapper,
        InviteStatusDtoMapper,
        ScheduleDtoMapper {
  static final Uri _defaultEventImage = Uri.parse(
    'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=800',
  );

  ScheduleRepository({
    ScheduleBackendContract? backend,
    BackendContract? backendContract,
  }) : _backend =
            backend ?? (backendContract ?? GetIt.I.get<BackendContract>())
                .schedule;

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
    return events.map(mapEventDto).toList();
  }

  @override
  Future<List<EventModel>> getEventsByDate(
    DateTime date, {
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final includePast = normalizedDate.isBefore(todayDate) ||
        normalizedDate.isAtSameMomentAs(todayDate);

    final upcoming = await _fetchEventsForDate(
      normalizedDate,
      showPastOnly: false,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );

    if (!includePast) {
      return upcoming;
    }

    final past = await _fetchEventsForDate(
      normalizedDate,
      showPastOnly: true,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );

    final merged = <String, EventModel>{};
    for (final event in [...upcoming, ...past]) {
      merged[event.id.value] = event;
    }
    return merged.values.toList();
  }

  @override
  Future<EventModel?> getEventBySlug(String slug) async {
    final dto = await _backend.fetchEventDetail(eventIdOrSlug: slug);
    if (dto != null) {
      return mapEventDto(dto);
    }
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
    return mapScheduleSummaryDto(summary);
  }

  @override
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
  }) async {
    final EventPageDTO pageDto = await _backend.fetchEventsPage(
      page: page,
      pageSize: pageSize,
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      categories: categories,
      tags: tags,
      taxonomy: taxonomy,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );

    final events = pageDto.events
        .map(mapEventDto)
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

  @override
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
  }) {
    return _backend
        .watchEventsStream(
          searchQuery: searchQuery,
          categories: categories,
          tags: tags,
          taxonomy: taxonomy,
          confirmedOnly: confirmedOnly,
          originLat: originLat,
          originLng: originLng,
          maxDistanceMeters: maxDistanceMeters,
          lastEventId: lastEventId,
          showPastOnly: showPastOnly,
        )
        .map(_mapDelta);
  }

  EventDeltaModel _mapDelta(EventDeltaDTO dto) {
    return EventDeltaModel(
      eventId: dto.eventId,
      type: _parseDeltaType(dto.type),
      updatedAt: dto.updatedAt,
      lastEventId: dto.lastEventId,
    );
  }

  EventDeltaType _parseDeltaType(String type) {
    switch (type) {
      case 'event.created':
        return EventDeltaType.created;
      case 'event.updated':
        return EventDeltaType.updated;
      case 'event.deleted':
        return EventDeltaType.deleted;
      default:
        return EventDeltaType.unknown;
    }
  }

  Future<List<EventModel>> _fetchEventsForDate(
    DateTime date, {
    required bool showPastOnly,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async {
    final matches = <EventModel>[];
    var page = 1;
    var hasMore = true;
    const pageSize = 25;

    while (hasMore && page <= 8) {
      final pageDto = await _backend.fetchEventsPage(
        page: page,
        pageSize: pageSize,
        showPastOnly: showPastOnly,
        originLat: originLat,
        originLng: originLng,
        maxDistanceMeters: maxDistanceMeters,
      );

      for (final event in pageDto.events) {
        final parsed = mapEventDto(event);
        final start = parsed.dateTimeStart.value;
        if (start == null) continue;
        if (_isSameDate(start, date)) {
          matches.add(parsed);
        }
      }

      hasMore = pageDto.hasMore;
      if (pageDto.events.isEmpty) break;
      final lastDate = _parseDate(pageDto.events.last);
      if (lastDate != null) {
        if (!showPastOnly && lastDate.isAfter(date)) {
          break;
        }
        if (showPastOnly && lastDate.isBefore(date)) {
          break;
        }
      }
      page += 1;
    }

    return matches;
  }


  DateTime? _parseDate(EventDTO event) {
    final parsed = DateTime.tryParse(event.dateTimeStart);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
