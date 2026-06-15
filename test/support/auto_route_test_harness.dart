import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpAutoRouteTestApp(
  WidgetTester tester, {
  required Widget child,
  String routeName = 'auto-route-test',
  CanonicalRouteFamily? routeFamily,
  ThemeData? theme,
}) async {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  final router = RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: routeName,
        path: '/',
        meta: routeFamily == null
            ? const <String, dynamic>{}
            : canonicalRouteMeta(family: routeFamily),
        builder: (_, __) => child,
      ),
    ],
  )..ignorePopCompleters = true;

  await tester.pumpWidget(
    MaterialApp.router(
      theme: theme,
      routeInformationParser: router.defaultRouteParser(),
      routerDelegate: router.delegate(),
    ),
  );
  await tester.pump();
}
