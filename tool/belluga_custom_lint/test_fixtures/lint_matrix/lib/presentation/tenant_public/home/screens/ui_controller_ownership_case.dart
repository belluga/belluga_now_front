class FormState {}

class GlobalKey<T> {
  GlobalKey();
}

class TextEditingController {
  TextEditingController();
}

class UiControllerOwnershipScreen {
  // expect_lint: ui_controller_ownership_forbidden
  final key = GlobalKey<FormState>();

  // expect_lint: ui_controller_ownership_forbidden
  final controller = TextEditingController();
}
