import 'dart:async';

import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/screens/map/controller/city_map_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/event_info_card.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/event_marker.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/location_status_banner.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/poi_info_card.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/poi_marker.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/user_location_marker.dart';
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
  String? _statusMessage = 'Localizando você...';

  @override
  void initState() {
    super.initState();
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
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Recarregar pontos',
            onPressed: _userOrigin == null
                ? null
                : () async {
                    setState(() {
                      _status = _MapStatus.fetching;
                      _statusMessage = 'Buscando pontos próximos...';
                    });
                    final success =
                        await _controller.loadPoints(_userOrigin!);
                    await _loadTodayEvents();
                    if (!mounted) return;
                    setState(() {
                      _status = success ? _MapStatus.ready : _MapStatus.error;
                      _statusMessage = success
                          ? null
                          : 'Não foi possível carregar os pontos próximos.';
                    });
                  },
          ),
          IconButton(
            icon: const Icon(Icons.my_location_outlined),
            tooltip: 'Centralizar na minha posição',
            onPressed: _userPosition == null ? null : _centerOnUser,
          ),
        ],
      ),
      body: StreamValueBuilder<List<EventModel>?>(
        streamValue: _controller.eventsStreamValue,
        builder: (context, events) {
          final eventList = events ?? const <EventModel>[];
          return StreamValueBuilder<List<CityPoiModel>?>(
            streamValue: _controller.poisStreamValue,
            builder: (context, pois) {
              final poiList = pois ?? const <CityPoiModel>[];
              return StreamValueBuilder<CityPoiModel?>(
                streamValue: _controller.selectedPoiStreamValue,
                builder: (context, selectedPoi) {
                  return StreamValueBuilder<EventModel?>(
                    streamValue: _controller.selectedEventStreamValue,
                    builder: (context, selectedEvent) {
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
                          ),
                          Positioned(
                            top: 16,
                            left: 16,
                            right: 16,
                            child: _buildStatusBanner(theme),
                          ),
                          if (selectedEvent != null)
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(24, 0, 24, 32),
                                child: SafeArea(
                                  child: EventInfoCard(
                                    event: selectedEvent,
                                    onDismiss: () =>
                                        _controller.selectEvent(null),
                                  ),
                                ),
                              ),
                            )
                          else if (selectedPoi != null)
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(24, 0, 24, 32),
                                child: SafeArea(
                                  child: PoiInfoCard(
                                    poi: selectedPoi,
                                    onDismiss: () =>
                                        _controller.selectPoi(null),
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
      ),
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
      _statusMessage = 'Localizando você...';
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _status = _MapStatus.error;
          _statusMessage =
              'Ative os serviços de localização para ver sua posição. Exibindo pontos padrão da cidade.';
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
              'Permita o acesso à localização para localizar pontos próximos. Exibindo pontos padrão da cidade.';
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
        _statusMessage = 'Buscando pontos próximos...';
      });

      final poiSuccess = await _controller.loadPoints(origin);
      await _loadTodayEvents();
      if (mounted) {
        setState(() {
          _status = poiSuccess ? _MapStatus.ready : _MapStatus.error;
          _statusMessage = poiSuccess
              ? null
              : 'Não foi possível carregar os pontos próximos.';
        });
      }

      _hasRequestedPois = true;

      if (mounted) {
        _mapController.move(userLatLng, 15);
      }
    } on PlatformException catch (error) {
      setState(() {
        _status = _MapStatus.error;
        _statusMessage =
            'Não foi possível obter a localização (${error.code}). Exibindo pontos padrão da cidade.';
      });
      _fallbackLoadPois();
      await _loadTodayEvents();
    } catch (_) {
      setState(() {
        _status = _MapStatus.error;
        _statusMessage =
            'Não foi possível obter a localização. Exibindo pontos padrão da cidade.';
      });
      _fallbackLoadPois();
      await _loadTodayEvents();
    }
  }

  void _centerOnUser() {
    final position = _userPosition;
    if (position == null) return;
    _mapController.move(position, 15);
    _controller.selectPoi(null);
    _controller.selectEvent(null);
  }

  void _fallbackLoadPois() {
    if (_hasRequestedPois) return;
    _hasRequestedPois = true;
    final center = _controller.defaultCenter;
    setState(() {
      _status = _MapStatus.fallback;
      _statusMessage = 'Exibindo pontos padrão da cidade.';
    });
    unawaited(() async {
      final success = await _controller.loadPoints(center);
      await _loadTodayEvents();
      if (!mounted) return;
      setState(() {
        _status = success ? _MapStatus.ready : _MapStatus.error;
        _statusMessage = success
            ? null
            : 'Não foi possível carregar os pontos padrão.';
      });
    }());
  }

  Future<void> _loadTodayEvents() async {
    if (_eventsLoaded) {
      await _controller.loadEventsForDate(_today);
      return;
    }
    _eventsLoaded = true;
    await _controller.loadEventsForDate(_today);
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}

enum _MapStatus { locating, fetching, ready, error, fallback }

class _CityMapView extends StatelessWidget {
  const _CityMapView({
    required this.mapController,
    required this.pois,
    required this.selectedPoi,
    required this.onSelectPoi,
    required this.events,
    required this.selectedEvent,
    required this.onSelectEvent,
    required this.userPosition,
    required this.defaultCenter,
  });

  final MapController mapController;
  final List<CityPoiModel> pois;
  final CityPoiModel? selectedPoi;
  final ValueChanged<CityPoiModel?> onSelectPoi;
  final List<EventModel> events;
  final EventModel? selectedEvent;
  final ValueChanged<EventModel?> onSelectEvent;
  final LatLng? userPosition;
  final LatLng defaultCenter;

  @override
  Widget build(BuildContext context) {
    final selectedEventId = selectedEvent?.id.value;
    final markers = <Marker>[
      if (userPosition != null)
        Marker(
          point: userPosition!,
          width: 48,
          height: 48,
          child: const UserLocationMarker(),
        ),
      ...pois.map(
        (poi) => Marker(
          point: LatLng(
            poi.coordinate.latitude,
            poi.coordinate.longitude,
          ),
          width: 52,
          height: 52,
          child: GestureDetector(
            onTap: () => onSelectPoi(poi),
            child: PoiMarker(
              poi: poi,
              isSelected: selectedPoi?.id == poi.id,
            ),
          ),
        ),
      ),
      ...events
          .where((event) => event.coordinate != null)
          .map(
            (event) => Marker(
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
    ];

    final initialCenter = userPosition ?? defaultCenter;

    return FmMap(
      mapController: mapController,
      mapOptions: MapOptions(
        initialCenter: initialCenter,
        initialZoom: userPosition != null ? 15 : 14,
        minZoom: 11,
        maxZoom: 19,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
      ),
      markers: markers,
      attributionAlignment: Alignment.bottomRight,
    );
  }
}
