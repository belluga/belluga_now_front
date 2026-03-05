class ScrollController {
  ScrollController();
}

class UiVisualControllerOwnershipScreen {
  // expect_lint: ui_controller_ownership_forbidden
  final scrollController = ScrollController();
}
