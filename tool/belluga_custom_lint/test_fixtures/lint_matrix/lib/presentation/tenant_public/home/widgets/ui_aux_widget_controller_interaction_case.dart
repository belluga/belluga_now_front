import 'package:lint_matrix_fixture/presentation/tenant_public/home/controllers/home_controller.dart';

class ScrollController {
  Object get position => Object();
}

class AuxiliaryWidgetLocalOwnershipCase {
  final scroll = ScrollController();

  void localOnly() {
    scroll.position;
  }
}

class AuxiliaryWidgetControllerInteractionCase {
  final scroll = ScrollController();
  final homeController = const HomeController();

  void forwardToController() {
    // expect_lint: ui_controller_ownership_forbidden
    homeController.onScroll(scroll.position);
  }
}
