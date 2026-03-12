// ignore_for_file: unused_element

class BuildContext {}

class _ContextController {
  // expect_lint: controller_buildcontext_dependency_forbidden
  final BuildContext context;

  _ContextController(this.context);
}
