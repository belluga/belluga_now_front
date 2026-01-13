import 'package:belluga_now/infrastructure/repositories/poi_repository.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class FabMenuController {
  FabMenuController({
    MapScreenController? mapController,
  }) : _mapController = mapController ?? GetIt.I.get<MapScreenController>();

  final MapScreenController _mapController;

  final expandedStreamValue = StreamValue<bool>(defaultValue: true);

  StreamValue<PoiFilterMode> get filterModeStreamValue =>
      _mapController.filterModeStreamValue;

  void toggleFilterMode(PoiFilterMode mode) {
    final current = filterModeStreamValue.value;
    if (current == mode) {
      _mapController.clearFilters();
    } else {
      _mapController.applyFilterMode(mode);
    }
  }

  void toggleExpanded() {
    final current = expandedStreamValue.value;
    expandedStreamValue.addValue(!current);
  }

  void setExpanded(bool expanded) {
    expandedStreamValue.addValue(expanded);
  }
}
