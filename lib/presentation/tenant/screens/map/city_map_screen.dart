import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/manual_route_stubs.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/filters/main_filter_option.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/screens/map/controller/city_map_controller.dart'
    show
        CityMapController,
        DirectionsInfo,
        MapNavigationTarget,
        MapStatus,
        RideShareProvider;
import 'package:belluga_now/presentation/tenant/screens/map/controller/cuisine_panel_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/map/controller/events_panel_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/map/controller/fab_menu_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/map/controller/music_panel_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/map/controller/region_panel_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/map/panels/cuisine_panel.dart';
import 'package:belluga_now/presentation/tenant/screens/map/panels/events_panel.dart';
import 'package:belluga_now/presentation/tenant/screens/map/panels/region_panel.dart';
import 'package:belluga_now/presentation/tenant/screens/map/poi_info_card/poi_info_card.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/city_map_view.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/event_info_card.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/location_status_banner.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/main_filter_icon_resolver.dart';
import 'package:belluga_now/presentation/tenant/widgets/event_details.dart';
import 'package:belluga_now/presentation/view_models/event_card_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:url_launcher/url_launcher.dart';

class CityMapScreen extends StatefulWidget {
  const CityMapScreen({super.key});

  @override
  State<CityMapScreen> createState() => _CityMapScreenState();
}

class _CityMapScreenState extends State<CityMapScreen> {
  final MapController _mapController = MapController();

  late final CityMapController _cityMapController;
  late final FabMenuController _fabMenuController;
  late final RegionPanelController _regionPanelController;
  late final EventsPanelController _eventsPanelController;
  late final MusicPanelController _musicPanelController;
  late final CuisinePanelController _cuisinePanelController;

  StreamSubscription<MapNavigationTarget?>? _navigationSubscription;
  StreamSubscription<LateralPanelType?>? _panelSubscription;

  @override
  void initState() {
    super.initState();
    _cityMapController = GetIt.I.get<CityMapController>();
    _fabMenuController = GetIt.I.get<FabMenuController>();
    _regionPanelController = RegionPanelController(
      mapController: _cityMapController,
      fabMenuController: _fabMenuController,
    );
    _eventsPanelController = EventsPanelController(
      mapController: _cityMapController,
      fabMenuController: _fabMenuController,
    );
    _musicPanelController = MusicPanelController(
      mapController: _cityMapController,
      fabMenuController: _fabMenuController,
    );
    _cuisinePanelController = CuisinePanelController(
      mapController: _cityMapController,
      fabMenuController: _fabMenuController,
    );

    _navigationSubscription = _cityMapController.mapNavigationTarget.stream
        .listen(_handleNavigationTarget);
    _panelSubscription =
        _fabMenuController.activePanel.stream.listen(_handlePanelChange);

    unawaited(_cityMapController.initialize());
    unawaited(_cityMapController.resolveUserLocation());
  }

  @override
  void dispose() {
    _navigationSubscription?.cancel();
    _panelSubscription?.cancel();
    _cuisinePanelController.onDispose();
    _musicPanelController.onDispose();
    _eventsPanelController.onDispose();
    _regionPanelController.onDispose();
    _fabMenuController.onDispose();
    _cityMapController.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultCenter = _cityMapController.defaultCenter;

    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Positioned.fill(child: _buildMapLayers(defaultCenter)),
          _buildStatusBanner(),
          _buildErrorCard(),
          _buildSelectedInfoCards(),
          _buildLateralPanel(),
          _buildLoadingOverlay(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _buildMainFilterFabGroup(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Mapa de Guarapari'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Buscar pontos',
          onPressed: _openSearchDialog,
        ),
        StreamValueBuilder<String?>(
          streamValue: _cityMapController.searchTermStreamValue,
          builder: (_, term) {
            final hasSearch = (term?.trim().isNotEmpty ?? false);
            if (!hasSearch) {
              return const SizedBox.shrink();
            }
            return IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Limpar busca',
              onPressed: _handleClearSearch,
            );
          },
        ),
        StreamValueBuilder<CityCoordinate?>(
          streamValue: _cityMapController.userLocationStreamValue,
          builder: (_, coordinate) {
            final target = coordinate;
            return IconButton(
              icon: const Icon(Icons.my_location_outlined),
              tooltip: 'Centralizar na minha posicao',
              onPressed: target == null ? null : () => _centerOnUser(target),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMapLayers(CityCoordinate defaultCenter) {
    final defaultLatLng = LatLng(
      defaultCenter.latitude,
      defaultCenter.longitude,
    );

    return StreamValueBuilder<List<CityPoiModel>>(
      streamValue: _cityMapController.pois,
      builder: (_, pois) {
        return StreamValueBuilder<List<EventModel>>(
          streamValue: _cityMapController.eventsStreamValue,
          builder: (_, events) {
            return StreamValueBuilder<CityCoordinate?>(
              streamValue: _cityMapController.userLocationStreamValue,
              builder: (_, coordinate) {
                final userLatLng = coordinate == null
                    ? null
                    : LatLng(coordinate.latitude, coordinate.longitude);
                return StreamValueBuilder<CityPoiModel?>(
                  streamValue: _cityMapController.selectedPoiStreamValue,
                  builder: (_, selectedPoi) {
                    return StreamValueBuilder<EventModel?>(
                      streamValue: _cityMapController.selectedEventStreamValue,
                      builder: (_, selectedEvent) {
                        return StreamValueBuilder<String?>(
                          streamValue:
                              _cityMapController.hoveredPoiIdStreamValue,
                          builder: (_, hoveredId) {
                            return CityMapView(
                              mapController: _mapController,
                              pois: pois,
                              selectedPoi: selectedPoi,
                              onSelectPoi: _handleSelectPoi,
                              hoveredPoiId: hoveredId,
                              onHoverChange: _handleHoverChange,
                              events: events,
                              selectedEvent: selectedEvent,
                              onSelectEvent: _handleSelectEvent,
                              userPosition: userLatLng,
                              defaultCenter: defaultLatLng,
                              onMapInteraction: _handleMapInteraction,
                            );
                          },
                        );
                      },
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

  Widget _buildStatusBanner() {
    final theme = Theme.of(context);
    return StreamValueBuilder<String?>(
      streamValue: _cityMapController.statusMessageStreamValue,
      builder: (_, message) {
        if (message == null || message.isEmpty) {
          return const SizedBox.shrink();
        }
        return StreamValueBuilder<MapStatus>(
          streamValue: _cityMapController.mapStatusStreamValue,
          builder: (_, status) {
            final visuals = _resolveStatusVisuals(status, theme);
            return Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SafeArea(
                  child: LocationStatusBanner(
                    icon: visuals.icon,
                    label: message,
                    backgroundColor: visuals.background,
                    textColor: visuals.textColor,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorCard() {
    final theme = Theme.of(context);
    return StreamValueBuilder<String?>(
      streamValue: _cityMapController.errorMessage,
      builder: (_, error) {
        if (error == null) {
          return const SizedBox.shrink();
        }
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
          ),
        );
      },
    );
  }

  Widget _buildSelectedInfoCards() {
    return StreamValueBuilder<EventModel?>(
      streamValue: _cityMapController.selectedEventStreamValue,
      builder: (_, selectedEvent) {
        if (selectedEvent != null) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SafeArea(
                child: EventInfoCard(
                  event: selectedEvent,
                  onDismiss: () => _cityMapController.selectEvent(null),
                  onDetails: () => _openEventDetails(selectedEvent),
                  onShare: () => _shareEvent(selectedEvent),
                  onRoute: selectedEvent.coordinate == null
                      ? null
                      : () => _handleDirectionsForEvent(selectedEvent),
                ),
              ),
            ),
          );
        }
        return StreamValueBuilder<CityPoiModel?>(
          streamValue: _cityMapController.selectedPoiStreamValue,
          builder: (_, selectedPoi) {
            if (selectedPoi == null) {
              return const SizedBox.shrink();
            }
            return Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: SafeArea(
                  child: PoiInfoCard(
                    poi: selectedPoi,
                    onDismiss: () => _cityMapController.selectPoi(null),
                    onDetails: () => _openPoiDetails(selectedPoi),
                    onShare: () => _sharePoi(selectedPoi),
                    onRoute: () => _handleDirectionsForPoi(selectedPoi),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLateralPanel() {
    return StreamValueBuilder<LateralPanelType?>(
      streamValue: _fabMenuController.activePanel,
      builder: (_, panel) {
        final panelType = panel;
        if (panelType == null) {
          return const SizedBox.shrink();
        }

        late final Widget panelWidget;
        switch (panelType) {
          case LateralPanelType.regions:
            panelWidget = RegionPanel(
              controller: _regionPanelController,
              onClose: _fabMenuController.closePanel,
            );
            break;
          case LateralPanelType.events:
            panelWidget = EventsPanel(
              controller: _eventsPanelController,
              onClose: _fabMenuController.closePanel,
              title: 'Eventos',
              icon: Icons.event,
            );
            break;
          case LateralPanelType.music:
            panelWidget = EventsPanel(
              controller: _musicPanelController,
              onClose: _fabMenuController.closePanel,
              title: 'Shows',
              icon: Icons.music_note,
            );
            break;
          case LateralPanelType.cuisines:
            panelWidget = CuisinePanel(
              controller: _cuisinePanelController,
              onClose: _cuisinePanelController.closePanel,
            );
            break;
        }

        return Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 16, right: 16),
            child: SafeArea(child: panelWidget),
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return StreamValueBuilder<bool>(
      streamValue: _cityMapController.isLoading,
      builder: (_, isLoading) {
        if (isLoading != true) {
          return const SizedBox.shrink();
        }
        return const Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainFilterFabGroup() {
    final theme = Theme.of(context);
    return StreamValueBuilder<List<MainFilterOption>>(
      streamValue: _cityMapController.mainFilterOptionsStreamValue,
      builder: (_, options) {
        if (options.isEmpty) {
          return const SizedBox.shrink();
        }
        return StreamValueBuilder<bool>(
          streamValue: _fabMenuController.menuExpanded,
          builder: (_, expanded) {
            return StreamValueBuilder<MainFilterOption?>(
              streamValue: _cityMapController.activeMainFilterStreamValue,
              builder: (_, activeFilter) {
                return StreamValueBuilder<LateralPanelType?>(
                  streamValue: _fabMenuController.activePanel,
                  builder: (_, activePanel) {
                    final children = <Widget>[];
                    if (expanded == true) {
                      for (final option in options.reversed) {
                        children.add(
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildSecondaryFilterFab(
                              theme: theme,
                              option: option,
                              activeFilter: activeFilter,
                              activePanel: activePanel,
                            ),
                          ),
                        );
                      }
                    }

                    children.add(
                      FloatingActionButton(
                        heroTag: 'main-filter-toggle-fab',
                        onPressed: _fabMenuController.toggleMenu,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            expanded == true ? Icons.close : Icons.filter_list,
                            key: ValueKey<bool>(expanded == true),
                          ),
                        ),
                      ),
                    );

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: children,
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

  Widget _buildSecondaryFilterFab({
    required ThemeData theme,
    required MainFilterOption option,
    required MainFilterOption? activeFilter,
    required LateralPanelType? activePanel,
  }) {
    final icon = resolveMainFilterIcon(option.iconName);
    final panelType = _panelTypeFor(option.type);
    final isActive = option.isQuickApply
        ? activeFilter?.id == option.id
        : (panelType != null && panelType == activePanel);
    final backgroundColor =
        isActive ? theme.colorScheme.primary : theme.colorScheme.surface;
    final foregroundColor =
        isActive ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    return Tooltip(
      message: option.label,
      child: FloatingActionButton.small(
        heroTag: 'main-filter-${option.id}',
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        onPressed: () => _onMainFilterTap(option),
        child: Icon(icon),
      ),
    );
  }

  Future<void> _openSearchDialog() async {
    final initialTerm = _cityMapController.searchTermStreamValue.value ?? '';
    final controller = TextEditingController(text: initialTerm);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Buscar pontos'),
          content: TextField(
            controller: controller,
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
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Buscar'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (!mounted || result == null) {
      return;
    }
    final query = result.trim();
    if (query.isEmpty) {
      await _handleClearSearch();
      return;
    }
    await _cityMapController.searchPois(query);
  }

  Future<void> _handleClearSearch() async {
    await _cityMapController.clearSearch();
  }

  Future<void> _centerOnUser(CityCoordinate coordinate) async {
    final target = LatLng(coordinate.latitude, coordinate.longitude);
    _mapController.move(target, 16);
    _cityMapController.clearSelections();
    _cityMapController.setHoveredPoi(null);
    _fabMenuController.closePanel();
  }

  void _handleSelectPoi(CityPoiModel? poi) {
    if (poi == null) {
      _cityMapController.selectPoi(null);
      return;
    }
    _cityMapController.selectPoi(poi);
    _cityMapController.selectEvent(null);
    _fabMenuController.closePanel();
  }

  void _handleSelectEvent(EventModel? event) {
    if (event == null) {
      _cityMapController.selectEvent(null);
      return;
    }
    _cityMapController.selectEvent(event);
    _cityMapController.selectPoi(null);
    _fabMenuController.closePanel();
  }

  void _handleHoverChange(String? poiId) {
    if (!kIsWeb) {
      return;
    }
    _cityMapController.setHoveredPoi(poiId);
  }

  void _handleMapInteraction() {
    _cityMapController.clearSelections();
    _cityMapController.setHoveredPoi(null);
    _fabMenuController.closePanel();
  }

  Future<void> _sharePoi(CityPoiModel poi) async {
    final payload = _cityMapController.buildPoiSharePayload(poi);
    await Share.share(payload.message, subject: payload.subject);
  }

  Future<void> _shareEvent(EventModel event) async {
    final payload = _cityMapController.buildEventSharePayload(event);
    await Share.share(payload.message, subject: payload.subject);
  }

  Future<void> _handleDirectionsForPoi(CityPoiModel poi) async {
    final info = await _cityMapController.preparePoiDirections(poi);
    if (info == null) {
      _showSnackbar('Localizacao indisponivel para este ponto.');
      return;
    }
    await _presentDirectionsOptions(info);
  }

  Future<void> _handleDirectionsForEvent(EventModel event) async {
    final info = await _cityMapController.prepareEventDirections(event);
    if (info == null) {
      _showSnackbar('Este evento nao possui localizacao cadastrada.');
      return;
    }
    await _presentDirectionsOptions(info);
  }

  Future<void> _presentDirectionsOptions(DirectionsInfo info) async {
    final maps = info.availableMaps;
    final rideShares = info.rideShareOptions;
    final totalOptions = maps.length + rideShares.length;

    if (totalOptions == 0) {
      await _launchFallbackDirections(info);
      return;
    }

    if (totalOptions == 1) {
      if (maps.length == 1) {
        await maps.first.showDirections(
          destination: info.destination,
          destinationTitle: info.destinationName,
        );
      } else {
        final success = await _cityMapController.launchRideShareOption(
          rideShares.first,
        );
        if (!success) {
          await _launchFallbackDirections(info);
        }
      }
      return;
    }

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
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
                    style: theme.textTheme.titleMedium,
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
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await map.showDirections(
                      destination: info.destination,
                      destinationTitle: info.destinationName,
                    );
                  },
                ),
              if (maps.isNotEmpty && rideShares.isNotEmpty)
                const Divider(height: 1),
              for (final option in rideShares)
                ListTile(
                  leading: Icon(
                    _rideShareIcon(option.provider),
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(option.label),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final success =
                        await _cityMapController.launchRideShareOption(option);
                    if (!success && mounted) {
                      await _launchFallbackDirections(info);
                    }
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchFallbackDirections(DirectionsInfo info) async {
    final launched = await launchUrl(
      info.fallbackUrl,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      _showSnackbar('Nao foi possivel abrir o mapa para direcoes.');
    }
  }

  void _showSnackbar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openPoiDetails(CityPoiModel poi) async {
    if (!mounted) {
      return;
    }
    await context.router.push(PoiDetailsRoute(poi: poi));
  }

  Future<void> _openEventDetails(EventModel event) async {
    if (!mounted) {
      return;
    }
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
    final thumbUri = event.thumb?.thumbUri.value;
    final imageUrl = thumbUri?.toString();
    final fallbackImage = _cityMapController.fallbackEventImage ??
        'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=800';
    final participants = event.artists
        .map(
          (artist) => EventParticipantData(
            name: artist.name.value,
            isHighlight: artist.isHighlight.value,
          ),
        )
        .toList(growable: false);
    final startDate = event.dateTimeStart.value ?? DateTime.now();
    final venue = event.location.value;

    return EventCardData(
      title: event.title.value,
      imageUrl: imageUrl?.isNotEmpty == true ? imageUrl! : fallbackImage,
      startDateTime: startDate,
      venue: venue,
      participants: participants,
    );
  }

  void _handleNavigationTarget(MapNavigationTarget? target) {
    if (target == null) {
      return;
    }
    final center = LatLng(
      target.center.latitude,
      target.center.longitude,
    );
    _mapController.move(center, target.zoom);
  }

  void _handlePanelChange(LateralPanelType? panel) {
    switch (panel) {
      case LateralPanelType.cuisines:
        unawaited(_cuisinePanelController.activate());
        break;
      case LateralPanelType.regions:
        unawaited(_cityMapController.loadRegions());
        break;
      case LateralPanelType.events:
      case LateralPanelType.music:
      case null:
        break;
    }
  }

  Future<void> _onMainFilterTap(MainFilterOption option) async {
    if (option.opensPanel) {
      final panelType = _panelTypeFor(option.type);
      if (panelType != null) {
        _fabMenuController.openPanel(panelType);
      }
      return;
    }
    _fabMenuController.closePanel();
    await _cityMapController.applyMainFilter(option);
  }

  LateralPanelType? _panelTypeFor(MainFilterType type) {
    switch (type) {
      case MainFilterType.regions:
        return LateralPanelType.regions;
      case MainFilterType.events:
        return LateralPanelType.events;
      case MainFilterType.music:
        return LateralPanelType.music;
      case MainFilterType.cuisines:
        return LateralPanelType.cuisines;
      case MainFilterType.promotions:
        return null;
    }
  }

  IconData _rideShareIcon(RideShareProvider provider) {
    switch (provider) {
      case RideShareProvider.uber:
        return Icons.local_taxi;
      case RideShareProvider.ninetyNine:
        return Icons.local_taxi_outlined;
    }
  }

  _StatusVisuals _resolveStatusVisuals(
    MapStatus status,
    ThemeData theme,
  ) {
    switch (status) {
      case MapStatus.locating:
        return _StatusVisuals(
          background: theme.colorScheme.surfaceContainerHigh,
          textColor: theme.colorScheme.onSurfaceVariant,
          icon: Icons.hourglass_bottom,
        );
      case MapStatus.fetching:
        return _StatusVisuals(
          background: theme.colorScheme.secondaryContainer,
          textColor: theme.colorScheme.onSecondaryContainer,
          icon: Icons.explore_outlined,
        );
      case MapStatus.fallback:
        return _StatusVisuals(
          background: theme.colorScheme.surfaceContainerHighest,
          textColor: theme.colorScheme.onSurfaceVariant,
          icon: Icons.location_off_outlined,
        );
      case MapStatus.error:
        return _StatusVisuals(
          background: theme.colorScheme.errorContainer,
          textColor: theme.colorScheme.onErrorContainer,
          icon: Icons.warning_amber_rounded,
        );
      case MapStatus.ready:
        return _StatusVisuals(
          background: theme.colorScheme.surfaceContainerHighest,
          textColor: theme.colorScheme.onSurfaceVariant,
          icon: Icons.info_outline,
        );
    }
  }
}

class _StatusVisuals {
  const _StatusVisuals({
    required this.background,
    required this.textColor,
    required this.icon,
  });

  final Color background;
  final Color textColor;
  final IconData icon;
}
