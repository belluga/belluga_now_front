enum BellugaMapInteractionType {
  ready,
  emptyTap,
  pan,
  zoom,
}

class BellugaMapInteractionEvent {
  const BellugaMapInteractionEvent({
    required this.type,
    this.zoom,
    this.userGesture = false,
  });

  final BellugaMapInteractionType type;
  final double? zoom;
  final bool userGesture;

  bool get isViewportChange =>
      type == BellugaMapInteractionType.pan ||
      type == BellugaMapInteractionType.zoom;

  bool get dismissesTransientNotice => userGesture;
}
