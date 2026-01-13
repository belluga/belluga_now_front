import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/presentation/prototypes/map_experience/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/prototypes/map_experience/widgets/poi_marker_builder.dart';
import 'package:belluga_now/domain/map/event_poi_model.dart';
import 'package:flutter/material.dart';
import 'package:free_map/free_map.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class PrototypeMapLayers extends StatelessWidget {
  PrototypeMapLayers({super.key})
      : _controller = GetIt.I.get<MapScreenController>(),
        _markerBuilder = const PoiMarkerBuilder();

  static const double _minZoom = 14.5;
  static const double _maxZoom = 17.0;

  final MapScreenController _controller;
  final PoiMarkerBuilder _markerBuilder;

  @override
  Widget build(BuildContext context) {
    final defaultLatLng = LatLng(
      _controller.defaultCenter.latitude,
      _controller.defaultCenter.longitude,
    );

    return StreamValueBuilder<List<CityPoiModel>>(
      streamValue: _controller.filteredPoisStreamValue,
      builder: (_, pois) {
        return StreamValueBuilder<CityPoiModel?>(
          streamValue: _controller.selectedPoiStreamValue,
          builder: (_, selectedPoi) {
            return StreamValueBuilder<CityCoordinate?>(
              streamValue: _controller.userLocationStreamValue,
              builder: (_, userCoordinate) {
                return StreamValueBuilder<double>(
                  streamValue: _controller.zoomStreamValue,
                  builder: (_, zoom) {
                    final currentZoom = zoom;
                    final poiSize = _scaledSize(
                      currentZoom,
                      minSize: 26,
                      maxSize: 65,
                    );
                    final eventSize = _scaledSize(
                      currentZoom,
                      minSize: 70,
                      maxSize: 100,
                    );
                    final userSize = _scaledSize(
                      currentZoom,
                      minSize: 36,
                      maxSize: 52,
                    );

                    final userPoint = userCoordinate == null
                        ? null
                        : LatLng(
                            userCoordinate.latitude,
                            userCoordinate.longitude,
                          );
                    final poiMarkers = pois.map(
                      (poi) => _markerBuilder.build(
                        poi: poi,
                        isSelected: selectedPoi?.id == poi.id,
                        onTap: () {
                          _controller.selectPoi(poi);
                          if (poi is EventPoiModel) {
                            _openEventDetails(context, poi.event.slug);
                          }
                        },
                        size: poi is EventPoiModel ? eventSize : poiSize,
                      ),
                    );

                    final markers = <Marker>[
                      if (userPoint != null)
                        _buildUserMarker(userPoint, userSize),
                      ...poiMarkers,
                    ];

                    return FmMap(
                      mapController: _controller.mapController,
                      mapOptions: MapOptions(
                        initialCenter: defaultLatLng,
                        initialZoom: 16,
                        minZoom: _minZoom,
                        maxZoom: _maxZoom,
                        onMapEvent: (event) {
                          final nextZoom = event.camera.zoom
                              .clamp(MapScreenController.minZoom,
                                  MapScreenController.maxZoom);
                          _controller.zoomStreamValue.addValue(nextZoom);
                        },
                        interactionOptions: InteractionOptions(
                          flags: InteractiveFlag.drag |
                              InteractiveFlag.pinchZoom |
                              InteractiveFlag.doubleTapZoom |
                              InteractiveFlag.scrollWheelZoom,
                          rotationWinGestures: MultiFingerGesture.none,
                          enableMultiFingerGestureRace: false,
                          cursorKeyboardRotationOptions:
                              CursorKeyboardRotationOptions.disabled(),
                        ),
                        onTap: (_, __) => _controller.clearSelectedPoi(),
                      ),
                      markers: markers,
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

  Marker _buildUserMarker(LatLng position, double size) {
    return Marker(
      point: position,
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black54),
        ),
        child: const Center(
          child: Icon(
            Icons.my_location,
            size: 20,
            color: Colors.blueAccent,
          ),
        ),
      ),
    );
  }

  double _scaledSize(
    double zoom, {
    required double minSize,
    required double maxSize,
  }) {
    final t = ((zoom - _minZoom) / (_maxZoom - _minZoom)).clamp(0.0, 1.0);
    return minSize + (maxSize - minSize) * t;
  }

  void _openEventDetails(BuildContext context, String slug) {
    if (slug.isEmpty) {
      return;
    }
    context.router.push(ImmersiveEventDetailRoute(eventSlug: slug));
  }
}
