import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/startup/app_startup_navigation_plan.dart';
import 'package:flutter/foundation.dart';

typedef AppStartupNavigationPlanLoader = Future<AppStartupNavigationPlan>
    Function();

final class AppStartupNavigationCoordinator {
  AppStartupNavigationCoordinator({
    required AppStartupNavigationPlanLoader planLoader,
    List<Duration>? retryDelays,
  })  : _planLoader = planLoader,
        _retryDelays =
            List<Duration>.unmodifiable(retryDelays ?? _defaultRetryDelays);

  final AppStartupNavigationPlanLoader _planLoader;
  final List<Duration> _retryDelays;
  static const List<Duration> _defaultRetryDelays = <Duration>[
    Duration(milliseconds: 250),
    Duration(milliseconds: 500),
    Duration(milliseconds: 750),
    Duration(milliseconds: 1000),
    Duration(milliseconds: 1250),
    Duration(milliseconds: 1500),
    Duration(milliseconds: 1750),
    Duration(milliseconds: 2000),
    Duration(milliseconds: 2500),
  ];

  DeepLink? _pendingInitialDeepLink;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    final plan = await _loadPlanWithRetry();
    _pendingInitialDeepLink = plan.toDeepLink();
  }

  Future<AppStartupNavigationPlan> _loadPlanWithRetry() async {
    Object? lastError;
    StackTrace? lastStackTrace;
    final attempts = 1 + _retryDelays.length;

    for (var attempt = 0; attempt < attempts; attempt += 1) {
      try {
        return await _planLoader();
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
        if (attempt >= _retryDelays.length) {
          break;
        }
        final delay = _retryDelays[attempt];
        if (delay > Duration.zero) {
          await Future<void>.delayed(delay);
        }
      }
    }

    debugPrint(
      'AppStartupNavigationCoordinator.initialize failed; '
      'continuing without startup override: $lastError\n$lastStackTrace',
    );
    return const AppStartupNavigationPlan.none();
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
