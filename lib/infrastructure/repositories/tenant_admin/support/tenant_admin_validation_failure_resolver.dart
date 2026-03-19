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

Exception tenantAdminWrapRepositoryError(
  DioException error,
  String label,
) {
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
