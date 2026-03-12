class _BuildContext {}

class _Widget {}

class StatelessWidget {
  const StatelessWidget();

  _Widget build(_BuildContext context) => _Widget();
}

// expect_lint: multi_public_class_file_warning
class MultiWidgetCaseScreen extends StatelessWidget {
  const MultiWidgetCaseScreen();
}

// expect_lint: multi_public_class_file_warning, multi_widget_file_warning
class MultiWidgetCaseWidget extends StatelessWidget {
  const MultiWidgetCaseWidget();
}
