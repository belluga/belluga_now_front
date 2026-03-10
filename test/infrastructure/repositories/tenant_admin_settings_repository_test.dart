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

  test('fetchMapUiSettings parses default origin from settings values',
      () async {
    final adapter = _RoutingAdapter();
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final settings = await repository.fetchMapUiSettings();

    expect(settings.defaultOrigin, isNotNull);
    expect(settings.defaultOrigin!.lat, closeTo(-20.6736, 0.000001));
    expect(settings.defaultOrigin!.lng, closeTo(-40.4976, 0.000001));
    expect(settings.defaultOrigin!.label, 'Centro');
    expect(settings.filters, hasLength(1));
    expect(settings.filters.first.key, 'events');
    expect(settings.filters.first.label, 'Eventos');
    expect(
      settings.filters.first.imageUri,
      'https://tenant-a.test/storage/map-filters/events.png',
    );
    final radius = settings.rawMapUi['radius'] as Map<String, dynamic>;
    expect(radius['default_km'], 5);
    expect(adapter.requests.single.uri.path, '/admin/api/v1/settings/values');
  });

  test(
      'fetchMapUiSettings treats empty map_ui namespace payload as empty settings only',
      () async {
    final adapter = _RoutingAdapter(
      settingsValuesPayload: const {
        'data': {
          'map_ui': [],
          'events': [],
          'telemetry': [],
          'push': [],
          'firebase': [],
        },
      },
    );
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final settings = await repository.fetchMapUiSettings();

    expect(settings.defaultOrigin, isNull);
    expect(settings.rawMapUi, isEmpty);
    expect(settings.rawMapUi.containsKey('events'), isFalse);
    expect(settings.rawMapUi.containsKey('telemetry'), isFalse);
    expect(adapter.requests.single.uri.path, '/admin/api/v1/settings/values');
  });

  test('updateMapUiSettings patches map_ui namespace payload', () async {
    final adapter = _RoutingAdapter();
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );
    const mapUi = TenantAdminMapUiSettings(
      rawMapUi: {
        'radius': {
          'min_km': 1,
          'default_km': 5,
          'max_km': 50,
        },
        'default_origin': {
          'lat': -20.611111,
          'lng': -40.422222,
          'label': 'Praia do Morro',
        },
        'filters': [
          {
            'key': 'events',
            'label': 'Eventos',
            'image_uri': 'https://tenant-a.test/storage/map-filters/events.png',
          },
        ],
      },
      defaultOrigin: TenantAdminMapDefaultOrigin(
        lat: -20.611111,
        lng: -40.422222,
        label: 'Praia do Morro',
      ),
      filters: [
        TenantAdminMapFilterCatalogItem(
          key: 'events',
          label: 'Eventos',
          imageUri: 'https://tenant-a.test/storage/map-filters/events.png',
        ),
      ],
    );

    final updated = await repository.updateMapUiSettings(settings: mapUi);

    final request = adapter.requests.single;
    expect(request.uri.path, '/admin/api/v1/settings/values/map_ui');
    final payload = request.data as Map<String, dynamic>;
    expect(payload['radius.default_km'], 5);
    expect(payload['default_origin.lat'], -20.611111);
    expect(payload['default_origin.lng'], -40.422222);
    expect(payload['default_origin.label'], 'Praia do Morro');
    expect(payload['filters'], isA<List<dynamic>>());
    expect(updated.defaultOrigin, isNotNull);
    expect(updated.defaultOrigin!.lat, closeTo(-20.611111, 0.000001));
    expect(updated.defaultOrigin!.lng, closeTo(-40.422222, 0.000001));
    expect(updated.defaultOrigin!.label, 'Praia do Morro');
    expect(updated.filters, hasLength(1));
    expect(updated.filters.first.key, 'events');
    expect(updated.filters.first.label, 'Eventos');
  });

  test(
      'uploadMapFilterImage sends authenticated multipart payload and returns image uri',
      () async {
    final adapter = _RoutingAdapter();
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final imageUri = await repository.uploadMapFilterImage(
      key: 'events',
      upload: TenantAdminMediaUpload(
        bytes: Uint8List.fromList(const [1, 2, 3, 4]),
        fileName: 'events.png',
        mimeType: 'image/png',
      ),
    );

    expect(imageUri, 'https://tenant-a.test/storage/map-filters/events.png');
    final request = adapter.requests.single;
    expect(request.uri.path, '/admin/api/v1/media/map-filter-image');
    expect(request.headers['Authorization'], 'Bearer test-token');
    expect(request.headers['Accept'], 'application/json');
    expect(request.data, isA<FormData>());
    final formData = request.data as FormData;
    expect(
      formData.fields.any(
        (entry) => entry.key == 'key' && entry.value == 'events',
      ),
      isTrue,
    );
    expect(
      formData.files.any((entry) => entry.key == 'image'),
      isTrue,
    );
  });

  test(
      'updateMapUiSettings after empty namespace fetch does not leak sibling namespaces',
      () async {
    final adapter = _RoutingAdapter(
      settingsValuesPayload: const {
        'data': {
          'map_ui': [],
          'events': [],
          'map_ingest': [],
          'map_security': [],
          'telemetry': [],
          'push': [],
          'firebase': [],
        },
      },
    );
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final fetched = await repository.fetchMapUiSettings();
    final updated = await repository.updateMapUiSettings(
      settings: fetched.applyDefaultOrigin(
        const TenantAdminMapDefaultOrigin(
          lat: -20.611111,
          lng: -40.422222,
          label: 'Praia do Morro',
        ),
      ),
    );

    expect(adapter.requests, hasLength(2));
    final request = adapter.requests.last;
    final payload = Map<String, dynamic>.from(request.data as Map);
    expect(
        payload.keys,
        unorderedEquals(const [
          'default_origin.lat',
          'default_origin.lng',
          'default_origin.label',
        ]));
    expect(payload.containsKey('events'), isFalse);
    expect(payload.containsKey('telemetry'), isFalse);
    expect(payload.containsKey('push'), isFalse);
    expect(updated.defaultOrigin, isNotNull);
    expect(updated.defaultOrigin!.lat, closeTo(-20.611111, 0.000001));
    expect(updated.defaultOrigin!.lng, closeTo(-40.422222, 0.000001));
    expect(updated.defaultOrigin!.label, 'Praia do Morro');
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

  test(
      'updateBranding sends multipart payload and reloads branding from tenant',
      () async {
    final adapter = _RoutingAdapter(
      environmentPayload: const {
        'type': 'tenant',
        'tenant_id': 'tenant-a',
        'name': 'Guarappari',
        'theme_data_settings': {
          'brightness_default': 'dark',
          'primary_seed_color': '#112233',
          'secondary_seed_color': '#445566',
        },
        'logo_settings': {
          'pwa_icon': {
            'icon512_uri': 'https://tenant-a.test/storage/pwa-icon.png',
          },
        },
      },
    );
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

    expect(adapter.requests, hasLength(2));
    final postRequest = adapter.requests.first;
    final environmentRequest = adapter.requests.last;

    expect(postRequest.path, contains('/branding/update'));
    expect(environmentRequest.uri.path, '/api/v1/environment');

    final requestData = postRequest.data;
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
    expect(updated.secondarySeedColor, '#445566');
    expect(updated.lightLogoUrl, contains('tenant-a.test/logo-light.png'));
    expect(updated.pwaIconUrl, 'https://tenant-a.test/storage/pwa-icon.png');
    expect(
      repository.brandingSettingsStreamValue.value?.primarySeedColor,
      '#112233',
    );
  });

  test(
      'updateBranding succeeds when refresh fails after POST and returns optimistic settings',
      () async {
    final adapter = _RoutingAdapter(
      environmentPayload: const {
        'type': 'landlord',
      },
    );
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

    expect(adapter.requests, hasLength(2));
    expect(updated.tenantName, 'Guarappari');
    expect(updated.brightnessDefault, TenantAdminBrandingBrightness.dark);
    expect(updated.primarySeedColor, '#112233');
    expect(updated.secondarySeedColor, '#445566');
    expect(updated.lightLogoUrl, contains('tenant-a.test/logo-light.png'));
    expect(
      repository.brandingSettingsStreamValue.value?.tenantName,
      'Guarappari',
    );
    expect(
      repository.brandingSettingsStreamValue.value?.primarySeedColor,
      '#112233',
    );
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

  test(
      'fetchBrandingSettings uses tenant-admin resolved origin for environment endpoint',
      () async {
    final adapter = _RoutingAdapter();
    final scope = _FixedTenantScopeForOriginRead(
      selectedTenantDomainValue: 'tenant-a.test',
      selectedTenantAdminBaseUrlValue: 'http://tenant-a.test:8081/admin/api',
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final branding = await repository.fetchBrandingSettings();
    final request = adapter.requests.single;

    expect(request.uri.scheme, 'http');
    expect(request.uri.host, 'tenant-a.test');
    expect(request.uri.port, 8081);
    expect(request.uri.path, '/api/v1/environment');
    expect(request.uri.queryParameters['_ts'], isNotNull);
    expect(request.headers['Authorization'], isNull);
    expect(request.headers['Accept'], 'application/json');
    expect(branding.primarySeedColor, '#A36CE3');
    expect(branding.secondarySeedColor, '#03DAC6');
    expect(
      repository.brandingSettingsStreamValue.value?.secondarySeedColor,
      '#03DAC6',
    );
  });

  test('fetchBrandingSettings maps pwa icon URL from environment payload',
      () async {
    final adapter = _RoutingAdapter(
      environmentPayload: const {
        'type': 'tenant',
        'tenant_id': 'tenant-a',
        'name': 'Guarappari Admin',
        'theme_data_settings': {
          'brightness_default': 'light',
          'primary_seed_color': '#a36ce3',
          'secondary_seed_color': '#03dac6',
        },
        'logo_settings': {
          'pwa_icon': {
            'icon512_uri': '/storage/pwa-icon-512.png',
          },
        },
      },
    );
    final scope = _FixedTenantScopeForOriginRead(
      selectedTenantDomainValue: 'tenant-a.test',
      selectedTenantAdminBaseUrlValue: 'http://tenant-a.test:8081/admin/api',
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final branding = await repository.fetchBrandingSettings();

    expect(
      branding.pwaIconUrl,
      'http://tenant-a.test:8081/storage/pwa-icon-512.png',
    );
    expect(
      repository.brandingSettingsStreamValue.value?.pwaIconUrl,
      'http://tenant-a.test:8081/storage/pwa-icon-512.png',
    );
  });

  test(
      'fetchBrandingSettings ignores stale response from previous tenant scope',
      () async {
    final adapter = _RoutingAdapter(
      environmentPayloadByHost: const {
        'tenant-a.test': {
          'type': 'tenant',
          'tenant_id': 'tenant-a',
          'name': 'Tenant A',
          'theme_data_settings': {
            'brightness_default': 'light',
            'primary_seed_color': '#111111',
            'secondary_seed_color': '#222222',
          },
        },
        'tenant-b.test': {
          'type': 'tenant',
          'tenant_id': 'tenant-b',
          'name': 'Tenant B',
          'theme_data_settings': {
            'brightness_default': 'dark',
            'primary_seed_color': '#333333',
            'secondary_seed_color': '#444444',
          },
        },
      },
      environmentDelayByHost: const {
        'tenant-a.test': Duration(milliseconds: 80),
        'tenant-b.test': Duration(milliseconds: 5),
      },
    );
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final staleFetch = repository.fetchBrandingSettings();
    scope.selectTenantDomain('https://tenant-b.test');
    final currentFetch = repository.fetchBrandingSettings();

    final current = await currentFetch;
    final stale = await staleFetch;

    expect(current.tenantName, 'Tenant B');
    expect(stale.tenantName, 'Tenant A');
    expect(
        repository.brandingSettingsStreamValue.value?.tenantName, 'Tenant B');
  });

  test('clearBrandingSettings clears repository canonical branding stream',
      () async {
    final adapter = _RoutingAdapter();
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await repository.fetchBrandingSettings();
    expect(repository.brandingSettingsStreamValue.value, isNotNull);

    repository.clearBrandingSettings();
    expect(repository.brandingSettingsStreamValue.value, isNull);
  });

  test('fetchBrandingSettings fails when tenant scope is missing (no fallback)',
      () async {
    final adapter = _RoutingAdapter();
    final scope = _NoTenantScope();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await expectLater(
      repository.fetchBrandingSettings(),
      throwsA(isA<StateError>()),
    );
    expect(adapter.requests, isEmpty);
  });

  test('fetchBrandingSettings fails for non-tenant environment payload',
      () async {
    final adapter = _RoutingAdapter(
      environmentPayload: const {
        'type': 'landlord',
        'name': 'Belluga',
        'theme_data_settings': {
          'brightness_default': 'light',
          'primary_seed_color': '#a36ce3',
          'secondary_seed_color': '#03dac6',
        },
      },
    );
    final scope = _FixedTenantScopeForOriginRead(
      selectedTenantDomainValue: 'tenant-a.test',
      selectedTenantAdminBaseUrlValue: 'http://tenant-a.test:8081/admin/api',
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await expectLater(
      repository.fetchBrandingSettings(),
      throwsA(isA<Exception>()),
    );
  });

  test('fetchBrandingSettings fails when theme settings are missing', () async {
    final adapter = _RoutingAdapter(
      environmentPayload: const {
        'type': 'tenant',
        'name': 'Guarappari Admin',
      },
    );
    final scope = _FixedTenantScopeForOriginRead(
      selectedTenantDomainValue: 'tenant-a.test',
      selectedTenantAdminBaseUrlValue: 'http://tenant-a.test:8081/admin/api',
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await expectLater(
      repository.fetchBrandingSettings(),
      throwsA(isA<Exception>()),
    );
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

class _FixedTenantScopeForOriginRead implements TenantAdminTenantScopeContract {
  _FixedTenantScopeForOriginRead({
    required this.selectedTenantDomainValue,
    required this.selectedTenantAdminBaseUrlValue,
  }) {
    _selectedTenantDomainStreamValue.addValue(selectedTenantDomainValue);
  }

  final String selectedTenantDomainValue;
  final String selectedTenantAdminBaseUrlValue;
  final StreamValue<String?> _selectedTenantDomainStreamValue =
      StreamValue<String?>(defaultValue: null);

  @override
  String? get selectedTenantDomain => selectedTenantDomainValue;

  @override
  String get selectedTenantAdminBaseUrl => selectedTenantAdminBaseUrlValue;

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

class _NoTenantScope implements TenantAdminTenantScopeContract {
  final StreamValue<String?> _selectedTenantDomainStreamValue =
      StreamValue<String?>(defaultValue: null);

  @override
  String? get selectedTenantDomain => null;

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
  _RoutingAdapter({
    this.environmentPayload,
    this.environmentPayloadByHost,
    this.environmentDelayByHost,
    this.settingsValuesPayload,
  });

  final Map<String, dynamic>? environmentPayload;
  final Map<String, Map<String, dynamic>>? environmentPayloadByHost;
  final Map<String, Duration>? environmentDelayByHost;
  final Map<String, dynamic>? settingsValuesPayload;
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

    if (path.endsWith('/settings/values') && method == 'GET') {
      return _jsonResponse(
        settingsValuesPayload ??
            {
              'data': {
                'map_ui': {
                  'radius': {
                    'min_km': 1,
                    'default_km': 5,
                    'max_km': 50,
                  },
                  'poi_time_window_days': {
                    'past': 1,
                    'future': 30,
                  },
                  'default_origin': {
                    'lat': -20.6736,
                    'lng': -40.4976,
                    'label': 'Centro',
                  },
                  'filters': [
                    {
                      'key': 'events',
                      'label': 'Eventos',
                      'image_uri':
                          'https://tenant-a.test/storage/map-filters/events.png',
                    },
                  ],
                },
              },
            },
      );
    }

    if (path.endsWith('/settings/values/map_ui') && method == 'PATCH') {
      final request = Map<String, dynamic>.from(options.data as Map);
      return _jsonResponse({
        'data': {
          'map_ui': _expandDotPayload(request),
        },
      });
    }

    if (path.endsWith('/media/map-filter-image') && method == 'POST') {
      final requestData = options.data;
      String key = '';
      if (requestData is FormData) {
        for (final field in requestData.fields) {
          if (field.key == 'key') {
            key = field.value.trim();
            break;
          }
        }
      }
      final normalizedKey = key.isEmpty ? 'uploaded-filter' : key;
      return _jsonResponse({
        'data': {
          'image_uri':
              'https://tenant-a.test/storage/map-filters/$normalizedKey.png',
        },
      });
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

    if (options.uri.path == '/api/v1/environment' && method == 'GET') {
      final host = options.uri.host.trim().toLowerCase();
      final delay = environmentDelayByHost?[host];
      if (delay != null && delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
      return _jsonResponse(
        environmentPayloadByHost?[host] ??
            environmentPayload ??
            {
              'type': 'tenant',
              'tenant_id': 'tenant-a',
              'name': 'Guarappari Admin',
              'theme_data_settings': {
                'brightness_default': 'light',
                'primary_seed_color': '#a36ce3',
                'secondary_seed_color': '#03dac6',
              },
            },
      );
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

  Map<String, dynamic> _expandDotPayload(Map<String, dynamic> source) {
    final expanded = <String, dynamic>{};
    source.forEach((rawPath, value) {
      if (rawPath.trim().isEmpty) {
        return;
      }
      final segments = rawPath.split('.');
      Map<String, dynamic> cursor = expanded;
      for (var index = 0; index < segments.length; index++) {
        final key = segments[index].trim();
        if (key.isEmpty) {
          continue;
        }
        if (index == segments.length - 1) {
          cursor[key] = value;
          continue;
        }
        final next = cursor[key];
        if (next is Map<String, dynamic>) {
          cursor = next;
          continue;
        }
        final created = <String, dynamic>{};
        cursor[key] = created;
        cursor = created;
      }
    });
    return expanded;
  }
}
