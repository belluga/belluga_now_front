class BuildContext {}

class Widget {}

class StatelessWidget {
  const StatelessWidget();

  Widget build(BuildContext context) => Widget();
}

class SideEffectService {
  void fetchData() {}
}

class BuildSideEffectsScreen extends StatelessWidget {
  BuildSideEffectsScreen(this.service);

  final SideEffectService service;

  @override
  Widget build(BuildContext context) {
    // expect_lint: ui_build_side_effects_forbidden
    service.fetchData();
    return Widget();
  }
}
