import 'package:belluga_form_validation/belluga_form_validation.dart';
import 'package:dio/dio.dart';

FormValidationFailure? tenantAdminTryResolveValidationFailure(
  DioException error,
) {
  final statusCode = error.response?.statusCode;
  final rawData = error.response?.data;
  if (statusCode != 422 || rawData is! Map) {
    return null;
  }

  final data = Map<String, dynamic>.from(rawData);
  final message = _readValidationMessage(data);
  final fieldErrors = _readFieldErrors(data);

  if (fieldErrors.isEmpty && message.isNotEmpty) {
    fieldErrors['global'] = <String>[message];
  }

  return FormValidationFailure(
    statusCode: statusCode!,
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

Exception tenantAdminWrapRepositoryError(
  DioException error,
  String label,
) {
  final status = error.response?.statusCode;
  final data = error.response?.data;
  return Exception(
    'Failed to $label [status=$status] (${error.requestOptions.uri}): '
    '${data ?? error.message}',
  );
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

Map<String, dynamic>? _readMap(Map<String, dynamic> data, String key) {
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
