import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/support/route_instance_scope.dart';
import 'package:belluga_now/application/router/support/route_scoped_resolver_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<_TestModule>(_TestModule());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets(
      'route scoped resolver reruns when resolver params change inside the wrapped route scope',
      (tester) async {
    final resolver = _RecordingResolver();

    Widget buildRoute(String slug) {
      return MaterialApp(
        home: Builder(
          builder: (context) => _FakeResolverRoute(
            slug: slug,
            resolver: resolver,
          ).wrappedRoute(context),
        ),
      );
    }

    await tester.pumpWidget(buildRoute('du-jorge'));
    await tester.pumpAndSettle();

    expect(find.text('du-jorge'), findsOneWidget);
    expect(resolver.calls, ['du-jorge']);
    expect(
      RouteInstanceScope.maybeStoreOf(tester.element(find.text('du-jorge'))),
      isNotNull,
    );

    await tester.pumpWidget(buildRoute('qa-discovery'));
    await tester.pumpAndSettle();

    expect(find.text('qa-discovery'), findsOneWidget);
    expect(resolver.calls, ['du-jorge', 'qa-discovery']);
  });
}

class _FakeResolverRoute extends RouteScopedResolverRoute<String, _TestModule> {
  const _FakeResolverRoute({
    required this.slug,
    required this.resolver,
  });

  final String slug;
  final _RecordingResolver resolver;

  @override
  RouteResolverParams get resolverParams => {'slug': slug};

  @override
  Future<String> resolve(
    BuildContext context,
    RouteResolverParams params,
  ) async {
    return resolver.resolve(params);
  }

  @override
  Widget buildScreen(BuildContext context, String model) {
    return Text(model, textDirection: TextDirection.ltr);
  }
}

class _RecordingResolver {
  final List<String> calls = <String>[];

  Future<String> resolve(RouteResolverParams params) async {
    final slug = (params['slug'] as String?) ?? '';
    calls.add(slug);
    return slug;
  }
}

class _TestModule extends ModuleContract {
  @override
  Future<void> registerDependencies() async {}

  @override
  List<AutoRoute> get routes => const <AutoRoute>[];
}
