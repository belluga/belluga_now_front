import 'package:belluga_now/infrastructure/repositories/tenant_admin/support/tenant_admin_validation_failure_resolver.dart';
import 'package:dio/dio.dart';

void tenantAdminAssertSuccessfulMutationResponse(
  Response<dynamic> response, {
  required String label,
  required String uri,
}) {
  final status = response.statusCode;
  if (status != null && status >= 200 && status < 300) {
    return;
  }
  throw tenantAdminResolveRawRepositoryFailure(
    statusCode: status,
    rawData: response.data,
    label: label,
    uri: uri,
  );
}
