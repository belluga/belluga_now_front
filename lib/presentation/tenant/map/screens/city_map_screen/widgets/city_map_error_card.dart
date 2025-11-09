import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/city_map_controller.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class CityMapErrorCard extends StatelessWidget {
  const CityMapErrorCard({super.key, required this.controller});

  final CityMapController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamValueBuilder<String?>(
      streamValue: controller.errorMessage,
      builder: (_, error) {
        if (error == null) {
          return const SizedBox.shrink();
        }
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SafeArea(
              child: Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    error,
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
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
