import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/events/poi_update_event.dart';
import 'package:belluga_now/domain/map/filters/main_filter_option.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_mode.dart';
import 'package:belluga_now/domain/map/map_region_definition.dart';
import 'package:belluga_now/domain/map/queries/poi_query.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/city_map_repository_contract.dart';
import 'package:belluga_now/domain/repositories/poi_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class PoiRepository implements PoiRepositoryContract {
  PoiRepository({
    CityMapRepositoryContract? dataSource,
  }) : _dataSource = dataSource ?? GetIt.I.get<CityMapRepositoryContract>();

  final CityMapRepositoryContract _dataSource;

  final allPoisStreamValue =
      StreamValue<List<CityPoiModel>>(defaultValue: const <CityPoiModel>[]);
  @override
  final filteredPoisStreamValue =
      StreamValue<List<CityPoiModel>>(defaultValue: const <CityPoiModel>[]);
  @override
  final selectedPoiStreamValue = StreamValue<CityPoiModel?>();
  @override
  final filterModeStreamValue =
      StreamValue<PoiFilterMode>(defaultValue: PoiFilterMode.none);
  PoiFilterMode _filterMode = PoiFilterMode.none;

  @override
  final filterOptionsStreamValue = StreamValue<PoiFilterOptions?>();

  @override
  final mainFilterOptionsStreamValue = StreamValue<List<MainFilterOption>>(
      defaultValue: const <MainFilterOption>[]);

  @override
  Future<List<CityPoiModel>> fetchPoints(PoiQuery query) async {
    final cityPois = await _dataSource.fetchPoints(query);
    final snapshot = List<CityPoiModel>.unmodifiable(cityPois);
    _setAllPois(snapshot);
    return snapshot;
  }

  @override
  Future<List<CityPoiModel>> fetchStackItems({
    required String stackKey,
    required PoiQuery query,
  }) {
    return _dataSource.fetchStackItems(
      query: query,
      stackKey: stackKey,
    );
  }

  @override
  Future<PoiFilterOptions> fetchFilters() async {
    final filters = await _dataSource.fetchFilters();
    filterOptionsStreamValue.addValue(filters);
    return filters;
  }

  @override
  Future<List<MainFilterOption>> fetchMainFilters() =>
      _dataSource.fetchMainFilters().then((filters) {
        mainFilterOptionsStreamValue.addValue(
          List<MainFilterOption>.unmodifiable(filters),
        );
        return filters;
      });

  Future<List<MapRegionDefinition>> fetchRegions() =>
      _dataSource.fetchRegions();

  Future<String> fetchFallbackEventImage() =>
      _dataSource.fetchFallbackEventImage();

  Stream<PoiUpdateEvent?> get poiEvents => _dataSource.poiEvents;

  @override
  CityCoordinate get defaultCenter => _dataSource.defaultCenter();

  @override
  void selectPoi(CityPoiModel? poi) {
    selectedPoiStreamValue.addValue(poi);
  }

  @override
  void clearSelection() => selectPoi(null);

  @override
  void applyFilterMode(PoiFilterMode mode) {
    if (_filterMode == mode) {
      return;
    }
    _filterMode = mode;
    filterModeStreamValue.addValue(mode);
    _recomputeFilteredPois();
    if (mode == PoiFilterMode.none) {
      clearSelection();
    }
  }

  @override
  void clearFilters() => applyFilterMode(PoiFilterMode.none);

  void _setAllPois(List<CityPoiModel> pois) {
    final snapshot = List<CityPoiModel>.unmodifiable(pois);
    allPoisStreamValue.addValue(snapshot);
    _recomputeFilteredPois(snapshot);
  }

  void _recomputeFilteredPois([List<CityPoiModel>? source]) {
    final all = source ?? allPoisStreamValue.value;
    final filtered = all;

    final snapshot = List<CityPoiModel>.unmodifiable(filtered);
    filteredPoisStreamValue.addValue(snapshot);

    if (_filterMode == PoiFilterMode.none) {
      return;
    }

    final selected = selectedPoiStreamValue.value;
    final stillContains =
        selected != null && snapshot.any((poi) => poi.id == selected.id);
    if (!stillContains) {
      if (snapshot.isEmpty) {
        clearSelection();
      } else {
        selectedPoiStreamValue.addValue(snapshot.first);
      }
    }
  }
}
