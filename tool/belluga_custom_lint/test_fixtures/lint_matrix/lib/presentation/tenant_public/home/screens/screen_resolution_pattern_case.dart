class BuildContext {}

class StatelessWidget {
  const StatelessWidget();
}

class HomeController {
  const HomeController();
}

class ScreenResolutionPatternScreen extends StatelessWidget {
  // expect_lint: screen_controller_resolution_pattern_required
  const ScreenResolutionPatternScreen({required this.controller});

  final HomeController controller;
}
