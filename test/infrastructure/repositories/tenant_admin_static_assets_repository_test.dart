import 'dart:convert';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_static_assets_repository.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_base_url_resolver.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(_StubAuthRepo());
    GetIt.I.registerSingleton<TenantAdminTenantScopeContract>(
      _StubTenantScope('https://tenant.test'),
    );
    GetIt.I.registerSingleton<AppData>(_buildAppData());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('updateStaticProfileType encodes reserved characters in route segment',
      () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminStaticAssetsRepository(dio: dio);

    await repository.updateStaticProfileType(
      type: 'poi/type',
      label: 'POI Type',
      capabilities: const TenantAdminStaticProfileTypeCapabilities(
        isPoiEnabled: true,
        hasBio: true,
        hasTaxonomies: true,
        hasAvatar: true,
        hasCover: false,
        hasContent: false,
      ),
    );

    expect(adapter.lastRequest?.method, 'PATCH');
    expect(
      adapter.lastRequest?.path,
      contains(
          'https://tenant.test/admin/api/v1/static_profile_types/poi%2Ftype'),
    );
  });

  test('deleteStaticProfileType encodes reserved characters in route segment',
      () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminStaticAssetsRepository(dio: dio);

    await repository.deleteStaticProfileType('poi/type');

    expect(adapter.lastRequest?.method, 'DELETE');
    expect(
      adapter.lastRequest?.path,
      contains(
          'https://tenant.test/admin/api/v1/static_profile_types/poi%2Ftype'),
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

class _StubTenantScope implements TenantAdminTenantScopeContract {
  _StubTenantScope(this._selectedTenantDomain);

  String? _selectedTenantDomain;

  @override
  String? get selectedTenantDomain => _selectedTenantDomain;

  @override
  String get selectedTenantAdminBaseUrl =>
      resolveTenantAdminBaseUrl(_selectedTenantDomain ?? '');

  @override
  StreamValue<String?> get selectedTenantDomainStreamValue =>
      StreamValue<String?>(defaultValue: _selectedTenantDomain);

  @override
  void clearSelectedTenantDomain() {
    _selectedTenantDomain = null;
  }

  @override
  void selectTenantDomain(String tenantDomain) {
    _selectedTenantDomain = tenantDomain;
  }
}

class _CaptureAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future? cancelFuture,
  ) async {
    lastRequest = options;
    if (options.method == 'PATCH') {
      final payload = jsonEncode({
        'data': {
          'type': 'poi/type',
          'label': 'POI Type',
          'allowed_taxonomies': <String>[],
          'capabilities': {
            'is_poi_enabled': true,
            'has_bio': true,
            'has_taxonomies': true,
            'has_avatar': true,
            'has_cover': false,
            'has_content': false,
          },
        },
      });
      return ResponseBody.fromString(
        payload,
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

AppData _buildAppData() {
  final remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'main_domain': 'https://tenant.test',
    'domains': ['https://tenant.test'],
    'app_domains': const [],
    'theme_data_settings': {
      'brightness_default': 'light',
      'primary_seed_color': '#FFFFFF',
      'secondary_seed_color': '#000000',
    },
    'main_color': '#FFFFFF',
    'tenant_id': 'tenant-1',
    'telemetry': const {'trackers': []},
    'telemetry_context': const {'location_freshness_minutes': 5},
    'firebase': null,
    'push': null,
  };
  final localInfo = {
    'platformType': PlatformTypeValue()..parse('mobile'),
    'hostname': 'tenant.test',
    'href': 'https://tenant.test',
    'port': null,
    'device': 'test-device',
  };
  return AppData.fromInitialization(
    remoteData: remoteData,
    localInfo: localInfo,
  );
}
