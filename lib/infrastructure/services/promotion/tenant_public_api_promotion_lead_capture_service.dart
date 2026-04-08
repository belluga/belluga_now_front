import 'package:belluga_now/application/contracts/promotion/promotion_lead_capture_request.dart';
import 'package:belluga_now/application/contracts/promotion/promotion_lead_capture_service_contract.dart';
import 'package:dio/dio.dart';

class TenantPublicApiPromotionLeadCaptureService
    implements PromotionLeadCaptureServiceContract {
  TenantPublicApiPromotionLeadCaptureService({
    Dio? dio,
  }) : _dio = dio ?? Dio();

  static const _endpointPath = '/api/v1/email/send';

  final Dio _dio;

  @override
  Future<void> submitTesterWaitlistLead(
    PromotionLeadCaptureRequest request,
  ) async {
    try {
      final response = await _dio.postUri<dynamic>(
        Uri(path: _endpointPath),
        options: Options(
          headers: const <String, Object>{
            'Content-Type': Headers.jsonContentType,
            'Accept': Headers.jsonContentType,
          },
        ),
        data: <String, Object>{
          'app_name': request.appName,
          'submitted_fields': request.submittedFields
              .map(
                (field) => <String, String>{
                  'label': field.label,
                  'value': field.value,
                },
              )
              .toList(growable: false),
        },
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode < 200 || statusCode >= 300) {
        throw StateError(_resolveErrorMessage(response.data));
      }
    } on DioException catch (error) {
      final response = error.response;
      if (response != null) {
        throw StateError(_resolveErrorMessage(response.data));
      }
      throw StateError(
        'Nao foi possivel registrar seu contato agora. Tente novamente em instantes.',
      );
    }
  }

  String _resolveErrorMessage(Object? data) {
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }

      final errors = data['errors'];
      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty && value.first is String) {
            return (value.first as String).trim();
          }
        }
      }
    }

    return 'Nao foi possivel registrar seu contato agora. Tente novamente em instantes.';
  }
}
