import 'dart:async';

import 'package:belluga_now/domain/map/geo_distance.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/value_objects/home_agenda_boolean_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/home_agenda_captured_at_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/home_agenda_page_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/home_agenda_search_query_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/agenda_app_bar_controller.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class TenantHomeAgendaController implements Disposable, AgendaAppBarController {
  TenantHomeAgendaController({
    ScheduleRepositoryContract? scheduleRepository,
    UserEventsRepositoryContract? userEventsRepository,
    InvitesRepositoryContract? invitesRepository,
    UserLocationRepositoryContract? userLocationRepository,
    AppDataRepositoryContract? appDataRepository,
    Duration locationWarmUpTimeout = const Duration(seconds: 4),
    Duration locationPermissionTimeout = const Duration(seconds: 8),
    Duration radiusRefreshDebounce = const Duration(milliseconds: 250),
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
            appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>(),
        _locationWarmUpTimeout = locationWarmUpTimeout,
        _locationPermissionTimeout = locationPermissionTimeout,
        _radiusRefreshDebounce = radiusRefreshDebounce;

  final ScheduleRepositoryContract _scheduleRepository;
  final UserEventsRepositoryContract _userEventsRepository;
  final InvitesRepositoryContract _invitesRepository;
  final UserLocationRepositoryContract? _userLocationRepository;
  final AppDataRepositoryContract _appDataRepository;
  final Duration _locationWarmUpTimeout;
  final Duration _locationPermissionTimeout;
  final Duration _radiusRefreshDebounce;

  static const double _fallbackRadiusMeters = 50000.0;
  static const double _locationRefreshMinJumpMeters = 1000.0;
  static const Duration _firstPageRetryDelay = Duration(milliseconds: 350);
  static const String _loadingLocationLabel = 'Encontrando sua localização...';
  static const String _loadingNearbyEventsLabel =
      'Buscando eventos perto de você...';
  static final Uri _localEventPlaceholderUri =
      Uri.parse('asset://event-placeholder');

  @override
  final searchController = TextEditingController();
  @override
  final focusNode = FocusNode();

  StreamValue<List<EventModel>?> get displayedEventsStreamValue =>
      _scheduleRepository.homeAgendaEventsStreamValue;
  final isInitialLoadingStreamValue = StreamValue<bool>(defaultValue: true);
  final initialLoadingLabelStreamValue =
      StreamValue<String>(defaultValue: _loadingLocationLabel);
  final isPageLoadingStreamValue = StreamValue<bool>(defaultValue: false);
  final hasMoreStreamValue = StreamValue<bool>(defaultValue: true);
  @override
  final showHistoryStreamValue = StreamValue<bool>(defaultValue: false);
  @override
  final searchActiveStreamValue = StreamValue<bool>(defaultValue: false);
  @override
  final inviteFilterStreamValue =
      StreamValue<InviteFilter>(defaultValue: InviteFilter.none);
  @override
  final radiusMetersStreamValue =
      StreamValue<double>(defaultValue: _fallbackRadiusMeters);
  final StreamValue<double> _maxRadiusMetersStreamValue =
      StreamValue<double>(defaultValue: _fallbackRadiusMeters);

  @override
  StreamValue<double> get maxRadiusMetersStreamValue =>
      _maxRadiusMetersStreamValue;

  @override
  double get minRadiusMeters => _resolveMinRadiusMeters();

  StreamSubscription? _confirmedEventsSubscription;
  StreamSubscription? _pendingInvitesSubscription;
  StreamSubscription? _userLocationSubscription;
  StreamSubscription? _radiusSubscription;
  Timer? _radiusRefreshDebounceTimer;
  int _currentPage = 1;
  bool _isFetching = false;
  bool _isRefreshing = false;
  bool _hasMore = true;
  bool _isDisposed = false;
  bool _hasQueuedRefresh = false;
  bool _queuedRefreshPreserveCurrentResults = true;
  Future<void>? _initInFlight;
  double? _effectiveOriginLat;
  double? _effectiveOriginLng;
  bool _locationPermissionRequested = false;

  Uri get defaultEventImageUri {
    final configured = _appDataRepository.appData.mainLogoDarkUrl.value;
    if (configured != null && configured.toString().trim().isNotEmpty) {
      return configured;
    }
    return _localEventPlaceholderUri;
  }

  void _setValue<T>(StreamValue<T> stream, T value) {
    if (_isDisposed) return;
    stream.addValue(value);
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

  Future<void> init({bool startWithHistory = false}) async {
    final inFlight = _initInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final initFuture =
        _initInternal(startWithHistory: startWithHistory).whenComplete(() {
      _initInFlight = null;
    });
    _initInFlight = initFuture;
    return initFuture;
  }

  Future<void> _initInternal({required bool startWithHistory}) async {
    _setValue(showHistoryStreamValue, startWithHistory);
    _setValue(radiusMetersStreamValue, _resolveDefaultRadiusMeters());
    _listenForStatusChanges();
    _listenForLocationChanges();
    _listenForRadiusChanges();

    final restored = _restoreFromRepositoryCache();
    if (restored) {
      _setValue(isInitialLoadingStreamValue, false);
      _setValue(initialLoadingLabelStreamValue, '');
      return;
    }

    try {
      await _invitesRepository.init();
    } catch (error) {
      debugPrint('TenantHomeAgendaController.init invites failed: $error');
    }
    try {
      await _userEventsRepository.refreshConfirmedEventIds();
    } catch (error) {
      debugPrint(
          'TenantHomeAgendaController.init confirmed ids failed: $error');
    }
    await _resolveEffectiveOrigin(warmUpIfPossible: true);
    await _refresh();
  }

  Future<void> _refresh({
    bool preserveCurrentResults = false,
  }) async {
    if (_isRefreshing) {
      _queueRefreshRequest(
        preserveCurrentResults: preserveCurrentResults,
      );
      return;
    }
    _isRefreshing = true;
    final shouldShowInitialLoading = !preserveCurrentResults;
    _currentPage = 1;
    _hasMore = true;
    _setValue(hasMoreStreamValue, true);
    if (shouldShowInitialLoading) {
      _scheduleRepository.clearHomeAgendaCache();
      _setValue(isInitialLoadingStreamValue, true);
      _setValue(initialLoadingLabelStreamValue, _loadingLocationLabel);
    }
    try {
      await _resolveEffectiveOrigin(
        warmUpIfPossible: shouldShowInitialLoading,
      );
      if (shouldShowInitialLoading) {
        _setValue(initialLoadingLabelStreamValue, _loadingNearbyEventsLabel);
      }
      _hasMore = true;
      _setValue(hasMoreStreamValue, true);
      await _fetchPage(
        page: 1,
        showPageLoadingForFirstPage: preserveCurrentResults,
      );
    } catch (error) {
      debugPrint('TenantHomeAgendaController._refresh failed: $error');
      if (shouldShowInitialLoading) {
        final recovered = await _retryFirstPageAfterFailure();
        if (!recovered) {
          debugPrint(
            'TenantHomeAgendaController._refresh retry failed after first-page error.',
          );
        }
      }
    } finally {
      if (shouldShowInitialLoading) {
        _setValue(isInitialLoadingStreamValue, false);
        _setValue(initialLoadingLabelStreamValue, '');
      }
      _isRefreshing = false;
      _consumeQueuedRefreshRequestIfNeeded();
    }
  }

  Future<bool> _retryFirstPageAfterFailure() async {
    if (_isDisposed) {
      return false;
    }

    await Future<void>.delayed(_firstPageRetryDelay);
    if (_isDisposed) {
      return false;
    }

    try {
      await _resolveEffectiveOrigin(warmUpIfPossible: false);
      _setValue(initialLoadingLabelStreamValue, _loadingNearbyEventsLabel);
      await _fetchPage(page: 1);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadNextPage() async {
    if (!_hasMore || _isFetching || _isRefreshing) return;
    await _fetchPage(page: _currentPage + 1);
  }

  void _queueRefreshRequest({
    required bool preserveCurrentResults,
  }) {
    _hasQueuedRefresh = true;
    _queuedRefreshPreserveCurrentResults =
        _queuedRefreshPreserveCurrentResults && preserveCurrentResults;
  }

  void _consumeQueuedRefreshRequestIfNeeded() {
    if (_isDisposed || !_hasQueuedRefresh) {
      return;
    }
    final preserveCurrentResults = _queuedRefreshPreserveCurrentResults;
    _hasQueuedRefresh = false;
    _queuedRefreshPreserveCurrentResults = true;
    unawaited(
      _refresh(
        preserveCurrentResults: preserveCurrentResults,
      ),
    );
  }

  Future<void> _fetchPage({
    required int page,
    bool showPageLoadingForFirstPage = false,
  }) async {
    if (_isFetching) return;
    _isFetching = true;
    if (page > 1 || (page == 1 && showPageLoadingForFirstPage)) {
      _setValue(isPageLoadingStreamValue, true);
    }

    try {
      if (page <= 1) {
        await _scheduleRepository.loadEventsPage(
          showPastOnly: _toScheduleBool(showHistoryStreamValue.value),
          searchQuery: _toScheduleText(searchController.text),
          confirmedOnly: _toScheduleBool(
            inviteFilterStreamValue.value == InviteFilter.confirmedOnly,
          ),
          originLat: _toNullableScheduleDouble(_effectiveOriginLat),
          originLng: _toNullableScheduleDouble(_effectiveOriginLng),
          maxDistanceMeters: _toScheduleDouble(radiusMetersStreamValue.value),
        );
      } else {
        await _scheduleRepository.loadNextEventsPage(
          showPastOnly: _toScheduleBool(showHistoryStreamValue.value),
          searchQuery: _toScheduleText(searchController.text),
          confirmedOnly: _toScheduleBool(
            inviteFilterStreamValue.value == InviteFilter.confirmedOnly,
          ),
          originLat: _toNullableScheduleDouble(_effectiveOriginLat),
          originLng: _toNullableScheduleDouble(_effectiveOriginLng),
          maxDistanceMeters: _toScheduleDouble(radiusMetersStreamValue.value),
        );
      }

      final result = _scheduleRepository.pagedEventsStreamValue.value;
      if (result == null) {
        final firstPageError =
            _scheduleRepository.pagedEventsErrorStreamValue.value;
        if (page == 1 &&
            firstPageError != null &&
            firstPageError.value.isNotEmpty) {
          throw Exception(firstPageError.value);
        }
        return;
      }
      final loadedPage = _scheduleRepository.currentPagedEventsPage.value;
      if (loadedPage <= 0) {
        final firstPageError =
            _scheduleRepository.pagedEventsErrorStreamValue.value;
        if (page == 1 &&
            firstPageError != null &&
            firstPageError.value.isNotEmpty) {
          throw Exception(firstPageError.value);
        }
        return;
      }

      final canonicalEvents = loadedPage == 1
          ? List<EventModel>.from(result.events)
          : [
              ..._currentCanonicalEvents(),
              ...result.events,
            ];

      _hasMore = result.hasMore;
      _setValue(hasMoreStreamValue, _hasMore);
      _currentPage = loadedPage;
      _writeRepositoryCacheSnapshot(canonicalEvents);
      _applyFiltersAndPublish();
    } finally {
      _isFetching = false;
      _setValue(isPageLoadingStreamValue, false);
    }
  }

  @override
  void toggleHistory() {
    final currentValue = showHistoryStreamValue.value;
    _setValue(showHistoryStreamValue, !currentValue);
    _refresh();
  }

  void setInviteFilter(InviteFilter filter) {
    _setValue(inviteFilterStreamValue, filter);
    _applyFiltersAndPublish();
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
    _scheduleRadiusRefresh();
  }

  void setInitialSearchQuery(String? query) {
    final normalized = query?.trim() ?? '';
    if (normalized.isEmpty) return;
    searchController.text = normalized;
    searchController.selection =
        TextSelection.fromPosition(TextPosition(offset: normalized.length));
    _refresh();
  }

  @override
  Future<void> searchEvents(String query) async {
    await _refresh();
  }

  List<EventModel> _applyInviteFilter(List<EventModel> events) {
    final filter = inviteFilterStreamValue.value;
    if (filter == InviteFilter.none) return events;

    final confirmedIds = _userEventsRepository.confirmedEventIdsStream.value;
    final pendingIds = _invitesRepository.pendingInvitesStreamValue.value
        .map((invite) => invite.eventId)
        .toSet();

    bool isConfirmed(String id) =>
        confirmedIds.any((confirmed) => confirmed.value == id);
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
    final inviteFiltered = _applyInviteFilter(_currentCanonicalEvents());
    _setValue(displayedEventsStreamValue, inviteFiltered);
  }

  List<EventModel> _currentCanonicalEvents() {
    final cache = _scheduleRepository.readHomeAgendaCache(
      showPastOnly: _toScheduleBool(showHistoryStreamValue.value),
      searchQuery: _toScheduleText(searchController.text.trim()),
      confirmedOnly: _toScheduleBool(
        inviteFilterStreamValue.value == InviteFilter.confirmedOnly,
      ),
    );
    if (cache == null) {
      return const <EventModel>[];
    }
    return cache.events;
  }

  bool _restoreFromRepositoryCache() {
    final showPastOnly = showHistoryStreamValue.value;
    final searchQuery = searchController.text.trim();
    final confirmedOnly =
        inviteFilterStreamValue.value == InviteFilter.confirmedOnly;
    final cache = _scheduleRepository.readHomeAgendaCache(
      showPastOnly: _toScheduleBool(showPastOnly),
      searchQuery: _toScheduleText(searchQuery),
      confirmedOnly: _toScheduleBool(confirmedOnly),
    );
    if (cache == null) {
      return false;
    }

    _hasMore = cache.hasMore;
    _currentPage = cache.page;
    _effectiveOriginLat = cache.originLat;
    _effectiveOriginLng = cache.originLng;
    _setValue(hasMoreStreamValue, _hasMore);
    _applyFiltersAndPublish();
    return true;
  }

  void _writeRepositoryCacheSnapshot(List<EventModel> events) {
    _scheduleRepository.writeHomeAgendaCache(
      HomeAgendaCacheSnapshot(
        events: List<EventModel>.unmodifiable(events),
        hasMoreValue: HomeAgendaBooleanValue(defaultValue: _hasMore)
          ..parse(_hasMore.toString()),
        pageValue: HomeAgendaPageValue(defaultValue: _currentPage)
          ..parse(_currentPage.toString()),
        showPastOnlyValue:
            HomeAgendaBooleanValue(defaultValue: showHistoryStreamValue.value)
              ..parse(showHistoryStreamValue.value.toString()),
        searchQueryValue: HomeAgendaSearchQueryValue(
          defaultValue: searchController.text.trim(),
        )..parse(searchController.text.trim()),
        confirmedOnlyValue: HomeAgendaBooleanValue(
          defaultValue:
              inviteFilterStreamValue.value == InviteFilter.confirmedOnly,
        )..parse(
            (inviteFilterStreamValue.value == InviteFilter.confirmedOnly)
                .toString(),
          ),
        capturedAtValue: HomeAgendaCapturedAtValue(defaultValue: DateTime.now())
          ..parse(DateTime.now().toIso8601String()),
        originLatValue: _effectiveOriginLat == null
            ? null
            : (LatitudeValue()..parse(_effectiveOriginLat.toString())),
        originLngValue: _effectiveOriginLng == null
            ? null
            : (LongitudeValue()..parse(_effectiveOriginLng.toString())),
        maxDistanceMetersValue: DistanceInMetersValue(
          defaultValue: radiusMetersStreamValue.value,
        )..parse(radiusMetersStreamValue.value.toString()),
      ),
    );
  }

  bool isEventConfirmed(String eventId) => _userEventsRepository
      .isEventConfirmed(
        userEventsRepoString(
          eventId,
          defaultValue: '',
          isRequired: true,
        ),
      )
      .value;

  int pendingInviteCount(String eventId) =>
      _invitesRepository.pendingInvitesStreamValue.value
          .where((invite) => invite.eventId == eventId)
          .length;

  String? distanceLabelFor(VenueEventResume event) {
    final userCoordinate =
        _userLocationRepository?.userLocationStreamValue.value ??
            _userLocationRepository?.lastKnownLocationStreamValue.value;
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
    _setValue(_maxRadiusMetersStreamValue, _currentMaxRadiusMeters());
    _radiusSubscription =
        _appDataRepository.maxRadiusMetersStreamValue.stream.listen((value) {
      _setValue(_maxRadiusMetersStreamValue, value.value);
      final current = radiusMetersStreamValue.value;
      final clamped = _clampRadiusMeters(current);
      _setValue(radiusMetersStreamValue, clamped);
      _scheduleRadiusRefresh();
    });
  }

  void _scheduleRadiusRefresh() {
    _radiusRefreshDebounceTimer?.cancel();
    _radiusRefreshDebounceTimer = Timer(_radiusRefreshDebounce, () {
      if (_isDisposed) {
        return;
      }
      unawaited(_refresh(preserveCurrentResults: true));
    });
  }

  Future<void> _handleLocationUpdate() async {
    final previousOriginLat = _effectiveOriginLat;
    final previousOriginLng = _effectiveOriginLng;
    final changed = await _resolveEffectiveOrigin(warmUpIfPossible: false);
    if (!changed) {
      return;
    }
    if (!_shouldRefreshForLocationJump(
      previousOriginLat: previousOriginLat,
      previousOriginLng: previousOriginLng,
      nextOriginLat: _effectiveOriginLat,
      nextOriginLng: _effectiveOriginLng,
    )) {
      return;
    }
    await _refresh(preserveCurrentResults: true);
  }

  bool _shouldRefreshForLocationJump({
    required double? previousOriginLat,
    required double? previousOriginLng,
    required double? nextOriginLat,
    required double? nextOriginLng,
  }) {
    if (previousOriginLat == null ||
        previousOriginLng == null ||
        nextOriginLat == null ||
        nextOriginLng == null) {
      return true;
    }

    final jumpMeters = haversineDistanceMeters(
      coordinateA: CityCoordinate(
        latitudeValue: _parseLatitude(previousOriginLat),
        longitudeValue: _parseLongitude(previousOriginLng),
      ),
      coordinateB: CityCoordinate(
        latitudeValue: _parseLatitude(nextOriginLat),
        longitudeValue: _parseLongitude(nextOriginLng),
      ),
    );
    return jumpMeters.value >= _locationRefreshMinJumpMeters;
  }

  LatitudeValue _parseLatitude(double raw) =>
      LatitudeValue()..parse(raw.toString());

  LongitudeValue _parseLongitude(double raw) =>
      LongitudeValue()..parse(raw.toString());

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

    final preWarmUpCoordinate = _resolveFreshLocationCoordinate(repository);
    if (preWarmUpCoordinate != null) {
      return preWarmUpCoordinate;
    }

    if (warmUpIfPossible) {
      try {
        await repository.warmUpIfPermitted().timeout(
              _locationWarmUpTimeout,
              onTimeout: () => false,
            );
      } on Object {
        // Best-effort warm up.
      }
    }

    final warmUpCoordinate = _resolveFreshLocationCoordinate(repository);
    if (warmUpCoordinate != null) {
      return warmUpCoordinate;
    }

    if (warmUpIfPossible && !_locationPermissionRequested) {
      _locationPermissionRequested = true;
      try {
        await repository.resolveUserLocation().timeout(
              _locationPermissionTimeout,
              onTimeout: () => null,
            );
      } on Object {
        // Best-effort permission prompt.
      }
    }

    return _resolveFreshLocationCoordinate(repository);
  }

  CityCoordinate? _resolveFreshLocationCoordinate(
    UserLocationRepositoryContract repository,
  ) {
    final coordinate = repository.userLocationStreamValue.value ??
        repository.lastKnownLocationStreamValue.value;
    if (coordinate == null) {
      return null;
    }

    final capturedAt = repository.lastKnownCapturedAtStreamValue.value;
    if (capturedAt == null) {
      return coordinate;
    }

    Duration freshnessWindow;
    try {
      freshnessWindow =
          _appDataRepository.appData.telemetryContextSettings.locationFreshness;
    } on Object {
      freshnessWindow = const Duration(minutes: 5);
    }

    if (DateTime.now().difference(capturedAt) > freshnessWindow) {
      return null;
    }

    return coordinate;
  }

  CityCoordinate? _resolveTenantDefaultOriginCoordinate() {
    try {
      return _appDataRepository.appData.tenantDefaultOrigin;
    } on Object {
      return null;
    }
  }

  double _resolveMinRadiusMeters() {
    final configured = _configuredMinRadiusMeters();
    return configured > 0 ? configured : 1000;
  }

  double _resolveDefaultRadiusMeters() {
    final configured = _configuredDefaultRadiusMeters();
    if (configured > 0) {
      return _clampRadiusMeters(configured);
    }
    return _clampRadiusMeters(_currentMaxRadiusMeters());
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

  @override
  void onDispose() {
    _isDisposed = true;
    _confirmedEventsSubscription?.cancel();
    _pendingInvitesSubscription?.cancel();
    _userLocationSubscription?.cancel();
    _radiusSubscription?.cancel();
    _radiusRefreshDebounceTimer?.cancel();
    isInitialLoadingStreamValue.dispose();
    initialLoadingLabelStreamValue.dispose();
    isPageLoadingStreamValue.dispose();
    hasMoreStreamValue.dispose();
    showHistoryStreamValue.dispose();
    searchActiveStreamValue.dispose();
    inviteFilterStreamValue.dispose();
    radiusMetersStreamValue.dispose();
    _maxRadiusMetersStreamValue.dispose();
    focusNode.dispose();
    searchController.dispose();
  }
}
