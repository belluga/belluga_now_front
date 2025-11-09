import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/cuisine_panel_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/events_panel_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/fab_menu_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/region_panel_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/panels/cuisine_panel.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/panels/events_panel.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/panels/region_panel.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class CityMapLateralPanel extends StatelessWidget {
  const CityMapLateralPanel({
    super.key,
    required this.fabMenuController,
    required this.regionPanelController,
    required this.eventsPanelController,
    required this.musicPanelController,
    required this.cuisinePanelController,
  });

  final FabMenuController fabMenuController;
  final RegionPanelController regionPanelController;
  final EventsPanelController eventsPanelController;
  final EventsPanelController musicPanelController;
  final CuisinePanelController cuisinePanelController;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<LateralPanelType?>(
      streamValue: fabMenuController.activePanel,
      builder: (_, panel) {
        final panelType = panel;
        if (panelType == null) {
          return const SizedBox.shrink();
        }

        late final Widget panelWidget;
        switch (panelType) {
          case LateralPanelType.regions:
            panelWidget = RegionPanel(
              controller: regionPanelController,
              onClose: fabMenuController.closePanel,
            );
            break;
          case LateralPanelType.events:
            panelWidget = EventsPanel(
              controller: eventsPanelController,
              onClose: fabMenuController.closePanel,
              title: 'Eventos',
              icon: Icons.event,
            );
            break;
          case LateralPanelType.music:
            panelWidget = EventsPanel(
              controller: musicPanelController,
              onClose: fabMenuController.closePanel,
              title: 'Shows',
              icon: Icons.music_note,
            );
            break;
          case LateralPanelType.cuisines:
            panelWidget = CuisinePanel(
              controller: cuisinePanelController,
              onClose: cuisinePanelController.closePanel,
            );
            break;
        }

        return Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 16, right: 16),
            child: SafeArea(child: panelWidget),
          ),
        );
      },
    );
  }
}
