import 'dart:async';

import 'package:belluga_now/application/router/guards/location_permission_gate_runtime.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/location_origin_reason.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/filters/main_filter_option.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_mode.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/map_status.dart';
import 'package:belluga_now/domain/map/projections/city_poi_stack_items.dart';
import 'package:belluga_now/domain/map/queries/poi_query.dart';
import 'package:belluga_now/domain/map/ride_share_provider.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_key_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_search_term_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_source_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_taxonomy_token_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_stack_count_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_stack_key_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_tag_value.dart';
import 'package:belluga_now/domain/repositories/poi_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_duration_value.dart';
import 'package:belluga_now/domain/services/location_origin_service_contract.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:free_map/free_map.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:belluga_now/infrastructure/services/location_origin_resolution_request_factory.dart';
import 'package:belluga_now/presentation/shared/location_permission/location_origin_message_resolver.dart';
import 'package:stream_value/core/stream_value.dart';

class MapScreenController implements Disposable {
  static const double minZoom = 14.5;
  static const double maxZoom = 17.0;
  MapScreenController({
    PoiRepositoryContract? poiRepository,
    UserLocationRepositoryContract? userLocationRepository,
    TelemetryRepositoryContract? telemetryRepository,
    MapController? mapController,
    AppData? appData,
    LocationOriginServiceContract? locationOriginService,
  })  : _poiRepository = poiRepository ?? GetIt.I.get<PoiRepositoryContract>(),
        _userLocationRepository = userLocationRepository ??
            GetIt.I.get<UserLocationRepositoryContract>(),
        _telemetryRepository =
            telemetryRepository ?? GetIt.I.get<TelemetryRepositoryContract>(),
        _appData = appData ?? GetIt.I.get<AppData>(),
        _locationOriginService = locationOriginService ??
            GetIt.I.get<LocationOriginServiceContract>(),
        mapController = mapController ?? MapController();

  final PoiRepositoryContract _poiRepository;
  final UserLocationRepositoryContract _userLocationRepository;
  final TelemetryRepositoryContract _telemetryRepository;
  final AppData _appData;
  final LocationOriginServiceContract _locationOriginService;

  final MapController mapController;

  final statusMessageStreamValue = StreamValue<String?>();
  final softLocationNoticeStreamValue = StreamValue<String>(defaultValue: '');
  final mapStatusStreamValue =
      StreamValue<MapStatus>(defaultValue: MapStatus.locating);
  final isLoading = StreamValue<bool>(defaultValue: false);
  final filterInteractionLockedStreamValue =
      StreamValue<bool>(defaultValue: false);
  final errorMessage = StreamValue<String?>();
  final searchTermStreamValue = StreamValue<String?>();
  final zoomStreamValue = StreamValue<double>(defaultValue: 16);
  Timer? _zoomThrottle;
  double? _pendingZoom;
  Future<EventTrackerTimedEventHandle?>? _activePoiTimedEventFuture;
  String? _activePoiId;
  final StreamValue<int> poiDeckIndexStreamValue =
      StreamValue<int>(defaultValue: 0);
  PoiFilterMode? lastPoiDeckFilterMode;
  final Map<String, double> poiDeckHeights = <String, double>{};

  StreamValue<CityCoordinate?> get userLocationStreamValue =>
      _userLocationRepository.userLocationStreamValue;
  bool get hasResolvedUserLocation => userLocationStreamValue.value != null;

  StreamValue<List<CityPoiModel>?> get filteredPoisStreamValue =>
      _poiRepository.filteredPoisStreamValue;

  StreamValue<CityPoiModel?> get selectedPoiStreamValue =>
      _poiRepository.selectedPoiStreamValue;

  StreamValue<PoiFilterMode> get filterModeStreamValue =>
      _poiRepository.filterModeStreamValue;

  StreamValue<PoiFilterOptions?> get filterOptionsStreamValue =>
      _poiRepository.filterOptionsStreamValue;

  StreamValue<List<MainFilterOption>> get mainFilterOptionsStreamValue =>
      _poiRepository.mainFilterOptionsStreamValue;

  final StreamValue<Set<String>> activeCategoryKeysStreamValue =
      StreamValue<Set<String>>(defaultValue: const <String>{});
  final StreamValue<Set<String>> activeTaxonomyTokensStreamValue =
      StreamValue<Set<String>>(defaultValue: const <String>{});
  final StreamValue<String?> activeCatalogFilterKeyStreamValue =
      StreamValue<String?>(defaultValue: null);
  final StreamValue<String?> appliedCatalogFilterKeyStreamValue =
      StreamValue<String?>(defaultValue: null);
  final StreamValue<String?> activeFilterLabelStreamValue =
      StreamValue<String?>();

  CityCoordinate get defaultCenter => _poiRepository.defaultCenter;

  PoiQuery _currentQuery = PoiQuery();
  bool _forceTenantDefaultUnavailableEntry = false;
  bool _hasDismissedSoftLocationNoticeForAccess = false;
  bool _filtersLoadFailed = false;
  Set<String> _activeCategoryKeys = <String>{};
  Set<String> _activeTaxonomyTokens = <String>{};
  Set<String> _activeTags = <String>{};
  String? _activeSource;
  Set<String> _activeTypes = <String>{};
  String? _activeCatalogFilterKey;
  String? _appliedCatalogFilterKey;
  StreamSubscription<MapEvent>? _mapEventSubscription;
  StreamSubscription<List<CityPoiModel>?>? _filteredPoisSubscription;
  int _poiRequestSequence = 0;
  bool _filterInteractionLocked = false;
  CityPoiModel? _pendingInitialPoiFocus;
  bool _initialPoiFocusApplied = false;
  bool _initialPoiFocusInProgress = false;
  bool _hasObservedMapEvent = false;

  Future<void> init({
    String? initialPoiQuery,
    String? initialPoiStackQuery,
  }) async {
    final enteredViaSoftLocationGate =
        LocationPermissionGateRuntime.consumeSoftLocationFallbackEntry();
    _resetInitialPoiFocusState();
    _forceTenantDefaultUnavailableEntry = enteredViaSoftLocationGate;
    _hasDismissedSoftLocationNoticeForAccess = false;
    softLocationNoticeStreamValue.addValue('');
    final hasInitialPoiQuery = _normalizePoiQuery(initialPoiQuery) != null;
    _bindFilteredPoisClamp();
    _attachZoomListener();

    final initialPoiHydrationFuture = hasInitialPoiQuery
        ? _applyInitialPoiQuery(
            initialPoiQuery: initialPoiQuery,
            initialPoiStackQuery: initialPoiStackQuery,
            emitNotFoundMessage: false,
          )
        : Future<void>.value();

    await Future.wait([
      loadMainFilters(),
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

    _tryApplyPendingInitialPoiFocus();
  }

  void _requestLocationPermissionIfNeeded() {
    if (_forceTenantDefaultUnavailableEntry || hasResolvedUserLocation) {
      return;
    }
    unawaited(_userLocationRepository.resolveUserLocation());
  }

  void _bindFilteredPoisClamp() {
    if (_filteredPoisSubscription != null) {
      return;
    }
    _filteredPoisSubscription =
        filteredPoisStreamValue.stream.listen(_clampPoiDeckIndex);
    _clampPoiDeckIndex(filteredPoisStreamValue.value);
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

  Future<void> loadMainFilters() async {
    if (mainFilterOptionsStreamValue.value.isNotEmpty) {
      return;
    }
    try {
      await _poiRepository.fetchMainFilters();
    } catch (error) {
      debugPrint('Failed to load main filters: $error');
    }
  }

  Future<void> centerOnUser({bool animate = true}) async {
    var coordinate = userLocationStreamValue.value;
    if (coordinate == null) {
      await _userLocationRepository.resolveUserLocation();
      coordinate = userLocationStreamValue.value;
    }

    if (coordinate == null) {
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

    final target = LatLng(coordinate.latitude, coordinate.longitude);
    await ensureMapReady();
    final targetZoom = animate ? 16.0 : _currentMapZoomOrDefault();
    try {
      mapController.move(target, _clampZoom(targetZoom));
    } catch (error) {
      debugPrint('Failed to center on user location: $error');
      statusMessageStreamValue
          .addValue('Mapa ainda está inicializando. Tente novamente.');
      return;
    }
    _logMapTelemetry(
      EventTrackerEvents.viewContent,
      eventName: telemetryRepoString('map_location_resolved'),
      properties: const {
        'status': 'success',
      },
    );

    statusMessageStreamValue.addValue(null);
  }

  double _currentMapZoomOrDefault() {
    try {
      return mapController.camera.zoom;
    } catch (_) {
      return 16.0;
    }
  }

  void clearStatusMessage() {
    statusMessageStreamValue.addValue(null);
  }

  void dismissSoftLocationNotice() {
    _hasDismissedSoftLocationNoticeForAccess = true;
    softLocationNoticeStreamValue.addValue('');
  }

  Future<void> ensureMapReady() async {
    if (_isMapCameraReady() || _hasObservedMapEvent) {
      return;
    }
    try {
      await mapController.mapEventStream.first.timeout(
        const Duration(milliseconds: 250),
      );
      _hasObservedMapEvent = true;
    } catch (_) {
      // map readiness can race against first frame; caller handles fallback
    }
  }

  Future<void> searchPois(String query) async {
    final trimmed = query.trim();
    final nextQuery = _composeQuery(searchTerm: query);
    _logMapTelemetry(
      EventTrackerEvents.search,
      eventName: telemetryRepoString('map_search_submitted'),
      properties: {
        'query_len': trimmed.length,
        'filter_mode': filterModeStreamValue.value.name,
      },
    );
    statusMessageStreamValue.addValue('Buscando pontos...');
    await loadPois(nextQuery);
    statusMessageStreamValue.addValue(null);
  }

  Future<void> clearSearch() async {
    final previousQueryLen =
        _currentQuery.searchTermValue?.value.trim().length ?? 0;
    _logMapTelemetry(
      EventTrackerEvents.buttonClick,
      eventName: telemetryRepoString('map_search_cleared'),
      properties: {
        'previous_query_len': previousQueryLen,
        'filter_mode': filterModeStreamValue.value.name,
      },
    );
    final query = _composeQuery(searchTerm: '');
    statusMessageStreamValue.addValue('Carregando pontos...');
    await loadPois(query, loadingMessage: 'Carregando pontos...');
    statusMessageStreamValue.addValue(null);
  }

  Future<void> loadPois(
    PoiQuery query, {
    String? loadingMessage,
  }) async {
    final requestSequence = ++_poiRequestSequence;
    final resolvedQuery = await _resolveRuntimeQuery(query);
    _currentQuery = resolvedQuery;
    searchTermStreamValue.addValue(resolvedQuery.searchTermValue?.value);

    _setMapStatus(MapStatus.fetching);
    _setMapMessage(loadingMessage ?? 'Carregando pontos...');
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
      _poiRepository.clearLoadedPois();
      resetPoiDeckIndex();
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
    _publishSoftLocationNotice(resolution.settings?.reason);
    final origin = resolution.effectiveCoordinate ?? query.origin;
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

  void _publishSoftLocationNotice(LocationOriginReason? reason) {
    if (_hasDismissedSoftLocationNoticeForAccess || reason == null) {
      return;
    }
    final message = LocationOriginMessageResolver.transientMessageForReason(
      reason: reason,
      appName: _appData.nameValue.value,
    );
    softLocationNoticeStreamValue.addValue(message ?? '');
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
    try {
      final camera = mapController.camera;
      return camera.nonRotatedSize != MapCamera.kImpossibleSize;
    } catch (_) {
      return false;
    }
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

  Future<void> handleMarkerTap(CityPoiModel poi) async {
    final hasStackCandidates = poi.stackCount > 1 && poi.stackKey.isNotEmpty;
    if (!hasStackCandidates) {
      selectPoi(poi);
      return;
    }

    try {
      await _poiRepository.loadStackItems(
        stackKey: PoiStackKeyValue()..parse(poi.stackKey),
        query: _currentQuery,
      );
      final stackItems =
          _poiRepository.stackItemsStreamValue.value ?? const <CityPoiModel>[];
      if (stackItems.isEmpty) {
        selectPoi(poi);
        return;
      }
      final enrichedItems = _attachStackContext(
        stackItems,
        stackKey: poi.stackKey,
        stackCount: poi.stackCount,
      );
      final selected = enrichedItems.firstWhere(
        (candidate) => candidate.id == poi.id,
        orElse: () => enrichedItems.first,
      );
      final selectedIndex = enrichedItems.indexOf(selected);
      setPoiDeckIndex(selectedIndex == -1 ? 0 : selectedIndex);
      selectPoi(selected);
    } catch (error) {
      debugPrint('Failed to load stack ${poi.stackKey}: $error');
      selectPoi(poi);
    }
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

  void clearSelectedPoi() {
    _poiRepository.clearSelection();
    _finishPoiTimedEvent();
  }

  void applyFilterMode(PoiFilterMode mode) {
    if (_filterInteractionLocked) {
      return;
    }
    final current = filterModeStreamValue.value;
    if (current == mode) {
      clearFilters();
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
    _poiRepository.applyFilterMode(mode);
    _logMapTelemetry(
      EventTrackerEvents.selectItem,
      eventName: telemetryRepoString('map_main_filter_applied'),
      properties: {
        'filter_mode': mode.name,
      },
    );
    unawaited(
      _runFilterReload(
        _composeQuery(
          categoryKeys: _activeCategoryKeys,
          taxonomy: const <String>{},
          tags: const <String>{},
          source: '',
          types: const <String>{},
        ),
        loadingMessage: 'Aplicando filtros...',
        appliedCatalogFilterKeyOnSuccess: null,
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
    activeFilterLabelStreamValue.addValue(null);
    _poiRepository.clearFilters();
    if (!wasFiltered) {
      return;
    }
    unawaited(
      _runFilterReload(
        _composeQuery(
          categoryKeys: const <String>{},
          taxonomy: const <String>{},
          tags: const <String>{},
          source: '',
          types: const <String>{},
        ),
        loadingMessage: 'Carregando pontos...',
        appliedCatalogFilterKeyOnSuccess: null,
      ),
    );
    _logMapTelemetry(
      EventTrackerEvents.buttonClick,
      eventName: telemetryRepoString('map_main_filter_cleared'),
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
      clearFilters();
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
    _poiRepository.applyFilterMode(PoiFilterMode.server);
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
    unawaited(
      _runFilterReload(
        _composeQuery(
          categoryKeys: _activeCategoryKeys,
          source: _activeSource ?? '',
          types: _activeTypes,
          taxonomy: _activeTaxonomyTokens,
          tags: _activeTags,
        ),
        loadingMessage: 'Aplicando filtros...',
        appliedCatalogFilterKeyOnSuccess: _activeCatalogFilterKey,
      ),
    );
  }

  void toggleTaxonomyFilter(PoiFilterTaxonomyTerm taxonomyTerm) {
    if (_filterInteractionLocked) {
      return;
    }
    final token = taxonomyTerm.token;
    if (token.isEmpty) {
      return;
    }

    final isSameSingleSelection = _activeTaxonomyTokens.length == 1 &&
        _activeTaxonomyTokens.contains(token) &&
        _activeCategoryKeys.isEmpty &&
        _activeTags.isEmpty &&
        (_activeSource == null || _activeSource!.isEmpty) &&
        _activeTypes.isEmpty;

    if (isSameSingleSelection) {
      clearFilters();
      return;
    }

    _activeCategoryKeys = <String>{};
    _activeSource = null;
    _activeTypes = <String>{};
    _activeTags = <String>{};
    _activeCatalogFilterKey = null;
    _activeTaxonomyTokens = <String>{token};

    _publishActiveFilters();
    activeFilterLabelStreamValue.addValue(
      _resolveActiveFilterLabel(
        fallbackTaxonomyLabel: taxonomyTerm.label,
      ),
    );
    _poiRepository.applyFilterMode(PoiFilterMode.server);
    _logMapTelemetry(
      EventTrackerEvents.selectItem,
      eventName: telemetryRepoString('map_taxonomy_filter_toggled'),
      properties: {
        'taxonomy_token': token,
        'selected': true,
      },
    );
    unawaited(
      _runFilterReload(
        _composeQuery(
          categoryKeys: _activeCategoryKeys,
          source: _activeSource ?? '',
          types: _activeTypes,
          tags: _activeTags,
          taxonomy: _activeTaxonomyTokens,
        ),
        loadingMessage: 'Aplicando filtros...',
        appliedCatalogFilterKeyOnSuccess: null,
      ),
    );
  }

  Future<void> _runFilterReload(
    PoiQuery query, {
    required String loadingMessage,
    required String? appliedCatalogFilterKeyOnSuccess,
  }) async {
    if (_filterInteractionLocked) {
      return;
    }
    _filterInteractionLocked = true;
    filterInteractionLockedStreamValue.addValue(true);
    try {
      await loadPois(query, loadingMessage: loadingMessage);
      _appliedCatalogFilterKey = appliedCatalogFilterKeyOnSuccess;
      appliedCatalogFilterKeyStreamValue.addValue(_appliedCatalogFilterKey);
    } finally {
      _filterInteractionLocked = false;
      filterInteractionLockedStreamValue.addValue(false);
    }
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

  bool isTaxonomyFilterActive(PoiFilterTaxonomyTerm taxonomyTerm) {
    return _activeTaxonomyTokens.contains(taxonomyTerm.token);
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

  Future<void> focusOnPoi(CityPoiModel poi, {double? zoom}) async {
    await _focusOnPoi(poi, zoom: zoom);
  }

  Future<bool> _focusOnPoi(CityPoiModel poi, {double? zoom}) async {
    await ensureMapReady();
    final coordinate = poi.coordinate;
    final target = LatLng(coordinate.latitude, coordinate.longitude);
    final targetZoom = zoom ?? 16;
    try {
      return mapController.move(target, _clampZoom(targetZoom.toDouble()));
    } catch (error) {
      debugPrint('Failed to focus on poi ${poi.id}: $error');
      return false;
    }
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
    activeTaxonomyTokensStreamValue.addValue(
      Set<String>.unmodifiable(_activeTaxonomyTokens),
    );
    activeCatalogFilterKeyStreamValue.addValue(_activeCatalogFilterKey);
  }

  String _resolveActiveFilterLabel({required String fallbackTaxonomyLabel}) {
    if (_activeTaxonomyTokens.isNotEmpty) {
      if (_activeTaxonomyTokens.length == 1 && _activeCategoryKeys.isEmpty) {
        return fallbackTaxonomyLabel;
      }
      return 'Filtros do mapa';
    }

    if (_activeCategoryKeys.length == 1) {
      final key = _activeCategoryKeys.first;
      final options = filterOptionsStreamValue.value;
      PoiFilterCategory? category;
      final categories = options?.categories;
      if (categories != null) {
        for (final item in categories) {
          if (item.key.trim().toLowerCase() == key) {
            category = item;
            break;
          }
        }
      }
      return category?.label ?? key;
    }

    return 'Filtros do mapa';
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
    poiDeckHeights[poiId] = height;
  }

  double? getPoiDeckHeight(String poiId) {
    return poiDeckHeights[poiId];
  }

  @override
  FutureOr onDispose() async {
    _finishPoiTimedEvent();
    _zoomThrottle?.cancel();
    await _mapEventSubscription?.cancel();
    await _filteredPoisSubscription?.cancel();
    statusMessageStreamValue.dispose();
    softLocationNoticeStreamValue.dispose();
    mapStatusStreamValue.dispose();
    isLoading.dispose();
    errorMessage.dispose();
    searchTermStreamValue.dispose();
    zoomStreamValue.dispose();
    activeCategoryKeysStreamValue.dispose();
    activeTaxonomyTokensStreamValue.dispose();
    activeCatalogFilterKeyStreamValue.dispose();
    appliedCatalogFilterKeyStreamValue.dispose();
    activeFilterLabelStreamValue.dispose();
    poiDeckIndexStreamValue.dispose();
    filterInteractionLockedStreamValue.dispose();
  }

  void _attachZoomListener() {
    try {
      zoomStreamValue.addValue(_clampZoom(mapController.camera.zoom));
    } catch (_) {
      // ignore if camera not ready yet
    }
    _mapEventSubscription?.cancel();
    _mapEventSubscription = mapController.mapEventStream.listen((event) {
      _hasObservedMapEvent = true;
      final nextZoom = _clampZoom(event.camera.zoom);
      _pushZoom(nextZoom);
      _tryApplyPendingInitialPoiFocus();
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
