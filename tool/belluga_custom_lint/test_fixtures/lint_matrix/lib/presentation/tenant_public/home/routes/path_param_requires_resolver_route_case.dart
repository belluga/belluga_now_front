// ignore_for_file: unused_element, multi_public_class_file_warning

class RoutePage {
  const RoutePage({this.name});
  final String? name;
}

class PathParam {
  const PathParam(this.name);
  final String name;
}

class Widget {}

class BuildContext {}

class Key {}

class StatelessWidget {
  const StatelessWidget({this.key});
  final Key? key;

  Widget build(BuildContext context) => Widget();
}

abstract class ModuleContract {}

abstract class ResolverRoute<TModel, TModule extends ModuleContract>
    extends StatelessWidget {
  const ResolverRoute({super.key});
}

class _FixtureModule extends ModuleContract {}

class _FixtureModel {}

// expect_lint: route_path_param_requires_resolver_route
@RoutePage(name: 'LegacyRoute')
class _LegacyRoutePage extends StatelessWidget {
  const _LegacyRoutePage({
    @PathParam('slug') required this.slug,
  });

  final String slug;
}

@RoutePage(name: 'HydratedRoute')
class _HydratedRoutePage extends ResolverRoute<_FixtureModel, _FixtureModule> {
  const _HydratedRoutePage({
    @PathParam('slug') required this.slug,
  });

  final String slug;
}
