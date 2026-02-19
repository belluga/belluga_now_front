import 'dart:convert';
import 'dart:typed_data';

import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_settings_repository.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_base_url_resolver.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(_StubAuthRepo());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('fetchFirebaseSettings parses firebase response', () async {
    final adapter = _RoutingAdapter();
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final settings = await repository.fetchFirebaseSettings();

    expect(settings, isNotNull);
    expect(settings!.projectId, 'project-a');
    expect(adapter.requests.single.path, contains('tenant-a.test/admin/api'));
  });

  test('updatePushSettings sends payload and parses response', () async {
    final adapter = _RoutingAdapter();
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final updated = await repository.updatePushSettings(
      settings: const TenantAdminPushSettings(
        maxTtlDays: 14,
        maxPerMinute: 20,
        maxPerHour: 120,
      ),
    );

    final requestData = adapter.requests.single.data as Map<String, dynamic>;
    expect(requestData['push'], isA<Map<String, dynamic>>());
    expect(updated.maxTtlDays, 14);
    expect(updated.maxPerMinute, 20);
    expect(updated.maxPerHour, 120);
  });

  test('upsertTelemetryIntegration returns snapshot', () async {
    final adapter = _RoutingAdapter();
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final snapshot = await repository.upsertTelemetryIntegration(
      integration: const TenantAdminTelemetryIntegration(
        type: 'mixpanel',
        trackAll: false,
        events: ['app_opened'],
        token: 'token-a',
      ),
    );

    expect(snapshot.integrations, isNotEmpty);
    expect(snapshot.integrations.first.type, 'mixpanel');
    expect(snapshot.availableEvents, contains('app_opened'));
  });

  test('updateBranding sends multipart payload and parses branding data',
      () async {
    final adapter = _RoutingAdapter();
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final updated = await repository.updateBranding(
      input: TenantAdminBrandingUpdateInput(
        tenantName: 'Guarappari',
        brightnessDefault: TenantAdminBrandingBrightness.dark,
        primarySeedColor: '#112233',
        secondarySeedColor: '#445566',
        lightLogoUpload: TenantAdminMediaUpload(
          bytes: Uint8List.fromList(const [1, 2, 3]),
          fileName: 'light_logo.png',
          mimeType: 'image/png',
        ),
      ),
    );

    final requestData = adapter.requests.single.data;
    expect(requestData, isA<FormData>());

    final formData = requestData as FormData;
    expect(
      formData.fields.any((item) =>
          item.key == 'theme_data_settings[brightness_default]' &&
          item.value == 'dark'),
      isTrue,
    );
    expect(
      formData.files.any(
        (entry) => entry.key == 'logo_settings[light_logo_uri]',
      ),
      isTrue,
    );
    expect(updated.brightnessDefault, TenantAdminBrandingBrightness.dark);
    expect(updated.primarySeedColor, '#112233');
    expect(updated.lightLogoUrl, contains('light-logo-updated'));
  });

  test('uses selected tenant scope dynamically between requests', () async {
    final adapter = _RoutingAdapter();
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await repository.fetchFirebaseSettings();
    scope.selectTenantDomain('https://tenant-b.test');
    await repository.fetchTelemetrySettings();

    expect(adapter.requests, hasLength(2));
    expect(adapter.requests[0].uri.host, 'tenant-a.test');
    expect(adapter.requests[1].uri.host, 'tenant-b.test');
  });
}

class _StubAuthRepo implements LandlordAuthRepositoryContract {
  @override
  bool get hasValidSession => true;

  @override
  String get token => 'test-token';

  @override
  Future<void> init() async {}

  @override
  Future<void> loginWithEmailPassword(String email, String password) async {}

  @override
  Future<void> logout() async {}
}

class _MutableTenantScope implements TenantAdminTenantScopeContract {
  _MutableTenantScope(String initialDomain) {
    _selectedTenantDomainStreamValue.addValue(initialDomain);
  }

  final StreamValue<String?> _selectedTenantDomainStreamValue =
      StreamValue<String?>(defaultValue: null);

  @override
  String? get selectedTenantDomain => _selectedTenantDomainStreamValue.value;

  @override
  String get selectedTenantAdminBaseUrl =>
      resolveTenantAdminBaseUrl(selectedTenantDomain ?? '');

  @override
  StreamValue<String?> get selectedTenantDomainStreamValue =>
      _selectedTenantDomainStreamValue;

  @override
  void clearSelectedTenantDomain() {
    _selectedTenantDomainStreamValue.addValue(null);
  }

  @override
  void selectTenantDomain(String tenantDomain) {
    _selectedTenantDomainStreamValue.addValue(tenantDomain.trim());
  }
}

class _RoutingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    requests.add(options);

    final path = options.path;
    final method = options.method.toUpperCase();

    if (path.endsWith('/settings/firebase') && method == 'GET') {
      return _jsonResponse({
        'data': {
          'apiKey': 'api-key-a',
          'appId': 'app-id-a',
          'projectId': 'project-a',
          'messagingSenderId': 'sender-a',
          'storageBucket': 'bucket-a',
        },
      });
    }

    if (path.endsWith('/settings/firebase') && method == 'PATCH') {
      final request = options.data as Map<String, dynamic>;
      return _jsonResponse({'data': request['firebase']});
    }

    if (path.endsWith('/settings/push') && method == 'PATCH') {
      final request = options.data as Map<String, dynamic>;
      return _jsonResponse({'data': request['push']});
    }

    if (path.endsWith('/settings/telemetry') && method == 'GET') {
      return _jsonResponse({
        'data': const [
          {
            'type': 'mixpanel',
            'track_all': false,
            'events': ['app_opened'],
            'token': 'token-a',
          },
        ],
        'available_events': const ['app_opened', 'invite_sent'],
      });
    }

    if (path.endsWith('/settings/telemetry') && method == 'POST') {
      final request = options.data as Map<String, dynamic>;
      return _jsonResponse({
        'data': [request],
        'available_events': const ['app_opened', 'invite_sent'],
      });
    }

    if (path.contains('/settings/telemetry/') && method == 'DELETE') {
      return _jsonResponse({
        'data': const [],
        'available_events': const ['app_opened', 'invite_sent'],
      });
    }

    if (path.endsWith('/branding/update') && method == 'POST') {
      return _jsonResponse({
        'branding_data': {
          'theme_data_settings': {
            'brightness_default': 'dark',
            'primary_seed_color': '#112233',
            'secondary_seed_color': '#445566',
          },
          'logo_settings': {
            'light_logo_uri':
                'https://tenant-a.test/storage/light-logo-updated.png',
            'dark_logo_uri':
                'https://tenant-a.test/storage/dark-logo-updated.png',
            'light_icon_uri':
                'https://tenant-a.test/storage/light-icon-updated.png',
            'dark_icon_uri':
                'https://tenant-a.test/storage/dark-icon-updated.png',
          },
          'pwa_icon': {
            'icon512_uri': 'https://tenant-a.test/storage/pwa-512-updated.png',
          },
        },
      });
    }

    return _jsonResponse(const {});
  }

  ResponseBody _jsonResponse(Map<String, dynamic> payload) {
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}
