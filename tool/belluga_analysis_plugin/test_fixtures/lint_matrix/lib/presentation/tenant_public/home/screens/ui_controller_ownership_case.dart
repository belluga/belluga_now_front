// ignore_for_file: unused_element

class FormState {}

// expect_lint: multi_public_class_file_warning
class GlobalKey<T> {
  GlobalKey();
}

// expect_lint: multi_public_class_file_warning
class TextEditingController {
  TextEditingController();
}

class _UiControllerOwnershipScreen {
  // expect_lint: ui_controller_ownership_forbidden
  final key = GlobalKey<FormState>();

  // expect_lint: ui_controller_ownership_forbidden
  final controller = TextEditingController();
}
