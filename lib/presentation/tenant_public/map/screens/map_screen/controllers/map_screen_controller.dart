import 'dart:async';
import 'dart:math' as math;

import 'package:belluga_now/application/router/guards/location_permission_gate_runtime.dart';
import 'package:belluga_now/application/time/timezone_converter.dart';
import 'package:belluga_now/application/map_surface/belluga_map_handle.dart';
import 'package:belluga_now/application/map_surface/belluga_map_handle_contract.dart';
import 'package:belluga_now/application/map_surface/belluga_map_interaction.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/location_origin_settings.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_mode.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/map_status.dart';
import 'package:belluga_now/domain/map/projections/city_poi_stack_items.dart';
import 'package:belluga_now/domain/map/projections/city_poi_linked_profile.dart';
import 'package:belluga_now/domain/map/projections/city_poi_visual.dart';
import 'package:belluga_now/domain/map/queries/poi_query.dart';
import 'package:belluga_now/domain/map/ride_share_provider.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_address_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_description_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_name_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_key_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_image_uri_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_search_term_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_source_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_taxonomy_token_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_path_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_slug_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_stack_count_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_stack_key_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_tag_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_type_label_value.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/poi_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/static_assets/public_static_asset_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_duration_value.dart';
import 'package:belluga_now/domain/services/location_origin_service_contract.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:belluga_now/infrastructure/services/location_origin_resolution_request_factory.dart';
import 'package:belluga_now/presentation/shared/location_permission/location_origin_message_resolver.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_location_feedback_state.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_selected_poi_memory.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_tray_mode.dart';
import 'package:stream_value/core/stream_value.dart';

class MapScreenController implements Disposable {
  static const double minZoom = 14.5;
  static const double maxZoom = 17.0;
  static const double _selectedPoiViewportAnchor = 0.28;
  static const double _filteredPreviewViewportAnchor = 0.40;
  static const Duration _postFilterMarkerTapSuppression = Duration(
    milliseconds: 1000,
  );
  static const Duration _searchInputDebounceDelay = Duration(
    milliseconds: 260,
  );
  MapScreenController({
    PoiRepositoryContract? poiRepository,
    UserLocationRepositoryContract? userLocationRepository,
    TelemetryRepositoryContract? telemetryRepository,
    BellugaMapHandleContract? mapHandle,
    AppData? appData,
    AppDataRepositoryContract? appDataRepository,
    LocationOriginServiceContract? locationOriginService,
    AuthRepositoryContract? authRepository,
  })  : _poiRepository = poiRepository ?? GetIt.I.get<PoiRepositoryContract>(),
        _userLocationRepository = userLocationRepository ??
            GetIt.I.get<UserLocationRepositoryContract>(),
        _telemetryRepository =
            telemetryRepository ?? GetIt.I.get<TelemetryRepositoryContract>(),
        _appData = appData ?? GetIt.I.get<AppData>(),
        _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>(),
        _locationOriginService = locationOriginService ??
            GetIt.I.get<LocationOriginServiceContract>(),
        _authRepository = authRepository ??
            (GetIt.I.isRegistered<AuthRepositoryContract>()
                ? GetIt.I.get<AuthRepositoryContract>()
                : null),
        mapHandle = mapHandle ?? BellugaMapHandle();

  final PoiRepositoryContract _poiRepository;
  final UserLocationRepositoryContract _userLocationRepository;
  final TelemetryRepositoryContract _telemetryRepository;
  final AppData _appData;
  final AppDataRepositoryContract _appDataRepository;
  final LocationOriginServiceContract _locationOriginService;
  final AuthRepositoryContract? _authRepository;

  final BellugaMapHandleContract mapHandle;

  final statusMessageStreamValue = StreamValue<String?>();
  final softLocationNoticeStreamValue = StreamValue<String>(defaultValue: '');
  final locationFeedbackStateStreamValue =
      StreamValue<MapLocationFeedbackState>(
    defaultValue: const MapLocationFeedbackState.loading(
      resolutionPhase: LocationResolutionPhase.unknown,
    ),
  );
  final mapStatusStreamValue =
      StreamValue<MapStatus>(defaultValue: MapStatus.locating);
  final isLoading = StreamValue<bool>(defaultValue: false);
  final filterInteractionLockedStreamValue =
      StreamValue<bool>(defaultValue: false);
  final mapInteractionGuardActiveStreamValue =
      StreamValue<bool>(defaultValue: false);
  final mapTrayModeStreamValue =
      StreamValue<MapTrayMode>(defaultValue: MapTrayMode.discovery);
  final errorMessage = StreamValue<String?>();
  final searchTermStreamValue = StreamValue<String?>();
  final searchTextController = TextEditingController();
  final lastSelectedPoiMemoryStreamValue = StreamValue<MapSelectedPoiMemory?>();
  final selectedPoiLoadingIdStreamValue = StreamValue<String?>();
  final hasSelectedPoiLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final hasSelectedPoiStreamValue = StreamValue<bool>(defaultValue: false);
  final hasClusterPickerStreamValue = StreamValue<bool>(defaultValue: false);
  final clusterPickerAnchorCoordinateStreamValue =
      StreamValue<CityCoordinate?>();
  final zoomStreamValue = StreamValue<double>(defaultValue: 16);
  Timer? _zoomThrottle;
  Timer? _searchInputDebounceTimer;
  double? _pendingZoom;
  Future<EventTrackerTimedEventHandle?>? _activePoiTimedEventFuture;
  String? _activePoiId;
  final StreamValue<int> poiDeckIndexStreamValue =
      StreamValue<int>(defaultValue: 0);
  final StreamValue<int> poiDeckHeightRevisionStreamValue =
      StreamValue<int>(defaultValue: 0);
  final Map<String, double> poiDeckHeights = <String, double>{};

  StreamValue<CityCoordinate?> get userLocationStreamValue =>
      _userLocationRepository.userLocationStreamValue;
  bool get hasResolvedUserLocation => userLocationStreamValue.value != null;

  StreamValue<List<CityPoiModel>?> get filteredPoisStreamValue =>
      _poiRepository.filteredPoisStreamValue;

  StreamValue<CityPoiModel?> get selectedPoiStreamValue =>
      _poiRepository.selectedPoiStreamValue;

  StreamValue<List<CityPoiModel>?> get clusterPickerPoisStreamValue =>
      _poiRepository.stackItemsStreamValue;

  StreamValue<PoiFilterMode> get filterModeStreamValue =>
      _poiRepository.filterModeStreamValue;

  StreamValue<PoiFilterOptions?> get filterOptionsStreamValue =>
      _poiRepository.filterOptionsStreamValue;
  StreamValue<int> get poiDeckContentRevisionStreamValue =>
      _poiRepository.poiHydrationRevisionStreamValue;

  final StreamValue<Set<String>> activeCategoryKeysStreamValue =
      StreamValue<Set<String>>(defaultValue: const <String>{});
  final StreamValue<String?> activeCatalogFilterKeyStreamValue =
      StreamValue<String?>(defaultValue: null);
  final StreamValue<String?> appliedCatalogFilterKeyStreamValue =
      StreamValue<String?>(defaultValue: null);
  final StreamValue<String?> activeFilterLabelStreamValue =
      StreamValue<String?>();
  final StreamValue<String?> pendingFilterLabelStreamValue =
      StreamValue<String?>();

  CityCoordinate get defaultCenter => _poiRepository.defaultCenter;

  PoiQuery _currentQuery = PoiQuery();
  LocationOriginSettings? _currentQueryOriginSettings;
  bool _forceTenantDefaultUnavailableEntry = false;
  bool _filtersLoadFailed = false;
  Set<String> _activeCategoryKeys = <String>{};
  Set<String> _activeTaxonomyTokens = <String>{};
  Set<String> _activeTags = <String>{};
  String? _activeSource;
  Set<String> _activeTypes = <String>{};
  String? _activeCatalogFilterKey;
  String? _appliedCatalogFilterKey;
  StreamSubscription<BellugaMapInteractionEvent>? _mapInteractionSubscription;
  StreamSubscription<List<CityPoiModel>?>? _filteredPoisSubscription;
  StreamSubscription<CityPoiModel?>? _selectedPoiSubscription;
  StreamSubscription<LocationResolutionPhase>? _locationResolutionSubscription;
  StreamSubscription<LocationOriginSettings?>?
      _locationOriginSettingsSubscription;
  int _poiRequestSequence = 0;
  bool _filterInteractionLocked = false;
  CityPoiModel? _pendingInitialPoiFocus;
  bool _initialPoiFocusApplied = false;
  bool _initialPoiFocusInProgress = false;
  bool _hasObservedMapEvent = false;
  bool _locationFeedbackNoticesArmed = false;
  MapLocationFeedbackState? _lastTerminalLocationFeedbackState;
  Timer? _softLocationNoticeTimer;
  Timer? _postFilterMarkerTapSuppressionTimer;
  bool _markerTapSuppressedAfterFilterReload = false;
  bool _isReconcilingLocationOrigin = false;
  int _selectedPoiHydrationSequence = 0;
  CityCoordinate? _searchTrayOrigin;

  bool get isUserAuthenticated => _authRepository?.isUserLoggedIn ?? false;

  String? get authenticatedUserDisplayName {
    final raw =
        _authRepository?.userStreamValue.value?.profile.nameValue?.value.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return raw;
  }

  AccountProfileModel? hydratedAccountProfileForPoi(CityPoiModel poi) {
    return _poiRepository.hydratedAccountProfileForPoi(poi);
  }

  EventModel? hydratedEventForPoi(CityPoiModel poi) {
    return _poiRepository.hydratedEventForPoi(poi);
  }

  PublicStaticAssetModel? hydratedStaticAssetForPoi(CityPoiModel poi) {
    return _poiRepository.hydratedStaticAssetForPoi(poi);
  }

  Uri? buildTenantPublicUriFromPath(String? rawPath) {
    final normalizedPath = rawPath?.trim();
    if (normalizedPath == null || normalizedPath.isEmpty) {
      return null;
    }
    return _appData.mainDomainValue.value.resolve(normalizedPath);
  }

  Uri get defaultEventImageUri {
    final configured = _appData.mainLogoDarkUrl.value;
    if (configured != null && configured.toString().trim().isNotEmpty) {
      return configured;
    }
    return Uri.parse('asset://event-placeholder');
  }

  Future<void> init({
    String? initialPoiQuery,
    String? initialPoiStackQuery,
  }) async {
    final enteredViaSoftLocationGate =
        LocationPermissionGateRuntime.consumeSoftLocationFallbackEntry();
    _resetInitialPoiFocusState();
    _forceTenantDefaultUnavailableEntry = enteredViaSoftLocationGate;
    _locationFeedbackNoticesArmed = false;
    _cancelSoftLocationNoticeTimer();
    softLocationNoticeStreamValue.addValue('');
    _attachLocationFeedbackListeners();
    _refreshLocationFeedback(emitNotice: false);
    final hasInitialPoiQuery = _normalizePoiQuery(initialPoiQuery) != null;
    _bindFilteredPoisClamp();
    _bindSelectedPoiPresence();
    _attachZoomListener();

    final initialPoiHydrationFuture = hasInitialPoiQuery
        ? _applyInitialPoiQuery(
            initialPoiQuery: initialPoiQuery,
            initialPoiStackQuery: initialPoiStackQuery,
            emitNotFoundMessage: false,
          )
        : Future<void>.value();

    await Future.wait([
      loadFilters(force: true),
      loadPois(PoiQuery()),
      _userLocationRepository.refreshIfPermitted(
        minInterval: UserLocationRepositoryContractDurationValue.fromRaw(
          Duration.zero,
          defaultValue: Duration.zero,
        ),
      ),
      initialPoiHydrationFuture,
    ]);

    if (hasInitialPoiQuery) {
      await _applyInitialPoiQuery(
        initialPoiQuery: initialPoiQuery,
        initialPoiStackQuery: initialPoiStackQuery,
      );
    } else if (!enteredViaSoftLocationGate) {
      _requestLocationPermissionIfNeeded();
    }

    _locationFeedbackNoticesArmed = true;
    _refreshLocationFeedback(emitNotice: false);
    _showSoftLocationNoticeForState(
      locationFeedbackStateStreamValue.value,
      force: true,
    );
    _tryApplyPendingInitialPoiFocus();
  }

  void _requestLocationPermissionIfNeeded() {
    if (_forceTenantDefaultUnavailableEntry || hasResolvedUserLocation) {
      return;
    }
    unawaited(
      _resolveUserLocationAndReconcile(
        emitNotice: true,
        reloadPoisIfOriginChanged: true,
      ),
    );
  }

  void _attachLocationFeedbackListeners() {
    _locationResolutionSubscription ??= _userLocationRepository
        .locationResolutionPhaseStreamValue.stream
        .listen((_) {
      _refreshLocationFeedback(emitNotice: _locationFeedbackNoticesArmed);
      unawaited(_reconcileResolvedOriginIfNeeded());
    });
    _locationOriginSettingsSubscription ??=
        _appDataRepository.locationOriginSettingsStreamValue.stream.listen((_) {
      _refreshLocationFeedback(emitNotice: _locationFeedbackNoticesArmed);
      unawaited(_reconcileResolvedOriginIfNeeded());
    });
  }

  void _bindFilteredPoisClamp() {
    if (_filteredPoisSubscription != null) {
      return;
    }
    _filteredPoisSubscription =
        filteredPoisStreamValue.stream.listen(_clampPoiDeckIndex);
    _clampPoiDeckIndex(filteredPoisStreamValue.value);
  }

  void _bindSelectedPoiPresence() {
    if (_selectedPoiSubscription != null) {
      return;
    }
    hasSelectedPoiStreamValue.addValue(selectedPoiStreamValue.value != null);
    _selectedPoiSubscription = selectedPoiStreamValue.stream.listen((poi) {
      final hasSelectedPoi = poi != null;
      if (hasSelectedPoiStreamValue.value == hasSelectedPoi) {
        return;
      }
      hasSelectedPoiStreamValue.addValue(hasSelectedPoi);
    });
  }

  void _clampPoiDeckIndex(List<CityPoiModel>? poisOrNull) {
    final pois = poisOrNull ?? const <CityPoiModel>[];
    if (pois.isEmpty) {
      if (poiDeckIndexStreamValue.value != 0) {
        poiDeckIndexStreamValue.addValue(0);
      }
      return;
    }
    final maxIndex = pois.length - 1;
    final current = poiDeckIndexStreamValue.value;
    final clamped = current.clamp(0, maxIndex);
    if (current != clamped) {
      poiDeckIndexStreamValue.addValue(clamped);
    }
  }

  Future<void> startTracking({
    LocationTrackingMode mode = LocationTrackingMode.mapForeground,
  }) async {
    await _userLocationRepository.startTracking(mode: mode);
  }

  Future<void> stopTracking() async {
    await _userLocationRepository.stopTracking();
  }

  Future<void> loadFilters({bool force = false}) async {
    if (!force &&
        filterOptionsStreamValue.value != null &&
        !_filtersLoadFailed) {
      return;
    }
    try {
      await _poiRepository.fetchFilters();
      _filtersLoadFailed = false;
    } catch (error) {
      _filtersLoadFailed = true;
      debugPrint('Failed to load POI filters: $error');
    }
  }

  Future<void> centerOnUser({bool animate = true}) async {
    var feedback = locationFeedbackStateStreamValue.value;
    var coordinate =
        feedback.targetCoordinate ?? _resolveCurrentEffectiveOrigin();
    if (!feedback.isActionEnabled && coordinate == null) {
      return;
    }

    if (feedback.kind == MapLocationFeedbackKind.permissionDenied ||
        feedback.kind == MapLocationFeedbackKind.unavailable) {
      await _resolveUserLocationAndReconcile(
        emitNotice: true,
        reloadPoisIfOriginChanged: true,
      );
      feedback = locationFeedbackStateStreamValue.value;
    }

    coordinate = feedback.targetCoordinate ?? _resolveCurrentEffectiveOrigin();
    if (coordinate == null) {
      if (feedback.isErrorLike || feedback.isAlertLike) {
        _showSoftLocationNoticeForState(
          feedback,
          force: true,
        );
        return;
      }
      _logMapTelemetry(
        EventTrackerEvents.viewContent,
        eventName: telemetryRepoString('map_location_resolved'),
        properties: const {
          'status': 'fallback',
          'reason': 'not_found',
        },
      );
      statusMessageStreamValue.addValue('Não encontramos sua localização');
      return;
    }

    final isMapReady = await ensureMapReady();
    if (!isMapReady) {
      return;
    }
    final targetZoom = animate ? 16.0 : _currentMapZoomOrDefault();
    var didMove = mapHandle.moveTo(
      coordinate,
      zoom: _clampZoom(targetZoom),
    );
    if (!didMove) {
      final readyAfterRetry = await ensureMapReady();
      if (!readyAfterRetry) {
        return;
      }
      didMove = mapHandle.moveTo(
        coordinate,
        zoom: _clampZoom(targetZoom),
      );
      if (!didMove) {
        debugPrint('Map moveTo failed after readiness reconciliation.');
        return;
      }
    }
    _logMapTelemetry(
      EventTrackerEvents.viewContent,
      eventName: telemetryRepoString('map_location_resolved'),
      properties: const {
        'status': 'success',
      },
    );

    statusMessageStreamValue.addValue(null);
    if (feedback.isErrorLike || feedback.isAlertLike) {
      _showSoftLocationNoticeForState(
        feedback,
        force: true,
      );
    }
  }

  double _currentMapZoomOrDefault() {
    return mapHandle.currentZoom ?? 16.0;
  }

  void clearStatusMessage() {
    statusMessageStreamValue.addValue(null);
  }

  void dismissSoftLocationNotice() {
    _cancelSoftLocationNoticeTimer();
    softLocationNoticeStreamValue.addValue('');
  }

  Future<void> _resolveUserLocationAndReconcile({
    required bool emitNotice,
    required bool reloadPoisIfOriginChanged,
  }) async {
    await _userLocationRepository.resolveUserLocation();
    _refreshLocationFeedback(emitNotice: emitNotice);
    if (!reloadPoisIfOriginChanged) {
      return;
    }
    await _reconcileResolvedOriginIfNeeded();
  }

  void _refreshLocationFeedback({
    required bool emitNotice,
  }) {
    final previous = locationFeedbackStateStreamValue.value;
    final next = _deriveLocationFeedbackState(previous);

    if (_locationFeedbackSignature(previous) ==
        _locationFeedbackSignature(next)) {
      return;
    }

    locationFeedbackStateStreamValue.addValue(next);
    if (next.isTerminal) {
      _lastTerminalLocationFeedbackState = next;
    }

    if (emitNotice) {
      _showSoftLocationNoticeForState(
        next,
        previous: previous,
      );
    }
  }

  MapLocationFeedbackState _deriveLocationFeedbackState(
    MapLocationFeedbackState previous,
  ) {
    final phase =
        _userLocationRepository.locationResolutionPhaseStreamValue.value;
    final resolution = _locationOriginService.resolveCached();
    final settings = resolution.settings;
    final targetCoordinate = resolution.effectiveCoordinate;

    if (settings?.usesUserFixedLocation == true) {
      return MapLocationFeedbackState(
        kind: MapLocationFeedbackKind.fixedManual,
        resolutionPhase: phase,
        settings: settings,
        targetCoordinate: targetCoordinate,
      );
    }

    if (_forceTenantDefaultUnavailableEntry &&
        settings?.usesTenantDefaultUnavailable == true) {
      return MapLocationFeedbackState(
        kind: MapLocationFeedbackKind.unavailable,
        resolutionPhase: phase,
        settings: settings,
        targetCoordinate: targetCoordinate ?? defaultCenter,
      );
    }

    if (phase == LocationResolutionPhase.unknown ||
        phase == LocationResolutionPhase.resolving) {
      final retained = _lastTerminalLocationFeedbackState;
      if (retained != null) {
        return MapLocationFeedbackState(
          kind: retained.kind,
          resolutionPhase: phase,
          settings: settings ?? retained.settings,
          targetCoordinate: targetCoordinate ?? retained.targetCoordinate,
        );
      }
      return MapLocationFeedbackState.loading(
        resolutionPhase: phase,
      );
    }

    if (phase == LocationResolutionPhase.permissionDenied) {
      return MapLocationFeedbackState(
        kind: MapLocationFeedbackKind.permissionDenied,
        resolutionPhase: phase,
        settings: settings,
        targetCoordinate: targetCoordinate,
      );
    }

    if (settings?.usesUserLiveLocation == true) {
      return MapLocationFeedbackState(
        kind: MapLocationFeedbackKind.live,
        resolutionPhase: phase,
        settings: settings,
        targetCoordinate: targetCoordinate,
      );
    }

    if (settings?.usesTenantDefaultOutsideRange == true) {
      return MapLocationFeedbackState(
        kind: MapLocationFeedbackKind.outsideRange,
        resolutionPhase: phase,
        settings: settings,
        targetCoordinate: targetCoordinate,
      );
    }

    if ((settings?.usesTenantDefaultUnavailable == true) ||
        phase == LocationResolutionPhase.unavailable) {
      return MapLocationFeedbackState(
        kind: MapLocationFeedbackKind.unavailable,
        resolutionPhase: phase,
        settings: settings,
        targetCoordinate: targetCoordinate ?? defaultCenter,
      );
    }

    return previous.isTerminal
        ? previous
        : MapLocationFeedbackState.loading(resolutionPhase: phase);
  }

  CityCoordinate? _resolveCurrentEffectiveOrigin() {
    return _locationOriginService.resolveCached().effectiveCoordinate;
  }

  bool _sameCoordinate(
    CityCoordinate? left,
    CityCoordinate? right,
  ) {
    if (left == null && right == null) {
      return true;
    }
    if (left == null || right == null) {
      return false;
    }
    return left.latitude == right.latitude && left.longitude == right.longitude;
  }

  String _locationFeedbackSignature(MapLocationFeedbackState state) {
    final target = state.targetCoordinate;
    return [
      state.kind.name,
      state.resolutionPhase.name,
      state.settings?.mode.name ?? 'none',
      state.settings?.reason.name ?? 'none',
      target?.latitude.toStringAsFixed(6) ?? 'null',
      target?.longitude.toStringAsFixed(6) ?? 'null',
    ].join('|');
  }

  void _showSoftLocationNoticeForState(
    MapLocationFeedbackState state, {
    MapLocationFeedbackState? previous,
    bool force = false,
  }) {
    if (!state.isTerminal) {
      return;
    }

    final shouldEmit = force ||
        previous == null ||
        previous.kind != state.kind ||
        !previous.isTerminal;
    if (!shouldEmit) {
      return;
    }

    final message = _messageForLocationFeedbackState(state);
    if (message == null || message.trim().isEmpty) {
      return;
    }

    _cancelSoftLocationNoticeTimer();
    softLocationNoticeStreamValue.addValue(message);
    _softLocationNoticeTimer = Timer(
      const Duration(seconds: 10),
      dismissSoftLocationNotice,
    );
  }

  String? _messageForLocationFeedbackState(MapLocationFeedbackState state) {
    switch (state.kind) {
      case MapLocationFeedbackKind.loading:
        return null;
      case MapLocationFeedbackKind.permissionDenied:
        return 'Permita o acesso à sua localização para mostrar eventos e lugares mais próximos.';
      case MapLocationFeedbackKind.live:
      case MapLocationFeedbackKind.fixedManual:
      case MapLocationFeedbackKind.outsideRange:
      case MapLocationFeedbackKind.unavailable:
        final settings = state.settings;
        if (settings == null) {
          return null;
        }
        return LocationOriginMessageResolver.fromSettings(
          settings: settings,
          appName: _appData.nameValue.value,
        );
    }
  }

  void _cancelSoftLocationNoticeTimer() {
    _softLocationNoticeTimer?.cancel();
    _softLocationNoticeTimer = null;
  }

  Future<void> _reconcileResolvedOriginIfNeeded() async {
    if (_isReconcilingLocationOrigin) {
      return;
    }

    final phase =
        _userLocationRepository.locationResolutionPhaseStreamValue.value;
    if (phase == LocationResolutionPhase.unknown ||
        phase == LocationResolutionPhase.resolving) {
      return;
    }

    final nextResolution = _locationOriginService.resolveCached();
    final nextSettings = nextResolution.settings;
    final nextOrigin = _resolveCurrentEffectiveOrigin();
    final semanticOriginChanged =
        !(_currentQueryOriginSettings?.sameAs(nextSettings) ??
            nextSettings == null);
    if (!semanticOriginChanged) {
      return;
    }
    if (_sameCoordinate(_currentQuery.origin, nextOrigin)) {
      return;
    }

    _isReconcilingLocationOrigin = true;
    try {
      await loadPois(
        _currentQuery,
        loadingMessage: 'Atualizando pontos...',
      );
    } finally {
      _isReconcilingLocationOrigin = false;
    }
  }

  Future<bool> ensureMapReady() async {
    if (_isMapInteractionReady()) {
      return true;
    }
    try {
      await mapHandle.interactionStream.first.timeout(
        const Duration(milliseconds: 250),
      );
      _hasObservedMapEvent = true;
    } catch (_) {
      // map readiness can race against first frame; caller handles fallback
    }
    return _isMapInteractionReady();
  }

  Future<void> searchPois(String query) async {
    _searchInputDebounceTimer?.cancel();
    await _runSearchQuery(
      query,
      logTelemetry: true,
    );
  }

  void handleSearchInputChanged(String query) {
    _searchInputDebounceTimer?.cancel();
    final trimmed = query.trim();
    final currentTerm = searchTermStreamValue.value?.trim() ?? '';

    if (trimmed == currentTerm) {
      return;
    }

    _searchInputDebounceTimer = Timer(_searchInputDebounceDelay, () {
      if (trimmed.isEmpty) {
        unawaited(
          clearSearch(
            logTelemetry: false,
          ),
        );
        return;
      }
      unawaited(
        _runSearchQuery(
          query,
          logTelemetry: false,
        ),
      );
    });
  }

  Future<void> clearSearch({
    bool logTelemetry = true,
  }) async {
    _searchInputDebounceTimer?.cancel();
    final previousQueryLen =
        _currentQuery.searchTermValue?.value.trim().length ?? 0;
    clearSelectedPoi(preserveMarkerMemory: false);
    if (logTelemetry) {
      _logMapTelemetry(
        EventTrackerEvents.buttonClick,
        eventName: telemetryRepoString('map_search_cleared'),
        properties: {
          'previous_query_len': previousQueryLen,
          'filter_mode': filterModeStreamValue.value.name,
        },
      );
    }
    final query = _composeQuery(
      searchTerm: '',
      origin: _searchTrayOrigin,
    );
    await loadPois(
      query,
      announceLoadingMessage: false,
    );
  }

  Future<void> _runSearchQuery(
    String query, {
    required bool logTelemetry,
  }) async {
    final trimmed = query.trim();
    final nextQuery = _composeQuery(
      searchTerm: query,
      origin: _searchTrayOrigin,
    );
    clearSelectedPoi(preserveMarkerMemory: false);
    if (logTelemetry) {
      _logMapTelemetry(
        EventTrackerEvents.search,
        eventName: telemetryRepoString('map_search_submitted'),
        properties: {
          'query_len': trimmed.length,
          'filter_mode': filterModeStreamValue.value.name,
        },
      );
    }
    await loadPois(
      nextQuery,
      announceLoadingMessage: false,
    );
  }

  Future<void> loadPois(
    PoiQuery query, {
    String? loadingMessage,
    bool announceLoadingMessage = true,
  }) async {
    final requestSequence = ++_poiRequestSequence;
    final resolvedQuery = await _resolveRuntimeQuery(query);
    _currentQuery = resolvedQuery;
    searchTermStreamValue.addValue(resolvedQuery.searchTermValue?.value);
    final nextSearchText = resolvedQuery.searchTermValue?.value ?? '';
    if (searchTextController.text != nextSearchText) {
      searchTextController.text = nextSearchText;
    }

    _setMapStatus(MapStatus.fetching);
    _setMapMessage(
      announceLoadingMessage
          ? (loadingMessage ?? 'Carregando pontos...')
          : null,
    );
    _setLoadingState();

    try {
      await _poiRepository.refreshPoints(resolvedQuery);
      if (!_isLatestPoiRequest(requestSequence)) {
        return;
      }
      _setIdleState();
      _setMapStatus(MapStatus.ready);
      _setMapMessage(null);
    } catch (error) {
      if (!_isLatestPoiRequest(requestSequence)) {
        return;
      }
      const errorMessage = 'Nao foi possivel carregar os pontos de interesse.';
      _setErrorState(errorMessage);
      _setMapStatus(MapStatus.error);
      _setMapMessage(errorMessage);
      debugPrint('Failed to load POIs: $error');
    }
  }

  bool _isLatestPoiRequest(int requestSequence) {
    return requestSequence == _poiRequestSequence;
  }

  Future<PoiQuery> _resolveRuntimeQuery(PoiQuery query) async {
    final resolution = await _locationOriginService.resolveAndPersist(
      LocationOriginResolutionRequestFactory.create(
        forceTenantDefaultUnavailable: _forceTenantDefaultUnavailableEntry,
      ),
    );
    _currentQueryOriginSettings = resolution.settings;
    _refreshLocationFeedback(emitNotice: false);
    final origin =
        _searchTrayOrigin ?? resolution.effectiveCoordinate ?? query.origin;
    return PoiQuery(
      northEast: query.northEast,
      southWest: query.southWest,
      origin: origin,
      maxDistanceMetersValue: query.maxDistanceMetersValue,
      categoryKeyValues: query.categoryKeyValues,
      sourceValue: query.sourceValue,
      typeValues: query.typeValues,
      tagValues: query.tagValues,
      taxonomyTokenValues: query.taxonomyTokenValues,
      searchTermValue: query.searchTermValue,
    );
  }

  Future<void> _applyInitialPoiQuery({
    required String? initialPoiQuery,
    required String? initialPoiStackQuery,
    bool emitNotFoundMessage = true,
  }) async {
    final normalizedPoiQuery = _normalizePoiQuery(initialPoiQuery);
    if (normalizedPoiQuery == null) {
      return;
    }

    final normalizedStackQuery = _normalizeStackQuery(initialPoiStackQuery);

    var resolvedPoi = _resolvePoiFromQuery(normalizedPoiQuery);
    if (resolvedPoi == null && normalizedStackQuery != null) {
      resolvedPoi = await _resolvePoiFromStackQuery(
        normalizedPoiQuery: normalizedPoiQuery,
        normalizedStackQuery: normalizedStackQuery,
      );
    }
    resolvedPoi ??= await _resolvePoiFromLookupQuery(normalizedPoiQuery);

    if (resolvedPoi == null) {
      if (emitNotFoundMessage) {
        statusMessageStreamValue.addValue('POI do link não foi encontrado.');
      }
      return;
    }

    if (selectedPoiStreamValue.value?.id != resolvedPoi.id) {
      selectPoi(resolvedPoi);
    }
    _queueInitialPoiFocus(resolvedPoi);
  }

  String? _normalizePoiQuery(String? rawPoiQuery) {
    final normalized = rawPoiQuery?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  String? _normalizeStackQuery(String? rawStackQuery) {
    final normalized = rawStackQuery?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  CityPoiModel? _resolvePoiFromQuery(String normalizedPoiQuery) {
    final selectedPoi = selectedPoiStreamValue.value;
    if (selectedPoi != null &&
        _matchesPoiQuery(selectedPoi, normalizedPoiQuery)) {
      return selectedPoi;
    }

    final filteredPois =
        filteredPoisStreamValue.value ?? const <CityPoiModel>[];
    for (final poi in filteredPois) {
      if (_matchesPoiQuery(poi, normalizedPoiQuery)) {
        return poi;
      }
      for (final stackItem in poi.stackItems) {
        if (_matchesPoiQuery(stackItem, normalizedPoiQuery)) {
          return stackItem;
        }
      }
    }

    return null;
  }

  Future<CityPoiModel?> _resolvePoiFromStackQuery({
    required String normalizedPoiQuery,
    required String normalizedStackQuery,
  }) async {
    try {
      await _poiRepository.loadStackItems(
        stackKey: PoiStackKeyValue()..parse(normalizedStackQuery),
        query: _currentQuery,
      );
    } catch (error) {
      debugPrint(
          'Failed to load stack for poi query $normalizedStackQuery: $error');
      return null;
    }

    final stackItems =
        _poiRepository.stackItemsStreamValue.value ?? const <CityPoiModel>[];
    if (stackItems.isEmpty) {
      return null;
    }

    final enrichedItems = _attachStackContext(
      stackItems,
      stackKey: normalizedStackQuery,
      stackCount: stackItems.length,
    );

    for (final item in enrichedItems) {
      if (_matchesPoiQuery(item, normalizedPoiQuery)) {
        return item;
      }
    }

    return null;
  }

  bool _matchesPoiQuery(CityPoiModel poi, String normalizedPoiQuery) {
    final id = poi.id.trim().toLowerCase();
    if (id.isNotEmpty && id == normalizedPoiQuery) {
      return true;
    }
    final poiQueryKey = _buildPoiQueryKey(poi);
    if (poiQueryKey.isEmpty) {
      return false;
    }
    return poiQueryKey == normalizedPoiQuery;
  }

  String _buildPoiQueryKey(CityPoiModel poi) {
    final refType = poi.refType.trim().toLowerCase();
    final refId = poi.refId.trim().toLowerCase();
    if (refType.isNotEmpty && refId.isNotEmpty) {
      return '$refType:$refId';
    }
    return '';
  }

  Future<CityPoiModel?> _resolvePoiFromLookupQuery(
    String normalizedPoiQuery,
  ) async {
    final typedReference = _parseTypedPoiReference(normalizedPoiQuery);
    if (typedReference == null) {
      return null;
    }

    try {
      return await _poiRepository.fetchPoiByReference(
        refType: PoiReferenceTypeValue()..parse(typedReference.refType),
        refId: PoiReferenceIdValue()..parse(typedReference.refId),
      );
    } catch (error) {
      debugPrint('Failed to lookup poi ${typedReference.refType}:'
          '${typedReference.refId}: $error');
      return null;
    }
  }

  ({String refType, String refId})? _parseTypedPoiReference(
    String normalizedPoiQuery,
  ) {
    final segments = normalizedPoiQuery.split(':');
    if (segments.length != 2) {
      return null;
    }
    final refType = segments.first.trim().toLowerCase();
    final refId = segments.last.trim();
    if (refType.isEmpty || refId.isEmpty) {
      return null;
    }
    return (refType: refType, refId: refId);
  }

  void selectPoi(CityPoiModel? poi) {
    _poiRepository.selectPoi(poi);
    if (poi == null) {
      _finishPoiTimedEvent();
      return;
    }
    lastSelectedPoiMemoryStreamValue.addValue(
      MapSelectedPoiMemory.fromPoi(poi),
    );
    if (_activePoiId != null && _activePoiId != poi.id) {
      _finishPoiTimedEvent();
    }
    unawaited(_startPoiTimedEvent(poi));
  }

  void _queueInitialPoiFocus(CityPoiModel poi) {
    if (_initialPoiFocusApplied) {
      return;
    }
    _pendingInitialPoiFocus = poi;
    _tryApplyPendingInitialPoiFocus();
  }

  void _resetInitialPoiFocusState() {
    _pendingInitialPoiFocus = null;
    _initialPoiFocusApplied = false;
    _initialPoiFocusInProgress = false;
    _hasObservedMapEvent = false;
  }

  bool _isMapCameraReady() {
    return mapHandle.isReady;
  }

  bool _isMapInteractionReady() {
    return _hasObservedMapEvent || _isMapCameraReady();
  }

  void _tryApplyPendingInitialPoiFocus() {
    if (_initialPoiFocusApplied || _initialPoiFocusInProgress) {
      return;
    }
    final pendingPoi = _pendingInitialPoiFocus;
    final isReadyByEvent = _hasObservedMapEvent;
    final isReadyByCamera = _isMapCameraReady();
    if (pendingPoi == null || (!isReadyByEvent && !isReadyByCamera)) {
      return;
    }
    _initialPoiFocusInProgress = true;
    unawaited(() async {
      final didFocus = await _focusOnPoi(pendingPoi);
      if (didFocus) {
        _initialPoiFocusApplied = true;
        if (_pendingInitialPoiFocus?.id == pendingPoi.id) {
          _pendingInitialPoiFocus = null;
        }
      }
      _initialPoiFocusInProgress = false;
    }());
  }

  int _beginSelectedPoiLoading(CityPoiModel poi) {
    _selectedPoiHydrationSequence += 1;
    selectedPoiLoadingIdStreamValue.addValue(poi.id);
    hasSelectedPoiLoadingStreamValue.addValue(true);
    _poiRepository.clearSelection();
    clearLastSelectedPoiMemory();
    _finishPoiTimedEvent();
    return _selectedPoiHydrationSequence;
  }

  bool _isLatestSelectedPoiHydration(int sequence) {
    return sequence == _selectedPoiHydrationSequence;
  }

  Future<void> _selectPoiFromMarkerTap(
    CityPoiModel poi, {
    int? loadingSequence,
  }) async {
    final sequence = loadingSequence ?? _beginSelectedPoiLoading(poi);
    try {
      final hydratedPoi = await _hydratePoiForSelection(poi);
      if (!_isLatestSelectedPoiHydration(sequence)) {
        return;
      }
      final resolvedPoi = hydratedPoi ?? poi;
      selectedPoiLoadingIdStreamValue.addValue(null);
      hasSelectedPoiLoadingStreamValue.addValue(false);
      selectPoi(resolvedPoi);
      await _focusOnPoi(resolvedPoi);
    } catch (error) {
      if (!_isLatestSelectedPoiHydration(sequence)) {
        return;
      }
      debugPrint('Failed to hydrate selected poi ${poi.id}: $error');
      selectedPoiLoadingIdStreamValue.addValue(null);
      hasSelectedPoiLoadingStreamValue.addValue(false);
      selectPoi(poi);
      await _focusOnPoi(poi);
    }
  }

  Future<CityPoiModel?> _hydratePoiForSelection(CityPoiModel poi) async {
    await _poiRepository.ensurePoiHydrated(poi);
    return _resolveHydratedPoi(poi);
  }

  void ensureDeckPoiHydrated(CityPoiModel poi) {
    unawaited(_poiRepository.ensurePoiHydrated(poi));
  }

  CityPoiModel? _resolveHydratedPoi(CityPoiModel poi) {
    final profile = hydratedAccountProfileForPoi(poi);
    if (profile != null) {
      return _mergeAccountProfileIntoPoi(poi, profile);
    }
    final event = hydratedEventForPoi(poi);
    if (event != null) {
      return _mergeEventIntoPoi(poi, event);
    }
    final asset = hydratedStaticAssetForPoi(poi);
    if (asset != null) {
      return _mergeStaticAssetIntoPoi(poi, asset);
    }
    return null;
  }

  CityPoiModel _mergeAccountProfileIntoPoi(
    CityPoiModel poi,
    AccountProfileModel profile,
  ) {
    final normalizedAvatarUrl = profile.avatarUrl?.trim();
    final normalizedCoverUrl = profile.coverUrl?.trim();
    final avatarUrl = normalizedAvatarUrl == null || normalizedAvatarUrl.isEmpty
        ? null
        : normalizedAvatarUrl;
    final coverUrl = normalizedCoverUrl == null || normalizedCoverUrl.isEmpty
        ? null
        : normalizedCoverUrl;
    final markerImageUrl = avatarUrl ?? coverUrl;
    final mergedVisual = markerImageUrl == null
        ? poi.visual
        : CityPoiVisual.image(
            imageUriValue: _parseImageUriValue(markerImageUrl),
          );

    final mergedDescription = _isWeakPoiDescription(poi.description) &&
            !_isWeakPoiDescription(profile.bio ?? '')
        ? _parsePoiDescriptionValue(profile.bio!)
        : null;

    final mergedAddress = _isWeakPoiAddress(poi.address) &&
            !_isWeakPoiAddress(profile.locationAddress ?? '')
        ? _parsePoiAddressValue(profile.locationAddress!)
        : null;

    final mergedDistance =
        poi.distanceMeters == null && profile.distanceMeters != null
            ? _parseDistanceValue(profile.distanceMeters)
            : null;

    final mergedCoordinate =
        profile.locationLat != null && profile.locationLng != null
            ? CityCoordinate(
                latitudeValue: _parseLatitudeValue(profile.locationLat!),
                longitudeValue: _parseLongitudeValue(profile.locationLng!),
              )
            : poi.coordinate;
    final normalizedProfileType = profile.profileType.trim();
    final categoryLabelValue = normalizedProfileType.isEmpty
        ? null
        : _parseTypeLabelValue(normalizedProfileType);
    final canonicalProfilePath = '/parceiro/${profile.slug}';

    return poi.copyWith(
      descriptionValue: mergedDescription,
      addressValue: mergedAddress,
      distanceMetersValue: mergedDistance,
      categoryLabelValue: categoryLabelValue,
      coverImageUriValue:
          coverUrl == null ? null : _parseImageUriValue(coverUrl),
      coordinate: mergedCoordinate,
      visual: mergedVisual,
      refSlugValue:
          poi.refSlug == null ? _parseReferenceSlugValue(profile.slug) : null,
      refPathValue: poi.refPath?.trim() == canonicalProfilePath
          ? null
          : _parseReferencePathValue(canonicalProfilePath),
    );
  }

  CityPoiModel _mergeEventIntoPoi(CityPoiModel poi, EventModel event) {
    final coverImageUrl = _resolveEventCoverImageUrl(event);
    final markerImageUrl = _resolveEventMarkerImageUrl(event, coverImageUrl);
    final descriptionExcerpt = _resolveEventDescriptionExcerpt(event);
    final linkedProfiles = _resolveEventLinkedProfiles(event);
    final mergedVisual = markerImageUrl == null
        ? poi.visual
        : CityPoiVisual.image(
            imageUriValue: _parseImageUriValue(markerImageUrl),
          );
    final canonicalEventPath =
        event.slug.trim().isEmpty ? null : '/agenda/evento/${event.slug}';

    return poi.copyWith(
      descriptionValue: descriptionExcerpt == null
          ? null
          : _parsePoiDescriptionValue(descriptionExcerpt),
      coverImageUriValue:
          coverImageUrl == null ? null : _parseImageUriValue(coverImageUrl),
      linkedProfiles: linkedProfiles,
      visual: mergedVisual,
      refSlugValue: poi.refSlug == null && event.slug.trim().isNotEmpty
          ? _parseReferenceSlugValue(event.slug)
          : null,
      refPathValue: canonicalEventPath == null ||
              poi.refPath?.trim() == canonicalEventPath
          ? null
          : _parseReferencePathValue(canonicalEventPath),
    );
  }

  CityPoiModel _mergeStaticAssetIntoPoi(
    CityPoiModel poi,
    PublicStaticAssetModel asset,
  ) {
    final coverImageUrl = _normalizeExternalImageUrl(asset.coverUrl);
    final description = _resolveStaticAssetDescription(asset);
    final canonicalPath =
        asset.slug.trim().isEmpty ? null : '/static/${asset.slug}';

    return poi.copyWith(
      descriptionValue:
          description == null ? null : _parsePoiDescriptionValue(description),
      categoryLabelValue: asset.profileType.trim().isEmpty
          ? null
          : _parseTypeLabelValue(asset.profileType),
      coverImageUriValue:
          coverImageUrl == null ? null : _parseImageUriValue(coverImageUrl),
      visual: coverImageUrl == null
          ? poi.visual
          : CityPoiVisual.image(
              imageUriValue: _parseImageUriValue(coverImageUrl),
            ),
      refSlugValue: poi.refSlug == null && asset.slug.trim().isNotEmpty
          ? _parseReferenceSlugValue(asset.slug)
          : null,
      refPathValue:
          canonicalPath == null || poi.refPath?.trim() == canonicalPath
              ? null
              : _parseReferencePathValue(canonicalPath),
    );
  }

  String? _resolveEventCoverImageUrl(EventModel event) {
    final eventImageUri = VenueEventResume.resolvePreferredImageUri(event);
    final canonicalEventImageUrl = _normalizeExternalImageUrl(
      eventImageUri.toString(),
    );
    if (canonicalEventImageUrl != null) {
      return canonicalEventImageUrl;
    }

    final linkedArtistAvatar = _normalizeExternalImageUrl(
      event.primaryLinkedArtist?.avatarUrl,
    );
    if (linkedArtistAvatar != null) {
      return linkedArtistAvatar;
    }

    return _normalizeExternalImageUrl(event.primaryLinkedArtist?.coverUrl);
  }

  String? _resolveEventMarkerImageUrl(
    EventModel event,
    String? coverImageUrl,
  ) {
    final linkedArtistAvatar = _normalizeExternalImageUrl(
      event.primaryLinkedArtist?.avatarUrl,
    );
    if (linkedArtistAvatar != null) {
      return linkedArtistAvatar;
    }

    final leadingArtistAvatar = event.artists
        .map((artist) =>
            _normalizeExternalImageUrl(artist.avatarUri?.toString()))
        .firstWhere((candidate) => candidate != null, orElse: () => null);
    return leadingArtistAvatar ?? coverImageUrl;
  }

  String? _resolveEventDescriptionExcerpt(EventModel event) {
    final rawContent = event.content.value?.trim() ?? '';
    if (rawContent.isEmpty) {
      return null;
    }
    final excerpt = rawContent
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (excerpt.length < 3) {
      return null;
    }
    return excerpt;
  }

  String? _resolveStaticAssetDescription(PublicStaticAssetModel asset) {
    final rawContent = asset.resolvedDescription?.trim() ?? '';
    if (rawContent.isEmpty) {
      return null;
    }
    final excerpt = rawContent
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (excerpt.length < 3) {
      return null;
    }
    return excerpt;
  }

  List<CityPoiLinkedProfile> _resolveEventLinkedProfiles(EventModel event) {
    final venueId = event.venue?.id.trim();
    final seen = <String>{};
    final linkedProfiles = <CityPoiLinkedProfile>[];
    for (final profile in event.linkedAccountProfiles) {
      final id = profile.id.trim();
      if (id.isEmpty) {
        continue;
      }
      if (venueId != null && venueId.isNotEmpty && id == venueId) {
        continue;
      }
      if (!seen.add(id)) {
        continue;
      }
      final displayName = profile.displayName.trim();
      if (displayName.isEmpty) {
        continue;
      }
      linkedProfiles.add(
        CityPoiLinkedProfile(
          idValue: _parseReferenceIdValue(id),
          displayNameValue: _parsePoiNameValue(displayName),
          avatarImageUriValue: (() {
            final avatarImageUrl =
                _normalizeExternalImageUrl(profile.avatarUrl);
            if (avatarImageUrl == null) {
              return null;
            }
            return _parseImageUriValue(avatarImageUrl);
          })(),
        ),
      );
    }
    return List<CityPoiLinkedProfile>.unmodifiable(linkedProfiles);
  }

  String? _normalizeExternalImageUrl(String? raw) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    if (normalized.toLowerCase().startsWith('asset://')) {
      return null;
    }
    return normalized;
  }

  bool _isWeakPoiDescription(String raw) {
    final normalized = raw.trim().toLowerCase();
    return normalized.isEmpty || normalized.length < 12;
  }

  bool _isWeakPoiAddress(String raw) {
    final normalized = raw.trim().toLowerCase();
    return normalized.isEmpty || normalized == 'mapa' || normalized.length < 4;
  }

  PoiFilterImageUriValue _parseImageUriValue(String raw) {
    final value = PoiFilterImageUriValue();
    value.parse(raw.trim());
    return value;
  }

  PoiReferenceIdValue _parseReferenceIdValue(String raw) {
    final value = PoiReferenceIdValue();
    value.parse(raw.trim());
    return value;
  }

  CityPoiNameValue _parsePoiNameValue(String raw) {
    final value = CityPoiNameValue();
    value.parse(raw.trim());
    return value;
  }

  PoiReferenceSlugValue _parseReferenceSlugValue(String raw) {
    final value = PoiReferenceSlugValue();
    value.parse(raw.trim());
    return value;
  }

  PoiReferencePathValue _parseReferencePathValue(String raw) {
    final value = PoiReferencePathValue();
    value.parse(raw.trim());
    return value;
  }

  PoiTypeLabelValue _parseTypeLabelValue(String raw) {
    final value = PoiTypeLabelValue();
    value.parse(raw.trim());
    return value;
  }

  CityPoiDescriptionValue _parsePoiDescriptionValue(String raw) {
    final value = CityPoiDescriptionValue();
    value.parse(raw.trim());
    return value;
  }

  CityPoiAddressValue _parsePoiAddressValue(String raw) {
    final value = CityPoiAddressValue();
    value.parse(raw.trim());
    return value;
  }

  LatitudeValue _parseLatitudeValue(double raw) {
    final value = LatitudeValue();
    value.parse(raw.toString());
    return value;
  }

  LongitudeValue _parseLongitudeValue(double raw) {
    final value = LongitudeValue();
    value.parse(raw.toString());
    return value;
  }

  Future<void> handleMarkerTap(CityPoiModel poi) async {
    if (_filterInteractionLocked || _markerTapSuppressedAfterFilterReload) {
      return;
    }
    final preserveFilterContext =
        mapTrayModeStreamValue.value == MapTrayMode.filterResults;
    if (!preserveFilterContext &&
        mapTrayModeStreamValue.value != MapTrayMode.discovery) {
      mapTrayModeStreamValue.addValue(MapTrayMode.discovery);
    }
    clearClusterPicker();
    if (selectedPoiLoadingIdStreamValue.value == poi.id) {
      return;
    }
    _syncDeckIndexToPoi(poi);
    final hasStackCandidates = poi.stackCount > 1 && poi.stackKey.isNotEmpty;
    if (!hasStackCandidates) {
      final loadingSequence = _beginSelectedPoiLoading(poi);
      await _focusOnPoi(poi);
      await _selectPoiFromMarkerTap(
        poi,
        loadingSequence: loadingSequence,
      );
      return;
    }

    final loadingSequence = _beginSelectedPoiLoading(poi);
    await _focusOnPoi(
      poi,
      verticalViewportAnchor: _filteredPreviewViewportAnchor,
    );
    try {
      await _poiRepository.loadStackItems(
        stackKey: PoiStackKeyValue()..parse(poi.stackKey),
        query: _currentQuery,
      );
      if (!_isLatestSelectedPoiHydration(loadingSequence)) {
        return;
      }
      final stackItems =
          _poiRepository.stackItemsStreamValue.value ?? const <CityPoiModel>[];
      if (stackItems.isEmpty) {
        await _selectPoiFromMarkerTap(
          poi,
          loadingSequence: loadingSequence,
        );
        return;
      }
      final enrichedItems = _attachStackContext(
        stackItems,
        stackKey: poi.stackKey,
        stackCount: poi.stackCount,
      );
      if (!_isLatestSelectedPoiHydration(loadingSequence)) {
        return;
      }
      selectedPoiLoadingIdStreamValue.addValue(null);
      hasSelectedPoiLoadingStreamValue.addValue(false);
      showClusterPicker(
        enrichedItems,
        anchorCoordinate: poi.coordinate,
      );
    } catch (error) {
      debugPrint('Failed to load stack ${poi.stackKey}: $error');
      if (!_isLatestSelectedPoiHydration(loadingSequence)) {
        return;
      }
      await _selectPoiFromMarkerTap(
        poi,
        loadingSequence: loadingSequence,
      );
    }
  }

  Future<void> handleDeckPoiSelection(CityPoiModel poi) async {
    clearClusterPicker();
    if (selectedPoiLoadingIdStreamValue.value == poi.id) {
      return;
    }
    _syncDeckIndexToPoi(poi);
    if (selectedPoiStreamValue.value?.id == poi.id) {
      await _focusOnPoi(poi);
      return;
    }
    final loadingSequence = _beginSelectedPoiLoading(poi);
    await _focusOnPoi(poi);
    await _selectPoiFromMarkerTap(
      poi,
      loadingSequence: loadingSequence,
    );
  }

  void showClusterPicker(
    List<CityPoiModel> pois, {
    required CityCoordinate anchorCoordinate,
  }) {
    final normalized = List<CityPoiModel>.unmodifiable(
      pois.where((poi) => poi.id.trim().isNotEmpty),
    );
    if (normalized.isEmpty) {
      clearClusterPicker();
      return;
    }
    _selectedPoiHydrationSequence += 1;
    selectedPoiLoadingIdStreamValue.addValue(null);
    hasSelectedPoiLoadingStreamValue.addValue(false);
    _poiRepository.clearSelection();
    clearLastSelectedPoiMemory();
    _finishPoiTimedEvent();
    _poiRepository.setStackItems(normalized);
    clusterPickerAnchorCoordinateStreamValue.addValue(anchorCoordinate);
    hasClusterPickerStreamValue.addValue(true);
  }

  void clearClusterPicker() {
    if (clusterPickerPoisStreamValue.value != null) {
      _poiRepository.clearStackItems();
    }
    if (clusterPickerAnchorCoordinateStreamValue.value != null) {
      clusterPickerAnchorCoordinateStreamValue.addValue(null);
    }
    if (hasClusterPickerStreamValue.value) {
      hasClusterPickerStreamValue.addValue(false);
    }
  }

  Future<void> handleClusterPickerPoiSelection(CityPoiModel poi) async {
    clearClusterPicker();
    await handleDeckPoiSelection(poi);
  }

  List<CityPoiModel> _attachStackContext(
    List<CityPoiModel> items, {
    required String stackKey,
    required int stackCount,
  }) {
    final normalizedStackKey =
        stackKey.trim().isNotEmpty ? stackKey.trim() : items.first.stackKey;
    final normalizedCount = stackCount > 0 ? stackCount : items.length;
    final seeded = items
        .map(
          (item) => item.copyWith(
            stackKeyValue: _parseStackKeyValue(normalizedStackKey),
            stackCountValue: _parseStackCountValue(normalizedCount),
          ),
        )
        .toList(growable: false);
    final stackItems = CityPoiStackItems();
    for (final item in seeded) {
      stackItems.add(item);
    }
    return seeded
        .map(
          (item) => item.copyWith(stackItems: stackItems),
        )
        .toList(growable: false);
  }

  PoiStackKeyValue _parseStackKeyValue(String raw) {
    final value = PoiStackKeyValue();
    value.parse(raw.trim());
    return value;
  }

  PoiStackCountValue _parseStackCountValue(int raw) {
    final value = PoiStackCountValue();
    value.parse(raw.toString());
    return value;
  }

  void clearSelectedPoi({
    bool preserveMarkerMemory = true,
  }) {
    _selectedPoiHydrationSequence += 1;
    selectedPoiLoadingIdStreamValue.addValue(null);
    hasSelectedPoiLoadingStreamValue.addValue(false);
    _poiRepository.clearSelection();
    clearClusterPicker();
    if (!preserveMarkerMemory) {
      clearLastSelectedPoiMemory();
    }
    _finishPoiTimedEvent();
  }

  void clearLastSelectedPoiMemory() {
    if (lastSelectedPoiMemoryStreamValue.value != null) {
      lastSelectedPoiMemoryStreamValue.addValue(null);
    }
  }

  void showDiscoveryTray() {
    _searchTrayOrigin = null;
    if (mapTrayModeStreamValue.value != MapTrayMode.discovery) {
      mapTrayModeStreamValue.addValue(MapTrayMode.discovery);
    }
    clearSelectedPoi();
  }

  void showFiltersTray() {
    _searchTrayOrigin = null;
    if (mapTrayModeStreamValue.value != MapTrayMode.filters) {
      mapTrayModeStreamValue.addValue(MapTrayMode.filters);
    }
    clearSelectedPoi();
    unawaited(loadFilters());
  }

  void showFilterResultsTray() {
    _searchTrayOrigin = null;
    if (mapTrayModeStreamValue.value != MapTrayMode.filterResults) {
      mapTrayModeStreamValue.addValue(MapTrayMode.filterResults);
    }
    clearSelectedPoi();
    unawaited(loadFilters());
  }

  void showSearchTray() {
    if (mapTrayModeStreamValue.value != MapTrayMode.search) {
      mapTrayModeStreamValue.addValue(MapTrayMode.search);
    }
    clearSelectedPoi();
    _searchTrayOrigin = mapHandle.currentCenter ??
        _resolveCurrentEffectiveOrigin() ??
        defaultCenter;
    unawaited(
      loadPois(
        _composeQuery(
          searchTerm: searchTextController.text,
          origin: _searchTrayOrigin,
        ),
        announceLoadingMessage: false,
      ),
    );
  }

  void applyFilterMode(PoiFilterMode mode) {
    if (_filterInteractionLocked) {
      return;
    }
    final current = filterModeStreamValue.value;
    if (current == mode) {
      showFilterResultsTray();
      return;
    }
    if (mode == PoiFilterMode.none) {
      clearFilters();
      return;
    }

    final categoryKeys = _categoryKeysForMode(mode);
    if (categoryKeys.isEmpty) {
      clearFilters();
      return;
    }

    _activeCategoryKeys = categoryKeys;
    _activeTaxonomyTokens = <String>{};
    _activeTags = <String>{};
    _activeSource = null;
    _activeTypes = <String>{};
    _activeCatalogFilterKey = null;
    _publishActiveFilters();
    activeFilterLabelStreamValue.addValue(_labelForMode(mode));
    pendingFilterLabelStreamValue.addValue(null);
    _poiRepository.applyFilterMode(mode);
    clearSelectedPoi(preserveMarkerMemory: false);
    _logMapTelemetry(
      EventTrackerEvents.selectItem,
      eventName: telemetryRepoString('map_filter_applied'),
      properties: {
        'filter_mode': mode.name,
      },
    );
    _beginFilterReloadInteraction();
    unawaited(
      _runFilterReload(
        _composeQuery(
          categoryKeys: _activeCategoryKeys,
          taxonomy: const <String>{},
          tags: const <String>{},
          source: '',
          types: const <String>{},
        ),
        appliedCatalogFilterKeyOnSuccess: null,
        focusLeadingResultOnSuccess: true,
      ),
    );
  }

  void clearFilters() {
    if (_filterInteractionLocked) {
      return;
    }
    final wasFiltered = filterModeStreamValue.value != PoiFilterMode.none ||
        _activeCategoryKeys.isNotEmpty ||
        _activeTaxonomyTokens.isNotEmpty ||
        _activeTags.isNotEmpty ||
        (_activeSource?.trim().isNotEmpty ?? false) ||
        _activeTypes.isNotEmpty;
    _activeCategoryKeys = <String>{};
    _activeTaxonomyTokens = <String>{};
    _activeTags = <String>{};
    _activeSource = null;
    _activeTypes = <String>{};
    _activeCatalogFilterKey = null;
    _publishActiveFilters();
    final previousFilterLabel = activeFilterLabelStreamValue.value?.trim();
    pendingFilterLabelStreamValue.addValue(
      previousFilterLabel == null || previousFilterLabel.isEmpty
          ? null
          : previousFilterLabel,
    );
    activeFilterLabelStreamValue.addValue(null);
    if (mapTrayModeStreamValue.value == MapTrayMode.filterResults) {
      mapTrayModeStreamValue.addValue(MapTrayMode.discovery);
    }
    _poiRepository.clearFilters();
    clearSelectedPoi(preserveMarkerMemory: false);
    if (!wasFiltered) {
      return;
    }
    _beginFilterReloadInteraction();
    unawaited(
      _runFilterReload(
        _composeQuery(
          categoryKeys: const <String>{},
          taxonomy: const <String>{},
          tags: const <String>{},
          source: '',
          types: const <String>{},
        ),
        appliedCatalogFilterKeyOnSuccess: null,
        focusLeadingResultOnSuccess: false,
      ),
    );
    _logMapTelemetry(
      EventTrackerEvents.buttonClick,
      eventName: telemetryRepoString('map_filter_cleared'),
    );
  }

  void toggleCatalogCategoryFilter(PoiFilterCategory category) {
    if (_filterInteractionLocked) {
      return;
    }
    final categoryKeys = _categoryKeysForCatalogFilter(category);
    if (categoryKeys.isEmpty) {
      final source = _sourceForCatalogFilter(category);
      final types = _typesForCatalogFilter(category);
      final taxonomyTokens = _taxonomyTokensForCatalogFilter(category);
      final tags = _tagsForCatalogFilter(category);
      if (source == null &&
          types.isEmpty &&
          taxonomyTokens.isEmpty &&
          tags.isEmpty) {
        return;
      }
    }
    final source = _sourceForCatalogFilter(category);
    final types = _typesForCatalogFilter(category);
    final taxonomyTokens = _taxonomyTokensForCatalogFilter(category);
    final tags = _tagsForCatalogFilter(category);

    if (_isCatalogFilterActive(
      categoryKeys: categoryKeys,
      source: source,
      types: types,
      taxonomyTokens: taxonomyTokens,
      tags: tags,
    )) {
      showFilterResultsTray();
      return;
    }

    _activeCategoryKeys = categoryKeys;
    _activeSource = source;
    _activeTypes = types;
    _activeTaxonomyTokens = taxonomyTokens;
    _activeTags = tags;
    _activeCatalogFilterKey = category.key.trim().toLowerCase();
    _publishActiveFilters();
    activeFilterLabelStreamValue.addValue(category.label);
    pendingFilterLabelStreamValue.addValue(null);
    _poiRepository.applyFilterMode(PoiFilterMode.server);
    clearSelectedPoi(preserveMarkerMemory: false);
    if (mapTrayModeStreamValue.value != MapTrayMode.filterResults) {
      mapTrayModeStreamValue.addValue(MapTrayMode.filterResults);
    }
    _logMapTelemetry(
      EventTrackerEvents.selectItem,
      eventName: telemetryRepoString('map_catalog_filter_applied'),
      properties: {
        'category_keys': categoryKeys.toList(growable: false),
        if (source != null) 'source': source,
        'types': types.toList(growable: false),
        'taxonomy': taxonomyTokens.toList(growable: false),
        'tags': tags.toList(growable: false),
      },
    );
    _beginFilterReloadInteraction();
    unawaited(
      _runFilterReload(
        _composeQuery(
          categoryKeys: _activeCategoryKeys,
          source: _activeSource ?? '',
          types: _activeTypes,
          taxonomy: _activeTaxonomyTokens,
          tags: _activeTags,
        ),
        appliedCatalogFilterKeyOnSuccess: _activeCatalogFilterKey,
        focusLeadingResultOnSuccess: true,
      ),
    );
  }

  Future<void> _runFilterReload(
    PoiQuery query, {
    required String? appliedCatalogFilterKeyOnSuccess,
    required bool focusLeadingResultOnSuccess,
  }) async {
    try {
      await loadPois(
        query,
        announceLoadingMessage: false,
      );
      _appliedCatalogFilterKey = appliedCatalogFilterKeyOnSuccess;
      appliedCatalogFilterKeyStreamValue.addValue(_appliedCatalogFilterKey);
      if (focusLeadingResultOnSuccess) {
        await _focusLeadingFilteredResult();
      }
    } finally {
      _armPostFilterMarkerTapSuppression();
      _filterInteractionLocked = false;
      filterInteractionLockedStreamValue.addValue(false);
      pendingFilterLabelStreamValue.addValue(null);
    }
  }

  void _beginFilterReloadInteraction() {
    if (_filterInteractionLocked) {
      return;
    }
    _filterInteractionLocked = true;
    filterInteractionLockedStreamValue.addValue(true);
    mapInteractionGuardActiveStreamValue.addValue(true);
  }

  void _armPostFilterMarkerTapSuppression() {
    _postFilterMarkerTapSuppressionTimer?.cancel();
    _markerTapSuppressedAfterFilterReload = true;
    mapInteractionGuardActiveStreamValue.addValue(true);
    _postFilterMarkerTapSuppressionTimer = Timer(
      _postFilterMarkerTapSuppression,
      () {
        _markerTapSuppressedAfterFilterReload = false;
        mapInteractionGuardActiveStreamValue.addValue(false);
      },
    );
  }

  Future<void> _focusLeadingFilteredResult() async {
    if (selectedPoiStreamValue.value != null) {
      clearSelectedPoi(preserveMarkerMemory: false);
    }
    final pois = orderedFilterResultPois(
      filteredPoisStreamValue.value ?? const <CityPoiModel>[],
    );
    if (pois.isEmpty) {
      return;
    }
    _syncDeckIndexToPoi(pois.first);
    await _focusOnPoi(
      pois.first,
      zoom: mapHandle.currentZoom,
      verticalViewportAnchor: _filteredPreviewViewportAnchor,
    );
  }

  List<CityPoiModel> orderedPoisByDistance(List<CityPoiModel> pois) {
    final ordered = List<CityPoiModel>.from(pois);
    ordered.sort((left, right) {
      final leftDistance = left.distanceMeters ?? double.infinity;
      final rightDistance = right.distanceMeters ?? double.infinity;
      final byDistance = leftDistance.compareTo(rightDistance);
      if (byDistance != 0) {
        return byDistance;
      }
      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });
    return List<CityPoiModel>.unmodifiable(ordered);
  }

  List<CityPoiModel> orderedFilterResultPois(List<CityPoiModel> pois) {
    if (!_isEventFilterContext) {
      return orderedPoisByDistance(pois);
    }

    final ordered = List<CityPoiModel>.from(pois);
    final referenceTime = DateTime.now();
    ordered.sort((left, right) {
      final leftState = _eventFilterOrderStateForPoi(
        left,
        referenceTime: referenceTime,
      );
      final rightState = _eventFilterOrderStateForPoi(
        right,
        referenceTime: referenceTime,
      );
      final byState = leftState.index.compareTo(rightState.index);
      if (byState != 0) {
        return byState;
      }

      final leftStart = _eventStartTimeForPoi(left);
      final rightStart = _eventStartTimeForPoi(right);
      final byStart = leftState == _EventFilterOrderState.past
          ? _compareNullableDateTimes(rightStart, leftStart)
          : _compareNullableDateTimes(leftStart, rightStart);
      if (byStart != 0) {
        return byStart;
      }

      final leftDistance = left.distanceMeters ?? double.infinity;
      final rightDistance = right.distanceMeters ?? double.infinity;
      final byDistance = leftDistance.compareTo(rightDistance);
      if (byDistance != 0) {
        return byDistance;
      }

      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });
    return List<CityPoiModel>.unmodifiable(ordered);
  }

  bool get isEventFilterContext => _isEventFilterContext;

  List<CityPoiModel> deckPoisForSelectedPoi(CityPoiModel selectedPoi) {
    if (mapTrayModeStreamValue.value != MapTrayMode.filterResults) {
      return <CityPoiModel>[selectedPoi];
    }

    final ordered = orderedFilterResultPois(
      filteredPoisStreamValue.value ?? const <CityPoiModel>[],
    );
    final selectedIndex = ordered.indexWhere((poi) => poi.id == selectedPoi.id);
    if (selectedIndex == -1) {
      return <CityPoiModel>[selectedPoi];
    }

    return List<CityPoiModel>.unmodifiable(
      ordered.map((poi) {
        if (poi.id == selectedPoi.id) {
          return selectedPoi;
        }
        return _resolveHydratedPoi(poi) ?? poi;
      }),
    );
  }

  int deckIndexForSelectedPoi(
    CityPoiModel selectedPoi,
    List<CityPoiModel> deckPois,
  ) {
    final resolvedIndex =
        deckPois.indexWhere((poi) => poi.id == selectedPoi.id);
    return resolvedIndex == -1 ? 0 : resolvedIndex;
  }

  Future<void> handleFilteredDeckPageChanged(int index) async {
    setPoiDeckIndex(index);
    final selectedPoi = selectedPoiStreamValue.value;
    if (selectedPoi == null) {
      return;
    }
    final deckPois = deckPoisForSelectedPoi(selectedPoi);
    if (deckPois.isEmpty || index < 0 || index >= deckPois.length) {
      return;
    }
    final targetPoi = deckPois[index];
    if (selectedPoiStreamValue.value?.id != targetPoi.id) {
      selectPoi(targetPoi);
    }
    await _focusOnPoi(targetPoi);
  }

  void _syncDeckIndexToPoi(CityPoiModel poi) {
    final orderedPois = orderedFilterResultPois(
      filteredPoisStreamValue.value ?? const <CityPoiModel>[],
    );
    final index = orderedPois.indexWhere((entry) => entry.id == poi.id);
    if (index == -1) {
      resetPoiDeckIndex();
      return;
    }
    setPoiDeckIndex(index);
  }

  bool get _isEventFilterContext {
    if (filterModeStreamValue.value == PoiFilterMode.events) {
      return true;
    }

    if (_isEventFilterKey(_normalizeSource(_activeSource))) {
      return true;
    }

    final activeCategoryKeys = activeCategoryKeysStreamValue.value;
    if (_activeCategoryKeys.any(_isEventFilterKey) ||
        activeCategoryKeys.any(_isEventFilterKey)) {
      return true;
    }

    final activeCatalogFilterKey =
        activeCatalogFilterKeyStreamValue.value?.trim().toLowerCase();
    if (_isEventFilterKey(activeCatalogFilterKey)) {
      return true;
    }

    final appliedCatalogFilterKey =
        appliedCatalogFilterKeyStreamValue.value?.trim().toLowerCase();
    return _isEventFilterKey(appliedCatalogFilterKey);
  }

  bool _isEventFilterKey(String? value) {
    return value == 'event' || value == 'events';
  }

  DateTime? _eventStartTimeForPoi(CityPoiModel poi) {
    final timeStart = poi.timeStart;
    if (timeStart != null) {
      return timeStart;
    }

    final hydratedStart = hydratedEventForPoi(poi)?.dateTimeStart.value;
    return hydratedStart;
  }

  DateTime? _eventEndTimeForPoi(CityPoiModel poi) {
    final timeEnd = poi.timeEnd;
    if (timeEnd != null) {
      return timeEnd;
    }

    final hydratedEnd = hydratedEventForPoi(poi)?.dateTimeEnd?.value;
    return hydratedEnd;
  }

  _EventFilterOrderState _eventFilterOrderStateForPoi(
    CityPoiModel poi, {
    required DateTime referenceTime,
  }) {
    if (poi.isHappeningNow) {
      return _EventFilterOrderState.now;
    }

    final start = _eventStartTimeForPoi(poi);
    final end = _eventEndTimeForPoi(poi);

    if (start == null) {
      return _EventFilterOrderState.unknown;
    }

    final localStart = TimezoneConverter.utcToLocal(start);
    final localEnd = end == null ? null : TimezoneConverter.utcToLocal(end);

    if (localEnd != null) {
      if (referenceTime.isBefore(localStart)) {
        return _EventFilterOrderState.upcoming;
      }
      if (referenceTime.isAfter(localEnd)) {
        return _EventFilterOrderState.past;
      }
      return _EventFilterOrderState.now;
    }

    if (!referenceTime.isBefore(localStart)) {
      return _EventFilterOrderState.past;
    }

    return _EventFilterOrderState.upcoming;
  }

  int _compareNullableDateTimes(DateTime? left, DateTime? right) {
    if (left == null && right == null) {
      return 0;
    }
    if (left == null) {
      return 1;
    }
    if (right == null) {
      return -1;
    }
    return left.compareTo(right);
  }

  bool isCategoryFilterActive(PoiFilterCategory category) {
    final categoryKeys = _categoryKeysForCatalogFilter(category);
    final source = _sourceForCatalogFilter(category);
    final types = _typesForCatalogFilter(category);
    final taxonomyTokens = _taxonomyTokensForCatalogFilter(category);
    final tags = _tagsForCatalogFilter(category);
    if (categoryKeys.isEmpty &&
        source == null &&
        types.isEmpty &&
        taxonomyTokens.isEmpty &&
        tags.isEmpty) {
      return false;
    }
    return _isCatalogFilterActive(
      categoryKeys: categoryKeys,
      source: source,
      types: types,
      taxonomyTokens: taxonomyTokens,
      tags: tags,
    );
  }

  List<PoiFilterCategory> visibleCatalogCategories(PoiFilterOptions? options) {
    final categories = options?.sortedCategories ?? const <PoiFilterCategory>[];
    if (categories.isEmpty) {
      return const <PoiFilterCategory>[];
    }

    final configuredKeys = _appData.mapFilterCatalogKeys.toList();
    if (configuredKeys.isEmpty) {
      return List<PoiFilterCategory>.unmodifiable(categories);
    }

    final ordered = <PoiFilterCategory>[];
    final seenKeys = <String>{};

    for (final configuredKey in configuredKeys) {
      final normalizedConfiguredKey = configuredKey.trim().toLowerCase();
      if (normalizedConfiguredKey.isEmpty) {
        continue;
      }
      for (final category in categories) {
        final normalizedCategoryKey = category.key.trim().toLowerCase();
        if (normalizedCategoryKey != normalizedConfiguredKey ||
            !seenKeys.add(normalizedCategoryKey)) {
          continue;
        }
        ordered.add(category);
      }
    }

    for (final category in categories) {
      final normalizedCategoryKey = category.key.trim().toLowerCase();
      if (!seenKeys.add(normalizedCategoryKey)) {
        continue;
      }
      ordered.add(category);
    }

    return List<PoiFilterCategory>.unmodifiable(ordered);
  }

  void logDirectionsOpened(CityPoiModel poi) {
    _logMapTelemetry(
      EventTrackerEvents.viewContent,
      eventName: telemetryRepoString('map_directions_opened'),
      properties: {
        'source': 'poi',
        'poi_id': poi.id,
      },
    );
  }

  String buildPoiQueryKey(CityPoiModel poi) {
    final queryKey = _buildPoiQueryKey(poi);
    if (queryKey.isNotEmpty) {
      return queryKey;
    }
    return poi.id.trim().toLowerCase();
  }

  void logRideShareClicked({
    required RideShareProvider provider,
    String? poiId,
  }) {
    _logMapTelemetry(
      EventTrackerEvents.buttonClick,
      eventName: telemetryRepoString('map_ride_share_clicked'),
      properties: {
        'provider': provider.name,
        if (poiId != null) 'poi_id': poiId,
      },
    );
  }

  Future<void> focusOnPoi(
    CityPoiModel poi, {
    double? zoom,
    double verticalViewportAnchor = _selectedPoiViewportAnchor,
  }) async {
    await _focusOnPoi(
      poi,
      zoom: zoom,
      verticalViewportAnchor: verticalViewportAnchor,
    );
  }

  Future<bool> _focusOnPoi(
    CityPoiModel poi, {
    double? zoom,
    double verticalViewportAnchor = _selectedPoiViewportAnchor,
  }) async {
    final isMapReady = await ensureMapReady();
    if (!isMapReady) {
      return false;
    }
    final coordinate = poi.coordinate;
    final targetZoom = zoom ?? 16;
    final didMove = mapHandle.moveToAnchored(
      coordinate,
      zoom: _clampZoom(targetZoom.toDouble()),
      verticalViewportAnchor: verticalViewportAnchor,
    );
    if (!didMove) {
      debugPrint('Failed to focus on poi ${poi.id}: map handle rejected move');
    }
    return didMove;
  }

  PoiQuery _composeQuery({
    CityCoordinate? northEast,
    CityCoordinate? southWest,
    CityCoordinate? origin,
    double? maxDistanceMeters,
    Iterable<String>? categoryKeys,
    String? source,
    Iterable<String>? types,
    Iterable<String>? tags,
    Iterable<String>? taxonomy,
    String? searchTerm,
  }) {
    final resolvedSourceValue = source == null
        ? _currentQuery.sourceValue
        : _parseFilterSourceValue(source);
    final resolvedSearchTermValue = searchTerm == null
        ? _currentQuery.searchTermValue
        : _parseSearchTermValue(searchTerm);

    return PoiQuery.compose(
      currentQuery: _currentQuery,
      northEast: northEast,
      southWest: southWest,
      origin: origin,
      maxDistanceMetersValue: _parseDistanceValue(maxDistanceMeters),
      categoryKeyValues: _parseFilterKeyValues(categoryKeys),
      sourceValue: resolvedSourceValue,
      typeValues: _parseFilterTypeValues(types),
      tagValues: _parseTagValues(tags),
      taxonomyTokenValues: _parseTaxonomyTokenValues(taxonomy),
      searchTermValue: resolvedSearchTermValue,
    );
  }

  DistanceInMetersValue? _parseDistanceValue(double? raw) {
    if (raw == null) {
      return null;
    }
    final value = DistanceInMetersValue();
    value.parse(raw.toString());
    return value;
  }

  List<PoiFilterKeyValue>? _parseFilterKeyValues(Iterable<String>? rawValues) {
    if (rawValues == null) {
      return null;
    }
    final values = <PoiFilterKeyValue>[];
    for (final entry in rawValues) {
      final normalized = entry.trim().toLowerCase();
      if (normalized.isEmpty) {
        continue;
      }
      final value = PoiFilterKeyValue();
      value.parse(normalized);
      values.add(value);
    }
    return List<PoiFilterKeyValue>.unmodifiable(values.toSet().toList());
  }

  PoiFilterSourceValue? _parseFilterSourceValue(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    final value = PoiFilterSourceValue();
    value.parse(normalized);
    return value;
  }

  List<PoiFilterTypeValue>? _parseFilterTypeValues(
      Iterable<String>? rawValues) {
    if (rawValues == null) {
      return null;
    }
    final values = <PoiFilterTypeValue>[];
    for (final entry in rawValues) {
      final normalized = entry.trim().toLowerCase();
      if (normalized.isEmpty) {
        continue;
      }
      final value = PoiFilterTypeValue();
      value.parse(normalized);
      values.add(value);
    }
    return List<PoiFilterTypeValue>.unmodifiable(values.toSet().toList());
  }

  List<PoiTagValue>? _parseTagValues(Iterable<String>? rawValues) {
    if (rawValues == null) {
      return null;
    }
    final values = <PoiTagValue>[];
    for (final entry in rawValues) {
      final normalized = entry.trim().toLowerCase();
      if (normalized.isEmpty) {
        continue;
      }
      final value = PoiTagValue();
      value.parse(normalized);
      values.add(value);
    }
    return List<PoiTagValue>.unmodifiable(values.toSet().toList());
  }

  List<PoiFilterTaxonomyTokenValue>? _parseTaxonomyTokenValues(
    Iterable<String>? rawValues,
  ) {
    if (rawValues == null) {
      return null;
    }
    final values = <PoiFilterTaxonomyTokenValue>[];
    for (final entry in rawValues) {
      final normalized = entry.trim().toLowerCase();
      if (normalized.isEmpty) {
        continue;
      }
      final value = PoiFilterTaxonomyTokenValue();
      value.parse(normalized);
      values.add(value);
    }
    return List<PoiFilterTaxonomyTokenValue>.unmodifiable(
      values.toSet().toList(),
    );
  }

  PoiFilterSearchTermValue? _parseSearchTermValue(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return null;
    }
    final value = PoiFilterSearchTermValue();
    value.parse(normalized);
    return value;
  }

  Set<String> _categoryKeysForMode(PoiFilterMode mode) {
    switch (mode) {
      case PoiFilterMode.events:
        return const <String>{'event'};
      case PoiFilterMode.restaurants:
        return const <String>{'restaurant'};
      case PoiFilterMode.beaches:
        return const <String>{'beach'};
      case PoiFilterMode.lodging:
        return const <String>{'lodging'};
      case PoiFilterMode.none:
      case PoiFilterMode.server:
        return const <String>{};
    }
  }

  Set<String> _categoryKeysForCatalogFilter(PoiFilterCategory category) {
    final serverQuery = category.serverQuery;
    final configured = category.serverQuery?.categoryKeyValues
            .map((entry) => entry.value.trim().toLowerCase())
            .where((entry) => entry.isNotEmpty)
            .toSet() ??
        const <String>{};
    if (configured.isNotEmpty) {
      return configured;
    }
    if (serverQuery != null && !serverQuery.isEmpty) {
      return const <String>{};
    }
    final key = category.key.trim().toLowerCase();
    if (key.isEmpty) {
      return const <String>{};
    }
    return <String>{key};
  }

  String? _sourceForCatalogFilter(PoiFilterCategory category) {
    final source =
        category.serverQuery?.sourceValue?.value.trim().toLowerCase();
    if (source == null || source.isEmpty) {
      return null;
    }
    return source;
  }

  Set<String> _typesForCatalogFilter(PoiFilterCategory category) {
    return category.serverQuery?.typeValues
            .map((entry) => entry.value.trim().toLowerCase())
            .where((entry) => entry.isNotEmpty)
            .toSet() ??
        const <String>{};
  }

  Set<String> _tagsForCatalogFilter(PoiFilterCategory category) {
    return category.serverQuery?.tagValues
            .map((entry) => entry.value.trim().toLowerCase())
            .where((entry) => entry.isNotEmpty)
            .toSet() ??
        const <String>{};
  }

  Set<String> _taxonomyTokensForCatalogFilter(PoiFilterCategory category) {
    return category.serverQuery?.taxonomyTokenValues
            .map((entry) => entry.value.trim().toLowerCase())
            .where((entry) => entry.isNotEmpty)
            .toSet() ??
        const <String>{};
  }

  bool _isCatalogFilterActive({
    required Set<String> categoryKeys,
    required String? source,
    required Set<String> types,
    required Set<String> taxonomyTokens,
    required Set<String> tags,
  }) {
    return _activeCategoryKeys.length == categoryKeys.length &&
        _activeCategoryKeys.containsAll(categoryKeys) &&
        (_normalizeSource(_activeSource) == _normalizeSource(source)) &&
        _activeTypes.length == types.length &&
        _activeTypes.containsAll(types) &&
        _activeTaxonomyTokens.length == taxonomyTokens.length &&
        _activeTaxonomyTokens.containsAll(taxonomyTokens) &&
        _activeTags.length == tags.length &&
        _activeTags.containsAll(tags);
  }

  String? _normalizeSource(String? raw) {
    final source = raw?.trim().toLowerCase();
    if (source == null || source.isEmpty) {
      return null;
    }
    return source;
  }

  String _labelForMode(PoiFilterMode mode) {
    switch (mode) {
      case PoiFilterMode.events:
        return 'Eventos agora';
      case PoiFilterMode.restaurants:
        return 'Restaurantes';
      case PoiFilterMode.beaches:
        return 'Praias';
      case PoiFilterMode.lodging:
        return 'Hospedagens';
      case PoiFilterMode.none:
      case PoiFilterMode.server:
        return 'Filtro do mapa';
    }
  }

  void _publishActiveFilters() {
    activeCategoryKeysStreamValue.addValue(
      Set<String>.unmodifiable(_activeCategoryKeys),
    );
    activeCatalogFilterKeyStreamValue.addValue(_activeCatalogFilterKey);
  }

  void _setMapStatus(MapStatus status) {
    mapStatusStreamValue.addValue(status);
  }

  void _setMapMessage(String? message) {
    statusMessageStreamValue.addValue(message);
  }

  void _setLoadingState() {
    isLoading.addValue(true);
    errorMessage.addValue(null);
  }

  void _setIdleState() {
    isLoading.addValue(false);
    errorMessage.addValue(null);
  }

  void _setErrorState(String message) {
    errorMessage.addValue(message);
    isLoading.addValue(false);
  }

  void setPoiDeckIndex(int index) {
    if (index != poiDeckIndexStreamValue.value) {
      poiDeckIndexStreamValue.addValue(index);
    }
  }

  void resetPoiDeckIndex() {
    setPoiDeckIndex(0);
  }

  void updatePoiDeckHeight(String poiId, double height) {
    final previous = poiDeckHeights[poiId];
    if (previous != null && (previous - height).abs() < 1) {
      return;
    }
    poiDeckHeights[poiId] = height;
    poiDeckHeightRevisionStreamValue
        .addValue(poiDeckHeightRevisionStreamValue.value + 1);
  }

  double? getPoiDeckHeight(String poiId) {
    return poiDeckHeights[poiId];
  }

  double resolvePoiDeckHeightForDeck(
    List<CityPoiModel> deckPois, {
    required int currentIndex,
    required double defaultHeight,
    required double safeFallbackHeight,
  }) {
    if (deckPois.isEmpty) {
      return defaultHeight;
    }

    final visiblePois = _visibleDeckPois(
      deckPois,
      currentIndex: currentIndex,
    );
    if (visiblePois.isEmpty) {
      return defaultHeight;
    }

    final measuredHeights = <double>[];
    var hasMissingVisibleMeasurement = false;
    for (final poi in visiblePois) {
      final measuredHeight = poiDeckHeights[poi.id];
      if (measuredHeight == null) {
        hasMissingVisibleMeasurement = true;
        continue;
      }
      measuredHeights.add(measuredHeight);
    }

    if (measuredHeights.isEmpty) {
      return safeFallbackHeight;
    }

    final maxMeasuredHeight =
        measuredHeights.reduce((left, right) => math.max(left, right));
    if (hasMissingVisibleMeasurement) {
      return math.max(maxMeasuredHeight, safeFallbackHeight);
    }

    return maxMeasuredHeight;
  }

  List<CityPoiModel> _visibleDeckPois(
    List<CityPoiModel> deckPois, {
    required int currentIndex,
  }) {
    if (deckPois.isEmpty) {
      return const <CityPoiModel>[];
    }

    final lastIndex = deckPois.length - 1;
    final normalizedIndex = currentIndex.clamp(0, lastIndex);
    final startIndex = normalizedIndex > 0 ? normalizedIndex - 1 : 0;
    final endIndex =
        normalizedIndex < lastIndex ? normalizedIndex + 1 : lastIndex;
    return List<CityPoiModel>.unmodifiable(
      deckPois.sublist(startIndex, endIndex + 1),
    );
  }

  @override
  FutureOr onDispose() async {
    _finishPoiTimedEvent();
    _zoomThrottle?.cancel();
    _searchInputDebounceTimer?.cancel();
    _cancelSoftLocationNoticeTimer();
    _postFilterMarkerTapSuppressionTimer?.cancel();
    await _mapInteractionSubscription?.cancel();
    await _filteredPoisSubscription?.cancel();
    await _selectedPoiSubscription?.cancel();
    await _locationResolutionSubscription?.cancel();
    await _locationOriginSettingsSubscription?.cancel();
    statusMessageStreamValue.dispose();
    softLocationNoticeStreamValue.dispose();
    locationFeedbackStateStreamValue.dispose();
    mapStatusStreamValue.dispose();
    isLoading.dispose();
    errorMessage.dispose();
    searchTermStreamValue.dispose();
    searchTextController.dispose();
    lastSelectedPoiMemoryStreamValue.dispose();
    selectedPoiLoadingIdStreamValue.dispose();
    hasSelectedPoiLoadingStreamValue.dispose();
    hasSelectedPoiStreamValue.dispose();
    hasClusterPickerStreamValue.dispose();
    clusterPickerAnchorCoordinateStreamValue.dispose();
    zoomStreamValue.dispose();
    activeCategoryKeysStreamValue.dispose();
    activeCatalogFilterKeyStreamValue.dispose();
    appliedCatalogFilterKeyStreamValue.dispose();
    activeFilterLabelStreamValue.dispose();
    pendingFilterLabelStreamValue.dispose();
    poiDeckIndexStreamValue.dispose();
    poiDeckHeightRevisionStreamValue.dispose();
    filterInteractionLockedStreamValue.dispose();
    mapInteractionGuardActiveStreamValue.dispose();
    mapTrayModeStreamValue.dispose();
    mapHandle.dispose();
  }

  void _attachZoomListener() {
    final initialZoom = mapHandle.currentZoom;
    if (initialZoom != null) {
      zoomStreamValue.addValue(_clampZoom(initialZoom));
    }
    _mapInteractionSubscription?.cancel();
    _mapInteractionSubscription = mapHandle.interactionStream.listen((event) {
      _hasObservedMapEvent = true;
      final nextZoom = event.zoom;
      if (nextZoom != null) {
        _pushZoom(_clampZoom(nextZoom));
      }
      if (event.dismissesTransientNotice) {
        dismissSoftLocationNotice();
      }
      if (event.isViewportChange) {
        clearSelectedPoi(preserveMarkerMemory: false);
      } else if (event.type == BellugaMapInteractionType.emptyTap) {
        clearClusterPicker();
      }
      if (event.userGesture &&
          mapTrayModeStreamValue.value != MapTrayMode.discovery &&
          (event.type == BellugaMapInteractionType.emptyTap ||
              event.isViewportChange)) {
        showDiscoveryTray();
      }
      if (event.type == BellugaMapInteractionType.ready) {
        _tryApplyPendingInitialPoiFocus();
      }
    });
  }

  void _pushZoom(double nextZoom) {
    final current = zoomStreamValue.value;
    if ((nextZoom - current).abs() < 0.01) {
      return;
    }

    // Throttle zoom updates on web to reduce RAF pressure.
    if (kIsWeb) {
      _pendingZoom = nextZoom;
      if (_zoomThrottle?.isActive ?? false) {
        return;
      }
      _zoomThrottle = Timer(const Duration(milliseconds: 50), () {
        final value = _pendingZoom;
        _pendingZoom = null;
        if (value != null) {
          zoomStreamValue.addValue(value);
        }
      });
      return;
    }

    zoomStreamValue.addValue(nextZoom);
  }

  double _clampZoom(double zoom) => zoom.clamp(minZoom, maxZoom);

  void _logMapTelemetry(
    EventTrackerEvents event, {
    required TelemetryRepositoryContractPrimString eventName,
    Object? properties,
  }) {
    unawaited(
      _telemetryRepository.logEvent(
        event,
        eventName: eventName,
        properties: telemetryRepoMap(properties),
      ),
    );
  }

  Future<void> _startPoiTimedEvent(CityPoiModel poi) async {
    _activePoiTimedEventFuture = _telemetryRepository.startTimedEvent(
      EventTrackerEvents.poiOpened,
      eventName: telemetryRepoString('poi_opened'),
      properties: telemetryRepoMap({
        'poi_id': poi.id,
      }),
    );
    _activePoiId = poi.id;
  }

  void _finishPoiTimedEvent() {
    final handleFuture = _activePoiTimedEventFuture;
    if (handleFuture == null) {
      return;
    }
    _activePoiTimedEventFuture = null;
    _activePoiId = null;
    unawaited(handleFuture.then<void>((handle) async {
      if (handle != null) {
        await _telemetryRepository.finishTimedEvent(handle);
      }
    }));
  }
}

enum _EventFilterOrderState { now, upcoming, past, unknown }
