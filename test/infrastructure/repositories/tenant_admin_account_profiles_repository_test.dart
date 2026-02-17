import 'dart:convert';
import 'dart:typed_data';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_account_profiles_repository.dart';
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

  test('createAccountProfile uses multipart when upload is provided', () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminAccountProfilesRepository(dio: dio);

    await repository.createAccountProfile(
      accountId: 'account-1',
      profileType: 'personal',
      displayName: 'Profile',
      avatarUpload: TenantAdminMediaUpload(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'avatar.png',
      ),
    );

    final data = adapter.lastRequest?.data;
    expect(
      adapter.lastRequest?.path,
      contains('https://tenant.test/admin/api/v1/account_profiles'),
    );
    expect(data, isA<FormData>());
    final formData = data as FormData;
    expect(formData.files.any((entry) => entry.key == 'avatar'), isTrue);
  });

  test('updateAccountProfile sends slug when provided', () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminAccountProfilesRepository(dio: dio);

    await repository.updateAccountProfile(
      accountProfileId: 'profile-1',
      slug: 'profile-slug-custom',
    );

    expect(adapter.lastRequest?.method, 'PATCH');
    expect(
      adapter.lastRequest?.path,
      contains('https://tenant.test/admin/api/v1/account_profiles/profile-1'),
    );
    final data = adapter.lastRequest?.data;
    expect(data, isA<Map<String, dynamic>>());
    expect((data as Map<String, dynamic>)['slug'], 'profile-slug-custom');
  });

  test('updateAccountProfile keeps empty bio as string payload', () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminAccountProfilesRepository(dio: dio);

    await repository.updateAccountProfile(
      accountProfileId: 'profile-1',
      bio: '',
    );

    final data = adapter.lastRequest?.data;
    expect(data, isA<Map<String, dynamic>>());
    expect((data as Map<String, dynamic>)['bio'], '');
  });

  test('updateAccountProfile omits bio when null', () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminAccountProfilesRepository(dio: dio);

    await repository.updateAccountProfile(
      accountProfileId: 'profile-1',
      bio: null,
      displayName: 'New Name',
    );

    final data = adapter.lastRequest?.data;
    expect(data, isA<Map<String, dynamic>>());
    expect((data as Map<String, dynamic>).containsKey('bio'), isFalse);
    expect(data['display_name'], 'New Name');
  });

  test('fetchProfileTypesPage sends pagination params and parses hasMore',
      () async {
    final adapter = _ProfileTypesRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminAccountProfilesRepository(dio: dio);

    final page = await repository.fetchProfileTypesPage(page: 1, pageSize: 2);

    expect(page.items, hasLength(2));
    expect(page.hasMore, isTrue);
    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.single.queryParameters['page'], 1);
    expect(adapter.requests.single.queryParameters['page_size'], 2);
  });

  test('load/reset/next follow paged stream contract for profile types',
      () async {
    final adapter = _ProfileTypesRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminAccountProfilesRepository(dio: dio);

    await verifyTenantAdminPagedStreamContract(
      scope: 'account profile types',
      loadFirstPage: () => repository.loadProfileTypes(pageSize: 2),
      loadNextPage: () => repository.loadNextProfileTypesPage(pageSize: 2),
      resetState: repository.resetProfileTypesState,
      readItems: () => repository.profileTypesStreamValue.value,
      readHasMore: () => repository.hasMoreProfileTypesStreamValue.value,
      readError: () => repository.profileTypesErrorStreamValue.value,
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
    final payload = jsonEncode({
      'data': {
        'id': 'profile-1',
        'account_id': 'account-1',
        'profile_type': 'personal',
        'display_name': 'Profile',
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
}

class _ProfileTypesRoutingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future? cancelFuture,
  ) async {
    requests.add(options);
    final pageRaw = options.queryParameters['page'];
    final page = pageRaw is int ? pageRaw : int.tryParse('$pageRaw') ?? 1;

    if (options.path.endsWith('/v1/account_profile_types') && page == 1) {
      return _jsonResponse({
        'data': [
          _profileType(id: 'pt-1', type: 'artist', label: 'Artist'),
          _profileType(id: 'pt-2', type: 'venue', label: 'Venue'),
        ],
        'current_page': 1,
        'last_page': 2,
      });
    }

    if (options.path.endsWith('/v1/account_profile_types') && page == 2) {
      return _jsonResponse({
        'data': [
          _profileType(id: 'pt-3', type: 'restaurant', label: 'Restaurant'),
        ],
        'current_page': 2,
        'last_page': 2,
      });
    }

    return _jsonResponse({
      'data': const [],
      'current_page': page,
      'last_page': page,
    });
  }

  Map<String, dynamic> _profileType({
    required String id,
    required String type,
    required String label,
  }) {
    return {
      'id': id,
      'type': type,
      'label': label,
      'allowed_taxonomies': const <String>[],
      'capabilities': const {
        'is_favoritable': true,
        'is_poi_enabled': false,
        'has_bio': true,
        'has_content': true,
        'has_taxonomies': true,
        'has_avatar': true,
        'has_cover': true,
        'has_events': false,
      },
    };
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

AppData _buildAppData() {
  final remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'main_domain': 'https://tenant.test',
    'profile_types': [
      {
        'type': 'personal',
        'label': 'Personal',
        'allowed_taxonomies': [],
        'capabilities': {
          'is_favoritable': false,
          'is_poi_enabled': false,
        },
      },
    ],
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
      remoteData: remoteData, localInfo: localInfo);
}
