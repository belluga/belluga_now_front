import 'package:belluga_now/domain/map/map_status.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/city_map_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/map_status_visuals.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/location_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class CityMapStatusBanner extends StatelessWidget {
  const CityMapStatusBanner({
    super.key,
    required this.controller,
  });

  final CityMapController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamValueBuilder<String?>(
      streamValue: controller.statusMessageStreamValue,
      builder: (_, message) {
        if (message == null || message.isEmpty) {
          return const SizedBox.shrink();
        }
        return StreamValueBuilder<MapStatus>(
          streamValue: controller.mapStatusStreamValue,
          builder: (_, status) {
            final visuals = resolveStatusVisuals(status, theme);
            return Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SafeArea(
                  child: LocationStatusBanner(
                    icon: visuals.icon,
                    label: message,
                    backgroundColor: visuals.background,
                    textColor: visuals.textColor,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
