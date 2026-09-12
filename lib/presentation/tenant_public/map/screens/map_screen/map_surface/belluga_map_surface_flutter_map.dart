import 'package:belluga_now/application/map_surface/belluga_map_handle_flutter_map.dart'
    as application_map_surface;
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/map_surface/belluga_map_surface_contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class BellugaMapSurface extends StatefulWidget {
  const BellugaMapSurface({
    super.key,
    required this.handle,
    required this.initialCenter,
    required this.initialZoom,
    required this.minZoom,
    required this.maxZoom,
    required this.annotations,
    this.onEmptyTap,
  });

  final BellugaMapHandleContract handle;
  final CityCoordinate initialCenter;
  final double initialZoom;
  final double minZoom;
  final double maxZoom;
  final List<BellugaMapAnnotation> annotations;
  final VoidCallback? onEmptyTap;

  @override
  State<BellugaMapSurface> createState() => _BellugaMapSurfaceState();
}

class _BellugaMapSurfaceState extends State<BellugaMapSurface> {
  CityCoordinate? _lastPublishedCenter;
  double? _lastPublishedZoom;
  bool _moveHadUserGesture = false;

  application_map_surface.BellugaMapHandle get _handle =>
      widget.handle as application_map_surface.BellugaMapHandle;

  @override
  Widget build(BuildContext context) {
    final initialCenter = LatLng(
      widget.initialCenter.latitude,
      widget.initialCenter.longitude,
    );
    return Stack(
      children: [
        FlutterMap(
          mapController: _handle.rawController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: widget.initialZoom,
            minZoom: widget.minZoom,
            maxZoom: widget.maxZoom,
            onMapReady: () {
              final camera = _handle.rawController.camera;
              _lastPublishedCenter = CityCoordinate.fromLatLng(camera.center);
              _lastPublishedZoom = camera.zoom;
              widget.handle.markReady();
            },
            onTap: (_, _) {
              widget.handle.emitInteraction(
                BellugaMapInteractionEvent(
                  type: BellugaMapInteractionType.emptyTap,
                  zoom: widget.handle.currentZoom,
                  userGesture: true,
                ),
              );
              widget.onEmptyTap?.call();
            },
            onPositionChanged: (camera, hasGesture) {
              if (hasGesture) {
                _moveHadUserGesture = true;
              }
            },
            onMapEvent: (event) {
              if (!_publishesViewportChange(event)) {
                return;
              }
              final camera = event.camera;
              final currentCenter = CityCoordinate.fromLatLng(camera.center);
              final previousCenter = _lastPublishedCenter;
              final previousZoom = _lastPublishedZoom;
              final userGesture =
                  _moveHadUserGesture ||
                  event is MapEventScrollWheelZoom ||
                  event is MapEventDoubleTapZoomEnd;
              _moveHadUserGesture = false;
              _lastPublishedCenter = currentCenter;
              _lastPublishedZoom = camera.zoom;
              final zoomChanged =
                  previousZoom != null &&
                  (previousZoom - camera.zoom).abs() >= 0.01;
              final centerChanged =
                  previousCenter != null &&
                  ((previousCenter.latitude - currentCenter.latitude).abs() >
                          0.000001 ||
                      (previousCenter.longitude - currentCenter.longitude)
                              .abs() >
                          0.000001);
              if (!zoomChanged && !centerChanged) {
                return;
              }
              widget.handle.emitInteraction(
                BellugaMapInteractionEvent(
                  type: zoomChanged
                      ? BellugaMapInteractionType.zoom
                      : BellugaMapInteractionType.pan,
                  zoom: camera.zoom,
                  viewport: widget.handle.currentViewport,
                  userGesture: userGesture,
                ),
              );
            },
            interactionOptions: InteractionOptions(
              flags:
                  InteractiveFlag.drag |
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.doubleTapZoom |
                  InteractiveFlag.scrollWheelZoom,
              rotationWinGestures: MultiFingerGesture.none,
              enableMultiFingerGestureRace: false,
              cursorKeyboardRotationOptions:
                  CursorKeyboardRotationOptions.disabled(),
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'belluga_now',
            ),
            if (widget.annotations.isNotEmpty)
              MarkerLayer(
                markers: widget.annotations
                    .map(
                      (annotation) => Marker(
                        point: LatLng(
                          annotation.coordinate.latitude,
                          annotation.coordinate.longitude,
                        ),
                        width: annotation.width,
                        height: annotation.height,
                        child: annotation.onTap == null
                            ? annotation.child
                            : GestureDetector(
                                onTap: annotation.onTap,
                                child: annotation.child,
                              ),
                      ),
                    )
                    .toList(growable: false),
              ),
          ],
        ),
        Positioned(
          left: 12,
          bottom: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                '© OpenStreetMap',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _publishesViewportChange(MapEvent event) =>
      event is MapEventMoveEnd ||
      event is MapEventFlingAnimationEnd ||
      event is MapEventDoubleTapZoomEnd ||
      event is MapEventScrollWheelZoom;
}
