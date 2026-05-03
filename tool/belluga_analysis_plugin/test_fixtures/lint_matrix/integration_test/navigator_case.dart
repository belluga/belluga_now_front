class Navigator {
  static Navigator of(Object context) => Navigator();

  void pop() {}
}

class IntegrationNavigatorCase {
  void close(Object context) {
    // expect_lint: ui_navigator_usage_forbidden
    Navigator.of(context).pop();
  }
}
