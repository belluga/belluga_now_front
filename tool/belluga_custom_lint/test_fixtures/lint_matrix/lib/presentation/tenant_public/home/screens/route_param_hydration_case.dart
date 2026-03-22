// ignore_for_file: unused_element

class _Widget {}

class _BuildContext {}

class _StatefulWidget {
  const _StatefulWidget();
}

abstract class _State<T extends _StatefulWidget> {
  late T widget;

  void initState() {}
  void didUpdateWidget(covariant T oldWidget) {}
  _Widget build(_BuildContext context) => _Widget();
}

abstract class _Controller {
  void loadBySlug(String slug) {}
  void loadByModel(String id) {}
}

class _RouteHydrationController extends _Controller {}

class _RouteHydrationScreen extends _StatefulWidget {
  const _RouteHydrationScreen({required this.slug});

  final String slug;
}

class _RouteHydrationScreenState extends _State<_RouteHydrationScreen> {
  final _controller = _RouteHydrationController();

  @override
  void initState() {
    super.initState();
    // expect_lint: ui_route_param_hydration_forbidden
    _controller.loadBySlug(widget.slug);
  }

  @override
  void didUpdateWidget(covariant _RouteHydrationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // expect_lint: ui_route_param_hydration_forbidden
    _controller.loadBySlug(widget.slug);
  }
}

class _SafeHydratedScreenState extends _State<_RouteHydrationScreen> {
  final _controller = _RouteHydrationController();
  final String resolvedAccountProfileId = 'resolved-id';

  @override
  void initState() {
    super.initState();
    _controller.loadByModel(resolvedAccountProfileId);
  }
}
