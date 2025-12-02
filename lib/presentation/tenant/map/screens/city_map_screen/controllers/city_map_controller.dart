import 'dart:async';

import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/direction_info.dart';
import 'package:belluga_now/domain/map/events/poi_update_event.dart';
import 'package:belluga_now/domain/map/filters/main_filter_option.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/map_navigation_target.dart';
import 'package:belluga_now/domain/map/map_region_definition.dart';
import 'package:belluga_now/domain/map/map_status.dart';
import 'package:belluga_now/domain/map/ride_share_option.dart';
import 'package:belluga_now/domain/map/ride_share_provider.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/repositories/city_map_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/share/share_payload.dart';
import 'package:belluga_now/infrastructure/services/dal/datasources/poi_query.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:intl/intl.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class CityMapController implements Disposable {
  CityMapController({
    CityMapRepositoryContract? repository,
    ScheduleRepositoryContract? scheduleRepository,
  })  : _repository = repository ?? GetIt.I.get<CityMapRepositoryContract>(),
        _scheduleRepository =
            scheduleRepository ?? GetIt.I.get<ScheduleRepositoryContract>(),
        eventsStreamValue =
            StreamValue<List<EventModel>>(defaultValue: const []) {
    _poiEventsSubscription = _repository.poiEvents.listen(_handlePoiEvent);
  }

  final CityMapRepositoryContract _repository;
  final ScheduleRepositoryContract _scheduleRepository;

  final StreamValue<List<EventModel>> eventsStreamValue;

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
  final userLocationStreamValue = StreamValue<CityCoordinate?>();
  final mapStatusStreamValue =
      StreamValue<MapStatus>(defaultValue: MapStatus.locating);
  final statusMessageStreamValue = StreamValue<String?>();
  final searchTermStreamValue = StreamValue<String?>();
  final TextEditingController searchInputController = TextEditingController();
  final MapController mapController = MapController();

  final selectedPoiStreamValue = StreamValue<CityPoiModel?>();
  final selectedEventStreamValue = StreamValue<EventModel?>();
  final mapNavigationTarget = StreamValue<MapNavigationTarget?>();

  final hoveredPoiIdStreamValue = StreamValue<String?>();
  final regionsStreamValue =
      StreamValue<List<MapRegionDefinition>>(defaultValue: const []);

  List<MapRegionDefinition> get regions =>
      List<MapRegionDefinition>.unmodifiable(regionsStreamValue.value);

  CityCoordinate get defaultCenter => _repository.defaultCenter();

  PoiQuery _currentQuery = const PoiQuery();
  PoiQuery? _previousQueryBeforeMainFilter;
  Set<CityPoiCategory>? _previousSelectedCategories;
  Set<String>? _previousSelectedTags;

  bool _hasRequestedPois = false;
  bool _eventsLoaded = false;
  StreamSubscription<PoiUpdateEvent?>? _poiEventsSubscription;
  bool _filtersLoadFailed = false;
  String? _fallbackEventImage;

  Future<void> initialize() async {
    await Future.wait([
      loadMainFilters(),
      loadFilters(),
      loadRegions(),
      _loadFallbackAssets(),
    ]);

    if (!_eventsLoaded) {
      await _loadEventsForDate(_today);
      _eventsLoaded = true;
    }
  }

  Future<void> loadFilters() async {
    if (filterOptionsStreamValue.value != null && !_filtersLoadFailed) {
      return;
    }
    try {
      final options = await _repository.fetchFilters();
      _filtersLoadFailed = false;
      filterOptionsStreamValue.addValue(options);
    } catch (error) {
      debugPrint('Failed to load POI filters: $error');
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

  Future<void> loadRegions() async {
    final current = regionsStreamValue.value;
    if (current.isNotEmpty) {
      return;
    }
    try {
      final regions = await _repository.fetchRegions();
      regionsStreamValue.addValue(
        List<MapRegionDefinition>.unmodifiable(regions),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to load regions: $error');
      debugPrintStack(stackTrace: stackTrace);
      regionsStreamValue.addValue(const <MapRegionDefinition>[]);
    }
  }

  Future<void> _loadFallbackAssets() async {
    if (_fallbackEventImage != null) {
      return;
    }
    try {
      _fallbackEventImage = await _repository.fetchFallbackEventImage();
    } catch (error, stackTrace) {
      debugPrint('Failed to load fallback assets: $error');
      debugPrintStack(stackTrace: stackTrace);
      _fallbackEventImage = null;
    }
  }

  String? get fallbackEventImage => _fallbackEventImage;

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
      final fetchedPois = await _repository.fetchPoints(query);
      _setSuccessState(fetchedPois);
      _setMapStatus(MapStatus.ready);
      _setMapMessage(null);
    } catch (_) {
      const errorMessage = 'Nao foi possivel carregar os pontos de interesse.';
      _setErrorState(errorMessage);
      _setMapStatus(MapStatus.error);
      _setMapMessage(errorMessage);
    }
  }

  void selectPoi(CityPoiModel? poi) {
    selectedPoiStreamValue.addValue(poi);
  }

  void selectEvent(EventModel? event) {
    selectedEventStreamValue.addValue(event);
  }

  void setHoveredPoi(String? poiId) {
    hoveredPoiIdStreamValue.addValue(poiId);
  }

  void clearSelections() {
    selectPoi(null);
    selectEvent(null);
    setHoveredPoi(null);
  }

  Future<void> searchPois(String query) async {
    final nextQuery = _composeQuery(searchTerm: query);
    await loadPois(nextQuery, loadingMessage: 'Buscando pontos...');
  }

  Future<void> clearSearch() async {
    final query = _composeQuery(searchTerm: '');
    await loadPois(query, loadingMessage: 'Carregando pontos...');
  }

  Future<void> goToRegion(MapRegionDefinition region) async {
    final delta = region.boundsDelta;
    final ne = CityCoordinate(
      latitudeValue: LatitudeValue()
        ..parse((region.center.latitude + delta).toString()),
      longitudeValue: LongitudeValue()
        ..parse((region.center.longitude + delta).toString()),
    );
    final sw = CityCoordinate(
      latitudeValue: LatitudeValue()
        ..parse((region.center.latitude - delta).toString()),
      longitudeValue: LongitudeValue()
        ..parse((region.center.longitude - delta).toString()),
    );

    final query = _composeQuery(
      northEast: ne,
      southWest: sw,
    );
    await loadPois(
      query,
      loadingMessage: 'Carregando regiao ${region.label}...',
    );
    mapNavigationTarget.addValue(
      MapNavigationTarget(center: region.center, zoom: region.zoom),
    );
  }

  Future<void> resolveUserLocation() async {
    _setMapStatus(MapStatus.locating);
    _setMapMessage('Localizando voce...');
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setMapStatus(MapStatus.error);
        _setMapMessage(
            'Ative os servicos de localizacao para ver sua posicao. Exibindo pontos padrao da cidade.');
        await _fallbackLoadPois();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _setMapStatus(MapStatus.error);
        _setMapMessage(
            'Permita o acesso a localizacao para localizar pontos proximos. Exibindo pontos padrao da cidade.');
        await _fallbackLoadPois();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      final coordinate = CityCoordinate(
        latitudeValue: LatitudeValue()..parse(position.latitude.toString()),
        longitudeValue: LongitudeValue()..parse(position.longitude.toString()),
      );

      userLocationStreamValue.addValue(coordinate);

      await loadPois(
        _queryForOrigin(coordinate),
        loadingMessage: 'Buscando pontos proximos...',
      );
      await initialize();
      _hasRequestedPois = true;
      mapNavigationTarget.addValue(
        MapNavigationTarget(center: coordinate, zoom: 16),
      );
    } on PlatformException catch (error) {
      _setMapStatus(MapStatus.error);
      _setMapMessage(
          'Nao foi possivel obter a localizacao (${error.code}). Exibindo pontos padrao da cidade.');
      await _fallbackLoadPois();
    } catch (_) {
      _setMapStatus(MapStatus.error);
      _setMapMessage(
          'Nao foi possivel obter a localizacao. Exibindo pontos padrao da cidade.');
      await _fallbackLoadPois();
    }
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

  MainFilterOption? get activeMainFilter => activeMainFilterStreamValue.value;

  bool get hasActiveMainFilter => activeMainFilterStreamValue.value != null;

  CityCoordinate? get userLocation => userLocationStreamValue.value;

  Future<void> applyMainFilter(MainFilterOption option) async {
    if (option.opensPanel) {
      activeMainFilterStreamValue.addValue(option);
      return;
    }

    final currentMainFilter = activeMainFilterStreamValue.value;

    if (currentMainFilter != null && currentMainFilter.id != option.id) {
      await clearMainFilter();
    }

    if (currentMainFilter?.id == option.id) {
      await clearMainFilter();
      return;
    }

    _previousQueryBeforeMainFilter = _currentQuery;
    _previousSelectedCategories =
        Set<CityPoiCategory>.from(selectedCategories.value);
    _previousSelectedTags = Set<String>.from(selectedTags.value);

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
    await loadPois(query, loadingMessage: 'Carregando pontos...');
  }

  Future<void> clearMainFilter() async {
    if (activeMainFilterStreamValue.value == null) {
      return;
    }

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

    final fallbackQuery = _previousQueryBeforeMainFilter ?? const PoiQuery();
    _previousQueryBeforeMainFilter = null;
    _previousSelectedCategories = null;
    _previousSelectedTags = null;

    _updateActiveFilterCount();
    await loadPois(fallbackQuery, loadingMessage: 'Carregando pontos...');
  }

  Future<void> clearFilters() async {
    if (activeMainFilterStreamValue.value != null) {
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

  SharePayload buildPoiSharePayload(CityPoiModel poi) {
    final shareLines = <String>[
      poi.name,
      if (poi.description.isNotEmpty) poi.description,
      poi.address,
    ];
    final message =
        shareLines.where((line) => line.trim().isNotEmpty).join('\n');

    return SharePayload(message: message, subject: poi.name);
  }

  SharePayload buildEventSharePayload(EventModel event) {
    final lines = <String>[
      event.title.value,
      event.location.value,
    ];
    final start = event.dateTimeStart.value;
    if (start != null) {
      lines.add(
        'Inicio: ${DateFormat('dd/MM/yyyy HH:mm').format(start)}',
      );
    }

    final coordinate = event.coordinate;
    if (coordinate != null) {
      lines.add(
        'Localizacao: https://maps.google.com/?q=${coordinate.latitude},${coordinate.longitude}',
      );
    }

    final message = lines.where((line) => line.trim().isNotEmpty).join('\n');
    return SharePayload(message: message, subject: event.title.value);
  }

  Future<DirectionsInfo?> preparePoiDirections(CityPoiModel poi) {
    return _buildDirectionsInfo(
      coordinate: poi.coordinate,
      destinationName: poi.name,
    );
  }

  Future<DirectionsInfo?> prepareEventDirections(EventModel event) {
    final coordinate = event.coordinate;
    if (coordinate == null) {
      return Future.value(null);
    }

    return _buildDirectionsInfo(
      coordinate: coordinate,
      destinationName: event.title.value,
    );
  }

  Future<void> _loadEventsForDate(DateTime date) async {
    try {
      selectedEventStreamValue.addValue(null);
      final events = await _scheduleRepository.getEventsByDate(date);
      eventsStreamValue.addValue(events);
      _eventsLoaded = true;
    } catch (_) {
      eventsStreamValue.addValue(const []);
      _eventsLoaded = true;
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
      idValue: poi.idValue,
      nameValue: poi.nameValue,
      descriptionValue: poi.descriptionValue,
      addressValue: poi.addressValue,
      category: poi.category,
      coordinate: coordinate,
      priorityValue: poi.priorityValue,
      assetPathValue: poi.assetPathValue,
      isDynamic: poi.isDynamic,
      movementRadiusValue: poi.movementRadiusValue,
      tagValues: poi.tagValues,
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
    userLocationStreamValue.dispose();
    mapStatusStreamValue.dispose();
    statusMessageStreamValue.dispose();
    mapNavigationTarget.dispose();
    hoveredPoiIdStreamValue.dispose();
    regionsStreamValue.dispose();
    searchTermStreamValue.dispose();
    searchInputController.dispose();
    mapController.dispose();
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
    final options = filterOptionsStreamValue.value;
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

    await loadPois(query, loadingMessage: 'Carregando pontos...');
  }

  void _setMapStatus(MapStatus status) {
    mapStatusStreamValue.addValue(status);
  }

  void _setMapMessage(String? message) {
    statusMessageStreamValue.addValue(message);
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

  Future<void> _fallbackLoadPois() async {
    final shouldLoad = !_hasRequestedPois;
    if (shouldLoad) {
      _hasRequestedPois = true;
      await loadPois(
        const PoiQuery(),
        loadingMessage: 'Carregando pontos...',
      );
      await initialize();
    } else {
      await initialize();
    }
    _setMapStatus(MapStatus.fallback);
    _setMapMessage('Exibindo pontos padrao da cidade.');
  }

  PoiQuery _queryForOrigin(CityCoordinate origin) {
    const boundsOffset = 0.1;
    return PoiQuery(
      northEast: CityCoordinate(
        latitudeValue: LatitudeValue()
          ..parse((origin.latitude + boundsOffset).toString()),
        longitudeValue: LongitudeValue()
          ..parse((origin.longitude + boundsOffset).toString()),
      ),
      southWest: CityCoordinate(
        latitudeValue: LatitudeValue()
          ..parse((origin.latitude - boundsOffset).toString()),
        longitudeValue: LongitudeValue()
          ..parse((origin.longitude - boundsOffset).toString()),
      ),
    );
  }

  Future<DirectionsInfo?> _buildDirectionsInfo({
    required CityCoordinate coordinate,
    required String destinationName,
  }) async {
    final destination = Coords(
      coordinate.latitude,
      coordinate.longitude,
    );

    try {
      final availableMaps = await MapLauncher.installedMaps;
      final rideShareOptions =
          await _availableRideShareOptions(destination, destinationName);
      final fallbackUrl =
          _buildFallbackDirectionsUri(destination, destinationName);
      return DirectionsInfo(
        coordinate: coordinate,
        destination: destination,
        destinationName: destinationName,
        availableMaps: availableMaps,
        rideShareOptions: rideShareOptions,
        fallbackUrl: fallbackUrl,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to prepare directions for $destinationName: $error');
      debugPrintStack(stackTrace: stackTrace);
      final fallbackUrl =
          _buildFallbackDirectionsUri(destination, destinationName);
      return DirectionsInfo(
        coordinate: coordinate,
        destination: destination,
        destinationName: destinationName,
        availableMaps: const [],
        rideShareOptions: const [],
        fallbackUrl: fallbackUrl,
      );
    }
  }

  Uri _buildFallbackDirectionsUri(
    Coords destination,
    String _destinationName,
  ) {
    return Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${destination.latitude},${destination.longitude}',
    );
  }

  Future<List<RideShareOption>> _availableRideShareOptions(
    Coords destination,
    String destinationTitle,
  ) async {
    final options = <RideShareOption>[];
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
        RideShareOption(
          provider: RideShareProvider.uber,
          label: 'Uber',
          uris: uberUris,
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
        RideShareOption(
          provider: RideShareProvider.ninetyNine,
          label: '99',
          uris: ninetyNineUris,
        ),
      );
    }

    return options;
  }

  Future<bool> launchRideShareOption(RideShareOption option) {
    return _launchFirstSupportedUri(option.uris, option.label);
  }

  Future<bool> _launchFirstSupportedUri(
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
          return true;
        }
      }
    }
    debugPrint('No handler available for $providerName');
    return false;
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
