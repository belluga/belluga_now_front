import 'dart:async';

import 'package:belluga_now/application/map_surface/belluga_map_handle_contract.dart';
import 'package:belluga_now/application/map_surface/belluga_map_interaction.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class BellugaMapHandle implements BellugaMapHandleContract {
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
      final targetOffset = Offset(
        0,
        (0.5 - verticalViewportAnchor) * camera.nonRotatedSize.height,
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
            .map((coordinate) => LatLng(coordinate.latitude, coordinate.longitude))
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
