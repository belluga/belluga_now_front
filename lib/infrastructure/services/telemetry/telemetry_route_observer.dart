import 'dart:async';

import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

class TelemetryRouteObserver extends NavigatorObserver {
  TelemetryRouteObserver({
    TelemetryRepositoryContract? telemetryRepository,
  }) : _telemetryRepository =
            telemetryRepository ?? GetIt.I.get<TelemetryRepositoryContract>();

  final TelemetryRepositoryContract _telemetryRepository;

  static const Map<String, String> _screenNamesByRoute = {
    'TenantHomeRoute': 'home',
    'CityMapRoute': 'map',
    'InviteFlowRoute': 'invites',
    'EventSearchRoute': 'schedule',
    'ProfileRoute': 'profile',
  };

  void _track(Route<dynamic>? route) {
    if (route is! PageRoute) return;
    final routeName = route.settings.name;
    if (routeName == null || routeName.isEmpty) return;
    final screenName = _screenNamesByRoute[routeName];
    if (screenName == null) return;
    unawaited(
      _telemetryRepository.logEvent(
        EventTrackerEvents.viewContent,
        eventName: 'screen_view',
        properties: {
          'screen_name': screenName,
          'route_name': routeName,
        },
      ),
    );
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _track(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _track(newRoute);
  }
}
