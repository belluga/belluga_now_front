import 'dart:async';

import 'package:belluga_now/presentation/tenant/screens/map/controller/city_map_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/map/controller/fab_menu_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';
import 'package:stream_value/core/stream_value.dart';

class RegionPanelController implements Disposable {
  RegionPanelController({
    CityMapController? mapController,
  })  : _mapController = mapController ?? GetIt.I.get<CityMapController>(),
        _fabMenuController = GetIt.I.get<FabMenuController>(),
        selectedRegion = StreamValue<MapRegionDefinition?>();

  final CityMapController _mapController;
  final FabMenuController _fabMenuController;

  final StreamValue<MapRegionDefinition?> selectedRegion;

  List<MapRegionDefinition> get regions => _mapController.regions;

  Future<void> goToRegion(MapRegionDefinition region) async {
    selectedRegion.addValue(region);
    await _mapController.goToRegion(region);
    _fabMenuController.closePanel();
  }

  @override
  void onDispose() {
    selectedRegion.dispose();
  }
}
