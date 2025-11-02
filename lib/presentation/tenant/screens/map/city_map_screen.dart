import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/manual_route_stubs.dart';
import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/screens/map/controller/city_map_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/event_info_card.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/event_marker.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/event_temporal_state.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/location_status_banner.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/poi_info_card.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/poi_marker.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/user_location_marker.dart';
import 'package:belluga_now/presentation/tenant/widgets/event_details.dart';
import 'package:belluga_now/presentation/view_models/event_card_data.dart';
import 'package:belluga_now/domain/map/filters/main_filter_option.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:free_map/fm_map.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:intl/intl.dart';
import 'package:belluga_now/infrastructure/services/dal/datasources/poi_query.dart';

class CityMapScreen extends StatefulWidget {
  const CityMapScreen({super.key});

  @override
  State<CityMapScreen> createState() => _CityMapScreenState();
}

class _CityMapScreenState extends State<CityMapScreen> {
  final _mapController = MapController();
  final _controller = GetIt.I.get<CityMapController>();

  String? _hoveredPoiId;
  bool _isFilterFabMenuOpen = false;
  StreamSubscription<MapNavigationTarget?>? _navigationSubscription;
  LatLng? _userPosition;
  bool _hasRequestedPois = false;
  bool _eventsLoaded = false;
  _MapStatus _status = _MapStatus.locating;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_controller.loadMainFilters());
    unawaited(_controller.loadFilters());
    unawaited(_controller.initialize());
    _navigationSubscription =
        _controller.mapNavigationTarget.stream.listen((target) {
      if (target == null) {
        return;
      }
      final center = LatLng(
        target.center.latitude,
        target.center.longitude,
      );
      _mapController.move(center, target.zoom);
    });
    unawaited(_resolveUserLocation());
  }

  @override
  void dispose() {
    _navigationSubscription?.cancel();
    _controller.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultCenter = _controller.defaultCenter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Guarapari'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Buscar pontos',
            onPressed: _openSearchDialog,
          ),
          if (_controller.hasActiveSearch)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Limpar busca',
              onPressed: _handleClearSearch,
            ),
          StreamValueBuilder<CityCoordinate?>(
            streamValue: _controller.userLocationStreamValue,
            builder: (context, coordinate) {
              final userCoordinate = coordinate;
              return IconButton(
                icon: const Icon(Icons.my_location_outlined),
                tooltip: 'Centralizar na minha posicao',
                onPressed: userCoordinate == null
                    ? null
                    : () => _centerOnUser(userCoordinate),
              );
            },
          ),
        ],
      ),
      body: StreamValueBuilder<CityCoordinate?>(
        streamValue: _controller.userLocationStreamValue,
        builder: (context, coordinate) {
          return _buildMapArea(theme, defaultCenter, coordinate);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _buildMainFilterFabGroup(theme),
    );
  }

  Widget _buildMainFilterFabGroup(ThemeData theme) {
    return StreamValueBuilder<List<MainFilterOption>>(
      streamValue: _controller.mainFilterOptionsStreamValue,
      builder: (context, options) {
        final filters = options;
        return StreamValueBuilder<MainFilterOption?>(
          streamValue: _controller.activeMainFilterStreamValue,
          builder: (context, activeFilter) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_isFilterFabMenuOpen)
                  ...filters.reversed.map(
                    (option) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildSecondaryFilterFab(
                        theme: theme,
                        option: option,
                        activeFilter: activeFilter,
                      ),
                    ),
                  ),
                FloatingActionButton(
                  heroTag: 'main-filter-toggle-fab',
                  onPressed: _toggleMainFilterMenu,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _isFilterFabMenuOpen ? Icons.close : Icons.filter_list,
                      key: ValueKey<bool>(_isFilterFabMenuOpen),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSecondaryFilterFab({
    required ThemeData theme,
    required MainFilterOption option,
    required MainFilterOption? activeFilter,
  }) {
    final icon = _iconForMainFilter(option);
    final isActive = option.isQuickApply &&
        activeFilter != null &&
        activeFilter.id == option.id;
    final backgroundColor = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.surface;
    final foregroundColor = isActive
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return Tooltip(
      message: option.label,
      child: FloatingActionButton.small(
        heroTag: 'main-filter-${option.id}',
        backgroundColor: backgroundColor,
        onPressed: () => _onMainFilterTap(option),
        child: Icon(icon, color: foregroundColor),
      ),
    );
  }

  void _toggleMainFilterMenu() {
    setState(() {
      _isFilterFabMenuOpen = !_isFilterFabMenuOpen;
    });
  }

  IconData _iconForMainFilter(MainFilterOption option) {
    switch (option.iconName) {
      case 'local_offer':
        return Icons.local_offer;
      case 'event':
        return Icons.event;
      case 'music_note':
        return Icons.music_note;
      case 'map':
        return Icons.map;
      case 'restaurant':
        return Icons.restaurant;
      default:
        return Icons.filter_alt;
    }
  }

  Future<void> _onMainFilterTap(MainFilterOption option) async {
    if (option.opensPanel) {
      setState(() {
        _isFilterFabMenuOpen = false;
      });

      switch (option.type) {
        case MainFilterType.events:
          await _openEventFilterSheet();
          break;
        case MainFilterType.music:
          await _openEventFilterSheet(musicOnly: true);
          break;
        case MainFilterType.regions:
          await _openRegionPicker();
          break;
        case MainFilterType.cuisines:
          await _openCuisinePanel();
          break;
        case MainFilterType.promotions:
          break;
      }
      return;
    }

    await _controller.applyMainFilter(option);
    if (!mounted) return;
    setState(() {
      _isFilterFabMenuOpen = false;
    });
  }

  Future<void> _openEventFilterSheet({bool musicOnly = false}) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        musicOnly ? Icons.music_note : Icons.event,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        musicOnly ? 'Eventos musicais' : 'Eventos',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamValueBuilder<List<EventModel>?>(
                      streamValue: _controller.eventsStreamValue,
                      builder: (context, events) {
                        final allEvents = events ?? const <EventModel>[];
                        final filtered = musicOnly
                            ? allEvents.where(
                                (event) =>
                                    event.type.slug.value.toLowerCase() ==
                                    'show',
                              )
                            : allEvents;
                        final items = filtered.toList(growable: false);
                        if (items.isEmpty) {
                          return Center(
                            child: Text(
                              musicOnly
                                  ? 'Nenhum evento musical disponivel.'
                                  : 'Nenhum evento disponivel no momento.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final event = items[index];
                            final start = event.dateTimeStart.value;
                            final subtitle = start != null
                                ? DateFormat('dd/MM • HH:mm').format(start)
                                : 'Horario a definir';
                            return ListTile(
                              title: Text(event.title.value),
                              subtitle: Text(
                                '${event.location.value} • $subtitle',
                              ),
                              trailing:
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                Navigator.of(context).pop();
                                _controller.selectEvent(event);
                                final coordinate = event.coordinate;
                                if (coordinate != null) {
                                  _mapController.move(
                                    LatLng(
                                      coordinate.latitude,
                                      coordinate.longitude,
                                    ),
                                    16,
                                  );
                                }
                              },
                              onLongPress: () {
                                Navigator.of(context).pop();
                                _openEventDetails(event);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openRegionPicker() async {
    final selected = await showModalBottomSheet<MapRegionDefinition>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemBuilder: (context, index) {
              final region = _controller.regions[index];
              return ListTile(
                leading: const Icon(Icons.place_outlined),
                title: Text(region.label),
                onTap: () => Navigator.of(context).pop(region),
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: _controller.regions.length,
          ),
        );
      },
    );

    if (selected != null) {
      await _handleRegionTap(selected);
    }
  }

  Future<void> _openCuisinePanel() async {
    await _controller.loadFilters();
    if (!mounted) return;
    final options = _controller.filterOptionsStreamValue.value;
    PoiFilterCategory? restaurantCategory;
    if (options != null) {
      for (final option in options.categories) {
        if (option.category == CityPoiCategory.restaurant) {
          restaurantCategory = option;
          break;
        }
      }
    }

    if (restaurantCategory == null || restaurantCategory.tags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum filtro de gastronomia disponivel.'),
        ),
      );
      return;
    }

    final selectedCategoriesValue = _controller.selectedCategories.value;
    final hasRestaurantSelected =
        selectedCategoriesValue.contains(CityPoiCategory.restaurant);
    if (!hasRestaurantSelected) {
      _controller.toggleCategory(CityPoiCategory.restaurant);
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final tags = restaurantCategory!.tags.toList()..sort();
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.restaurant, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Gastronomia',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StreamValueBuilder<Set<String>>(
                  streamValue: _controller.selectedTags,
                  builder: (context, selectedTags) {
                    final current = selectedTags;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in tags)
                          FilterChip(
                            label: Text(_formatTag(tag)),
                            selected: current.contains(tag),
                            onSelected: (_) => _controller.toggleTag(tag),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTag(String tag) {
    if (tag.isEmpty) {
      return tag;
    }
    if (tag.length == 1) {
      return tag.toUpperCase();
    }
    return tag[0].toUpperCase() + tag.substring(1);
  }

  Future<void> _openSearchDialog() async {
    final initialTerm = _controller.currentSearchTerm ?? '';
    final textController = TextEditingController(text: initialTerm);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Buscar pontos'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Digite um termo para buscar',
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(textController.text),
              child: const Text('Buscar'),
            ),
          ],
        );
      },
    );
    final query = result?.trim() ?? '';
    textController.dispose();
    if (!mounted || result == null) {
      return;
    }
    if (query.isEmpty) {
      await _handleClearSearch();
      return;
    }
    setState(() {
      _status = _MapStatus.fetching;
      _statusMessage = 'Buscando pontos...';
    });
    await _controller.searchPois(query);
    if (!mounted) return;
    _updateStatusFromState();
  }

  Future<void> _handleClearSearch() async {
    setState(() {
      _status = _MapStatus.fetching;
      _statusMessage = 'Carregando pontos...';
    });
    await _controller.clearSearch();
    if (!mounted) return;
    _updateStatusFromState();
  }

  Future<void> _handleRegionTap(MapRegionDefinition region) async {
    setState(() {
      _status = _MapStatus.fetching;
      _statusMessage = 'Carregando regiao ${region.label}...';
    });
    await _controller.goToRegion(region);
    if (!mounted) return;
    final target = LatLng(
      region.center.latitude,
      region.center.longitude,
    );
    _mapController.move(target, region.zoom);
    _updateStatusFromState();
  }

  Widget _buildMapArea(
    ThemeData theme,
    CityCoordinate defaultCenter,
    CityCoordinate? userCoordinate,
  ) {
    final LatLng? userPosition;
    if (userCoordinate != null) {
      userPosition = LatLng(
        userCoordinate.latitude,
        userCoordinate.longitude,
      );
      _userPosition = userPosition;
    } else {
      userPosition = _userPosition;
    }

    return StreamValueBuilder<List<CityPoiModel>>(
      streamValue: _controller.pois,
      onNullWidget: const Center(child: CircularProgressIndicator()),
      builder: (context, poiStreamValue) {
        final poiList = poiStreamValue;
        return StreamValueBuilder<List<EventModel>?>(
          streamValue: _controller.eventsStreamValue,
          builder: (context, events) {
            final eventList = events ?? const <EventModel>[];
            return StreamValueBuilder<EventModel?>(
              streamValue: _controller.selectedEventStreamValue,
              builder: (context, selectedEvent) {
                return StreamValueBuilder<CityPoiModel?>(
                  streamValue: _controller.selectedPoiStreamValue,
                  builder: (context, selectedPoi) {
                    return Stack(
                      children: [
                        _CityMapView(
                          mapController: _mapController,
                          pois: poiList,
                          selectedPoi: selectedPoi,
                          onSelectPoi: (poi) {
                            _controller.selectPoi(poi);
                            _controller.selectEvent(null);
                          },
                          hoveredPoiId: _hoveredPoiId,
                          onHoverChange: _handlePoiHover,
                          events: eventList,
                          selectedEvent: selectedEvent,
                          onSelectEvent: (event) {
                            _controller.selectEvent(event);
                            _controller.selectPoi(null);
                          },
                          userPosition: userPosition,
                          defaultCenter: LatLng(
                            defaultCenter.latitude,
                            defaultCenter.longitude,
                          ),
                          onMapInteraction: _handleMapInteraction,
                        ),
                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: _buildStatusBanner(theme),
                        ),
                        StreamValueBuilder<bool>(
                          streamValue: _controller.isLoading,
                          builder: (context, isLoading) {
                            if (isLoading == true) {
                              return const Positioned.fill(
                                child: IgnorePointer(
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        StreamValueBuilder<String?>(
                          streamValue: _controller.errorMessage,
                          builder: (context, error) {
                            if (error == null) {
                              return const SizedBox.shrink();
                            }
                            return Positioned(
                              bottom: 24,
                              left: 24,
                              right: 24,
                              child: SafeArea(
                                child: Card(
                                  color: theme.colorScheme.errorContainer,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      error,
                                      style: TextStyle(
                                        color: theme.colorScheme.onErrorContainer,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        if (selectedEvent != null)
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                              child: SafeArea(
                                child: EventInfoCard(
                                  event: selectedEvent,
                                  onDismiss: () => _controller.selectEvent(null),
                                  onDetails: () => _openEventDetails(selectedEvent),
                                  onShare: () => _controller.shareEvent(selectedEvent),
                                  onRoute: selectedEvent.coordinate == null
                                      ? null
                                      : () => _controller.getDirectionsToEvent(
                                            selectedEvent,
                                            context,
                                          ),
                                ),
                              ),
                            ),
                          )
                        else if (selectedPoi != null)
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                              child: SafeArea(
                                child: PoiInfoCard(
                                  poi: selectedPoi,
                                  onDismiss: () => _controller.selectPoi(null),
                                  onDetails: () => _openPoiDetails(selectedPoi),
                                  onShare: () => _controller.sharePoi(selectedPoi),
                                  onRoute: () => _controller.getDirectionsToPoi(
                                    selectedPoi,
                                    context,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
  Widget _buildStatusBanner(ThemeData theme) {
    if (_statusMessage == null) {
      return const SizedBox.shrink();
    }

    late final Color background;
    late final Color textColor;
    late final IconData icon;

    switch (_status) {
      case _MapStatus.locating:
        background = theme.colorScheme.surfaceContainerHigh;
        textColor = theme.colorScheme.onSurfaceVariant;
        icon = Icons.hourglass_bottom;
        break;
      case _MapStatus.fetching:
        background = theme.colorScheme.secondaryContainer;
        textColor = theme.colorScheme.onSecondaryContainer;
        icon = Icons.explore_outlined;
        break;
      case _MapStatus.fallback:
        background = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurfaceVariant;
        icon = Icons.location_off_outlined;
        break;
      case _MapStatus.error:
        background = theme.colorScheme.errorContainer;
        textColor = theme.colorScheme.onErrorContainer;
        icon = Icons.warning_amber_rounded;
        break;
      case _MapStatus.ready:
        background = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurfaceVariant;
        icon = Icons.info_outline;
        break;
    }

    return LocationStatusBanner(
      icon: icon,
      label: _statusMessage!,
      backgroundColor: background,
      textColor: textColor,
    );
  }

  Future<void> _resolveUserLocation() async {
    setState(() {
      _status = _MapStatus.locating;
      _statusMessage = 'Localizando voc├¬...';
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _status = _MapStatus.error;
          _statusMessage =
              'Ative os servi├ºos de localiza├º├úo para ver sua posi├º├úo. Exibindo pontos padr├úo da cidade.';
        });
        _fallbackLoadPois();
        await _loadTodayEvents();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _status = _MapStatus.error;
          _statusMessage =
              'Permita o acesso ├á localiza├º├úo para localizar pontos pr├│ximos. Exibindo pontos padr├úo da cidade.';
        });
        _fallbackLoadPois();
        await _loadTodayEvents();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      final origin = CityCoordinate(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final userLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _userPosition = userLatLng;
        _status = _MapStatus.fetching;
        _statusMessage = 'Buscando pontos pr├│ximos...';
      });

      await _controller.loadPois(_queryForOrigin(origin));
      await _loadTodayEvents();
      if (mounted) {
        _updateStatusFromState();
      }

      _hasRequestedPois = true;

      if (mounted) {
        _mapController.move(userLatLng, 16);
      }
    } on PlatformException catch (error) {
      setState(() {
        _status = _MapStatus.error;
        _statusMessage =
            'N├úo foi poss├¡vel obter a localiza├º├úo (${error.code}). Exibindo pontos padr├úo da cidade.';
      });
      _fallbackLoadPois();
      await _loadTodayEvents();
    } catch (_) {
      setState(() {
        _status = _MapStatus.error;
        _statusMessage =
            'N├úo foi poss├¡vel obter a localiza├º├úo. Exibindo pontos padr├úo da cidade.';
      });
      _fallbackLoadPois();
      await _loadTodayEvents();
    }
  }

  void _centerOnUser(CityCoordinate coordinate) {
    final target = LatLng(
      coordinate.latitude,
      coordinate.longitude,
    );
    _userPosition = target;
    _mapController.move(target, 16);
    _controller.selectPoi(null);
    _controller.selectEvent(null);
  }
  

  void _handlePoiHover(String? poiId) {
    if (!kIsWeb) {
      return;
    }
    if (_hoveredPoiId == poiId) {
      return;
    }
    setState(() {
      _hoveredPoiId = poiId;
    });
  }

  void _handleMapInteraction() {
    if (_controller.selectedPoiStreamValue.value != null) {
      _controller.selectPoi(null);
    }
    if (_controller.selectedEventStreamValue.value != null) {
      _controller.selectEvent(null);
    }
  }

  Future<void> _openPoiDetails(CityPoiModel poi) async {
    if (!mounted) return;
    await context.router.push(PoiDetailsRoute(poi: poi));
  }

  Future<void> _openEventDetails(EventModel event) async {
    if (!mounted) return;
    final eventData = _mapEventToCardData(event);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Material(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: EventDetails(eventCardData: eventData),
            ),
          ),
        );
      },
    );
  }

  EventCardData _mapEventToCardData(EventModel event) {
    final imageUrl = event.thumb?.thumbUri.value.toString() ??
        'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=800';
    final participants = event.artists
        .map(
          (artist) => EventParticipantData(
            name: artist.name.value,
            isHighlight: artist.isHighlight.value,
          ),
        )
        .toList();
    final startDate = event.dateTimeStart.value ?? DateTime.now();
    final venue = event.location.value;

    return EventCardData(
      title: event.title.value,
      imageUrl: imageUrl,
      startDateTime: startDate,
      venue: venue,
      participants: participants,
    );
  }

  void _fallbackLoadPois() {
    if (_hasRequestedPois) return;
    _hasRequestedPois = true;
    setState(() {
      _status = _MapStatus.fallback;
      _statusMessage = 'Exibindo pontos padr├úo da cidade.';
    });
    unawaited(() async {
      await _controller.loadPois(const PoiQuery());
      await _loadTodayEvents();
      if (!mounted) return;
      _updateStatusFromState();
    }());
  }

  Future<void> _loadTodayEvents() async {
    if (_eventsLoaded) {
      return;
    }
    _eventsLoaded = true;
    await _controller.initialize();
  }

  void _updateStatusFromState() {
    setState(() {
      _status = _controller.hasError ? _MapStatus.error : _MapStatus.ready;
      _statusMessage =
          _controller.hasError ? _controller.currentErrorMessage : null;
    });
  }

  PoiQuery _queryForOrigin(CityCoordinate origin) {
    const boundsOffset = 0.1;
    return PoiQuery(
      northEast: CityCoordinate(
        latitude: origin.latitude + boundsOffset,
        longitude: origin.longitude + boundsOffset,
      ),
      southWest: CityCoordinate(
        latitude: origin.latitude - boundsOffset,
        longitude: origin.longitude - boundsOffset,
      ),
    );
  }
}

class _CityMapView extends StatelessWidget {
  const _CityMapView({
    required this.mapController,
    required this.pois,
    required this.selectedPoi,
    required this.onSelectPoi,
    required this.hoveredPoiId,
    required this.onHoverChange,
    required this.events,
    required this.selectedEvent,
    required this.onSelectEvent,
    required this.userPosition,
    required this.defaultCenter,
    required this.onMapInteraction,
  });

  final MapController mapController;
  final List<CityPoiModel> pois;
  final CityPoiModel? selectedPoi;
  final ValueChanged<CityPoiModel?> onSelectPoi;
  final String? hoveredPoiId;
  final ValueChanged<String?> onHoverChange;
  final List<EventModel> events;
  final EventModel? selectedEvent;
  final ValueChanged<EventModel?> onSelectEvent;
  final LatLng? userPosition;
  final LatLng defaultCenter;
  final VoidCallback onMapInteraction;

  @override
  Widget build(BuildContext context) {
    final selectedEventId = selectedEvent?.id.value;
    final now = DateTime.now();
    final markerEntries = <_MarkerEntry>[];

    if (userPosition != null) {
      markerEntries.add(
        _MarkerEntry(
          priority: 110,
          marker: Marker(
            point: userPosition!,
            width: 48,
            height: 48,
            child: const UserLocationMarker(),
          ),
        ),
      );
    }

    final sortedPois = List<CityPoiModel>.from(pois)
      ..sort((a, b) => a.priority.compareTo(b.priority));
    for (final poi in sortedPois) {
      final isHovered = hoveredPoiId == poi.id;
      markerEntries.add(
        _MarkerEntry(
          priority: isHovered ? poi.priority + 1000 : poi.priority,
          marker: Marker(
            point: LatLng(
              poi.coordinate.latitude,
              poi.coordinate.longitude,
            ),
            width: 52,
            height: 52,
            child: GestureDetector(
              onTap: () => onSelectPoi(poi),
              child: MouseRegion(
                onEnter: (_) => onHoverChange(poi.id),
                onExit: (_) => onHoverChange(null),
                child: PoiMarker(
                  poi: poi,
                  isSelected: selectedPoi?.id == poi.id,
                  isHovered: isHovered && kIsWeb,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final eventCandidates = events
        .where((event) => event.coordinate != null)
        .toList(growable: false)
      ..sort(
        (a, b) => _priorityForEvent(a, now).compareTo(
          _priorityForEvent(b, now),
        ),
      );

    for (final event in eventCandidates) {
      final eventPriority = _priorityForEvent(event, now);
      markerEntries.add(
        _MarkerEntry(
          priority: eventPriority,
          marker: Marker(
            point: LatLng(
              event.coordinate!.latitude,
              event.coordinate!.longitude,
            ),
            width: 96,
            height: 96,
            child: GestureDetector(
              onTap: () => onSelectEvent(event),
              child: EventMarker(
                event: event,
                isSelected: selectedEventId == event.id.value,
              ),
            ),
          ),
        ),
      );
    }

    markerEntries.sort((a, b) => a.priority.compareTo(b.priority));
    final markers = markerEntries.map((entry) => entry.marker).toList();

    final initialCenter = userPosition ?? defaultCenter;

    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: (_) => onMapInteraction(),
      child: FmMap(
        mapController: mapController,
        mapOptions: MapOptions(
          initialCenter: initialCenter,
          initialZoom: 16,
          minZoom: 14,
          maxZoom: 18,
          interactionOptions:
              const InteractionOptions(flags: InteractiveFlag.all),
        ),
        markers: markers,
        attributionAlignment: Alignment.bottomRight,
      ),
    );
  }
}

enum _MapStatus { locating, fetching, ready, error, fallback }

class _MarkerEntry {
  _MarkerEntry({required this.priority, required this.marker});

  final int priority;
  final Marker marker;
}

int _priorityForEvent(EventModel event, DateTime now) {
  final state = resolveEventTemporalState(event, reference: now);
  switch (state) {
    case CityEventTemporalState.now:
      return 90;
    case CityEventTemporalState.upcoming:
      return 80;
    case CityEventTemporalState.past:
      return 70;
  }
}



