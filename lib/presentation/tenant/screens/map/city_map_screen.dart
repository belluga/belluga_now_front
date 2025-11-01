import 'dart:async';

import 'package:belluga_now/presentation/common/widgets/main_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:free_map/fm_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

part 'city_poi.dart';

class CityMapScreen extends StatefulWidget {
  const CityMapScreen({super.key});

  @override
  State<CityMapScreen> createState() => _CityMapScreenState();
}

class _CityMapScreenState extends State<CityMapScreen> {
  final _mapController = MapController();
  final List<CityPoi> _pois = CityPoiData.points;

  LatLng? _userPosition;
  String? _errorMessage;
  bool _isLoadingPosition = true;
  CityPoi? _selectedPoi;

  @override
  void initState() {
    super.initState();
    _resolveUserLocation();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const MainLogo(),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_outlined),
            tooltip: 'Centralizar na minha posição',
            onPressed: _userPosition == null ? null : _centerOnUser,
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildMap(theme),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildStatusBanner(theme),
          ),
          _PoiInfoCard(
            poi: _selectedPoi,
            onDismiss: () => setState(() => _selectedPoi = null),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(ThemeData theme) {
    final initialCenter = _userPosition ?? CityPoiData.defaultCenter;
    final markers = <Marker>[
      if (_userPosition != null)
        Marker(
          point: _userPosition!,
          width: 48,
          height: 48,
          child: const _UserMarker(),
        ),
      ..._pois.map(_buildPoiMarker),
    ];

    return ClipRect(
      child: FmMap(
        mapController: _mapController,
        mapOptions: MapOptions(
          initialCenter: initialCenter,
          initialZoom: 14,
          minZoom: 11,
          maxZoom: 19,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        markers: markers,
        attributionAlignment: Alignment.bottomRight,
        attributionStyle: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildStatusBanner(ThemeData theme) {
    if (_isLoadingPosition) {
      return _StatusChip(
        icon: Icons.hourglass_bottom,
        label: 'Localizando você... ',
        color: theme.colorScheme.surfaceContainerHighest,
        textColor: theme.colorScheme.onSurfaceVariant,
      );
    }

    if (_errorMessage != null) {
      return _StatusChip(
        icon: Icons.warning_amber_rounded,
        label: _errorMessage!,
        color: theme.colorScheme.errorContainer,
        textColor: theme.colorScheme.onErrorContainer,
      );
    }

    return const SizedBox.shrink();
  }

  Marker _buildPoiMarker(CityPoi poi) {
    return Marker(
      point: poi.coordinate,
      width: 52,
      height: 52,
      child: GestureDetector(
        onTap: () => setState(() => _selectedPoi = poi),
        child: _PoiMarker(poi: poi, isSelected: poi == _selectedPoi),
      ),
    );
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
    } on PlatformException catch (e) {
      setState(() {
        _errorMessage =
            'Não foi possível obter a localização (${e.code}).';
        _isLoadingPosition = false;
      });
    } catch (e) {
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
    setState(() => _selectedPoi = null);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PoiMarker extends StatelessWidget {
  const _PoiMarker({required this.poi, required this.isSelected});

  final CityPoi poi;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? poi.category.selectedColor : poi.category.color;
    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: isSelected ? 1.15 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Icon(poi.category.icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _PoiInfoCard extends StatelessWidget {
  const _PoiInfoCard({required this.poi, required this.onDismiss});

  final CityPoi? poi;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    if (poi == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Card(
              key: ValueKey(poi!.name),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: poi!.category.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            poi!.category.icon,
                            color: poi!.category.color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                poi!.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                poi!.category.label,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: onDismiss,
                          icon: const Icon(Icons.close),
                          tooltip: 'Fechar',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      poi!.description,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            poi!.address,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserMarker extends StatelessWidget {
  const _UserMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: const Icon(Icons.my_location, color: Colors.white, size: 20),
    );
  }
}
