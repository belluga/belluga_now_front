// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/city_map_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/city_map_view.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class CityMapLayers extends StatelessWidget {
  CityMapLayers({
    super.key,
    CityMapController? controller,
    required this.defaultCenter,
    required this.onSelectPoi,
    required this.onHoverChange,
    required this.onSelectEvent,
    required this.onMapInteraction,
  }) : _controller = controller ?? GetIt.I.get<CityMapController>();

  @visibleForTesting
  CityMapLayers.withController(
    this._controller, {
    super.key,
    required this.defaultCenter,
    required this.onSelectPoi,
    required this.onHoverChange,
    required this.onSelectEvent,
    required this.onMapInteraction,
  });

  final CityMapController _controller;
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
      streamValue: _controller.pois,
      builder: (_, pois) {
        return StreamValueBuilder<List<EventModel>>(
          streamValue: _controller.eventsStreamValue,
          builder: (_, events) {
            return StreamValueBuilder<CityCoordinate?>(
              streamValue: _controller.userLocationStreamValue,
              builder: (_, coordinate) {
                final userLatLng = coordinate == null
                    ? null
                    : LatLng(coordinate.latitude, coordinate.longitude);
                return StreamValueBuilder<CityPoiModel?>(
                  streamValue: _controller.selectedPoiStreamValue,
                  builder: (_, selectedPoi) {
                    return StreamValueBuilder<EventModel?>(
                      streamValue: _controller.selectedEventStreamValue,
                      builder: (_, selectedEvent) {
                        return StreamValueBuilder<String?>(
                          streamValue: _controller.hoveredPoiIdStreamValue,
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
