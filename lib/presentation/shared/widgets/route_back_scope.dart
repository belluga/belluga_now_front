import 'package:belluga_now/application/router/support/route_back_policy.dart';
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        backPolicy.handleBack();
      },
      child: child,
    );
  }
}
