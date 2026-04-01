import 'package:belluga_now/domain/map/geo_distance.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/schedule_repository_contract_values.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/paged_events_result.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/domain/services/location_origin_service_contract.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_page_dto.dart';
import 'package:belluga_now/infrastructure/services/location_origin_resolution_request_factory.dart';
import 'package:belluga_now/infrastructure/services/location_origin_service.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class ScheduleRepository extends ScheduleRepositoryContract {
  static final Uri _localEventPlaceholderUri =
      Uri.parse('asset://event-placeholder');
  static const int _maxPagedFetches = 8;
  static const int _defaultPageSize = 25;
  static const double _homeAgendaCacheReuseMaxOriginJumpMeters = 1000.0;

  ScheduleRepository({
    ScheduleBackendContract? backend,
    BackendContract? backendContract,
    UserLocationRepositoryContract? userLocationRepository,
    AppDataRepositoryContract? appDataRepository,
    LocationOriginServiceContract? locationOriginService,
  })  : _backend = backend ??
            (backendContract ?? GetIt.I.get<BackendContract>()).schedule,
        _userLocationRepository = userLocationRepository,
        _appDataRepository = appDataRepository,
        _locationOriginService = locationOriginService;

  final ScheduleBackendContract _backend;
  final UserLocationRepositoryContract? _userLocationRepository;
  AppDataRepositoryContract? _appDataRepository;
  LocationOriginServiceContract? _locationOriginService;
  @override
  final StreamValue<List<EventModel>?> homeAgendaEventsStreamValue =
      StreamValue<List<EventModel>?>();
  @override
  final StreamValue<HomeAgendaCacheSnapshot?> homeAgendaCacheStreamValue =
      StreamValue<HomeAgendaCacheSnapshot?>();

  @override
  HomeAgendaCacheSnapshot? readHomeAgendaCache({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) {
    final snapshot = homeAgendaCacheStreamValue.value;
    if (snapshot == null) {
      return null;
    }
    if (snapshot.showPastOnly != showPastOnly.value) {
      return null;
    }
    if (snapshot.searchQuery != searchQuery.value) {
      return null;
    }
    if (snapshot.confirmedOnly != confirmedOnly.value) {
      return null;
    }
    if (!_matchesHomeAgendaOrigin(
      snapshot: snapshot,
      requestedOriginLat: originLat?.value,
      requestedOriginLng: originLng?.value,
    )) {
      return null;
    }
    if (!_matchesHomeAgendaMaxDistance(
      snapshot: snapshot,
      requestedMaxDistanceMeters: maxDistanceMeters?.value,
    )) {
      return null;
    }
    return snapshot;
  }

  bool _matchesHomeAgendaOrigin({
    required HomeAgendaCacheSnapshot snapshot,
    required double? requestedOriginLat,
    required double? requestedOriginLng,
  }) {
    final snapshotOriginLat = snapshot.originLat;
    final snapshotOriginLng = snapshot.originLng;

    if (requestedOriginLat == null || requestedOriginLng == null) {
      return snapshotOriginLat == null && snapshotOriginLng == null;
    }

    if (snapshotOriginLat == null || snapshotOriginLng == null) {
      return false;
    }

    final jumpMeters = haversineDistanceMeters(
      coordinateA: CityCoordinate(
        latitudeValue: LatitudeValue()..parse(snapshotOriginLat.toString()),
        longitudeValue: LongitudeValue()..parse(snapshotOriginLng.toString()),
      ),
      coordinateB: CityCoordinate(
        latitudeValue: LatitudeValue()..parse(requestedOriginLat.toString()),
        longitudeValue: LongitudeValue()..parse(requestedOriginLng.toString()),
      ),
    );

    return jumpMeters.value < _homeAgendaCacheReuseMaxOriginJumpMeters;
  }

  bool _matchesHomeAgendaMaxDistance({
    required HomeAgendaCacheSnapshot snapshot,
    required double? requestedMaxDistanceMeters,
  }) {
    final snapshotMaxDistanceMeters = snapshot.maxDistanceMeters;

    if (requestedMaxDistanceMeters == null) {
      return snapshotMaxDistanceMeters == null;
    }

    if (snapshotMaxDistanceMeters == null) {
      return false;
    }

    return (snapshotMaxDistanceMeters - requestedMaxDistanceMeters).abs() <
        0.001;
  }

  @override
  void writeHomeAgendaCache(HomeAgendaCacheSnapshot snapshot) {
    homeAgendaCacheStreamValue.addValue(snapshot);
    homeAgendaEventsStreamValue.addValue(snapshot.events);
  }

  @override
  void clearHomeAgendaCache() {
    homeAgendaCacheStreamValue.addValue(null);
    homeAgendaEventsStreamValue.addValue(null);
  }

  Future<void> initializeHomeAgendaStreams() async {
    homeAgendaCacheStreamValue.addValue(homeAgendaCacheStreamValue.value);
    homeAgendaEventsStreamValue.addValue(homeAgendaEventsStreamValue.value);
  }

  Future<void> refreshHomeAgendaStreams() async {
    homeAgendaCacheStreamValue.addValue(homeAgendaCacheStreamValue.value);
    homeAgendaEventsStreamValue.addValue(homeAgendaEventsStreamValue.value);
  }

  AppDataRepositoryContract? get _resolvedAppDataRepository {
    if (_appDataRepository != null) {
      return _appDataRepository;
    }
    if (!GetIt.I.isRegistered<AppDataRepositoryContract>()) {
      return null;
    }
    _appDataRepository = GetIt.I.get<AppDataRepositoryContract>();
    return _appDataRepository;
  }

  LocationOriginServiceContract? get _resolvedLocationOriginService {
    if (_locationOriginService != null) {
      return _locationOriginService;
    }
    if (!GetIt.I.isRegistered<LocationOriginServiceContract>()) {
      final appDataRepository = _resolvedAppDataRepository;
      if (appDataRepository == null) {
        return null;
      }
      _locationOriginService = LocationOriginService(
        appDataRepository: appDataRepository,
        userLocationRepository: _userLocationRepository,
      );
      return _locationOriginService;
    }
    _locationOriginService = GetIt.I.get<LocationOriginServiceContract>();
    return _locationOriginService;
  }

  ThumbUriValue _resolveDefaultEventImage() {
    final configured =
        _resolvedAppDataRepository?.appData.mainLogoDarkUrl.value;
    final resolvedUri =
        (configured != null && configured.toString().trim().isNotEmpty)
            ? configured
            : _localEventPlaceholderUri;
    final thumbUriValue =
        ThumbUriValue(defaultValue: resolvedUri, isRequired: true)
          ..parse(resolvedUri.toString());
    return thumbUriValue;
  }

  @override
  Future<List<EventModel>> getAllEvents() async {
    final events = await _backend.fetchEvents();
    return events.map((dto) => dto.toDomain()).toList(growable: false);
  }

  @override
  Future<List<EventModel>> getEventsByDate(
    ScheduleRepoDateTime date, {
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    final dateValue = date.value;
    final normalizedDate =
        DateTime(dateValue.year, dateValue.month, dateValue.day);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final includePast = normalizedDate.isBefore(todayDate) ||
        normalizedDate.isAtSameMomentAs(todayDate);

    final upcoming = await _fetchEventsForDate(
      normalizedDate,
      showPastOnly: false,
      originLat: originLat?.value,
      originLng: originLng?.value,
      maxDistanceMeters: maxDistanceMeters?.value,
    );

    if (!includePast) {
      return upcoming;
    }

    final past = await _fetchEventsForDate(
      normalizedDate,
      showPastOnly: true,
      originLat: originLat?.value,
      originLng: originLng?.value,
      maxDistanceMeters: maxDistanceMeters?.value,
    );

    final merged = <String, EventModel>{};
    for (final event in [...upcoming, ...past]) {
      merged[event.id.value] = event;
    }
    return merged.values.toList();
  }

  @override
  Future<EventModel?> getEventBySlug(ScheduleRepoString slug) async {
    final slugValue = slug.value;
    final dto = await _backend.fetchEventDetail(eventIdOrSlug: slugValue);
    if (dto != null) {
      return dto.toDomain();
    }
    final normalizedSlug = _normalizeSlug(slugValue);
    final events = await getAllEvents();
    for (final event in events) {
      final idValue = event.id.value;
      if (idValue == slugValue) {
        return event;
      }

      if (event.slug == slugValue) {
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

  Map<String, String> _encodeTaxonomyEntry(ScheduleRepoTaxonomyEntry entry) {
    return <String, String>{
      'type': entry.type.value,
      'term': entry.term.value,
    };
  }

  @override
  Future<ScheduleSummaryModel> getScheduleSummary() async {
    final summary = await _backend.fetchSummary();
    return summary.toDomain();
  }

  @override
  Future<PagedEventsResult> getEventsPage({
    required ScheduleRepoInt page,
    required ScheduleRepoInt pageSize,
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoBool? liveNowOnly,
    ScheduleRepoString? searchQuery,
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    ScheduleRepoTaxonomyEntries? taxonomy,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    final EventPageDTO pageDto = await _backend.fetchEventsPage(
      page: page.value,
      pageSize: pageSize.value,
      showPastOnly: showPastOnly.value,
      liveNowOnly: liveNowOnly?.value ?? false,
      searchQuery: searchQuery?.value,
      categories: categories?.map((entry) => entry.value).toList(
            growable: false,
          ),
      tags: tags?.map((entry) => entry.value).toList(
            growable: false,
          ),
      taxonomy: taxonomy?.map(_encodeTaxonomyEntry).toList(
            growable: false,
          ),
      confirmedOnly: confirmedOnly?.value ?? false,
      originLat: originLat?.value,
      originLng: originLng?.value,
      maxDistanceMeters: maxDistanceMeters?.value,
    );

    final events =
        pageDto.events.map((event) => event.toDomain()).toList(growable: false);

    return pagedEventsResultFromRaw(
      events: events,
      hasMore: pageDto.hasMore,
    );
  }

  @override
  Future<List<VenueEventResume>> getEventResumesByDate(
      ScheduleRepoDateTime date) async {
    final events = await getEventsByDate(date);
    final fallbackImage = _resolveDefaultEventImage();
    return events
        .map(
          (event) => VenueEventResume.fromScheduleEvent(
            event,
            fallbackImage,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<VenueEventResume>> fetchUpcomingEvents() async {
    final effectiveOrigin = await _resolveEffectiveOrigin();
    if (effectiveOrigin == null) {
      return const [];
    }
    final events = await _fetchAllEventsWithOrigin(
      originLat: effectiveOrigin.latitude,
      originLng: effectiveOrigin.longitude,
    );
    final now = DateTime.now();
    const assumedDuration = Duration(hours: 3);

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
    final sorted = _sortByStartTime(listToMap);
    final fallbackImage = _resolveDefaultEventImage();

    return sorted
        .map(
          (event) => VenueEventResume.fromScheduleEvent(
            event,
            fallbackImage,
          ),
        )
        .toList(growable: false);
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
    ScheduleRepoString? searchQuery,
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    ScheduleRepoTaxonomyEntries? taxonomy,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
    ScheduleRepoString? lastEventId,
    ScheduleRepoBool? showPastOnly,
  }) {
    return _backend
        .watchEventsStream(
          searchQuery: searchQuery?.value,
          categories: categories?.map((entry) => entry.value).toList(
                growable: false,
              ),
          tags: tags?.map((entry) => entry.value).toList(
                growable: false,
              ),
          taxonomy: taxonomy?.map(_encodeTaxonomyEntry).toList(
                growable: false,
              ),
          confirmedOnly: confirmedOnly?.value ?? false,
          originLat: originLat?.value,
          originLng: originLng?.value,
          maxDistanceMeters: maxDistanceMeters?.value,
          lastEventId: lastEventId?.value,
          showPastOnly: showPastOnly?.value ?? false,
        )
        .map((deltaDto) => deltaDto.toDomain());
  }

  @override
  Stream<void> watchEventsSignal({
    required ScheduleRepositoryContractDeltaHandler onDelta,
    ScheduleRepoString? searchQuery,
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    ScheduleRepoTaxonomyEntries? taxonomy,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
    ScheduleRepoString? lastEventId,
    ScheduleRepoBool? showPastOnly,
  }) {
    return watchEventsStream(
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
    ).map((delta) {
      onDelta(delta);
    });
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
    while (hasMore && page <= _maxPagedFetches) {
      final pageDto = await _backend.fetchEventsPage(
        page: page,
        pageSize: _defaultPageSize,
        showPastOnly: showPastOnly,
        originLat: originLat,
        originLng: originLng,
        maxDistanceMeters: maxDistanceMeters,
      );

      for (final event in pageDto.events) {
        final parsed = event.toDomain();
        final start = parsed.dateTimeStart.value;
        if (start == null) continue;
        if (_isSameDate(start, date)) {
          matches.add(parsed);
        }
      }

      hasMore = pageDto.hasMore;
      if (pageDto.events.isEmpty) break;
      final lastDate = pageDto.events.last.dateOnly();
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

  Future<List<EventModel>> _fetchAllEventsWithOrigin({
    required double originLat,
    required double originLng,
  }) async {
    final events = <EventModel>[];
    var page = 1;
    var hasMore = true;

    while (hasMore && page <= _maxPagedFetches) {
      final pageDto = await _backend.fetchEventsPage(
        page: page,
        pageSize: _defaultPageSize,
        showPastOnly: false,
        originLat: originLat,
        originLng: originLng,
      );
      events.addAll(pageDto.events.map((dto) => dto.toDomain()));
      hasMore = pageDto.hasMore;
      if (pageDto.events.isEmpty) {
        break;
      }
      page += 1;
    }

    return events;
  }

  Future<CityCoordinate?> _resolveEffectiveOrigin() async {
    final locationOriginService = _resolvedLocationOriginService;
    if (locationOriginService == null) {
      return null;
    }
    final resolution = await locationOriginService.resolve(
      LocationOriginResolutionRequestFactory.create(
        warmUpIfPossible: true,
      ),
    );
    return resolution.effectiveCoordinate;
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
