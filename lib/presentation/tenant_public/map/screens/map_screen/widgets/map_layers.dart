import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/projections/city_poi_visual.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_marker_builder.dart';
import 'package:flutter/material.dart';
import 'package:free_map/free_map.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class MapLayers extends StatelessWidget {
  const MapLayers({
    super.key,
    required MapScreenController controller,
  })  : _controller = controller,
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

    return StreamValueBuilder<PoiFilterOptions?>(
      streamValue: _controller.filterOptionsStreamValue,
      builder: (_, filterOptions) {
        return StreamValueBuilder<String?>(
          streamValue: _controller.appliedCatalogFilterKeyStreamValue,
          builder: (_, appliedCatalogFilterKey) {
            final markerOverrideVisual = _resolveMarkerOverrideVisual(
              filterOptions: filterOptions,
              activeCatalogFilterKey: appliedCatalogFilterKey,
            );
            return StreamValueBuilder<List<CityPoiModel>?>(
              streamValue: _controller.filteredPoisStreamValue,
              builder: (_, poisOrNull) {
                final pois = poisOrNull ?? const <CityPoiModel>[];
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
                            // Keep event markers slightly larger than regular POIs, but
                            // bound to the same zoom curve so they still shrink/grow
                            // proportionally while zooming.
                            final eventSize =
                                (poiSize * 1.18).clamp(30.0, 78.0);
                            final userSize = _scaledSize(
                              currentZoom,
                              minSize: 36,
                              maxSize: 52,
                            );

                            final userPoint = switch (userCoordinate) {
                              final coordinate? => LatLng(
                                  coordinate.latitude,
                                  coordinate.longitude,
                                ),
                              null => null,
                            };
                            final poiMarkers = pois.map(
                              (poi) => _markerBuilder.build(
                                poi: poi,
                                isSelected: _isPoiSelected(
                                  selectedPoi: selectedPoi,
                                  markerPoi: poi,
                                ),
                                onTap: () => _controller.handleMarkerTap(poi),
                                size: poi.isDynamic ? eventSize : poiSize,
                                overrideVisual: markerOverrideVisual,
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
                                  final nextZoom = event.camera.zoom.clamp(
                                      MapScreenController.minZoom,
                                      MapScreenController.maxZoom);
                                  _controller.zoomStreamValue
                                      .addValue(nextZoom);
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
                                onTap: (_, __) =>
                                    _controller.clearSelectedPoi(),
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
          },
        );
      },
    );
  }

  CityPoiVisual? _resolveMarkerOverrideVisual({
    required PoiFilterOptions? filterOptions,
    required String? activeCatalogFilterKey,
  }) {
    final key = activeCatalogFilterKey?.trim().toLowerCase();
    if (filterOptions == null || key == null || key.isEmpty) {
      return null;
    }

    for (final category in filterOptions.categories) {
      if (category.key.trim().toLowerCase() != key) {
        continue;
      }
      return category.markerOverrideVisual;
    }

    return null;
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

  bool _isPoiSelected({
    required CityPoiModel? selectedPoi,
    required CityPoiModel markerPoi,
  }) {
    if (selectedPoi == null) {
      return false;
    }
    if (selectedPoi.id == markerPoi.id) {
      return true;
    }
    return selectedPoi.stackKey.isNotEmpty &&
        selectedPoi.stackKey == markerPoi.stackKey;
  }
}
