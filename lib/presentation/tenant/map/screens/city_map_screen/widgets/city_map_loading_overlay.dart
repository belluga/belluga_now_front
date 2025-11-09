import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/city_map_controller.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class CityMapLoadingOverlay extends StatelessWidget {
  const CityMapLoadingOverlay({super.key, required this.controller});

  final CityMapController controller;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<bool>(
      streamValue: controller.isLoading,
      builder: (_, isLoading) {
        if (isLoading != true) {
          return const SizedBox.shrink();
        }
        return const Positioned.fill(
          child: IgnorePointer(
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }
}
