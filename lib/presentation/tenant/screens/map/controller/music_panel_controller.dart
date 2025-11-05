import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/screens/map/controller/events_panel_controller.dart';

class MusicPanelController extends EventsPanelController {
  MusicPanelController({
    super.mapController,
    super.fabMenuController,
  });

  @override
  List<EventModel> filterEvents(List<EventModel> items) {
    return items
        .where(
          (event) => event.type.slug.value.toLowerCase().trim() == 'show',
        )
        .toList(growable: false);
  }
}
