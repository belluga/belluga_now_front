import 'package:belluga_now/application/map_surface/belluga_map_viewport.dart';

enum BellugaMapInteractionType { ready, emptyTap, pan, zoom }

enum BellugaMapInteractionOrigin { user, programmatic, system }

class BellugaMapInteractionEvent {
  const BellugaMapInteractionEvent({
    required this.type,
    this.zoom,
    this.viewport,
    this.origin = BellugaMapInteractionOrigin.system,
  });

  final BellugaMapInteractionType type;
  final double? zoom;
  final BellugaMapViewport? viewport;
  final BellugaMapInteractionOrigin origin;

  bool get isViewportChange =>
      type == BellugaMapInteractionType.pan ||
      type == BellugaMapInteractionType.zoom;

  bool get initiatedByUser => origin == BellugaMapInteractionOrigin.user;

  bool get dismissesTransientNotice => initiatedByUser;
}
