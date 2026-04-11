import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/support/route_no_history_outcome_kind.dart';

typedef RouteNoHistoryHandler = FutureOr<void> Function(StackRouter router);
typedef RouteNoHistoryDelegate = FutureOr<void> Function();

final class RouteNoHistoryOutcome {
  RouteNoHistoryOutcome._({
    required this.kind,
    required RouteNoHistoryHandler handler,
  }) : _handler = handler;

  final RouteNoHistoryOutcomeKind kind;
  final RouteNoHistoryHandler _handler;

  factory RouteNoHistoryOutcome.fallback(
    PageRouteInfo<dynamic> route,
  ) {
    return RouteNoHistoryOutcome._(
      kind: RouteNoHistoryOutcomeKind.fallbackRoute,
      handler: (router) => router.replaceAll([route]),
    );
  }

  factory RouteNoHistoryOutcome.replace(
    PageRouteInfo<dynamic> route,
  ) {
    return RouteNoHistoryOutcome._(
      kind: RouteNoHistoryOutcomeKind.replaceRoute,
      handler: (router) => router.replace(route),
    );
  }

  factory RouteNoHistoryOutcome.delegateToShell(
    RouteNoHistoryDelegate delegate,
  ) {
    return RouteNoHistoryOutcome._(
      kind: RouteNoHistoryOutcomeKind.delegateToShell,
      handler: (_) => delegate(),
    );
  }

  factory RouteNoHistoryOutcome.requestExit(
    RouteNoHistoryDelegate delegate,
  ) {
    return RouteNoHistoryOutcome._(
      kind: RouteNoHistoryOutcomeKind.requestExit,
      handler: (_) => delegate(),
    );
  }

  factory RouteNoHistoryOutcome.noop() {
    return RouteNoHistoryOutcome._(
      kind: RouteNoHistoryOutcomeKind.noop,
      handler: (_) {},
    );
  }

  Future<void> run(StackRouter router) {
    return Future<void>.sync(() => _handler(router));
  }
}
