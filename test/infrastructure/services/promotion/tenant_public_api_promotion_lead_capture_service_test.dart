import 'package:belluga_now/domain/app_data/value_object/environment_name_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_email_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_phone_value.dart';
import 'package:belluga_now/domain/promotion/promotion_lead_capture_request.dart';
import 'package:belluga_now/domain/promotion/promotion_lead_mobile_platform.dart';
import 'package:belluga_now/infrastructure/services/promotion/tenant_public_api_promotion_lead_capture_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _RecordingDio dio;
  late TenantPublicApiPromotionLeadCaptureService service;
  late PromotionLeadCaptureRequest request;

  setUp(() {
    dio = _RecordingDio();
    service = TenantPublicApiPromotionLeadCaptureService(
      dio: dio,
    );
    request = PromotionLeadCaptureRequest(
      appNameValue: EnvironmentNameValue()..parse('Bóora!'),
      emailValue: ContactEmailValue(raw: 'tester@example.com'),
      whatsappValue: ContactPhoneValue(raw: '27999999999'),
      mobilePlatform: PromotionLeadMobilePlatform.android,
    );
  });

  test('posts the expected payload to the tenant public backend', () async {
    dio.nextStatusCode = 200;

    await service.submitTesterWaitlistLead(request);

    expect(dio.lastUri?.path, '/api/v1/email/send');
    expect(dio.lastData?['email'], 'tester@example.com');
    expect(dio.lastData?['whatsapp'], '27999999999');
    expect(dio.lastData?['os'], 'Android');
    expect(dio.lastData?['app_name'], 'Bóora!');
    expect(
      dio.lastOptions?.headers?['Content-Type'],
      Headers.jsonContentType,
    );
    expect(
      dio.lastOptions?.headers?['Accept'],
      Headers.jsonContentType,
    );
  });

  test('throws backend message when tenant public api responds with error',
      () async {
    dio.errorToThrow = DioException.badResponse(
      statusCode: 503,
      requestOptions: RequestOptions(path: '/api/v1/email/send'),
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/api/v1/email/send'),
        statusCode: 503,
        data: const {
          'ok': false,
          'message':
              'Integracao de email pendente. Informe ao administrador do site.',
        },
      ),
    );

    await expectLater(
      service.submitTesterWaitlistLead(request),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Integracao de email pendente. Informe ao administrador do site.',
        ),
      ),
    );
  });

  test('throws a generic message when no response is received', () async {
    dio.errorToThrow = DioException.connectionError(
      requestOptions: RequestOptions(path: '/api/v1/email/send'),
      reason: 'XMLHttpRequest error',
    );

    await expectLater(
      service.submitTesterWaitlistLead(request),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Nao foi possivel registrar seu contato agora. Tente novamente em instantes.',
        ),
      ),
    );
  });
}

class _RecordingDio extends Fake implements Dio {
  Uri? lastUri;
  Map<String, Object>? lastData;
  Options? lastOptions;
  int nextStatusCode = 200;
  DioException? errorToThrow;

  @override
  Future<Response<T>> postUri<T>(
    Uri uri, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }

    lastUri = uri;
    lastData = (data as Map<String, Object?>?)?.cast<String, Object>();
    lastOptions = options;

    return Response<T>(
      requestOptions: RequestOptions(path: uri.toString()),
      statusCode: nextStatusCode,
    );
  }
}
