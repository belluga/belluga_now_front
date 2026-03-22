// ignore_for_file: unused_element

class RoutePage {
  const RoutePage({this.name});
  final String? name;
}

class _Widget {}

class _BuildContext {}

class _StatefulWidget {
  const _StatefulWidget();

  _Widget build(_BuildContext context) => _Widget();
}

// expect_lint: route_page_must_live_in_routes_folder
@RoutePage(name: 'OutsideRoutes')
class _OutsideRoutesRoutePage extends _StatefulWidget {
  const _OutsideRoutesRoutePage();
}
