import 'dart:async';

import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/map/geo_distance.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/agenda_app_bar_controller.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/invite_filter.dart';
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
  })  : _scheduleRepository =
            scheduleRepository ?? GetIt.I.get<ScheduleRepositoryContract>(),
        _userEventsRepository =
            userEventsRepository ?? GetIt.I.get<UserEventsRepositoryContract>(),
        _invitesRepository =
            invitesRepository ?? GetIt.I.get<InvitesRepositoryContract>(),
        _userLocationRepository = userLocationRepository ??
            (GetIt.I.isRegistered<UserLocationRepositoryContract>()
                ? GetIt.I.get<UserLocationRepositoryContract>()
                : null),
        _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>() {
    _initializeStateHolders();
  }

  final ScheduleRepositoryContract _scheduleRepository;
  final UserEventsRepositoryContract _userEventsRepository;
  final InvitesRepositoryContract _invitesRepository;
  final UserLocationRepositoryContract? _userLocationRepository;
  final AppDataRepositoryContract _appDataRepository;

  static const int _pageSize = 10;
  static const double _fallbackRadiusMeters = 50000.0;

  @override
  late TextEditingController searchController;
  @override
  late FocusNode focusNode;
  late ScrollController scrollController;

  late StreamValue<List<EventModel>> displayedEventsStreamValue;
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

  StreamSubscription? _confirmedEventsSubscription;
  StreamSubscription? _pendingInvitesSubscription;
  StreamSubscription? _userLocationSubscription;
  StreamSubscription? _radiusSubscription;
  StreamSubscription? _eventsStreamSubscription;
  bool _isStreamRefreshing = false;
  String? _lastEventStreamId;
  final List<EventModel> _fetchedEvents = [];
  int _currentPage = 1;
  bool _isFetching = false;
  bool _hasMore = true;
  bool _isScrollListenerAttached = false;
  bool _isDisposed = false;
  bool _isAutoPaging = false;
  double? _effectiveOriginLat;
  double? _effectiveOriginLng;

  void _setValue<T>(StreamValue<T> stream, T value) {
    if (_isDisposed) return;
    stream.addValue(value);
  }

  void _initializeStateHolders() {
    searchController = TextEditingController();
    focusNode = FocusNode();
    scrollController = ScrollController();
    displayedEventsStreamValue =
        StreamValue<List<EventModel>>(defaultValue: const []);
    isInitialLoadingStreamValue = StreamValue<bool>(defaultValue: true);
    isPageLoadingStreamValue = StreamValue<bool>(defaultValue: false);
    hasMoreStreamValue = StreamValue<bool>(defaultValue: true);
    showHistoryStreamValue = StreamValue<bool>(defaultValue: false);
    searchActiveStreamValue = StreamValue<bool>(defaultValue: false);
    inviteFilterStreamValue =
        StreamValue<InviteFilter>(defaultValue: InviteFilter.none);
    radiusMetersStreamValue =
        StreamValue<double>(defaultValue: _fallbackRadiusMeters);
    _isScrollListenerAttached = false;
  }

  void _resetInternalState() {
    _fetchedEvents.clear();
    _currentPage = 1;
    _isFetching = false;
    _hasMore = true;
  }

  Future<void> init({bool startWithHistory = false}) async {
    if (_isDisposed) {
      _initializeStateHolders();
      _isDisposed = false;
    }
    await _invitesRepository.init();
    await _userEventsRepository.refreshConfirmedEventIds();
    _resetInternalState();
    _setValue(showHistoryStreamValue, startWithHistory);
    _setValue(radiusMetersStreamValue, _resolveDefaultRadiusMeters());
    _attachScrollListener();
    _listenForStatusChanges();
    _listenForLocationChanges();
    _listenForRadiusChanges();
    await _resolveEffectiveOrigin(warmUpIfPossible: true);
    await _refresh();
    _restartEventStream();
  }

  void _attachScrollListener() {
    if (_isScrollListenerAttached) return;
    _isScrollListenerAttached = true;
    scrollController.addListener(() {
      if (!_hasMore ||
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
    });
  }

  Future<void> _refresh({bool warmUpIfPossible = true}) async {
    await _waitForOngoingFetch();
    _currentPage = 1;
    _hasMore = true;
    _setValue(hasMoreStreamValue, true);
    _fetchedEvents.clear();
    _setValue(displayedEventsStreamValue, const <EventModel>[]);
    _setValue(isInitialLoadingStreamValue, true);
    try {
      await _resolveEffectiveOrigin(warmUpIfPossible: warmUpIfPossible);
      if (!_hasEffectiveOrigin) {
        _hasMore = false;
        _setValue(hasMoreStreamValue, false);
        _setValue(displayedEventsStreamValue, const <EventModel>[]);
        return;
      }

      _hasMore = true;
      _setValue(hasMoreStreamValue, true);
      await _fetchPage(page: 1);
    } catch (error) {
      debugPrint('EventSearchScreenController._refresh failed: $error');
    } finally {
      _setValue(isInitialLoadingStreamValue, false);
    }
  }

  Future<void> _waitForOngoingFetch() async {
    while (_isFetching) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> loadNextPage() async {
    if (!_hasEffectiveOrigin || !_hasMore || _isFetching) return;
    await _fetchPage(page: _currentPage + 1);
  }

  Future<void> _fetchPage({required int page}) async {
    if (_isFetching || !_hasEffectiveOrigin) return;
    _isFetching = true;
    if (page > 1 && !_isDisposed) {
      _setValue(isPageLoadingStreamValue, true);
    }

    try {
      final result = await _scheduleRepository.getEventsPage(
        page: page,
        pageSize: _pageSize,
        showPastOnly: showHistoryStreamValue.value,
        searchQuery: searchController.text,
        confirmedOnly:
            inviteFilterStreamValue.value == InviteFilter.confirmedOnly,
        originLat: _effectiveOriginLat,
        originLng: _effectiveOriginLng,
        maxDistanceMeters: radiusMetersStreamValue.value,
      );

      if (_isDisposed) return;
      if (page == 1) {
        _fetchedEvents
          ..clear()
          ..addAll(result.events);
      } else {
        _fetchedEvents.addAll(result.events);
      }

      _hasMore = result.hasMore;
      _setValue(hasMoreStreamValue, _hasMore);
      _currentPage = page;
      _applyFiltersAndPublish();
    } finally {
      _isFetching = false;
      if (!_isDisposed) {
        _setValue(isPageLoadingStreamValue, false);
      }
    }
  }

  @override
  void toggleHistory() {
    final currentValue = showHistoryStreamValue.value;
    _setValue(showHistoryStreamValue, !currentValue);
    _refresh();
    _restartEventStream();
  }

  void setInviteFilter(InviteFilter filter) {
    _setValue(inviteFilterStreamValue, filter);
    _applyFiltersAndPublish();
    _restartEventStream();
  }

  @override
  void cycleInviteFilter() {
    final current = inviteFilterStreamValue.value;
    switch (current) {
      case InviteFilter.none:
        setInviteFilter(InviteFilter.invitesAndConfirmed);
        break;
      case InviteFilter.invitesAndConfirmed:
        setInviteFilter(InviteFilter.confirmedOnly);
        break;
      case InviteFilter.confirmedOnly:
        setInviteFilter(InviteFilter.none);
        break;
    }
  }

  void setSearchActive(bool active) {
    _setValue(searchActiveStreamValue, active);
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
    _setValue(radiusMetersStreamValue, _clampRadiusMeters(meters));
    unawaited(_refresh());
    _restartEventStream();
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

    final confirmedIds = _userEventsRepository.confirmedEventIdsStream.value;
    final pendingIds = _invitesRepository.pendingInvitesStreamValue.value
        .map((invite) => invite.eventId)
        .toSet();

    bool isConfirmed(String id) => confirmedIds.contains(id);
    bool hasPending(String id) => pendingIds.contains(id);

    return events.where((event) {
      final id = event.id.value;
      switch (filter) {
        case InviteFilter.none:
          return true;
        case InviteFilter.invitesAndConfirmed:
          return isConfirmed(id) || hasPending(id);
        case InviteFilter.confirmedOnly:
          return isConfirmed(id);
      }
    }).toList();
  }

  void _applyFiltersAndPublish() {
    if (_isDisposed) return;
    final inviteFiltered = _applyInviteFilter(_fetchedEvents);
    _setValue(displayedEventsStreamValue, inviteFiltered);
    _maybeAutoPage(inviteFiltered);
  }

  void _maybeAutoPage(List<EventModel> filtered) {
    if (filtered.isNotEmpty || !_hasMore || _isAutoPaging) {
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
        await _fetchPage(page: _currentPage + 1);
        if (displayedEventsStreamValue.value.isNotEmpty || !_hasMore) {
          break;
        }
      }
    } finally {
      _isAutoPaging = false;
    }
  }

  bool isEventConfirmed(String eventId) =>
      _userEventsRepository.isEventConfirmed(eventId);

  int pendingInviteCount(String eventId) =>
      _invitesRepository.pendingInvitesStreamValue.value
          .where((invite) => invite.eventId == eventId)
          .length;

  bool hasPendingInvite(String eventId) => pendingInviteCount(eventId) > 0;

  String? distanceLabelFor(VenueEventResume event) {
    final userCoordinate =
        _userLocationRepository?.userLocationStreamValue.value ??
            _userLocationRepository?.lastKnownLocationStreamValue.value;
    final eventCoordinate = event.coordinate;
    if (userCoordinate == null || eventCoordinate == null) {
      return null;
    }
    final distanceMeters = haversineDistanceMeters(
      lat1: userCoordinate.latitude,
      lon1: userCoordinate.longitude,
      lat2: eventCoordinate.latitude,
      lon2: eventCoordinate.longitude,
    );
    return _formatDistanceLabel(distanceMeters);
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
        _userEventsRepository.confirmedEventIdsStream.stream.listen((_) {
      _applyFiltersAndPublish();
    });
    _pendingInvitesSubscription =
        _invitesRepository.pendingInvitesStreamValue.stream.listen((_) {
      _applyFiltersAndPublish();
    });
  }

  void _listenForLocationChanges() {
    final repo = _userLocationRepository;
    if (repo == null) return;
    _userLocationSubscription?.cancel();
    _userLocationSubscription = repo.userLocationStreamValue.stream.listen((_) {
      unawaited(_handleLocationUpdate());
    });
  }

  void _listenForRadiusChanges() {
    _radiusSubscription?.cancel();
    _radiusSubscription =
        _appDataRepository.maxRadiusMetersStreamValue.stream.listen((_) {
      final current = radiusMetersStreamValue.value;
      final clamped = _clampRadiusMeters(current);
      _setValue(radiusMetersStreamValue, clamped);
      unawaited(_refresh());
      _restartEventStream();
    });
  }

  bool get _hasEffectiveOrigin =>
      _effectiveOriginLat != null && _effectiveOriginLng != null;

  Future<void> _handleLocationUpdate() async {
    final changed = await _resolveEffectiveOrigin(warmUpIfPossible: false);
    if (!changed) {
      return;
    }

    await _refresh();
    _restartEventStream();
  }

  Future<bool> _resolveEffectiveOrigin({
    required bool warmUpIfPossible,
  }) async {
    final currentLat = _effectiveOriginLat;
    final currentLng = _effectiveOriginLng;

    final userCoordinate = await _resolveUserCoordinate(
      warmUpIfPossible: warmUpIfPossible,
    );
    if (userCoordinate != null) {
      _effectiveOriginLat = userCoordinate.latitude;
      _effectiveOriginLng = userCoordinate.longitude;
      return _effectiveOriginLat != currentLat ||
          _effectiveOriginLng != currentLng;
    }

    final tenantDefaultOrigin = _resolveTenantDefaultOriginCoordinate();
    if (tenantDefaultOrigin != null) {
      _effectiveOriginLat = tenantDefaultOrigin.latitude;
      _effectiveOriginLng = tenantDefaultOrigin.longitude;
      return _effectiveOriginLat != currentLat ||
          _effectiveOriginLng != currentLng;
    }

    _effectiveOriginLat = null;
    _effectiveOriginLng = null;
    return currentLat != null || currentLng != null;
  }

  Future<CityCoordinate?> _resolveUserCoordinate({
    required bool warmUpIfPossible,
  }) async {
    final repository = _userLocationRepository;
    if (repository == null) {
      return null;
    }

    if (warmUpIfPossible) {
      try {
        await repository.warmUpIfPermitted();
      } on Object {
        // Best-effort warm up.
      }
    }

    return repository.userLocationStreamValue.value ??
        repository.lastKnownLocationStreamValue.value;
  }

  CityCoordinate? _resolveTenantDefaultOriginCoordinate() {
    try {
      return _appDataRepository.appData.tenantDefaultOrigin;
    } on Object {
      return null;
    }
  }

  @override
  double get minRadiusMeters => _resolveMinRadiusMeters();

  @override
  StreamValue<double> get maxRadiusMetersStreamValue =>
      _appDataRepository.maxRadiusMetersStreamValue;

  double _resolveMinRadiusMeters() {
    final configured = _configuredMinRadiusMeters();
    return configured > 0 ? configured : 1000;
  }

  double _resolveDefaultRadiusMeters() {
    final configured = _configuredDefaultRadiusMeters();
    if (configured > 0) {
      return _clampRadiusMeters(configured);
    }
    return _clampRadiusMeters(_appDataRepository.maxRadiusMeters);
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
      return _appDataRepository.maxRadiusMeters;
    }
  }

  double _clampRadiusMeters(double meters) {
    final min = _resolveMinRadiusMeters();
    final max = _appDataRepository.maxRadiusMeters;
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
    _eventsStreamSubscription = _scheduleRepository
        .watchEventsStream(
      searchQuery: searchController.text,
      confirmedOnly:
          inviteFilterStreamValue.value == InviteFilter.confirmedOnly,
      originLat: _effectiveOriginLat,
      originLng: _effectiveOriginLng,
      maxDistanceMeters: radiusMetersStreamValue.value,
      lastEventId: _lastEventStreamId,
      showPastOnly: showHistoryStreamValue.value,
    )
        .listen(
      (delta) {
        if (delta.lastEventId != null && delta.lastEventId!.isNotEmpty) {
          _lastEventStreamId = delta.lastEventId;
        }
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
    _userLocationSubscription?.cancel();
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
    focusNode.dispose();
    searchController.dispose();
    scrollController.dispose();
  }
}
