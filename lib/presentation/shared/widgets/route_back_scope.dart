import 'package:belluga_now/application/router/support/route_back_policy.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class RouteBackScope extends StatelessWidget {
  const RouteBackScope({
    super.key,
    required this.backPolicy,
    required this.child,
  });

  final RouteBackPolicy backPolicy;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final router = context.router;
    final navigationHistory = kIsWeb ? _tryGetNavigationHistory(router) : null;
    final listenables = kIsWeb
        ? <Listenable>[
            if (_usableListenable(router) case final routerListenable?)
              routerListenable,
            if (_usableListenable(navigationHistory)
                case final historyListenable?)
              historyListenable,
          ]
        : const <Listenable>[];

    Widget buildScope(Widget child) {
      final allowPlatformPop = kIsWeb ? _allowPlatformPop(router) : false;
      return PopScope(
        canPop: allowPlatformPop,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop || kIsWeb) {
            return;
          }
          backPolicy.handleBack();
        },
        child: child,
      );
    }

    if (listenables.isEmpty) {
      return buildScope(child);
    }

    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      child: child,
      builder: (context, routedChild) {
        return buildScope(routedChild ?? const SizedBox.shrink());
      },
    );
  }
}

Listenable? _usableListenable(Object? candidate) {
  if (candidate is! Listenable) {
    return null;
  }
  void noop() {}
  try {
    candidate.addListener(noop);
    candidate.removeListener(noop);
    return candidate;
  } catch (_) {
    return null;
  }
}

Object? _tryGetNavigationHistory(StackRouter router) {
  try {
    return router.root.navigationHistory;
  } catch (_) {
    return null;
  }
}

bool _canNavigateBackWithManagedHistory(StackRouter router) {
  try {
    return router.root.navigationHistory.canNavigateBack;
  } catch (_) {
    return false;
  }
}

bool _allowPlatformPop(StackRouter router) {
  return router.canPop() || _canNavigateBackWithManagedHistory(router);
}
