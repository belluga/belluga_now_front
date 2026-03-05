class Router {
  void push(Object route) {}
}

class NavAfterAwaitScreen {
  final Router router = Router();

  Future<void> open(Object route) async {
    await Future<void>.value();
    // expect_lint: ui_navigation_after_await_forbidden
    router.push(route);
  }
}
