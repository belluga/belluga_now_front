import 'dart:async';

import 'package:belluga_now/domain/map/map_region_definition.dart';
import 'package:belluga_now/presentation/tenant/screens/map/controller/city_map_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/map/controller/fab_menu_controller.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class RegionPanelController implements Disposable {
  RegionPanelController({
    CityMapController? mapController,
    FabMenuController? fabMenuController,
  })  : _mapController = mapController ?? GetIt.I.get<CityMapController>(),
        _fabMenuController =
            fabMenuController ?? GetIt.I.get<FabMenuController>(),
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
