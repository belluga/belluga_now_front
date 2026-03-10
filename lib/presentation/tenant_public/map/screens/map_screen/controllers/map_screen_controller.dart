import 'dart:async';

import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/filters/main_filter_option.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_mode.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/map_status.dart';
import 'package:belluga_now/domain/map/queries/poi_query.dart';
import 'package:belluga_now/domain/map/ride_share_provider.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/poi_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:free_map/free_map.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class MapScreenController implements Disposable {
  static const double minZoom = 14.5;
  static const double maxZoom = 17.0;
  MapScreenController({
    PoiRepositoryContract? poiRepository,
    UserLocationRepositoryContract? userLocationRepository,
    TelemetryRepositoryContract? telemetryRepository,
  })  : _poiRepository = poiRepository ?? GetIt.I.get<PoiRepositoryContract>(),
        _userLocationRepository = userLocationRepository ??
            GetIt.I.get<UserLocationRepositoryContract>(),
        _telemetryRepository =
            telemetryRepository ?? GetIt.I.get<TelemetryRepositoryContract>();

  final PoiRepositoryContract _poiRepository;
  final UserLocationRepositoryContract _userLocationRepository;
  final TelemetryRepositoryContract _telemetryRepository;

  final mapController = MapController();

  final statusMessageStreamValue = StreamValue<String?>();
  final mapStatusStreamValue =
      StreamValue<MapStatus>(defaultValue: MapStatus.locating);
  final isLoading = StreamValue<bool>(defaultValue: false);
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

  StreamValue<List<CityPoiModel>> get filteredPoisStreamValue =>
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
  final StreamValue<String?> activeFilterLabelStreamValue =
      StreamValue<String?>();

  CityCoordinate get defaultCenter => _poiRepository.defaultCenter;

  PoiQuery _currentQuery = const PoiQuery();
  bool _filtersLoadFailed = false;
  Set<String> _activeCategoryKeys = <String>{};
  Set<String> _activeTaxonomyTokens = <String>{};
  StreamSubscription<MapEvent>? _mapEventSubscription;
  StreamSubscription<List<CityPoiModel>>? _filteredPoisSubscription;

  Future<void> init() async {
    _bindFilteredPoisClamp();
    await Future.wait([
      loadMainFilters(),
      loadFilters(),
      loadPois(const PoiQuery()),
    ]);
    await _userLocationRepository.refreshIfPermitted(
      minInterval: Duration.zero,
    );
    await centerOnUser();
    _attachZoomListener();
  }

  void _bindFilteredPoisClamp() {
    if (_filteredPoisSubscription != null) {
      return;
    }
    _filteredPoisSubscription =
        filteredPoisStreamValue.stream.listen(_clampPoiDeckIndex);
    _clampPoiDeckIndex(filteredPoisStreamValue.value);
  }

  void _clampPoiDeckIndex(List<CityPoiModel> pois) {
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

  Future<void> loadFilters() async {
    if (filterOptionsStreamValue.value != null && !_filtersLoadFailed) {
      return;
    }
    try {
      await _poiRepository.fetchFilters();
      _filtersLoadFailed = false;
    } catch (error) {
      _filtersLoadFailed = true;
      filterOptionsStreamValue.addValue(null);
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
      mainFilterOptionsStreamValue.addValue(const <MainFilterOption>[]);
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
        eventName: 'map_location_resolved',
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
    final targetZoom = animate ? 16.0 : mapController.camera.zoom;
    mapController.move(target, _clampZoom(targetZoom));
    _logMapTelemetry(
      EventTrackerEvents.viewContent,
      eventName: 'map_location_resolved',
      properties: const {
        'status': 'success',
      },
    );

    statusMessageStreamValue.addValue(null);
  }

  void clearStatusMessage() {
    statusMessageStreamValue.addValue(null);
  }

  Future<void> ensureMapReady() async {
    try {
      mapController.camera;
      return;
    } catch (_) {
      try {
        await mapController.mapEventStream.first;
      } catch (_) {}
    }
  }

  Future<void> searchPois(String query) async {
    final trimmed = query.trim();
    final nextQuery = _composeQuery(searchTerm: query);
    _logMapTelemetry(
      EventTrackerEvents.search,
      eventName: 'map_search_submitted',
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
    final previousQueryLen = _currentQuery.searchTerm?.trim().length ?? 0;
    _logMapTelemetry(
      EventTrackerEvents.buttonClick,
      eventName: 'map_search_cleared',
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
    final resolvedQuery = _resolveRuntimeQuery(query);
    _currentQuery = resolvedQuery;
    searchTermStreamValue.addValue(resolvedQuery.searchTerm);

    _setMapStatus(MapStatus.fetching);
    _setMapMessage(loadingMessage ?? 'Carregando pontos...');
    _setLoadingState();

    try {
      await _poiRepository.fetchPoints(resolvedQuery);
      _setIdleState();
      _setMapStatus(MapStatus.ready);
      _setMapMessage(null);
    } catch (error) {
      const errorMessage = 'Nao foi possivel carregar os pontos de interesse.';
      _setErrorState(errorMessage);
      _setMapStatus(MapStatus.error);
      _setMapMessage(errorMessage);
      debugPrint('Failed to load POIs: $error');
    }
  }

  PoiQuery _resolveRuntimeQuery(PoiQuery query) {
    final origin = query.origin ?? userLocationStreamValue.value;
    return PoiQuery(
      northEast: query.northEast,
      southWest: query.southWest,
      origin: origin,
      maxDistanceMeters: query.maxDistanceMeters,
      categories: query.categories,
      categoryKeys: query.categoryKeys,
      tags: query.tags,
      taxonomy: query.taxonomy,
      searchTerm: query.searchTerm,
    );
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

  Future<void> handleMarkerTap(CityPoiModel poi) async {
    final hasStackCandidates = poi.stackCount > 1 && poi.stackKey.isNotEmpty;
    if (!hasStackCandidates) {
      selectPoi(poi);
      return;
    }

    try {
      final stackItems = await _poiRepository.fetchStackItems(
        stackKey: poi.stackKey,
        query: _currentQuery,
      );
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
            stackKey: normalizedStackKey,
            stackCount: normalizedCount,
          ),
        )
        .toList(growable: false);
    return seeded
        .map(
          (item) => item.copyWith(stackItems: seeded),
        )
        .toList(growable: false);
  }

  void clearSelectedPoi() {
    _poiRepository.clearSelection();
    _finishPoiTimedEvent();
  }

  void applyFilterMode(PoiFilterMode mode) {
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
    _publishActiveFilters();
    activeFilterLabelStreamValue.addValue(_labelForMode(mode));
    _poiRepository.applyFilterMode(mode);
    _logMapTelemetry(
      EventTrackerEvents.selectItem,
      eventName: 'map_main_filter_applied',
      properties: {
        'filter_mode': mode.name,
      },
    );
    unawaited(
      loadPois(
        _composeQuery(
          categoryKeys: _activeCategoryKeys,
          taxonomy: const <String>{},
        ),
        loadingMessage: 'Aplicando filtros...',
      ),
    );
  }

  void clearFilters() {
    final wasFiltered = filterModeStreamValue.value != PoiFilterMode.none ||
        _activeCategoryKeys.isNotEmpty ||
        _activeTaxonomyTokens.isNotEmpty;
    _activeCategoryKeys = <String>{};
    _activeTaxonomyTokens = <String>{};
    _publishActiveFilters();
    activeFilterLabelStreamValue.addValue(null);
    _poiRepository.clearFilters();
    if (!wasFiltered) {
      return;
    }
    unawaited(
      loadPois(
        _composeQuery(
          categoryKeys: const <String>{},
          taxonomy: const <String>{},
        ),
        loadingMessage: 'Carregando pontos...',
      ),
    );
    _logMapTelemetry(
      EventTrackerEvents.buttonClick,
      eventName: 'map_main_filter_cleared',
    );
  }

  void toggleCatalogCategoryFilter(PoiFilterCategory category) {
    final key = category.key.trim().toLowerCase();
    if (key.isEmpty) {
      return;
    }

    if (_activeCategoryKeys.length == 1 &&
        _activeCategoryKeys.contains(key) &&
        _activeTaxonomyTokens.isEmpty) {
      clearFilters();
      return;
    }

    _activeCategoryKeys = <String>{key};
    _activeTaxonomyTokens = <String>{};
    _publishActiveFilters();
    activeFilterLabelStreamValue.addValue(category.label);
    _poiRepository.applyFilterMode(PoiFilterMode.server);
    _logMapTelemetry(
      EventTrackerEvents.selectItem,
      eventName: 'map_catalog_filter_applied',
      properties: {
        'category_key': key,
      },
    );
    unawaited(
      loadPois(
        _composeQuery(
          categoryKeys: _activeCategoryKeys,
          taxonomy: const <String>{},
        ),
        loadingMessage: 'Aplicando filtros...',
      ),
    );
  }

  void toggleTaxonomyFilter(PoiFilterTaxonomyTerm taxonomyTerm) {
    final token = taxonomyTerm.token;
    if (token.isEmpty) {
      return;
    }

    final next = <String>{..._activeTaxonomyTokens};
    final selected = !next.remove(token);
    if (selected) {
      next.add(token);
    }
    _activeTaxonomyTokens = next;

    if (_activeTaxonomyTokens.isEmpty && _activeCategoryKeys.isEmpty) {
      clearFilters();
      return;
    }

    _publishActiveFilters();
    activeFilterLabelStreamValue.addValue(
      _resolveActiveFilterLabel(
        fallbackTaxonomyLabel: taxonomyTerm.label,
      ),
    );
    _poiRepository.applyFilterMode(PoiFilterMode.server);
    _logMapTelemetry(
      EventTrackerEvents.selectItem,
      eventName: 'map_taxonomy_filter_toggled',
      properties: {
        'taxonomy_token': token,
        'selected': selected,
      },
    );
    unawaited(
      loadPois(
        _composeQuery(
          categoryKeys: _activeCategoryKeys,
          taxonomy: _activeTaxonomyTokens,
        ),
        loadingMessage: 'Aplicando filtros...',
      ),
    );
  }

  bool isCategoryFilterActive(PoiFilterCategory category) {
    final key = category.key.trim().toLowerCase();
    if (key.isEmpty) {
      return false;
    }
    return _activeCategoryKeys.contains(key);
  }

  bool isTaxonomyFilterActive(PoiFilterTaxonomyTerm taxonomyTerm) {
    return _activeTaxonomyTokens.contains(taxonomyTerm.token);
  }

  void logDirectionsOpened(CityPoiModel poi) {
    _logMapTelemetry(
      EventTrackerEvents.viewContent,
      eventName: 'map_directions_opened',
      properties: {
        'source': 'poi',
        'poi_id': poi.id,
      },
    );
  }

  void logRideShareClicked({
    required RideShareProvider provider,
    String? poiId,
  }) {
    _logMapTelemetry(
      EventTrackerEvents.buttonClick,
      eventName: 'map_ride_share_clicked',
      properties: {
        'provider': provider.name,
        if (poiId != null) 'poi_id': poiId,
      },
    );
  }

  Future<void> focusOnPoi(CityPoiModel poi, {double? zoom}) async {
    await ensureMapReady();
    final coordinate = poi.coordinate;
    final target = LatLng(coordinate.latitude, coordinate.longitude);
    final targetZoom = zoom ?? 16;
    mapController.move(target, _clampZoom(targetZoom.toDouble()));
  }

  PoiQuery _composeQuery({
    CityCoordinate? northEast,
    CityCoordinate? southWest,
    CityCoordinate? origin,
    double? maxDistanceMeters,
    Iterable<CityPoiCategory>? categories,
    Iterable<String>? categoryKeys,
    Iterable<String>? tags,
    Iterable<String>? taxonomy,
    String? searchTerm,
  }) {
    return PoiQuery.compose(
      currentQuery: _currentQuery,
      northEast: northEast,
      southWest: southWest,
      origin: origin,
      maxDistanceMeters: maxDistanceMeters,
      categories: categories,
      categoryKeys: categoryKeys,
      tags: tags,
      taxonomy: taxonomy,
      searchTerm: searchTerm,
    );
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
        return 'Filtros personalizados';
    }
  }

  void _publishActiveFilters() {
    activeCategoryKeysStreamValue.addValue(
      Set<String>.unmodifiable(_activeCategoryKeys),
    );
    activeTaxonomyTokensStreamValue.addValue(
      Set<String>.unmodifiable(_activeTaxonomyTokens),
    );
  }

  String _resolveActiveFilterLabel({required String fallbackTaxonomyLabel}) {
    if (_activeTaxonomyTokens.isNotEmpty) {
      if (_activeTaxonomyTokens.length == 1 && _activeCategoryKeys.isEmpty) {
        return fallbackTaxonomyLabel;
      }
      return 'Filtros personalizados';
    }

    if (_activeCategoryKeys.length == 1) {
      final key = _activeCategoryKeys.first;
      final options = filterOptionsStreamValue.value;
      final category = options?.categories.firstWhere(
        (item) => item.key.trim().toLowerCase() == key,
        orElse: () => PoiFilterCategory(key: key, label: key, tags: const {}),
      );
      return category?.label ?? key;
    }

    return 'Filtros personalizados';
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
    await _mapEventSubscription?.cancel();
    await _filteredPoisSubscription?.cancel();
    activeCategoryKeysStreamValue.dispose();
    activeTaxonomyTokensStreamValue.dispose();
    activeFilterLabelStreamValue.dispose();
    poiDeckIndexStreamValue.dispose();
  }

  void _attachZoomListener() {
    try {
      zoomStreamValue.addValue(_clampZoom(mapController.camera.zoom));
    } catch (_) {
      // ignore if camera not ready yet
    }
    _mapEventSubscription?.cancel();
    _mapEventSubscription = mapController.mapEventStream.listen((event) {
      final nextZoom = _clampZoom(event.camera.zoom);
      _pushZoom(nextZoom);
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
    required String eventName,
    Map<String, dynamic>? properties,
  }) {
    unawaited(
      _telemetryRepository.logEvent(
        event,
        eventName: eventName,
        properties: properties,
      ),
    );
  }

  Future<void> _startPoiTimedEvent(CityPoiModel poi) async {
    _activePoiTimedEventFuture = _telemetryRepository.startTimedEvent(
      EventTrackerEvents.poiOpened,
      eventName: 'poi_opened',
      properties: {
        'poi_id': poi.id,
      },
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
