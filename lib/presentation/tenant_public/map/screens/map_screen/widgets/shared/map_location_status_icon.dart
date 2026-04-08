import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_location_feedback_state.dart';
import 'package:flutter/material.dart';

class MapLocationStatusIcon extends StatelessWidget {
  const MapLocationStatusIcon({
    super.key,
    required this.state,
    required this.enabled,
    this.size = 28,
  });

  final MapLocationFeedbackState state;
  final bool enabled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = enabled
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onSecondaryContainer.withAlpha(176);
    final badgeBackgroundColor = switch (state.kind) {
      MapLocationFeedbackKind.loading => theme.colorScheme.surface,
      MapLocationFeedbackKind.live => theme.colorScheme.primary,
      MapLocationFeedbackKind.fixedManual => theme.colorScheme.tertiary,
      MapLocationFeedbackKind.outsideRange => Colors.amber.shade700,
      MapLocationFeedbackKind.permissionDenied ||
      MapLocationFeedbackKind.unavailable =>
        theme.colorScheme.error,
    };
    final badgeChild = switch (state.kind) {
      MapLocationFeedbackKind.loading => SizedBox(
          width: size * 0.36,
          height: size * 0.36,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),
      MapLocationFeedbackKind.live => const Icon(
          Icons.location_on,
          size: 10,
          color: Colors.white,
        ),
      MapLocationFeedbackKind.fixedManual => const Icon(
          Icons.home_rounded,
          size: 10,
          color: Colors.white,
        ),
      MapLocationFeedbackKind.outsideRange => const Icon(
          Icons.warning_amber_rounded,
          size: 10,
          color: Colors.white,
        ),
      MapLocationFeedbackKind.permissionDenied ||
      MapLocationFeedbackKind.unavailable =>
        const Icon(
          Icons.error_outline_rounded,
          size: 10,
          color: Colors.white,
        ),
    };

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Icon(
              Icons.my_location,
              color: color,
            ),
          ),
          Positioned(
            top: -1,
            right: -1,
            child: Container(
              width: size * 0.5,
              height: size * 0.5,
              decoration: BoxDecoration(
                color: badgeBackgroundColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 1.2,
                ),
              ),
              child: Center(child: badgeChild),
            ),
          ),
        ],
      ),
    );
  }
}
