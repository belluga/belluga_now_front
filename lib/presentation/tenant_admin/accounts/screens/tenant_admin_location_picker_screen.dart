import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_location_picker_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:stream_value/core/stream_value_builder.dart';

@RoutePage()
class TenantAdminLocationPickerScreen extends StatefulWidget {
  const TenantAdminLocationPickerScreen({
    super.key,
    this.initialLocation,
    required this.controller,
  });

  final TenantAdminLocation? initialLocation;
  final TenantAdminLocationPickerController controller;

  @override
  State<TenantAdminLocationPickerScreen> createState() =>
      _TenantAdminLocationPickerScreenState();
}

class _TenantAdminLocationPickerScreenState
    extends State<TenantAdminLocationPickerScreen> {
  static const LatLng _defaultCenter = LatLng(-20.6736, -40.4976);
  static const double _defaultZoom = 15.5;

  late final TenantAdminLocationPickerController _controller;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.setInitialLocation(widget.initialLocation);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng _centerForLocation(TenantAdminLocation? location) {
    if (location == null) {
      return _defaultCenter;
    }
    return LatLng(location.latitude, location.longitude);
  }

  void _onMapTap(LatLng point) {
    _controller.setLocation(
      TenantAdminLocation(latitude: point.latitude, longitude: point.longitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Localização'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.router.maybePop(),
        ),
      ),
      body: StreamValueBuilder<TenantAdminLocation?>(
        streamValue: _controller.locationStreamValue,
        builder: (context, location) {
          final center = _centerForLocation(location);
          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: _defaultZoom,
                  minZoom: 12,
                  maxZoom: 18,
                  onTap: (tapPosition, latLng) => _onMapTap(latLng),
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    rotationWinGestures: MultiFingerGesture.none,
                    cursorKeyboardRotationOptions:
                        CursorKeyboardRotationOptions.disabled(),
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.belluganow.app',
                  ),
                  MarkerLayer(
                    markers: [
                      if (location != null)
                        Marker(
                          point: LatLng(
                            location.latitude,
                            location.longitude,
                          ),
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.redAccent,
                            size: 48,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              location == null
                                  ? 'Toque no mapa para selecionar.'
                                  : 'Lat ${location.latitude.toStringAsFixed(6)} · Lng ${location.longitude.toStringAsFixed(6)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: location == null
                                ? null
                                : () => context.router.pop(location),
                            child: const Text('Confirmar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
