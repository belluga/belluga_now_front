import 'package:belluga_now/domain/promotion/promotion_lead_capture_request.dart';
import 'package:belluga_now/domain/services/promotion_lead_capture_service_contract.dart';
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
          'email': request.email,
          'whatsapp': request.whatsapp,
          'os': request.mobilePlatform.label,
          'app_name': request.appName,
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
