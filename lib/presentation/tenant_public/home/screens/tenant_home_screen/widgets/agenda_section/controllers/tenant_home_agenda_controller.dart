import 'dart:async';

import 'package:belluga_now/domain/map/geo_distance.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
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

  @override
  StreamValue<double> get maxRadiusMetersStreamValue =>
      _appDataRepository.maxRadiusMetersStreamValue;

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
      final stopwatch = Stopwatch()..start();
      if (shouldShowInitialLoading) {
        initialLoadingLabelStreamValue.addValue('Localizando...');
        await _resolveEffectiveOrigin(
          warmUpIfPossible: shouldShowInitialLoading,
        );
      }
      final locationElapsed = stopwatch.elapsedMilliseconds;

      if (shouldShowInitialLoading) {
        _setValue(initialLoadingLabelStreamValue, _loadingNearbyEventsLabel);
      }
      _hasMore = true;
      _setValue(hasMoreStreamValue, true);
      await _fetchPage(
        page: 1,
        showPageLoadingForFirstPage: preserveCurrentResults,
      );
      final totalElapsed = stopwatch.elapsedMilliseconds;
      debugPrint('TenantHomeAgendaController._refresh: '
          'Location resolution took ${locationElapsed}ms, '
          'API fetch took ${totalElapsed - locationElapsed}ms. '
          'Total: ${totalElapsed}ms.');
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
          showPastOnly: showHistoryStreamValue.value,
          searchQuery: searchController.text,
          confirmedOnly:
              inviteFilterStreamValue.value == InviteFilter.confirmedOnly,
          originLat: _effectiveOriginLat,
          originLng: _effectiveOriginLng,
          maxDistanceMeters: radiusMetersStreamValue.value,
        );
      } else {
        await _scheduleRepository.loadNextEventsPage(
          showPastOnly: showHistoryStreamValue.value,
          searchQuery: searchController.text,
          confirmedOnly:
              inviteFilterStreamValue.value == InviteFilter.confirmedOnly,
          originLat: _effectiveOriginLat,
          originLng: _effectiveOriginLng,
          maxDistanceMeters: radiusMetersStreamValue.value,
        );
      }

      final result = _scheduleRepository.pagedEventsStreamValue.value;
      if (result == null) {
        final firstPageError =
            _scheduleRepository.pagedEventsErrorStreamValue.value;
        if (page == 1 && firstPageError != null && firstPageError.isNotEmpty) {
          throw Exception(firstPageError);
        }
        return;
      }
      final loadedPage = _scheduleRepository.currentPagedEventsPage;
      if (loadedPage <= 0) {
        final firstPageError =
            _scheduleRepository.pagedEventsErrorStreamValue.value;
        if (page == 1 && firstPageError != null && firstPageError.isNotEmpty) {
          throw Exception(firstPageError);
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
    final inviteFiltered = _applyInviteFilter(_currentCanonicalEvents());
    _setValue(displayedEventsStreamValue, inviteFiltered);
  }

  List<EventModel> _currentCanonicalEvents() {
    final cache = _scheduleRepository.readHomeAgendaCache(
      showPastOnly: showHistoryStreamValue.value,
      searchQuery: searchController.text.trim(),
      confirmedOnly:
          inviteFilterStreamValue.value == InviteFilter.confirmedOnly,
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
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
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
        hasMore: _hasMore,
        page: _currentPage,
        showPastOnly: showHistoryStreamValue.value,
        searchQuery: searchController.text.trim(),
        confirmedOnly:
            inviteFilterStreamValue.value == InviteFilter.confirmedOnly,
        capturedAt: DateTime.now(),
        originLat: _effectiveOriginLat,
        originLng: _effectiveOriginLng,
        maxDistanceMeters: radiusMetersStreamValue.value,
      ),
    );
  }

  bool isEventConfirmed(String eventId) =>
      _userEventsRepository.isEventConfirmed(eventId);

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
      lat1: previousOriginLat,
      lon1: previousOriginLng,
      lat2: nextOriginLat,
      lon2: nextOriginLng,
    );
    return jumpMeters >= _locationRefreshMinJumpMeters;
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

    // Aumentamos a "janela de frescor" de 5 para 20 minutos para evitar
    // esperas desnecessárias pelo GPS ao reabrir o app em um local próximo.
    if (DateTime.now().difference(capturedAt) > const Duration(minutes: 20)) {
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
    if (_appDataRepository.hasPersistedMaxRadiusPreference) {
      final preferred = _appDataRepository.maxRadiusMeters;
      if (preferred > 0) {
        return _clampRadiusMeters(preferred);
      }
    }

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
    focusNode.dispose();
    searchController.dispose();
  }
}
