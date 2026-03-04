class BuildContext {}

class ContextController {
  // expect_lint: controller_buildcontext_dependency_forbidden
  final BuildContext context;

  ContextController(this.context);
}
