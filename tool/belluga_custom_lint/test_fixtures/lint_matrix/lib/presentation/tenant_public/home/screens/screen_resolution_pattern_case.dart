// ignore_for_file: unused_element

class _BuildContext {}

class StatelessWidget {
  const StatelessWidget();
}

class _HomeController {
  const _HomeController();
}

class _ScreenResolutionPatternScreen extends StatelessWidget {
  // expect_lint: screen_controller_resolution_pattern_required
  const _ScreenResolutionPatternScreen({required this.controller});

  final _HomeController controller;
}
