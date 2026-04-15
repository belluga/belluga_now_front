import 'dart:convert';
import 'dart:typed_data';
import 'package:belluga_now/testing/tenant_admin_app_links_settings_builder.dart';

import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_boolean_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_hex_color_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_positive_int_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_settings_repository.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_base_url_resolver.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:value_object_pattern/domain/value_objects/email_address_value.dart';

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

  test('fetchResendEmailSettings parses resend_email namespace payload',
      () async {
    final adapter = _RoutingAdapter();
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final settings = await repository.fetchResendEmailSettings();

    expect(settings.token, 're_live_token');
    expect(settings.from, 'Belluga <noreply@belluga.space>');
    expect(
      _recipientStrings(settings.to),
      equals(['admin@bellugasolutions.com.br']),
    );
    expect(
      _recipientStrings(settings.cc),
      equals(['ops@bellugasolutions.com.br']),
    );
    expect(
      _recipientStrings(settings.bcc),
      equals(['audit@bellugasolutions.com.br']),
    );
    expect(
      _recipientStrings(settings.replyTo),
      equals(['reply@bellugasolutions.com.br']),
    );
    expect(adapter.requests.single.uri.path, '/admin/api/v1/settings/values');
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
      settings: TenantAdminPushSettings(
        maxTtlDaysValue: _positiveIntValue(14),
        maxPerMinuteValue: _positiveIntValue(20),
        maxPerHourValue: _positiveIntValue(120),
      ),
    );

    final requestData = adapter.requests.single.data as Map<String, dynamic>;
    expect(requestData['push'], isA<Map<String, dynamic>>());
    expect(updated.maxTtlDays, 14);
    expect(updated.maxPerMinute, 20);
    expect(updated.maxPerHour, 120);
  });

  test('updateResendEmailSettings patches resend_email namespace payload',
      () async {
    final adapter = _RoutingAdapter();
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final updated = await repository.updateResendEmailSettings(
      settings: TenantAdminResendEmailSettings(
        token: _optionalTextValue('re_live_token'),
        from: _optionalTextValue('Belluga <noreply@belluga.space>'),
        toRecipients: _recipients(['admin@bellugasolutions.com.br']),
        ccRecipients: _recipients(['ops@bellugasolutions.com.br']),
        bccRecipients: _recipients(['audit@bellugasolutions.com.br']),
        replyToRecipients: _recipients(['reply@bellugasolutions.com.br']),
      ),
    );

    final request = adapter.requests.single;
    expect(request.uri.path, '/admin/api/v1/settings/values/resend_email');
    final payload = request.data as Map<String, dynamic>;
    expect(payload['token'], 're_live_token');
    expect(payload['from'], 'Belluga <noreply@belluga.space>');
    expect(
      payload['to'],
      equals(['admin@bellugasolutions.com.br']),
    );
    expect(
      payload['cc'],
      equals(['ops@bellugasolutions.com.br']),
    );
    expect(
      payload['bcc'],
      equals(['audit@bellugasolutions.com.br']),
    );
    expect(
      payload['reply_to'],
      equals(['reply@bellugasolutions.com.br']),
    );
    expect(updated.from, 'Belluga <noreply@belluga.space>');
    expect(
      _recipientStrings(updated.to),
      equals(['admin@bellugasolutions.com.br']),
    );
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
      'https://tenant-a.test/api/v1/media/map-filters/events?v=1710000000',
    );
    expect(
      settings.filters.first.query.source,
      TenantAdminMapFilterSource.event,
    );
    expect(
      settings.filters.first.query.types.map((entry) => entry.value).toList(),
      equals(['show']),
    );
    expect(
      settings.filters.first.query.taxonomy
          .map((entry) => entry.value)
          .toList(),
      equals(['music_genre:rock']),
    );
    final radius = settings.rawMapUi['radius'] as Map<String, dynamic>;
    expect(radius['default_km'], 5);
    expect(adapter.requests.single.uri.path, '/admin/api/v1/settings/values');
  });

  test(
      'fetchMapUiSettings treats empty map_ui namespace payload as empty settings only',
      () async {
    final adapter = _RoutingAdapter(
      settingsValuesPayload: {
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

  test('fetchAppLinksSettings parses app_links namespace payload', () async {
    final adapter = _RoutingAdapter();
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final settings = await repository.fetchAppLinksSettings();

    expect(settings.androidAppIdentifier, 'com.guarappari.app');
    expect(
      settings.androidSha256CertFingerprints,
      equals(
        [
          '3E:72:4C:54:E9:53:26:7D:E6:E1:9B:F8:DC:53:30:2A:08:01:8E:36:40:AA:23:11:22:33:44:55:66:77:88:99',
        ],
      ),
    );
    expect(settings.iosTeamId, 'TEAMID1234');
    expect(settings.iosBundleId, 'com.guarappari.app');
    expect(settings.iosPaths, equals(['/invite*', '/convites*']));
    expect(adapter.requests, hasLength(2));
    expect(adapter.requests.first.uri.path, '/admin/api/v1/settings/values');
    expect(adapter.requests.last.uri.path, '/admin/api/v1/appdomains');
  });

  test('fetchDomainsPage requests page/per_page and decodes active domains',
      () async {
    final adapter = _RoutingAdapter(
      domainsPayload: [
        {
          'id': 'domain-1',
          'path': 'tenant-a.test',
          'type': 'web',
          'status': 'active',
          'created_at': '2026-04-01T10:00:00Z',
          'updated_at': '2026-04-01T10:00:00Z',
          'deleted_at': null,
        },
        {
          'id': 'domain-2',
          'path': 'tenant-b.test',
          'type': 'web',
          'status': 'active',
          'created_at': '2026-03-01T10:00:00Z',
          'updated_at': '2026-03-01T10:00:00Z',
          'deleted_at': null,
        },
      ],
    );
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final result = await repository.fetchDomainsPage(
      page: TenantAdminCountValue(1),
      pageSize: TenantAdminCountValue(1),
    );

    expect(adapter.requests.single.uri.path, '/admin/api/v1/domains');
    expect(adapter.requests.single.uri.queryParameters['page'], '1');
    expect(adapter.requests.single.uri.queryParameters['per_page'], '1');
    expect(result.items, hasLength(1));
    expect(result.items.single.path, 'tenant-a.test');
    expect(result.items.single.status, TenantAdminDomainStatusValue.active);
    expect(result.hasMore, isTrue);
  });

  test('createDomain posts payload and decodes created entry', () async {
    final adapter = _RoutingAdapter();
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final created = await repository.createDomain(
      path: _requiredTextValue('new-tenant.test'),
    );

    expect(adapter.requests.single.uri.path, '/admin/api/v1/domains');
    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.data, {'path': 'new-tenant.test'});
    expect(created.path, 'new-tenant.test');
    expect(created.status, TenantAdminDomainStatusValue.active);
  });

  test('createDomain preserves backend validation message for duplicates',
      () async {
    final adapter = _RoutingAdapter(
      createDomainValidationMessage: 'Another tenant already uses this domain.',
    );
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await expectLater(
      () => repository.createDomain(
        path: _requiredTextValue('duplicate-tenant.test'),
      ),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Another tenant already uses this domain.'),
        ),
      ),
    );
  });

  test('deleteDomain hits expected endpoint', () async {
    final adapter = _RoutingAdapter();
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await repository.deleteDomain(_requiredTextValue('domain-1'));

    expect(adapter.requests.single.method, 'DELETE');
    expect(adapter.requests.single.uri.path, '/admin/api/v1/domains/domain-1');
  });

  test('updateMapUiSettings patches map_ui namespace payload', () async {
    final adapter = _RoutingAdapter();
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );
    final mapUi = TenantAdminMapUiSettings(
      rawMapUiValue: TenantAdminDynamicMapValue({
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
            'image_uri':
                'https://tenant-a.test/map-filters/events/image?v=1710000000',
            'query': {
              'source': 'event',
              'types': ['show'],
              'taxonomy': ['music_genre:rock'],
            },
          },
        ],
      }),
      defaultOrigin: TenantAdminMapDefaultOrigin(
        lat: _latitudeValue(-20.611111),
        lng: _longitudeValue(-40.422222),
        label: _optionalTextValue('Praia do Morro'),
      ),
      filters: _mapFilterCatalogItems([
        TenantAdminMapFilterCatalogItem(
          keyValue: TenantAdminLowercaseTokenValue()..parse('events'),
          labelValue: TenantAdminRequiredTextValue()..parse('Eventos'),
          imageUriValue: TenantAdminOptionalUrlValue()
            ..parse(
                'https://tenant-a.test/map-filters/events/image?v=1710000000'),
          query: TenantAdminMapFilterQuery(
            source: TenantAdminMapFilterSource.event,
            typeValues: [_tokenValue('show')],
            taxonomyValues: [_tokenValue('music_genre:rock')],
          ),
        ),
      ]),
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
    final filtersPayload = payload['filters'] as List<dynamic>;
    expect(filtersPayload, hasLength(1));
    final firstFilterPayload =
        Map<String, dynamic>.from(filtersPayload.first as Map);
    final queryPayload = Map<String, dynamic>.from(
      firstFilterPayload['query'] as Map,
    );
    expect(queryPayload['source'], 'event');
    expect(queryPayload['types'], equals(['show']));
    expect(queryPayload['taxonomy'], equals(['music_genre:rock']));
    expect(updated.defaultOrigin, isNotNull);
    expect(updated.defaultOrigin!.lat, closeTo(-20.611111, 0.000001));
    expect(updated.defaultOrigin!.lng, closeTo(-40.422222, 0.000001));
    expect(updated.defaultOrigin!.label, 'Praia do Morro');
    expect(updated.filters, hasLength(1));
    expect(updated.filters.first.key, 'events');
    expect(updated.filters.first.label, 'Eventos');
    expect(
      updated.filters.first.imageUri,
      'https://tenant-a.test/api/v1/media/map-filters/events?v=1710000000',
    );
    expect(
        updated.filters.first.query.source, TenantAdminMapFilterSource.event);
    expect(
      updated.filters.first.query.types.map((entry) => entry.value).toList(),
      equals(['show']),
    );
    expect(
      updated.filters.first.query.taxonomy.map((entry) => entry.value).toList(),
      equals(['music_genre:rock']),
    );
  });

  test('updateAppLinksSettings patches app_links namespace payload', () async {
    final adapter = _RoutingAdapter();
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );
    final appLinks = buildTenantAdminAppLinksSettings(
      rawAppLinks: {
        'android': {
          'sha256_cert_fingerprints': [
            '3E:72:4C:54:E9:53:26:7D:E6:E1:9B:F8:DC:53:30:2A:08:01:8E:36:40:AA:23:11:22:33:44:55:66:77:88:99',
          ],
        },
        'ios': {
          'team_id': 'TEAMID1234',
          'paths': ['/invite*', '/convites*'],
        },
      },
      androidAppIdentifier: 'com.guarappari.app',
      androidSha256CertFingerprints: [
        '3E:72:4C:54:E9:53:26:7D:E6:E1:9B:F8:DC:53:30:2A:08:01:8E:36:40:AA:23:11:22:33:44:55:66:77:88:99',
      ],
      iosTeamId: 'TEAMID1234',
      iosBundleId: 'com.guarappari.app',
      iosPaths: ['/invite*', '/convites*'],
    );

    final updated = await repository.updateAppLinksSettings(settings: appLinks);

    expect(adapter.requests, hasLength(4));
    expect(adapter.requests.first.uri.path, '/admin/api/v1/appdomains');
    expect(adapter.requests[1].uri.path, '/admin/api/v1/appdomains');
    expect(adapter.requests[1].method.toUpperCase(), 'POST');
    expect(adapter.requests[2].uri.path, '/admin/api/v1/appdomains');
    expect(adapter.requests[2].method.toUpperCase(), 'POST');
    final request = adapter.requests.last;
    expect(request.uri.path, '/admin/api/v1/settings/values/app_links');
    final payload = request.data as Map<String, dynamic>;
    expect(payload['android.sha256_cert_fingerprints'], isA<List<dynamic>>());
    expect(payload['ios.team_id'], 'TEAMID1234');
    expect(payload['ios.paths'], equals(['/invite*', '/convites*']));
    expect(updated.androidAppIdentifier, 'com.guarappari.app');
    expect(updated.iosTeamId, 'TEAMID1234');
    expect(updated.iosBundleId, 'com.guarappari.app');
    expect(updated.iosPaths, equals(['/invite*', '/convites*']));
  });

  test('updateAppLinksSettings upserts typed identifiers before patch',
      () async {
    final adapter = _RoutingAdapter(
      appDomainsPayload: {
        'android': 'com.old.app',
        'ios': null,
      },
    );
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );
    final appLinks = buildTenantAdminAppLinksSettings(
      rawAppLinks: {
        'android': {
          'sha256_cert_fingerprints': [
            '3E:72:4C:54:E9:53:26:7D:E6:E1:9B:F8:DC:53:30:2A:08:01:8E:36:40:4D:0C:CA:98:3B:46:84:53:E7:A9:A9',
          ],
        },
        'ios': {
          'team_id': 'ABCDE12345',
          'paths': ['/invite*', '/convites*'],
        },
      },
      androidAppIdentifier: 'com.guarappari.app',
      androidSha256CertFingerprints: [
        '3E:72:4C:54:E9:53:26:7D:E6:E1:9B:F8:DC:53:30:2A:08:01:8E:36:40:4D:0C:CA:98:3B:46:84:53:E7:A9:A9',
      ],
      iosTeamId: 'ABCDE12345',
      iosBundleId: 'com.guarappari.app',
      iosPaths: ['/invite*', '/convites*'],
    );

    final updated = await repository.updateAppLinksSettings(settings: appLinks);

    expect(adapter.requests, hasLength(4));
    expect(adapter.requests[0].uri.path, '/admin/api/v1/appdomains');
    expect(adapter.requests[1].uri.path, '/admin/api/v1/appdomains');
    expect(adapter.requests[2].uri.path, '/admin/api/v1/appdomains');
    expect(adapter.requests[3].uri.path,
        '/admin/api/v1/settings/values/app_links');
    expect(updated.androidAppIdentifier, 'com.guarappari.app');
    expect(updated.iosBundleId, 'com.guarappari.app');
  });

  test(
      'updateAppLinksSettings upserts Android typed identifier even when GET appdomains matches legacy fallback',
      () async {
    final adapter = _RoutingAdapter(
      appDomainsPayload: {
        'android': 'com.guarappari.app',
        'ios': null,
      },
      typedAppDomainPersistedByPlatform: {
        'android': false,
        'ios': false,
      },
    );
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );
    final appLinks = buildTenantAdminAppLinksSettings(
      rawAppLinks: {
        'android': {
          'sha256_cert_fingerprints': [
            'ED:07:87:5E:89:8A:4B:26:41:5B:C7:A9:19:44:84:D3:0A:A4:AD:52:BA:66:47:56:8F:62:EF:71:F0:FD:1A:54',
          ],
        },
        'ios': {
          'team_id': null,
          'paths': ['/invite*', '/convites*'],
        },
      },
      androidAppIdentifier: 'com.guarappari.app',
      androidSha256CertFingerprints: [
        'ED:07:87:5E:89:8A:4B:26:41:5B:C7:A9:19:44:84:D3:0A:A4:AD:52:BA:66:47:56:8F:62:EF:71:F0:FD:1A:54',
      ],
      iosTeamId: null,
      iosBundleId: null,
      iosPaths: ['/invite*', '/convites*'],
    );

    final updated = await repository.updateAppLinksSettings(settings: appLinks);

    expect(adapter.requests, hasLength(3));
    expect(adapter.requests[0].method.toUpperCase(), 'GET');
    expect(adapter.requests[0].uri.path, '/admin/api/v1/appdomains');
    expect(adapter.requests[1].method.toUpperCase(), 'POST');
    expect(adapter.requests[1].uri.path, '/admin/api/v1/appdomains');
    expect(adapter.requests[2].method.toUpperCase(), 'PATCH');
    expect(
      adapter.requests[2].uri.path,
      '/admin/api/v1/settings/values/app_links',
    );
    expect(updated.androidAppIdentifier, 'com.guarappari.app');
    expect(
      updated.androidSha256CertFingerprints,
      equals([
        'ED:07:87:5E:89:8A:4B:26:41:5B:C7:A9:19:44:84:D3:0A:A4:AD:52:BA:66:47:56:8F:62:EF:71:F0:FD:1A:54',
      ]),
    );
  });

  test('updateAppLinksSettings removes typed identifiers when cleared',
      () async {
    final adapter = _RoutingAdapter(
      appDomainsPayload: {
        'android': 'com.guarappari.app',
        'ios': 'com.guarappari.app',
      },
    );
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );
    final appLinks = buildTenantAdminAppLinksSettings(
      rawAppLinks: {
        'android': {
          'sha256_cert_fingerprints': [],
        },
        'ios': {
          'team_id': null,
          'paths': ['/invite*'],
        },
      },
      androidAppIdentifier: null,
      androidSha256CertFingerprints: [],
      iosTeamId: null,
      iosBundleId: null,
      iosPaths: ['/invite*'],
    );

    final updated = await repository.updateAppLinksSettings(settings: appLinks);

    expect(adapter.requests, hasLength(4));
    expect(adapter.requests[0].uri.path, '/admin/api/v1/appdomains');
    expect(adapter.requests[1].uri.path, '/admin/api/v1/appdomains');
    expect(adapter.requests[1].method.toUpperCase(), 'DELETE');
    expect(adapter.requests[2].uri.path, '/admin/api/v1/appdomains');
    expect(adapter.requests[2].method.toUpperCase(), 'DELETE');
    expect(adapter.requests[3].uri.path,
        '/admin/api/v1/settings/values/app_links');
    expect(updated.androidAppIdentifier, isNull);
    expect(updated.iosBundleId, isNull);
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
      key: _tokenValue('events'),
      upload: tenantAdminMediaUploadFromRaw(
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        fileName: 'events.png',
        mimeType: 'image/png',
      ),
    );

    expect(imageUri,
        'https://tenant-a.test/api/v1/media/map-filters/events?v=1710000000');
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
      settingsValuesPayload: {
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
        TenantAdminMapDefaultOrigin(
          lat: _latitudeValue(-20.611111),
          lng: _longitudeValue(-40.422222),
          label: _optionalTextValue('Praia do Morro'),
        ),
      ),
    );

    expect(adapter.requests, hasLength(2));
    final request = adapter.requests.last;
    final payload = Map<String, dynamic>.from(request.data as Map);
    expect(
        payload.keys,
        unorderedEquals([
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
      integration: TenantAdminTelemetryIntegration(
        type: _tokenValue('mixpanel'),
        trackAll: _booleanValue(false),
        eventValues: [_tokenValue('app_opened')],
        token: _optionalTextValue('token-a'),
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
      environmentPayload: {
        'type': 'tenant',
        'tenant_id': 'tenant-a',
        'name': 'Guarappari',
        'theme_data_settings': {
          'brightness_default': 'dark',
          'primary_seed_color': '#112233',
          'secondary_seed_color': '#445566',
        },
        'branding_assets': {
          'favicon': {
            'has_dedicated_asset': true,
            'uses_pwa_fallback': false,
          },
        },
        'public_web_metadata': {
          'default_title': 'Guarappari Home',
          'default_description': 'Fallback institucional da home.',
          'default_image': 'https://tenant-a.test/storage/public-web-updated.jpg',
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
        tenantName: _requiredTextValue('Guarappari'),
        brightnessDefault: TenantAdminBrandingBrightness.dark,
        primarySeedColor: _hexColorValue('#112233'),
        secondarySeedColor: _hexColorValue('#445566'),
        lightLogoUpload: tenantAdminMediaUploadFromRaw(
          bytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'light_logo.png',
          mimeType: 'image/png',
        ),
        faviconUpload: tenantAdminMediaUploadFromRaw(
          bytes: Uint8List.fromList([0, 0, 1, 0, 1, 0, 16, 16]),
          fileName: 'favicon.ico',
          mimeType: 'image/x-icon',
        ),
        publicWebDefaultTitle: _optionalTextValue('Guarappari Home'),
        publicWebDefaultDescription:
            _optionalTextValue('Fallback institucional da home.'),
        publicWebDefaultImageUpload: tenantAdminMediaUploadFromRaw(
          bytes: Uint8List.fromList([1, 2, 3, 4]),
          fileName: 'public_web.jpg',
          mimeType: 'image/jpeg',
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
      formData.fields.any(
        (item) => item.key == 'name' && item.value == 'Guarappari',
      ),
      isTrue,
    );
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
    expect(
      formData.files.any(
        (entry) => entry.key == 'logo_settings[favicon_uri]',
      ),
      isTrue,
    );
    expect(
      formData.fields.any(
        (item) =>
            item.key == 'public_web_metadata[default_title]' &&
            item.value == 'Guarappari Home',
      ),
      isTrue,
    );
    expect(
      formData.fields.any(
        (item) =>
            item.key == 'public_web_metadata[default_description]' &&
            item.value == 'Fallback institucional da home.',
      ),
      isTrue,
    );
    expect(
      formData.files.any(
        (entry) => entry.key == 'public_web_metadata[default_image]',
      ),
      isTrue,
    );
    expect(updated.brightnessDefault, TenantAdminBrandingBrightness.dark);
    expect(updated.primarySeedColor, '#112233');
    expect(updated.secondarySeedColor, '#445566');
    expect(updated.publicWebDefaultTitle, 'Guarappari Home');
    expect(updated.publicWebDefaultDescription, 'Fallback institucional da home.');
    expect(
      updated.publicWebDefaultImageUrl,
      'https://tenant-a.test/storage/public-web-updated.jpg',
    );
    expect(updated.lightLogoUrl, contains('tenant-a.test/logo-light.png'));
    expect(updated.faviconUrl, contains('tenant-a.test/favicon.ico'));
    expect(updated.pwaIconUrl, 'https://tenant-a.test/storage/pwa-icon.png');
    expect(updated.hasDedicatedFavicon, isTrue);
    expect(updated.usesPwaFaviconFallback, isFalse);
    expect(
      repository.brandingSettingsStreamValue.value?.primarySeedColor,
      '#112233',
    );
  });

  test(
      'updateBranding fails when refresh fails after POST (no optimistic fallback)',
      () async {
    final adapter = _RoutingAdapter(
      environmentPayload: {
        'type': 'landlord',
      },
    );
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await expectLater(
      repository.updateBranding(
        input: TenantAdminBrandingUpdateInput(
          tenantName: _requiredTextValue('Guarappari'),
          brightnessDefault: TenantAdminBrandingBrightness.dark,
          primarySeedColor: _hexColorValue('#112233'),
          secondarySeedColor: _hexColorValue('#445566'),
          lightLogoUpload: tenantAdminMediaUploadFromRaw(
            bytes: Uint8List.fromList([1, 2, 3]),
            fileName: 'light_logo.png',
            mimeType: 'image/png',
          ),
          faviconUpload: tenantAdminMediaUploadFromRaw(
            bytes: Uint8List.fromList([0, 0, 1, 0, 1, 0, 16, 16]),
            fileName: 'favicon.ico',
            mimeType: 'image/x-icon',
          ),
          pwaIconUpload: tenantAdminMediaUploadFromRaw(
            bytes: Uint8List.fromList([4, 5, 6]),
            fileName: 'pwa_icon.png',
            mimeType: 'image/png',
          ),
        ),
      ),
      throwsA(isA<Exception>()),
    );

    expect(adapter.requests, hasLength(2));
    expect(repository.brandingSettingsStreamValue.value, isNull);
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

  test('fetchTelemetrySettings uses tenant admin telemetry endpoint', () async {
    final adapter = _RoutingAdapter();
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final snapshot = await repository.fetchTelemetrySettings();

    expect(snapshot.integrations, hasLength(1));
    expect(snapshot.integrations.single.type, 'mixpanel');
    expect(snapshot.integrations.single.token, 'token-a');
    expect(
        adapter.requests.single.uri.path, '/admin/api/v1/settings/telemetry');
  });

  test(
      'upsertTelemetryIntegration posts telemetry payload to tenant admin endpoint',
      () async {
    final adapter = _RoutingAdapter();
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final snapshot = await repository.upsertTelemetryIntegration(
      integration: TenantAdminTelemetryIntegration(
        type: _tokenValue('mixpanel'),
        trackAll: TenantAdminBooleanValue(defaultValue: false)..parse('false'),
        eventValues: [_tokenValue('app_opened')],
        token: TenantAdminOptionalTextValue()..parse('tenant-token'),
      ),
    );

    expect(snapshot.integrations, hasLength(1));
    expect(snapshot.integrations.single.type, 'mixpanel');
    expect(snapshot.integrations.single.token, 'tenant-token');
    expect(
        adapter.requests.single.uri.path, '/admin/api/v1/settings/telemetry');
    expect(adapter.requests.single.data, isA<Map<String, dynamic>>());
    final payload = Map<String, dynamic>.from(
      adapter.requests.single.data as Map<String, dynamic>,
    );
    expect(payload['type'], 'mixpanel');
    expect(payload['events'], equals(['app_opened']));
    expect(payload['token'], 'tenant-token');
    expect(payload.containsKey('url'), isFalse);
  });

  test('deleteTelemetryIntegration deletes by type at tenant admin endpoint',
      () async {
    final adapter = _RoutingAdapter();
    final scope = _MutableTenantScope('https://tenant-a.test');
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminSettingsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final snapshot = await repository.deleteTelemetryIntegration(
      type: _tokenValue('mixpanel'),
    );

    expect(snapshot.integrations, isEmpty);
    expect(
      adapter.requests.single.uri.path,
      '/admin/api/v1/settings/telemetry/mixpanel',
    );
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
      environmentPayload: {
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
      'fetchBrandingSettings maps public web metadata fields from environment payload',
      () async {
    final adapter = _RoutingAdapter(
      environmentPayload: {
        'type': 'tenant',
        'tenant_id': 'tenant-a',
        'name': 'Guarappari Admin',
        'theme_data_settings': {
          'brightness_default': 'light',
          'primary_seed_color': '#a36ce3',
          'secondary_seed_color': '#03dac6',
        },
        'public_web_metadata': {
          'default_title': 'Guarappari Home',
          'default_description': 'Fallback institucional da home.',
          'default_image': '/storage/public-web.jpg',
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

    expect(branding.publicWebDefaultTitle, 'Guarappari Home');
    expect(
      branding.publicWebDefaultDescription,
      'Fallback institucional da home.',
    );
    expect(
      branding.publicWebDefaultImageUrl,
      'http://tenant-a.test:8081/storage/public-web.jpg',
    );
  });

  test(
      'fetchBrandingSettings ignores stale response from previous tenant scope',
      () async {
    final adapter = _RoutingAdapter(
      environmentPayloadByHost: {
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
      environmentDelayByHost: {
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
      environmentPayload: {
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
      environmentPayload: {
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

TenantAdminPositiveIntValue _positiveIntValue(int raw) {
  final value = TenantAdminPositiveIntValue();
  value.parse(raw.toString());
  return value;
}

TenantAdminResendEmailRecipients _recipients(Iterable<String> values) {
  return TenantAdminResendEmailRecipients(
    values.map(_emailAddressValue),
  );
}

List<String> _recipientStrings(TenantAdminResendEmailRecipients values) {
  return values.values.map((entry) => entry.value).toList(growable: false);
}

EmailAddressValue _emailAddressValue(String raw) {
  final value = EmailAddressValue();
  value.parse(raw);
  return value;
}

LatitudeValue _latitudeValue(double raw) {
  final value = LatitudeValue();
  value.parse(raw.toString());
  return value;
}

LongitudeValue _longitudeValue(double raw) {
  final value = LongitudeValue();
  value.parse(raw.toString());
  return value;
}

TenantAdminOptionalTextValue _optionalTextValue(String raw) {
  final value = TenantAdminOptionalTextValue();
  value.parse(raw);
  return value;
}

TenantAdminBooleanValue _booleanValue(bool raw) {
  final value = TenantAdminBooleanValue();
  value.parse(raw.toString());
  return value;
}

TenantAdminLowercaseTokenValue _tokenValue(String raw) {
  final value = TenantAdminLowercaseTokenValue();
  value.parse(raw);
  return value;
}

TenantAdminRequiredTextValue _requiredTextValue(String raw) {
  final value = TenantAdminRequiredTextValue();
  value.parse(raw);
  return value;
}

TenantAdminMapFilterCatalogItems _mapFilterCatalogItems(
  Iterable<TenantAdminMapFilterCatalogItem> items,
) {
  final collection = TenantAdminMapFilterCatalogItems();
  for (final item in items) {
    collection.add(item);
  }
  return collection;
}

TenantAdminHexColorValue _hexColorValue(String raw) {
  final value = TenantAdminHexColorValue();
  value.parse(raw);
  return value;
}

class _StubAuthRepo implements LandlordAuthRepositoryContract {
  @override
  bool get hasValidSession => true;

  @override
  String get token => 'test-token';

  @override
  Future<void> init() async {}

  @override
  Future<void> loginWithEmailPassword(
      LandlordAuthRepositoryContractPrimString email,
      LandlordAuthRepositoryContractPrimString password) async {}

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
  void selectTenantDomain(Object tenantDomain) {
    _selectedTenantDomainStreamValue.addValue((tenantDomain is String
            ? tenantDomain
            : (tenantDomain as dynamic).value as String)
        .trim());
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
  void selectTenantDomain(Object tenantDomain) {
    _selectedTenantDomainStreamValue.addValue((tenantDomain is String
            ? tenantDomain
            : (tenantDomain as dynamic).value as String)
        .trim());
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
  void selectTenantDomain(Object tenantDomain) {
    _selectedTenantDomainStreamValue.addValue((tenantDomain is String
            ? tenantDomain
            : (tenantDomain as dynamic).value as String)
        .trim());
  }
}

class _RoutingAdapter implements HttpClientAdapter {
  _RoutingAdapter({
    this.environmentPayload,
    this.environmentPayloadByHost,
    this.environmentDelayByHost,
    this.settingsValuesPayload,
    this.createDomainValidationMessage,
    List<Map<String, dynamic>>? domainsPayload,
    Map<String, dynamic>? appDomainsPayload,
    Map<String, bool>? typedAppDomainPersistedByPlatform,
  })  : _appDomainsPayload = Map<String, dynamic>.from(
          appDomainsPayload ??
              {
                'android': 'com.guarappari.app',
                'ios': 'com.guarappari.app',
              },
        ),
        _typedAppDomainPersistedByPlatform = Map<String, bool>.from(
          typedAppDomainPersistedByPlatform ??
              {
                if ((appDomainsPayload?['android'] as String?)
                        ?.trim()
                        .isNotEmpty ??
                    true)
                  'android': true,
                if ((appDomainsPayload?['ios'] as String?)?.trim().isNotEmpty ??
                    true)
                  'ios': true,
              },
        ),
        _domainsPayload = (domainsPayload ??
                [
                  {
                    'id': 'domain-1',
                    'path': 'tenant-a.test',
                    'type': 'web',
                    'status': 'active',
                    'created_at': '2026-04-01T10:00:00Z',
                    'updated_at': '2026-04-01T10:00:00Z',
                    'deleted_at': null,
                  },
                  {
                    'id': 'domain-2',
                    'path': 'tenant-old.test',
                    'type': 'web',
                    'status': 'deleted',
                    'created_at': '2026-03-01T10:00:00Z',
                    'updated_at': '2026-03-01T10:00:00Z',
                    'deleted_at': '2026-04-02T10:00:00Z',
                  },
                ])
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList(growable: true);

  final Map<String, dynamic>? environmentPayload;
  final Map<String, Map<String, dynamic>>? environmentPayloadByHost;
  final Map<String, Duration>? environmentDelayByHost;
  final Map<String, dynamic>? settingsValuesPayload;
  final String? createDomainValidationMessage;
  final Map<String, dynamic> _appDomainsPayload;
  final Map<String, bool> _typedAppDomainPersistedByPlatform;
  final List<Map<String, dynamic>> _domainsPayload;
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

    final path = options.uri.path;
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
                'app_links': {
                  'android': {
                    'sha256_cert_fingerprints': [
                      '3E:72:4C:54:E9:53:26:7D:E6:E1:9B:F8:DC:53:30:2A:08:01:8E:36:40:AA:23:11:22:33:44:55:66:77:88:99',
                    ],
                  },
                  'ios': {
                    'team_id': 'TEAMID1234',
                    'paths': ['/invite*', '/convites*'],
                  },
                },
                'resend_email': {
                  'token': 're_live_token',
                  'from': 'Belluga <noreply@belluga.space>',
                  'to': ['admin@bellugasolutions.com.br'],
                  'cc': ['ops@bellugasolutions.com.br'],
                  'bcc': ['audit@bellugasolutions.com.br'],
                  'reply_to': ['reply@bellugasolutions.com.br'],
                },
                'map_ui': {
                  'radius': {
                    'min_km': 1,
                    'default_km': 5,
                    'max_km': 50,
                  },
                  'poi_time_window_days': {
                    'past': 0,
                    'future': 0,
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
                          'https://tenant-a.test/map-filters/events/image?v=1710000000',
                      'query': {
                        'source': 'event',
                        'types': ['show'],
                        'taxonomy': ['music_genre:rock'],
                      },
                    },
                  ],
                },
              },
            },
      );
    }

    if (path.endsWith('/appdomains') && method == 'GET') {
      return _jsonResponse({
        'data': {
          'app_domains': Map<String, dynamic>.from(_appDomainsPayload),
        },
      });
    }

    if (path.endsWith('/appdomains') && method == 'POST') {
      final request = Map<String, dynamic>.from(options.data as Map);
      final platform = (request['platform'] as String?)?.trim() ?? '';
      final identifier = (request['identifier'] as String?)?.trim();
      if (platform.isNotEmpty && identifier != null && identifier.isNotEmpty) {
        _appDomainsPayload[platform] = identifier;
        _typedAppDomainPersistedByPlatform[platform] = true;
      }
      return _jsonResponse({
        'data': {
          'app_domains': Map<String, dynamic>.from(_appDomainsPayload),
        },
      });
    }

    if (path.endsWith('/appdomains') && method == 'DELETE') {
      final request = Map<String, dynamic>.from(options.data as Map);
      final platform = (request['platform'] as String?)?.trim() ?? '';
      if (platform.isNotEmpty) {
        _appDomainsPayload[platform] = null;
        _typedAppDomainPersistedByPlatform[platform] = false;
      }
      return _jsonResponse({
        'data': {
          'app_domains': Map<String, dynamic>.from(_appDomainsPayload),
        },
      });
    }

    if (path.endsWith('/domains') && method == 'GET') {
      final queryParameters = options.uri.queryParameters;
      final page = int.tryParse(queryParameters['page']?.toString() ?? '') ?? 1;
      final perPage = int.tryParse(
            queryParameters['per_page']?.toString() ?? '',
          ) ??
          15;
      final start = (page - 1) * perPage;
      final end = start + perPage > _domainsPayload.length
          ? _domainsPayload.length
          : start + perPage;
      final data = start >= _domainsPayload.length
          ? <Map<String, dynamic>>[]
          : _domainsPayload.sublist(start, end);
      final lastPage = _domainsPayload.isEmpty
          ? 1
          : ((_domainsPayload.length + perPage - 1) / perPage).ceil();
      return _jsonResponse({
        'data': data,
        'current_page': page,
        'per_page': perPage,
        'last_page': lastPage,
        'total': _domainsPayload.length,
      });
    }

    if (path.endsWith('/domains') && method == 'POST') {
      final request = Map<String, dynamic>.from(options.data as Map);
      if (createDomainValidationMessage != null) {
        return _jsonResponse(
          {
            'message': createDomainValidationMessage,
            'errors': {
              'path': [createDomainValidationMessage],
            },
          },
          statusCode: 422,
        );
      }
      final next = <String, dynamic>{
        'id': 'domain-${_domainsPayload.length + 1}',
        'path': (request['path'] as String?)?.trim() ?? '',
        'type': 'web',
        'status': 'active',
        'created_at': '2026-04-05T10:00:00Z',
        'updated_at': '2026-04-05T10:00:00Z',
        'deleted_at': null,
      };
      _domainsPayload.insert(0, next);
      return _jsonResponse({'data': next});
    }

    if (path.contains('/domains/') && method == 'DELETE') {
      final domainId = path.split('/').last;
      _domainsPayload.removeWhere((entry) => entry['id'] == domainId);
      return _jsonResponse(const <String, dynamic>{});
    }

    if (path.endsWith('/settings/values/map_ui') && method == 'PATCH') {
      final request = Map<String, dynamic>.from(options.data as Map);
      return _jsonResponse({
        'data': {
          'map_ui': _expandDotPayload(request),
        },
      });
    }

    if (path.endsWith('/settings/values/app_links') && method == 'PATCH') {
      final request = Map<String, dynamic>.from(options.data as Map);
      final androidFingerprints =
          request['android.sha256_cert_fingerprints'] as List<dynamic>?;
      if ((androidFingerprints?.isNotEmpty ?? false) &&
          _typedAppDomainPersistedByPlatform['android'] != true) {
        return _jsonResponse(
          {
            'message':
                'Configure Android app identifier before saving fingerprints.',
            'errors': {
              'android.sha256_cert_fingerprints': [
                'Configure Android app identifier before saving fingerprints.',
              ],
            },
          },
          statusCode: 422,
        );
      }
      return _jsonResponse({
        'data': {
          'app_links': _expandDotPayload(request),
        },
      });
    }

    if (path.endsWith('/settings/values/resend_email') && method == 'PATCH') {
      final request = Map<String, dynamic>.from(options.data as Map);
      return _jsonResponse({
        'data': {
          'resend_email': _expandDotPayload(request),
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
              'https://tenant-a.test/map-filters/$normalizedKey/image?v=1710000000',
        },
      });
    }

    if (path.endsWith('/settings/telemetry') && method == 'GET') {
      return _jsonResponse({
        'data': [
          {
            'type': 'mixpanel',
            'track_all': false,
            'events': ['app_opened'],
            'token': 'token-a',
          },
        ],
        'available_events': ['app_opened', 'invite_sent'],
      });
    }

    if (path.endsWith('/settings/telemetry') && method == 'POST') {
      final request = options.data as Map<String, dynamic>;
      return _jsonResponse({
        'data': [request],
        'available_events': ['app_opened', 'invite_sent'],
      });
    }

    if (path.contains('/settings/telemetry/') && method == 'DELETE') {
      return _jsonResponse({
        'data': [],
        'available_events': ['app_opened', 'invite_sent'],
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

    return _jsonResponse({});
  }

  ResponseBody _jsonResponse(
    Map<String, dynamic> payload, {
    int statusCode = 200,
  }) {
    return ResponseBody.fromString(
      jsonEncode(payload),
      statusCode,
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
