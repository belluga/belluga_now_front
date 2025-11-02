import 'package:belluga_now/presentation/tenant/screens/map/controller/region_panel_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/map/panels/map_lateral_panel.dart';
import 'package:flutter/material.dart';

class RegionPanel extends StatelessWidget {
  const RegionPanel({
    super.key,
    required this.controller,
    required this.onClose,
  });

  final RegionPanelController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final regions = controller.regions;
    return MapLateralPanel(
      title: 'Regioes',
      icon: Icons.map_outlined,
      onClose: onClose,
      child: ListView.separated(
        itemCount: regions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, index) {
          final region = regions[index];
          return ListTile(
            leading: const Icon(Icons.place_outlined),
            title: Text(region.label),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => controller.goToRegion(region),
          );
        },
      ),
    );
  }
}
