// ignore_for_file: unused_element

class _Router {
  void push(Object route) {}
}

class _NavigationController {
  final _Router router = _Router();

  void go(Object route) {
    // expect_lint: controller_direct_navigation_forbidden
    router.push(route);
  }
}
