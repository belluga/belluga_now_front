import 'dart:convert';

import 'package:belluga_now/infrastructure/dal/dao/account_deletion_backend_result.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/auth_backend/auth_backend.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'user_token': 'registered-token',
      'device_id': 'device-id',
    });
    PackageInfo.setMockInitialValues(
      appName: 'Belluga',
      packageName: 'space.belluga.test',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  test('delete uses the exact current-user contract and maps 204', () async {
    final adapter = _RecordingAdapter(statusCode: 204, responseBody: '');
    final backend = LaravelAuthBackend(dio: Dio()..httpClientAdapter = adapter);

    final result = await backend.deleteCurrentAccount();

    expect(result, isA<CurrentAccountDeletionSucceeded>());
    expect(adapter.lastRequest?.method, 'DELETE');
    expect(adapter.lastRequest?.uri.path, '/v1/profile');
    expect(
      adapter.lastRequest?.headers['Authorization'],
      'Bearer registered-token',
    );
    expect(
      adapter.lastRequest?.headers[Headers.acceptHeader],
      'application/json',
    );
    expect(adapter.lastRequest?.contentType, Headers.jsonContentType);
    expect(adapter.lastRequest?.data, const <String, String>{
      'confirmation': 'remove_account',
    });
  });

  test(
    'delete status mapping follows the frozen direct-only contract',
    () async {
      for (final expectation in <(int, Type)>[
        (401, CurrentAccountDeletionPreEraseRejected),
        (403, CurrentAccountDeletionPreEraseRejected),
        (409, CurrentAccountDeletionPreEraseRejected),
        (422, CurrentAccountDeletionPreEraseRejected),
        (500, CurrentAccountDeletionUnknown),
      ]) {
        final adapter = _RecordingAdapter(
          statusCode: expectation.$1,
          responseBody: jsonEncode(<String, String>{'message': 'busy'}),
        );
        final backend = LaravelAuthBackend(
          dio: Dio()..httpClientAdapter = adapter,
        );

        final result = await backend.deleteCurrentAccount();

        expect(result.runtimeType, expectation.$2);
        if (result is CurrentAccountDeletionPreEraseRejected) {
          expect(result.statusCode, expectation.$1);
        }
      }
    },
  );

  test(
    'identity validation status mapping is terminal only for 401 and 404',
    () async {
      for (final expectation in <(int, Type)>[
        (401, CurrentIdentityValidationTerminalAbsent),
        (404, CurrentIdentityValidationTerminalAbsent),
        (403, CurrentIdentityValidationUncertain),
        (422, CurrentIdentityValidationUncertain),
        (500, CurrentIdentityValidationUncertain),
      ]) {
        final adapter = _RecordingAdapter(
          statusCode: expectation.$1,
          responseBody: jsonEncode(<String, String>{'message': 'response'}),
        );
        final backend = LaravelAuthBackend(
          dio: Dio()..httpClientAdapter = adapter,
        );

        final result = await backend
            .validateCurrentIdentityForDeletionResolution();

        expect(result.runtimeType, expectation.$2);
        expect(adapter.lastRequest?.method, 'GET');
        expect(adapter.lastRequest?.uri.path, '/v1/auth/token_validate');
      }
    },
  );

  test('malformed identity validation remains uncertain', () async {
    final adapter = _RecordingAdapter(
      statusCode: 200,
      responseBody: jsonEncode(<String, Object?>{'data': <String, Object?>{}}),
    );
    final backend = LaravelAuthBackend(dio: Dio()..httpClientAdapter = adapter);

    final result = await backend.validateCurrentIdentityForDeletionResolution();

    expect(result, isA<CurrentIdentityValidationUncertain>());
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({required this.statusCode, required this.responseBody});

  final int statusCode;
  final String responseBody;
  RequestOptions? lastRequest;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      responseBody,
      statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }
}
