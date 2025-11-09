// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:belluga_now/domain/map/map_status.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/city_map_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/map_status_visuals.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/location_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class CityMapStatusBanner extends StatelessWidget {
  CityMapStatusBanner({
    super.key,
    CityMapController? controller,
  }) : _controller = controller ?? GetIt.I.get<CityMapController>();

  @visibleForTesting
  CityMapStatusBanner.withController(
    this._controller, {
    super.key,
  });

  final CityMapController _controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamValueBuilder<String?>(
      streamValue: _controller.statusMessageStreamValue,
      onNullWidget: const SizedBox.shrink(),
      builder: (_, message) {
        if (message == null || message.isEmpty) {
          return const SizedBox.shrink();
        }
        return StreamValueBuilder<MapStatus>(
          streamValue: _controller.mapStatusStreamValue,
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
