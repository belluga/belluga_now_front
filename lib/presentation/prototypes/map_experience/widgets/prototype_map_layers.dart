import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/presentation/prototypes/map_experience/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/prototypes/map_experience/widgets/poi_marker_builder.dart';
import 'package:flutter/material.dart';
import 'package:free_map/free_map.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class PrototypeMapLayers extends StatelessWidget {
  PrototypeMapLayers({super.key})
      : _controller = GetIt.I.get<MapScreenController>(),
        _markerBuilder = const PoiMarkerBuilder();

  final MapScreenController _controller;
  final PoiMarkerBuilder _markerBuilder;

  @override
  Widget build(BuildContext context) {
    final defaultLatLng = LatLng(
      _controller.defaultCenter.latitude,
      _controller.defaultCenter.longitude,
    );

    return StreamValueBuilder<List<CityPoiModel>>(
      streamValue: _controller.allPois,
      builder: (_, pois) {
        return StreamValueBuilder<CityPoiModel?>(
          streamValue: _controller.selectedPoiStreamValue,
          builder: (_, selectedPoi) {
            return StreamValueBuilder<CityCoordinate?>(
              streamValue: _controller.userLocationStreamValue,
              builder: (_, userCoordinate) {
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
                    onTap: () => _controller.selectPoi(poi),
                  ),
                );

                final markers = <Marker>[
                  if (userPoint != null) _buildUserMarker(userPoint),
                  ...poiMarkers,
                ];

                return FmMap(
                  mapController: _controller.mapController,
                  mapOptions: MapOptions(
                    initialCenter: defaultLatLng,
                    initialZoom: 14,
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
  }

  Marker _buildUserMarker(LatLng position) {
    return Marker(
      point: position,
      width: 48,
      height: 48,
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
}
