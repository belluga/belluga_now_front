// ignore_for_file: unused_element

class _BuildContext {}

class _Widget {}

class StatelessWidget {
  const StatelessWidget();

  _Widget build(_BuildContext context) => _Widget();
}

class _SideEffectService {
  void fetchData() {}
}

class _BuildSideEffectsScreen extends StatelessWidget {
  _BuildSideEffectsScreen(this.service);

  final _SideEffectService service;

  @override
  _Widget build(_BuildContext context) {
    // expect_lint: ui_build_side_effects_forbidden
    service.fetchData();
    return _Widget();
  }
}
