import 'dart:async';

import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/filters/main_filter_option.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/map_status.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/infrastructure/repositories/poi_repository.dart';
import 'package:belluga_now/infrastructure/repositories/user_location_repository.dart';
import 'package:belluga_now/infrastructure/dal/datasources/poi_query.dart';
import 'package:free_map/free_map.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class MapScreenController implements Disposable {
  static const double minZoom = 14.5;
  static const double maxZoom = 17.0;
  MapScreenController({
    PoiRepository? poiRepository,
    UserLocationRepository? userLocationRepository,
  })  : _poiRepository = poiRepository ?? GetIt.I.get<PoiRepository>(),
        _userLocationRepository =
            userLocationRepository ?? GetIt.I.get<UserLocationRepository>();

  final PoiRepository _poiRepository;
  final UserLocationRepository _userLocationRepository;

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

  CityCoordinate get defaultCenter => _poiRepository.defaultCenter;

  PoiQuery _currentQuery = const PoiQuery();
  bool _filtersLoadFailed = false;
  StreamSubscription<MapEvent>? _mapEventSubscription;

  Future<void> init() async {
    await Future.wait([
      loadMainFilters(),
      loadFilters(),
      loadPois(const PoiQuery()),
    ]);
    await _userLocationRepository.resolveUserLocation();
    await centerOnUser();
    _attachZoomListener();
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

  Future<String?> centerOnUser({bool animate = true}) async {
    await _userLocationRepository.resolveUserLocation();
    final coordinate = userLocationStreamValue.value;

    if (coordinate == null) {
      return Future.value('Não encontramos sua localização');
    }

    final target = LatLng(coordinate.latitude, coordinate.longitude);
    await ensureMapReady();
    final targetZoom = animate ? 16.0 : mapController.camera.zoom;
    mapController.move(target, _clampZoom(targetZoom));

    return null;
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
    final nextQuery = _composeQuery(searchTerm: query);
    statusMessageStreamValue.addValue('Buscando pontos...');
    await loadPois(nextQuery);
    statusMessageStreamValue.addValue(null);
  }

  Future<void> clearSearch() async {
    final query = _composeQuery(searchTerm: '');
    statusMessageStreamValue.addValue('Carregando pontos...');
    await loadPois(query, loadingMessage: 'Carregando pontos...');
    statusMessageStreamValue.addValue(null);
  }

  Future<void> loadPois(
    PoiQuery query, {
    String? loadingMessage,
  }) async {
    _currentQuery = query;
    searchTermStreamValue.addValue(query.searchTerm);

    _setMapStatus(MapStatus.fetching);
    _setMapMessage(loadingMessage ?? 'Carregando pontos...');
    _setLoadingState();

    try {
      await _poiRepository.fetchPoints(query);
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

  void selectPoi(CityPoiModel? poi) => _poiRepository.selectPoi(poi);

  void clearSelectedPoi() => _poiRepository.clearSelection();

  void applyFilterMode(PoiFilterMode mode) =>
      _poiRepository.applyFilterMode(mode);

  void clearFilters() => _poiRepository.clearFilters();

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
    Iterable<CityPoiCategory>? categories,
    Iterable<String>? tags,
    String? searchTerm,
  }) {
    return PoiQuery.compose(
      currentQuery: _currentQuery,
      northEast: northEast,
      southWest: southWest,
      categories: categories,
      tags: tags,
      searchTerm: searchTerm,
    );
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

  @override
  FutureOr onDispose() async {
    await _mapEventSubscription?.cancel();
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
}
