import 'dart:async';

import 'package:auto_route/auto_route.dart';

void performTenantPublicSafeBack(
  StackRouter router, {
  required PageRouteInfo<dynamic> fallbackRoute,
  bool Function()? consumeBackNavigationIfNeeded,
}) {
  if (consumeBackNavigationIfNeeded?.call() ?? false) {
    return;
  }

  if (router.canPop()) {
    router.pop();
    return;
  }

  unawaited(router.replaceAll([fallbackRoute]));
}
