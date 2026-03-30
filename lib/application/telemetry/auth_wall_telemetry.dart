import 'dart:async';

import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:get_it/get_it.dart';

final class AuthWallActionType {
  AuthWallActionType._();

  static const favorite = 'favorite';
  static const sendInvite = 'send_invite';
}

final class AuthWallAction {
  const AuthWallAction({
    required this.actionType,
    this.payload,
  });

  final String actionType;
  final Map<String, dynamic>? payload;
}

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
  }) {
    _rememberAuthWallContext(
      actionType: actionType,
      redirectPath: redirectPath,
      payload: payload,
    );

    if (_shouldSuppressDuplicate(actionType)) {
      return;
    }

    _lastTrackedActionType = actionType;
    _lastTrackedAt = DateTime.now().toUtc();
    unawaited(
      _logAuthWallTriggered(
        actionType: actionType,
        redirectPath: redirectPath,
      ),
    );
  }

  static Map<String, dynamic> consumeSignupCompletedProperties() {
    final now = DateTime.now().toUtc();
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
    if (normalizedCurrent == _lastAuthWallRedirectPath) {
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
  }) {
    _lastAuthWallActionType = actionType;
    _lastAuthWallRedirectPath = _normalizePath(redirectPath);
    _lastAuthWallPayload = payload;
    _lastAuthWallAt = DateTime.now().toUtc();
  }

  static bool _shouldSuppressDuplicate(String actionType) {
    final lastTrackedAt = _lastTrackedAt;
    if (lastTrackedAt == null || _lastTrackedActionType != actionType) {
      return false;
    }

    final elapsed = DateTime.now().toUtc().difference(lastTrackedAt);
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
      eventName: 'app_auth_wall_triggered',
      properties: <String, dynamic>{
        'source': authWallSource,
        'action_type': actionType,
        'redirect_path': _normalizePath(redirectPath),
      },
    );
  }

  static void _clearAuthWallContext() {
    _lastAuthWallActionType = null;
    _lastAuthWallRedirectPath = null;
    _lastAuthWallPayload = null;
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
