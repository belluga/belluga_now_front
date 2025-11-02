import 'dart:async';

import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/events/poi_update_event.dart';
import 'package:belluga_now/domain/map/filters/main_filter_option.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/city_map_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/infrastructure/services/dal/datasources/poi_query.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final mainFilterOptionsStreamValue =
      StreamValue<List<MainFilterOption>>(defaultValue: const []);
  final activeMainFilterStreamValue = StreamValue<MainFilterOption?>();

  final selectedPoiStreamValue = StreamValue<CityPoiModel?>();
  final selectedEventStreamValue = StreamValue<EventModel?>();
  final mapNavigationTarget = StreamValue<MapNavigationTarget?>();

  static const List<MapRegionDefinition> _regions = <MapRegionDefinition>[
    MapRegionDefinition(
      id: 'rota_ferradura',
      label: 'Rota da Ferradura',
      center: CityCoordinate(latitude: -20.6608, longitude: -40.4915),
      zoom: 14.2,
    ),
    MapRegionDefinition(
      id: 'meaipe',
      label: 'Meaípe',
      center: CityCoordinate(latitude: -20.7254, longitude: -40.5198),
      zoom: 14.0,
    ),
    MapRegionDefinition(
      id: 'setiba',
      label: 'Setiba',
      center: CityCoordinate(latitude: -20.6392, longitude: -40.4455),
      zoom: 13.6,
    ),
    MapRegionDefinition(
      id: 'nova_guarapari',
      label: 'Nova Guarapari',
      center: CityCoordinate(latitude: -20.6965, longitude: -40.5092),
      zoom: 13.8,
    ),
  ];

  List<MapRegionDefinition> get regions =>
      List<MapRegionDefinition>.unmodifiable(_regions);

  CityCoordinate get defaultCenter => _repository.defaultCenter();

  PoiQuery _currentQuery = const PoiQuery();
  MainFilterOption? _activeMainFilter;
  PoiQuery? _previousQueryBeforeMainFilter;
  Set<CityPoiCategory>? _previousSelectedCategories;
  Set<String>? _previousSelectedTags;
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

  Future<void> loadMainFilters() async {
    if (mainFilterOptionsStreamValue.value.isNotEmpty) {
      return;
    }
    try {
      final filters = await _repository.fetchMainFilters();
      mainFilterOptionsStreamValue.addValue(filters);
    } catch (error, stackTrace) {
      debugPrint('Failed to load main filters: $error');
      debugPrintStack(stackTrace: stackTrace);
      mainFilterOptionsStreamValue.addValue(const <MainFilterOption>[]);
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

  Future<void> searchPois(String query) async {
    final nextQuery = _composeQuery(searchTerm: query);
    await loadPois(nextQuery);
  }

  Future<void> clearSearch() async {
    final query = _composeQuery(searchTerm: '');
    await loadPois(query);
  }

  Future<void> goToRegion(MapRegionDefinition region) async {
    final delta = region.boundsDelta;
    final ne = CityCoordinate(
      latitude: region.center.latitude + delta,
      longitude: region.center.longitude + delta,
    );
    final sw = CityCoordinate(
      latitude: region.center.latitude - delta,
      longitude: region.center.longitude - delta,
    );

    final query = _composeQuery(
      northEast: ne,
      southWest: sw,
    );
    await loadPois(query);
    mapNavigationTarget.addValue(
      MapNavigationTarget(center: region.center, zoom: region.zoom),
    );
  }

  void toggleCategory(CityPoiCategory category) {
    final currentCategories = Set<CityPoiCategory>.from(
      selectedCategories.value,
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
      selectedTags.value,
    )..removeWhere((tag) => !allowedTags.contains(tag));
    selectedTags.addValue(Set<String>.unmodifiable(nextTags));
    _updateActiveFilterCount();

    unawaited(
      _applyFilters(normalized, nextTags),
    );
  }

  void toggleTag(String tag) {
    final allowedTags = _allowedTagsForCategories(
      selectedCategories.value,
    );
    if (!allowedTags.contains(tag)) {
      return;
    }

    final currentTags = Set<String>.from(
      selectedTags.value,
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
        selectedCategories.value,
        normalized,
      ),
    );
  }

  MainFilterOption? get activeMainFilter => _activeMainFilter;

  bool get hasActiveMainFilter => _activeMainFilter != null;

  Future<void> applyMainFilter(MainFilterOption option) async {
    if (option.opensPanel) {
      activeMainFilterStreamValue.addValue(option);
      return;
    }

    if (_activeMainFilter != null && _activeMainFilter!.id != option.id) {
      await clearMainFilter();
    }

    if (_activeMainFilter?.id == option.id) {
      await clearMainFilter();
      return;
    }

    _previousQueryBeforeMainFilter = _currentQuery;
    _previousSelectedCategories = Set<CityPoiCategory>.from(selectedCategories.value);
    _previousSelectedTags = Set<String>.from(selectedTags.value);

    _activeMainFilter = option;
    activeMainFilterStreamValue.addValue(option);

    final optionCategories = option.categories;
    if (optionCategories != null) {
      selectedCategories.addValue(
        Set<CityPoiCategory>.unmodifiable(optionCategories),
      );
    }

    final optionTags = option.tags;
    if (optionTags != null) {
      selectedTags.addValue(
        Set<String>.unmodifiable(
          optionTags.map((tag) => tag.toLowerCase()).toSet(),
        ),
      );
    }

    _updateActiveFilterCount();
    final query = _buildQueryForMainFilter(option);
    await loadPois(query);
  }

  Future<void> clearMainFilter() async {
    if (_activeMainFilter == null) {
      return;
    }

    _activeMainFilter = null;
    activeMainFilterStreamValue.addValue(null);

    if (_previousSelectedCategories != null) {
      selectedCategories.addValue(
        Set<CityPoiCategory>.unmodifiable(_previousSelectedCategories!),
      );
    }
    if (_previousSelectedTags != null) {
      selectedTags.addValue(
        Set<String>.unmodifiable(_previousSelectedTags!),
      );
    }

    final fallbackQuery =
        _previousQueryBeforeMainFilter ?? const PoiQuery();
    _previousQueryBeforeMainFilter = null;
    _previousSelectedCategories = null;
    _previousSelectedTags = null;

    _updateActiveFilterCount();
    await loadPois(fallbackQuery);
  }

  Future<void> clearFilters() async {
    if (_activeMainFilter != null) {
      _activeMainFilter = null;
      activeMainFilterStreamValue.addValue(null);
      _previousQueryBeforeMainFilter = null;
      _previousSelectedCategories = null;
      _previousSelectedTags = null;
    }

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
    final shareLines = <String>[
      poi.name,
      if (poi.description.isNotEmpty) poi.description,
      poi.address,
    ];
    final message =
        shareLines.where((line) => line.trim().isNotEmpty).join('\n');

    unawaited(_shareContent(message, poi.name));
  }

  void shareEvent(EventModel event) {
    final lines = <String>[
      event.title.value,
      event.location.value,
    ];
    final start = event.dateTimeStart.value;
    if (start != null) {
      lines.add(
        'Início: ${DateFormat('dd/MM/yyyy HH:mm').format(start)}',
      );
    }

    final message = lines.where((line) => line.trim().isNotEmpty).join('\n');
    unawaited(_shareContent(message, event.title.value));
  }

  void getDirectionsToPoi(CityPoiModel poi, BuildContext context) {
    unawaited(
      _openDirectionsToCoordinate(
        poi.coordinate,
        poi.name,
        context,
      ),
    );
  }

  void getDirectionsToEvent(EventModel event, BuildContext context) {
    final coordinate = event.coordinate;
    if (coordinate == null) {
      return;
    }

    unawaited(
      _openDirectionsToCoordinate(
        coordinate,
        event.title.value,
        context,
      ),
    );
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
      pois.value,
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
  List<CityPoiModel> get currentPois => List<CityPoiModel>.unmodifiable(
        pois.value,
      );

  bool get filtersLoadFailed => _filtersLoadFailed;

  PoiQuery get currentQuery => _currentQuery;

  String? get currentSearchTerm => _currentQuery.searchTerm;

  bool get hasActiveSearch =>
      (_currentQuery.searchTerm?.trim().isNotEmpty ?? false);

  Future<void> reload() => loadPois(_currentQuery);

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  PoiQuery _composeQuery({
    CityCoordinate? northEast,
    CityCoordinate? southWest,
    Iterable<CityPoiCategory>? categories,
    Iterable<String>? tags,
    String? searchTerm,
  }) {
    Set<CityPoiCategory>? resolvedCategories;
    if (categories == null) {
      resolvedCategories = _currentQuery.categories;
    } else if (categories.isEmpty) {
      resolvedCategories = null;
    } else {
      resolvedCategories =
          Set<CityPoiCategory>.unmodifiable(categories.toSet());
    }

    Set<String>? resolvedTags;
    if (tags == null) {
      resolvedTags = _currentQuery.tags;
    } else if (tags.isEmpty) {
      resolvedTags = null;
    } else {
      resolvedTags = Set<String>.unmodifiable(
        tags.map((tag) => tag.toLowerCase()).toSet(),
      );
    }

    final sanitizedSearch = searchTerm == null
        ? _currentQuery.searchTerm
        : (searchTerm.trim().isEmpty ? null : searchTerm.trim());

    return PoiQuery(
      northEast: northEast ?? _currentQuery.northEast,
      southWest: southWest ?? _currentQuery.southWest,
      categories: resolvedCategories,
      tags: resolvedTags,
      searchTerm: sanitizedSearch,
    );
  }

  @override
  void onDispose() {
    eventsStreamValue.dispose();
    isLoading.dispose();
    pois.dispose();
    errorMessage.dispose();
    latestOffer.dispose();
    filterOptionsStreamValue.dispose();
    mainFilterOptionsStreamValue.dispose();
    selectedCategories.dispose();
    selectedTags.dispose();
    selectedPoiStreamValue.dispose();
    selectedEventStreamValue.dispose();
    activeFilterCount.dispose();
    activeMainFilterStreamValue.dispose();
    mapNavigationTarget.dispose();
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
    final query = _composeQuery(
      categories: categories,
      tags: tags,
    );

    await loadPois(query);
  }

  PoiQuery _buildQueryForMainFilter(MainFilterOption option) {
    final baseQuery = _currentQuery;
    final categorySet = option.categories;
    final tagSet = option.tags;

    return PoiQuery(
      northEast: baseQuery.northEast,
      southWest: baseQuery.southWest,
      categories: (categorySet == null || categorySet.isEmpty)
          ? null
          : Set<CityPoiCategory>.unmodifiable(categorySet),
      tags: (tagSet == null || tagSet.isEmpty)
          ? null
          : Set<String>.unmodifiable(
              tagSet.map((tag) => tag.toLowerCase()).toSet(),
            ),
      searchTerm: baseQuery.searchTerm,
    );
  }

  Future<void> _shareContent(String message, String subject) async {
    try {
      await Share.share(message, subject: subject);
    } catch (error, stackTrace) {
      debugPrint('Failed to share content: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _openDirectionsToCoordinate(
    CityCoordinate coordinate,
    String destinationName,
    BuildContext context,
  ) async {
    final destination = Coords(
      coordinate.latitude,
      coordinate.longitude,
    );

    try {
      final availableMaps = await MapLauncher.installedMaps;
      final rideShareOptions =
          await _availableRideShareOptions(destination, destinationName);
      final totalOptions = availableMaps.length + rideShareOptions.length;

      if (totalOptions == 0) {
        await _launchFallbackDirections(destination, destinationName);
        return;
      }

      if (totalOptions == 1) {
        if (availableMaps.length == 1) {
          await availableMaps.first.showDirections(
            destination: destination,
            destinationTitle: destinationName,
          );
        } else {
          await rideShareOptions.first.launcher();
        }
        return;
      }

      final launcher = await _selectNavigationLauncher(
        context,
        availableMaps,
        rideShareOptions,
        destination,
        destinationName,
      );
      if (launcher == null) {
        return;
      }
      await launcher();
    } catch (error, stackTrace) {
      debugPrint('Failed to open directions for $destinationName: $error');
      debugPrintStack(stackTrace: stackTrace);
      await _launchFallbackDirections(destination, destinationName);
    }
  }

  Future<_NavigationLauncher?> _selectNavigationLauncher(
    BuildContext context,
    List<AvailableMap> maps,
    List<_RideShareOption> rideOptions,
    Coords destination,
    String destinationTitle,
  ) async {
    final navigator = Navigator.maybeOf(context);
    if (navigator == null || !navigator.mounted) {
      return null;
    }
    return showModalBottomSheet<_NavigationLauncher>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Escolha como chegar',
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
              ),
              for (final map in maps)
                ListTile(
                  leading: SvgPicture.asset(
                    map.icon,
                    width: 32,
                    height: 32,
                  ),
                  title: Text(map.mapName),
                  onTap: () => Navigator.of(sheetContext).pop(
                    () => map.showDirections(
                      destination: destination,
                      destinationTitle: destinationTitle,
                    ),
                  ),
                ),
              if (maps.isNotEmpty && rideOptions.isNotEmpty)
                for (final option in rideOptions)
                  ListTile(
                    leading: Icon(option.icon, size: 28),
                    title: Text(option.label),
                    onTap: () => Navigator.of(sheetContext).pop(
                      option.launcher,
                    ),
                  ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchFallbackDirections(
    Coords destination,
    String label,
  ) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${destination.latitude},${destination.longitude}',
    );
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        debugPrint('Could not launch fallback directions for $label');
      }
    } catch (error, stackTrace) {
      debugPrint('Fallback navigation failed for $label: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<List<_RideShareOption>> _availableRideShareOptions(
    Coords destination,
    String destinationTitle,
  ) async {
    final options = <_RideShareOption>[];
    final latitude = destination.latitude;
    final longitude = destination.longitude;
    final encodedTitle = Uri.encodeComponent(destinationTitle);

    final uberUris = <Uri>[
      Uri.parse(
        'uber://?action=setPickup'
        '&dropoff[latitude]=$latitude'
        '&dropoff[longitude]=$longitude'
        '&dropoff[nickname]=$encodedTitle',
      ),
      Uri.parse(
        'https://m.uber.com/ul/?action=setPickup'
        '&dropoff[latitude]=$latitude'
        '&dropoff[longitude]=$longitude'
        '&dropoff[nickname]=$encodedTitle',
      ),
    ];

    if (await _hasAnyLaunchHandler(uberUris)) {
      options.add(
        _RideShareOption(
          label: 'Uber',
          icon: Icons.local_taxi,
          launcher: () => _launchFirstSupportedUri(uberUris, 'Uber'),
        ),
      );
    }

    final ninetyNineUris = <Uri>[
      Uri.parse(
        'ninetynine://ride?dropoff_latitude=$latitude'
        '&dropoff_longitude=$longitude'
        '&dropoff_title=$encodedTitle',
      ),
      Uri.parse(
        'ninety-nine://ride?dropoff_latitude=$latitude'
        '&dropoff_longitude=$longitude'
        '&dropoff_title=$encodedTitle',
      ),
      Uri.parse(
        'ninety9://ride?dropoff_latitude=$latitude'
        '&dropoff_longitude=$longitude'
        '&dropoff_title=$encodedTitle',
      ),
      Uri.parse(
        'https://app.99app.com/open?deep_link_value=ride'
        '&dropoff_latitude=$latitude'
        '&dropoff_longitude=$longitude'
        '&dropoff_title=$encodedTitle',
      ),
    ];

    if (await _hasAnyLaunchHandler(ninetyNineUris)) {
      options.add(
        _RideShareOption(
          label: '99',
          icon: Icons.local_taxi_outlined,
          launcher: () => _launchFirstSupportedUri(ninetyNineUris, '99'),
        ),
      );
    }

    return options;
  }

  Future<void> _launchFirstSupportedUri(
    List<Uri> uris,
    String providerName,
  ) async {
    for (final uri in uris) {
      if (await _safeCanLaunch(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) {
          return;
        }
      }
    }
    debugPrint('No handler available for $providerName');
  }

  Future<bool> _hasAnyLaunchHandler(List<Uri> uris) async {
    for (final uri in uris) {
      if (await _safeCanLaunch(uri)) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _safeCanLaunch(Uri uri) async {
    try {
      return await canLaunchUrl(uri);
    } catch (error, stackTrace) {
      debugPrint('canLaunchUrl failed for $uri: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  void _updateActiveFilterCount() {
    final categoryCount = selectedCategories.value.length;
    final tagCount = selectedTags.value.length;
    activeFilterCount.addValue(categoryCount + tagCount);
  }
}

typedef _NavigationLauncher = Future<void> Function();

class MapRegionDefinition {
  const MapRegionDefinition({
    required this.id,
    required this.label,
    required this.center,
    required this.zoom,
    this.boundsDelta = 0.08,
  });

  final String id;
  final String label;
  final CityCoordinate center;
  final double zoom;
  final double boundsDelta;
}

class MapNavigationTarget {
  const MapNavigationTarget({
    required this.center,
    required this.zoom,
  });

  final CityCoordinate center;
  final double zoom;
}

class _RideShareOption {
  const _RideShareOption({
    required this.label,
    required this.icon,
    required this.launcher,
  });

  final String label;
  final IconData icon;
  final _NavigationLauncher launcher;
}




