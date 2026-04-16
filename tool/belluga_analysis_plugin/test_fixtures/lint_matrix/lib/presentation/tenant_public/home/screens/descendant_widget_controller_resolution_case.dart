import 'package:get_it/get_it.dart';

import 'home_screen/widgets/agenda_section/controllers/home_agenda_section_controller.dart';

class DescendantWidgetControllerResolutionCaseScreen {
  final HomeAgendaSectionController controller =
      // expect_lint: screen_descendant_widget_controller_resolution_forbidden
      GetIt.I.get<HomeAgendaSectionController>();

  void touch() {
    controller.hashCode;
  }
}
