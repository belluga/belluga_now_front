import 'dart:convert';

import 'package:flutter/foundation.dart';

final class InviteFlowDebugLogger {
  InviteFlowDebugLogger._();

  static const String _tag = '[InviteFlowDebug]';
  static const String _redacted = '<redacted>';
  static int _sequence = 0;
  static void Function(String message) _writer = _defaultWriter;

  static String nextTraceId(String scope) {
    final normalizedScope = scope
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-');
    final resolvedScope = normalizedScope.isEmpty ? 'trace' : normalizedScope;
    _sequence += 1;
    return '$resolvedScope#$_sequence';
  }

  static void log(
    String event, {
    String? traceId,
    Map<String, Object?> fields = const <String, Object?>{},
  }) {
    if (!kDebugMode) {
      return;
    }

    final payload = <String, Object?>{
      'event': event,
      if (traceId != null && traceId.isNotEmpty) 'trace_id': traceId,
      ...sanitizeFieldsForTesting(fields),
    };

    _writer('$_tag ${jsonEncode(payload)}');
  }

  static void logPagedFetch(
    String event, {
    String? traceId,
    required int page,
    required int pageSize,
  }) {
    log(
      event,
      traceId: traceId,
      fields: <String, Object?>{'page': page, 'page_size': pageSize},
    );
  }

  static void logCount(
    String event, {
    String? traceId,
    required String field,
    required int count,
  }) {
    log(event, traceId: traceId, fields: <String, Object?>{field: count});
  }

  static void logReason(
    String event, {
    String? traceId,
    required String reason,
  }) {
    log(event, traceId: traceId, fields: <String, Object?>{'reason': reason});
  }

  static void logReasonWithCount(
    String event, {
    String? traceId,
    required String reason,
    required String countField,
    required int count,
  }) {
    log(
      event,
      traceId: traceId,
      fields: <String, Object?>{'reason': reason, countField: count},
    );
  }

  static void logContactsImportSkipped({
    required String traceId,
    required int inputContactCount,
    required bool forceImport,
    required bool regionCodePresent,
  }) {
    log(
      'contacts.import.repository.skipped',
      traceId: traceId,
      fields: <String, Object?>{
        'reason': 'no_import_items',
        'input_contact_count': inputContactCount,
        'force_import': forceImport,
        'region_code_present': regionCodePresent,
      },
    );
  }

  static void logContactsImportSnapshot({
    required String traceId,
    required int inputContactCount,
    required bool forceImport,
    required bool regionCodePresent,
    required int importItemCount,
    required bool cacheHit,
    required int cachedMatchCount,
  }) {
    log(
      'contacts.import.repository.snapshot',
      traceId: traceId,
      fields: <String, Object?>{
        'input_contact_count': inputContactCount,
        'force_import': forceImport,
        'region_code_present': regionCodePresent,
        'import_item_count': importItemCount,
        'cache_hit': cacheHit,
        'cached_match_count': cachedMatchCount,
      },
    );
  }

  static void logInviteSendRequest({
    required String traceId,
    required int recipientCount,
    required bool hasMessage,
    required int messageLength,
  }) {
    log(
      'invites.send.repository.request',
      traceId: traceId,
      fields: <String, Object?>{
        'recipient_count': recipientCount,
        'has_message': hasMessage,
        'message_length': messageLength,
      },
    );
  }

  static void logInviteSendStateUpdated({
    required String traceId,
    required int recipientCount,
    required int acknowledgedCount,
  }) {
    log(
      'invites.send.repository.state_updated',
      traceId: traceId,
      fields: <String, Object?>{
        'recipient_count': recipientCount,
        'acknowledged_count': acknowledgedCount,
      },
    );
  }

  @visibleForTesting
  static Map<String, Object?> sanitizeFieldsForTesting(
    Map<String, Object?> fields,
  ) {
    final sanitized = <String, Object?>{};
    fields.forEach((key, value) {
      sanitized[key] = _sanitizeValue(key, value);
    });
    return sanitized;
  }

  @visibleForTesting
  static void overrideWriterForTesting(void Function(String message) writer) {
    _writer = writer;
  }

  @visibleForTesting
  static void resetForTesting() {
    _sequence = 0;
    _writer = _defaultWriter;
  }

  static Object? _sanitizeValue(String key, Object? value) {
    if (value == null || value is num || value is bool) {
      return value;
    }

    if (_shouldRedact(key)) {
      return _redacted;
    }

    if (value is String) {
      return value;
    }

    if (value is DateTime) {
      return value.toIso8601String();
    }

    if (value is Map) {
      final sanitized = <String, Object?>{};
      value.forEach((nestedKey, nestedValue) {
        sanitized[nestedKey.toString()] = _sanitizeValue(
          nestedKey.toString(),
          nestedValue,
        );
      });
      return sanitized;
    }

    if (value is Iterable) {
      return value
          .map((item) => _sanitizeCollectionItem(key, item))
          .toList(growable: false);
    }

    return value.toString();
  }

  static Object? _sanitizeCollectionItem(String key, Object? value) {
    if (value == null || value is num || value is bool) {
      return value;
    }

    if (_shouldRedact(key)) {
      return _redacted;
    }

    if (value is String) {
      return value;
    }

    if (value is DateTime) {
      return value.toIso8601String();
    }

    if (value is Map) {
      final sanitized = <String, Object?>{};
      value.forEach((nestedKey, nestedValue) {
        sanitized[nestedKey.toString()] = _sanitizeValue(
          nestedKey.toString(),
          nestedValue,
        );
      });
      return sanitized;
    }

    if (value is Iterable) {
      return value
          .map((item) => _sanitizeCollectionItem(key, item))
          .toList(growable: false);
    }

    return value.toString();
  }

  static bool _shouldRedact(String key) {
    final normalized = key.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }

    return normalized == 'authorization' ||
        normalized == 'token' ||
        normalized == 'auth_token' ||
        normalized == 'push_token' ||
        normalized == 'device_token' ||
        normalized == 'phone' ||
        normalized == 'email' ||
        normalized == 'hash' ||
        normalized == 'contacts' ||
        normalized == 'recipients' ||
        normalized == 'device_id' ||
        normalized == 'display_name' ||
        normalized == 'name' ||
        normalized.endsWith('_token') ||
        normalized.endsWith('_phone') ||
        normalized.endsWith('_email') ||
        normalized.endsWith('_hash') ||
        normalized.endsWith('_name') ||
        normalized.endsWith('_device_id') ||
        normalized.contains('account_profile_id');
  }

  static void _defaultWriter(String message) {
    debugPrint(message);
  }
}
