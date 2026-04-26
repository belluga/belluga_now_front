import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/support/back_surface_kind.dart';
import 'package:belluga_now/application/router/support/route_back_policy.dart';
import 'package:belluga_now/application/router/support/route_back_spec.dart';

final class DeterministicRouteBackPolicy implements RouteBackPolicy {
  DeterministicRouteBackPolicy(
    this._router, {
    required this.spec,
  });

  static final Set<String> _activeReentrancyKeys = <String>{};

  final StackRouter _router;
  final RouteBackSpec spec;
  bool _isHandlingBack = false;

  @override
  BackSurfaceKind get surfaceKind => spec.surfaceKind;

  @override
  void handleBack() {
    if (!_tryEnterHandling()) {
      return;
    }
    unawaited(
      _handleBackAsync().whenComplete(() {
        _leaveHandling();
      }),
    );
  }

  bool _tryEnterHandling() {
    final reentrancyKey = spec.reentrancyKey;
    if (reentrancyKey != null) {
      return _activeReentrancyKeys.add(reentrancyKey);
    }
    if (_isHandlingBack) {
      return false;
    }
    _isHandlingBack = true;
    return true;
  }

  void _leaveHandling() {
    final reentrancyKey = spec.reentrancyKey;
    if (reentrancyKey != null) {
      _activeReentrancyKeys.remove(reentrancyKey);
      return;
    }
    _isHandlingBack = false;
  }

  Future<void> _handleBackAsync() async {
    final localConsumer = spec.consumeLocalStateIfNeeded;
    if (localConsumer != null && await localConsumer()) {
      return;
    }

    if (_router.canPop()) {
      _router.pop();
      return;
    }

    await spec.noHistoryOutcome.run(_router);
  }
}
