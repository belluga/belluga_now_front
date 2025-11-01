import 'dart:async';

import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/events/poi_update_event.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/city_map_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/infrastructure/services/dal/datasources/poi_query.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class CityMapController implements Disposable {
  CityMapController({
    CityMapRepositoryContract? repository,
    ScheduleRepositoryContract? scheduleRepository,
  })  : _repository = repository ?? GetIt.I.get<CityMapRepositoryContract>(),
        _scheduleRepository =
            scheduleRepository ?? GetIt.I.get<ScheduleRepositoryContract>(),
        eventsStreamValue = StreamValue<List<EventModel>?>() {
    _poiEventsSubscription = _repository.poiEvents.listen(_handlePoiEvent);
  }

  final CityMapRepositoryContract _repository;
  final ScheduleRepositoryContract _scheduleRepository;

  final StreamValue<List<EventModel>?> eventsStreamValue;

  final isLoading = StreamValue<bool>(defaultValue: false);
  final pois = StreamValue<List<CityPoiModel>>(defaultValue: const []);
  final errorMessage = StreamValue<String?>();
  final latestOffer = StreamValue<PoiOfferActivatedEvent?>();
  final filterOptionsStreamValue = StreamValue<PoiFilterOptions?>();
  final selectedCategories =
      StreamValue<Set<CityPoiCategory>>(defaultValue: <CityPoiCategory>{});
  final selectedTags = StreamValue<Set<String>>(defaultValue: <String>{});
  final activeFilterCount = StreamValue<int>(defaultValue: 0);

  final selectedPoiStreamValue = StreamValue<CityPoiModel?>();
  final selectedEventStreamValue = StreamValue<EventModel?>();

  CityCoordinate get defaultCenter => _repository.defaultCenter();

  PoiQuery _currentQuery = const PoiQuery();
  StreamSubscription<PoiUpdateEvent?>? _poiEventsSubscription;
  PoiFilterOptions? _cachedFilterOptions;
  bool _filtersLoadFailed = false;

  Future<void> initialize() async {
    await _loadEventsForDate(_today);
  }

  Future<void> loadFilters() async {
    if (filterOptionsStreamValue.value != null && !_filtersLoadFailed) {
      return;
    }
    try {
      final options = await _repository.fetchFilters();
      _cachedFilterOptions = options;
      _filtersLoadFailed = false;
      filterOptionsStreamValue.addValue(options);
    } catch (error) {
      debugPrint('Failed to load POI filters: $error');
      _cachedFilterOptions = null;
      _filtersLoadFailed = true;
      filterOptionsStreamValue.addValue(
        PoiFilterOptions(categories: const <PoiFilterCategory>[]),
      );
    }
  }

  Future<void> loadPois(PoiQuery query) async {
    _currentQuery = query;
    _setLoadingState();

    try {
      final fetchedPois = await _repository.fetchPoints(query);
      _setSuccessState(fetchedPois);
    } catch (_) {
      _setErrorState('Não foi possível carregar os pontos de interesse.');
    }
  }

  void selectPoi(CityPoiModel? poi) {
    selectedPoiStreamValue.addValue(poi);
  }

  void selectEvent(EventModel? event) {
    selectedEventStreamValue.addValue(event);
  }

  void toggleCategory(CityPoiCategory category) {
    final currentCategories = Set<CityPoiCategory>.from(
      selectedCategories.value ?? const <CityPoiCategory>{},
    );
    if (currentCategories.contains(category)) {
      currentCategories.remove(category);
    } else {
      currentCategories.add(category);
    }

    final normalized = Set<CityPoiCategory>.unmodifiable(currentCategories);
    selectedCategories.addValue(normalized);

    final allowedTags = _allowedTagsForCategories(normalized);
    final nextTags = Set<String>.from(
      selectedTags.value ?? const <String>{},
    )..removeWhere((tag) => !allowedTags.contains(tag));
    selectedTags.addValue(Set<String>.unmodifiable(nextTags));
    _updateActiveFilterCount();

    unawaited(
      _applyFilters(normalized, nextTags),
    );
  }

  void toggleTag(String tag) {
    final allowedTags = _allowedTagsForCategories(
      selectedCategories.value ?? const <CityPoiCategory>{},
    );
    if (!allowedTags.contains(tag)) {
      return;
    }

    final currentTags = Set<String>.from(
      selectedTags.value ?? const <String>{},
    );
    if (currentTags.contains(tag)) {
      currentTags.remove(tag);
    } else {
      currentTags.add(tag);
    }

    final normalized = Set<String>.unmodifiable(currentTags);
    selectedTags.addValue(normalized);
    _updateActiveFilterCount();
    unawaited(
      _applyFilters(
        selectedCategories.value ?? const <CityPoiCategory>{},
        normalized,
      ),
    );
  }

  Future<void> clearFilters() async {
    selectedCategories.addValue(
      Set<CityPoiCategory>.unmodifiable(<CityPoiCategory>{}),
    );
    selectedTags.addValue(
      Set<String>.unmodifiable(<String>{}),
    );
    _updateActiveFilterCount();
    await _applyFilters(const <CityPoiCategory>{}, const <String>{});
  }

  void sharePoi(CityPoiModel poi) {
    debugPrint('Share action triggered for ${poi.name}');
  }

  void getDirectionsToPoi(CityPoiModel poi) {
    debugPrint('Route action triggered for ${poi.name}');
  }

  Future<void> _loadEventsForDate(DateTime date) async {
    try {
      selectedEventStreamValue.addValue(null);
      final events = await _scheduleRepository.getEventsByDate(date);
      eventsStreamValue.addValue(events);
    } catch (_) {
      eventsStreamValue.addValue(const []);
    }
  }

  void _handlePoiEvent(PoiUpdateEvent? event) {
    if (event == null) {
      return;
    }

    switch (event) {
      case PoiMovedEvent(:final coordinate):
        _updatePoiCoordinate(event.poiId, coordinate);
        break;
      case PoiOfferActivatedEvent():
        final offerEvent = event;
        isLoading.addValue(false);
        errorMessage.addValue(null);
        latestOffer.addValue(offerEvent);
        break;
    }
  }

  void _updatePoiCoordinate(String poiId, CityCoordinate coordinate) {
    final currentPois = List<CityPoiModel>.from(
      pois.value ?? const <CityPoiModel>[],
    );
    final index = currentPois.indexWhere((poi) => poi.id == poiId);
    if (index == -1) {
      return;
    }
    final poi = currentPois[index];
    currentPois[index] = CityPoiModel(
      id: poi.id,
      name: poi.name,
      description: poi.description,
      address: poi.address,
      category: poi.category,
      coordinate: coordinate,
      priority: poi.priority,
      assetPath: poi.assetPath,
      isDynamic: poi.isDynamic,
      movementRadiusMeters: poi.movementRadiusMeters,
      tags: poi.tags,
    );

    pois.addValue(List<CityPoiModel>.unmodifiable(currentPois));
    errorMessage.addValue(null);
    latestOffer.addValue(null);

    if (selectedPoiStreamValue.value?.id == poiId) {
      selectedPoiStreamValue.addValue(currentPois[index]);
    }
  }

  bool get hasError => (errorMessage.value?.isNotEmpty ?? false);
  String? get currentErrorMessage => errorMessage.value;
  List<CityPoiModel> get currentPois =>
      List<CityPoiModel>.unmodifiable(
        pois.value ?? const <CityPoiModel>[],
      );

  bool get filtersLoadFailed => _filtersLoadFailed;

  PoiQuery get currentQuery => _currentQuery;

  Future<void> reload() => loadPois(_currentQuery);

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void onDispose() {
    eventsStreamValue.dispose();
    isLoading.dispose();
    pois.dispose();
    errorMessage.dispose();
    latestOffer.dispose();
    filterOptionsStreamValue.dispose();
    selectedCategories.dispose();
    selectedTags.dispose();
    selectedPoiStreamValue.dispose();
    selectedEventStreamValue.dispose();
    activeFilterCount.dispose();
    _poiEventsSubscription?.cancel();
  }

  void _setLoadingState() {
    isLoading.addValue(true);
    errorMessage.addValue(null);
    latestOffer.addValue(null);
  }

  void _setSuccessState(List<CityPoiModel> newPois) {
    isLoading.addValue(false);
    errorMessage.addValue(null);
    latestOffer.addValue(null);
    pois.addValue(List<CityPoiModel>.unmodifiable(newPois));
  }

  void _setErrorState(String message) {
    isLoading.addValue(false);
    errorMessage.addValue(message);
    latestOffer.addValue(null);
  }

  Set<String> _allowedTagsForCategories(
    Iterable<CityPoiCategory> categories,
  ) {
    final options = _cachedFilterOptions;
    if (options == null) {
      return const <String>{};
    }
    final selected = categories.toSet();
    if (selected.isEmpty) {
      return const <String>{};
    }
    return options.tagsForCategories(selected);
  }

  Future<void> _applyFilters(
    Iterable<CityPoiCategory> categories,
    Iterable<String> tags,
  ) async {
    final categorySet = categories is Set<CityPoiCategory>
        ? categories
        : categories.toSet();
    final tagSet = tags is Set<String> ? tags : tags.toSet();

    final query = PoiQuery(
      northEast: _currentQuery.northEast,
      southWest: _currentQuery.southWest,
      categories: categorySet.isEmpty ? null : categorySet,
      tags: tagSet.isEmpty ? null : tagSet.map((tag) => tag.toLowerCase()).toSet(),
    );

    await loadPois(query);
  }

  void _updateActiveFilterCount() {
    final categoryCount = selectedCategories.value?.length ?? 0;
    final tagCount = selectedTags.value?.length ?? 0;
    activeFilterCount.addValue(categoryCount + tagCount);
  }
}
