import 'dart:async';

import 'package:belluga_now/domain/app_data/location_origin_resolution.dart';
import 'package:belluga_now/domain/app_data/location_origin_settings.dart';
import 'package:belluga_now/domain/map/geo_distance.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/schedule_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/services/location_origin_service_contract.dart';
import 'package:belluga_now/infrastructure/services/location_origin_resolution_request_factory.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/agenda_app_bar_controller.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class EventSearchScreenController
    implements Disposable, AgendaAppBarController {
  EventSearchScreenController({
    ScheduleRepositoryContract? scheduleRepository,
    UserEventsRepositoryContract? userEventsRepository,
    InvitesRepositoryContract? invitesRepository,
    UserLocationRepositoryContract? userLocationRepository,
    AppDataRepositoryContract? appDataRepository,
    LocationOriginServiceContract? locationOriginService,
    TelemetryRepositoryContract? telemetryRepository,
  })  : _scheduleRepository =
            scheduleRepository ?? GetIt.I.get<ScheduleRepositoryContract>(),
        _userEventsRepository =
            userEventsRepository ?? GetIt.I.get<UserEventsRepositoryContract>(),
        _invitesRepository =
            invitesRepository ?? GetIt.I.get<InvitesRepositoryContract>(),
        _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>(),
        _telemetryRepository = telemetryRepository ??
            (GetIt.I.isRegistered<TelemetryRepositoryContract>()
                ? GetIt.I.get<TelemetryRepositoryContract>()
                : null),
        _locationOriginService = locationOriginService ??
            GetIt.I.get<LocationOriginServiceContract>() {
    _initializeStateHolders();
  }

  final ScheduleRepositoryContract _scheduleRepository;
  final UserEventsRepositoryContract _userEventsRepository;
  final InvitesRepositoryContract _invitesRepository;
  final AppDataRepositoryContract _appDataRepository;
  final TelemetryRepositoryContract? _telemetryRepository;
  final LocationOriginServiceContract _locationOriginService;

  static const double _fallbackRadiusMeters = 50000.0;
  static const double _radiusTelemetryChangeEpsilon = 0.001;
  static const double _radiusCompactScrollEpsilon = 0.5;
  static const String _radiusChangedEventName = 'agenda_radius_changed';
  static const String _radiusChangedSurface = 'agenda';
  static final Uri _localEventPlaceholderUri =
      Uri.parse('asset://event-placeholder');

  @override
  late TextEditingController searchController;
  @override
  late FocusNode focusNode;
  late ScrollController scrollController;

  late StreamValue<List<VenueEventResume>> displayedEventsStreamValue;
  late StreamValue<bool> isInitialLoadingStreamValue;
  late StreamValue<bool> isPageLoadingStreamValue;
  late StreamValue<bool> hasMoreStreamValue;
  @override
  late StreamValue<bool> showHistoryStreamValue;
  @override
  late StreamValue<bool> searchActiveStreamValue;
  @override
  late StreamValue<InviteFilter> inviteFilterStreamValue;
  @override
  late StreamValue<double> radiusMetersStreamValue;
  @override
  late StreamValue<bool> isRadiusRefreshLoadingStreamValue;
  @override
  late StreamValue<bool> isRadiusActionCompactStreamValue;
  late StreamValue<double> _maxRadiusMetersStreamValue;

  StreamSubscription? _confirmedEventsSubscription;
  StreamSubscription? _pendingInvitesSubscription;
  StreamSubscription<LocationOriginResolution?>? _effectiveOriginSubscription;
  StreamSubscription? _radiusSubscription;
  StreamSubscription? _eventsStreamSubscription;
  bool _isStreamRefreshing = false;
  String? _lastEventStreamId;
  final List<EventModel> _fetchedEvents = [];
  bool _isFetching = false;
  bool _hasMore = true;
  bool _isScrollListenerAttached = false;
  bool _isDisposed = false;
  bool _isAutoPaging = false;
  double? _effectiveOriginLat;
  double? _effectiveOriginLng;
  LocationOriginSettings? _effectiveOriginSettings;

  Uri get defaultEventImageUri {
    final configured = _appDataRepository.appData.mainLogoDarkUrl.value;
    if (configured != null && configured.toString().trim().isNotEmpty) {
      return configured;
    }
    return _localEventPlaceholderUri;
  }

  void _ifAlive(VoidCallback writer) {
    if (_isDisposed) return;
    writer();
  }

  ScheduleRepoBool _toScheduleBool(bool value) {
    return ScheduleRepoBool.fromRaw(
      value,
      defaultValue: value,
    );
  }

  ScheduleRepoString _toScheduleText(String value) {
    return ScheduleRepoString.fromRaw(
      value,
      defaultValue: value,
    );
  }

  ScheduleRepoDouble _toScheduleDouble(double value) {
    return ScheduleRepoDouble.fromRaw(
      value,
      defaultValue: value,
    );
  }

  ScheduleRepoDouble? _toNullableScheduleDouble(double? value) {
    if (value == null) {
      return null;
    }
    return _toScheduleDouble(value);
  }

  void _initializeStateHolders() {
    searchController = TextEditingController();
    focusNode = FocusNode();
    scrollController = ScrollController();
    displayedEventsStreamValue = StreamValue<List<VenueEventResume>>(
      defaultValue: const <VenueEventResume>[],
    );
    isInitialLoadingStreamValue = StreamValue<bool>(defaultValue: true);
    isPageLoadingStreamValue = StreamValue<bool>(defaultValue: false);
    hasMoreStreamValue = StreamValue<bool>(defaultValue: true);
    showHistoryStreamValue = StreamValue<bool>(defaultValue: false);
    searchActiveStreamValue = StreamValue<bool>(defaultValue: false);
    inviteFilterStreamValue =
        StreamValue<InviteFilter>(defaultValue: InviteFilter.none);
    radiusMetersStreamValue =
        StreamValue<double>(defaultValue: _fallbackRadiusMeters);
    isRadiusRefreshLoadingStreamValue = StreamValue<bool>(defaultValue: false);
    isRadiusActionCompactStreamValue = StreamValue<bool>(defaultValue: false);
    _maxRadiusMetersStreamValue =
        StreamValue<double>(defaultValue: _fallbackRadiusMeters);
    _isScrollListenerAttached = false;
  }

  void _resetInternalState() {
    _fetchedEvents.clear();
    _isFetching = false;
    _hasMore = true;
  }

  Future<void> init({bool startWithHistory = false}) async {
    if (_isDisposed) {
      _initializeStateHolders();
      _isDisposed = false;
    }
    await _invitesRepository.init();
    _resetInternalState();
    _ifAlive(() => showHistoryStreamValue.addValue(startWithHistory));
    _ifAlive(
        () => radiusMetersStreamValue.addValue(_resolveDefaultRadiusMeters()));
    _attachScrollListener();
    _listenForStatusChanges();
    _listenForRadiusChanges();
    await _resolveEffectiveOrigin(warmUpIfPossible: true);
    _listenForCanonicalOriginChanges();
    await _refresh(warmUpIfPossible: false);
    _restartEventStream();
  }

  void _attachScrollListener() {
    if (_isScrollListenerAttached) return;
    _isScrollListenerAttached = true;
    scrollController.addListener(_handleScrollChanged);
    _syncRadiusActionCompactStateWithCurrentOffset();
  }

  void _handleScrollChanged() {
    _syncRadiusActionCompactStateWithCurrentOffset();
    if (!scrollController.hasClients ||
        !_hasMore ||
        _isFetching ||
        isInitialLoadingStreamValue.value ||
        !hasMoreStreamValue.value) {
      return;
    }

    final position = scrollController.position;
    const threshold = 320.0;
    if (position.pixels + threshold >= position.maxScrollExtent) {
      loadNextPage();
    }
  }

  void _syncRadiusActionCompactStateWithCurrentOffset() {
    if (scrollController.hasClients) {
      _updateRadiusActionCompactState(scrollController.position.pixels);
      return;
    }

    final attachedScrollController = scrollController;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed ||
          !identical(scrollController, attachedScrollController)) {
        return;
      }
      if (!attachedScrollController.hasClients) {
        return;
      }
      _updateRadiusActionCompactState(
        attachedScrollController.position.pixels,
      );
    });
  }

  void _updateRadiusActionCompactState(double pixels) {
    final shouldCompact = pixels > _radiusCompactScrollEpsilon;
    if (shouldCompact == isRadiusActionCompactStreamValue.value) {
      return;
    }
    _ifAlive(() => isRadiusActionCompactStreamValue.addValue(shouldCompact));
  }

  Future<void> _refresh({bool warmUpIfPossible = true}) async {
    await _waitForOngoingFetch();
    _hasMore = true;
    _ifAlive(() => hasMoreStreamValue.addValue(true));
    _fetchedEvents.clear();
    _ifAlive(
      () => displayedEventsStreamValue.addValue(const <VenueEventResume>[]),
    );
    _ifAlive(() => isInitialLoadingStreamValue.addValue(true));
    try {
      await _resolveEffectiveOrigin(warmUpIfPossible: warmUpIfPossible);
      if (!_hasEffectiveOrigin) {
        _hasMore = false;
        _ifAlive(() => hasMoreStreamValue.addValue(false));
        _ifAlive(
          () => displayedEventsStreamValue.addValue(const <VenueEventResume>[]),
        );
        return;
      }

      if (_shouldShortCircuitPendingOnlyQuery) {
        _hasMore = false;
        _ifAlive(() => hasMoreStreamValue.addValue(false));
        _ifAlive(
          () => displayedEventsStreamValue.addValue(const <VenueEventResume>[]),
        );
        return;
      }

      _hasMore = true;
      _ifAlive(() => hasMoreStreamValue.addValue(true));
      await _fetchFirstPage();
    } catch (error) {
      debugPrint('EventSearchScreenController._refresh failed: $error');
    } finally {
      _ifAlive(() => isInitialLoadingStreamValue.addValue(false));
    }
  }

  Future<void> _waitForOngoingFetch() async {
    while (_isFetching) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> loadNextPage() async {
    if (!_hasEffectiveOrigin || !_hasMore || _isFetching) return;
    await _fetchNextPage();
  }

  Future<void> _fetchFirstPage() async {
    if (_isFetching || !_hasEffectiveOrigin) return;
    _isFetching = true;

    try {
      final queryShowPastOnly = _toScheduleBool(showHistoryStreamValue.value);
      final querySearch = _toScheduleText(searchController.text);
      final queryConfirmedOnly = _toScheduleBool(
        inviteFilterStreamValue.value == InviteFilter.confirmedOnly,
      );
      final queryOccurrenceIds = _activeOccurrenceIdsFilter();
      final queryOriginLat = _toNullableScheduleDouble(_effectiveOriginLat);
      final queryOriginLng = _toNullableScheduleDouble(_effectiveOriginLng);
      final queryMaxDistance = _toScheduleDouble(radiusMetersStreamValue.value);
      final events = await _scheduleRepository.loadEventSearch(
        showPastOnly: queryShowPastOnly,
        searchQuery: querySearch,
        confirmedOnly: queryConfirmedOnly,
        occurrenceIds: queryOccurrenceIds,
        originLat: queryOriginLat,
        originLng: queryOriginLng,
        maxDistanceMeters: queryMaxDistance,
      );

      if (_isDisposed) return;
      _fetchedEvents
        ..clear()
        ..addAll(events);

      _hasMore = events.isNotEmpty;
      _ifAlive(() => hasMoreStreamValue.addValue(_hasMore));
      _applyFiltersAndPublish();
    } finally {
      _isFetching = false;
      if (!_isDisposed) {
        isPageLoadingStreamValue.addValue(false);
      }
    }
  }

  Future<void> _fetchNextPage() async {
    if (_isFetching || !_hasEffectiveOrigin) return;
    _isFetching = true;
    if (!_isDisposed) {
      isPageLoadingStreamValue.addValue(true);
    }

    try {
      final queryShowPastOnly = _toScheduleBool(showHistoryStreamValue.value);
      final querySearch = _toScheduleText(searchController.text);
      final queryConfirmedOnly = _toScheduleBool(
        inviteFilterStreamValue.value == InviteFilter.confirmedOnly,
      );
      final queryOccurrenceIds = _activeOccurrenceIdsFilter();
      final queryOriginLat = _toNullableScheduleDouble(_effectiveOriginLat);
      final queryOriginLng = _toNullableScheduleDouble(_effectiveOriginLng);
      final queryMaxDistance = _toScheduleDouble(radiusMetersStreamValue.value);
      final events = await _scheduleRepository.loadMoreEventSearch(
        showPastOnly: queryShowPastOnly,
        searchQuery: querySearch,
        confirmedOnly: queryConfirmedOnly,
        occurrenceIds: queryOccurrenceIds,
        originLat: queryOriginLat,
        originLng: queryOriginLng,
        maxDistanceMeters: queryMaxDistance,
      );

      if (_isDisposed) return;
      if (events.isNotEmpty) {
        _fetchedEvents.addAll(events);
      }
      _hasMore = events.isNotEmpty;
      _ifAlive(() => hasMoreStreamValue.addValue(_hasMore));
      _applyFiltersAndPublish();
    } finally {
      _isFetching = false;
      if (!_isDisposed) {
        isPageLoadingStreamValue.addValue(false);
      }
    }
  }

  @override
  void toggleHistory() {
    final currentValue = showHistoryStreamValue.value;
    _ifAlive(() => showHistoryStreamValue.addValue(!currentValue));
    _refresh();
    _restartEventStream();
  }

  void setInviteFilter(InviteFilter filter) {
    _ifAlive(() => inviteFilterStreamValue.addValue(filter));
    _applyFiltersAndPublish();
    unawaited(_refresh(warmUpIfPossible: false));
    _restartEventStream();
  }

  @override
  void cycleInviteFilter() {
    setInviteFilter(inviteFilterStreamValue.value.next);
  }

  void setSearchActive(bool active) {
    _ifAlive(() => searchActiveStreamValue.addValue(active));
    if (active) {
      focusNode.requestFocus();
    } else {
      focusNode.unfocus();
    }
  }

  @override
  void toggleSearchMode() {
    setSearchActive(!searchActiveStreamValue.value);
  }

  @override
  void setRadiusMeters(double meters) {
    if (meters <= 0) return;
    final previousRadius = radiusMetersStreamValue.value;
    final clampedRadius = _clampRadiusMeters(meters);
    _ifAlive(() => radiusMetersStreamValue.addValue(clampedRadius));
    if (_didRadiusChangeEffectively(
      previousRadius: previousRadius,
      nextRadius: clampedRadius,
    )) {
      unawaited(
        _logRadiusChangedTelemetry(
          previousRadiusMeters: previousRadius,
          selectedRadiusMeters: clampedRadius,
        ),
      );
    }
    unawaited(_refresh());
    _restartEventStream();
  }

  bool _didRadiusChangeEffectively({
    required double previousRadius,
    required double nextRadius,
  }) {
    return (nextRadius - previousRadius).abs() > _radiusTelemetryChangeEpsilon;
  }

  Future<void> _logRadiusChangedTelemetry({
    required double previousRadiusMeters,
    required double selectedRadiusMeters,
  }) async {
    final telemetryRepository = _telemetryRepository;
    if (telemetryRepository == null) {
      return;
    }
    await telemetryRepository.logEvent(
      EventTrackerEvents.selectItem,
      eventName: telemetryRepoString(_radiusChangedEventName),
      properties: telemetryRepoMap(<String, dynamic>{
        'surface': _radiusChangedSurface,
        'previous_radius_meters': previousRadiusMeters.round(),
        'selected_radius_meters': selectedRadiusMeters.round(),
      }),
    );
  }

  void setInitialSearchQuery(String? query) {
    final normalized = query?.trim() ?? '';
    if (normalized.isEmpty) return;
    searchController.text = normalized;
    searchController.selection =
        TextSelection.fromPosition(TextPosition(offset: normalized.length));
    unawaited(_refresh());
    _restartEventStream();
  }

  @override
  Future<void> searchEvents(String query) async {
    await _refresh(warmUpIfPossible: false);
    _restartEventStream();
  }

  List<EventModel> _applyInviteFilter(List<EventModel> events) {
    final filter = inviteFilterStreamValue.value;
    if (filter == InviteFilter.none) return events;

    final confirmedIds =
        _userEventsRepository.confirmedOccurrenceIdsStream.value;
    final pendingIds = _invitesRepository.pendingInvitesStreamValue.value
        .map((invite) => invite.occurrenceId?.trim() ?? '')
        .where((occurrenceId) => occurrenceId.isNotEmpty)
        .toSet();

    bool isConfirmed(String id) =>
        confirmedIds.any((confirmed) => confirmed.value == id);
    bool hasPending(String id) => pendingIds.contains(id);

    return events.where((event) {
      final id = _eventOccurrenceIdentity(event);
      switch (filter) {
        case InviteFilter.none:
          return true;
        case InviteFilter.pendingOnly:
          return hasPending(id);
        case InviteFilter.confirmedOnly:
          return isConfirmed(id);
      }
    }).toList();
  }

  void _applyFiltersAndPublish() {
    if (_isDisposed) return;
    final inviteFiltered = _applyInviteFilter(_fetchedEvents);
    displayedEventsStreamValue.addValue(
      inviteFiltered.map(_toVenueEventResume).toList(growable: false),
    );
    _maybeAutoPage(inviteFiltered);
  }

  void _maybeAutoPage(List<EventModel> filtered) {
    if (filtered.isNotEmpty ||
        !_hasMore ||
        _isAutoPaging ||
        inviteFilterStreamValue.value == InviteFilter.pendingOnly) {
      return;
    }
    unawaited(_autoPageToFirstMatch());
  }

  Future<void> _autoPageToFirstMatch() async {
    _isAutoPaging = true;
    try {
      while (_hasMore) {
        await _waitForOngoingFetch();
        if (!_hasMore) {
          break;
        }
        await _fetchNextPage();
        if (displayedEventsStreamValue.value.isNotEmpty || !_hasMore) {
          break;
        }
      }
    } finally {
      _isAutoPaging = false;
    }
  }

  bool isOccurrenceConfirmed(String occurrenceId) => _userEventsRepository
      .isOccurrenceConfirmed(
        userEventsRepoString(
          occurrenceId,
          defaultValue: '',
          isRequired: true,
        ),
      )
      .value;

  int pendingInviteCount(String occurrenceId) =>
      _invitesRepository.pendingInvitesStreamValue.value
          .where((invite) => invite.occurrenceId == occurrenceId)
          .length;

  bool hasPendingInvite(String occurrenceId) =>
      pendingInviteCount(occurrenceId) > 0;

  String _eventOccurrenceIdentity(EventModel event) =>
      event.selectedOccurrenceId?.trim() ?? '';

  bool get _shouldShortCircuitPendingOnlyQuery =>
      inviteFilterStreamValue.value == InviteFilter.pendingOnly &&
      _pendingInviteOccurrenceIds().isEmpty;

  List<ScheduleRepoString>? _activeOccurrenceIdsFilter() {
    if (inviteFilterStreamValue.value != InviteFilter.pendingOnly) {
      return null;
    }

    final pendingIds = _pendingInviteOccurrenceIds();
    if (pendingIds.isEmpty) {
      return null;
    }

    return pendingIds
        .map(
          (occurrenceId) => _toScheduleText(occurrenceId),
        )
        .toList(growable: false);
  }

  List<String> _pendingInviteOccurrenceIds() {
    final ids = <String>{};
    for (final invite in _invitesRepository.pendingInvitesStreamValue.value) {
      final occurrenceId = invite.occurrenceId?.trim() ?? '';
      if (occurrenceId.isNotEmpty) {
        ids.add(occurrenceId);
      }
    }

    return ids.toList(growable: false)..sort();
  }

  VenueEventResume _toVenueEventResume(EventModel event) {
    return VenueEventResume.fromScheduleEvent(
      event,
      ThumbUriValue(
        defaultValue: defaultEventImageUri,
        isRequired: true,
      )..parse(defaultEventImageUri.toString()),
    );
  }

  String? distanceLabelFor(VenueEventResume event) {
    final userCoordinate = _currentEffectiveOriginCoordinate();
    final eventCoordinate = event.coordinate;
    if (userCoordinate == null || eventCoordinate == null) {
      return null;
    }
    final distanceMeters = haversineDistanceMeters(
      coordinateA: userCoordinate,
      coordinateB: eventCoordinate,
    );
    return _formatDistanceLabel(distanceMeters.value);
  }

  String _formatDistanceLabel(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  void _listenForStatusChanges() {
    _confirmedEventsSubscription?.cancel();
    _pendingInvitesSubscription?.cancel();

    _confirmedEventsSubscription =
        _userEventsRepository.confirmedOccurrenceIdsStream.stream.listen((_) {
      if (inviteFilterStreamValue.value == InviteFilter.confirmedOnly) {
        unawaited(_refresh(warmUpIfPossible: false));
        _restartEventStream();
        return;
      }
      _applyFiltersAndPublish();
    });
    _pendingInvitesSubscription =
        _invitesRepository.pendingInvitesStreamValue.stream.listen((_) {
      if (inviteFilterStreamValue.value == InviteFilter.pendingOnly) {
        unawaited(_refresh(warmUpIfPossible: false));
        _restartEventStream();
        return;
      }
      _applyFiltersAndPublish();
    });
  }

  void _listenForCanonicalOriginChanges() {
    _effectiveOriginSubscription?.cancel();
    _effectiveOriginSubscription =
        _locationOriginService.effectiveOriginStreamValue.stream.listen((
      resolution,
    ) {
      unawaited(_handleEffectiveOriginUpdate(resolution));
    });
  }

  void _listenForRadiusChanges() {
    _radiusSubscription?.cancel();
    _ifAlive(
      () => _maxRadiusMetersStreamValue.addValue(_currentMaxRadiusMeters()),
    );
    _radiusSubscription =
        _appDataRepository.maxRadiusMetersStreamValue.stream.listen((value) {
      _ifAlive(() => _maxRadiusMetersStreamValue.addValue(value.value));
      final current = radiusMetersStreamValue.value;
      final clamped = _clampRadiusMeters(current);
      _ifAlive(() => radiusMetersStreamValue.addValue(clamped));
      unawaited(_refresh());
      _restartEventStream();
    });
  }

  bool get _hasEffectiveOrigin =>
      _effectiveOriginLat != null && _effectiveOriginLng != null;

  Future<void> _handleEffectiveOriginUpdate(
    LocationOriginResolution? resolution,
  ) async {
    if (resolution == null) {
      return;
    }

    final previousOriginLat = _effectiveOriginLat;
    final previousOriginLng = _effectiveOriginLng;
    final previousOriginSettings = _effectiveOriginSettings;
    final changed = _applyResolvedEffectiveOrigin(resolution);
    if (!changed) {
      return;
    }

    if (!_didCanonicalOriginChangeMeaningfully(
      previousOriginSettings: previousOriginSettings,
      nextOriginSettings: _effectiveOriginSettings,
      previousOriginLat: previousOriginLat,
      previousOriginLng: previousOriginLng,
      nextOriginLat: _effectiveOriginLat,
      nextOriginLng: _effectiveOriginLng,
    )) {
      return;
    }

    await _refresh(warmUpIfPossible: false);
    _restartEventStream();
  }

  Future<bool> _resolveEffectiveOrigin({
    required bool warmUpIfPossible,
  }) async {
    final currentLat = _effectiveOriginLat;
    final currentLng = _effectiveOriginLng;

    final resolution = await _locationOriginService.resolveAndPersist(
      LocationOriginResolutionRequestFactory.create(
        warmUpIfPossible: warmUpIfPossible,
      ),
    );
    final effectiveOrigin = resolution.effectiveCoordinate;
    final changed = _applyResolvedEffectiveOrigin(resolution);
    if (!changed) {
      return false;
    }
    return _didCanonicalOriginChangeMeaningfully(
      previousOriginSettings: null,
      nextOriginSettings: _effectiveOriginSettings,
      previousOriginLat: currentLat,
      previousOriginLng: currentLng,
      nextOriginLat: effectiveOrigin?.latitude,
      nextOriginLng: effectiveOrigin?.longitude,
    );
  }

  bool _applyResolvedEffectiveOrigin(LocationOriginResolution resolution) {
    final nextCoordinate = resolution.effectiveCoordinate;
    final nextLat = nextCoordinate?.latitude;
    final nextLng = nextCoordinate?.longitude;
    final nextSettings = resolution.settings;
    final changed =
        _effectiveOriginLat != nextLat ||
        _effectiveOriginLng != nextLng ||
        !(_effectiveOriginSettings?.sameAs(nextSettings) ?? nextSettings == null);
    _effectiveOriginLat = nextLat;
    _effectiveOriginLng = nextLng;
    _effectiveOriginSettings = nextSettings;
    return changed;
  }

  bool _didCanonicalOriginChangeMeaningfully({
    required LocationOriginSettings? previousOriginSettings,
    required LocationOriginSettings? nextOriginSettings,
    required double? previousOriginLat,
    required double? previousOriginLng,
    required double? nextOriginLat,
    required double? nextOriginLng,
  }) {
    if (!(previousOriginSettings?.sameAs(nextOriginSettings) ??
        nextOriginSettings == null)) {
      return true;
    }
    return previousOriginLat != nextOriginLat ||
        previousOriginLng != nextOriginLng;
  }

  @override
  double get minRadiusMeters => _resolveMinRadiusMeters();

  @override
  StreamValue<double> get maxRadiusMetersStreamValue =>
      _maxRadiusMetersStreamValue;

  double _resolveMinRadiusMeters() {
    final configured = _configuredMinRadiusMeters();
    return configured > 0 ? configured : 1000;
  }

  double _resolveDefaultRadiusMeters() {
    if (_appDataRepository.hasPersistedMaxRadiusPreference) {
      final preferred = _appDataRepository.maxRadiusMeters;
      if (preferred.value > 0) {
        return _clampRadiusMeters(preferred.value);
      }
    }

    final configured = _configuredDefaultRadiusMeters();
    if (configured > 0) {
      return _clampRadiusMeters(configured);
    }
    return _clampRadiusMeters(_currentMaxRadiusMeters());
  }

  CityCoordinate? _currentEffectiveOriginCoordinate() {
    if (_effectiveOriginLat != null && _effectiveOriginLng != null) {
      return CityCoordinate(
        latitudeValue: LatitudeValue()..parse(_effectiveOriginLat!.toString()),
        longitudeValue: LongitudeValue()
          ..parse(_effectiveOriginLng!.toString()),
      );
    }
    return _locationOriginService.resolveCached().effectiveCoordinate;
  }

  double _configuredMinRadiusMeters() {
    try {
      return _appDataRepository.appData.mapRadiusMinMeters;
    } on Object {
      return 1000;
    }
  }

  double _configuredDefaultRadiusMeters() {
    try {
      return _appDataRepository.appData.mapRadiusDefaultMeters;
    } on Object {
      return _currentMaxRadiusMeters();
    }
  }

  double _currentMaxRadiusMeters() => _appDataRepository.maxRadiusMeters.value;

  double _clampRadiusMeters(double meters) {
    final min = _resolveMinRadiusMeters();
    final max = _currentMaxRadiusMeters();
    final effectiveMax = max < min ? min : max;
    return meters.clamp(min, effectiveMax).toDouble();
  }

  void _restartEventStream() {
    if (_isDisposed) return;
    _eventsStreamSubscription?.cancel();
    if (!_hasEffectiveOrigin) {
      _lastEventStreamId = null;
      return;
    }
    if (_shouldShortCircuitPendingOnlyQuery) {
      _lastEventStreamId = null;
      return;
    }
    final queryOccurrenceIds = _activeOccurrenceIdsFilter();
    _eventsStreamSubscription = _scheduleRepository
        .watchEventsSignal(
      onDelta: ScheduleRepositoryContractDeltaHandler((delta) {
        if (delta.lastEventId != null && delta.lastEventId!.isNotEmpty) {
          _lastEventStreamId = delta.lastEventId;
        }
      }),
      searchQuery: _toScheduleText(searchController.text),
      confirmedOnly: _toScheduleBool(
        inviteFilterStreamValue.value == InviteFilter.confirmedOnly,
      ),
      occurrenceIds: queryOccurrenceIds,
      originLat: _toNullableScheduleDouble(_effectiveOriginLat),
      originLng: _toNullableScheduleDouble(_effectiveOriginLng),
      maxDistanceMeters: _toScheduleDouble(radiusMetersStreamValue.value),
      lastEventId: _lastEventStreamId == null
          ? null
          : _toScheduleText(_lastEventStreamId!),
      showPastOnly: _toScheduleBool(showHistoryStreamValue.value),
    )
        .listen(
      (_) {
        _refreshFromStream();
      },
      onError: (_) {
        _lastEventStreamId = null;
        _refreshFromStream();
        _scheduleStreamReconnect();
      },
      onDone: () {
        _lastEventStreamId = null;
        _refreshFromStream();
        _scheduleStreamReconnect();
      },
    );

    if (_lastEventStreamId == null) {
      _refreshFromStream();
    }
  }

  Future<void> _refreshFromStream() async {
    if (_isStreamRefreshing || _isDisposed) return;
    _isStreamRefreshing = true;
    try {
      await _refresh(warmUpIfPossible: false);
    } finally {
      _isStreamRefreshing = false;
    }
  }

  void _scheduleStreamReconnect() {
    if (_isDisposed) return;
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (_isDisposed) return;
      _restartEventStream();
    });
  }

  @override
  void onDispose() {
    _isDisposed = true;
    _confirmedEventsSubscription?.cancel();
    _pendingInvitesSubscription?.cancel();
    _effectiveOriginSubscription?.cancel();
    _radiusSubscription?.cancel();
    _eventsStreamSubscription?.cancel();
    displayedEventsStreamValue.dispose();
    isInitialLoadingStreamValue.dispose();
    isPageLoadingStreamValue.dispose();
    hasMoreStreamValue.dispose();
    showHistoryStreamValue.dispose();
    searchActiveStreamValue.dispose();
    inviteFilterStreamValue.dispose();
    radiusMetersStreamValue.dispose();
    isRadiusRefreshLoadingStreamValue.dispose();
    isRadiusActionCompactStreamValue.dispose();
    _maxRadiusMetersStreamValue.dispose();
    focusNode.dispose();
    searchController.dispose();
    scrollController.dispose();
  }
}
