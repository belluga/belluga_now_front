import 'dart:convert';
import 'dart:typed_data';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_static_assets_repository.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_base_url_resolver.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

import 'support/tenant_admin_paged_stream_contract.dart';

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

  test('updateStaticProfileType sends new type when renaming', () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminStaticAssetsRepository(dio: dio);

    await repository.updateStaticProfileType(
      type: 'poi',
      newType: 'landmark',
    );

    expect(adapter.lastRequest?.method, 'PATCH');
    expect(
      adapter.lastRequest?.path,
      contains('https://tenant.test/admin/api/v1/static_profile_types/poi'),
    );
    final data = adapter.lastRequest?.data;
    expect(data, isA<Map<String, dynamic>>());
    expect((data as Map<String, dynamic>)['type'], 'landmark');
  });

  test('fetchStaticAssets switches request host after tenant selection changes',
      () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final tenantScope = _StubTenantScope('https://tenant-a.test');
    final repository = TenantAdminStaticAssetsRepository(
      dio: dio,
      tenantScope: tenantScope,
    );

    await repository.fetchStaticAssets();
    tenantScope.selectTenantDomain('https://tenant-b.test');
    await repository.fetchStaticAssets();

    expect(adapter.requests, hasLength(2));
    expect(adapter.requests[0].uri.host, 'tenant-a.test');
    expect(adapter.requests[1].uri.host, 'tenant-b.test');
  });

  test('createStaticAsset sends multipart avatar/cover uploads', () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminStaticAssetsRepository(dio: dio);

    await repository.createStaticAsset(
      profileType: 'poi',
      displayName: 'Asset Name',
      avatarUpload: TenantAdminMediaUpload(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'avatar.jpg',
        mimeType: 'image/jpeg',
      ),
      coverUpload: TenantAdminMediaUpload(
        bytes: Uint8List.fromList([4, 5, 6]),
        fileName: 'cover.jpg',
        mimeType: 'image/jpeg',
      ),
    );

    final data = adapter.lastRequest?.data;
    expect(data, isA<FormData>());
    final formData = data as FormData;
    expect(formData.files.any((entry) => entry.key == 'avatar'), isTrue);
    expect(formData.files.any((entry) => entry.key == 'cover'), isTrue);
  });

  test('updateStaticAsset with uploads uses multipart PATCH override',
      () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminStaticAssetsRepository(dio: dio);

    await repository.updateStaticAsset(
      assetId: 'asset-1',
      displayName: 'Updated Name',
      avatarUpload: TenantAdminMediaUpload(
        bytes: Uint8List.fromList([7, 8, 9]),
        fileName: 'avatar.jpg',
        mimeType: 'image/jpeg',
      ),
    );

    expect(adapter.lastRequest?.method, 'POST');
    expect(
      adapter.lastRequest?.path,
      contains('https://tenant.test/admin/api/v1/static_assets/asset-1'),
    );
    final data = adapter.lastRequest?.data;
    expect(data, isA<FormData>());
    final formData = data as FormData;
    expect(
      formData.fields.any(
        (entry) => entry.key == '_method' && entry.value == 'PATCH',
      ),
      isTrue,
    );
    expect(formData.files.any((entry) => entry.key == 'avatar'), isTrue);
  });

  test('load/reset/next follow paged stream contract for static assets',
      () async {
    final adapter = _CaptureAdapter(
      staticAssetsByPage: const {
        1: [
          {
            'id': 'asset-1',
            'profile_type': 'beach',
            'display_name': 'Praia do Morro',
            'slug': 'praia-do-morro',
            'is_active': true,
          },
          {
            'id': 'asset-2',
            'profile_type': 'beach',
            'display_name': 'Setiba',
            'slug': 'setiba',
            'is_active': true,
          },
        ],
        2: [
          {
            'id': 'asset-3',
            'profile_type': 'museum',
            'display_name': 'Museu',
            'slug': 'museu',
            'is_active': true,
          },
        ],
      },
      staticAssetsLastPage: 2,
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminStaticAssetsRepository(dio: dio);

    await verifyTenantAdminPagedStreamContract(
      scope: 'static assets',
      loadFirstPage: () => repository.loadStaticAssets(pageSize: 2),
      loadNextPage: () => repository.loadNextStaticAssetsPage(pageSize: 2),
      resetState: repository.resetStaticAssetsState,
      readItems: () => repository.staticAssetsStreamValue.value,
      readHasMore: () => repository.hasMoreStaticAssetsStreamValue.value,
      readError: () => repository.staticAssetsErrorStreamValue.value,
      expectedCountsPerStep: const [2, 3],
      loadNextCalls: 1,
    );
  });

  test('load/reset/next follow paged stream contract for static profile types',
      () async {
    final adapter = _CaptureAdapter(
      staticProfileTypesByPage: const {
        1: [
          {
            'id': 'type-1',
            'type': 'beach',
            'label': 'Beach',
            'allowed_taxonomies': <String>[],
            'capabilities': {
              'is_poi_enabled': true,
              'has_bio': true,
              'has_taxonomies': true,
              'has_avatar': true,
              'has_cover': true,
              'has_content': true,
            },
          },
          {
            'id': 'type-2',
            'type': 'museum',
            'label': 'Museum',
            'allowed_taxonomies': <String>[],
            'capabilities': {
              'is_poi_enabled': true,
              'has_bio': true,
              'has_taxonomies': true,
              'has_avatar': true,
              'has_cover': true,
              'has_content': true,
            },
          },
        ],
        2: [
          {
            'id': 'type-3',
            'type': 'culture',
            'label': 'Culture',
            'allowed_taxonomies': <String>[],
            'capabilities': {
              'is_poi_enabled': true,
              'has_bio': true,
              'has_taxonomies': true,
              'has_avatar': true,
              'has_cover': true,
              'has_content': true,
            },
          },
        ],
      },
      staticProfileTypesLastPage: 2,
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminStaticAssetsRepository(dio: dio);

    await verifyTenantAdminPagedStreamContract(
      scope: 'static profile types',
      loadFirstPage: () => repository.loadStaticProfileTypes(pageSize: 2),
      loadNextPage: () =>
          repository.loadNextStaticProfileTypesPage(pageSize: 2),
      resetState: repository.resetStaticProfileTypesState,
      readItems: () => repository.staticProfileTypesStreamValue.value,
      readHasMore: () => repository.hasMoreStaticProfileTypesStreamValue.value,
      readError: () => repository.staticProfileTypesErrorStreamValue.value,
      expectedCountsPerStep: const [2, 3],
      loadNextCalls: 1,
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
  _CaptureAdapter({
    this.staticAssetsByPage = const <int, List<Map<String, dynamic>>>{},
    this.staticAssetsLastPage = 1,
    this.staticProfileTypesByPage = const <int, List<Map<String, dynamic>>>{},
    this.staticProfileTypesLastPage = 1,
  });

  RequestOptions? lastRequest;
  final List<RequestOptions> requests = [];
  final Map<int, List<Map<String, dynamic>>> staticAssetsByPage;
  final int staticAssetsLastPage;
  final Map<int, List<Map<String, dynamic>>> staticProfileTypesByPage;
  final int staticProfileTypesLastPage;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future? cancelFuture,
  ) async {
    lastRequest = options;
    requests.add(options);
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

    if (options.method == 'GET' && options.path.contains('/v1/static_assets')) {
      final page = options.queryParameters['page'];
      final parsedPage = page is int ? page : int.tryParse('$page') ?? 1;
      final data = staticAssetsByPage[parsedPage] ?? const [];
      return ResponseBody.fromString(
        jsonEncode({
          'data': data,
          'current_page': parsedPage,
          'last_page': staticAssetsLastPage,
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    if (options.method == 'GET' &&
        options.path.contains('/v1/static_profile_types')) {
      final page = options.queryParameters['page'];
      final parsedPage = page is int ? page : int.tryParse('$page') ?? 1;
      final data = staticProfileTypesByPage[parsedPage] ?? const [];
      return ResponseBody.fromString(
        jsonEncode({
          'data': data,
          'current_page': parsedPage,
          'last_page': staticProfileTypesLastPage,
        }),
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
