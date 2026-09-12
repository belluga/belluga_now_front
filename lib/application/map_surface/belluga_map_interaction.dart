import 'package:belluga_now/application/map_surface/belluga_map_viewport.dart';

enum BellugaMapInteractionType { ready, emptyTap, pan, zoom }

class BellugaMapInteractionEvent {
  const BellugaMapInteractionEvent({
    required this.type,
    this.zoom,
    this.viewport,
    this.userGesture = false,
  });

  final BellugaMapInteractionType type;
  final double? zoom;
  final BellugaMapViewport? viewport;
  final bool userGesture;

  bool get isViewportChange =>
      type == BellugaMapInteractionType.pan ||
      type == BellugaMapInteractionType.zoom;

  bool get dismissesTransientNotice => userGesture;
}
