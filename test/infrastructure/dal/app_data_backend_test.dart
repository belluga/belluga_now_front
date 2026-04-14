import 'dart:convert';

import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/app_data_backend_stub.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const packageInfoChannel =
      MethodChannel('dev.fluttercommunity.plus/package_info');

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(packageInfoChannel, (call) async {
      return <String, dynamic>{
        'appName': 'Belluga Now',
        'packageName': 'com.boora.app',
        'version': '1.0.0',
        'buildNumber': '1',
      };
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(packageInfoChannel, null);
  });

  test('fetch parses JSON string payload from /environment', () async {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://guarappari.belluga.space',
      ),
    )..httpClientAdapter = _StringEnvironmentAdapter();

    final backend = AppDataBackend(dio: dio);
    final dto = await backend.fetch();

    expect(dto.type, 'tenant');
    expect(dto.mainDomain, 'https://guarappari.belluga.space');
    expect(dto.name, 'Guarappari');
    expect(dto.themeDataSettings['primary_seed_color'], '#A36CE3');
  });

  test('fetch retries without X-App-Domain when response is HTML', () async {
    final adapter = _HtmlFallbackAdapter();
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://guarappari.belluga.space',
      ),
    )..httpClientAdapter = adapter;

    final backend = AppDataBackend(dio: dio);
    final dto = await backend.fetch();

    expect(dto.type, 'tenant');
    expect(dto.mainDomain, 'https://guarappari.belluga.space');
    expect(adapter.requestCount, 2);
    expect(adapter.seenRequestWithAppDomain, isTrue);
    expect(adapter.seenRequestWithoutAppDomain, isTrue);
  });

  test('fetch retries without X-App-Domain on unknown app_domain (422)',
      () async {
    final adapter = _UnknownAppDomainFallbackAdapter();
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://guarappari.belluga.space',
      ),
    )..httpClientAdapter = adapter;

    final backend = AppDataBackend(dio: dio);
    final dto = await backend.fetch();

    expect(dto.type, 'tenant');
    expect(dto.mainDomain, 'https://guarappari.belluga.space');
    expect(adapter.requestCount, 2);
    expect(adapter.seenRequestWithAppDomain, isTrue);
    expect(adapter.seenRequestWithoutAppDomain, isTrue);
  });

  test(
      'fetch keeps main_domain as effective origin when domains omit the implicit subdomain host',
      () async {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://guarappari.belluga.space',
      ),
    )..httpClientAdapter = _MultiDomainEnvironmentAdapter();

    final backend = AppDataBackend(dio: dio);
    final dto = await backend.fetch();

    expect(dto.type, 'tenant');
    expect(dto.mainDomain, 'https://guarappari.belluga.space');
    expect(dto.domains, ['guarapari.com.br']);
  });
}

class _StringEnvironmentAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final payload = <String, Object?>{
      'type': 'tenant',
      'tenant_id': 'tenant-id',
      'name': 'Guarappari',
      'subdomain': 'guarappari',
      'main_domain': 'https://guarappari.belluga.space',
      'landlord_domain': 'https://belluga.space',
      'domains': <String>['guarappari.belluga.space'],
      'app_domains': <String>['com.guarappari.app'],
      'theme_data_settings': <String, Object?>{
        'brightness_default': 'dark',
        'primary_seed_color': '#A36CE3',
        'secondary_seed_color': '#FF6E00',
      },
      'profile_types': const <Object>[],
      'telemetry': <String, Object?>{
        'trackers': const <Object>[],
      },
    };

    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['text/plain'],
      },
    );
  }
}

class _HtmlFallbackAdapter implements HttpClientAdapter {
  int requestCount = 0;
  bool seenRequestWithAppDomain = false;
  bool seenRequestWithoutAppDomain = false;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount += 1;
    final hasAppDomainHeader = options.headers.keys
        .map((key) => key.toString().toLowerCase())
        .contains('x-app-domain');

    if (hasAppDomainHeader) {
      seenRequestWithAppDomain = true;
      return ResponseBody.fromString(
        '<!DOCTYPE html><html><body>Redirect</body></html>',
        200,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>['text/html'],
        },
      );
    }

    seenRequestWithoutAppDomain = true;
    final payload = <String, Object?>{
      'type': 'tenant',
      'tenant_id': 'tenant-id',
      'name': 'Guarappari',
      'subdomain': 'guarappari',
      'main_domain': 'https://guarappari.belluga.space',
      'landlord_domain': 'https://belluga.space',
      'domains': <String>['guarappari.belluga.space'],
      'app_domains': <String>['com.guarappari.app'],
      'theme_data_settings': <String, Object?>{
        'brightness_default': 'dark',
        'primary_seed_color': '#A36CE3',
      },
      'profile_types': const <Object>[],
      'telemetry': <String, Object?>{
        'trackers': const <Object>[],
      },
    };

    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }
}

class _UnknownAppDomainFallbackAdapter implements HttpClientAdapter {
  int requestCount = 0;
  bool seenRequestWithAppDomain = false;
  bool seenRequestWithoutAppDomain = false;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount += 1;
    final hasAppDomainHeader = options.headers.keys
        .map((key) => key.toString().toLowerCase())
        .contains('x-app-domain');

    if (hasAppDomainHeader) {
      seenRequestWithAppDomain = true;
      final payload = <String, Object?>{
        'message': 'Unknown app_domain.',
        'errors': <String, Object?>{
          'app_domain': <String>['Unknown app_domain.'],
        },
      };
      return ResponseBody.fromString(
        jsonEncode(payload),
        422,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>['application/json'],
        },
      );
    }

    seenRequestWithoutAppDomain = true;
    final payload = <String, Object?>{
      'type': 'tenant',
      'tenant_id': 'tenant-id',
      'name': 'Guarappari',
      'subdomain': 'guarappari',
      'main_domain': 'https://guarappari.belluga.space',
      'landlord_domain': 'https://belluga.space',
      'domains': <String>['guarappari.belluga.space'],
      'app_domains': <String>['com.guarappari.app'],
      'theme_data_settings': <String, Object?>{
        'brightness_default': 'dark',
        'primary_seed_color': '#A36CE3',
      },
      'profile_types': const <Object>[],
      'telemetry': <String, Object?>{
        'trackers': const <Object>[],
      },
    };

    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }
}

class _MultiDomainEnvironmentAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final payload = <String, Object?>{
      'type': 'tenant',
      'tenant_id': 'tenant-id',
      'name': 'Guarappari',
      'subdomain': 'guarappari',
      'main_domain': 'https://guarappari.belluga.space',
      'landlord_domain': 'https://belluga.space',
      'domains': <String>['guarapari.com.br'],
      'app_domains': <String>['com.guarappari.app'],
      'theme_data_settings': <String, Object?>{
        'brightness_default': 'dark',
        'primary_seed_color': '#A36CE3',
      },
      'profile_types': const <Object>[],
      'telemetry': <String, Object?>{
        'trackers': const <Object>[],
      },
    };

    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }
}
