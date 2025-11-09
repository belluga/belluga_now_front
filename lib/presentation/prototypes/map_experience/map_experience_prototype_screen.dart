import 'dart:async';

import 'package:belluga_now/application/router/modular_app/modules/map_prototype_module.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/map_status.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/repositories/city_map_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/city_map_repository.dart';
import 'package:belluga_now/infrastructure/repositories/schedule_repository.dart';
import 'package:belluga_now/infrastructure/services/dal/datasources/mock_poi_database.dart';
import 'package:belluga_now/infrastructure/services/http/mock_http_service.dart';
import 'package:belluga_now/infrastructure/services/networking/mock_web_socket_service.dart';
import 'package:belluga_now/infrastructure/services/dal/datasources/poi_query.dart';
import 'package:belluga_now/presentation/prototypes/map_experience/widgets/map_intent_fab_menu.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/city_map_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/city_map_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class MapExperiencePrototypeScreen extends StatefulWidget {
  const MapExperiencePrototypeScreen({super.key});

  @override
  State<MapExperiencePrototypeScreen> createState() =>
      _MapExperiencePrototypeScreenState();
}

class _MapExperiencePrototypeScreenState
    extends State<MapExperiencePrototypeScreen> {
  late final CityMapController _cityMapController;
  CityMapRepositoryContract? _ownedCityMapRepository;
  MockWebSocketService? _ownedWebSocketService;
  bool _ownsController = false;
  MapIntent _activeIntent = MapIntent.discover;
  bool _menuExpanded = true;
  CityMapController _resolveController() {
    final getIt = GetIt.I;
    if (getIt.isRegistered<CityMapController>(
      instanceName: MapPrototypeModule.instanceName,
    )) {
      return getIt.get<CityMapController>(
        instanceName: MapPrototypeModule.instanceName,
      );
    }
    _ownsController = true;
    final mockDatabase = MockPoiDatabase();
    final httpService = MockHttpService(database: mockDatabase);
    final webSocketService = MockWebSocketService();
    final mapRepository = CityMapRepository(
      database: mockDatabase,
      httpService: httpService,
      webSocketService: webSocketService,
    );
    final scheduleRepository = ScheduleRepository();
    _ownedCityMapRepository = mapRepository;
    _ownedWebSocketService = webSocketService;
    return CityMapController(
      repository: mapRepository,
      scheduleRepository: scheduleRepository,
    );
  }

  @override
  void initState() {
    super.initState();
    _cityMapController = _resolveController();
    scheduleMicrotask(_initializeController);
  }

  @override
  void dispose() {
    if (_ownsController) {
      _cityMapController.onDispose();
      _ownedCityMapRepository?.dispose();
      _ownedWebSocketService?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final scheme = ColorScheme.fromSeed(
      seedColor: base.colorScheme.primary,
      brightness: base.brightness,
    );
    final theme = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.black,
      textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
    );

    final defaultCenter = _cityMapController.defaultCenter;

    return Theme(
      data: theme,
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: _PrototypeMapLayers(
                    controller: _cityMapController,
                    defaultCenter: defaultCenter,
                    onSelectPoi: _handleSelectPoi,
                    onHoverChange: _handleHoverChange,
                    onSelectEvent: _handleSelectEvent,
                    onMapInteraction: _handleMapInteraction,
                  ),
                ),
              ],
            ),
            SafeArea(
              child: SizedBox(
                height: 120,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MapHeader(
                        onSearch: _openSearchDialog,
                        onLocate: _centerOnUser,
                      ),
                      const SizedBox(height: 8),
                      _StatusBanner(controller: _cityMapController),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: MapIntentFabMenu(
          expanded: _menuExpanded,
          activeIntent: _activeIntent,
          onToggle: () => setState(() => _menuExpanded = !_menuExpanded),
          onSelectIntent: (intent) {
            setState(() {
              _activeIntent = intent;
              _menuExpanded = false;
            });
            _handleIntent(intent);
          },
        ),
      ),
    );
  }

  void _handleSelectPoi(CityPoiModel? poi) {
    _cityMapController.selectPoi(poi);
    if (poi != null) {
      _cityMapController.selectEvent(null);
    }
  }

  void _handleSelectEvent(EventModel? event) {
    _cityMapController.selectEvent(event);
    if (event != null) {
      _cityMapController.selectPoi(null);
    }
  }

  void _handleHoverChange(String? poiId) {
    if (!kIsWeb) {
      return;
    }
    _cityMapController.setHoveredPoi(poiId);
  }

  void _handleMapInteraction() {
    _cityMapController.clearSelections();
  }

  Future<void> _handleIntent(MapIntent intent) async {
    switch (intent) {
      case MapIntent.discover:
        _cityMapController.clearSelections();
        _showSnackbar('Explorando todos os pontos de Guarapari.');
        break;
      case MapIntent.contribute:
        await _showSimpleSheet(
          title: 'Contribuir com a cidade',
          description:
              'Em breve você poderá reivindicar pontos, enviar histórias e atualizar horários diretamente do mapa.',
        );
        break;
      case MapIntent.social:
        await _showSimpleSheet(
          title: 'Visão social',
          description:
              'Esta visão mostrará os pontos favoritos dos seus amigos e recomendações da comunidade.',
        );
        break;
      case MapIntent.travel:
        final poi = _cityMapController.selectedPoiStreamValue.value;
        if (poi == null) {
          _showSnackbar('Selecione um ponto no mapa para traçar uma rota.');
          return;
        }
        await _showSimpleSheet(
          title: 'Mover-se até ${poi.name}',
          description:
              'Integrações com apps de rota e caronas aparecerão aqui quando finalizarmos a experiência.',
        );
        break;
    }
  }

  Future<void> _openSearchDialog() async {
    final controller = TextEditingController();
    final query = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar pontos'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration:
              const InputDecoration(hintText: 'Digite o termo de busca'),
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
      ),
    );
    if (query == null) {
      return;
    }
    if (query.trim().isEmpty) {
      await _cityMapController.clearSearch();
    } else {
      await _cityMapController.searchPois(query.trim());
    }
  }

  Future<void> _centerOnUser() async {
    final coordinate = _cityMapController.userLocationStreamValue.value;
    if (coordinate == null) {
      _showSnackbar('Ainda estamos localizando você.');
      return;
    }
    final target = LatLng(coordinate.latitude, coordinate.longitude);
    _cityMapController.mapController.move(target, 15);
  }

  Future<void> _showSimpleSheet({
    required String title,
    required String description,
  }) async {
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackbar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _initializeController() async {
    await _simulateDelay();
    await _cityMapController.loadMainFilters();
    await _cityMapController.loadFilters();
    await _simulateDelay();
    await _cityMapController.loadRegions();
    await _simulateDelay();
    await _cityMapController.loadPois(const PoiQuery());
    await _simulateDelay();
    await _cityMapController.resolveUserLocation();
  }

  Future<void> _simulateDelay() =>
      Future<void>.delayed(const Duration(milliseconds: 650));
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({
    required this.onSearch,
    required this.onLocate,
  });

  final VoidCallback onSearch;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 4,
      color: scheme.surfaceContainerHigh.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.map_outlined),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Mapa • Guarapari',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Buscar pontos',
              onPressed: onSearch,
            ),
            IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: 'Centralizar em mim',
              onPressed: onLocate,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrototypeMapLayers extends StatelessWidget {
  const _PrototypeMapLayers({
    required this.controller,
    required this.defaultCenter,
    required this.onSelectPoi,
    required this.onHoverChange,
    required this.onSelectEvent,
    required this.onMapInteraction,
  });

  final CityMapController controller;
  final CityCoordinate defaultCenter;
  final ValueChanged<CityPoiModel?> onSelectPoi;
  final ValueChanged<String?> onHoverChange;
  final ValueChanged<EventModel?> onSelectEvent;
  final VoidCallback onMapInteraction;

  @override
  Widget build(BuildContext context) {
    final defaultLatLng = LatLng(
      defaultCenter.latitude,
      defaultCenter.longitude,
    );

    return StreamValueBuilder<List<CityPoiModel>>(
      streamValue: controller.pois,
      builder: (_, pois) {
        return StreamValueBuilder<List<EventModel>>(
          streamValue: controller.eventsStreamValue,
          builder: (_, events) {
            return StreamValueBuilder<CityCoordinate?>(
              streamValue: controller.userLocationStreamValue,
              builder: (_, coordinate) {
                final userLatLng = coordinate == null
                    ? null
                    : LatLng(coordinate.latitude, coordinate.longitude);
                return StreamValueBuilder<CityPoiModel?>(
                  streamValue: controller.selectedPoiStreamValue,
                  builder: (_, selectedPoi) {
                    return StreamValueBuilder<EventModel?>(
                      streamValue: controller.selectedEventStreamValue,
                      builder: (_, selectedEvent) {
                        return StreamValueBuilder<String?>(
                          streamValue: controller.hoveredPoiIdStreamValue,
                          builder: (_, hoveredId) {
                            return CityMapView(
                              pois: pois,
                              selectedPoi: selectedPoi,
                              onSelectPoi: onSelectPoi,
                              hoveredPoiId: hoveredId,
                              onHoverChange: onHoverChange,
                              events: events,
                              selectedEvent: selectedEvent,
                              onSelectEvent: onSelectEvent,
                              userPosition: userLatLng,
                              defaultCenter: defaultLatLng,
                              onMapInteraction: onMapInteraction,
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
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.controller});

  final CityMapController controller;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodySmall;
    return StreamValueBuilder<MapStatus>(
      streamValue: controller.mapStatusStreamValue,
      builder: (_, status) {
        return StreamValueBuilder<String?>(
          streamValue: controller.statusMessageStreamValue,
          builder: (_, message) {
            final resolvedMessage =
                message ?? _fallbackMessage(status);
            if (resolvedMessage == null) {
              return const SizedBox.shrink();
            }
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                resolvedMessage,
                style: baseStyle?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ) ??
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            );
          },
        );
      },
    );
  }

  String? _fallbackMessage(MapStatus status) {
    switch (status) {
      case MapStatus.locating:
        return 'Localizando você...';
      case MapStatus.fetching:
        return 'Buscando pontos de interesse...';
      case MapStatus.fallback:
        return 'Exibindo mapa padrão da cidade.';
      case MapStatus.error:
        return 'Não foi possível atualizar o mapa.';
      case MapStatus.ready:
        return null;
    }
  }
}
