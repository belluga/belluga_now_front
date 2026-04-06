import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_location_feedback_state.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/shared/map_location_status_icon.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

const double _kMapUtilityButtonSize = 52;

class MapLocationUtilityButton extends StatelessWidget {
  const MapLocationUtilityButton({
    super.key,
    required this.controller,
  });

  final MapScreenController controller;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<MapLocationFeedbackState>(
      streamValue: controller.locationFeedbackStateStreamValue,
      builder: (_, locationFeedbackState) {
        final scheme = Theme.of(context).colorScheme;

        return Tooltip(
          message: 'Sua localização',
          child: Material(
            key: const ValueKey<String>('map-location-floating-button'),
            color: scheme.surface.withValues(alpha: 0.96),
            shape: const CircleBorder(),
            elevation: 10,
            shadowColor: Colors.black26,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: locationFeedbackState.isActionEnabled
                  ? controller.centerOnUser
                  : null,
              child: Opacity(
                opacity: locationFeedbackState.isActionEnabled ? 1 : 0.56,
                child: SizedBox(
                  width: _kMapUtilityButtonSize,
                  height: _kMapUtilityButtonSize,
                  child: Center(
                    child: MapLocationStatusIcon(
                      state: locationFeedbackState,
                      enabled: locationFeedbackState.isActionEnabled,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
