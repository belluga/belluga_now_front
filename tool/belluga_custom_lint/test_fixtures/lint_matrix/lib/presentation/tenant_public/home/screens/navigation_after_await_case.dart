class _Router {
  void push(Object route) {}
}

class NavAfterAwaitScreen {
  final _Router router = _Router();

  Future<void> open(Object route) async {
    await Future<void>.value();
    // expect_lint: ui_navigation_after_await_forbidden
    router.push(route);
  }
}
