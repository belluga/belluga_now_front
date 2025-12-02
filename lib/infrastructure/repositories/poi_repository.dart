import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/event_poi_model.dart';
import 'package:belluga_now/domain/map/events/poi_update_event.dart';
import 'package:belluga_now/domain/map/filters/main_filter_option.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/map_region_definition.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/city_map_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/infrastructure/services/dal/datasources/poi_query.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

enum PoiFilterMode { none, events, restaurants, beaches, lodging }

class PoiRepository {
  PoiRepository({
    CityMapRepositoryContract? dataSource,
    ScheduleRepositoryContract? scheduleRepository,
  })  : _dataSource = dataSource ?? GetIt.I.get<CityMapRepositoryContract>(),
        _scheduleRepository =
            scheduleRepository ?? GetIt.I.get<ScheduleRepositoryContract>();

  final CityMapRepositoryContract _dataSource;
  final ScheduleRepositoryContract _scheduleRepository;

  final allPoisStreamValue =
      StreamValue<List<CityPoiModel>>(defaultValue: const <CityPoiModel>[]);
  final filteredPoisStreamValue =
      StreamValue<List<CityPoiModel>>(defaultValue: const <CityPoiModel>[]);
  final selectedPoiStreamValue = StreamValue<CityPoiModel?>();
  final filterModeStreamValue =
      StreamValue<PoiFilterMode>(defaultValue: PoiFilterMode.none);
  PoiFilterMode _filterMode = PoiFilterMode.none;

  final filterOptionsStreamValue = StreamValue<PoiFilterOptions?>();

  final mainFilterOptionsStreamValue = StreamValue<List<MainFilterOption>>(
      defaultValue: const <MainFilterOption>[]);

  Future<List<CityPoiModel>> fetchPoints(PoiQuery query) async {
    final cityPoisFuture = _dataSource.fetchPoints(query);
    final eventPoisFuture = _fetchEventPois(query);

    List<CityPoiModel> cityPois;
    List<CityPoiModel> eventPois;

    cityPois = await cityPoisFuture;
    eventPois = await eventPoisFuture;

    final combined = <CityPoiModel>[
      ...cityPois,
      ...eventPois,
    ]..sort((a, b) => a.priority.compareTo(b.priority));

    final snapshot = List<CityPoiModel>.unmodifiable(combined);
    _setAllPois(snapshot);
    return snapshot;
  }

  Future<PoiFilterOptions> fetchFilters() async {
    final filters = await _dataSource.fetchFilters();
    filterOptionsStreamValue.addValue(filters);
    return filters;
  }

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

  CityCoordinate get defaultCenter => _dataSource.defaultCenter();

  void selectPoi(CityPoiModel? poi) {
    selectedPoiStreamValue.addValue(poi);
  }

  void clearSelection() => selectPoi(null);

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

  void clearFilters() => applyFilterMode(PoiFilterMode.none);

  void _setAllPois(List<CityPoiModel> pois) {
    final snapshot = List<CityPoiModel>.unmodifiable(pois);
    allPoisStreamValue.addValue(snapshot);
    _recomputeFilteredPois(snapshot);
  }

  void _recomputeFilteredPois([List<CityPoiModel>? source]) {
    final all = source ?? allPoisStreamValue.value;
    List<CityPoiModel> filtered;
    switch (_filterMode) {
      case PoiFilterMode.events:
        filtered = all.where((poi) => poi.isDynamic).toList(growable: false);
        break;
      case PoiFilterMode.restaurants:
        filtered = all
            .where((poi) => poi.category == CityPoiCategory.restaurant)
            .toList(growable: false);
        break;
      case PoiFilterMode.beaches:
        filtered = all
            .where((poi) => poi.category == CityPoiCategory.beach)
            .toList(growable: false);
        break;
      case PoiFilterMode.lodging:
        filtered = all
            .where((poi) => poi.category == CityPoiCategory.lodging)
            .toList(growable: false);
        break;
      case PoiFilterMode.none:
        filtered = all;
        break;
    }

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

  Future<List<CityPoiModel>> _fetchEventPois(PoiQuery query) async {
    try {
      final events = await _scheduleRepository.getAllEvents();
      final today = DateTime.now();
      return events
          .where((event) {
            final start = event.dateTimeStart.value;
            if (start == null) {
              return false;
            }
            final localStart = start.toLocal();
            return localStart.year == today.year &&
                localStart.month == today.month &&
                localStart.day == today.day;
          })
          .where(_eventHasCoordinate)
          .map(EventPoiModel.fromEvent)
          .where((poi) => _matchesQuery(poi, query))
          .toList(growable: false);
    } catch (error, stackTrace) {
      debugPrint('PoiRepository -> failed to load event POIs: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const <CityPoiModel>[];
    }
  }

  bool _eventHasCoordinate(EventModel event) => event.coordinate != null;

  bool _matchesQuery(CityPoiModel poi, PoiQuery query) {
    final searchTerm = query.searchTerm?.trim().toLowerCase();
    if (searchTerm != null && searchTerm.isNotEmpty) {
      final matchesText = _containsSearchableText(poi, searchTerm);
      if (!matchesText) {
        return false;
      }
    }

    if (!query.matchesCategory(poi.category)) {
      return false;
    }
    if (!query.matchesTags(poi.tags)) {
      return false;
    }
    return query.containsCoordinate(poi.coordinate);
  }

  bool _containsSearchableText(CityPoiModel poi, String searchTerm) {
    final normalizedName = poi.name.toLowerCase();
    final normalizedDescription = poi.description.toLowerCase();
    final normalizedAddress = poi.address.toLowerCase();
    final hasTagMatch = poi.tags.any(
      (tag) => tag.toLowerCase().contains(searchTerm),
    );

    return normalizedName.contains(searchTerm) ||
        normalizedDescription.contains(searchTerm) ||
        normalizedAddress.contains(searchTerm) ||
        hasTagMatch;
  }
}
