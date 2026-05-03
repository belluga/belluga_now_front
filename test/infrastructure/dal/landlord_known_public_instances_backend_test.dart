import 'dart:convert';

import 'package:belluga_now/infrastructure/dal/dao/landlord_known_public_instances_backend.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses lane subdomain when landlord origin is belluga.app', () async {
    final adapter = _RecordingEnvironmentAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LandlordKnownPublicInstancesBackend(dio: dio);

    final results = await backend.fetchFeaturedInstanceEnvironments(
      landlordOrigin: 'https://belluga.app',
    );

    expect(
      adapter.requestedUrls,
      ['https://guarappari.belluga.app/api/v1/environment'],
    );
    expect(results.single.mainDomain, 'https://guarappari.belluga.app');
  });

  test('uses production custom domain when landlord origin is booraagora.com.br',
      () async {
    final adapter = _RecordingEnvironmentAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LandlordKnownPublicInstancesBackend(dio: dio);

    final results = await backend.fetchFeaturedInstanceEnvironments(
      landlordOrigin: 'https://booraagora.com.br',
    );

    expect(
      adapter.requestedUrls,
      ['https://guarappari.com.br/api/v1/environment'],
    );
    expect(results.single.mainDomain, 'https://guarappari.com.br');
  });
}

class _RecordingEnvironmentAdapter implements HttpClientAdapter {
  final List<String> requestedUrls = <String>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestedUrls.add(options.uri.toString());

    final origin = options.uri.replace(path: '', query: null, fragment: null);
    final payload = <String, Object?>{
      'type': 'tenant',
      'tenant_id': 'tenant-id',
      'name': 'Guarappari',
      'subdomain': 'guarappari',
      'main_domain': origin.toString(),
      'landlord_domain': 'https://belluga.app',
      'domains': <String>[origin.host],
      'app_domains': const <String>['com.guarappari.app'],
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
