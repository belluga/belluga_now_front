import 'package:belluga_form_validation/src/failures/form_api_failure.dart';
import 'package:belluga_form_validation/src/failures/form_validation_failure.dart';

FormValidationFailure? tryParseFormValidationFailure({
  required int? statusCode,
  required Object? rawData,
}) {
  if (statusCode != 422) {
    return null;
  }
  final data = _asMap(rawData);
  if (data == null) {
    return null;
  }

  final message = _readValidationMessage(data);
  final fieldErrors = _readFieldErrors(data);
  if (fieldErrors.isEmpty && message.isNotEmpty) {
    fieldErrors['global'] = <String>[message];
  }

  return FormValidationFailure(
    statusCode: 422,
    message: message.isEmpty ? 'Validation failed.' : message,
    errorCode: _readString(_readMap(data, 'error'), 'code') ??
        _readString(data, 'code'),
    hints: _readStringList(_readMap(data, 'error'), 'hints') ??
        _readStringList(data, 'hints') ??
        const <String>[],
    requestId: _readString(_readMap(data, 'metadata'), 'request_id') ??
        _readString(data, 'request_id'),
    fieldErrors: fieldErrors,
  );
}

FormApiFailure? tryParseFormApiFailure({
  required int? statusCode,
  required Object? rawData,
}) {
  if (statusCode == null) {
    return null;
  }
  final data = _asMap(rawData);
  if (data == null) {
    return null;
  }

  final errorNode = _readMap(data, 'error');
  final errorCode = _readString(errorNode, 'code') ?? _readString(data, 'code');
  final message =
      _readString(errorNode, 'message') ?? _readString(data, 'message');
  final hints = _readStringList(errorNode, 'hints') ??
      _readStringList(data, 'hints') ??
      const <String>[];
  final requestId = _readString(_readMap(data, 'metadata'), 'request_id') ??
      _readString(data, 'request_id');
  final retryAfter = _readInt(data, 'retry_after') ??
      _readInt(_readMap(data, 'metadata'), 'retry_after');
  final correlationId = _readString(data, 'correlation_id') ??
      _readString(_readMap(data, 'metadata'), 'correlation_id');
  final cfRayId = _readString(data, 'cf_ray_id') ??
      _readString(_readMap(data, 'metadata'), 'cf_ray_id');

  final hasStructuredSignal = errorCode != null ||
      message != null ||
      hints.isNotEmpty ||
      requestId != null ||
      retryAfter != null ||
      correlationId != null ||
      cfRayId != null;
  if (!hasStructuredSignal) {
    return null;
  }

  return FormApiFailure(
    statusCode: statusCode,
    message: (message == null || message.isEmpty)
        ? _defaultMessageForStatus(statusCode)
        : message,
    errorCode: errorCode,
    hints: hints,
    requestId: requestId,
    retryAfterSeconds: retryAfter,
    correlationId: correlationId,
    cfRayId: cfRayId,
  );
}

String _defaultMessageForStatus(int statusCode) {
  switch (statusCode) {
    case 401:
      return 'Authentication required.';
    case 403:
      return 'Access denied.';
    case 404:
      return 'Resource not found.';
    case 409:
      return 'Request conflict.';
    case 422:
      return 'Validation failed.';
    case 429:
      return 'Too many requests.';
    default:
      if (statusCode >= 500) {
        return 'Server error.';
      }
      return 'Request failed.';
  }
}

Map<String, dynamic>? _asMap(Object? rawData) {
  if (rawData is Map) {
    return Map<String, dynamic>.from(rawData);
  }
  return null;
}

Map<String, List<String>> _readFieldErrors(Map<String, dynamic> data) {
  final rawErrors = data['errors'];
  if (rawErrors is! Map) {
    return <String, List<String>>{};
  }

  final fieldErrors = <String, List<String>>{};
  for (final entry in rawErrors.entries) {
    final key = entry.key.toString().trim();
    if (key.isEmpty) {
      continue;
    }
    final messages = _coerceMessages(entry.value);
    if (messages.isEmpty) {
      continue;
    }
    fieldErrors[key] = messages;
  }
  return fieldErrors;
}

String _readValidationMessage(Map<String, dynamic> data) {
  final nestedMessage = _readString(_readMap(data, 'error'), 'message');
  if (nestedMessage != null && nestedMessage.isNotEmpty) {
    return nestedMessage;
  }
  return _readString(data, 'message') ?? '';
}

Map<String, dynamic>? _readMap(Map<String, dynamic>? data, String key) {
  if (data == null) {
    return null;
  }
  final value = data[key];
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

String? _readString(Map<String, dynamic>? data, String key) {
  if (data == null) {
    return null;
  }
  final value = data[key];
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) {
    return null;
  }
  return text;
}

List<String>? _readStringList(Map<String, dynamic>? data, String key) {
  if (data == null) {
    return null;
  }
  final value = data[key];
  if (value is! List) {
    return null;
  }
  final items = _coerceMessages(value);
  if (items.isEmpty) {
    return null;
  }
  return items;
}

int? _readInt(Map<String, dynamic>? data, String key) {
  if (data == null) {
    return null;
  }
  final value = data[key];
  if (value is int) {
    return value;
  }
  final parsed = int.tryParse(value?.toString().trim() ?? '');
  return parsed;
}

List<String> _coerceMessages(Object? value) {
  if (value is List) {
    return value
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }
  final message = value?.toString().trim();
  if (message == null || message.isEmpty) {
    return const <String>[];
  }
  return <String>[message];
}
