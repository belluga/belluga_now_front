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
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  final isFilterVisible = StreamValue<bool>(defaultValue: false);

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
    final shareLines = <String>[
      poi.name,
      if (poi.description.isNotEmpty) poi.description,
      poi.address,
    ];
    final message =
        shareLines.where((line) => line.trim().isNotEmpty).join('\n');

    unawaited(_sharePoi(message, poi.name));
  }

  void getDirectionsToPoi(CityPoiModel poi, BuildContext context) {
    unawaited(_openDirections(poi, context));
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
  List<CityPoiModel> get currentPois => List<CityPoiModel>.unmodifiable(
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
    final categorySet =
        categories is Set<CityPoiCategory> ? categories : categories.toSet();
    final tagSet = tags is Set<String> ? tags : tags.toSet();

    final query = PoiQuery(
      northEast: _currentQuery.northEast,
      southWest: _currentQuery.southWest,
      categories: categorySet.isEmpty ? null : categorySet,
      tags: tagSet.isEmpty
          ? null
          : tagSet.map((tag) => tag.toLowerCase()).toSet(),
    );

    await loadPois(query);
  }

  Future<void> _sharePoi(String message, String subject) async {
    try {
      await Share.share(message, subject: subject);
    } catch (error, stackTrace) {
      debugPrint('Failed to share POI: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _openDirections(
    CityPoiModel poi,
    BuildContext context,
  ) async {
    final coordinate = poi.coordinate;
    final destination = Coords(
      coordinate.latitude,
      coordinate.longitude,
    );

    try {
      final availableMaps = await MapLauncher.installedMaps;
      final rideShareOptions =
          await _availableRideShareOptions(destination, poi.name);
      final totalOptions = availableMaps.length + rideShareOptions.length;

      if (totalOptions == 0) {
        await _launchFallbackDirections(destination, poi.name);
        return;
      }

      if (totalOptions == 1) {
        if (availableMaps.length == 1) {
          await availableMaps.first.showDirections(
            destination: destination,
            destinationTitle: poi.name,
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
        poi.name,
      );
      if (launcher == null) {
        return;
      }
      await launcher();
    } catch (error, stackTrace) {
      debugPrint('Failed to open directions for ${poi.name}: $error');
      debugPrintStack(stackTrace: stackTrace);
      await _launchFallbackDirections(destination, poi.name);
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
    final categoryCount = selectedCategories.value?.length ?? 0;
    final tagCount = selectedTags.value?.length ?? 0;
    activeFilterCount.addValue(categoryCount + tagCount);
  }
}

typedef _NavigationLauncher = Future<void> Function();

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
