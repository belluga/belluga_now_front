// ignore_for_file: unused_element

class ScrollController {
  ScrollController();
}

class _UiVisualControllerOwnershipScreen {
  // expect_lint: ui_controller_ownership_forbidden
  final scrollController = ScrollController();
}
