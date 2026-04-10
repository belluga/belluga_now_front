import 'dart:async';

import 'package:belluga_now/application/router/support/back_surface_kind.dart';
import 'package:belluga_now/application/router/support/route_no_history_outcome.dart';

typedef RouteBackLocalStateConsumer = FutureOr<bool> Function();

final class RouteBackSpec {
  const RouteBackSpec({
    required this.surfaceKind,
    required this.noHistoryOutcome,
    this.consumeLocalStateIfNeeded,
    this.reentrancyKey,
  });

  final BackSurfaceKind surfaceKind;
  final RouteBackLocalStateConsumer? consumeLocalStateIfNeeded;
  final RouteNoHistoryOutcome noHistoryOutcome;
  final String? reentrancyKey;
}
