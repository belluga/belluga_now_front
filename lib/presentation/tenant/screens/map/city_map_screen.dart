import 'dart:async';

import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/presentation/common/widgets/main_logo.dart';
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

  @override
  void initState() {
    super.initState();
    _controller.init();
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
        title: const MainLogo(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Recarregar pontos',
            onPressed: _controller.loadPoints,
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
      setState(() {
        _userPosition = userLatLng;
        _isLoadingPosition = false;
      });

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
    } catch (_) {
      setState(() {
        _errorMessage = 'Não foi possível obter a localização.';
        _isLoadingPosition = false;
      });
    }
  }

  void _centerOnUser() {
    final position = _userPosition;
    if (position == null) return;
    _mapController.move(position, 15);
    _controller.selectPoi(null);
  }
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
