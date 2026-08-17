import 'dart:convert';

import 'package:belluga_form_validation/belluga_form_validation.dart';
import 'package:dio/dio.dart';

FormValidationFailure? tenantAdminTryResolveValidationFailure(
  DioException error,
) {
  return tryParseFormValidationFailure(
    statusCode: error.response?.statusCode,
    rawData: error.response?.data,
  );
}

Exception tenantAdminWrapRepositoryError(DioException error, String label) {
  final apiFailure = tryParseFormApiFailure(
    statusCode: error.response?.statusCode,
    rawData: error.response?.data,
  );
  if (apiFailure != null) {
    return apiFailure;
  }

  final status = error.response?.statusCode;
  final data = error.response?.data;
  return Exception(
    'Failed to $label [status=$status] (${error.requestOptions.uri}): '
    '${data ?? error.message}',
  );
}

Exception tenantAdminResolveRawRepositoryFailure({
  required int? statusCode,
  required Object? rawData,
  required String label,
  required String uri,
}) {
  final validationFailure = tryParseFormValidationFailure(
    statusCode: statusCode,
    rawData: rawData,
  );
  if (validationFailure != null) {
    return validationFailure;
  }

  final apiFailure = tryParseFormApiFailure(
    statusCode: statusCode,
    rawData: rawData,
  );
  if (apiFailure != null) {
    return apiFailure;
  }

  final fallback = switch (rawData) {
    String() => rawData.trim(),
    List<int>() => utf8.decode(rawData, allowMalformed: true).trim(),
    null => '',
    _ => _tryEncodeRawData(rawData),
  };
  final renderedMessage = fallback.isEmpty ? 'Request failed.' : fallback;
  return FormatException(
    'Failed to $label [status=$statusCode] ($uri): $renderedMessage',
  );
}

String _tryEncodeRawData(Object rawData) {
  var fallback = rawData.toString().trim();
  try {
    fallback = jsonEncode(rawData);
  } catch (_) {
    // Keep the string fallback when JSON encoding is not possible.
  }
  return fallback;
}
