import 'package:get_it/get_it.dart';

import 'controllers/home_agenda_section_controller.dart';

class AgendaSectionWidget {
  final HomeAgendaSectionController controller =
      GetIt.I.get<HomeAgendaSectionController>();

  void touch() {
    controller.hashCode;
  }

  void disposeOwnedController() {
    controller.onDispose();
  }
}
