// ignore_for_file: unused_element

class Navigator {
  static Navigator of(Object context) => Navigator();

  void push(Object route) {}
}

class _UiNavigatorCase {
  void go(Object context, Object route) {
    // expect_lint: ui_navigator_usage_forbidden
    Navigator.of(context).push(route);
  }
}
