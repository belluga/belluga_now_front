import 'dart:async';

import 'package:belluga_discovery_filters/belluga_discovery_filters.dart';
import 'package:belluga_now/domain/app_data/location_origin_resolution.dart';
import 'package:belluga_now/domain/map/geo_distance.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/discovery_filters_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/proximity_preferences_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/services/location_origin_service_contract.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/infrastructure/services/location_origin_resolution_request_factory.dart';
import 'package:belluga_now/presentation/shared/discovery_filters/public_discovery_filter_controller_mixin.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/agenda_app_bar_controller.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/models/tenant_home_agenda_display_state.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class TenantHomeAgendaController extends Object
    with PublicDiscoveryFilterControllerMixin
    implements Disposable, AgendaAppBarController {
  TenantHomeAgendaController({
    ScheduleRepositoryContract? scheduleRepository,
    UserEventsRepositoryContract? userEventsRepository,
    DiscoveryFiltersRepositoryContract? discoveryFiltersRepository,
    InvitesRepositoryContract? invitesRepository,
    UserLocationRepositoryContract? userLocationRepository,
    AppDataRepositoryContract? appDataRepository,
    AuthRepositoryContract? authRepository,
    ProximityPreferencesRepositoryContract? proximityPreferencesRepository,
    LocationOriginServiceContract? locationOriginService,
    TelemetryRepositoryContract? telemetryRepository,
    bool isWebRuntime = kIsWeb,
    Duration locationWarmUpTimeout = const Duration(seconds: 4),
    Duration locationPermissionTimeout = const Duration(seconds: 8),
    Duration radiusRefreshDebounce = const Duration(milliseconds: 250),
  })  : _scheduleRepository =
            scheduleRepository ?? GetIt.I.get<ScheduleRepositoryContract>(),
        _userEventsRepository =
            userEventsRepository ?? GetIt.I.get<UserEventsRepositoryContract>(),
        _discoveryFiltersRepository = discoveryFiltersRepository ??
            (GetIt.I.isRegistered<DiscoveryFiltersRepositoryContract>()
                ? GetIt.I.get<DiscoveryFiltersRepositoryContract>()
                : null),
        _invitesRepository =
            invitesRepository ?? GetIt.I.get<InvitesRepositoryContract>(),
        _userLocationRepository = userLocationRepository ??
            (GetIt.I.isRegistered<UserLocationRepositoryContract>()
                ? GetIt.I.get<UserLocationRepositoryContract>()
                : null),
        _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>(),
        _authRepository = authRepository ??
            (GetIt.I.isRegistered<AuthRepositoryContract>()
                ? GetIt.I.get<AuthRepositoryContract>()
                : null),
        _proximityPreferencesRepository = proximityPreferencesRepository ??
            (GetIt.I.isRegistered<ProximityPreferencesRepositoryContract>()
                ? GetIt.I.get<ProximityPreferencesRepositoryContract>()
                : null),
        _locationOriginService = locationOriginService ??
            GetIt.I.get<LocationOriginServiceContract>(),
        _telemetryRepository = telemetryRepository ??
            (GetIt.I.isRegistered<TelemetryRepositoryContract>()
                ? GetIt.I.get<TelemetryRepositoryContract>()
                : null),
        _isWebRuntime = isWebRuntime,
        _locationWarmUpTimeout = locationWarmUpTimeout,
        _locationPermissionTimeout = locationPermissionTimeout,
        _radiusRefreshDebounce = radiusRefreshDebounce;

  final ScheduleRepositoryContract _scheduleRepository;
  final UserEventsRepositoryContract _userEventsRepository;
  final DiscoveryFiltersRepositoryContract? _discoveryFiltersRepository;
  final InvitesRepositoryContract _invitesRepository;
  final UserLocationRepositoryContract? _userLocationRepository;
  final AppDataRepositoryContract _appDataRepository;
  final AuthRepositoryContract? _authRepository;
  final ProximityPreferencesRepositoryContract? _proximityPreferencesRepository;
  final LocationOriginServiceContract _locationOriginService;
  final TelemetryRepositoryContract? _telemetryRepository;
  final bool _isWebRuntime;
  final Duration _locationWarmUpTimeout;
  final Duration _locationPermissionTimeout;
  final Duration _radiusRefreshDebounce;

  static const double _fallbackRadiusMeters = 50000.0;
  static const double _radiusTelemetryChangeEpsilon = 0.001;
  static const double _radiusCompactScrollEpsilon = 0.5;
  static const double _locationRefreshMinJumpMeters = 1000.0;
  static const Duration _firstPageRetryDelay = Duration(milliseconds: 350);
  static const Duration _preservedFirstPageEmptyRetryDelay =
      Duration(milliseconds: 250);
  static const String _homeEventsFilterSurface = 'home.events';
  static const DiscoveryFilterPolicy _homeEventsFilterPolicy =
      DiscoveryFilterPolicy(
    primarySelectionMode: DiscoveryFilterSelectionMode.single,
    taxonomySelectionMode: DiscoveryFilterSelectionMode.multiple,
    primaryLayoutMode: DiscoveryFilterLayoutMode.row,
    taxonomyLayoutMode: DiscoveryFilterLayoutMode.row,
  );
  static const String _loadingLocationLabel = 'Encontrando sua localização...';
  static const String _loadingNearbyEventsLabel =
      'Buscando eventos perto de você...';
  static const String _radiusChangedEventName = 'agenda_radius_changed';
  static const String _radiusChangedSurface = 'home';
  static final Uri _localEventPlaceholderUri =
      Uri.parse('asset://event-placeholder');

  @override
  final searchController = TextEditingController();
  @override
  final focusNode = FocusNode();

  final displayStateStreamValue =
      StreamValue<TenantHomeAgendaDisplayState?>(defaultValue: null);
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
  final isRadiusRefreshLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  @override
  final isRadiusActionCompactStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<double> _maxRadiusMetersStreamValue =
      StreamValue<double>(defaultValue: _fallbackRadiusMeters);
  @override
  final discoveryFilterCatalogStreamValue = StreamValue<DiscoveryFilterCatalog>(
    defaultValue: const DiscoveryFilterCatalog(
      surface: _homeEventsFilterSurface,
    ),
  );
  @override
  final discoveryFilterSelectionStreamValue =
      StreamValue<DiscoveryFilterSelection>(
    defaultValue: const DiscoveryFilterSelection(),
  );
  @override
  final isDiscoveryFilterPanelVisibleStreamValue =
      StreamValue<bool>(defaultValue: false);
  @override
  final isDiscoveryFilterCatalogLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);

  @override
  StreamValue<double> get maxRadiusMetersStreamValue =>
      _maxRadiusMetersStreamValue;

  @override
  double get minRadiusMeters => _resolveMinRadiusMeters();

  @override
  DiscoveryFilterPolicy get discoveryFilterPolicy => _homeEventsFilterPolicy;

  StreamSubscription? _confirmedEventsSubscription;
  StreamSubscription? _pendingInvitesSubscription;
  StreamSubscription? _userLocationSubscription;
  StreamSubscription? _radiusSubscription;
  Timer? _radiusRefreshDebounceTimer;
  bool _outerScrollCompactHint = false;
  bool _innerScrollCompactHint = false;
  bool _isFetching = false;
  bool _isRefreshing = false;
  bool _hasMore = true;
  bool _isDisposed = false;
  bool _hasQueuedRefresh = false;
  bool _queuedRefreshPreserveCurrentResults = true;
  Future<void>? _initInFlight;
  double? _effectiveOriginLat;
  double? _effectiveOriginLng;
  double? _pendingPersistedRadiusEchoMeters;
  bool _locationPermissionRequested = false;

  Uri get defaultEventImageUri {
    final configured = _appDataRepository.appData.mainLogoDarkUrl.value;
    if (configured != null && configured.toString().trim().isNotEmpty) {
      return configured;
    }
    return _localEventPlaceholderUri;
  }

  StreamValue<UserContract?>? get authUserStreamValue =>
      _authRepository?.userStreamValue;

  bool get isAuthorized => _authRepository?.isAuthorized ?? true;

  bool get shouldShowInviteFilterAction => !_isWebRuntime || isAuthorized;

  List<EventModel>? get displayedEvents =>
      displayStateStreamValue.value?.events;

  @override
  DiscoveryFiltersRepositoryContract? get publicDiscoveryFiltersRepository =>
      _discoveryFiltersRepository;

  @override
  AppDataRepositoryContract? get publicDiscoveryFilterAppDataRepository =>
      _appDataRepository;

  @override
  String get publicDiscoveryFilterSurface => _homeEventsFilterSurface;

  @override
  bool get isPublicDiscoveryFilterDisposed => _isDisposed;

  @override
  String get publicDiscoveryFilterLogLabel => 'TenantHomeAgendaController';

  @override
  void onPublicDiscoveryFilterSelectionChanged(
    DiscoveryFilterSelection selection,
  ) {
    unawaited(_refresh(preserveCurrentResults: true));
  }

  void _ifAlive(VoidCallback writer) {
    if (_isDisposed) return;
    writer();
  }

  void setRadiusActionCompactState(bool isCompact) {
    _outerScrollCompactHint = isCompact;
    _innerScrollCompactHint = isCompact;
    _publishRadiusActionCompactState();
  }

  void updateRadiusActionCompactStateFromOuterScroll(double pixels) {
    _outerScrollCompactHint = _resolveRadiusActionCompactHint(
      current: _outerScrollCompactHint,
      pixels: pixels,
    );
    _hideDiscoveryFilterPanelWhenScrolled(pixels);
    _publishRadiusActionCompactState();
  }

  void updateRadiusActionCompactStateFromScroll(double pixels) {
    _innerScrollCompactHint = _resolveRadiusActionCompactHint(
      current: _innerScrollCompactHint,
      pixels: pixels,
    );
    _hideDiscoveryFilterPanelWhenScrolled(pixels);
    _publishRadiusActionCompactState();
  }

  void _hideDiscoveryFilterPanelWhenScrolled(double pixels) {
    updateDiscoveryFilterPanelVisibilityFromScroll(
      pixels,
      epsilon: _radiusCompactScrollEpsilon,
    );
  }

  bool _resolveRadiusActionCompactHint({
    required bool current,
    required double pixels,
  }) {
    return pixels > _radiusCompactScrollEpsilon;
  }

  void _publishRadiusActionCompactState() {
    final shouldCompact = _outerScrollCompactHint || _innerScrollCompactHint;
    if (isRadiusActionCompactStreamValue.value == shouldCompact) {
      return;
    }
    _ifAlive(() => isRadiusActionCompactStreamValue.addValue(shouldCompact));
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
    _ifAlive(() => showHistoryStreamValue.addValue(startWithHistory));
    _ifAlive(
        () => radiusMetersStreamValue.addValue(_resolveDefaultRadiusMeters()));
    _listenForStatusChanges();
    _listenForLocationChanges();
    _listenForRadiusChanges();
    final restoredSelection =
        await loadPersistedPublicDiscoveryFilterSelection();
    if (restoredSelection != null &&
        !samePublicDiscoveryFilterSelection(
          discoveryFilterSelectionStreamValue.value,
          restoredSelection,
        )) {
      _ifAlive(
        () => discoveryFilterSelectionStreamValue.addValue(restoredSelection),
      );
    }
    final mustAwaitCatalogBeforeResults = restoredSelection?.isEmpty == false ||
        discoveryFilterSelectionStreamValue.value.isNotEmpty;
    final catalogFuture = loadPublicDiscoveryFilterCatalog(
      restoredSelection: restoredSelection,
    );
    if (mustAwaitCatalogBeforeResults) {
      await catalogFuture;
    } else {
      unawaited(catalogFuture);
    }

    final restored = _restoreFromRepositoryCache();
    if (restored) {
      _ifAlive(() => isInitialLoadingStreamValue.addValue(false));
      _ifAlive(() => initialLoadingLabelStreamValue.addValue(''));
      unawaited(_reconcileEffectiveOriginAfterCacheRestore());
      return;
    }

    await _resolveEffectiveOrigin(warmUpIfPossible: true);
    _ifAlive(
      () => initialLoadingLabelStreamValue.addValue(_loadingNearbyEventsLabel),
    );
    try {
      await _invitesRepository.init();
    } catch (error) {
      debugPrint('TenantHomeAgendaController.init invites failed: $error');
    }
    try {
      await _userEventsRepository.refreshConfirmedOccurrenceIds();
    } catch (error) {
      debugPrint(
          'TenantHomeAgendaController.init confirmed ids failed: $error');
    }
    await _refresh(resolveOrigin: false);
  }

  Future<void> _refresh({
    bool preserveCurrentResults = false,
    bool resolveOrigin = true,
  }) async {
    if (_isRefreshing) {
      _queueRefreshRequest(
        preserveCurrentResults: preserveCurrentResults,
      );
      return;
    }
    _isRefreshing = true;
    final shouldShowInitialLoading = !preserveCurrentResults;
    final previousCanonicalEvents = preserveCurrentResults
        ? List<EventModel>.unmodifiable(_currentCanonicalEvents())
        : const <EventModel>[];
    _hasMore = true;
    _ifAlive(() => hasMoreStreamValue.addValue(true));
    if (shouldShowInitialLoading) {
      _ifAlive(() => isInitialLoadingStreamValue.addValue(true));
      _ifAlive(
        () => initialLoadingLabelStreamValue.addValue(
          resolveOrigin ? _loadingLocationLabel : _loadingNearbyEventsLabel,
        ),
      );
    }
    try {
      final stopwatch = Stopwatch()..start();
      int locationElapsed = 0;
      if (shouldShowInitialLoading && resolveOrigin) {
        _ifAlive(
            () => initialLoadingLabelStreamValue.addValue('Localizando...'));
        await _resolveEffectiveOrigin(
          warmUpIfPossible: shouldShowInitialLoading,
        );
        locationElapsed = stopwatch.elapsedMilliseconds;
      }

      if (shouldShowInitialLoading) {
        _ifAlive(
          () => initialLoadingLabelStreamValue
              .addValue(_loadingNearbyEventsLabel),
        );
      }
      _hasMore = true;
      _ifAlive(() => hasMoreStreamValue.addValue(true));
      await _fetchAgenda(
        append: false,
        showPageLoadingForFirstPage: preserveCurrentResults,
        previousCanonicalEvents: previousCanonicalEvents,
      );
      final totalElapsed = stopwatch.elapsedMilliseconds;
      debugPrint('TenantHomeAgendaController._refresh: '
          'Location resolution took ${locationElapsed}ms, '
          'API fetch took ${totalElapsed - locationElapsed}ms. '
          'Total: ${totalElapsed}ms.');
    } catch (error) {
      if (_isDisposed) {
        return;
      }
      debugPrint('TenantHomeAgendaController._refresh failed: $error');
      if (shouldShowInitialLoading) {
        final recovered = await _retryFirstPageAfterFailure();
        if (!recovered) {
          _publishEmptyFirstPageStateIfNeeded();
          debugPrint(
            'TenantHomeAgendaController._refresh retry failed after first-page error.',
          );
        }
      }
    } finally {
      if (shouldShowInitialLoading) {
        _ifAlive(() => isInitialLoadingStreamValue.addValue(false));
        _ifAlive(() => initialLoadingLabelStreamValue.addValue(''));
      }
      _isRefreshing = false;
      _consumeQueuedRefreshRequestIfNeeded();
      _maybeResolveRadiusRefreshLoading();
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
      _ifAlive(
        () =>
            initialLoadingLabelStreamValue.addValue(_loadingNearbyEventsLabel),
      );
      await _fetchAgenda(append: false);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _publishEmptyFirstPageStateIfNeeded() {
    if (_isDisposed) {
      return;
    }
    _hasMore = false;
    _ifAlive(() => hasMoreStreamValue.addValue(false));
    if (displayStateStreamValue.value != null) {
      return;
    }
    _ifAlive(
      () => displayStateStreamValue.addValue(
        TenantHomeAgendaDisplayState(events: const <EventModel>[]),
      ),
    );
  }

  Future<void> loadNextPage() async {
    if (!_hasMore || _isFetching || _isRefreshing) return;
    await _fetchAgenda(append: true);
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

  Future<void> _fetchAgenda({
    required bool append,
    bool showPageLoadingForFirstPage = false,
    List<EventModel> previousCanonicalEvents = const <EventModel>[],
  }) async {
    if (_isFetching) return;
    _isFetching = true;
    if (append || showPageLoadingForFirstPage) {
      _ifAlive(() => isPageLoadingStreamValue.addValue(true));
    }

    try {
      final showPastOnly = _toScheduleBool(showHistoryStreamValue.value);
      final searchQuery = _toScheduleText(searchController.text);
      final confirmedOnly = _toScheduleBool(
        inviteFilterStreamValue.value == InviteFilter.confirmedOnly,
      );
      final originLat = _toNullableScheduleDouble(_effectiveOriginLat);
      final originLng = _toNullableScheduleDouble(_effectiveOriginLng);
      final maxDistanceMeters =
          _toScheduleDouble(radiusMetersStreamValue.value);
      final categories = _selectedEventCategories();
      final taxonomy = _selectedEventTaxonomyEntries();
      final previousCanonicalEventCount = previousCanonicalEvents.isNotEmpty
          ? previousCanonicalEvents.length
          : _currentCanonicalEvents().length;

      List<EventModel> resolvedEvents;
      if (!append) {
        resolvedEvents = await _scheduleRepository.loadHomeAgenda(
          showPastOnly: showPastOnly,
          searchQuery: searchQuery,
          confirmedOnly: confirmedOnly,
          originLat: originLat,
          originLng: originLng,
          maxDistanceMeters: maxDistanceMeters,
          categories: categories,
          taxonomy: taxonomy,
        );
      } else {
        resolvedEvents = await _scheduleRepository.loadMoreHomeAgenda(
          showPastOnly: showPastOnly,
          searchQuery: searchQuery,
          confirmedOnly: confirmedOnly,
          originLat: originLat,
          originLng: originLng,
          maxDistanceMeters: maxDistanceMeters,
          categories: categories,
          taxonomy: taxonomy,
        );
      }

      if (!append &&
          showPageLoadingForFirstPage &&
          previousCanonicalEvents.isNotEmpty &&
          resolvedEvents.isEmpty) {
        await Future<void>.delayed(_preservedFirstPageEmptyRetryDelay);
        if (_isDisposed) {
          return;
        }
        resolvedEvents = await _scheduleRepository.loadHomeAgenda(
          showPastOnly: showPastOnly,
          searchQuery: searchQuery,
          confirmedOnly: confirmedOnly,
          originLat: originLat,
          originLng: originLng,
          maxDistanceMeters: maxDistanceMeters,
          categories: categories,
          taxonomy: taxonomy,
        );
        if (resolvedEvents.isEmpty) {
          return;
        }
      }

      _hasMore = !append
          ? resolvedEvents.isNotEmpty
          : resolvedEvents.length > previousCanonicalEventCount;
      _ifAlive(() => hasMoreStreamValue.addValue(_hasMore));
      _applyFiltersAndPublish();
    } finally {
      _isFetching = false;
      _ifAlive(() => isPageLoadingStreamValue.addValue(false));
    }
  }

  @override
  void toggleHistory() {
    final currentValue = showHistoryStreamValue.value;
    _ifAlive(() => showHistoryStreamValue.addValue(!currentValue));
    _refresh();
  }

  void setInviteFilter(InviteFilter filter) {
    _ifAlive(() => inviteFilterStreamValue.addValue(filter));
    _applyFiltersAndPublish();
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
    final clamped = _clampRadiusMeters(meters);
    final previousRadius = radiusMetersStreamValue.value;
    _pendingPersistedRadiusEchoMeters = clamped;
    _ifAlive(() => radiusMetersStreamValue.addValue(clamped));
    if (_didRadiusChangeEffectively(
      previousRadius: previousRadius,
      nextRadius: clamped,
    )) {
      unawaited(
        _logRadiusChangedTelemetry(
          previousRadiusMeters: previousRadius,
          selectedRadiusMeters: clamped,
        ),
      );
    }
    unawaited(_persistSelectedRadiusPreference(clamped));
    _scheduleRadiusRefresh();
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
    _refresh();
  }

  @override
  Future<void> searchEvents(String query) async {
    await _refresh();
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
    if (_scheduleRepository.homeAgendaStreamValue.value == null &&
        displayStateStreamValue.value == null) {
      return;
    }
    final inviteFiltered = _applyInviteFilter(_currentCanonicalEvents());
    _ifAlive(
      () => displayStateStreamValue.addValue(
        TenantHomeAgendaDisplayState(events: inviteFiltered),
      ),
    );
  }

  List<EventModel> _currentCanonicalEvents() {
    return _scheduleRepository.homeAgendaStreamValue.value ??
        const <EventModel>[];
  }

  bool _restoreFromRepositoryCache() {
    final cacheOrigin = _currentCacheReferenceOrigin();
    final showPastOnly = showHistoryStreamValue.value;
    final searchQuery = searchController.text.trim();
    final confirmedOnly =
        inviteFilterStreamValue.value == InviteFilter.confirmedOnly;
    final cache = _scheduleRepository.readHomeAgenda(
      showPastOnly: _toScheduleBool(showPastOnly),
      searchQuery: _toScheduleText(searchQuery),
      confirmedOnly: _toScheduleBool(confirmedOnly),
      originLat: _toNullableScheduleDouble(cacheOrigin?.latitude),
      originLng: _toNullableScheduleDouble(cacheOrigin?.longitude),
      maxDistanceMeters: _toScheduleDouble(radiusMetersStreamValue.value),
      categories: _selectedEventCategories(),
      taxonomy: _selectedEventTaxonomyEntries(),
    );
    if (cache == null) {
      return false;
    }

    _hasMore = cache.isNotEmpty;
    _effectiveOriginLat = cacheOrigin?.latitude;
    _effectiveOriginLng = cacheOrigin?.longitude;
    _ifAlive(() => hasMoreStreamValue.addValue(_hasMore));
    _applyFiltersAndPublish();
    return true;
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

  String _eventOccurrenceIdentity(EventModel event) =>
      event.selectedOccurrenceId?.trim() ?? '';

  String? distanceLabelFor(VenueEventResume event) {
    final userCoordinate = _currentCacheReferenceOrigin();
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

  CityCoordinate? _currentCacheReferenceOrigin() {
    if (_effectiveOriginLat != null && _effectiveOriginLng != null) {
      return CityCoordinate(
        latitudeValue: _parseLatitude(_effectiveOriginLat!),
        longitudeValue: _parseLongitude(_effectiveOriginLng!),
      );
    }
    return _locationOriginService.resolveCached().effectiveCoordinate;
  }

  String _formatDistanceLabel(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  List<ScheduleRepoString>? _selectedEventCategories() {
    final payload = DiscoveryFilterQueryPayload.compile(
      catalog: discoveryFilterCatalogStreamValue.value,
      selection: discoveryFilterSelectionStreamValue.value,
    );
    final categories = payload.typesForEntity('event');
    if (categories.isEmpty) {
      return null;
    }
    return categories
        .map(_toScheduleText)
        .where((value) => value.value.trim().isNotEmpty)
        .toList(growable: false);
  }

  ScheduleRepoTaxonomyEntries? _selectedEventTaxonomyEntries() {
    final payload = DiscoveryFilterQueryPayload.compile(
      catalog: discoveryFilterCatalogStreamValue.value,
      selection: discoveryFilterSelectionStreamValue.value,
    );
    final entries = payload.taxonomyEntries;
    if (entries.isEmpty) {
      return null;
    }
    final taxonomy = ScheduleRepoTaxonomyEntries();
    for (final entry in entries) {
      taxonomy.add(
        ScheduleRepoTaxonomyEntry(
          type: _toScheduleText(entry.type),
          term: _toScheduleText(entry.value),
        ),
      );
    }
    return taxonomy.isEmpty ? null : taxonomy;
  }

  void _listenForStatusChanges() {
    _confirmedEventsSubscription?.cancel();
    _pendingInvitesSubscription?.cancel();

    _confirmedEventsSubscription =
        _userEventsRepository.confirmedOccurrenceIdsStream.stream.listen((_) {
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
    _ifAlive(
      () => _maxRadiusMetersStreamValue.addValue(_configuredMaxRadiusMeters()),
    );
    _radiusSubscription =
        _appDataRepository.maxRadiusMetersStreamValue.stream.listen((value) {
      _ifAlive(
        () =>
            _maxRadiusMetersStreamValue.addValue(_configuredMaxRadiusMeters()),
      );
      final clamped = _clampRadiusMeters(value.value);
      final pendingEcho = _pendingPersistedRadiusEchoMeters;
      if (pendingEcho != null) {
        if ((pendingEcho - clamped).abs() < 0.001) {
          _pendingPersistedRadiusEchoMeters = null;
        }
        return;
      }
      final current = radiusMetersStreamValue.value;
      if ((current - clamped).abs() < 0.001) {
        return;
      }
      _ifAlive(() => radiusMetersStreamValue.addValue(clamped));
      _scheduleRadiusRefresh();
    });
  }

  Future<void> _persistSelectedRadiusPreference(double meters) async {
    final value = DistanceInMetersValue(
      defaultValue: meters,
    )..parse(meters.toString());
    try {
      final repository = _proximityPreferencesRepository;
      if (repository != null) {
        await repository.updateMaxDistanceMeters(value);
      } else {
        await _appDataRepository.setMaxRadiusMeters(value);
      }
    } catch (_) {
      if ((_pendingPersistedRadiusEchoMeters ?? -1) == meters) {
        _pendingPersistedRadiusEchoMeters = null;
      }
      rethrow;
    }
  }

  void _scheduleRadiusRefresh() {
    _radiusRefreshDebounceTimer?.cancel();
    _ifAlive(() => isRadiusRefreshLoadingStreamValue.addValue(true));
    _radiusRefreshDebounceTimer = Timer(_radiusRefreshDebounce, () {
      _radiusRefreshDebounceTimer = null;
      if (_isDisposed) {
        return;
      }
      unawaited(_refresh(preserveCurrentResults: true));
    });
  }

  void _maybeResolveRadiusRefreshLoading() {
    final hasPendingDebounce = _radiusRefreshDebounceTimer?.isActive ?? false;
    if (hasPendingDebounce || _isRefreshing || _hasQueuedRefresh) {
      return;
    }
    _ifAlive(() => isRadiusRefreshLoadingStreamValue.addValue(false));
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

  Future<void> _reconcileEffectiveOriginAfterCacheRestore() async {
    if (_isDisposed) {
      return;
    }
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
    final shouldRequestPermission =
        warmUpIfPossible && !_locationPermissionRequested;
    if (shouldRequestPermission) {
      _locationPermissionRequested = true;
    }
    final resolution = await _locationOriginService.resolveAndPersist(
      LocationOriginResolutionRequestFactory.create(
        warmUpIfPossible: warmUpIfPossible,
        requestPermissionIfNeeded: shouldRequestPermission,
        warmUpTimeout: _locationWarmUpTimeout,
        permissionTimeout: _locationPermissionTimeout,
      ),
    );
    await _seedInitialRadiusPreferenceIfNeeded(resolution);
    final effectiveOrigin = resolution.effectiveCoordinate;
    if (effectiveOrigin != null) {
      _effectiveOriginLat = effectiveOrigin.latitude;
      _effectiveOriginLng = effectiveOrigin.longitude;
      return _effectiveOriginLat != currentLat ||
          _effectiveOriginLng != currentLng;
    }

    _effectiveOriginLat = null;
    _effectiveOriginLng = null;
    return currentLat != null || currentLng != null;
  }

  Future<void> _seedInitialRadiusPreferenceIfNeeded(
    LocationOriginResolution resolution,
  ) async {
    if (_appDataRepository.hasPersistedMaxRadiusPreference ||
        resolution.liveUserCoordinate == null ||
        resolution.tenantDefaultCoordinate == null ||
        resolution.distanceFromTenantDefaultOriginMeters == null) {
      return;
    }

    final suggestedRadiusMeters = _clampRadiusMeters(
      resolution.distanceFromTenantDefaultOriginMeters!,
    );

    if ((radiusMetersStreamValue.value - suggestedRadiusMeters).abs() >=
        0.001) {
      _ifAlive(() => radiusMetersStreamValue.addValue(suggestedRadiusMeters));
    }

    _pendingPersistedRadiusEchoMeters = suggestedRadiusMeters;
    try {
      await _persistSelectedRadiusPreference(suggestedRadiusMeters);
    } on Object {
      if ((_pendingPersistedRadiusEchoMeters ?? -1) == suggestedRadiusMeters) {
        _pendingPersistedRadiusEchoMeters = null;
      }
      debugPrint(
        'TenantHomeAgendaController._seedInitialRadiusPreferenceIfNeeded failed',
      );
    }
  }

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
    return _clampRadiusMeters(_configuredMaxRadiusMeters());
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
      return _configuredMaxRadiusMeters();
    }
  }

  double _configuredMaxRadiusMeters() {
    try {
      return _appDataRepository.appData.mapRadiusMaxMeters;
    } on Object {
      return _appDataRepository.maxRadiusMeters.value;
    }
  }

  double _clampRadiusMeters(double meters) {
    final min = _resolveMinRadiusMeters();
    final max = _configuredMaxRadiusMeters();
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
    displayStateStreamValue.dispose();
    isInitialLoadingStreamValue.dispose();
    initialLoadingLabelStreamValue.dispose();
    isPageLoadingStreamValue.dispose();
    hasMoreStreamValue.dispose();
    showHistoryStreamValue.dispose();
    searchActiveStreamValue.dispose();
    inviteFilterStreamValue.dispose();
    discoveryFilterCatalogStreamValue.dispose();
    discoveryFilterSelectionStreamValue.dispose();
    isDiscoveryFilterPanelVisibleStreamValue.dispose();
    isDiscoveryFilterCatalogLoadingStreamValue.dispose();
    radiusMetersStreamValue.dispose();
    isRadiusRefreshLoadingStreamValue.dispose();
    isRadiusActionCompactStreamValue.dispose();
    _maxRadiusMetersStreamValue.dispose();
    focusNode.dispose();
    searchController.dispose();
  }
}
