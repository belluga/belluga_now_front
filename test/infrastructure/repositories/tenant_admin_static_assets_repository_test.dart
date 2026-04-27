import 'dart:convert';
import 'dart:typed_data';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_static_assets_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_hex_color_value.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_static_assets_repository.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_base_url_resolver.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

import 'support/tenant_admin_paged_stream_contract.dart';

TenantAdminStaticAssetsRepoString _staticText(String value) =>
    TenantAdminStaticAssetsRepoString.fromRaw(value);
TenantAdminStaticAssetsRepoInt _staticInt(int value) =>
    TenantAdminStaticAssetsRepoInt.fromRaw(value, defaultValue: value);
List<TenantAdminStaticAssetsRepoString> _staticTextList(
  Iterable<String> values,
) {
  return values.map(_staticText).toList(growable: false);
}

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
      type: _staticText('poi/type'),
      label: _staticText('POI Type'),
      capabilities: TenantAdminStaticProfileTypeCapabilities(
        isPoiEnabled: TenantAdminFlagValue(true),
        hasBio: TenantAdminFlagValue(true),
        hasTaxonomies: TenantAdminFlagValue(true),
        hasAvatar: TenantAdminFlagValue(true),
        hasCover: TenantAdminFlagValue(false),
        hasContent: TenantAdminFlagValue(false),
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

    await repository.deleteStaticProfileType(_staticText('poi/type'));

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
      type: _staticText('poi'),
      newType: _staticText('landmark'),
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

  test(
      'createStaticProfileTypeWithVisual sends canonical and legacy visual payloads',
      () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminStaticAssetsRepository(dio: dio);

    await repository.createStaticProfileTypeWithVisual(
      type: _staticText('beach'),
      label: _staticText('Beach'),
      allowedTaxonomies: _staticTextList(const ['region']),
      capabilities: TenantAdminStaticProfileTypeCapabilities(
        isPoiEnabled: TenantAdminFlagValue(true),
        hasBio: TenantAdminFlagValue(true),
        hasTaxonomies: TenantAdminFlagValue(true),
        hasAvatar: TenantAdminFlagValue(true),
        hasCover: TenantAdminFlagValue(true),
        hasContent: TenantAdminFlagValue(true),
      ),
      visual: TenantAdminPoiVisual.image(
        imageSource: TenantAdminPoiVisualImageSource.cover,
      ),
    );

    final payload = adapter.lastRequest?.data as Map<String, dynamic>;
    expect(payload['visual'], <String, dynamic>{
      'mode': 'image',
      'image_source': 'cover',
    });
    expect(payload['poi_visual'], <String, dynamic>{
      'mode': 'image',
      'image_source': 'cover',
    });
  });

  test('updateStaticProfileTypeWithVisual sends nullable visual payloads',
      () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminStaticAssetsRepository(dio: dio);

    await repository.updateStaticProfileTypeWithVisual(
      type: _staticText('beach'),
      capabilities: TenantAdminStaticProfileTypeCapabilities(
        isPoiEnabled: TenantAdminFlagValue(false),
        hasBio: TenantAdminFlagValue(true),
        hasTaxonomies: TenantAdminFlagValue(true),
        hasAvatar: TenantAdminFlagValue(true),
        hasCover: TenantAdminFlagValue(true),
        hasContent: TenantAdminFlagValue(true),
      ),
      visual: null,
    );

    final payload = adapter.lastRequest?.data as Map<String, dynamic>;
    expect(payload.containsKey('visual'), isTrue);
    expect(payload['visual'], isNull);
    expect(payload.containsKey('poi_visual'), isTrue);
    expect(payload['poi_visual'], isNull);
  });

  test(
      'createStaticProfileTypeWithVisual uses multipart when type_asset upload exists',
      () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminStaticAssetsRepository(dio: dio);

    await repository.createStaticProfileTypeWithVisual(
      type: _staticText('landmark'),
      label: _staticText('Landmark'),
      capabilities: TenantAdminStaticProfileTypeCapabilities(
        isPoiEnabled: TenantAdminFlagValue(true),
        hasBio: TenantAdminFlagValue(true),
        hasTaxonomies: TenantAdminFlagValue(true),
        hasAvatar: TenantAdminFlagValue(true),
        hasCover: TenantAdminFlagValue(true),
        hasContent: TenantAdminFlagValue(true),
      ),
      visual: TenantAdminPoiVisual.image(
        imageSource: TenantAdminPoiVisualImageSource.typeAsset,
        colorValue: TenantAdminHexColorValue()..parse('#00897B'),
      ),
      typeAssetUpload: tenantAdminMediaUploadFromRaw(
        bytes: Uint8List.fromList([3, 4, 5]),
        fileName: 'landmark.png',
      ),
    );

    expect(adapter.lastRequest?.method, 'POST');
    expect(adapter.lastRequest?.contentType, contains('multipart/form-data'));
    final payload = adapter.lastRequest?.data;
    expect(payload, isA<FormData>());
    final formData = payload as FormData;
    expect(formData.files.any((entry) => entry.key == 'type_asset'), isTrue);
    expect(
      formData.fields.any((entry) => entry.key == 'visual[image_source]'),
      isTrue,
    );
    expect(
      formData.fields.any(
        (entry) => entry.key == 'visual[color]' && entry.value == '#00897B',
      ),
      isTrue,
    );
    expect(
      formData.fields.any(
        (entry) =>
            entry.key == 'capabilities[is_poi_enabled]' && entry.value == '1',
      ),
      isTrue,
    );
    expect(
      formData.fields.any(
        (entry) =>
            entry.key == 'capabilities[has_avatar]' && entry.value == '1',
      ),
      isTrue,
    );
  });

  test(
      'updateStaticProfileTypeWithVisual uses multipart patch tunnel for type_asset upload and removal',
      () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminStaticAssetsRepository(dio: dio);

    await repository.updateStaticProfileTypeWithVisual(
      type: _staticText('landmark'),
      visual: TenantAdminPoiVisual.image(
        imageSource: TenantAdminPoiVisualImageSource.typeAsset,
      ),
      typeAssetUpload: tenantAdminMediaUploadFromRaw(
        bytes: Uint8List.fromList([3, 4, 5]),
        fileName: 'landmark.png',
      ),
      removeTypeAsset: TenantAdminStaticAssetsRepoBool.fromRaw(
        true,
        defaultValue: false,
      ),
    );

    expect(adapter.lastRequest?.method, 'POST');
    expect(adapter.lastRequest?.contentType, contains('multipart/form-data'));
    final payload = adapter.lastRequest?.data;
    expect(payload, isA<FormData>());
    final formData = payload as FormData;
    expect(formData.files.any((entry) => entry.key == 'type_asset'), isTrue);
    expect(formData.fields, contains(const MapEntry('_method', 'PATCH')));
    expect(
      formData.fields.any(
        (entry) => entry.key == 'remove_type_asset' && entry.value == '1',
      ),
      isTrue,
    );
  });

  test('fetchStaticProfileTypeMapPoiProjectionImpact returns projection count',
      () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminStaticAssetsRepository(dio: dio);

    final count = await repository.fetchStaticProfileTypeMapPoiProjectionImpact(
      type: _staticText('beach'),
    );

    expect(count.value, 42);
    expect(
      adapter.lastRequest?.path,
      contains(
        '/admin/api/v1/static_profile_types/beach/map_poi_projection_impact',
      ),
    );
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

  test(
      'normalizes relative static-asset media urls and preserves absolute urls',
      () async {
    final adapter = _CaptureAdapter(
      staticAssetsByPage: {
        1: [
          {
            'id': 'asset-1',
            'profile_type': 'poi',
            'display_name': 'Asset 1',
            'slug': 'asset-1',
            'avatar_url':
                'http://legacy-host.test/static-assets/asset-1/avatar?v=7',
            'cover_url': '/static-assets/asset-1/cover?v=7',
            'is_active': true,
          },
          {
            'id': 'asset-2',
            'profile_type': 'poi',
            'display_name': 'Asset 2',
            'slug': 'asset-2',
            'avatar_url': 'https://cdn.example.com/avatar.png',
            'cover_url': 'https://cdn.example.com/cover.png',
            'is_active': true,
          },
        ],
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final tenantScope = _StubTenantScope('https://tenant-current.test');
    final repository = TenantAdminStaticAssetsRepository(
      dio: dio,
      tenantScope: tenantScope,
    );

    final page = await repository.fetchStaticAssetsPage(
      page: _staticInt(1),
      pageSize: _staticInt(20),
    );

    expect(page.items, hasLength(2));
    expect(
      page.items.first.avatarUrl,
      'http://legacy-host.test/static-assets/asset-1/avatar?v=7',
    );
    expect(
      page.items.first.coverUrl,
      'https://tenant-current.test/static-assets/asset-1/cover?v=7',
    );
    expect(page.items[1].avatarUrl, 'https://cdn.example.com/avatar.png');
    expect(page.items[1].coverUrl, 'https://cdn.example.com/cover.png');
  });

  test('normalizes static-asset media urls on detail fetch', () async {
    final adapter = _CaptureAdapter(
      staticAssetsByPage: {
        1: [
          {
            'id': 'asset-1',
            'profile_type': 'poi',
            'display_name': 'Asset 1',
            'slug': 'asset-1',
            'avatar_url':
                'http://legacy-host.test/static-assets/asset-1/avatar?v=9',
            'cover_url':
                'http://legacy-host.test/static-assets/asset-1/cover?v=9',
            'is_active': true,
          },
        ],
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final tenantScope = _StubTenantScope('https://tenant-current.test');
    final repository = TenantAdminStaticAssetsRepository(
      dio: dio,
      tenantScope: tenantScope,
    );

    final asset = await repository.fetchStaticAsset(_staticText('asset-1'));

    expect(
      asset.avatarUrl,
      'http://legacy-host.test/static-assets/asset-1/avatar?v=9',
    );
    expect(
      asset.coverUrl,
      'http://legacy-host.test/static-assets/asset-1/cover?v=9',
    );
  });

  test('createStaticAsset sends multipart avatar/cover uploads', () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminStaticAssetsRepository(dio: dio);

    await repository.createStaticAsset(
      profileType: _staticText('poi'),
      displayName: _staticText('Asset Name'),
      avatarUpload: tenantAdminMediaUploadFromRaw(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'avatar.jpg',
        mimeType: 'image/jpeg',
      ),
      coverUpload: tenantAdminMediaUploadFromRaw(
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
      assetId: _staticText('asset-1'),
      displayName: _staticText('Updated Name'),
      avatarUpload: tenantAdminMediaUploadFromRaw(
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

  test('updateStaticAsset sends explicit remove avatar/cover flags', () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminStaticAssetsRepository(dio: dio);

    await repository.updateStaticAsset(
      assetId: _staticText('asset-1'),
      removeAvatar: TenantAdminStaticAssetsRepoBool.fromRaw(true),
      removeCover: TenantAdminStaticAssetsRepoBool.fromRaw(true),
    );

    expect(adapter.lastRequest?.method, 'PATCH');
    final data = adapter.lastRequest?.data;
    expect(data, isA<Map<String, dynamic>>());
    final payload = data as Map<String, dynamic>;
    expect(payload['remove_avatar'], isTrue);
    expect(payload['remove_cover'], isTrue);
  });

  test('fetchStaticProfileTypesPage parses poi_visual contract', () async {
    final adapter = _CaptureAdapter(
      staticProfileTypesByPage: {
        1: [
          {
            'id': 'type-1',
            'type': 'beach',
            'label': 'Beach',
            'allowed_taxonomies': <String>[],
            'poi_visual': {
              'mode': 'image',
              'image_source': 'avatar',
            },
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
      staticProfileTypesLastPage: 1,
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminStaticAssetsRepository(dio: dio);

    final page = await repository.fetchStaticProfileTypesPage(
      page: _staticInt(1),
      pageSize: _staticInt(20),
    );

    expect(page.items, hasLength(1));
    expect(page.items.first.visual?.mode, TenantAdminPoiVisualMode.image);
    expect(
      page.items.first.visual?.imageSource,
      TenantAdminPoiVisualImageSource.avatar,
    );
  });

  test('load/reset/next follow paged stream contract for static assets',
      () async {
    final adapter = _CaptureAdapter(
      staticAssetsByPage: {
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
      loadFirstPage: () => repository.loadStaticAssets(pageSize: _staticInt(2)),
      loadNextPage: () =>
          repository.loadNextStaticAssetsPage(pageSize: _staticInt(2)),
      resetState: repository.resetStaticAssetsState,
      readItems: () => repository.staticAssetsStreamValue.value,
      readHasMore: () => repository.hasMoreStaticAssetsStreamValue.value.value,
      readError: () => repository.staticAssetsErrorStreamValue.value?.value,
      expectedCountsPerStep: [2, 3],
      loadNextCalls: 1,
    );
  });

  test('load/reset/next follow paged stream contract for static profile types',
      () async {
    final adapter = _CaptureAdapter(
      staticProfileTypesByPage: {
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
      loadFirstPage: () =>
          repository.loadStaticProfileTypes(pageSize: _staticInt(2)),
      loadNextPage: () =>
          repository.loadNextStaticProfileTypesPage(pageSize: _staticInt(2)),
      resetState: repository.resetStaticProfileTypesState,
      readItems: () => repository.staticProfileTypesStreamValue.value,
      readHasMore: () =>
          repository.hasMoreStaticProfileTypesStreamValue.value.value,
      readError: () =>
          repository.staticProfileTypesErrorStreamValue.value?.value,
      expectedCountsPerStep: [2, 3],
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
  Future<void> loginWithEmailPassword(
      LandlordAuthRepositoryContractPrimString email,
      LandlordAuthRepositoryContractPrimString password) async {}

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
  void selectTenantDomain(Object tenantDomain) {
    _selectedTenantDomain = tenantDomain is String
        ? tenantDomain
        : (tenantDomain as dynamic).value as String;
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
    if (options.path.endsWith('/map_poi_projection_impact')) {
      return ResponseBody.fromString(
        jsonEncode({
          'data': {
            'profile_type': 'beach',
            'projection_count': 42,
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    if ((options.method == 'POST' || options.method == 'PATCH') &&
        options.path.contains('/v1/static_profile_types')) {
      final payload = jsonEncode({
        'data': {
          'type': 'poi/type',
          'label': 'POI Type',
          'poi_visual': {
            'mode': 'icon',
            'icon': 'place',
            'color': '#00AAFF',
            'icon_color': '#FFFFFF',
          },
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

    if ((options.method == 'POST' || options.method == 'PATCH') &&
        options.path.contains('/v1/static_assets')) {
      final pathSegments = options.path.split('/');
      final maybeAssetId = pathSegments.isNotEmpty ? pathSegments.last : '';
      final assetId = maybeAssetId.isNotEmpty &&
              maybeAssetId != 'static_assets' &&
              maybeAssetId != 'v1'
          ? maybeAssetId
          : 'asset-created';
      return ResponseBody.fromString(
        jsonEncode({
          'data': {
            'id': assetId,
            'profile_type': 'poi',
            'display_name': 'Asset Name',
            'slug': 'asset-name',
            'is_active': true,
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    if (options.method == 'GET' &&
        options.path.contains('/v1/static_assets/') &&
        !options.path.endsWith('/v1/static_assets')) {
      final detailItem = (staticAssetsByPage[1] ?? []).firstWhere(
        (item) => (item['id']?.toString() ?? '').trim().isNotEmpty,
        orElse: () => <String, dynamic>{},
      );
      return ResponseBody.fromString(
        jsonEncode({'data': detailItem}),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    if (options.method == 'GET' && options.path.contains('/v1/static_assets')) {
      final page = options.queryParameters['page'];
      final parsedPage = page is int ? page : int.tryParse('$page') ?? 1;
      final data = staticAssetsByPage[parsedPage] ?? [];
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
      final data = staticProfileTypesByPage[parsedPage] ?? [];
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
    'app_domains': [],
    'theme_data_settings': {
      'brightness_default': 'light',
      'primary_seed_color': '#FFFFFF',
      'secondary_seed_color': '#000000',
    },
    'main_color': '#FFFFFF',
    'tenant_id': 'tenant-1',
    'telemetry': {'trackers': []},
    'telemetry_context': {'location_freshness_minutes': 5},
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
  return buildAppDataFromInitialization(
    remoteData: remoteData,
    localInfo: localInfo,
  );
}
