import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/startup/app_startup_navigation_plan.dart';

typedef AppStartupNavigationPlanLoader = Future<AppStartupNavigationPlan>
    Function();

final class AppStartupNavigationCoordinator {
  AppStartupNavigationCoordinator({
    required AppStartupNavigationPlanLoader planLoader,
  }) : _planLoader = planLoader;

  final AppStartupNavigationPlanLoader _planLoader;

  DeepLink? _pendingInitialDeepLink;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    final plan = await _planLoader();
    _pendingInitialDeepLink = plan.toDeepLink();
  }

  FutureOr<DeepLink> resolvePlatformDeepLink(PlatformDeepLink deepLink) {
    final pendingInitialDeepLink = _pendingInitialDeepLink;
    _pendingInitialDeepLink = null;
    if (pendingInitialDeepLink == null) {
      return deepLink;
    }
    if (!_isRootBootstrapPath(deepLink.path)) {
      return deepLink;
    }
    return pendingInitialDeepLink;
  }

  bool _isRootBootstrapPath(String rawPath) {
    final parsedUri = Uri.tryParse(rawPath);
    final normalizedPath = parsedUri?.path ?? rawPath;
    return normalizedPath.isEmpty ||
        normalizedPath == '/' ||
        normalizedPath == '/home';
  }
}
