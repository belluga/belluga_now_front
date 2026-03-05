class Router {
  void push(Object route) {}
}

class NavigationController {
  final Router router = Router();

  void go(Object route) {
    // expect_lint: controller_direct_navigation_forbidden
    router.push(route);
  }
}
