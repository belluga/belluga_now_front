import 'package:belluga_now/presentation/tenant/screens/map/controller/cuisine_panel_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/map/panels/map_lateral_panel.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class CuisinePanel extends StatelessWidget {
  const CuisinePanel({
    super.key,
    required this.controller,
    required this.onClose,
  });

  final CuisinePanelController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return MapLateralPanel(
      title: 'Gastronomia',
      icon: Icons.restaurant_menu_outlined,
      onClose: onClose,
      child: StreamValueBuilder<List<String>>(
        streamValue: controller.availableTags,
        builder: (_, tags) {
          final options = tags;
          if (options.isEmpty) {
            return Center(
              child: Text(
                'Selecione uma categoria disponivel para ver os filtros.',
                style: textTheme.bodyMedium,
              ),
            );
          }
          return SingleChildScrollView(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final tag in options)
                  FilterChip(
                    label: Text(_formatTag(tag)),
                    selected: controller.isTagSelected(tag),
                    onSelected: (_) => controller.toggleTag(tag),
                    selectedColor: scheme.primary.withOpacity(0.16),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTag(String value) {
    if (value.length <= 1) {
      return value.toUpperCase();
    }
    return value[0].toUpperCase() + value.substring(1);
  }
}
