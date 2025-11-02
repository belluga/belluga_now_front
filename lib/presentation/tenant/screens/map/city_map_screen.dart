import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/manual_route_stubs.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/infrastructure/services/dal/datasources/poi_query.dart';
import 'package:belluga_now/presentation/tenant/screens/map/controller/city_map_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/event_info_card.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/event_marker.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/event_temporal_state.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/location_status_banner.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/filter_panel.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/poi_info_card.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/poi_marker.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/user_location_marker.dart';
import 'package:belluga_now/presentation/tenant/widgets/event_details.dart';
import 'package:belluga_now/presentation/view_models/event_card_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:free_map/fm_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class CityMapScreen extends StatefulWidget {
  const CityMapScreen({super.key});

  @override
  State<CityMapScreen> createState() => _CityMapScreenState();
}

class _CityMapScreenState extends State<CityMapScreen> {
  final _mapController = MapController();
  final _controller = GetIt.I.get<CityMapController>();

  LatLng? _userPosition;
  CityCoordinate? _userOrigin;
  bool _hasRequestedPois = false;
  bool _eventsLoaded = false;
  _MapStatus _status = _MapStatus.locating;
  String? _statusMessage = 'Localizando voce...';
  String? _hoveredPoiId;

  @override
  void initState() {
    super.initState();
    unawaited(_controller.loadFilters());
    _resolveUserLocation();
  }

  @override
  void dispose() {
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
          IconButton(
            icon: const Icon(Icons.my_location_outlined),
            tooltip: 'Centralizar na minha posicao',
            onPressed: _userPosition == null ? null : _centerOnUser,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterAndRegionBar(theme),
          Expanded(
            child: _buildMapArea(theme, defaultCenter),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndRegionBar(ThemeData theme) {
    return Material(
      elevation: 2,
      color: theme.colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilterPanel(controller: _controller),
            const SizedBox(width: 16),
            for (final region in _controller.regions)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton.tonalIcon(
                  onPressed: () => _handleRegionTap(region),
                  icon: const Icon(Icons.place_outlined),
                  label: Text(region.label),
                ),
              ),
          ],
        ),
      ),
    );
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

  Widget _buildMapArea(ThemeData theme, CityCoordinate defaultCenter) {
    return StreamValueBuilder<List<CityPoiModel>>(
      streamValue: _controller.pois,
      onNullWidget: const Center(child: CircularProgressIndicator()),
      builder: (context, poiStreamValue) {
        final poiList = poiStreamValue ?? const <CityPoiModel>[];
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
                          userPosition: _userPosition,
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
        _userOrigin = origin;
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

  void _centerOnUser() {
    final position = _userPosition;
    if (position == null) return;
    _mapController.move(position, 16);
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
