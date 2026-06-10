import 'dart:async';

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
            resolveWith: resolver.resolve,
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

  testWidgets(
      'route scoped resolver keeps the last resolved screen visible while param refresh is pending',
      (tester) async {
    final resolver = _CompleterResolver();

    Widget buildRoute(String slug) {
      return MaterialApp(
        home: Builder(
          builder: (context) => _FakeResolverRoute(
            slug: slug,
            resolveWith: resolver.resolve,
          ).wrappedRoute(context),
        ),
      );
    }

    await tester.pumpWidget(buildRoute('du-jorge'));
    final firstCompleter = resolver.pending.removeAt(0);
    firstCompleter.complete('du-jorge');
    await tester.pumpAndSettle();

    expect(find.text('du-jorge'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pumpWidget(buildRoute('qa-discovery'));
    await tester.pump();

    expect(find.text('du-jorge'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    final secondCompleter = resolver.pending.removeAt(0);
    secondCompleter.complete('qa-discovery');
    await tester.pumpAndSettle();

    expect(find.text('qa-discovery'), findsOneWidget);
  });
}

class _FakeResolverRoute extends RouteScopedResolverRoute<String, _TestModule> {
  const _FakeResolverRoute({
    required this.slug,
    required this.resolveWith,
  });

  final String slug;
  final Future<String> Function(RouteResolverParams params) resolveWith;

  @override
  RouteResolverParams get resolverParams => {'slug': slug};

  @override
  Future<String> resolve(
    BuildContext context,
    RouteResolverParams params,
  ) async {
    return resolveWith(params);
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

class _CompleterResolver {
  final List<String> calls = <String>[];
  final List<Completer<String>> pending = <Completer<String>>[];

  Future<String> resolve(RouteResolverParams params) {
    final slug = (params['slug'] as String?) ?? '';
    calls.add(slug);
    final completer = Completer<String>();
    pending.add(completer);
    return completer.future;
  }
}

class _TestModule extends ModuleContract {
  @override
  Future<void> registerDependencies() async {}

  @override
  List<AutoRoute> get routes => const <AutoRoute>[];
}
