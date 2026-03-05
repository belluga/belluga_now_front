class BuildContext {}

class Widget {}

class StatelessWidget {
  const StatelessWidget();

  Widget build(BuildContext context) => Widget();
}

class MultiWidgetCaseScreen extends StatelessWidget {
  const MultiWidgetCaseScreen();
}

// expect_lint: multi_widget_file_warning
class MultiWidgetCaseWidget extends StatelessWidget {
  const MultiWidgetCaseWidget();
}
