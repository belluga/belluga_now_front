import 'package:belluga_form_validation/belluga_form_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tryParseFormValidationFailure preserves structured 422 field errors',
      () {
    final failure = tryParseFormValidationFailure(
      statusCode: 422,
      rawData: <String, dynamic>{
        'message': 'The given data was invalid.',
        'errors': <String, dynamic>{
          'name': <String>['Nome e obrigatorio.'],
        },
      },
    );

    expect(failure, isNotNull);
    expect(failure!.message, 'The given data was invalid.');
    expect(failure.fieldErrors['name'], <String>['Nome e obrigatorio.']);
  });

  test(
      'tryParseFormValidationFailure maps 422 security envelope to global validation',
      () {
    final failure = tryParseFormValidationFailure(
      statusCode: 422,
      rawData: <String, dynamic>{
        'code': 'idempotency_missing',
        'message': 'Idempotency key is required for this endpoint.',
        'correlation_id': 'corr-123',
      },
    );

    expect(failure, isNotNull);
    expect(failure!.errorCode, 'idempotency_missing');
    expect(
      failure.fieldErrors['global'],
      <String>['Idempotency key is required for this endpoint.'],
    );
  });

  test('tryParseFormApiFailure parses security envelope metadata', () {
    final failure = tryParseFormApiFailure(
      statusCode: 429,
      rawData: <String, dynamic>{
        'code': 'rate_limited',
        'message': 'Too many requests. Retry later.',
        'retry_after': 17,
        'correlation_id': 'corr-xyz',
        'cf_ray_id': 'ray-abc',
      },
    );

    expect(failure, isNotNull);
    expect(failure!.statusCode, 429);
    expect(failure.errorCode, 'rate_limited');
    expect(failure.retryAfterSeconds, 17);
    expect(failure.correlationId, 'corr-xyz');
    expect(failure.cfRayId, 'ray-abc');
    expect(failure.toString(), contains('status=429'));
    expect(failure.toString(), contains('code=rate_limited'));
  });

  test('tryParseFormApiFailure parses nested envelope metadata shape', () {
    final failure = tryParseFormApiFailure(
      statusCode: 403,
      rawData: <String, dynamic>{
        'error': <String, dynamic>{
          'code': 'origin_access_denied',
          'message': 'Direct origin access is not allowed.',
          'hints': <String>['Use the tenant edge host.'],
        },
        'metadata': <String, dynamic>{
          'request_id': 'req-1',
          'retry_after': '30',
        },
      },
    );

    expect(failure, isNotNull);
    expect(failure!.errorCode, 'origin_access_denied');
    expect(failure.requestId, 'req-1');
    expect(failure.retryAfterSeconds, 30);
    expect(failure.hints, <String>['Use the tenant edge host.']);
  });
}
