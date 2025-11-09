import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/city_map_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/city_map_view.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class CityMapLayers extends StatelessWidget {
  const CityMapLayers({
    super.key,
    required this.controller,
    required this.defaultCenter,
    required this.onSelectPoi,
    required this.onHoverChange,
    required this.onSelectEvent,
    required this.onMapInteraction,
  });

  final CityMapController controller;
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
      streamValue: controller.pois,
      builder: (_, pois) {
        return StreamValueBuilder<List<EventModel>>(
          streamValue: controller.eventsStreamValue,
          builder: (_, events) {
            return StreamValueBuilder<CityCoordinate?>(
              streamValue: controller.userLocationStreamValue,
              builder: (_, coordinate) {
                final userLatLng = coordinate == null
                    ? null
                    : LatLng(coordinate.latitude, coordinate.longitude);
                return StreamValueBuilder<CityPoiModel?>(
                  streamValue: controller.selectedPoiStreamValue,
                  builder: (_, selectedPoi) {
                    return StreamValueBuilder<EventModel?>(
                      streamValue: controller.selectedEventStreamValue,
                      builder: (_, selectedEvent) {
                        return StreamValueBuilder<String?>(
                          streamValue: controller.hoveredPoiIdStreamValue,
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
