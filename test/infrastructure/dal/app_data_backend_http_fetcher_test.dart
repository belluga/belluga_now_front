import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/app_data_backend_http_fetcher.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses wrapped environment payloads into AppDataDTO', () async {
    final dio = _FakeDio([
      _response(
        data: {
          'data': _environmentPayload(),
        },
      ),
    ]);

    final dto = await fetchAppDataEnvironment(
      bootstrapBaseUrl: 'https://tenant.example.test',
      dio: dio,
      appDomain: 'app.domain.test',
    );

    expect(dto.name, 'Tenant Test');
    expect(dto.mainDomain, 'https://tenant.example.test');
    expect(dio.recordedCalls, hasLength(1));
    expect(
      dio.recordedCalls.single.options?.headers,
      containsPair('X-App-Domain', 'app.domain.test'),
    );
  });

  test('retries without X-App-Domain when backend rejects unknown app_domain',
      () async {
    final dio = _FakeDio([
      DioException(
        requestOptions: RequestOptions(path: '/api/v1/environment'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/environment'),
          statusCode: 422,
          data: const {
            'message': 'Unknown app_domain provided.',
          },
        ),
      ),
      _response(
        data: _environmentPayload(),
      ),
    ]);

    final dto = await fetchAppDataEnvironment(
      bootstrapBaseUrl: 'https://tenant.example.test',
      dio: dio,
      appDomain: 'bad.app.domain',
    );

    expect(dto.name, 'Tenant Test');
    expect(dio.recordedCalls, hasLength(2));
    expect(
      dio.recordedCalls.first.options?.headers,
      containsPair('X-App-Domain', 'bad.app.domain'),
    );
    expect(
      dio.recordedCalls.last.options?.headers,
      isNot(contains('X-App-Domain')),
    );
  });

  test('retries without X-App-Domain when first response is HTML shell',
      () async {
    final dio = _FakeDio([
      _response(data: '<!DOCTYPE html><html><body>fallback</body></html>'),
      _response(data: _environmentPayload()),
    ]);

    final dto = await fetchAppDataEnvironment(
      bootstrapBaseUrl: 'https://tenant.example.test',
      dio: dio,
      appDomain: 'app.domain.test',
    );

    expect(dto.name, 'Tenant Test');
    expect(dio.recordedCalls, hasLength(2));
    expect(
      dio.recordedCalls.first.options?.headers,
      containsPair('X-App-Domain', 'app.domain.test'),
    );
    expect(
      dio.recordedCalls.last.options?.headers,
      isNot(contains('X-App-Domain')),
    );
  });
}

Response<dynamic> _response({required dynamic data}) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: '/api/v1/environment'),
    statusCode: 200,
    data: data,
  );
}

Map<String, dynamic> _environmentPayload() {
  return {
    'name': 'Tenant Test',
    'type': 'tenant',
    'main_domain': 'https://tenant.example.test',
    'profile_types': const [
      {
        'type': 'artist',
        'label': 'Artist',
        'allowed_taxonomies': [],
        'capabilities': {
          'is_favoritable': true,
          'is_poi_enabled': true,
        },
      },
    ],
    'domains': const ['https://tenant.example.test'],
    'app_domains': const [],
    'theme_data_settings': const {
      'brightness_default': 'dark',
      'primary_seed_color': '#112233',
      'secondary_seed_color': '#445566',
    },
    'main_color': '#112233',
    'tenant_id': 'tenant-1',
    'telemetry': const {'trackers': []},
    'telemetry_context': const {'location_freshness_minutes': 5},
    'firebase': null,
    'push': null,
    'settings': {
      'map_ui': {
        'radius': {
          'min_km': 1,
          'default_km': 5,
          'max_km': 50,
        },
      },
    },
  };
}

class _RecordedDioCall {
  const _RecordedDioCall({
    required this.path,
    required this.options,
  });

  final String path;
  final Options? options;
}

class _FakeDio extends Fake implements Dio {
  _FakeDio(this._results);

  final List<Object> _results;
  final List<_RecordedDioCall> recordedCalls = <_RecordedDioCall>[];
  final BaseOptions _options =
      BaseOptions(baseUrl: 'https://tenant.example.test');

  @override
  BaseOptions get options => _options;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    recordedCalls.add(_RecordedDioCall(path: path, options: options));
    final next = _results.removeAt(0);
    if (next is DioException) {
      throw next;
    }
    return next as Response<T>;
  }
}
