import 'package:belluga_now/presentation/tenant/screens/map/controller/city_map_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class RegionPanelController implements Disposable {
  RegionPanelController({
    CityMapController? mapController,
  }) : _mapController = mapController ?? GetIt.I.get<CityMapController>();

  final CityMapController _mapController;

  List<MapRegionDefinition> get regions => _mapController.regions;

  Future<void> goToRegion(MapRegionDefinition region) =>
      _mapController.goToRegion(region);

  @override
  void onDispose() {}
}
