import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/filters/main_filter_option.dart';
import 'package:belluga_now/domain/map/direction_info.dart';
import 'package:belluga_now/domain/map/map_navigation_target.dart';
import 'package:belluga_now/domain/map/ride_share_provider.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/city_map_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/cuisine_panel_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/fab_menu_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/city_map_error_card.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/city_map_layers.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/city_map_lateral_panel.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/city_map_loading_overlay.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/city_map_main_filter_fab.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/city_map_selected_cards.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/city_map_status_banner.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
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
  late final CityMapController _cityMapController;
  late final FabMenuController _fabMenuController;
  late final CuisinePanelController _cuisinePanelController;

  StreamSubscription<MapNavigationTarget?>? _navigationSubscription;
  StreamSubscription<LateralPanelType?>? _panelSubscription;

  @override
  void initState() {
    super.initState();
    _cityMapController = GetIt.I.get<CityMapController>();
    _fabMenuController = GetIt.I.get<FabMenuController>();
    _cuisinePanelController = GetIt.I.get<CuisinePanelController>();

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultCenter = _cityMapController.defaultCenter;

    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Positioned.fill(
            child: CityMapLayers(
              defaultCenter: defaultCenter,
              onSelectPoi: _handleSelectPoi,
              onHoverChange: _handleHoverChange,
              onSelectEvent: _handleSelectEvent,
              onMapInteraction: _handleMapInteraction,
            ),
          ),
          CityMapStatusBanner(),
          CityMapErrorCard(controller: _cityMapController),
          CityMapSelectedCards(
            onOpenEventDetails: _openEventDetails,
            onShareEvent: _shareEvent,
            onRouteToEvent: _handleDirectionsForEvent,
            onOpenPoiDetails: _openPoiDetails,
            onSharePoi: _sharePoi,
            onRouteToPoi: _handleDirectionsForPoi,
          ),
          CityMapLateralPanel(),
          CityMapLoadingOverlay(controller: _cityMapController),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: CityMapMainFilterFabGroup(
        onMainFilterTap: _onMainFilterTap,
        panelResolver: _panelTypeFor,
      ),
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

  Future<void> _openSearchDialog() async {
    final initialTerm = _cityMapController.searchTermStreamValue.value ?? '';
    final textController = _cityMapController.searchInputController
      ..text = initialTerm
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: initialTerm.length),
      );
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
    _cityMapController.mapController.move(target, 16);
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
    await SharePlus.instance.share(
      ShareParams(text: payload.message, subject: payload.subject),
    );
  }

  Future<void> _shareEvent(EventModel event) async {
    final payload = _cityMapController.buildEventSharePayload(event);
    await SharePlus.instance.share(
      ShareParams(text: payload.message, subject: payload.subject),
    );
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
    final slugSource = event.id.value;
    final slug = slugSource.isNotEmpty
        ? _slugify(slugSource)
        : _slugify(event.title.value);
    await context.router.push(ImmersiveEventDetailRoute(eventSlug: slug));
  }

  void _handleNavigationTarget(MapNavigationTarget? target) {
    if (target == null) {
      return;
    }
    final center = LatLng(
      target.center.latitude,
      target.center.longitude,
    );
    _cityMapController.mapController.move(center, target.zoom);
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

  String _slugify(String value) {
    final slug = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final cleaned = slug.replaceAll(RegExp(r'-{2,}'), '-');
    return cleaned.replaceAll(RegExp(r'^-+|-+$'), '');
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
}
