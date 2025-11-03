import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/screens/map/controller/city_map_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/map/controller/fab_menu_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/map/controller/events_panel_controller.dart';

class MusicPanelController extends EventsPanelController {
  MusicPanelController({
    CityMapController? mapController,
    FabMenuController? fabMenuController,
  }) : super(
          mapController: mapController,
          fabMenuController: fabMenuController,
        );

  @override
  List<EventModel> filterEvents(List<EventModel> items) {
    return items
        .where(
          (event) => event.type.slug.value.toLowerCase().trim() == 'show',
        )
        .toList(growable: false);
  }
}
