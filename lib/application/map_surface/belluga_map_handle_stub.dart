import 'dart:async';

import 'package:belluga_now/application/map_surface/belluga_map_handle_contract.dart';
import 'package:belluga_now/application/map_surface/belluga_map_interaction.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:flutter/widgets.dart';

class BellugaMapHandle implements BellugaMapHandleContract {
  final StreamController<BellugaMapInteractionEvent> _interactionController =
      StreamController<BellugaMapInteractionEvent>.broadcast();

  bool _isDisposed = false;
  bool _isReady = false;
  double? _currentZoom;
  CityCoordinate? _currentCenter;

  @override
  Stream<BellugaMapInteractionEvent> get interactionStream =>
      _interactionController.stream;

  @override
  bool get isReady => _isReady;

  @override
  double? get currentZoom => _currentZoom;

  @override
  CityCoordinate? get currentCenter => _currentCenter;

  @override
  void markReady() {
    if (_isDisposed || _isReady) {
      return;
    }
    _isReady = true;
    _interactionController.add(
      const BellugaMapInteractionEvent(
        type: BellugaMapInteractionType.ready,
      ),
    );
  }

  @override
  void emitInteraction(BellugaMapInteractionEvent event) {
    if (_isDisposed) {
      return;
    }
    _currentZoom = event.zoom ?? _currentZoom;
    _interactionController.add(event);
  }

  @override
  bool moveTo(
    CityCoordinate coordinate, {
    required double zoom,
  }) {
    _currentZoom = zoom;
    _currentCenter = coordinate;
    return false;
  }

  @override
  bool moveToAnchored(
    CityCoordinate coordinate, {
    required double zoom,
    required double verticalViewportAnchor,
  }) {
    _currentZoom = zoom;
    _currentCenter = coordinate;
    return false;
  }

  @override
  bool fitToCoordinates(
    List<CityCoordinate> coordinates, {
    double padding = 32,
    double? maxZoom,
  }) {
    return false;
  }

  @override
  Offset? projectToViewport(CityCoordinate coordinate) {
    return null;
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _interactionController.close();
  }
}
