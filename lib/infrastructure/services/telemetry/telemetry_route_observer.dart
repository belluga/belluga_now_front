import 'dart:async';

import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

class TelemetryRouteObserver extends NavigatorObserver {
  TelemetryRouteObserver({
    TelemetryRepositoryContract? telemetryRepository,
  }) : _telemetryRepository =
            telemetryRepository ?? GetIt.I.get<TelemetryRepositoryContract>();

  final TelemetryRepositoryContract _telemetryRepository;
  EventTrackerTimedEventHandle? _activeTimedEvent;
  Future<void> _pendingTrack = Future.value();
  Route<dynamic>? _lastEnqueuedRoute;

  void _debugWebTelemetry(String message, [Object? details]) {
    if (kIsWeb) {
      final payload = details == null ? message : '$message | $details';
      // ignore: avoid_print
      print('[Telemetry][Web][RouteObserver] $payload');
    }
  }

  Future<void> _track(Route<dynamic>? route) async {
    _debugWebTelemetry('track start', route?.settings.name);
    _finishActiveTimedEvent();
    if (route == null) return;
    final screenContext = _buildScreenContext(route);
    _telemetryRepository.setScreenContext(screenContext);
    _activeTimedEvent = await _telemetryRepository.startTimedEvent(
      EventTrackerEvents.viewContent,
      eventName: 'screen_view',
      properties: {
        'screen_context': screenContext,
      },
    );
    _debugWebTelemetry(
      'track started',
      {
        'route': screenContext['route_name'],
        'handle': _activeTimedEvent?.id,
      },
    );
  }

  void _enqueueTrack(Route<dynamic>? route) {
    if (identical(route, _lastEnqueuedRoute)) {
      _debugWebTelemetry('enqueue skip (same route)', route?.settings.name);
      return;
    }
    _lastEnqueuedRoute = route;
    _debugWebTelemetry('enqueue track', route?.settings.name);
    _pendingTrack =
        _pendingTrack.then((_) => _track(route)).catchError((_) {});
  }

  void _finishActiveTimedEvent() {
    final handle = _activeTimedEvent;
    if (handle == null) {
      return;
    }
    _activeTimedEvent = null;
    _debugWebTelemetry('track finish', handle.id);
    unawaited(_telemetryRepository.finishTimedEvent(handle));
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _enqueueTrack(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _enqueueTrack(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _enqueueTrack(previousRoute);
  }

  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    super.didChangeTop(topRoute, previousTopRoute);
    _enqueueTrack(topRoute);
  }

  Map<String, dynamic> _buildScreenContext(Route<dynamic> route) {
    final routeName = _resolveRouteName(route);
    final routeType = route.runtimeType.toString();
    final isOverlay = route is ModalRoute
        ? route is PopupRoute || route.opaque == false
        : false;
    final routeParams = _extractRouteParams(route.settings.arguments);

    return {
      'route_name': routeName,
      'route_type': routeType,
      'is_overlay': isOverlay,
      if (routeParams != null && routeParams.isNotEmpty)
        'route_params': routeParams,
    };
  }

  String _resolveRouteName(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && name.trim().isNotEmpty) {
      return name;
    }
    return route.runtimeType.toString();
  }

  Map<String, dynamic>? _extractRouteParams(Object? arguments) {
    if (arguments is Map) {
      final map = arguments is Map<String, dynamic>
          ? arguments
          : Map<String, dynamic>.from(arguments);
      final sanitized = <String, dynamic>{};
      map.forEach((key, value) {
        final safeValue = _sanitizeJsonValue(value);
        if (safeValue != null) {
          sanitized[key.toString()] = safeValue;
        }
      });
      return sanitized.isEmpty ? null : sanitized;
    }
    return null;
  }

  Object? _sanitizeJsonValue(Object? value) {
    if (value == null ||
        value is String ||
        value is num ||
        value is bool) {
      return value;
    }
    if (value is Map) {
      final sanitized = <String, dynamic>{};
      value.forEach((key, nested) {
        final safeValue = _sanitizeJsonValue(nested);
        if (safeValue != null) {
          sanitized[key.toString()] = safeValue;
        }
      });
      return sanitized.isEmpty ? null : sanitized;
    }
    if (value is Iterable) {
      final sanitized = value
          .map(_sanitizeJsonValue)
          .where((item) => item != null)
          .toList();
      return sanitized.isEmpty ? null : sanitized;
    }
    return null;
  }
}
