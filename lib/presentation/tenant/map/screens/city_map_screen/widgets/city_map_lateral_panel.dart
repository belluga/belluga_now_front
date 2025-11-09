// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/cuisine_panel_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/events_panel_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/fab_menu_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/region_panel_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/panels/cuisine_panel.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/panels/events_panel.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/panels/region_panel.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class CityMapLateralPanel extends StatelessWidget {
  CityMapLateralPanel({
    super.key,
    FabMenuController? fabMenuController,
    RegionPanelController? regionPanelController,
    EventsPanelController? eventsPanelController,
    EventsPanelController? musicPanelController,
    CuisinePanelController? cuisinePanelController,
  })  : _fabMenuController =
            fabMenuController ?? GetIt.I.get<FabMenuController>(),
        _regionPanelController =
            regionPanelController ?? GetIt.I.get<RegionPanelController>(),
        _eventsPanelController =
            eventsPanelController ?? GetIt.I.get<EventsPanelController>(),
        _musicPanelController =
            musicPanelController ?? GetIt.I.get<EventsPanelController>(),
        _cuisinePanelController =
            cuisinePanelController ?? GetIt.I.get<CuisinePanelController>();

  @visibleForTesting
  CityMapLateralPanel.withControllers({
    super.key,
    required FabMenuController fabMenuController,
    required RegionPanelController regionPanelController,
    required EventsPanelController eventsPanelController,
    required EventsPanelController musicPanelController,
    required CuisinePanelController cuisinePanelController,
  })  : _fabMenuController = fabMenuController,
        _regionPanelController = regionPanelController,
        _eventsPanelController = eventsPanelController,
        _musicPanelController = musicPanelController,
        _cuisinePanelController = cuisinePanelController;

  final FabMenuController _fabMenuController;
  final RegionPanelController _regionPanelController;
  final EventsPanelController _eventsPanelController;
  final EventsPanelController _musicPanelController;
  final CuisinePanelController _cuisinePanelController;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<LateralPanelType?>(
      streamValue: _fabMenuController.activePanel,
      builder: (_, panel) {
        final panelType = panel;
        if (panelType == null) {
          return const SizedBox.shrink();
        }

        late final Widget panelWidget;
        switch (panelType) {
          case LateralPanelType.regions:
            panelWidget = RegionPanel(
              controller: _regionPanelController,
              onClose: _fabMenuController.closePanel,
            );
            break;
          case LateralPanelType.events:
            panelWidget = EventsPanel(
              controller: _eventsPanelController,
              onClose: _fabMenuController.closePanel,
              title: 'Eventos',
              icon: Icons.event,
            );
            break;
          case LateralPanelType.music:
            panelWidget = EventsPanel(
              controller: _musicPanelController,
              onClose: _fabMenuController.closePanel,
              title: 'Shows',
              icon: Icons.music_note,
            );
            break;
          case LateralPanelType.cuisines:
            panelWidget = CuisinePanel(
              controller: _cuisinePanelController,
              onClose: _cuisinePanelController.closePanel,
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
