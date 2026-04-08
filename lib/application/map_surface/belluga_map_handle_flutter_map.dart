import 'dart:async';

import 'package:belluga_now/application/map_surface/belluga_map_handle_contract.dart';
import 'package:belluga_now/application/map_surface/belluga_map_interaction.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class BellugaMapHandle implements BellugaMapHandleContract {
  static const double _cameraCoordinateTolerance = 0.000001;
  static const double _cameraZoomTolerance = 0.01;

  BellugaMapHandle() : _mapController = MapController();

  final MapController _mapController;
  final StreamController<BellugaMapInteractionEvent> _interactionController =
      StreamController<BellugaMapInteractionEvent>.broadcast();

  bool _isDisposed = false;
  bool _isReady = false;

  MapController get rawController => _mapController;

  @override
  Stream<BellugaMapInteractionEvent> get interactionStream =>
      _interactionController.stream;

  @override
  bool get isReady => _isReady;

  @override
  double? get currentZoom {
    try {
      return _mapController.camera.zoom;
    } catch (_) {
      return null;
    }
  }

  @override
  CityCoordinate? get currentCenter {
    try {
      final center = _mapController.camera.center;
      return CityCoordinate.fromLatLng(center);
    } catch (_) {
      return null;
    }
  }

  @override
  void markReady() {
    if (_isDisposed || _isReady) {
      return;
    }
    _isReady = true;
    _interactionController.add(
      BellugaMapInteractionEvent(
        type: BellugaMapInteractionType.ready,
        zoom: currentZoom,
      ),
    );
  }

  @override
  void emitInteraction(BellugaMapInteractionEvent event) {
    if (_isDisposed) {
      return;
    }
    _interactionController.add(event);
  }

  @override
  bool moveTo(
    CityCoordinate coordinate, {
    required double zoom,
  }) {
    try {
      if (_matchesCurrentCamera(coordinate, zoom)) {
        return true;
      }
      return _mapController.move(
        LatLng(coordinate.latitude, coordinate.longitude),
        zoom,
      );
    } catch (_) {
      return false;
    }
  }

  @override
  bool moveToAnchored(
    CityCoordinate coordinate, {
    required double zoom,
    required double verticalViewportAnchor,
  }) {
    try {
      final camera = _mapController.camera;
      final targetOffset = calculateAnchoredMoveOffset(
        viewportHeight: camera.nonRotatedSize.height,
        verticalViewportAnchor: verticalViewportAnchor,
      );
      return _mapController.move(
        LatLng(coordinate.latitude, coordinate.longitude),
        zoom,
        offset: targetOffset,
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Offset? projectToViewport(CityCoordinate coordinate) {
    try {
      return _mapController.camera.latLngToScreenOffset(
        LatLng(coordinate.latitude, coordinate.longitude),
      );
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  static Offset calculateAnchoredMoveOffset({
    required double viewportHeight,
    required double verticalViewportAnchor,
  }) {
    return Offset(
      0,
      (verticalViewportAnchor - 0.5) * viewportHeight,
    );
  }

  bool _matchesCurrentCamera(CityCoordinate coordinate, double zoom) {
    try {
      final camera = _mapController.camera;
      final center = camera.center;
      return (center.latitude - coordinate.latitude).abs() <=
              _cameraCoordinateTolerance &&
          (center.longitude - coordinate.longitude).abs() <=
              _cameraCoordinateTolerance &&
          (camera.zoom - zoom).abs() <= _cameraZoomTolerance;
    } catch (_) {
      return false;
    }
  }

  @override
  bool fitToCoordinates(
    List<CityCoordinate> coordinates, {
    double padding = 32,
    double? maxZoom,
  }) {
    if (coordinates.isEmpty) {
      return false;
    }
    if (coordinates.length == 1) {
      return moveTo(coordinates.first, zoom: maxZoom ?? 16);
    }

    try {
      final bounds = LatLngBounds.fromPoints(
        coordinates
            .map((coordinate) =>
                LatLng(coordinate.latitude, coordinate.longitude))
            .toList(growable: false),
      );
      return _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: EdgeInsets.all(padding),
          maxZoom: maxZoom,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _interactionController.close();
    _mapController.dispose();
  }
}
