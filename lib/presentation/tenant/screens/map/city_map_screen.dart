import 'dart:async';

import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/presentation/tenant/screens/map/controller/city_map_controller.dart';
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
import 'package:url_launcher/url_launcher.dart';

class CityMapScreen extends StatefulWidget {
  const CityMapScreen({super.key});

  @override
  State<CityMapScreen> createState() => _CityMapScreenState();
}

class _CityMapScreenState extends State<CityMapScreen> {
  final _mapController = MapController();
  final _controller = GetIt.I.get<CityMapController>();

  LatLng? _userPosition;
  String? _errorMessage;
  bool _isLoadingPosition = true;
  bool _hasRequestedPois = false;
  CityCoordinate? _userOrigin;

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Guarapari'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Recarregar pontos',
            onPressed: _userOrigin == null
                ? null
                : () => _controller.loadPoints(_userOrigin!),
          ),
          IconButton(
            icon: const Icon(Icons.my_location_outlined),
            tooltip: 'Centralizar na minha posição',
            onPressed: _userPosition == null ? null : _centerOnUser,
          ),
        ],
      ),
      body: StreamValueBuilder<List<CityPoiModel>?>(
        streamValue: _controller.poisStreamValue,
        onNullWidget: const Center(child: CircularProgressIndicator()),
        builder: (context, pois) {
          final poiList = pois ?? const <CityPoiModel>[];
          return StreamValueBuilder<CityPoiModel?>(
            streamValue: _controller.selectedPoiStreamValue,
            builder: (context, selectedPoi) {
              return Stack(
                children: [
                  _CityMapView(
                    mapController: _mapController,
                    pois: poiList,
                    selectedPoi: selectedPoi,
                    onSelectPoi: _controller.selectPoi,
                    userPosition: _userPosition,
                    defaultCenter: LatLng(
                      _controller.defaultCenter.latitude,
                      _controller.defaultCenter.longitude,
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: _buildStatusBanner(theme),
                  ),
                  if (selectedPoi != null)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                        child: PoiInfoCard(
                          poi: selectedPoi,
                          onDismiss: () => _controller.selectPoi(null),
                          onRoute: () => _showRouteOptions(selectedPoi),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner(ThemeData theme) {
    if (_isLoadingPosition) {
      return LocationStatusBanner(
        icon: Icons.hourglass_bottom,
        label: 'Localizando você... ',
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        textColor: theme.colorScheme.onSurfaceVariant,
      );
    }

    if (_errorMessage != null) {
      return LocationStatusBanner(
        icon: Icons.warning_amber_rounded,
        label: _errorMessage!,
        backgroundColor: theme.colorScheme.errorContainer,
        textColor: theme.colorScheme.onErrorContainer,
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _resolveUserLocation() async {
    setState(() {
      _isLoadingPosition = true;
      _errorMessage = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Ative os serviços de localização para ver sua posição.';
          _isLoadingPosition = false;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _errorMessage =
              'Permita o acesso à localização para localizar pontos próximos.';
          _isLoadingPosition = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      final userLatLng = LatLng(position.latitude, position.longitude);
      final origin = CityCoordinate(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      setState(() {
        _userPosition = userLatLng;
        _userOrigin = origin;
        _isLoadingPosition = false;
      });

      if (!_hasRequestedPois) {
        _hasRequestedPois = true;
        unawaited(_controller.loadPoints(origin));
      }

      unawaited(Future<void>.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _mapController.move(userLatLng, 15);
        }
      }));
    } on PlatformException catch (error) {
      setState(() {
        _errorMessage = 'Não foi possível obter a localização (${error.code}).';
        _isLoadingPosition = false;
      });
      _fallbackLoadPois();
    } catch (_) {
      setState(() {
        _errorMessage = 'Não foi possível obter a localização.';
        _isLoadingPosition = false;
      });
      _fallbackLoadPois();
    }
  }

  void _centerOnUser() {
    final position = _userPosition;
    if (position == null) return;
    _mapController.move(position, 15);
    _controller.selectPoi(null);
  }

  Future<void> _showRouteOptions(CityPoiModel poi) async {
    final destination = '${poi.coordinate.latitude},${poi.coordinate.longitude}';
    final options = [
      _RouteOption(
        label: 'Google Maps',
        icon: Icons.map_outlined,
        uri: Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$destination'),
      ),
      _RouteOption(
        label: 'Waze',
        icon: Icons.directions_car_filled_outlined,
        uri: Uri.parse('https://waze.com/ul?ll=$destination&navigate=yes'),
      ),
      _RouteOption(
        label: 'Uber',
        icon: Icons.local_taxi_outlined,
        uri: Uri.parse('uber://?action=setPickup&dropoff[latitude]=${poi.coordinate.latitude}&dropoff[longitude]=${poi.coordinate.longitude}&dropoff[nickname]=${Uri.encodeComponent(poi.name)}'),
        fallback: Uri.parse('https://m.uber.com/ul/?action=setPickup&dropoff[latitude]=${poi.coordinate.latitude}&dropoff[longitude]=${poi.coordinate.longitude}&dropoff[nickname]=${Uri.encodeComponent(poi.name)}'),
      ),
    ];

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Abrir rota',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final option in options)
              ListTile(
                leading: Icon(option.icon),
                title: Text(option.label),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _launchUri(option.uri, fallback: option.fallback);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUri(Uri uri, {Uri? fallback}) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (fallback != null && await canLaunchUrl(fallback)) {
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Não foi possível abrir o aplicativo de rotas.'),
      ),
    );
  }

  void _fallbackLoadPois() {
    if (_hasRequestedPois) return;
    _hasRequestedPois = true;
    final center = _controller.defaultCenter;
    _controller.loadPoints(center);
  }
}

class _RouteOption {
  const _RouteOption({
    required this.label,
    required this.icon,
    required this.uri,
    this.fallback,
  });

  final String label;
  final IconData icon;
  final Uri uri;
  final Uri? fallback;
}

class _CityMapView extends StatelessWidget {
  const _CityMapView({
    required this.mapController,
    required this.pois,
    required this.selectedPoi,
    required this.onSelectPoi,
    required this.userPosition,
    required this.defaultCenter,
  });

  final MapController mapController;
  final List<CityPoiModel> pois;
  final CityPoiModel? selectedPoi;
  final ValueChanged<CityPoiModel?> onSelectPoi;
  final LatLng? userPosition;
  final LatLng defaultCenter;

  @override
  Widget build(BuildContext context) {
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
