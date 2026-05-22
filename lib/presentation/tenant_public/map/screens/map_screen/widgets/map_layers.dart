import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/projections/city_poi_visual.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/map_surface/belluga_map_surface.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/map_surface/belluga_map_surface_contract.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_marker_builder.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class MapLayers extends StatelessWidget {
  const MapLayers({super.key, required MapScreenController controller})
      : _controller = controller,
        _markerBuilder = const PoiMarkerBuilder();

  static const double _minZoom = 14.5;
  static const double _maxZoom = 17.0;

  final MapScreenController _controller;
  final PoiMarkerBuilder _markerBuilder;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<bool>(
      streamValue: _controller.mapInteractionGuardActiveStreamValue,
      builder: (_, interactionGuardActive) {
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
                  onNullWidget: _MapViewport(
                    controller: _controller,
                    markerBuilder: _markerBuilder,
                    markerOverrideVisual: markerOverrideVisual,
                    pois: const <CityPoiModel>[],
                    interactionGuardActive: interactionGuardActive,
                  ),
                  builder: (_, pois) {
                    return StreamValueBuilder<CityPoiModel?>(
                      streamValue: _controller.selectedPoiStreamValue,
                      builder: (_, selectedPoi) {
                        return StreamValueBuilder<String?>(
                          streamValue:
                              _controller.selectedPoiLoadingIdStreamValue,
                          builder: (_, selectedPoiLoadingId) {
                            return StreamValueBuilder<CityCoordinate?>(
                              streamValue: _controller.userLocationStreamValue,
                              builder: (_, userCoordinate) {
                                return StreamValueBuilder<double>(
                                  streamValue: _controller.zoomStreamValue,
                                  builder: (_, zoom) {
                                    return _MapViewport(
                                      controller: _controller,
                                      markerBuilder: _markerBuilder,
                                      markerOverrideVisual:
                                          markerOverrideVisual,
                                      pois: pois!,
                                      selectedPoi: selectedPoi,
                                      selectedPoiLoadingId:
                                          selectedPoiLoadingId,
                                      userCoordinate: userCoordinate,
                                      zoom: zoom,
                                      interactionGuardActive:
                                          interactionGuardActive,
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

  static double _scaledSize(
    double zoom, {
    required double minSize,
    required double maxSize,
  }) {
    final t = ((zoom - _minZoom) / (_maxZoom - _minZoom)).clamp(0.0, 1.0);
    return minSize + (maxSize - minSize) * t;
  }

  @visibleForTesting
  static CityCoordinate? resolveBootstrapInitialCenter({
    required CityCoordinate? tenantDefaultOrigin,
  }) {
    return tenantDefaultOrigin;
  }

  @visibleForTesting
  static bool shouldRenderViewport({
    required CityCoordinate? bootstrapInitialCenter,
  }) {
    return bootstrapInitialCenter != null;
  }

  @visibleForTesting
  static List<CityPoiModel> orderPoisForRendering({
    required List<CityPoiModel> pois,
    CityPoiModel? selectedPoi,
    String? selectedPoiLoadingId,
    String? rememberedPoiId,
  }) {
    final priorityPoiId = (() {
      final loadingId = selectedPoiLoadingId?.trim();
      if (loadingId != null && loadingId.isNotEmpty) {
        return loadingId;
      }
      final selectedId = selectedPoi?.id.trim();
      if (selectedId != null && selectedId.isNotEmpty) {
        return selectedId;
      }
      final rememberedId = rememberedPoiId?.trim();
      if (rememberedId != null && rememberedId.isNotEmpty) {
        return rememberedId;
      }
      return null;
    })();

    if (priorityPoiId == null) {
      return List<CityPoiModel>.unmodifiable(pois);
    }

    final trailing = <CityPoiModel>[];
    final leading = <CityPoiModel>[];
    for (final poi in pois) {
      if (poi.id == priorityPoiId) {
        trailing.add(poi);
      } else {
        leading.add(poi);
      }
    }
    return List<CityPoiModel>.unmodifiable(<CityPoiModel>[
      ...leading,
      ...trailing,
    ]);
  }
}

class _MapViewport extends StatelessWidget {
  const _MapViewport({
    required this.controller,
    required this.markerBuilder,
    required this.markerOverrideVisual,
    required this.pois,
    this.selectedPoi,
    this.selectedPoiLoadingId,
    this.userCoordinate,
    this.zoom = 16,
    this.interactionGuardActive = false,
  });

  final MapScreenController controller;
  final PoiMarkerBuilder markerBuilder;
  final CityPoiVisual? markerOverrideVisual;
  final List<CityPoiModel> pois;
  final CityPoiModel? selectedPoi;
  final String? selectedPoiLoadingId;
  final CityCoordinate? userCoordinate;
  final double zoom;
  final bool interactionGuardActive;

  @override
  Widget build(BuildContext context) {
    final bootstrapInitialCenter = MapLayers.resolveBootstrapInitialCenter(
      tenantDefaultOrigin: controller.initialMapCenter,
    );
    if (!MapLayers.shouldRenderViewport(
      bootstrapInitialCenter: bootstrapInitialCenter,
    )) {
      return const SizedBox.expand();
    }

    final currentZoom = zoom;
    final poiSize = MapLayers._scaledSize(
      currentZoom,
      minSize: 26,
      maxSize: 65,
    );
    final eventSize = (poiSize * 1.18).clamp(30.0, 78.0);
    final userSize = MapLayers._scaledSize(
      currentZoom,
      minSize: 36,
      maxSize: 52,
    );

    final rememberedPoiId =
        controller.lastSelectedPoiMemoryStreamValue.value?.poiId;
    final orderedPois = MapLayers.orderPoisForRendering(
      pois: pois,
      selectedPoi: selectedPoi,
      selectedPoiLoadingId: selectedPoiLoadingId,
      rememberedPoiId: rememberedPoiId,
    );

    final poiMarkers = orderedPois.map((poi) {
      final isSelected = _isPoiSelected(
        selectedPoi: selectedPoi,
        markerPoi: poi,
        selectedPoiLoadingId: selectedPoiLoadingId,
      );
      final isLoading = selectedPoiLoadingId == poi.id;
      final displayPoi = _displayPoiForMarker(
        markerPoi: poi,
        selectedPoi: selectedPoi,
        selectedPoiLoadingId: selectedPoiLoadingId,
      );
      return markerBuilder.build(
        poi: displayPoi,
        isSelected: isSelected,
        isLoading: isLoading,
        onTap: () => controller.handleMarkerTap(poi),
        size: poi.isDynamic ? eventSize : poiSize,
        overrideVisual: (isSelected || isLoading) ? null : markerOverrideVisual,
      );
    });

    final markers = <BellugaMapAnnotation>[
      if (userCoordinate != null) _buildUserMarker(userCoordinate!, userSize),
      ...poiMarkers,
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        BellugaMapSurface(
          handle: controller.mapHandle,
          initialCenter: bootstrapInitialCenter!,
          initialZoom: 16,
          minZoom: MapLayers._minZoom,
          maxZoom: MapLayers._maxZoom,
          annotations: markers,
          onEmptyTap: () => controller.clearSelectedPoi(),
        ),
        if (interactionGuardActive)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              onPanStart: (_) {},
              onPanUpdate: (_) {},
              onPanEnd: (_) {},
            ),
          ),
      ],
    );
  }

  BellugaMapAnnotation _buildUserMarker(CityCoordinate position, double size) {
    return BellugaMapAnnotation(
      id: 'belluga-user-location',
      coordinate: position,
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black54),
        ),
        child: const Center(
          child: Icon(Icons.my_location, size: 20, color: Colors.blueAccent),
        ),
      ),
    );
  }

  bool _isPoiSelected({
    required CityPoiModel? selectedPoi,
    required CityPoiModel markerPoi,
    required String? selectedPoiLoadingId,
  }) {
    if (selectedPoiLoadingId != null) {
      return selectedPoiLoadingId == markerPoi.id;
    }
    if (selectedPoi != null) {
      if (selectedPoi.id == markerPoi.id) {
        return true;
      }
      return selectedPoi.stackKey.isNotEmpty &&
          selectedPoi.stackKey == markerPoi.stackKey;
    }

    final memory = controller.lastSelectedPoiMemoryStreamValue.value;
    if (memory == null) {
      return false;
    }
    if (memory.poiId == markerPoi.id) {
      return true;
    }
    return memory.stackKey.isNotEmpty && memory.stackKey == markerPoi.stackKey;
  }

  CityPoiModel _displayPoiForMarker({
    required CityPoiModel markerPoi,
    required CityPoiModel? selectedPoi,
    required String? selectedPoiLoadingId,
  }) {
    if (selectedPoiLoadingId != null) {
      return markerPoi;
    }

    if (selectedPoi != null) {
      if (selectedPoi.id == markerPoi.id) {
        return selectedPoi;
      }
      final selectedStackKey = selectedPoi.stackKey.trim();
      if (selectedStackKey.isNotEmpty &&
          selectedStackKey == markerPoi.stackKey) {
        return markerPoi.copyWith(visual: selectedPoi.visual);
      }
      return markerPoi;
    }

    final memory = controller.lastSelectedPoiMemoryStreamValue.value;
    if (memory == null) {
      return markerPoi;
    }
    if (memory.poiId == markerPoi.id) {
      return markerPoi.copyWith(visual: memory.visual);
    }
    if (memory.stackKey.isNotEmpty && memory.stackKey == markerPoi.stackKey) {
      return markerPoi.copyWith(visual: memory.visual);
    }
    return markerPoi;
  }
}
