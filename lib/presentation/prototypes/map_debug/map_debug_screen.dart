import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapDebugScreen extends StatefulWidget {
  const MapDebugScreen({super.key});

  @override
  State<MapDebugScreen> createState() => _MapDebugScreenState();
}

class _MapDebugScreenState extends State<MapDebugScreen> {
  static const double _minZoom = 14.5;
  static const double _maxZoom = 17.0;
  static const LatLng _center = LatLng(-20.6736, -40.4976);

  final MapController _mapController = MapController();
  late double _currentZoom = 16;
  StreamSubscription<MapEvent>? _mapSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attachZoomListener());
  }

  @override
  void dispose() {
    _mapSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  double _sizeForZoom({
    required double zoom,
    required double minSize,
    required double maxSize,
  }) {
    final t = ((zoom - _minZoom) / (_maxZoom - _minZoom))
        .clamp(0.0, 1.0);
    return lerpDouble(minSize, maxSize, t)!;
  }

  void _attachZoomListener() {
    _currentZoom = _mapController.camera.zoom.clamp(_minZoom, _maxZoom);
    _mapSub = _mapController.mapEventStream.listen((event) {
      if (event is MapEventMove ||
          event is MapEventMoveStart ||
          event is MapEventMoveEnd ||
          event is MapEventDoubleTapZoom ||
          event is MapEventFlingAnimation) {
        final nextZoom = event.camera.zoom.clamp(_minZoom, _maxZoom);
        if (nextZoom != _currentZoom) {
          setState(() => _currentZoom = nextZoom);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final markerSize =
        _sizeForZoom(zoom: _currentZoom, minSize: 26, maxSize: 65);
    final userSize =
        _sizeForZoom(zoom: _currentZoom, minSize: 44, maxSize: 60);
    // Linear map: 26px -> 16px, 65px -> 36px
    final iconSize = lerpDouble(16, 36,
        ((markerSize - 26) / (65 - 26)).clamp(0.0, 1.0))!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Debug Prototype'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                'Zoom ${_currentZoom.toStringAsFixed(2)} | POI ${markerSize.toStringAsFixed(1)} | Icon ${iconSize.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _center,
          initialZoom: 16,
          minZoom: _minZoom,
          maxZoom: _maxZoom,
          onMapEvent: (event) {
            final next = event.camera.zoom.clamp(_minZoom, _maxZoom);
            if (next != _currentZoom) {
              setState(() => _currentZoom = next);
            }
          },
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
              Marker(
                point: _center,
                width: userSize,
                height: userSize,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.my_location, color: Colors.white),
                ),
              ),
              for (final offset in [
                const LatLng(-20.6736, -40.492),
                const LatLng(-20.678, -40.4976),
                const LatLng(-20.669, -40.503),
              ])
                Marker(
                  point: offset,
                  width: markerSize,
                  height: markerSize,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.pinkAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.place,
                        color: Colors.white,
                        size: iconSize,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
