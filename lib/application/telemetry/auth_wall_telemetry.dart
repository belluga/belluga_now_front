import 'dart:async';

import 'package:belluga_now/application/telemetry/auth_wall_action.dart';
import 'package:belluga_now/application/telemetry/auth_wall_action_type.dart';
import 'package:belluga_now/application/time/timezone_converter.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:get_it/get_it.dart';

export 'auth_wall_action.dart';
export 'auth_wall_action_type.dart';

final class AuthWallTelemetry {
  AuthWallTelemetry._();

  static const String authWallSource = 'auth_wall';
  static const String directSource = 'direct';

  static const Duration _dedupeWindow = Duration(seconds: 2);
  static const Duration _signupContextTtl = Duration(minutes: 15);

  static String? _lastTrackedActionType;
  static DateTime? _lastTrackedAt;
  static String? _lastAuthWallActionType;
  static String? _lastAuthWallRedirectPath;
  static Map<String, dynamic>? _lastAuthWallPayload;
  static bool _lastAuthWallAllowsPendingActionReplay = false;
  static DateTime? _lastAuthWallAt;

  static String? resolveActionTypeForPath(String path) {
    final normalizedPath = _normalizePath(path);
    if (normalizedPath == '/convites/compartilhar') {
      return AuthWallActionType.sendInvite;
    }
    return null;
  }

  static void trackTriggered({
    required String actionType,
    required String redirectPath,
    Map<String, dynamic>? payload,
    bool allowPendingActionReplay = true,
  }) {
    _rememberAuthWallContext(
      actionType: actionType,
      redirectPath: redirectPath,
      payload: payload,
      allowPendingActionReplay: allowPendingActionReplay,
    );

    if (_shouldSuppressDuplicate(actionType)) {
      return;
    }

    _lastTrackedActionType = actionType;
    _lastTrackedAt = TimezoneConverter.localToUtc(DateTime.now());
    unawaited(
      _logAuthWallTriggered(
        actionType: actionType,
        redirectPath: redirectPath,
      ),
    );
  }

  static Future<void> trackSignupCompleted() async {
    if (!GetIt.I.isRegistered<TelemetryRepositoryContract>()) {
      return;
    }

    final telemetry = GetIt.I.get<TelemetryRepositoryContract>();
    final properties = consumeSignupCompletedProperties();
    await telemetry.logEvent(
      EventTrackerEvents.buttonClick,
      eventName: telemetryRepoString('app_signup_completed'),
      properties: telemetryRepoMap(properties),
    );
  }

  static Map<String, dynamic> consumeSignupCompletedProperties() {
    final now = TimezoneConverter.localToUtc(DateTime.now());
    final capturedAt = _lastAuthWallAt;
    if (capturedAt == null || now.difference(capturedAt) > _signupContextTtl) {
      _clearAuthWallContext();
      return const <String, dynamic>{
        'source': directSource,
      };
    }

    final properties = <String, dynamic>{
      'source': authWallSource,
    };
    final actionType = _lastAuthWallActionType;
    if (actionType != null && actionType.isNotEmpty) {
      properties['action_type'] = actionType;
    }
    final redirectPath = _lastAuthWallRedirectPath;
    if (redirectPath != null && redirectPath.isNotEmpty) {
      properties['redirect_path'] = redirectPath;
    }
    _clearAuthWallContext();
    return properties;
  }

  static AuthWallAction? consumePendingAction(String currentPath) {
    if (_lastAuthWallActionType == null || _lastAuthWallRedirectPath == null) {
      return null;
    }

    final normalizedCurrent = _normalizePath(currentPath);
    if (_lastAuthWallAllowsPendingActionReplay &&
        normalizedCurrent == _lastAuthWallRedirectPath) {
      final action = AuthWallAction(
        actionType: _lastAuthWallActionType!,
        payload: _lastAuthWallPayload,
      );
      // For login, we want the action back. Let's clear so it doesn't fire twice.
      _clearAuthWallContext();
      return action;
    }
    return null;
  }

  static void resetForTesting() {
    _lastTrackedActionType = null;
    _lastTrackedAt = null;
    _clearAuthWallContext();
  }

  static void _rememberAuthWallContext({
    required String actionType,
    required String redirectPath,
    Map<String, dynamic>? payload,
    required bool allowPendingActionReplay,
  }) {
    _lastAuthWallActionType = actionType;
    _lastAuthWallRedirectPath = _normalizePath(redirectPath);
    _lastAuthWallPayload = payload;
    _lastAuthWallAllowsPendingActionReplay = allowPendingActionReplay;
    _lastAuthWallAt = TimezoneConverter.localToUtc(DateTime.now());
  }

  static bool _shouldSuppressDuplicate(String actionType) {
    final lastTrackedAt = _lastTrackedAt;
    if (lastTrackedAt == null || _lastTrackedActionType != actionType) {
      return false;
    }

    final elapsed =
        TimezoneConverter.localToUtc(DateTime.now()).difference(lastTrackedAt);
    return elapsed >= Duration.zero && elapsed <= _dedupeWindow;
  }

  static Future<void> _logAuthWallTriggered({
    required String actionType,
    required String redirectPath,
  }) async {
    if (!GetIt.I.isRegistered<TelemetryRepositoryContract>()) {
      return;
    }

    final telemetry = GetIt.I.get<TelemetryRepositoryContract>();
    await telemetry.logEvent(
      EventTrackerEvents.buttonClick,
      eventName: telemetryRepoString('app_auth_wall_triggered'),
      properties: telemetryRepoMap(<String, dynamic>{
        'source': authWallSource,
        'action_type': actionType,
        'redirect_path': _normalizePath(redirectPath),
      }),
    );
  }

  static void _clearAuthWallContext() {
    _lastAuthWallActionType = null;
    _lastAuthWallRedirectPath = null;
    _lastAuthWallPayload = null;
    _lastAuthWallAllowsPendingActionReplay = false;
    _lastAuthWallAt = null;
  }

  static String _normalizePath(String path) {
    final raw = path.trim();
    if (raw.isEmpty) {
      return '/';
    }

    final uri = Uri.tryParse(raw);
    final normalizedPath = (uri?.path ?? raw).trim();
    if (normalizedPath.isEmpty) {
      return '/';
    }
    return normalizedPath.startsWith('/') ? normalizedPath : '/$normalizedPath';
  }
}
